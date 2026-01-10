# 건설 시스템 구현 가이드 (Implementation Guide)

## 📌 개요

이 문서는 **건설 시스템을 실제로 구현하는 단계별 가이드**입니다.

### 핵심 원칙

**완전히 독립적인 4단계로 구현:**

```
Phase 1: 최소 UI (로그만)
    ↓
Phase 2: Resource 시스템 (테스트 함수)
    ↓
Phase 3: ConstructionManager (강제 호출)
    ↓
Phase 4: 통합 (실제 동작)
```

**각 Phase의 독립성:**
- Phase 1과 Phase 2는 **동시 개발 가능** (서로 독립)
- Phase 3은 Phase 2 필요
- Phase 4는 모든 Phase 완료 필요

---

## 🎯 Phase별 개요

| Phase | 목표 | 의존성 | 소요 시간 | 결과물 |
|-------|------|--------|----------|--------|
| **Phase 1** | 최소 UI (로그만) | 없음 | 15분 | 버튼 클릭 시 로그 출력 |
| **Phase 2** | Resource 시스템 | 없음 | 30분 | .tres 파일, 테스트 함수 |
| **Phase 3** | ConstructionManager | Phase 2 | 30분 | 강제 호출로 건물 배치 |
| **Phase 4** | 통합 | 전체 | 15분 | 버튼 → 건물 배치 동작 |

---

## 📋 Phase 1: 최소 UI (하단 바, 로그만)

### 🎯 목표
- 하단 고정 바 UI 구조 생성 (모바일 호환)
- 접힌 상태 (50px) / 펼쳐진 상태 (200px)
- 버튼 3개 (주택, 농장, 상점) 가로 배치
- 펼침/접기 버튼으로 메뉴 제어
- 클릭하면 **콘솔에 로그만 출력**

### 📦 의존성
- 없음 (완전 독립)

### ⏱️ 소요 시간
- 30분

---

### ✅ Todo 체크리스트

- [x] ConstructionMenu.tscn 씬 생성 (Full Rect)
- [x] CollapsedBar (Panel) 추가 - 하단 50px
- [x] ExpandButton 추가 ("건설 ▲")
- [x] ExpandedPanel (Panel) 추가 - 하단 200px
- [x] Header 추가 (TitleLabel + CollapseButton)
- [x] BuildingList (HBoxContainer) 가로 배치
- [x] ScrollContainer 설정 (horizontal)
- [x] 버튼 3개 추가 (주택, 농장, 상점)
- [x] 스크립트 작성 (펼침/접기 + 로그 출력)
- [x] test_map.tscn에 추가
- [x] 테스트: 펼침/접기 동작 확인
- [x] 테스트: 버튼 클릭 시 로그 출력 확인

---

### 📝 상세 단계

#### 1-1. ConstructionMenu.tscn 생성 (하단 바 구조)

**Godot 에디터:**

```
1. Scene → New Scene
2. Other Node → Control 선택
3. 이름: ConstructionMenu
4. Inspector 설정:
   - Layout → Anchors Preset: Full Rect
5. Scene → Save Scene As
   - 경로: scenes/ui/construction_menu.tscn
```

**노드 구조 추가:**

```
ConstructionMenu (Control, Full Rect)
├── CollapsedBar (Panel)  # 접힌 상태 바
│   └── ExpandButton (Button, text: "건설 ▲")
└── ExpandedPanel (Panel)  # 펼쳐진 상태
    ├── Header (HBoxContainer)
    │   ├── TitleLabel (Label, text: "건설 메뉴")
    │   └── CollapseButton (Button, text: "▼ 접기")
    └── Content (VBoxContainer)
        └── ScrollContainer (horizontal)
            └── BuildingList (HBoxContainer)  # 가로 배치!
                ├── HouseButton (Button, text: "주택")
                ├── FarmButton (Button, text: "농장")
                └── ShopButton (Button, text: "상점")
```

**노드 추가 방법:**

