# UI 시스템 설계 (UI System Design)

## 1. 개요

타이쿤/RTS 게임의 **모든 UI 시스템**을 다루는 설계 문서입니다.

### 1.1. 핵심 원칙

**점진적 개발: 최소 → 동적 → 고급**

```
Phase 1: 최소 UI (하드코딩, 30분)
    ↓
Phase 2: 데이터 기반 (Resource 연동, 1시간)
    ↓
Phase 3: 고급 기능 (애니메이션, 툴팁 등)
```

**왜 이 순서인가?**
- ✅ Phase 1에서 **즉시 시각적 피드백** (개발 재미)
- ✅ Phase 2에서 **확장성 확보** (새 건물 추가 쉬움)
- ✅ Phase 3는 **선택사항** (게임 완성도)

### 1.2. UI 구성 요소

| 우선순위 | UI 요소 | 설명 | Phase |
|---------|---------|------|-------|
| **P0** | 건설 메뉴 | 건물 선택 버튼 | 1 |
| **P1** | HUD | 자원, 인구 표시 | 2 |
| P2 | 정보 패널 | 건물/유닛 정보 | 3 |
| P2 | 미니맵 | 맵 전체 뷰 | 3 |
| P3 | 설정 메뉴 | 게임 설정 | 3 |

---

## 2. UI 전체 아키텍처

### 2.1. 씬 구조 (CanvasLayer 기반)

**test_map.tscn 구조:**

```
TestMap (Node2D)
├── World (Node2D)
│   ├── GroundTileMapLayer
│   └── Entities
├── Camera (Camera2D)
├── Managers
│   ├── BuildingManager
│   └── ConstructionManager
└── UI (CanvasLayer) ⭐ 모든 UI는 여기
    ├── ConstructionMenu (Control)     # 건설 메뉴
    ├── HUD (Control)                  # 상단 HUD
    ├── InfoPanel (Control)            # 정보 패널
    └── Minimap (Control)              # 미니맵
```

### 2.2. CanvasLayer 설정

```gdscript
# UI (CanvasLayer)
layer = 10  # 항상 게임 월드 위에 표시
follow_viewport_enabled = false  # 카메라 이동에 영향 없음
```

### 2.3. UI 좌표 시스템

**중요:** UI는 **화면 좌표** 사용, 게임 월드와 분리됨

```gdscript
# ❌ 잘못된 예: UI가 월드 좌표 사용
var building_pos = BuildingManager.get_building_position()
info_panel.position = building_pos  # 카메라 이동 시 UI도 따라감!

# ✅ 올바른 예: 월드 → 화면 좌표 변환
var building_world_pos = BuildingManager.get_building_position()
var screen_pos = get_viewport().get_camera_2d().unproject_position(building_world_pos)
info_panel.position = screen_pos
```

### 2.4. 입력 처리 우선순위

**Godot의 입력 처리 순서:**

```
1. GUI (Control 노드) ← 최우선
   ↓ (처리 안 됨)
2. _input() (모든 노드)
   ↓ (처리 안 됨)
3. _unhandled_input() (배경 클릭 등)
```

**활용:**
- UI 버튼 클릭 → GUI에서 처리 (끝)
- 빈 공간 클릭 → _unhandled_input()에서 처리

```gdscript
# scripts/ui/construction_menu.gd
func _on_button_pressed():
    # UI 버튼 처리
    get_viewport().set_input_as_handled()  # 다른 입력 무시
```

---

## 3. 건설 메뉴 (Construction Menu)

타이쿤 게임의 **핵심 UI**입니다.

### 3.1. Phase 1: 최소 UI (하단 바, 모바일 호환) ⭐ 30분 완성

**목표:** 하단 고정 바로 건물 배치 테스트 (모바일 호환)

#### 씬 구조

**파일:** `scenes/ui/construction_menu.tscn`

```
ConstructionMenu (Control, Full Rect)
├── CollapsedBar (Panel)  # 접힌 상태 바 (하단 50px)
│   └── ExpandButton (Button, text: "건설 ▲")
└── ExpandedPanel (Panel)  # 펼쳐진 상태 (하단 200px)
    ├── Header (HBoxContainer)
    │   ├── TitleLabel (Label, text: "건설 메뉴")
    │   └── CollapseButton (Button, text: "▼ 접기")
    └── Content (VBoxContainer)
        └── ScrollContainer (horizontal)
            └── BuildingList (HBoxContainer)  # 가로 배치!
                ├── HouseButton (Button: "주택")
                ├── FarmButton (Button: "농장")
                └── ShopButton (Button: "상점")
```

