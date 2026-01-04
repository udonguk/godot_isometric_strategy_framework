# 건설 시스템 설계 (Building Construction System Design)

## 1. 개요

타이쿤 게임에서 핵심이 되는 **건물 건설 시스템**의 상세 설계 문서입니다.

### 1.1. 목표

- **데이터 주도 개발**: Resource 기반으로 건물 데이터 관리
- **확장성**: 새 건물 추가 시 코드 수정 최소화
- **직관적 UX**: 클릭/드래그로 쉽게 건축
- **검증 시스템**: 건설 가능 여부 명확한 피드백

### 1.2. 핵심 원칙

**개발 순서: 데이터 → 로직**

```
1. BuildingData (Resource) 정의
   ↓
2. ConstructionManager (로직) 구현
   ↓
3. UI 연결 (별도 문서 참조)
```

이 문서는 **데이터와 로직**에 집중합니다:
- ✅ Resource 기반 건물 데이터 설계
- ✅ ConstructionManager 건설 로직
- ✅ 시그널 기반 UI 연동 인터페이스

**UI 구현은 별도 문서 참조:**
- `docs/design/ui_system_design.md` - 건설 메뉴 UI 상세 설계

---

## 2. Resource 시스템

### 2.1. BuildingData 정의

**파일 위치**: `scripts/resources/building_data.gd`

```gdscript
# scripts/resources/building_data.gd
class_name BuildingData extends Resource

# 기본 정보
@export var building_id: String = "house_01"  # 고유 ID (저장/로드용)
@export var building_name: String = "주택"     # 표시 이름
@export var description: String = "주민이 거주하는 집입니다."

# 비주얼
@export var icon: Texture2D                    # UI 아이콘 (64x64)
@export var scene_to_build: PackedScene        # 실제 건물 씬

# 건설 정보
@export var cost_wood: int = 50                # 나무 비용
@export var cost_stone: int = 30               # 돌 비용
@export var cost_gold: int = 100               # 골드 비용
@export var build_time: float = 3.0            # 건설 시간 (초, 옵션)

# 그리드 크기
@export var grid_size: Vector2i = Vector2i(1, 1)  # 1x1, 2x2 등

# 카테고리
enum BuildingCategory {
    RESIDENTIAL,  # 주거
    PRODUCTION,   # 생산
    MILITARY,     # 군사
    DECORATION    # 장식
}
@export var category: BuildingCategory = BuildingCategory.RESIDENTIAL

# 건설 제한
@export var requires_road_access: bool = false  # 도로 인접 필요 여부
@export var max_count: int = -1                 # 최대 건설 수 (-1 = 무제한)

# 헬퍼 함수
func get_total_cost() -> Dictionary:
    return {
        "wood": cost_wood,
        "stone": cost_stone,
        "gold": cost_gold
    }

func can_afford(resources: Dictionary) -> bool:
    return (
        resources.get("wood", 0) >= cost_wood and
        resources.get("stone", 0) >= cost_stone and
        resources.get("gold", 0) >= cost_gold
    )
```

### 2.2. BuildingData Resource 생성 (Godot 에디터)

**Step 1: Resource 파일 생성**

```
Godot 에디터:
1. FileSystem → scripts/resources/ 우클릭
2. "Create New" → "Resource"
3. 타입 선택: "BuildingData"
4. 이름: house_01.tres
5. 저장
```

**Step 2: Inspector에서 데이터 입력**

```
house_01.tres:
- building_id: "house_01"
- building_name: "주택"
- description: "주민이 거주하는 집입니다."
- icon: [assets/sprites/ui/icons/house_icon.png 드래그]
- scene_to_build: [scenes/entity/building_entity.tscn 드래그]
- cost_wood: 50
- cost_stone: 30
- cost_gold: 100
- build_time: 3.0
- grid_size: (1, 1)
- category: RESIDENTIAL
```

**Step 3: 여러 건물 생성**

```
scripts/resources/
├── house_01.tres       # 주택
├── farm_01.tres        # 농장
├── barracks_01.tres    # 병영
└── tree_decoration.tres # 장식용 나무
```

### 2.3. BuildingDatabase (중앙 관리)

**파일 위치**: `scripts/config/building_database.gd`