1. **CollapsedBar (Panel) 추가**
   - Layout → Bottom (Full Width)
   - Anchor: Left=0, Right=1, Top=1, Bottom=1
   - Offset: Top=-50, Bottom=0

2. **ExpandButton (Button) 추가**
   - Text: "건설 ▲"
   - Size: (120, 50)

3. **ExpandedPanel (Panel) 추가**
   - Layout → Bottom (Full Width)
   - Anchor: Left=0, Right=1, Top=1, Bottom=1
   - Offset: Top=-200, Bottom=0
   - Visible: false (초기 숨김)

4. **Header (HBoxContainer) 추가**
   - Size: (화면 너비, 40)

5. **Content → ScrollContainer → BuildingList (HBoxContainer) 추가**
   - ScrollContainer: Horizontal Scroll Enabled
   - BuildingList: Separation = 10

**CollapsedBar 설정:**
- 높이: 50px
- 배경: 반투명 검은색

**ExpandedPanel 설정:**
- 높이: 200px
- 배경: 반투명 검은색

**BuildingList 설정:**
- Alignment: Begin
- Separation: 10

#### 1-2. 스크립트 작성 (로그만!)

**파일:** `scripts/ui/construction_menu.gd`

```gdscript
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
```

**스크립트 연결 방법:**
1. ConstructionMenu 노드 선택
2. Inspector → Script → Attach Script
3. 경로: scripts/ui/construction_menu.gd
4. 위 코드 붙여넣기

#### 1-3. test_map.tscn에 추가

**씬 구조:**

```
TestMap (Node2D)
├── World
├── Managers
└── UI (CanvasLayer)
    └── ConstructionMenu (인스턴스) ← 추가
```

**추가 방법:**
1. test_map.tscn 열기
2. UI (CanvasLayer) 노드 우클릭
3. Instantiate Child Scene
4. scenes/ui/construction_menu.tscn 선택

#### 1-4. 테스트

**실행:**
```
F5 (또는 재생 버튼)
```

**테스트 시나리오:**
1. "건설 ▲" 버튼 클릭/터치 → 메뉴 펼쳐짐
2. "주택" 버튼 클릭 → 콘솔 확인
3. "농장" 버튼 클릭 → 콘솔 확인
4. "▼ 접기" 버튼 클릭 → 메뉴 접힘

**기대 출력 (콘솔):**
```
[Phase 1] ConstructionMenu 준비 완료 (하단 바)
[Phase 1] 메뉴 펼침
[Phase 1] 주택 버튼 클릭!
[Phase 1] 농장 버튼 클릭!
[Phase 1] 메뉴 접힘
```

**PC 및 모바일 확인:**
- ✅ 하단 바가 화면 하단에 고정됨
- ✅ 접힌 상태: 50px만 차지
- ✅ 펼쳐진 상태: 200px 차지
- ✅ 버튼이 가로로 나열됨
- ✅ 터치/클릭 모두 동작

---

### ✅ Phase 1 완료 조건

- [x] 펼침/접기 버튼으로 메뉴 제어
- [x] 하단 바가 화면 하단에 고정
- [x] 버튼 클릭하면 콘솔에 로그 출력
- [x] Resource, ConstructionManager 등 전혀 없음
- [x] UI 동작만 확인
- [x] 모바일 호환 (터치 가능)

**완료 후:** Phase 2 또는 Phase 3 진행 가능 (독립적)

---

## 🗂️ Phase 2: Resource 시스템 (UI 없이, 테스트 함수)

### 🎯 목표
- BuildingData Resource 클래스 작성
- .tres 파일 2개 생성 (주택, 농장)
- 테스트 함수로 Resource 로드 및 인스턴스 생성 확인

### 📦 의존성
- 없음 (Phase 1과 독립)

### ⏱️ 소요 시간
- 30분

---

### ✅ Todo 체크리스트