#### 스크립트 (하단 바 버전)

**파일:** `scripts/ui/construction_menu.gd`

```gdscript
# scripts/ui/construction_menu.gd
extends Control

# 건물 씬 (하드코딩)
const HOUSE_SCENE = preload("res://scenes/entity/building_entity.tscn")
const FARM_SCENE = preload("res://scenes/entity/building_entity.tscn")  # 일단 같은 씬
const SHOP_SCENE = preload("res://scenes/entity/building_entity.tscn")

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
    # 시그널 연결
    expand_button.pressed.connect(_on_expand_button_pressed)
    collapse_button.pressed.connect(_on_collapse_button_pressed)

    house_button.pressed.connect(_on_house_button_pressed)
    farm_button.pressed.connect(_on_farm_button_pressed)
    shop_button.pressed.connect(_on_shop_button_pressed)

    # 초기 상태: 접힘
    _set_collapsed()

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

# 상태 변경: 접힘
func _set_collapsed():
    is_expanded = false
    collapsed_bar.visible = true
    expanded_panel.visible = false

func _on_house_button_pressed():
    # ConstructionManager에 건물 선택 알림
    var construction_manager = get_node("/root/TestMap/Managers/ConstructionManager")
    construction_manager.select_building_scene(HOUSE_SCENE, "주택")
    # ⭐ 메뉴 유지 (닫지 않음) - 빠른 재선택 가능
    get_viewport().set_input_as_handled()

func _on_farm_button_pressed():
    var construction_manager = get_node("/root/TestMap/Managers/ConstructionManager")
    construction_manager.select_building_scene(FARM_SCENE, "농장")
    # ⭐ 메뉴 유지
    get_viewport().set_input_as_handled()

func _on_shop_button_pressed():
    var construction_manager = get_node("/root/TestMap/Managers/ConstructionManager")
    construction_manager.select_building_scene(SHOP_SCENE, "상점")
    # ⭐ 메뉴 유지
    get_viewport().set_input_as_handled()
```

#### ConstructionManager 간단 버전

**파일:** `scripts/managers/construction_manager.gd` (Phase 1용)

```gdscript
# scripts/managers/construction_manager.gd
extends Node

var selected_building_scene: PackedScene = null
var selected_building_name: String = ""
var preview_sprite: Sprite2D = null

signal building_selected(scene: PackedScene, name: String)

func _ready():
    # 미리보기 스프라이트
    preview_sprite = Sprite2D.new()
    preview_sprite.modulate = Color(1, 1, 1, 0.5)
    preview_sprite.z_index = 100
    preview_sprite.visible = false
    add_child(preview_sprite)

# Phase 1: 씬 직접 받기 (하드코딩)
func select_building_scene(scene: PackedScene, building_name: String):
    selected_building_scene = scene
    selected_building_name = building_name

    # 미리보기 텍스처 설정
    var temp_instance = scene.instantiate()
    var sprite = temp_instance.get_node("Sprite2D") as Sprite2D
    if sprite:
        preview_sprite.texture = sprite.texture
        preview_sprite.visible = true
    temp_instance.queue_free()

    building_selected.emit(scene, building_name)

func _process(delta):
    if not selected_building_scene:
        return

    # 마우스 위치에 미리보기 업데이트
    var mouse_pos = get_viewport().get_mouse_position()
    var camera = get_viewport().get_camera_2d()
    var world_pos = mouse_pos
    if camera:
        world_pos = camera.get_global_mouse_position()

    var grid_pos = GridSystem.world_to_grid(world_pos)
    var snap_world_pos = GridSystem.grid_to_world(grid_pos)
    preview_sprite.global_position = snap_world_pos

    # 건설 가능 여부 색상
    if can_build_at(grid_pos):
        preview_sprite.modulate = Color(0.5, 1, 0.5, 0.7)  # 녹색
    else:
        preview_sprite.modulate = Color(1, 0.5, 0.5, 0.7)  # 빨간색

func _unhandled_input(event):
    if not selected_building_scene:
        return

    # ESC로 취소
    if event.is_action_pressed("ui_cancel"):
        cancel_construction()
        get_viewport().set_input_as_handled()
        return

    # 클릭으로 배치
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var mouse_pos = get_viewport().get_mouse_position()
        var camera = get_viewport().get_camera_2d()
        var world_pos = mouse_pos
        if camera:
            world_pos = camera.get_global_mouse_position()

        var grid_pos = GridSystem.world_to_grid(world_pos)

        if try_place_building(grid_pos):
            cancel_construction()

        get_viewport().set_input_as_handled()

func can_build_at(grid_pos: Vector2i) -> bool:
    if not GridSystem.is_valid_position(grid_pos):
        return false
    if BuildingManager.has_building_at(grid_pos):
        return false
    return true

func try_place_building(grid_pos: Vector2i) -> bool:
    if not can_build_at(grid_pos):
        return false

    var building = selected_building_scene.instantiate()
    building.global_position = GridSystem.grid_to_world(grid_pos)

    BuildingManager.add_building(building, grid_pos)
    print("[건설] %s 건설 완료: %s" % [selected_building_name, grid_pos])
    return true

func cancel_construction():
    selected_building_scene = null
    selected_building_name = ""
    preview_sprite.visible = false
```