```gdscript
# scripts/config/building_database.gd
extends Node
class_name BuildingDatabase

# 모든 건물 데이터 배열
const BUILDINGS: Array[BuildingData] = [
    preload("res://scripts/resources/house_01.tres"),
    preload("res://scripts/resources/farm_01.tres"),
    preload("res://scripts/resources/barracks_01.tres"),
    preload("res://scripts/resources/tree_decoration.tres"),
]

# ID로 건물 찾기
static func get_building_by_id(id: String) -> BuildingData:
    for building in BUILDINGS:
        if building.building_id == id:
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

**장점:**
- ✅ 한 곳에서 모든 건물 관리
- ✅ ID로 빠른 검색
- ✅ 카테고리별 필터링
- ✅ 새 건물 추가 = 배열에 1줄 추가

---

## 3. 건설 로직 (ConstructionManager)

### 3.1. 건설 상태 관리

**파일 위치**: `scripts/managers/construction_manager.gd`

```gdscript
# scripts/managers/construction_manager.gd
extends Node

# 건설 모드 상태
enum ConstructionMode {
    NONE,           # 건설 모드 아님
    SINGLE,         # 단일 건축 (클릭)
    DRAG            # 드래그 건축 (연속)
}

var current_mode: ConstructionMode = ConstructionMode.NONE
var selected_building: BuildingData = null  # 선택된 건물 데이터
var preview_sprite: Sprite2D = null         # 미리보기 스프라이트

# 드래그 건축용
var is_dragging: bool = false
var drag_start_grid: Vector2i = Vector2i.ZERO
var placed_during_drag: Array[Vector2i] = []  # 이미 배치한 위치들

# 시그널
signal building_selected(building_data: BuildingData)
signal building_placed(building_data: BuildingData, grid_pos: Vector2i)
signal construction_cancelled()

func _ready():
    # 미리보기 스프라이트 생성
    preview_sprite = Sprite2D.new()
    preview_sprite.modulate = Color(1, 1, 1, 0.5)  # 반투명
    preview_sprite.z_index = 10  # 최상위
    preview_sprite.visible = false
    add_child(preview_sprite)

# 건물 선택 (건설 메뉴에서 호출)
func select_building(building_data: BuildingData, mode: ConstructionMode = ConstructionMode.SINGLE):
    selected_building = building_data
    current_mode = mode

    # 미리보기 설정
    if building_data:
        var building_scene = building_data.scene_to_build.instantiate()
        var sprite = building_scene.get_node("Sprite2D") as Sprite2D
        preview_sprite.texture = sprite.texture
        preview_sprite.visible = true
        building_scene.queue_free()

    building_selected.emit(building_data)

# 건설 취소
func cancel_construction():
    selected_building = null
    current_mode = ConstructionMode.NONE
    preview_sprite.visible = false
    is_dragging = false
    placed_during_drag.clear()
    construction_cancelled.emit()

# 마우스 위치에 미리보기 업데이트
func _process(delta):
    if current_mode == ConstructionMode.NONE:
        return

    # 마우스 → 그리드 좌표 변환
    var mouse_world = get_viewport().get_mouse_position()
    # TODO: 카메라 오프셋 고려 필요
    var grid_pos = GridSystem.world_to_grid(mouse_world)

    # 미리보기 위치 업데이트
    var world_pos = GridSystem.grid_to_world(grid_pos)
    preview_sprite.global_position = world_pos

    # 건설 가능 여부에 따라 색상 변경
    if can_build_at(grid_pos):
        preview_sprite.modulate = Color(0.5, 1, 0.5, 0.7)  # 녹색 (가능)
    else:
        preview_sprite.modulate = Color(1, 0.5, 0.5, 0.7)  # 빨간색 (불가)

# 건설 가능 여부 검증
func can_build_at(grid_pos: Vector2i) -> bool:
    # 1. 그리드 범위 체크
    if not GridSystem.is_valid_position(grid_pos):
        return false

    # 2. 이미 건물이 있는지 체크
    if BuildingManager.has_building_at(grid_pos):
        return false

    # 3. 자원 체크 (ResourceManager 필요)
    # if not ResourceManager.can_afford(selected_building.get_total_cost()):
    #     return false

    # 4. 도로 인접 체크 (옵션)
    if selected_building.requires_road_access:
        if not has_road_nearby(grid_pos):
            return false

    return true

