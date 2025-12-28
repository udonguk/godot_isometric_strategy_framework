extends Node2D

## 테스트 맵 스크립트
## Step 4: BuildingManager를 사용한 건물 자동 생성

# ============================================================
# 스크립트 참조
# ============================================================

## GridSystem 스크립트 참조
# GridSystem은 Autoload 싱글톤이므로 preload 불필요 (이름 충돌 방지)
# const GridSystem = preload("res://scripts/map/grid_system.gd")

## BuildingManager 스크립트 참조
const BuildingManager = preload("res://scripts/managers/building_manager.gd")

## BuildingEntity 스크립트 참조 (상태 enum 접근용)
const BuildingEntity = preload("res://scripts/entity/building_entity.gd")

## UnitEntity 씬 참조 (테스트용)
const UnitEntityScene = preload("res://scenes/entitys/unit_entity.tscn")


# ============================================================
# 노드 참조
# ============================================================

## GroundTileMapLayer 참조 (좌표 변환용)
@onready var ground_layer: TileMapLayer = $GroundTileMapLayer

## Buildings 컨테이너 참조 (동적 건물들을 담는 컨테이너)
@onready var buildings_container: Node2D = $Buildings

## Units 컨테이너 참조 (동적 유닛들을 담는 컨테이너)
@onready var units_container: Node2D = $Units


# ============================================================
# 매니저 인스턴스
# ============================================================

## BuildingManager 인스턴스
var building_manager: BuildingManager = null

## 현재 선택된 건물
var selected_building = null

## 테스트 유닛 배열
var test_units: Array = []

## 현재 선택된 유닛
var selected_unit = null


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# main 그룹 등록 (건물에서 이벤트를 전달받기 위해)
	add_to_group("main")

	print("[TestMap] 테스트 맵 초기화")

	# 노드 참조 확인
	if not ground_layer:
		push_error("[TestMap] GroundTileMapLayer를 찾을 수 없습니다!")
		return

	if not buildings_container:
		push_error("[TestMap] Buildings 컨테이너를 찾을 수 없습니다!")
		return

	print("[TestMap] ground_layer: ", ground_layer)
	print("[TestMap] buildings_container: ", buildings_container)

	# GridSystem 초기화 (최우선!)
	# 모든 좌표 변환은 GridSystem을 통해 이루어짐
	# get_node()로 명시적 접근 (Autoload 인식 문제 우회)
	GridSystem.initialize(ground_layer)

	# 타일 자동 배치 (Navigation 테스트를 위해)
	_create_test_tiles()

	# NavigationServer2D가 Navigation Mesh를 업데이트할 시간을 주기 위해 대기
	await get_tree().physics_frame
	await get_tree().physics_frame  # 2프레임 대기 (안정성 향상)

	# GridSystem에 Navigation Map 캐싱
	GridSystem.cache_navigation_map()

	# BuildingManager 생성 및 씬 트리에 추가 (Autoload 접근을 위해 필수!)
	building_manager = BuildingManager.new()
	add_child(building_manager)  # ← 이게 핵심! 씬 트리에 추가해야 GridSystem 접근 가능
	building_manager.initialize(buildings_container)

	# 3x3 그리드에 9개 건물 자동 생성
	#_create_test_buildings()

	# === Navigation 테스트 ===
	_test_navigation_validation()
	_test_obstacle_marking()

	# === 테스트 유닛 생성 ===
	_create_test_units()

	print("[TestMap] 테스트 맵 초기화 완료")
	print("[TestMap] 건물을 클릭하면 외곽선이 표시됩니다")
	print("[TestMap] 우클릭으로 유닛을 이동시킬 수 있습니다")


# ============================================================
# 타일 배치
# ============================================================