#### 레이아웃 설정

**CollapsedBar (접힌 바):**
```gdscript
# Inspector 설정:
- Layout: Bottom (Full Width)
- Anchor Left: 0, Right: 1, Top: 1, Bottom: 1
- Offset Top: -50, Bottom: 0
- Size: (화면 너비, 50)
```

**ExpandedPanel (펼쳐진 패널):**
```gdscript
# Inspector 설정:
- Layout: Bottom (Full Width)
- Anchor Left: 0, Right: 1, Top: 1, Bottom: 1
- Offset Top: -200, Bottom: 0
- Size: (화면 너비, 200)
- Visible: false (초기 숨김)
```

**ScrollContainer:**
```gdscript
# Inspector 설정:
- Horizontal Scroll: Enabled
- Vertical Scroll: Disabled
```

#### 테스트 시나리오

**30분 안에 완성 후 테스트:**

1. ✅ F5로 게임 실행
2. ✅ 하단에 "건설 ▲" 바 표시 확인
3. ✅ "건설 ▲" 버튼 클릭 → 메뉴 펼쳐짐
4. ✅ "주택" 버튼 클릭
5. ✅ 마우스 따라다니는 반투명 건물 표시
6. ✅ 녹색/빨간색으로 건설 가능 여부 표시
7. ✅ 클릭으로 건물 배치
8. ✅ 메뉴가 펼쳐진 상태 유지 (빠른 재선택 가능)
9. ✅ "▼ 접기" 버튼 클릭 → 메뉴 접힘
10. ✅ ESC로 건설 취소

**결과:** 모바일 호환 하단 바 UI 완성! 🎉

---

### 3.2. Phase 2: Resource 기반 동적 UI

**목표:** BuildingData Resource로 버튼 자동 생성 (하단 바 유지)

#### 업그레이드된 씬 구조

**파일:** `scenes/ui/construction_menu.tscn`

```
ConstructionMenu (Control, Full Rect)
├── CollapsedBar (Panel)
│   └── ExpandButton (Button, "건설 ▲")
└── ExpandedPanel (Panel)
    ├── Header (HBoxContainer)
    │   ├── TitleLabel (Label: "건설 메뉴")
    │   └── CollapseButton (Button, "▼ 접기")
    └── Content (VBoxContainer)
        └── ScrollContainer (horizontal)
            └── BuildingListContainer (HBoxContainer) ← 동적 생성
```

#### 동적 버튼 생성 스크립트

**파일:** `scripts/ui/construction_menu.gd`

