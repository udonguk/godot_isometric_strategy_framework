# scripts/ui/construction_menu.gd
extends Control

## 건설 메뉴 UI 컨트롤러
## 접힘/펼침 상태를 관리하고 건물 선택 이벤트를 처리합니다.

# ============================================================
# Signals
# ============================================================

## 메뉴의 확장 상태가 변경될 때 발생
## @param expanded: true면 펼쳐진 상태, false면 접힌 상태
signal expansion_state_changed(expanded: bool)


# ============================================================
# 노드 참조
# ============================================================

@onready var collapsed_bar: Panel = $CollapsedBar
@onready var expanded_panel: Panel = $ExpandedPanel
@onready var expand_button: Button = $CollapsedBar/ExpandButton
@onready var collapse_button: Button = $ExpandedPanel/Header/CollapseButton

@onready var house_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/HouseButton
@onready var farm_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/FarmButton
@onready var shop_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/ShopButton


# ============================================================
# 의존성
# ============================================================

## BuildingManager 참조 (의존성 주입)
var building_manager = null


# ============================================================
# 상태
# ============================================================

## 메뉴가 펼쳐져 있는지 여부
var is_expanded: bool = false

func _ready():
	# 배경색 설정 (반투명 검은색)
	var style_collapsed = StyleBoxFlat.new()
	style_collapsed.bg_color = Color(0, 0, 0, 0.8)  # 반투명 검은색
	collapsed_bar.add_theme_stylebox_override("panel", style_collapsed)

	var style_expanded = StyleBoxFlat.new()
	style_expanded.bg_color = Color(0, 0, 0, 0.8)
	expanded_panel.add_theme_stylebox_override("panel", style_expanded)

	# 시그널 연결
	expand_button.pressed.connect(_on_expand_button_pressed)
	collapse_button.pressed.connect(_on_collapse_button_pressed)

	house_button.pressed.connect(_on_house_button_pressed)
	farm_button.pressed.connect(_on_farm_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)

	# 초기 상태: 접힘
	set_expansion_state(false)


## 입력 이벤트 처리 (ESC 키로 건설 취소)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC 키
		if building_manager and building_manager.is_in_placement_mode():
			building_manager.cancel_building_placement()
			get_viewport().set_input_as_handled()


# ============================================================
# 공개 API
# ============================================================

## ConstructionMenu 초기화 (BuildingManager 연동)
##
## @param manager: BuildingManager 인스턴스 (의존성 주입)
##
## 💡 설계 의도:
## - UI/Logic 분리 원칙 준수
## - BuildingManager를 의존성 주입으로 전달받아 결합도 감소
## - BuildingManager 시그널을 구독하여 상태 변화 감지
func initialize(manager) -> void:
	if not manager:
		push_error("[ConstructionMenu] BuildingManager가 null입니다")
		return

	building_manager = manager

	# BuildingManager 시그널 연결
	building_manager.building_placement_started.connect(_on_placement_started)
	building_manager.building_placed.connect(_on_building_placed)
	building_manager.building_placement_failed.connect(_on_placement_failed)


## 메뉴의 확장 상태를 설정합니다.
##
## @param expanded: true면 메뉴를 펼치고, false면 접습니다.
##
## ✅ Hidden Dependency 제거: 상태를 파라미터로 명시적으로 전달
## ✅ 단일 진입점: _set_expanded()/_set_collapsed() 대신 하나의 메서드로 통합
## ✅ Signal 발생: 상태 변경 시 다른 시스템에 알림 가능
func set_expansion_state(expanded: bool) -> void:
	# 동일한 상태로 변경 시 무시 (불필요한 Signal 방지)
	if is_expanded == expanded:
		return

	is_expanded = expanded
	_update_ui_visibility(expanded)
	expansion_state_changed.emit(is_expanded)


# ============================================================
# 버튼 이벤트 핸들러
# ============================================================

## 펼치기 버튼 클릭 시 호출
func _on_expand_button_pressed() -> void:
	set_expansion_state(true)


## 접기 버튼 클릭 시 호출
func _on_collapse_button_pressed() -> void:
	set_expansion_state(false)


# ============================================================
# 내부 헬퍼 메서드
# ============================================================

## 확장 상태에 맞게 UI 요소들의 가시성을 업데이트합니다.
##
## @param expanded: true면 expanded_panel을 보이고, false면 collapsed_bar를 보입니다.
##
## 💡 설계 의도: UI 업데이트 로직을 별도 메서드로 분리하여
##    향후 애니메이션 추가나 추가 UI 요소 처리 시 확장 용이
func _update_ui_visibility(expanded: bool) -> void:
	collapsed_bar.visible = not expanded
	expanded_panel.visible = expanded


# ============================================================
# 건물 버튼 이벤트 핸들러
# ============================================================

## 주택 버튼 클릭 시 호출
func _on_house_button_pressed() -> void:
	print("[ConstructionMenu] === 주택 버튼 클릭됨 ===")

	if not building_manager:
		push_error("[ConstructionMenu] BuildingManager가 초기화되지 않았습니다")
		return

	print("[ConstructionMenu] BuildingManager 확인 완료")

	var building_data = BuildingDatabase.get_building_by_id("house_01")
	print("[ConstructionMenu] BuildingDatabase 호출 결과: ", building_data)

	if building_data:
		building_manager.start_building_placement(building_data)
		print("[ConstructionMenu] 주택 건설 모드 시작")
	else:
		push_error("[ConstructionMenu] house_01 데이터를 찾을 수 없습니다")

	get_viewport().set_input_as_handled()


## 농장 버튼 클릭 시 호출
func _on_farm_button_pressed() -> void:
	if not building_manager:
		push_error("[ConstructionMenu] BuildingManager가 초기화되지 않았습니다")
		return

	var building_data = BuildingDatabase.get_building_by_id("farm_01")
	if building_data:
		building_manager.start_building_placement(building_data)
		print("[ConstructionMenu] 농장 건설 모드 시작")
	else:
		push_error("[ConstructionMenu] farm_01 데이터를 찾을 수 없습니다")

	get_viewport().set_input_as_handled()


## 상점 버튼 클릭 시 호출
func _on_shop_button_pressed() -> void:
	if not building_manager:
		push_error("[ConstructionMenu] BuildingManager가 초기화되지 않았습니다")
		return

	var building_data = BuildingDatabase.get_building_by_id("shop_01")
	if building_data:
		building_manager.start_building_placement(building_data)
		print("[ConstructionMenu] 상점 건설 모드 시작")
	else:
		push_error("[ConstructionMenu] shop_01 데이터를 찾을 수 없습니다")

	get_viewport().set_input_as_handled()


# ============================================================
# BuildingManager 시그널 핸들러
# ============================================================

## 건설 모드 시작 시 호출
func _on_placement_started(building_data) -> void:
	print("[ConstructionMenu] 건설 모드 시작: ", building_data.entity_name)
	# TODO: 버튼 강조 표시


## 건물 배치 완료 시 호출
func _on_building_placed(building_data, grid_pos: Vector2i) -> void:
	print("[ConstructionMenu] 건물 배치 완료: ", building_data.entity_name, " at ", grid_pos)
	# TODO: UI 상태 초기화


## 건설 실패 시 호출
func _on_placement_failed(reason: String) -> void:
	print("[ConstructionMenu] 건설 실패: ", reason)
	# TODO: 에러 메시지 표시