# 건물 배치 시도
func try_place_building(grid_pos: Vector2i) -> bool:
    if not can_build_at(grid_pos):
        return false

    # 실제 건물 생성
    var building_scene = selected_building.scene_to_build.instantiate()
    building_scene.global_position = GridSystem.grid_to_world(grid_pos)

    # BuildingManager에 등록
    BuildingManager.add_building(building_scene, grid_pos)

    # 자원 차감 (ResourceManager 필요)
    # ResourceManager.consume_resources(selected_building.get_total_cost())

    # 시그널 발송
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

    # 마우스 클릭
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var mouse_world = get_viewport().get_mouse_position()
        var grid_pos = GridSystem.world_to_grid(mouse_world)

        if event.pressed:
            # 클릭 시작
            if current_mode == ConstructionMode.SINGLE:
                # 단일 건축
                if try_place_building(grid_pos):
                    cancel_construction()  # 건설 완료 후 모드 해제

            elif current_mode == ConstructionMode.DRAG:
                # 드래그 건축 시작
                is_dragging = true
                drag_start_grid = grid_pos
                placed_during_drag.clear()
                try_place_building(grid_pos)
                placed_during_drag.append(grid_pos)

        else:
            # 클릭 해제
            if current_mode == ConstructionMode.DRAG:
                is_dragging = false

        get_viewport().set_input_as_handled()

    # 드래그 중 마우스 이동
    if current_mode == ConstructionMode.DRAG and is_dragging:
        if event is InputEventMouseMotion:
            var mouse_world = get_viewport().get_mouse_position()
            var grid_pos = GridSystem.world_to_grid(mouse_world)

            # 아직 배치하지 않은 위치라면
            if not placed_during_drag.has(grid_pos):
                if try_place_building(grid_pos):
                    placed_during_drag.append(grid_pos)
```

### 3.2. BuildingManager 연동

**기존 BuildingManager에 메서드 추가:**

```gdscript
# scripts/managers/building_manager.gd

# 건물 존재 여부 확인
func has_building_at(grid_pos: Vector2i) -> bool:
    return grid_buildings.has(grid_pos)

# 건물 추가 (외부에서 호출 가능하게)
func add_building(building: Node2D, grid_pos: Vector2i):
    entities_container.add_child(building)
    grid_buildings[grid_pos] = building
```

---

## 4. UI 연동 인터페이스

ConstructionManager는 **시그널**을 통해 UI와 통신합니다.

### 4.1. 시그널 정의

```gdscript
# scripts/managers/construction_manager.gd에 정의됨

signal building_selected(building_data: BuildingData)
signal building_placed(building_data: BuildingData, grid_pos: Vector2i)
signal construction_cancelled()
```

### 4.2. UI에서 ConstructionManager 호출

**UI → ConstructionManager:**

```gdscript
# UI에서 건물 선택 시
ConstructionManager.select_building(building_data, ConstructionManager.ConstructionMode.SINGLE)

# 드래그 모드로 선택 시
ConstructionManager.select_building(road_data, ConstructionManager.ConstructionMode.DRAG)
```

### 4.3. ConstructionManager → UI 시그널

**UI에서 시그널 수신:**

```gdscript
# scripts/ui/construction_menu.gd (하단 바 버전)
func _ready():
    # 시그널 연결
    ConstructionManager.building_placed.connect(_on_building_placed)
    ConstructionManager.construction_cancelled.connect(_on_construction_cancelled)

func _on_building_placed(building_data: BuildingData, grid_pos: Vector2i):
    print("[UI] 건물 배치 완료: %s at %s" % [building_data.building_name, grid_pos])
    # UI 업데이트 (예: 자원 표시 갱신)
    # 하단 바는 펼쳐진 상태 유지 (빠른 재선택 가능)

func _on_construction_cancelled():
    print("[UI] 건설 취소")
    # 하단 바 상태는 변경 없음 (사용자가 접기 버튼으로 제어)
```

**UI 구현 상세:**
- `docs/design/construction_menu_ui_redesign.md` - 하단 바 UI 재설계 (모바일 호환)
- `docs/design/ui_system_design.md` - 전체 UI 시스템 설계

---

## 5. 통합 워크플로우

### 5.1. 데이터 흐름

```
1. UI에서 건물 선택
   → ConstructionManager.select_building(building_data)
   ↓
2. ConstructionManager가 건설 모드 진입
   - 미리보기 스프라이트 표시
   - 마우스 추적 시작 (_process)
   ↓
3. 플레이어가 맵 클릭
   ↓
4. ConstructionManager._unhandled_input()
   → can_build_at(grid_pos) 검증
   → try_place_building(grid_pos)
   ↓
5. BuildingManager.add_building() 호출
   → 건물 씬 인스턴스화
   → 그리드에 등록
   ↓
6. building_placed 시그널 발송
   → UI 업데이트
   ↓