```gdscript
# scripts/ui/construction_menu.gd
extends Control

# 노드 참조
@onready var collapsed_bar: Panel = $CollapsedBar
@onready var expanded_panel: Panel = $ExpandedPanel
@onready var expand_button: Button = $CollapsedBar/ExpandButton
@onready var collapse_button: Button = $ExpandedPanel/Header/CollapseButton
@onready var building_list_container: HBoxContainer = $ExpandedPanel/Content/ScrollContainer/BuildingListContainer

# BuildingButton 씬 (프리팹)
const BuildingButtonScene = preload("res://scenes/ui/building_button.tscn")

# 상태
var is_expanded: bool = false

func _ready():
    # 시그널 연결
    expand_button.pressed.connect(_on_expand_button_pressed)
    collapse_button.pressed.connect(_on_collapse_button_pressed)

    # 초기 상태: 접힘
    _set_collapsed()

    populate_buildings()

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

# 상태 변경: 접힘
func _set_collapsed():
    is_expanded = false
    collapsed_bar.visible = true
    expanded_panel.visible = false

# Resource 기반 동적 버튼 생성
func populate_buildings():
    # 기존 버튼 제거
    for child in building_list_container.get_children():
        child.queue_free()

    # 카테고리별 분류
    var categories = [
        BuildingData.BuildingCategory.RESIDENTIAL,
        BuildingData.BuildingCategory.PRODUCTION,
        BuildingData.BuildingCategory.MILITARY,
        BuildingData.BuildingCategory.DECORATION
    ]

    var category_names = {
        BuildingData.BuildingCategory.RESIDENTIAL: "🏠 주거",
        BuildingData.BuildingCategory.PRODUCTION: "🏭 생산",
        BuildingData.BuildingCategory.MILITARY: "⚔️ 군사",
        BuildingData.BuildingCategory.DECORATION: "🌳 장식"
    }

    for category in categories:
        var buildings = EntityDatabase.get_buildings_by_category(category)

        if buildings.is_empty():
            continue

        # 카테고리 라벨
        var label = Label.new()
        label.text = category_names[category]
        label.add_theme_font_size_override("font_size", 18)
        building_list_container.add_child(label)

        # 건물 버튼들
        for building_data in buildings:
            var button = BuildingButtonScene.instantiate()
            button.set_building_data(building_data)
            button.pressed.connect(_on_building_button_pressed.bind(building_data))
            building_list_container.add_child(button)

func _on_building_button_pressed(building_data: BuildingData):
    # ConstructionManager에 Resource 전달
    ConstructionManager.select_building(building_data)
    # ⭐ 메뉴 유지 (닫지 않음) - 빠른 재선택 가능
```

#### BuildingButton 프리팹

**씬:** `scenes/ui/building_button.tscn`

```
BuildingButton (Button)
└── HBoxContainer
    ├── Icon (TextureRect, 64x64)
    └── VBoxContainer
        ├── NameLabel (Label)
        └── CostLabel (Label)
```

**스크립트:** `scripts/ui/building_button.gd`

```gdscript
# scripts/ui/building_button.gd
extends Button

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var cost_label: Label = $HBoxContainer/VBoxContainer/CostLabel

var building_data: BuildingData

func set_building_data(data: BuildingData):
    building_data = data

    # 아이콘
    icon.texture = data.icon

    # 이름
    name_label.text = data.building_name

    # 비용
    var cost_parts = []
    if data.cost_wood > 0:
        cost_parts.append("🪵 %d" % data.cost_wood)
    if data.cost_stone > 0:
        cost_parts.append("🪨 %d" % data.cost_stone)
    if data.cost_gold > 0:
        cost_parts.append("💰 %d" % data.cost_gold)

    cost_label.text = " ".join(cost_parts)

func _process(delta):
    # 자원 부족 시 비활성화 (ResourceManager 필요)
    # disabled = not ResourceManager.can_afford(building_data.get_total_cost())
    pass
```

#### ConstructionManager 업그레이드

**파일:** `scripts/managers/construction_manager.gd` (Phase 2용)

```gdscript
# scripts/managers/construction_manager.gd
extends Node

var selected_building_data: BuildingData = null  # Resource로 변경
var preview_sprite: Sprite2D = null

func select_building(building_data: BuildingData):
    selected_building_data = building_data

    # 미리보기 텍스처
    var temp_instance = building_data.scene_to_spawn.instantiate()
    var sprite = temp_instance.get_node("Sprite2D") as Sprite2D
    if sprite:
        preview_sprite.texture = sprite.texture
        preview_sprite.visible = true
    temp_instance.queue_free()

func try_place_building(grid_pos: Vector2i) -> bool:
    if not can_build_at(grid_pos):
        return false

    # Resource에서 씬 로드
    var building = selected_building_data.scene_to_spawn.instantiate()
    building.global_position = GridSystem.grid_to_world(grid_pos)

    # 건물에 데이터 전달 (옵션)
    if building.has_method("set_entity_data"):
        building.set_entity_data(selected_building_data)

    BuildingManager.add_building(building, grid_pos)

    # 자원 소비 (ResourceManager 필요)
    # ResourceManager.consume_resources(selected_building_data.get_total_cost())

    print("[건설] %s 건설 완료: %s" % [selected_building_data.building_name, grid_pos])
    return true
```