- [ ] EntityData.gd 작성 (베이스 클래스)
- [ ] BuildingData.gd 작성 (EntityData 상속)
- [ ] house_01.tres 생성 (에디터)
- [ ] farm_01.tres 생성 (에디터)
- [ ] BuildingDatabase.gd 작성
- [ ] 테스트: Resource 로드 및 데이터 출력 확인
- [ ] 테스트: Resource로 건물 인스턴스 생성 확인

---

### 📝 상세 단계

#### 2-1. EntityData.gd 작성 (베이스 클래스)

**파일:** `scripts/resources/entity_data.gd`

```gdscript
# scripts/resources/entity_data.gd
class_name EntityData extends Resource

# 모든 엔티티 공통 속성
@export var entity_id: String = ""           # 고유 ID
@export var entity_name: String = ""         # 표시 이름
@export var description: String = ""         # 설명
@export var icon: Texture2D                  # UI 아이콘
@export var scene_to_spawn: PackedScene      # 실제 씬

func get_id() -> String:
    return entity_id

func get_display_name() -> String:
    return entity_name
```

**폴더 생성:**
1. FileSystem → scripts 우클릭
2. Create Folder → "resources"

**파일 생성:**
1. scripts/resources/ 우클릭
2. Create Script
3. 경로: scripts/resources/entity_data.gd
4. 위 코드 입력

#### 2-2. BuildingData.gd 작성 (상속)

**파일:** `scripts/resources/building_data.gd`

```gdscript
# scripts/resources/building_data.gd
class_name BuildingData extends EntityData

# 건물 전용 속성
@export var cost_wood: int = 0
@export var cost_stone: int = 0
@export var cost_gold: int = 100
@export var grid_size: Vector2i = Vector2i(1, 1)

# 카테고리
enum BuildingCategory {
    RESIDENTIAL,  # 주거
    PRODUCTION,   # 생산
    MILITARY,     # 군사
    DECORATION    # 장식
}
@export var category: BuildingCategory = BuildingCategory.RESIDENTIAL

# 헬퍼 함수
func get_total_cost() -> Dictionary:
    return {
        "wood": cost_wood,
        "stone": cost_stone,
        "gold": cost_gold
    }
```

#### 2-3. house_01.tres 생성 (Godot 에디터)

**Resource 파일 생성:**

```
1. FileSystem → scripts/resources/ 우클릭
2. Create New → Resource
3. 타입 선택: "BuildingData" 검색
4. 이름: house_01.tres
5. Create
```

**Inspector에서 데이터 입력:**

```
house_01.tres (Resource):
- entity_id: "house_01"
- entity_name: "주택"
- description: "주민이 거주하는 집입니다."
- icon: (일단 비워둠, 나중에 추가)
- scene_to_spawn: [scenes/entity/building_entity.tscn 드래그]
- cost_wood: 50
- cost_stone: 30
- cost_gold: 100
- grid_size: (1, 1)
- category: RESIDENTIAL
```

**주의:** `scene_to_spawn`은 기존 `building_entity.tscn`을 드래그해서 연결

#### 2-4. farm_01.tres 생성

**같은 방법으로:**

```
farm_01.tres:
- entity_id: "farm_01"
- entity_name: "농장"
- description: "식량을 생산합니다."
- scene_to_spawn: [building_entity.tscn]
- cost_gold: 150
- category: PRODUCTION
```

#### 2-5. BuildingDatabase.gd 작성

**파일:** `scripts/config/building_database.gd`

```gdscript
# scripts/config/building_database.gd
extends Node
class_name BuildingDatabase

# 모든 건물 데이터 배열
const BUILDINGS: Array[BuildingData] = [
    preload("res://scripts/resources/house_01.tres"),
    preload("res://scripts/resources/farm_01.tres"),
]

# ID로 건물 찾기
static func get_building_by_id(id: String) -> BuildingData:
    for building in BUILDINGS:
        if building.entity_id == id:
            return building
    return null

# 카테고리별 건물 목록
static func get_buildings_by_category(category: BuildingData.BuildingCategory) -> Array[BuildingData]:
    var result: Array[BuildingData] = []
    for building in BUILDINGS:
        if building.category == category:
            result.append(building)
    return result

# 모든 건물 목록
static func get_all_buildings() -> Array[BuildingData]:
    return BUILDINGS.duplicate()
```

