extends Node

## 건물 매니저
## 건물 생성, 관리, 조회를 담당하는 매니저 클래스
##
## SOLID 원칙 준수:
## - Single Responsibility: 건물 생성/관리만 담당 (좌표 변환은 GridSystem)
## - Dependency Inversion: TileMapLayer 대신 GridSystem에 의존

# ============================================================
# 시그널
# ============================================================

## 건물 배치 시작 시그널 (UI에서 건물 선택 시)
signal building_placement_started(building_data: BuildingData)

## 건물 배치 성공 시그널
signal building_placed(building_data: BuildingData, grid_pos: Vector2i)

## 건물 배치 실패 시그널
signal building_placement_failed(reason: String)


# ============================================================
# 리소스 참조
# ============================================================

## BuildingEntity 씬 참조 (preload)
const BuildingEntityScene = preload("res://scenes/entitys/building_entity.tscn")


# ============================================================
# 의존성
# ============================================================

## GridSystem 참조 (의존성 주입)
##
## ✅ 하이브리드 접근법:
## - 실제 게임: initialize() 호출 시 생략 → Autoload 자동 사용
## - 테스트: Mock GridSystem 주입 → 단위 테스트 가능
var grid_system_ref: GridSystemNode = null


# ============================================================
# 건물 관리 데이터
# ============================================================

## 그리드 좌표 → BuildingEntity 매핑
## Key: Vector2i (그리드 좌표), Value: BuildingEntity 노드
var grid_buildings: Dictionary = {}

## 엔티티들을 추가할 부모 노드 (Entities 컨테이너 - z_index = 1)
var buildings_parent: Node2D = null


# ============================================================
# 초기화
# ============================================================

## BuildingManager 초기화
##
## @param parent_node: 건물 엔티티가 추가될 부모 노드 (필수)
## @param grid_system: (선택) GridSystem 인스턴스. 생략 시 Autoload 사용
##
## 💡 설계 의도 (Dependency Injection - 하이브리드 접근):
## - 실제 게임에서는 grid_system 파라미터를 생략하면 Autoload가 자동으로 사용됨
## - 테스트에서는 Mock GridSystem을 주입하여 독립적인 단위 테스트 가능
## - 이 방식으로 Autoload의 편의성과 테스트 가능성을 모두 확보
##
## 예시:
##   # 실제 게임 (main.gd)
##   BuildingManager.initialize(entities_parent)  # Autoload 자동 사용
##
##   # 테스트 (test_building_manager.gd)
##   var mock_grid = GridSystemNode.new()
##   BuildingManager.initialize(entities_parent, mock_grid)  # Mock 주입
func initialize(parent_node: Node2D, grid_system: GridSystemNode = null) -> void:
	buildings_parent = parent_node

	# 의존성 주입 (Dependency Injection)
	# grid_system이 제공되면 사용, 없으면 Autoload 사용
	grid_system_ref = grid_system if grid_system else GridSystem

	print("[BuildingManager] 초기화 완료 - 부모 노드: ", parent_node.name)


# ============================================================
# 건물 생성
# ============================================================

## 특정 위치에 건물을 건설할 수 있는지 검증
##
## 검증 항목:
## 1. 맵 범위 검증 (GridSystem.is_valid_position)
## 2. 기존 건물 존재 여부 (BuildingManager.has_building)
## 3. 건물 크기 고려 (grid_size)
##
## @param building_data: 건설할 건물 데이터
## @param grid_pos: 건설할 그리드 좌표 (건물의 좌상단 위치)
## @return: {success: bool, reason: String}
func can_build_at(building_data: BuildingData, grid_pos: Vector2i) -> Dictionary:
	# 1. building_data 유효성 확인
	if not building_data:
		return {"success": false, "reason": "건물 데이터가 없습니다"}

	# 2. 건물 크기 가져오기
	var grid_size: Vector2i = building_data.grid_size

	# 3. 맵 범위 검증 (주입된 GridSystem 인스턴스 사용)
	if not grid_system_ref.is_valid_position(grid_pos, grid_size):
		return {"success": false, "reason": "맵 범위를 벗어났습니다"}

	# 4. 건물이 차지하는 모든 타일에 기존 건물이 있는지 확인
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var check_pos = grid_pos + Vector2i(x, y)
			if has_building(check_pos):
				return {"success": false, "reason": "이미 건물이 존재합니다 (Grid: %s)" % GridSystemNode.grid_to_string(check_pos)}

	# 5. 모든 검증 통과
	return {"success": true, "reason": ""}


## 특정 그리드 위치에 건물 생성
## grid_pos: 그리드 좌표
## building_data: (선택) BuildingData Resource - 제공 시 initialize() 호출
## 반환값: 생성된 BuildingEntity 인스턴스 (실패 시 null)
func create_building(grid_pos: Vector2i, building_data: BuildingData = null) -> Node2D:
	# 1. 부모 노드가 설정되지 않았으면 에러
	if not buildings_parent:
		push_error("[BuildingManager] 부모 노드가 설정되지 않았습니다. initialize()를 먼저 호출하세요.")
		return null

	# 2. building_data가 있으면 can_build_at()로 사전 검증
	if building_data:
		var validation_result = can_build_at(building_data, grid_pos)
		if not validation_result.success:
			print("[BuildingManager] 건설 불가: ", validation_result.reason)
			building_placement_failed.emit(validation_result.reason)
			return null
	else:
		# building_data가 없으면 기존 방식으로 간단히 검증
		if grid_buildings.has(grid_pos):
			print("[BuildingManager] 이미 건물이 존재: ", grid_pos)
			building_placement_failed.emit("이미 건물이 존재합니다")
			return null

	# 3. BuildingEntity 인스턴스 생성
	var building = BuildingEntityScene.instantiate()

	# 4. 그리드 좌표 설정
	building.grid_position = grid_pos

	# 5. 월드 좌표 계산 (주입된 GridSystem 인스턴스 사용)
	# GridSystem이 TileMapLayer를 캡슐화하여 정확한 좌표 제공
	var world_pos: Vector2 = grid_system_ref.grid_to_world(grid_pos)
	building.position = world_pos

	# 6. 씬 트리에 추가
	buildings_parent.add_child(building)

	# 7. Dictionary에 등록 (건물 크기 고려)
	if building_data:
		var grid_size: Vector2i = building_data.grid_size
		# 건물이 차지하는 모든 타일을 Dictionary에 등록
		for x in range(grid_size.x):
			for y in range(grid_size.y):
				var occupied_pos = grid_pos + Vector2i(x, y)
				grid_buildings[occupied_pos] = building
	else:
		grid_buildings[grid_pos] = building

	# 8. ⭐ Resource 기반 초기화 (의존성 주입 패턴)
	if building_data:
		building.initialize(building_data)
		print("[BuildingManager] 건물 생성 (Resource): ", building_data.entity_name, " at Grid ", grid_pos, " → World ", world_pos)
		building_placed.emit(building_data, grid_pos)
	else:
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
func get_all_buildings() -> Array[Node2D]:
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

	# 건물이 차지하는 모든 타일을 Dictionary에서 제거
	if building.data:
		var grid_size: Vector2i = building.data.grid_size
		var base_pos: Vector2i = building.grid_position
		for x in range(grid_size.x):
			for y in range(grid_size.y):
				var occupied_pos = base_pos + Vector2i(x, y)
				grid_buildings.erase(occupied_pos)
	else:
		# data가 없으면 단일 타일만 제거 (기존 방식)
		grid_buildings.erase(grid_pos)

	# 씬 트리에서 제거
	building.queue_free()

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