---

### 3.3. Phase 3: 고급 기능

#### 3.3.1. 탭 시스템 (카테고리별)

```
ConstructionMenu
└── TabContainer
    ├── 주거 (Tab)
    │   └── HouseButton, ApartmentButton...
    ├── 생산 (Tab)
    │   └── FarmButton, MineButton...
    └── 군사 (Tab)
        └── BarracksButton, TowerButton...
```

#### 3.3.2. 툴팁 시스템

```gdscript
# scripts/ui/building_button.gd에 추가
func _on_mouse_entered():
    var tooltip = get_node("/root/UI/Tooltip")
    tooltip.show_building_info(building_data)
    tooltip.global_position = global_position + Vector2(0, -100)

func _on_mouse_exited():
    var tooltip = get_node("/root/UI/Tooltip")
    tooltip.hide()
```

#### 3.3.3. 건설 불가 메시지

```gdscript
# ConstructionManager에 추가
func try_place_building(grid_pos: Vector2i) -> bool:
    if not GridSystem.is_valid_position(grid_pos):
        show_message("맵 범위를 벗어났습니다")
        return false

    if BuildingManager.has_building_at(grid_pos):
        show_message("이미 건물이 있습니다")
        return false

    # if not ResourceManager.can_afford(...):
    #     show_message("자원이 부족합니다")
    #     return false

    # 건설 성공
    return true

func show_message(text: String):
    var message_label = get_node("/root/UI/MessageLabel")
    message_label.text = text
    message_label.visible = true
    # 3초 후 자동 숨김
    await get_tree().create_timer(3.0).timeout
    message_label.visible = false
```

---

## 4. HUD (Head-Up Display)

게임 정보를 상단에 표시하는 UI입니다.

### 4.1. 기본 HUD

**씬:** `scenes/ui/hud.tscn`

```
HUD (Control)
└── Panel
    └── HBoxContainer
        ├── ResourcesContainer (HBoxContainer)
        │   ├── WoodLabel (Label: "🪵 500")
        │   ├── StoneLabel (Label: "🪨 300")
        │   └── GoldLabel (Label: "💰 1000")
        ├── Spacer (Control, size_flags_horizontal: EXPAND)
        └── PopulationLabel (Label: "👥 10/50")
```

**스크립트:** `scripts/ui/hud.gd`

```gdscript
# scripts/ui/hud.gd
extends Control

@onready var wood_label: Label = $Panel/HBoxContainer/ResourcesContainer/WoodLabel
@onready var stone_label: Label = $Panel/HBoxContainer/ResourcesContainer/StoneLabel
@onready var gold_label: Label = $Panel/HBoxContainer/ResourcesContainer/GoldLabel
@onready var population_label: Label = $Panel/HBoxContainer/PopulationLabel

func _ready():
    # ResourceManager 시그널 연결 (미래)
    # ResourceManager.resources_changed.connect(_on_resources_changed)
    update_display()

func _process(delta):
    # 임시: 매 프레임 업데이트 (나중에 시그널로 변경)
    update_display()

func update_display():
    # ResourceManager에서 데이터 가져오기 (미래)
    # var resources = ResourceManager.get_all_resources()
    # wood_label.text = "🪵 %d" % resources.wood

    # 임시 하드코딩
    wood_label.text = "🪵 500"
    stone_label.text = "🪨 300"
    gold_label.text = "💰 1000"
    population_label.text = "👥 10/50"
```

### 4.2. HUD 배치

```gdscript
# HUD (Control) 설정
# Inspector:
# - Layout → Anchors Preset: Top Wide
# - Layout → Position: (0, 0)
# - Layout → Size: (화면 너비, 60)
```

---

## 5. 정보 패널 (Info Panel)

건물/유닛 선택 시 정보를 표시합니다.

