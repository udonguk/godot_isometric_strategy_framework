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

	# NavigationRegion2D가 NavigationServer2D에 등록될 때까지 대기
	# (보통 2-3 physics_frame 필요)
	await get_tree().physics_frame
	await get_tree().physics_frame
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