#### 2-6. 테스트 함수 작성

**파일:** `scripts/maps/test_map.gd` (새로 만들거나 수정)

```gdscript
# scripts/maps/test_map.gd
extends Node2D

func _ready():
    print("\n========================================")
    print("Phase 2: Resource 시스템 테스트 시작")
    print("========================================\n")

    test_resource_load()
    test_instance_creation()

# ⭐ 테스트 1: Resource 로드
func test_resource_load():
    print("=== 테스트 1: Resource 로드 ===")

    var house = load("res://scripts/resources/house_01.tres") as BuildingData
    print("건물 ID:", house.entity_id)
    print("건물 이름:", house.entity_name)
    print("건물 비용 (골드):", house.cost_gold)
    print("건물 크기:", house.grid_size)
    print("✅ Resource 로드 성공!\n")

# ⭐ 테스트 2: 인스턴스 생성
func test_instance_creation():
    print("=== 테스트 2: 인스턴스 생성 ===")

    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData

    if not house_data.scene_to_spawn:
        print("❌ scene_to_spawn이 null입니다!")
        return

    var building = house_data.scene_to_spawn.instantiate()
    building.position = Vector2(100, 100)
    add_child(building)

    print("✅ 건물 인스턴스 생성 성공!")
    print("위치:", building.position)
    print("화면에 건물이 나타나야 합니다.\n")

# ⭐ 테스트 3: Database
func test_database():
    print("=== 테스트 3: BuildingDatabase ===")

    var house = BuildingDatabase.get_building_by_id("house_01")
    print("Database에서 조회:", house.entity_name)

    var all_buildings = BuildingDatabase.get_all_buildings()
    print("전체 건물 수:", all_buildings.size())

    print("✅ Database 테스트 성공!\n")
```

**스크립트 연결:**
1. test_map.tscn의 TestMap (루트 노드) 선택
2. Inspector → Script → Attach Script
3. 경로: scripts/maps/test_map.gd
4. 위 코드 입력

#### 2-7. 테스트 실행

**F5 실행**

**기대 출력 (콘솔):**
```
========================================
Phase 2: Resource 시스템 테스트 시작
========================================

=== 테스트 1: Resource 로드 ===
건물 ID: house_01
건물 이름: 주택
건물 비용 (골드): 100
건물 크기: (1, 1)
✅ Resource 로드 성공!

=== 테스트 2: 인스턴스 생성 ===
✅ 건물 인스턴스 생성 성공!
위치: (100, 100)
화면에 건물이 나타나야 합니다.
```

**화면 확인:**
- 왼쪽 상단에 건물 1개 나타남 (100, 100 위치)

---

### ✅ Phase 2 완료 조건

- [x] 콘솔에 "Resource 로드 성공!" 출력
- [x] 콘솔에 "인스턴스 생성 성공!" 출력
- [x] 화면에 건물 1개 나타남
- [x] .tres 파일 2개 생성됨

**완료 후:** Phase 3 진행 가능

---

## ⚙️ Phase 3: ConstructionManager (로직, UI 없이)

### 🎯 목표
- ConstructionManager 로직 구현
- 코드로 강제 호출해서 건물 배치 테스트
- 미리보기, 검증 로직 동작 확인

### 📦 의존성
- Phase 2 (BuildingData 필요)

### ⏱️ 소요 시간
- 30분

---

### ✅ Todo 체크리스트

- [ ] ConstructionManager.gd 기본 구조 작성
- [ ] select_building() 함수 구현
- [ ] 미리보기 스프라이트 시스템 구현
- [ ] can_build_at() 검증 로직 구현
- [ ] try_place_building() 배치 로직 구현
- [ ] 테스트: 코드로 강제 호출해서 건물 배치 확인

---

### 📝 상세 단계