### 5.1. 건물 정보 패널

**씬:** `scenes/ui/building_info_panel.tscn`

```
BuildingInfoPanel (Control)
└── Panel
    └── VBoxContainer
        ├── NameLabel (Label)
        ├── DescriptionLabel (Label)
        ├── HSeparator
        ├── StatsContainer (VBoxContainer)
        │   ├── HealthLabel (Label: "HP: 500/500")
        │   └── LevelLabel (Label: "레벨: 1")
        └── ButtonsContainer (HBoxContainer)
            ├── UpgradeButton (Button: "업그레이드")
            └── DestroyButton (Button: "철거")
```

**스크립트:** `scripts/ui/building_info_panel.gd`

```gdscript
# scripts/ui/building_info_panel.gd
extends Control

@onready var name_label: Label = $Panel/VBoxContainer/NameLabel
@onready var description_label: Label = $Panel/VBoxContainer/DescriptionLabel
@onready var health_label: Label = $Panel/VBoxContainer/StatsContainer/HealthLabel
@onready var upgrade_button: Button = $Panel/VBoxContainer/ButtonsContainer/UpgradeButton
@onready var destroy_button: Button = $Panel/VBoxContainer/ButtonsContainer/DestroyButton

var current_building: Node2D = null

func _ready():
    visible = false
    upgrade_button.pressed.connect(_on_upgrade_button_pressed)
    destroy_button.pressed.connect(_on_destroy_button_pressed)

func show_building_info(building: Node2D):
    current_building = building

    # BuildingEntity가 entity_data를 가지고 있다고 가정
    if building.has_method("get_entity_data"):
        var data = building.get_entity_data()
        name_label.text = data.building_name
        description_label.text = data.description

    # 체력 정보
    if building.has_method("get_health"):
        var current_hp = building.get_health()
        var max_hp = building.get_max_health()
        health_label.text = "HP: %d/%d" % [current_hp, max_hp]

    visible = true

    # 건물 위치 위에 패널 배치
    position_above_building(building)

func position_above_building(building: Node2D):
    var camera = get_viewport().get_camera_2d()
    if camera:
        var building_screen_pos = camera.unproject_position(building.global_position)
        global_position = building_screen_pos + Vector2(-100, -200)

func hide_panel():
    visible = false
    current_building = null

func _on_upgrade_button_pressed():
    # 업그레이드 로직 (미래)
    print("업그레이드 버튼 클릭")

func _on_destroy_button_pressed():
    if current_building:
        # 건물 철거
        BuildingManager.remove_building(current_building)
        hide_panel()
```

### 5.2. 선택 시스템 연동

```gdscript
# scripts/managers/selection_manager.gd
signal building_selected(building: Node2D)
signal building_deselected()

func select_building(building: Node2D):
    current_selection = building

    # 정보 패널 표시
    var info_panel = get_node("/root/UI/BuildingInfoPanel")
    info_panel.show_building_info(building)

    building_selected.emit(building)

func deselect():
    current_selection = null

    # 정보 패널 숨김
    var info_panel = get_node("/root/UI/BuildingInfoPanel")
    info_panel.hide_panel()

    building_deselected.emit()
```

---

## 6. 미니맵 (Minimap)

맵 전체를 축소해서 보여주는 UI입니다.

### 6.1. 기본 미니맵

**씬:** `scenes/ui/minimap.tscn`

```
Minimap (Control)
└── Panel
    ├── ViewportContainer
    │   └── SubViewport
    │       └── MinimapCamera (Camera2D)
    └── CameraRect (ColorRect) # 현재 카메라 위치 표시
```

**스크립트:** `scripts/ui/minimap.gd`

```gdscript
# scripts/ui/minimap.gd
extends Control

@onready var sub_viewport: SubViewport = $Panel/ViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $Panel/ViewportContainer/SubViewport/MinimapCamera
@onready var camera_rect: ColorRect = $Panel/CameraRect

var main_camera: Camera2D

func _ready():
    # 메인 카메라 찾기
    main_camera = get_viewport().get_camera_2d()

    # 미니맵 카메라 설정
    minimap_camera.zoom = Vector2(0.1, 0.1)  # 10배 축소

func _process(delta):
    if not main_camera:
        return

    # 미니맵 카메라를 메인 카메라와 동기화
    minimap_camera.global_position = main_camera.global_position

    # 현재 카메라 범위 표시
    update_camera_rect()

func update_camera_rect():
    # 메인 카메라의 화면 범위 계산
    var viewport_size = get_viewport().get_visible_rect().size
    var camera_zoom = main_camera.zoom

    # 미니맵 좌표로 변환
    var rect_size = viewport_size / camera_zoom / 10.0  # 10.0 = minimap zoom

    camera_rect.size = rect_size
    camera_rect.position = (size / 2) - (rect_size / 2)
```