## 테스트용 타일 자동 배치 (20x20 맵)
func _create_test_tiles() -> void:
	print("[TestMap] === 타일 자동 배치 시작 ===")

	# TileMapLayer의 Navigation 활성화 확인 및 설정
	print("[TestMap] TileMapLayer 설정 확인...")
	print("[TestMap] - enabled: ", ground_layer.enabled)

	# TileMapLayer 활성화
	ground_layer.enabled = true

	# GameConfig의 맵 크기만큼 타일 배치
	for x in range(GameConfig.MAP_WIDTH):
		for y in range(GameConfig.MAP_HEIGHT):
			var grid_pos = Vector2i(x, y)
			# 타일 ID 0:0/0 (ground_tileset.tres에 정의된 Ground 타일)
			# source_id: 0, atlas_coords: Vector2i(0, 0)
			ground_layer.set_cell(grid_pos, 0, Vector2i(0, 0))

	print("[TestMap] === 타일 배치 완료: %dx%d (%d개) ===" % [GameConfig.MAP_WIDTH, GameConfig.MAP_HEIGHT, GameConfig.MAP_WIDTH * GameConfig.MAP_HEIGHT])

	# NavigationServer2D 강제 업데이트
	print("[TestMap] NavigationServer2D 강제 업데이트...")
	var nav_map = ground_layer.get_world_2d().navigation_map
	if nav_map.is_valid():
		NavigationServer2D.map_force_update(nav_map)
		print("[TestMap] - Navigation Map 업데이트 완료")
	else:
		push_error("[TestMap] - Navigation Map이 유효하지 않습니다!")


# ============================================================
# 건물 생성
# ============================================================

## 테스트용 건물들 생성 (3x3 그리드)
func _create_test_buildings() -> void:
	print("[TestMap] === 3x3 건물 자동 생성 시작 ===")

	# 3x3 그리드 범위 설정
	var grid_size: int = 3
	var start_x: int = 0
	var start_y: int = 0

	# 이중 for문으로 건물 생성
	for x in range(start_x, start_x + grid_size):
		for y in range(start_y, start_y + grid_size):
			var grid_pos = Vector2i(x, y)
			var building = building_manager.create_building(grid_pos)

			# 중앙 건물(1,1)을 INFECTED 상태로 초기화
			if grid_pos == Vector2i(1, 1):
				if building and building.has_method("set_state"):
					building.set_state(BuildingEntity.BuildingState.INFECTED)
					print("[TestMap] 중앙 건물(1,1)을 INFECTED 상태로 설정")

	# 생성 완료 로그
	var total_count = building_manager.get_building_count()
	print("[TestMap] === 건물 생성 완료: 총 ", total_count, "개 ===")

	# 디버그: 모든 건물 정보 출력
	building_manager.print_all_buildings()


# ============================================================
# Navigation 테스트
# ============================================================

## Navigation 검증 테스트
func _test_navigation_validation() -> void:
	print("\n[TestMap] === Navigation 검증 테스트 시작 ===")

	# 테스트 케이스
	var test_cases = [
		Vector2i(0, 0),      # 좌상단 (유효)
		Vector2i(10, 10),    # 중앙 (유효)
		Vector2i(19, 19),    # 우하단 (유효)
		Vector2i(-1, 0),     # 맵 밖 (무효)
		Vector2i(0, -1),     # 맵 밖 (무효)
		Vector2i(20, 20),    # 맵 밖 (무효)
		Vector2i(5, 5),      # 임의 위치 (유효)
	]

	for grid_pos in test_cases:
		var is_valid = GridSystem.is_valid_navigation_position(grid_pos)
		var status = "✅ 유효" if is_valid else "❌ 무효"
		print("  Grid %s: %s" % [GridSystemNode.grid_to_string(grid_pos), status])

	print("[TestMap] === Navigation 검증 테스트 완료 ===\n")


## 장애물 등록 테스트
func _test_obstacle_marking() -> void:
	print("\n[TestMap] === 장애물 등록 테스트 시작 ===")

	# 장애물 등록
	GridSystem.mark_as_obstacle(Vector2i(5, 5), Vector2i(1, 1))
	GridSystem.mark_as_obstacle(Vector2i(10, 10), Vector2i(2, 2))

	# 장애물 Dictionary 확인
	print("[TestMap] 등록된 장애물 수: %d" % GridSystem.obstacles.size())
	for pos in GridSystem.obstacles.keys():
		var size = GridSystem.obstacles[pos]
		print("  장애물: Grid %s, Size: %s" % [GridSystemNode.grid_to_string(pos), size])

	print("[TestMap] === 장애물 등록 테스트 완료 ===\n")


# ============================================================
# 유닛 생성
# ============================================================