#### 3-1. ConstructionManager.gd 작성

**파일:** `scripts/managers/construction_manager.gd`

```gdscript
# scripts/managers/construction_manager.gd
extends Node

# 건설 모드
enum ConstructionMode {
    NONE,
    SINGLE,
    DRAG
}

var current_mode: ConstructionMode = ConstructionMode.NONE
var selected_building: BuildingData = null
var preview_sprite: Sprite2D = null

# 시그널
signal building_selected(building_data: BuildingData)
signal building_placed(building_data: BuildingData, grid_pos: Vector2i)
signal construction_cancelled()

func _ready():
    # 미리보기 스프라이트 생성
    preview_sprite = Sprite2D.new()
    preview_sprite.modulate = Color(1, 1, 1, 0.5)
    preview_sprite.z_index = 100
    preview_sprite.visible = false
    add_child(preview_sprite)

    print("[Phase 3] ConstructionManager 준비 완료")

# 건물 선택
func select_building(building_data: BuildingData, mode: ConstructionMode = ConstructionMode.SINGLE):
    selected_building = building_data
    current_mode = mode

    print("[Phase 3] 건물 선택:", building_data.entity_name)

    # 미리보기 설정
    if building_data and building_data.scene_to_spawn:
        var temp_instance = building_data.scene_to_spawn.instantiate()
        var sprite = temp_instance.get_node("Sprite2D") as Sprite2D
        if sprite:
            preview_sprite.texture = sprite.texture
            preview_sprite.visible = true
        temp_instance.queue_free()

    building_selected.emit(building_data)

# 건설 취소
func cancel_construction():
    selected_building = null
    current_mode = ConstructionMode.NONE
    preview_sprite.visible = false
    print("[Phase 3] 건설 취소")
    construction_cancelled.emit()

# 미리보기 업데이트
func _process(delta):
    if current_mode == ConstructionMode.NONE:
        return

    # 마우스 → 그리드 좌표 변환
    var mouse_pos = get_viewport().get_mouse_position()
    var camera = get_viewport().get_camera_2d()
    if camera:
        mouse_pos = camera.get_global_mouse_position()

    var grid_pos = GridSystem.world_to_grid(mouse_pos)
    var world_pos = GridSystem.grid_to_world(grid_pos)
    preview_sprite.global_position = world_pos

    # 건설 가능 여부에 따라 색상 변경
    if can_build_at(grid_pos):
        preview_sprite.modulate = Color(0.5, 1, 0.5, 0.7)  # 녹색
    else:
        preview_sprite.modulate = Color(1, 0.5, 0.5, 0.7)  # 빨간색

# 건설 가능 여부 검증
func can_build_at(grid_pos: Vector2i) -> bool:
    if not selected_building:
        return false

    # 그리드 범위 체크
    if not GridSystem.is_valid_position(grid_pos):
        return false

    # 이미 건물이 있는지 체크
    if BuildingManager.has_building_at(grid_pos):
        return false

    return true

# 건물 배치 시도
func try_place_building(grid_pos: Vector2i) -> bool:
    if not can_build_at(grid_pos):
        print("[Phase 3] 건설 불가:", grid_pos)
        return false

    # 실제 건물 생성
    var building = selected_building.scene_to_spawn.instantiate()
    building.global_position = GridSystem.grid_to_world(grid_pos)

    # BuildingManager에 등록
    BuildingManager.add_building(building, grid_pos)

    print("[Phase 3] 건물 배치 성공:", selected_building.entity_name, "at", grid_pos)
    building_placed.emit(selected_building, grid_pos)

    return true

# 입력 처리
func _unhandled_input(event):
    if current_mode == ConstructionMode.NONE:
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
        if camera:
            mouse_pos = camera.get_global_mouse_position()

        var grid_pos = GridSystem.world_to_grid(mouse_pos)

        if try_place_building(grid_pos):
            if current_mode == ConstructionMode.SINGLE:
                cancel_construction()

        get_viewport().set_input_as_handled()
```