7. 건설 모드 종료 (SINGLE) 또는 유지 (DRAG)
```

### 5.2. 씬 구조 (test_map.tscn)

```
TestMap (Node2D)
├── World (Node2D)
│   ├── GroundTileMapLayer
│   └── Entities (Node2D)
│       └── Buildings...
├── Managers (Node)
│   ├── BuildingManager (Node)
│   └── ConstructionManager (Node)  ← 건설 로직
└── UI (CanvasLayer)  ← 하단 바 UI
    └── ConstructionMenu (Control)  ← 하단 고정 바 (모바일 호환)
        ├── CollapsedBar (Panel)    ← 접힌 상태 (50px)
        └── ExpandedPanel (Panel)   ← 펼쳐진 상태 (200px)
    # 상세 구조: construction_menu_ui_redesign.md 참고
```

### 5.3. Autoload 등록 (옵션)

**프로젝트 설정 → Autoload:**

```
ConstructionManager: scripts/managers/construction_manager.gd (싱글톤)
BuildingDatabase: scripts/config/building_database.gd (싱글톤)
```

**장점:**
- 어디서든 `ConstructionManager.select_building()` 호출 가능
- `BuildingDatabase.get_building_by_id()` 전역 접근

---

## 6. 고급 기능

### 6.1. 드래그 건축 (연속 배치)

이미 `ConstructionManager`에 구현됨:

```gdscript
# 건설 메뉴에서 드래그 모드로 선택
ConstructionManager.select_building(road_01.tres, ConstructionManager.ConstructionMode.DRAG)

# 마우스 드래그 시 자동으로 연속 배치
```

**활용 예:**
- 도로 건설
- 벽 건설
- 울타리 배치

### 6.2. 건설 진행도 시스템 (옵션)

**BuildingData에 build_time이 있는 경우:**

```gdscript
# scripts/entity/building_entity.gd
extends Node2D

var is_constructing: bool = true
var construction_progress: float = 0.0
var build_time: float = 3.0

func _ready():
    modulate = Color(0.5, 0.5, 0.5)  # 건설 중 회색

func _process(delta):
    if is_constructing:
        construction_progress += delta

        if construction_progress >= build_time:
            # 건설 완료
            is_constructing = false
            modulate = Color.WHITE
            emit_signal("construction_completed")
```

### 6.3. 건물 회전 (옵션)

```gdscript
# ConstructionManager에 추가
var preview_rotation: int = 0  # 0, 90, 180, 270

func _unhandled_input(event):
    # R 키로 회전
    if event.is_action_pressed("rotate_building"):
        preview_rotation = (preview_rotation + 90) % 360
        preview_sprite.rotation_degrees = preview_rotation
```

### 6.4. 건물 크기 지원 (2x2, 3x3 등)

```gdscript
# BuildingData.grid_size = Vector2i(2, 2)인 경우

func can_build_at(grid_pos: Vector2i) -> bool:
    var size = selected_building.grid_size

    # 모든 타일 체크
    for x in range(size.x):
        for y in range(size.y):
            var check_pos = grid_pos + Vector2i(x, y)

            if not GridSystem.is_valid_position(check_pos):
                return false

            if BuildingManager.has_building_at(check_pos):
                return false

    return true
```

---

## 7. 테스트 시나리오

### 7.1. Phase 1: Resource 테스트

```gdscript
# test_map.gd
func _ready():
    # Resource 로드 테스트
    var house = load("res://scripts/resources/house_01.tres")
    print(house.building_name)  # "주택"
    print(house.cost_gold)      # 100
```

### 7.2. Phase 2: 로직 테스트 (UI 없이)

```gdscript
# test_map.gd
func _ready():
    var house = load("res://scripts/resources/house_01.tres")

    # 강제로 건물 선택
    ConstructionManager.select_building(house, ConstructionManager.ConstructionMode.SINGLE)

    # 클릭으로 건물 배치 테스트
