extends Node2D

## 메인 씬 스크립트
## Step 1 테스트: 스페이스바로 모든 건물 상태 순환 변경

# ============================================================
# 스크립트 참조
# ============================================================

## BuildingEntity 스크립트 참조
const BuildingEntity = preload("res://scripts/entity/building_entity.gd")

## GridSystem은 Autoload 싱글톤이므로 preload 불필요!
## 전역적으로 GridSystem으로 바로 접근 가능


# ============================================================
# 노드 참조
# ============================================================

## GroundTileMapLayer 참조 (좌표 변환용)
@onready var ground_layer: TileMapLayer = $test_map_Node2D/GroundTileMapLayer


# ============================================================
# 테스트 변수
# ============================================================

## 현재 테스트 상태 (모든 건물에 적용)
var test_state_index: int = 0

## 가능한 상태 배열
var test_states: Array = [
	BuildingEntity.BuildingState.NORMAL,
	BuildingEntity.BuildingState.INFECTING,
	BuildingEntity.BuildingState.INFECTED
]

## 현재 선택된 건물
var selected_building = null


# ============================================================
# 생명주기
# ============================================================

func _ready() -> void:
	# main 그룹 등록 (건물에서 이벤트를 전달받기 위해)
	add_to_group("main")

	# GridSystem 초기화 (Autoload 싱글톤)
	# get_node()로 명시적 접근 (Autoload 인식 문제 우회)
	if ground_layer:
		GridSystem.initialize(ground_layer)
	else:
		push_warning("[Main] GroundTileMapLayer를 찾을 수 없어 GridSystem 초기화를 건너뜁니다.")

	print("[Main] 게임 시작")
	print("[Main] 스페이스바를 눌러 모든 건물의 상태를 변경하세요")
	print("[Main] 건물을 클릭하면 외곽선이 표시됩니다")


# ============================================================
# 입력 처리
# ============================================================

func _input(event: InputEvent) -> void:
	# 스페이스바 입력 감지
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		cycle_all_buildings_state()


## 빈 공간 클릭 처리 (Entity가 처리하지 않은 입력만)
func _unhandled_input(event: InputEvent) -> void:
	# 마우스 왼쪽 버튼 클릭 감지
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_empty_click(event.position)


# ============================================================
# 테스트 함수
# ============================================================

## 모든 건물의 상태를 순환 변경
func cycle_all_buildings_state() -> void:
	# 다음 상태로 순환
	test_state_index = (test_state_index + 1) % test_states.size()
	var new_state = test_states[test_state_index]

	# 씬 트리에서 모든 BuildingEntity 찾기
	var buildings = get_tree().get_nodes_in_group("buildings")

	# 모든 건물의 상태 변경
	for building in buildings:
		if building.has_method("set_state"):
			building.set_state(new_state)

	print("[Main] 모든 건물 상태 변경: ", _state_to_string(new_state), " (총 ", buildings.size(), "개)")


## 빈 공간 클릭 시 호출되는 함수
func _on_empty_click(_screen_pos: Vector2) -> void:
	# 화면 좌표 → 월드 좌표 변환
	var world_pos: Vector2 = get_global_mouse_position()

	# 월드 좌표 → 그리드 좌표 변환 (TileMapLayer 사용)
	var grid_pos: Vector2i = ground_layer.local_to_map(world_pos)

	# 디버그: GridSystem과 TileMapLayer 좌표 비교
	var grid_system_pos: Vector2i = GridSystem.world_to_grid(world_pos)
	print("[Main] 빈 공간 클릭 - World: ", world_pos)
	print("  → TileMapLayer Grid: ", grid_pos, " | GridSystem Grid: ", grid_system_pos)

	# 빈 공간 클릭 시 선택 해제
	_deselect_building()


## 건물 선택 처리 (building_entity.gd에서 호출)
func _on_building_selected(building) -> void:
	# 이전 선택된 건물 외곽선 제거
	if selected_building and selected_building != building:
		selected_building.hide_outline()

	# 새 건물 선택
	selected_building = building
	selected_building.show_outline()


## 건물 선택 해제
func _deselect_building() -> void:
	if selected_building:
		selected_building.hide_outline()
		selected_building = null
		print("[Main] 건물 선택 해제")


## 상태를 문자열로 변환 (디버그용)
func _state_to_string(state) -> String:
	match state:
		BuildingEntity.BuildingState.NORMAL:
			return "NORMAL (흰색)"
		BuildingEntity.BuildingState.INFECTING:
			return "INFECTING (노란색)"
		BuildingEntity.BuildingState.INFECTED:
			return "INFECTED (빨간색)"
		_:
			return "UNKNOWN"