## 테스트용 유닛 생성
func _create_test_units() -> void:
	print("\n[TestMap] === 테스트 유닛 생성 시작 ===")

	# Units 컨테이너 확인
	if not units_container:
		push_error("[TestMap] Units 컨테이너를 찾을 수 없습니다!")
		return

	# 테스트 유닛 2개 생성 (그리드 (5, 5), (7, 7))
	var test_positions = [
		Vector2i(5, 5),
		Vector2i(7, 7)
	]

	for grid_pos in test_positions:
		# UnitEntity 인스턴스 생성
		var unit = UnitEntityScene.instantiate()

		# 월드 좌표로 변환
		var world_pos = GridSystem.grid_to_world(grid_pos)
		unit.global_position = world_pos

		# Units 컨테이너에 추가
		units_container.add_child(unit)

		# 배열에 저장
		test_units.append(unit)

		# 유닛 클릭 이벤트 연결
		unit.input_event.connect(_on_unit_input_event.bind(unit))

		print("[TestMap] 유닛 생성 - Grid: %s, World: %s" % [grid_pos, world_pos])

	print("[TestMap] === 테스트 유닛 생성 완료: 총 %d개 ===" % test_units.size())


# ============================================================
# 입력 처리
# ============================================================

## 입력 처리 (Entity가 처리하지 않은 입력만)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# 마우스 왼쪽 버튼 클릭 - 빈 공간 클릭
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_empty_click()

		# 마우스 우클릭 - 유닛 이동 명령
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_on_move_command()


## 빈 공간 클릭 시 호출되는 함수
func _on_empty_click() -> void:
	# 마우스 위치 → 월드 좌표 변환
	var world_pos: Vector2 = get_global_mouse_position()

	# 월드 좌표 → 그리드 좌표 변환
	var grid_pos: Vector2i = GridSystem.world_to_grid(world_pos)

	# Navigation 유효성 검증 ✅ 추가
	var is_valid_nav = GridSystem.is_valid_navigation_position(grid_pos)
	var nav_status = "✅ Navigation 가능" if is_valid_nav else "❌ Navigation 불가"

	print("[TestMap] 빈 공간 클릭 - World: %s | Grid: %s | %s" % [world_pos, grid_pos, nav_status])

	# 해당 위치에 건물이 있는지 확인
	if building_manager.has_building(grid_pos):
		print("  → 이미 건물이 존재합니다")
	else:
		print("  → 빈 공간입니다")

	# 빈 공간 클릭 시 선택 해제
	_deselect_building()
	_deselect_unit()


# ============================================================
# 건물 선택 처리
# ============================================================

## 건물 선택 처리 (building_entity.gd에서 호출)
func _on_building_selected(building) -> void:
	# 이전 선택된 건물 외곽선 제거
	if selected_building and selected_building != building:
		selected_building.hide_outline()

	# 새 건물 선택
	selected_building = building
	selected_building.show_outline()

	# 디버그: 선택된 건물 정보 출력
	print("[TestMap] 건물 선택: Grid ", building.grid_position, " | State: ", building.current_state)


## 건물 선택 해제
func _deselect_building() -> void:
	if selected_building:
		selected_building.hide_outline()
		selected_building = null
		print("[TestMap] 건물 선택 해제")


# ============================================================
# 유닛 선택 처리
# ============================================================

## 유닛 클릭 처리
func _on_unit_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, unit) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_unit(unit)


## 유닛 선택
func _select_unit(unit) -> void:
	# 이전 선택된 유닛 해제
	if selected_unit and selected_unit != unit:
		selected_unit.is_selected = false

	# 새 유닛 선택
	selected_unit = unit
	selected_unit.is_selected = true

	print("[TestMap] 유닛 선택: Position ", unit.global_position)


## 유닛 선택 해제
func _deselect_unit() -> void:
	if selected_unit:
		selected_unit.is_selected = false
		selected_unit = null
		print("[TestMap] 유닛 선택 해제")


## 유닛 이동 명령 (우클릭)
func _on_move_command() -> void:
	# 선택된 유닛이 없으면 무시
	if not selected_unit:
		return

	# 마우스 위치 → 월드 좌표
	var world_pos = get_global_mouse_position()

	# 월드 좌표 → 그리드 좌표
	var grid_pos = GridSystem.world_to_grid(world_pos)

	# Navigation 가능 여부 검증
	if not GridSystem.is_valid_navigation_position(grid_pos):
		push_warning("[TestMap] Navigation 불가능한 위치: ", grid_pos)
		return

	# 최종 목표는 월드 좌표로 전달
	var target_world = GridSystem.grid_to_world(grid_pos)

	# 유닛에게 이동 명령
	selected_unit.move_to(target_world)

	print("[TestMap] 유닛 이동 명령 - Grid: %s, World: %s" % [grid_pos, target_world])