#### 3-2. test_map.tscn에 ConstructionManager 추가

**노드 추가:**

```
TestMap (Node2D)
├── World
├── Managers (Node)
│   ├── BuildingManager
│   └── ConstructionManager (Node) ← 새로 추가
└── UI
```

**추가 방법:**
1. test_map.tscn 열기
2. Managers 노드 우클릭 → Add Child Node
3. Node 선택 → Create
4. 이름: ConstructionManager
5. Inspector → Script → Attach Script
6. 경로: scripts/managers/construction_manager.gd
7. 위 코드 입력

#### 3-3. Autoload 등록 (옵션)

**프로젝트 설정:**

```
Project → Project Settings → Autoload:
- Path: scripts/managers/construction_manager.gd
- Name: ConstructionManager
- Singleton: 체크
- Enable
```

**장점:** 어디서든 `ConstructionManager.select_building()` 호출 가능

#### 3-4. 테스트 함수 추가

**파일:** `scripts/maps/test_map.gd` (추가)

```gdscript
# scripts/maps/test_map.gd
func _ready():
    # Phase 2 테스트...
    test_resource_load()
    test_instance_creation()

    # ⭐ Phase 3 테스트
    call_deferred("test_construction_manager")

func test_construction_manager():
    print("\n========================================")
    print("Phase 3: ConstructionManager 테스트")
    print("========================================\n")

    # 건물 데이터 로드
    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData

    # 강제로 건물 선택
    ConstructionManager.select_building(house_data)

    # 잠시 대기 (미리보기 확인용)
    await get_tree().create_timer(1.0).timeout

    # 강제로 배치 시도
    var test_pos = Vector2i(5, 5)
    var success = ConstructionManager.try_place_building(test_pos)

    if success:
        print("✅ ConstructionManager 배치 성공!")
        print("화면에서 그리드 (5, 5) 위치에 건물 확인\n")
    else:
        print("❌ ConstructionManager 배치 실패!")
```

#### 3-5. 테스트 실행

**F5 실행**

**기대 동작:**
1. 1초 후 건물 미리보기가 마우스를 따라다님 (반투명)
2. 녹색/빨간색으로 색상 변경
3. 그리드 (5, 5) 위치에 건물 자동 배치

**기대 출력:**
```
[Phase 3] ConstructionManager 준비 완료
[Phase 3] 건물 선택: 주택
[Phase 3] 건물 배치 성공: 주택 at (5, 5)
✅ ConstructionManager 배치 성공!
화면에서 그리드 (5, 5) 위치에 건물 확인
```

---

### ✅ Phase 3 완료 조건

- [x] 콘솔에 "건물 선택: 주택" 출력
- [x] 콘솔에 "건물 배치 성공" 출력
- [x] 미리보기가 마우스 따라다님
- [x] 녹색/빨간색 색상 변경 동작
- [x] 화면에 건물이 (5, 5) 위치에 배치됨

**완료 후:** Phase 4 진행 가능

---

## 🔗 Phase 4: 통합 (UI + Resource + Logic)

### 🎯 목표
- Phase 1 UI + Phase 2 Resource + Phase 3 Logic 연결
- 버튼 클릭 → 실제 건물 배치 동작
- 전체 워크플로우 테스트

### 📦 의존성
- Phase 1 + Phase 2 + Phase 3 (모두 필요)

### ⏱️ 소요 시간
- 15분

---

### ✅ Todo 체크리스트

- [ ] UI 버튼 → ConstructionManager 연결
- [ ] 버튼 클릭 시 실제 BuildingData 전달
- [ ] 테스트: 미리보기 마우스 따라다님 확인
- [ ] 테스트: 클릭으로 건물 배치 확인
- [ ] 테스트: ESC로 건설 취소 확인

---

### 📝 상세 단계

#### 4-1. ConstructionMenu 수정 (하단 바 + Resource 연결)

**파일:** `scripts/ui/construction_menu.gd` (수정)

