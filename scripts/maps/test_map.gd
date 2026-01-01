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
@onready var ground_layer: TileMapLayer = $World/NavigationRegion2D/GroundTileMapLayer

## StructuresTileMapLayer 참조 (건물 타일 레이어)
@onready var structures_layer: TileMapLayer = $World/NavigationRegion2D/StructuresTileMapLayer

## World 컨테이너 참조 (모든 Y-Sort 엔티티를 담는 단일 루트)
@onready var world_container: Node2D = $World

## Entities 컨테이너 참조 (건물, 유닛 등 동적 엔티티 - z_index = 1)
@onready var entities_container: Node2D = $World/NavigationRegion2D/Entities


# ============================================================
# 매니저 인스턴스
# ============================================================

## BuildingManager 인스턴스
var building_manager: BuildingManager = null

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

	print("[TestMap] 테스트 맵 초기화")

	# 노드 참조 확인
	if not ground_layer:
		push_error("[TestMap] GroundTileMapLayer를 찾을 수 없습니다!")
		return

	if not world_container:
		push_error("[TestMap] World 컨테이너를 찾을 수 없습니다!")
		return

	if not entities_container:
		push_error("[TestMap] Entities 컨테이너를 찾을 수 없습니다!")
		return

	# GridSystem 초기화 (최우선!)
	GridSystem.initialize(ground_layer)

	# NavigationServer2D 업데이트 대기
	await get_tree().physics_frame

	# GridSystem에 Navigation Map 캐싱
	GridSystem.cache_navigation_map()

	# BuildingManager 생성 및 초기화
	building_manager = BuildingManager.new()
	add_child(building_manager)
	building_manager.initialize(entities_container)

	# 테스트 유닛 생성
	_create_test_units()

	print("[TestMap] 테스트 맵 초기화 완료")
	print("[TestMap] 우클릭으로 유닛을 이동시킬 수 있습니다")


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
