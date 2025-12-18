extends Node

## 건물 매니저
## 건물 생성, 관리, 조회를 담당하는 매니저 클래스
##
## SOLID 원칙 준수:
## - Single Responsibility: 건물 생성/관리만 담당 (좌표 변환은 GridSystem)
## - Dependency Inversion: TileMapLayer 대신 GridSystem에 의존

# ============================================================
# 리소스 참조
# ============================================================

## BuildingEntity 씬 참조 (preload)
const BuildingEntityScene = preload("res://scenes/entitys/building_entity.tscn")


# ============================================================
# 건물 관리 데이터
# ============================================================

## 그리드 좌표 → BuildingEntity 매핑
## Key: Vector2i (그리드 좌표), Value: BuildingEntity 노드
var grid_buildings: Dictionary = {}

## 건물들을 추가할 부모 노드 (씬 트리에서 설정)
var buildings_parent: Node2D = null


# ============================================================
# 초기화
# ============================================================

## 매니저 초기화
## parent_node: 건물들을 추가할 부모 노드 (예: test_map의 Buildings 노드)
func initialize(parent_node: Node2D) -> void:
	buildings_parent = parent_node
	print("[BuildingManager] 초기화 완료 - 부모 노드: ", parent_node.name)


# ============================================================
# 건물 생성
# ============================================================

## 특정 그리드 위치에 건물 생성
## grid_pos: 그리드 좌표
## 반환값: 생성된 BuildingEntity 인스턴스 (실패 시 null)
func create_building(grid_pos: Vector2i) -> Node2D:
	# 이미 건물이 존재하는 위치인지 확인
	if grid_buildings.has(grid_pos):
		push_warning("[BuildingManager] 이미 건물이 존재: ", grid_pos)
		return grid_buildings[grid_pos]

	# 부모 노드가 설정되지 않았으면 에러
	if not buildings_parent:
		push_error("[BuildingManager] 부모 노드가 설정되지 않았습니다. initialize()를 먼저 호출하세요.")
		return null

	# BuildingEntity 인스턴스 생성
	var building = BuildingEntityScene.instantiate()

	# 그리드 좌표 설정
	building.grid_position = grid_pos

	# 월드 좌표 계산 (GridSystem 사용!)
	# GridSystem이 TileMapLayer를 캡슐화하여 정확한 좌표 제공
	# get_node()로 명시적 접근 (Autoload 인식 문제 우회)
	var grid_system = get_node("/root/GridSystem")
	var world_pos: Vector2 = grid_system.grid_to_world(grid_pos)
	building.position = world_pos

	# 씬 트리에 추가
	buildings_parent.add_child(building)

	# Dictionary에 등록
	grid_buildings[grid_pos] = building

	print("[BuildingManager] 건물 생성: Grid ", grid_pos, " → World ", world_pos)

	return building


## 여러 건물을 한 번에 생성
## grid_positions: 그리드 좌표 배열
## 반환값: 생성된 BuildingEntity 배열
func create_buildings(grid_positions: Array[Vector2i]) -> Array:
	var created_buildings: Array = []

	for grid_pos in grid_positions:
		var building = create_building(grid_pos)
		if building:
			created_buildings.append(building)

	print("[BuildingManager] 총 ", created_buildings.size(), "개 건물 생성 완료")
	return created_buildings


# ============================================================
# 건물 조회
# ============================================================

## 특정 그리드 위치의 건물 가져오기
## grid_pos: 그리드 좌표
## 반환값: BuildingEntity 인스턴스 (없으면 null)
func get_building(grid_pos: Vector2i):
	if grid_buildings.has(grid_pos):
		return grid_buildings[grid_pos]
	return null


## 특정 그리드 위치에 건물이 존재하는지 확인
func has_building(grid_pos: Vector2i) -> bool:
	return grid_buildings.has(grid_pos)


## 모든 건물 가져오기
func get_all_buildings() -> Array:
	return grid_buildings.values()


## 건물 개수 가져오기
func get_building_count() -> int:
	return grid_buildings.size()


# ============================================================
# 건물 제거
# ============================================================

## 특정 그리드 위치의 건물 제거
func remove_building(grid_pos: Vector2i) -> void:
	if not grid_buildings.has(grid_pos):
		push_warning("[BuildingManager] 제거할 건물이 없음: ", grid_pos)
		return

	var building = grid_buildings[grid_pos]

	# 씬 트리에서 제거
	building.queue_free()

	# Dictionary에서 제거
	grid_buildings.erase(grid_pos)

	print("[BuildingManager] 건물 제거: ", grid_pos)


## 모든 건물 제거
func clear_all_buildings() -> void:
	for building in grid_buildings.values():
		building.queue_free()

	grid_buildings.clear()
	print("[BuildingManager] 모든 건물 제거 완료")


# ============================================================
# 유틸리티
# ============================================================

## 디버그: 모든 건물 정보 출력
func print_all_buildings() -> void:
	print("[BuildingManager] === 건물 목록 (총 ", grid_buildings.size(), "개) ===")
	for grid_pos in grid_buildings.keys():
		var building = grid_buildings[grid_pos]
		print("  Grid: ", grid_pos, " | State: ", building.current_state)