```gdscript
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
    # 시그널 연결
    expand_button.pressed.connect(_on_expand_button_pressed)
    collapse_button.pressed.connect(_on_collapse_button_pressed)

    house_button.pressed.connect(_on_house_button_pressed)
    farm_button.pressed.connect(_on_farm_button_pressed)
    shop_button.pressed.connect(_on_shop_button_pressed)

    # 초기 상태: 접힘
    _set_collapsed()

    print("[Phase 4] ConstructionMenu (하단 바 + Resource 통합) 준비 완료")

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

# ⭐ Phase 4: Resource 연결!
func _on_house_button_pressed():
    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData
    ConstructionManager.select_building(house_data)
    # ⭐ 메뉴 유지 (닫지 않음) - 빠른 재선택 가능
    print("[Phase 4] 주택 선택 → ConstructionManager 호출")
    get_viewport().set_input_as_handled()

func _on_farm_button_pressed():
    var farm_data = load("res://scripts/resources/farm_01.tres") as BuildingData
    ConstructionManager.select_building(farm_data)
    # ⭐ 메뉴 유지
    print("[Phase 4] 농장 선택 → ConstructionManager 호출")
    get_viewport().set_input_as_handled()

func _on_shop_button_pressed():
    print("[Phase 4] 상점은 아직 Resource 없음")
    get_viewport().set_input_as_handled()
```

#### 4-2. test_map.gd 테스트 함수 비활성화

**파일:** `scripts/maps/test_map.gd` (수정)

```gdscript
# scripts/maps/test_map.gd
func _ready():
    # ⭐ Phase 4: 이전 테스트 함수 비활성화 (주석 처리)
    # test_resource_load()
    # test_instance_creation()
    # call_deferred("test_construction_manager")

    print("\n========================================")
    print("Phase 4: 통합 테스트")
    print("========================================")
    print("하단의 '건설 ▲' 버튼을 클릭하여 메뉴를 열고 건물을 선택하세요.\n")
```

#### 4-3. 최종 테스트

**F5 실행**

**테스트 시나리오:**

```
1. 하단 "건설 ▲" 버튼 클릭
   → 건설 메뉴 펼쳐짐

2. "주택" 버튼 클릭
   → 메뉴 유지 (펼쳐진 상태)
   → 반투명 주택이 마우스 따라다님
   → 녹색/빨간색으로 색상 변경

3. 빈 공간 클릭
   → 건물 배치됨
   → 미리보기 사라짐
   → 메뉴는 여전히 펼쳐진 상태 (빠른 재선택 가능)

4. "농장" 버튼 클릭
   → 농장 미리보기 나타남

5. ESC 키
   → 건설 취소
   → 미리보기 사라짐
   → 메뉴는 여전히 펼쳐진 상태

6. "▼ 접기" 버튼 클릭
   → 메뉴 접힘 (하단 50px만)
```

**기대 출력:**
```
Phase 4: 통합 테스트
하단의 '건설 ▲' 버튼을 클릭하여 메뉴를 열고 건물을 선택하세요.

[Phase 4] ConstructionMenu (하단 바 + Resource 통합) 준비 완료
[Phase 4] 주택 선택 → ConstructionManager 호출
[Phase 3] 건물 선택: 주택
[Phase 3] 건물 배치 성공: 주택 at (10, 8)

[Phase 4] 농장 선택 → ConstructionManager 호출
[Phase 3] 건물 선택: 농장
[Phase 3] 건설 취소
```

---

### ✅ Phase 4 완료 조건

- [x] "건설 ▲" 버튼으로 메뉴 펼침
- [x] 버튼 클릭 → 미리보기 표시
- [x] 미리보기가 마우스 따라다님
- [x] 녹색/빨간색 색상 변경
- [x] 클릭 → 건물 배치
- [x] 건물 배치 후에도 메뉴 유지 (빠른 재선택)
- [x] "▼ 접기" 버튼으로 메뉴 접힘
- [x] ESC → 건설 취소

**🎉 모든 Phase 완료! 하단 바 건설 메뉴 완성!**

