# scripts/ui/construction_menu.gd
extends Control

# 노드 참조
@onready var collapsed_bar: Panel = $CollapsedBar
@onready var expanded_panel: Panel = $ExpandedPanel
@onready var expand_button: Button = $CollapsedBar/ExpandButton
@onready var collapse_button: Button = $ExpandedPanel/Header/CollapseButton

@onready var house_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/HouseButton
@onready var farm_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/FarmButton
@onready var shop_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/ShopButton

# 상태
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
	_set_collapsed()

	print("[Phase 1] ConstructionMenu 준비 완료 (하단 바)")

# 펼치기
func _on_expand_button_pressed():
	_set_expanded()

# 접기
func _on_collapse_button_pressed():
	_set_collapsed()

# 상태 변경: 펼침
func _set_expanded():
	is_expanded = true
	collapsed_bar.visible = false
	expanded_panel.visible = true
	print("[Phase 1] 메뉴 펼침")

# 상태 변경: 접힘
func _set_collapsed():
	is_expanded = false
	collapsed_bar.visible = true
	expanded_panel.visible = false
	print("[Phase 1] 메뉴 접힘")

# ⭐ Resource 없이 로그만 출력!
func _on_house_button_pressed():
	print("[Phase 1] 주택 버튼 클릭!")
	get_viewport().set_input_as_handled()

func _on_farm_button_pressed():
	print("[Phase 1] 농장 버튼 클릭!")
	get_viewport().set_input_as_handled()

func _on_shop_button_pressed():
	print("[Phase 1] 상점 버튼 클릭!")
	get_viewport().set_input_as_handled()
