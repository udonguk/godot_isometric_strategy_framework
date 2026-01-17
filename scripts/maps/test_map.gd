extends Node2D

## 테스트 맵 스크립트
## Step 4: BuildingManager를 사용한 건물 자동 생성

# ============================================================
# 스크립트 참조
# ============================================================

## GridSystem 스크립트 참조
# GridSystem은 Autoload 싱글톤이므로 preload 불필요 (이름 충돌 방지)
# const GridSystem = preload("res://scripts/map/grid_system.gd")

## BuildingManager는 Autoload 싱글톤이므로 preload 불필요
# const BuildingManager = preload(...) → BuildingManager Autoload 직접 사용

## UnitEntity 씬 참조 (테스트용)
const UnitEntityScene = preload("res://scenes/entitys/unit_entity.tscn")


# ============================================================
# 노드 참조
# ============================================================

## GroundTileMapLayer 참조 (좌표 변환용)
@onready var ground_layer: TileMapLayer = $World/NavigationRegion2D/GroundTileMapLayer

## StructuresTileMapLayer 참조 (건물 타일 레이어)
@onready var structures_layer: TileMapLayer = $World/NavigationRegion2D/StructuresTileMapLayer

## World 컨테이너 참조 (모든 Y-Sort 엔티티를 담는 단일 루트)
@onready var world_container: Node2D = $World

## Entities 컨테이너 참조 (건물, 유닛 등 동적 엔티티 - z_index = 1)
@onready var entities_container: Node2D = $World/NavigationRegion2D/Entities

## NavigationRegion2D 참조 (건물 배치 시 자동 bake용)
@onready var navigation_region: NavigationRegion2D = $World/NavigationRegion2D


# ============================================================
# 테스트 데이터
# ============================================================

## 테스트 유닛 배열
var test_units: Array = []


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# Navigation Debug 활성화 (시각적 확인용)
	NavigationServer2D.set_debug_enabled(true)

	# main 그룹 등록 (건물에서 이벤트를 전달받기 위해)
	add_to_group("main")


## 맵 비동기 초기화 (외부에서 await로 호출)
##
## _ready()에서 직접 await를 사용하면 ready 신호가 await 이전에 발생하여
## 외부에서 초기화 완료 시점을 알 수 없습니다.
## 따라서 비동기 초기화는 별도 함수로 분리하고, main.gd에서 직접 await합니다.
##
## @example
##   # main.gd
##   await test_map.initialize_async()
func initialize_async() -> void:
	print("[TestMap] 테스트 맵 초기화")

	# 노드 참조 확인
	if not _validate_node_references():
		return

	# 게임 시스템 초기화 (순서 중요!)
	await _initialize_systems()

	# 테스트 엔티티 생성
	_create_test_units()
	_test_resource_based_buildings()

	print("[TestMap] 테스트 맵 초기화 완료")
	print("[TestMap] 우클릭으로 유닛을 이동시킬 수 있습니다")


## 필수 노드 참조를 검증합니다.
## @return 모든 노드가 유효하면 true, 하나라도 null이면 false
func _validate_node_references() -> bool:
	if not ground_layer:
		push_error("[TestMap] GroundTileMapLayer를 찾을 수 없습니다!")
		return false

	if not world_container:
		push_error("[TestMap] World 컨테이너를 찾을 수 없습니다!")
		return false

	if not entities_container:
		push_error("[TestMap] Entities 컨테이너를 찾을 수 없습니다!")
		return false

	return true


## 게임 시스템들을 올바른 순서로 초기화합니다.
##
## 초기화 순서가 중요한 이유:
## 1. GridSystem.initialize() - TileMapLayer를 GridSystem에 등록해야 좌표 변환 가능
## 2. await _wait_for_navigation_registration() - NavigationRegion2D가 NavigationServer2D에 등록 대기
## 3. GridSystem.cache_navigation_map() - Navigation Map ID를 캐싱 (1, 2 완료 후에만 가능)
## 4. BuildingManager.initialize() - 건물 생성 시 GridSystem 사용 (1, 3 완료 후에만 가능)
##
## ⚠️ 주의: 이 순서를 변경하면 Navigation 시스템이 정상 작동하지 않습니다!
func _initialize_systems() -> void:
	# 1단계: GridSystem에 TileMapLayer 등록
	GridSystem.initialize(ground_layer)

	# 2단계: NavigationServer2D 등록 완료 대기
	await _wait_for_navigation_registration()

	# 3단계: Navigation Map 캐싱 (경로 찾기에 필요)
	GridSystem.cache_navigation_map()

	# 4단계: BuildingManager 초기화 (Autoload이므로 initialize만 호출)
	BuildingManager.initialize(entities_container, null, navigation_region)