### 6.2. 미니맵 클릭으로 카메라 이동

```gdscript
# scripts/ui/minimap.gd에 추가
func _on_panel_gui_input(event):
    if event is InputEventMouseButton and event.pressed:
        # 클릭 위치를 월드 좌표로 변환
        var click_pos = event.position
        var minimap_center = size / 2
        var offset = click_pos - minimap_center

        # 메인 카메라 이동
        main_camera.global_position += offset * 10.0  # 10.0 = zoom 배율
```

---

## 7. 입력 처리 시스템

### 7.1. 입력 우선순위 관리

**문제:** UI 버튼 클릭 시 배경도 클릭됨

**해결:**

```gdscript
# 모든 UI 버튼 클릭 핸들러에 추가
func _on_button_pressed():
    # ... 로직 ...
    get_viewport().set_input_as_handled()  # ✅ 다른 입력 무시
```

### 7.2. 단축키 시스템

**프로젝트 설정 → Input Map:**

```
toggle_construction_menu: B
toggle_hud: H
open_minimap: M
cancel_action: ESC
quick_save: F5
quick_load: F9
```

**전역 입력 처리:**

```gdscript
# scripts/managers/input_manager.gd (Autoload)
extends Node

func _input(event):
    # ESC: 모든 UI 닫기
    if event.is_action_pressed("cancel_action"):
        close_all_ui()
        get_viewport().set_input_as_handled()

    # B: 건설 메뉴 토글
    if event.is_action_pressed("toggle_construction_menu"):
        var menu = get_node("/root/UI/ConstructionMenu")
        menu.visible = !menu.visible
        get_viewport().set_input_as_handled()

func close_all_ui():
    var ui_root = get_node("/root/UI")
    for child in ui_root.get_children():
        if child is Control and child.has_method("hide"):
            child.hide()
```

---

## 8. 테마 시스템 (Theme)

일관된 UI 스타일을 위한 테마 설정입니다.

### 8.1. 테마 리소스 생성

**파일:** `resources/ui/main_theme.tres`

```
Godot 에디터:
1. FileSystem → resources/ui/ 폴더 생성
2. 우클릭 → Create New → Theme
3. 이름: main_theme.tres
4. 더블클릭으로 테마 에디터 열기
```

### 8.2. 테마 설정 예시

**Button 스타일:**

```
Theme → Button:
- Font Size: 16
- Normal: StyleBoxFlat (배경색: #2c3e50)
- Hover: StyleBoxFlat (배경색: #34495e)
- Pressed: StyleBoxFlat (배경색: #1a252f)
- Font Color: #ecf0f1
```

**Panel 스타일:**

```
Theme → Panel:
- Panel: StyleBoxFlat
  - Background Color: #2c3e50 (80% 투명도)
  - Border Width: 2
  - Border Color: #34495e
  - Corner Radius: 5
```

### 8.3. 테마 적용

**모든 UI에 적용:**

```gdscript
# UI (CanvasLayer) 노드에 설정
# Inspector → Theme → main_theme.tres 드래그
```

또는 개별 Control 노드에:

```gdscript
# Inspector → Theme → main_theme.tres
```

---

## 9. 구현 순서 (전체 로드맵)

### Week 1: 최소 UI (즉시 테스트 가능)

**Day 1-2: 건설 메뉴 (Phase 1)**
- [ ] SimpleConstructionMenu.tscn 생성
- [ ] 버튼 3개 (주택, 농장, 상점)
- [ ] ConstructionManager 간단 버전
- [ ] B 키로 열기/닫기
- [ ] 테스트: 건물 배치 성공

**Day 3-4: 기본 HUD**
- [ ] HUD.tscn 생성
- [ ] 자원 표시 (하드코딩)
- [ ] 인구 표시 (하드코딩)