```

### 7.3. Phase 3: 통합 테스트 (UI 포함)

**UI 구현 후 테스트 (ui_system_design.md 참고):**

- [ ] 건물 선택 → select_building() 호출 확인
- [ ] 미리보기가 마우스 따라다님
- [ ] 녹색/빨간색으로 건설 가능 여부 표시
- [ ] 클릭으로 건물 배치 성공
- [ ] building_placed 시그널 발송 확인
- [ ] 드래그로 도로 연속 배치 성공
- [ ] ESC로 건설 취소 동작

---

## 8. 확장 가능성

### 8.1. 새 건물 추가 절차

**1단계: Resource 파일 생성 (1분)**
```
Godot 에디터:
- FileSystem → scripts/resources/ 우클릭
- Create New → Resource → BuildingData
- 이름: windmill_01.tres
- Inspector에서 데이터 입력
```

**2단계: Database 등록 (10초)**
```gdscript
# building_database.gd
const BUILDINGS: Array[BuildingData] = [
    # ...
    preload("res://scripts/resources/windmill_01.tres"),  # ← 1줄 추가
]
```

**완료!**
- ✅ 건설 메뉴에 자동 표시
- ✅ 배치 가능
- ✅ 비용 시스템 자동 적용

### 8.2. 미래 확장

**업그레이드 시스템:**
```gdscript
# BuildingData에 추가
@export var upgrade_to: BuildingData = null
@export var upgrade_cost_gold: int = 200
```

**특수 효과:**
```gdscript
# BuildingData에 추가
@export var produces_resource: String = "food"  # 생산 자원
@export var production_rate: float = 10.0      # 생산 속도
```

**건물 애니메이션:**
```gdscript
# BuildingData에 추가
@export var idle_animation: String = "idle"
@export var working_animation: String = "working"
```

---

## 9. 참고 문서

- `docs/prd.md`: 건설 시스템 요구사항 (2.11)
- `docs/design/resource_based_entity_design.md`: Resource 패턴 상세
- `docs/design/tile_system_design.md`: 그리드 시스템 연동
- **`docs/design/construction_menu_ui_redesign.md`**: 하단 바 건설 메뉴 UI 재설계 (⭐ 최신 UI 디자인)
- **`docs/design/ui_system_design.md`**: 전체 UI 시스템 설계
- Godot 공식 문서: [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

---

## 10. 요약

### 핵심 파일 구조

**이 문서에서 다루는 부분:**

```
scripts/
├── resources/
│   ├── building_data.gd         # Resource 클래스 정의
│   ├── house_01.tres            # 주택 데이터
│   ├── farm_01.tres             # 농장 데이터
│   └── ...
├── config/
│   └── building_database.gd     # 건물 목록 관리
└── managers/
    └── construction_manager.gd  # 건설 로직 (시그널 포함)
```

**UI 부분 (별도 문서):**

```
scripts/ui/
├── construction_menu.gd         # 건설 메뉴 (ui_system_design.md)
└── building_button.gd           # 건물 버튼 (ui_system_design.md)

scenes/ui/
├── construction_menu.tscn       # (ui_system_design.md)
└── building_button.tscn         # (ui_system_design.md)
```

### 개발 체크리스트

**Phase 1: 데이터 (이 문서)**
- [ ] BuildingData.gd 작성
- [ ] house_01.tres, farm_01.tres 생성
- [ ] BuildingDatabase.gd 작성

**Phase 2: 로직 (이 문서)**
- [ ] ConstructionManager.gd 작성
- [ ] 미리보기 시스템 구현
- [ ] 건설 가능 검증 로직
- [ ] 시그널 정의 및 구현

**Phase 3: UI (ui_system_design.md)**
- [ ] SimpleConstructionMenu.tscn 생성 (최소 UI)
- [ ] ConstructionMenu.tscn 생성 (Resource 기반)
- [ ] BuildingButton.tscn 생성
- [ ] 시그널 연결

**Phase 4: 통합**
- [ ] test_map.tscn에 통합
- [ ] 전체 워크플로우 테스트

---

## 11. 결론

이 문서는 **건설 시스템의 데이터와 로직**에 집중합니다:

### 핵심 구성 요소

1. **BuildingData (Resource)**: 건물의 모든 정보를 담는 그릇
   - 이름, 비용, 크기, 카테고리 등
   - .tres 파일로 에디터에서 편집

2. **BuildingDatabase**: 모든 건물 데이터 중앙 관리
   - ID 기반 검색
   - 카테고리별 필터링

3. **ConstructionManager (Logic)**: 건설 로직 핵심
   - 건설 모드 관리 (SINGLE/DRAG)
   - 미리보기 시스템
   - 건설 가능 검증
   - 시그널 기반 UI 통신

### 장점

- ✅ 새 건물 추가가 매우 쉬움 (.tres 파일 1개)
- ✅ UI/Logic이 완전히 분리됨 (시그널 통신)
- ✅ 저장/로드 시스템 확장 용이
- ✅ 모딩 지원 가능

### 다음 단계

1. **UI 구현**: `docs/design/ui_system_design.md` 참고
   - 최소 UI (30분)
   - Resource 기반 동적 UI

2. **Resource 패턴 확장**: `docs/design/resource_based_entity_design.md` 참고
   - 유닛, NPC 등 다른 엔티티에 적용

3. **통합 테스트**: 데이터 + 로직 + UI 전체 연동