## NavigationRegion2D가 NavigationServer2D에 완전히 등록될 때까지 대기합니다.
##
## Godot 4.x에서는 NavigationRegion2D 노드가 씬 트리에 추가된 후
## 최소 3 physics frame이 지나야 NavigationServer2D에 완전히 등록됩니다.
##
## 이 대기 시간이 없으면:
## - NavigationServer2D.map_get_path() 호출 시 빈 경로 반환
## - GridSystem.cache_navigation_map()에서 유효하지 않은 Map ID 획득
## - 유닛의 NavigationAgent2D가 경로를 찾지 못함
##
## @see https://docs.godotengine.org/en/stable/classes/class_navigationserver2d.html
func _wait_for_navigation_registration() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


# ============================================================
# 입력 처리 (건설 모드)
# ============================================================

## 입력 이벤트 처리 (건설 모드 중 맵 클릭)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_map_click(event.position)


## 맵 클릭 처리 (건설 모드 중 건물 배치)
func _handle_map_click(screen_pos: Vector2) -> void:
	# 건설 모드가 아니면 무시 (BuildingManager는 Autoload)
	if not BuildingManager.is_in_placement_mode():
		return

	# 화면 좌표 → 월드 좌표 → 그리드 좌표 변환
	var world_pos = get_global_mouse_position()
	var grid_pos = GridSystem.world_to_grid(world_pos)

	# 건물 배치 시도
	if BuildingManager.try_place_building(grid_pos):
		print("[TestMap] 건물 배치 성공: ", grid_pos)
		get_viewport().set_input_as_handled()


# ============================================================
# 유닛 생성
# ============================================================

## 테스트용 유닛 생성
func _create_test_units() -> void:
	# 테스트 유닛 2개 생성 (오른쪽 끝)
	var test_positions = [
		Vector2i(15, 5),
		Vector2i(18, 7)
	]

	for grid_pos in test_positions:
		var unit = UnitEntityScene.instantiate()
		var world_pos = GridSystem.grid_to_world(grid_pos)
		unit.global_position = world_pos
		entities_container.add_child(unit)
		test_units.append(unit)

	print("[TestMap] 테스트 유닛 %d개 생성 완료" % test_units.size())
	print("[TestMap] 좌클릭으로 유닛 선택, 우클릭으로 이동 명령")


# ============================================================
# Resource 기반 건물 테스트
# ============================================================

## Resource 기반 건물 생성 테스트
func _test_resource_based_buildings() -> void:
	print("\n========================================")
	print("Resource 기반 건물 생성 테스트 시작")
	print("========================================\n")

	print("[TestMap] BuildingDatabase 확인: ", BuildingDatabase)

	# BuildingDatabase에서 건물 데이터 로드
	print("[TestMap] house_01 데이터 요청 중...")
	var house_data = BuildingDatabase.get_building_by_id("house_01")
	print("[TestMap] house_01 데이터 결과: ", house_data)

	print("[TestMap] farm_01 데이터 요청 중...")
	var farm_data = BuildingDatabase.get_building_by_id("farm_01")
	print("[TestMap] farm_01 데이터 결과: ", farm_data)

	print("[TestMap] shop_01 데이터 요청 중...")
	var shop_data = BuildingDatabase.get_building_by_id("shop_01")
	print("[TestMap] shop_01 데이터 결과: ", shop_data)

	# 데이터 로드 확인
	if house_data:
		print("[TestMap] house_01 로드 성공: ", house_data.entity_name)
	else:
		push_error("[TestMap] house_01 로드 실패!")

	if farm_data:
		print("[TestMap] farm_01 로드 성공: ", farm_data.entity_name)
	else:
		push_error("[TestMap] farm_01 로드 실패!")

	if shop_data:
		print("[TestMap] shop_01 로드 성공: ", shop_data.entity_name)
	else:
		push_error("[TestMap] shop_01 로드 실패!")

	# 건물 생성 (왼쪽 영역에 배치)
	var test_building_positions = [
		{"pos": Vector2i(3, 3), "data": house_data},
		{"pos": Vector2i(5, 3), "data": farm_data},
		{"pos": Vector2i(7, 3), "data": shop_data},
	]

	for building_info in test_building_positions:
		var grid_pos = building_info["pos"]
		var data = building_info["data"]

		if data:
			var building = BuildingManager.create_building(grid_pos, data)
			if building:
				print("[TestMap] ✅ 건물 생성 성공: ", data.entity_name, " at ", grid_pos)
			else:
				push_error("[TestMap] ❌ 건물 생성 실패: ", data.entity_name)
		else:
			push_error("[TestMap] ❌ 건물 데이터가 null입니다!")

	print("\n========================================")
	print("✅ Resource 기반 건물 테스트 완료!")
	print("화면 왼쪽에 3개의 건물이 각기 다른 이미지로 보여야 합니다:")
	print("  - (3, 3): 주택 (빨간 아이콘)")
	print("  - (5, 3): 농장 (원형 아이콘)")
	print("  - (7, 3): 상점 (타일셋 이미지)")
	print("========================================\n")
