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


# ============================================================
# 노드 참조
# ============================================================

## GroundTileMapLayer 참조 (좌표 변환용)
@onready var ground_layer: TileMapLayer = $GroundTileMapLayer

## Buildings 컨테이너 참조 (동적 건물들을 담는 컨테이너)
@onready var buildings_container: Node2D = $Buildings


# ============================================================
# 매니저 인스턴스
# ============================================================

## BuildingManager 인스턴스
var building_manager: BuildingManager = null

## 현재 선택된 건물
var selected_building = null


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

	# BuildingManager 생성 및 씬 트리에 추가 (Autoload 접근을 위해 필수!)
	building_manager = BuildingManager.new()
	add_child(building_manager)  # ← 이게 핵심! 씬 트리에 추가해야 GridSystem 접근 가능
	building_manager.initialize(buildings_container)

	# 3x3 그리드에 9개 건물 자동 생성
	#_create_test_buildings()

	print("[TestMap] 테스트 맵 초기화 완료")
	print("[TestMap] 건물을 클릭하면 외곽선이 표시됩니다")


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
# 입력 처리
# ============================================================

## 빈 공간 클릭 처리 (Entity가 처리하지 않은 입력만)
func _unhandled_input(event: InputEvent) -> void:
	# 마우스 왼쪽 버튼 클릭 감지
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_empty_click(event.position)


## 빈 공간 클릭 시 호출되는 함수
func _on_empty_click(screen_pos: Vector2) -> void:
	# 화면 좌표 → 월드 좌표 변환
	var world_pos: Vector2 = get_global_mouse_position()

	# 월드 좌표 → 그리드 좌표 변환
	var grid_pos: Vector2i = GridSystem.world_to_grid(world_pos)

	print("[TestMap] 빈 공간 클릭 - World: ", world_pos, " | Grid: ", grid_pos)

	# 해당 위치에 건물이 있는지 확인
	if building_manager.has_building(grid_pos):
		print("  → 이미 건물이 존재합니다")
	else:
		print("  → 빈 공간입니다")

	# 빈 공간 클릭 시 선택 해제
	_deselect_building()


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