---

### Week 2: Resource 통합

**Day 5-7: Resource 시스템**
- [ ] EntityData.gd, BuildingData.gd 작성
- [ ] house_01.tres, farm_01.tres, shop_01.tres 생성
- [ ] BuildingDatabase.gd 작성

**Day 8-10: 건설 메뉴 (Phase 2)**
- [ ] ConstructionMenu.tscn (동적 버전)
- [ ] BuildingButton.tscn 프리팹
- [ ] populate_buildings() 구현
- [ ] 테스트: Resource 기반 동작 확인

---

### Week 3: 고급 기능

**Day 11-13: 정보 패널**
- [ ] BuildingInfoPanel.tscn 생성
- [ ] 건물 선택 시스템 연동
- [ ] 업그레이드/철거 버튼

**Day 14-15: 미니맵**
- [ ] Minimap.tscn 생성
- [ ] SubViewport 설정
- [ ] 카메라 범위 표시
- [ ] 클릭으로 이동

---

### Week 4: 폴리싱

**Day 16-18: 테마 적용**
- [ ] main_theme.tres 생성
- [ ] 모든 UI에 테마 적용
- [ ] 색상/폰트 통일

**Day 19-20: 고급 기능**
- [ ] 툴팁 시스템
- [ ] 건설 불가 메시지
- [ ] 애니메이션 효과

---

## 10. 폴더 구조 (최종)

```
scenes/
└── ui/
    ├── simple_construction_menu.tscn    # Phase 1
    ├── construction_menu.tscn           # Phase 2
    ├── building_button.tscn             # 건물 버튼 프리팹
    ├── hud.tscn                         # HUD
    ├── building_info_panel.tscn         # 정보 패널
    ├── minimap.tscn                     # 미니맵
    └── tooltip.tscn                     # 툴팁

scripts/
└── ui/
    ├── simple_construction_menu.gd
    ├── construction_menu.gd
    ├── building_button.gd
    ├── hud.gd
    ├── building_info_panel.gd
    ├── minimap.gd
    └── tooltip.gd

resources/
└── ui/
    └── main_theme.tres                  # UI 테마
```

---

## 11. 참고 문서

- `docs/design/building_construction_system_design.md`: Resource 시스템
- `docs/design/resource_based_entity_design.md`: Resource 패턴
- `docs/prd.md`: UI 시스템 요구사항 (2.8)
- Godot 공식 문서:
  - [Control 노드](https://docs.godotengine.org/en/stable/classes/class_control.html)
  - [CanvasLayer](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html)
  - [Theme](https://docs.godotengine.org/en/stable/classes/class_theme.html)

---

## 12. 체크리스트

### Phase 1: 최소 UI (30분)
- [ ] SimpleConstructionMenu.tscn 생성
- [ ] 버튼 3개 추가
- [ ] ConstructionManager 간단 버전
- [ ] B 키로 열기/닫기 동작
- [ ] 건물 배치 테스트 성공

### Phase 2: Resource 통합 (2시간)
- [ ] BuildingData.gd 작성
- [ ] .tres 파일 3개 생성
- [ ] ConstructionMenu 동적 버전
- [ ] BuildingButton 프리팹
- [ ] Resource 기반 동작 확인

### Phase 3: 추가 UI (4시간)
- [ ] HUD 생성 및 표시
- [ ] BuildingInfoPanel 생성
- [ ] Minimap 생성
- [ ] 테마 적용

---

## 13. 결론

**핵심 원칙:**

1. **최소 UI 먼저** (30분)
   - 버튼 3개로 즉시 테스트
   - 시각적 피드백 확보

2. **Resource 통합** (2시간)
   - 데이터 주도 설계
   - 확장성 확보

3. **고급 기능은 나중에**
   - 게임이 동작한 후 추가
   - 우선순위에 따라 선택

**다음 단계:**
- Phase 1부터 바로 시작 가능
- SimpleConstructionMenu.tscn 생성
- 30분 안에 동작하는 UI 완성!

**성공 지표:**
- ✅ B 키로 메뉴 열림
- ✅ 버튼 클릭으로 건물 선택
- ✅ 마우스 미리보기 동작
- ✅ 클릭으로 건물 배치 성공

이제 **즉시 개발 시작** 가능합니다! 🚀
