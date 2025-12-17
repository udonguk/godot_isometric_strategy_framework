extends Node2D

## 테스트 맵 스크립트
## Step 3: 그리드 좌표 기반 건물 배치

# ============================================================
# 스크립트 참조
# ============================================================

## GridSystem 스크립트 참조
const GridSystem = preload("res://scripts/map/grid_system.gd")

## BuildingEntity 씬 참조
const BuildingEntityScene = preload("res://scenes/entitys/building_entity.tscn")


# ============================================================
# 노드 참조
# ============================================================

## GroundTileMapLayer 참조 (좌표 변환용)
@onready var ground_layer: TileMapLayer = $GroundTileMapLayer

## Buildings 컨테이너 참조 (동적 건물들을 담는 컨테이너)
@onready var buildings_container: Node2D = $Buildings


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
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

	# 건물 3개를 그리드 좌표로 배치
	_spawn_test_buildings()


# ============================================================
# 건물 배치
# ============================================================

## 테스트용 건물 3개 생성
func _spawn_test_buildings() -> void:
	# 배치할 그리드 좌표
	var grid_positions: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1)
	]

	# 각 그리드 좌표에 건물 배치
	for i in range(grid_positions.size()):
		var grid_pos = grid_positions[i]
		_create_building(grid_pos, "Building_%d" % i)

	print("[TestMap] 건물 ", grid_positions.size(), "개 배치 완료")


## 특정 그리드 좌표에 건물 생성
func _create_building(grid_pos: Vector2i, building_name: String) -> void:
	# BuildingEntity 인스턴스 생성
	var building = BuildingEntityScene.instantiate()

	if not building:
		push_error("[TestMap] BuildingEntity 인스턴스 생성 실패!")
		return

	# 건물 이름 설정
	building.name = building_name

	# 그리드 좌표 설정
	building.grid_position = grid_pos

	# 월드 좌표 계산 (TileMapLayer의 좌표 변환 사용)
	var world_pos: Vector2 = ground_layer.map_to_local(grid_pos)
	building.position = world_pos

	# Buildings 컨테이너에 추가
	buildings_container.add_child(building)

	print("[TestMap] ✅ 건물 생성 성공: ", building_name, " at Grid ", grid_pos)
	print("  → World Position: ", world_pos)
	print("  → 부모 노드: ", building.get_parent().name)