---

## 📊 전체 체크리스트

### Phase 1: 최소 UI (하단 바)
- [x] ConstructionMenu.tscn 생성 (하단 고정 바)
- [x] CollapsedBar + ExpandedPanel 구조
- [x] 펼침/접기 버튼 추가
- [x] 버튼 3개 가로 배치
- [x] 로그 출력 스크립트
- [x] 테스트 완료

### Phase 2: Resource
- [ ] EntityData.gd
- [ ] BuildingData.gd
- [ ] house_01.tres
- [ ] farm_01.tres
- [ ] BuildingDatabase.gd
- [ ] 테스트 함수
- [ ] 테스트 완료

### Phase 3: Logic
- [ ] ConstructionManager.gd
- [ ] select_building()
- [ ] 미리보기 시스템
- [ ] can_build_at()
- [ ] try_place_building()
- [ ] 테스트 완료

### Phase 4: 통합
- [ ] UI 연결
- [ ] BuildingData 전달
- [ ] 전체 워크플로우 테스트
- [ ] 완료!

---

## 🐛 트러블슈팅

### 문제 1: 버튼 클릭해도 반응 없음 (Phase 1)

**원인:** 시그널 연결 안 됨

**해결:**
```gdscript
func _ready():
    house_button.pressed.connect(_on_house_button_pressed)  # ✅ 이 줄 확인
```

### 문제 2: Resource 로드 실패 (Phase 2)

**증상:**
```
Cannot load resource at path 'res://scripts/resources/house_01.tres'
```

**해결:**
1. FileSystem에서 파일 경로 확인
2. .tres 파일 더블클릭해서 열리는지 확인
3. BuildingData 타입인지 확인

### 문제 3: 미리보기 안 나타남 (Phase 3)

**원인:** Sprite2D 노드 못 찾음

**해결:**
```gdscript
var sprite = temp_instance.get_node("Sprite2D") as Sprite2D
if sprite:  # ✅ null 체크
    preview_sprite.texture = sprite.texture
```

### 문제 4: 건물 배치 안 됨 (Phase 4)

**원인:** GridSystem, BuildingManager 없음

**해결:**
- GridSystem이 Autoload로 등록되어 있는지 확인
- BuildingManager가 test_map.tscn에 있는지 확인

---

## 📚 참고 문서

- `../design/construction_menu_ui_redesign.md` - 하단 바 UI 재설계 (⭐ 최신 UI 디자인)
- `../design/building_construction_system_design.md` - 데이터 + 로직 설계
- `../design/ui_system_design.md` - 전체 UI 시스템 설계
- `../design/resource_based_entity_design.md` - Resource 패턴
- `../product/prd.md` - 전체 요구사항

---

## 🎯 다음 단계

Phase 4 완료 후:

1. **건설 메뉴 개선** (ui_system_design.md Phase 2)
   - BuildingButton 프리팹
   - 동적 버튼 생성
   - 카테고리별 분류

2. **드래그 건축** (building_construction_system_design.md 6.1)
   - ConstructionMode.DRAG 활용
   - 도로 연속 배치

3. **자원 시스템**
   - ResourceManager 추가
   - 비용 차감 로직

4. **건물 정보 패널** (ui_system_design.md 5)
   - 선택 시 정보 표시
   - 업그레이드/철거 버튼

---

## ✅ 최종 확인

**모든 Phase 완료 시:**

```
✓ 하단 "건설 ▲" 버튼으로 메뉴 펼침
✓ 버튼 클릭 → 미리보기
✓ 마우스 따라다님
✓ 녹색/빨간색 표시
✓ 클릭으로 배치
✓ 건물 배치 후에도 메뉴 유지 (빠른 재선택)
✓ "▼ 접기" 버튼으로 메뉴 접힘
✓ ESC로 건설 취소
✓ 여러 건물 배치 가능
✓ 모바일 호환 (터치 동작)
```

**축하합니다! 하단 바 건설 시스템 완성! 🎉**
