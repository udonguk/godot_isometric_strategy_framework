# Godot에서의 Flux 패턴 적용 가이드

## 📖 개요

이 문서는 웹 프레임워크의 Flux 패턴을 Godot 게임 엔진에 어떻게 적용하는지 설명합니다.

**핵심**: Godot는 웹이 아니므로 **Godot 스타일의 Flux**를 사용해야 합니다.

---

## 🔄 Flux 패턴이란?

### 원본 Flux (웹)

Facebook이 제안한 단방향 데이터 흐름 패턴:

```
Action → Dispatcher → Store → View
  ↑                              ↓
  └──────────────────────────────┘
```

**핵심 원칙:**
1. **단방향 데이터 흐름**: Action → Store → View
2. **Store는 상태 소유**: View는 Store 구독
3. **View는 Store 변경 불가**: Action을 통해서만

---

## 🎮 Godot Flux 패턴

### Godot 스타일 Flux

```
User Input → Manager (Store) → Signal → View (UI/Scene)
   (버튼)   (BuildingManager)  (시그널)  (ConstructionMenu)
```

**Godot 변환:**
- **Action**: 사용자 입력, 버튼 클릭
- **Dispatcher**: 함수 호출 (Manager의 public 메서드)
- **Store**: Manager (Autoload 싱글톤)
- **View**: UI 노드, 씬

---

## 🏗️ 아키텍처 비교

### React (웹) Flux
```jsx
// Store (Redux)
const store = createStore(reducer);

// Action
store.dispatch({ type: 'ADD_BUILDING', building: {...} });

// View
function BuildingList() {
  const buildings = useSelector(state => state.buildings);
  return <div>{buildings.map(...)}</div>;
}
```

### Godot Flux
```gdscript
# Store (Autoload)
# building_manager.gd
extends Node
var buildings: Dictionary = {}
signal building_added(building)

func add_building(pos, data):
    buildings[pos] = data
    building_added.emit(data)

# View
# building_list.gd
func _ready():
    BuildingManager.building_added.connect(_on_building_added)

func _on_building_added(building):
    update_ui()
```

---

## 📊 계층 구조 설계

### ❌ 잘못된 구조 (계층 위반)

```
main (Node2D)
├── GameWorld
│   └── BuildingManager ← Store가 View 아래!
└── UI
    └── ConstructionMenu
        └── BuildingManager 참조 필요 ← 형제의 자식 참조 (위반!)
```

**문제점:**
1. Store가 View보다 하위 (Flux 위반)
2. UI가 GameWorld의 자식 참조 (계층 위반)
3. 의존성 방향이 복잡

### ✅ 올바른 구조 (Autoload)

```
[Autoload Layer - 전역]
└── BuildingManager (Store) ← 최상위

[Scene Tree]
main (Node2D)
├── GameWorld (View)
│   └── BuildingManager 사용 (읽기)
└── UI (View)
    └── ConstructionMenu
        └── BuildingManager 사용 (Action 발송)
```

**장점:**
1. Store가 View보다 상위 (Flux 준수)
2. 모든 View가 동등하게 접근
3. 계층 구조 깔끔

---

## 🔄 데이터 흐름

### 전체 흐름도

```
1. User Input
   ↓
2. View (UI) → Action 발송
   BuildingManager.place_building(pos, data)
   ↓
3. Store (Manager) → 상태 변경
   buildings[pos] = building
   ↓
4. Signal 발생
   building_placed.emit(data, pos)
   ↓
5. View (UI/Scene) → UI 업데이트
   _on_building_placed(data, pos)
```

### 코드 예시

```gdscript
# === Store (Autoload) ===
# building_manager.gd
extends Node

signal building_placed(data, pos)
signal building_removed(pos)

var buildings: Dictionary = {}

# Action Handler
func place_building(pos: Vector2i, data: BuildingData) -> bool:
    if not can_place(pos):
        return false

    # 상태 변경
    buildings[pos] = create_building_entity(pos, data)

    # Signal 발송 (View에 알림)
    building_placed.emit(data, pos)
    return true

# === View 1: UI ===
# construction_menu.gd
extends Control

func _on_house_button_pressed():
    # Action 발송
    var data = BuildingDatabase.get_building_by_id("house_01")
    BuildingManager.place_building(target_pos, data)

# === View 2: Game Scene ===
# map.gd
extends Node2D

func _ready():
    # Store 구독
    BuildingManager.building_placed.connect(_on_building_placed)

func _on_building_placed(data, pos):
    # UI 업데이트
    print("Building placed: ", data.name)
```

---

## 🎯 Godot Flux 핵심 원칙

### 1. Manager = Store (항상 Autoload)

```gdscript
# ✅ 올바른 예
# building_manager.gd (Autoload)
extends Node

var buildings: Dictionary = {}  # 상태

# ❌ 잘못된 예
# building_manager.gd (씬에 배치)
extends Node2D  # 특정 씬에 종속
```

**이유**: Store는 전역이거나 최소한 View보다 상위에 있어야 함

### 2. 단방향 데이터 흐름

```gdscript
# ✅ 올바른 흐름
View → Manager 메서드 호출 → Signal → View 업데이트

# ❌ 잘못된 흐름
View ←→ Manager 직접 변수 접근
```

**나쁜 예:**
```gdscript
# ui.gd
func update():
    var buildings = BuildingManager.buildings  # 직접 접근
    BuildingManager.buildings[pos] = building  # 직접 변경! (나쁨)
```

**좋은 예:**
```gdscript
# ui.gd
func update():
    BuildingManager.place_building(pos, data)  # 메서드 호출
```

### 3. Signal로 통신 (Flux의 Dispatcher)

```gdscript
# building_manager.gd (Store)
signal building_placed(data, pos)
signal building_removed(pos)
signal building_updated(pos, new_data)

func place_building(...):
    # 상태 변경 후
    building_placed.emit(data, pos)  # 모든 구독자에게 알림

# ui.gd (View)
func _ready():
    BuildingManager.building_placed.connect(_on_placed)
    BuildingManager.building_removed.connect(_on_removed)
```

### 4. View는 읽기 전용

```gdscript
# ✅ 올바른 예
func get_building_count() -> int:
    return BuildingManager.get_building_count()  # getter 사용

# ❌ 잘못된 예
func remove_building():
    BuildingManager.buildings.erase(pos)  # 직접 수정 (나쁨!)
```

---

## 🔀 Godot vs React Flux 비교

| 구성 요소 | React Flux | Godot Flux |
|----------|------------|------------|
| **Action** | `dispatch({ type: ... })` | 메서드 호출 `Manager.do_action()` |
| **Dispatcher** | Redux Store | Manager의 public 메서드 |
| **Store** | Redux State | Manager (Autoload) |
| **Subscribe** | `useSelector`, `connect` | Signal 연결 `.connect()` |
| **Update View** | React re-render | Signal 핸들러에서 수동 업데이트 |

### Action 발송 비교

```jsx
// React
dispatch({ type: 'PLACE_BUILDING', payload: { pos, data } });
```

```gdscript
# Godot
BuildingManager.place_building(pos, data)
```

### Store 구독 비교

```jsx
// React
const buildings = useSelector(state => state.buildings);
useEffect(() => { ... }, [buildings]);
```

```gdscript
# Godot
func _ready():
    BuildingManager.building_placed.connect(_on_building_placed)

func _on_building_placed(data, pos):
    update_ui()
```

---

## 🛠️ 실전 예제: 건설 시스템

### Store (BuildingManager)

```gdscript
# building_manager.gd (Autoload)
extends Node

# === State ===
var buildings: Dictionary = {}
var is_placement_mode: bool = false
var selected_building_data: BuildingData = null

# === Signals (View에 알림) ===
signal building_placement_started(data)
signal building_placed(data, pos)
signal building_placement_failed(reason)
signal building_removed(pos)

# === Actions ===
func start_placement(data: BuildingData):
    is_placement_mode = true
    selected_building_data = data
    building_placement_started.emit(data)

func place_building(pos: Vector2i) -> bool:
    if not can_place(pos):
        building_placement_failed.emit("Cannot place here")
        return false

    buildings[pos] = create_entity(pos, selected_building_data)
    building_placed.emit(selected_building_data, pos)

    is_placement_mode = false
    selected_building_data = null
    return true

func cancel_placement():
    is_placement_mode = false
    selected_building_data = null
    building_placement_failed.emit("Cancelled")

# === Getters (읽기 전용) ===
func is_in_placement_mode() -> bool:
    return is_placement_mode

func get_building_at(pos: Vector2i):
    return buildings.get(pos)
```

### View 1: UI (ConstructionMenu)

```gdscript
# construction_menu.gd
extends Control

var building_manager = null

func initialize(manager):
    building_manager = manager

    # Store 구독
    manager.building_placement_started.connect(_on_started)
    manager.building_placed.connect(_on_placed)
    manager.building_placement_failed.connect(_on_failed)

# Action 발송
func _on_house_button_pressed():
    var data = BuildingDatabase.get_building_by_id("house_01")
    building_manager.start_placement(data)  # ← Action!

# Signal 핸들러 (View 업데이트)
func _on_started(data):
    print("Placement started: ", data.name)
    highlight_button(data.id)

func _on_placed(data, pos):
    print("Building placed at ", pos)
    unhighlight_buttons()

func _on_failed(reason):
    show_error(reason)
```

### View 2: Map (test_map)

```gdscript
# test_map.gd
extends Node2D

func _ready():
    # Store 구독
    BuildingManager.building_placed.connect(_on_building_placed)
    BuildingManager.building_removed.connect(_on_building_removed)

func _unhandled_input(event):
    if event is InputEventMouseButton and event.pressed:
        if BuildingManager.is_in_placement_mode():
            var grid_pos = GridSystem.world_to_grid(get_global_mouse_position())
            BuildingManager.place_building(grid_pos)  # ← Action!

# Signal 핸들러 (View 업데이트)
func _on_building_placed(data, pos):
    print("Map: Building added to ", pos)
    # 시각적 업데이트는 BuildingManager가 create_entity()에서 처리

func _on_building_removed(pos):
    print("Map: Building removed from ", pos)
```

---

## 🚫 안티패턴

### 1. View가 Store 직접 수정

```gdscript
# ❌ 나쁜 예
func _on_button_pressed():
    BuildingManager.buildings[pos] = building  # 직접 수정!
    BuildingManager.is_placement_mode = false  # 직접 수정!
```

**문제**: 다른 View에 알림이 가지 않음

**✅ 올바른 예:**
```gdscript
func _on_button_pressed():
    BuildingManager.place_building(pos, data)  # 메서드 호출
```

### 2. Store가 View 참조

```gdscript
# ❌ 나쁜 예
# building_manager.gd
var ui_menu: Control = null  # View 참조 (나쁨!)

func place_building(pos, data):
    buildings[pos] = data
    ui_menu.update_ui()  # View 직접 호출 (나쁨!)
```

**✅ 올바른 예:**
```gdscript
# building_manager.gd
func place_building(pos, data):
    buildings[pos] = data
    building_placed.emit(data, pos)  # Signal로 알림
```

### 3. 순환 참조

```gdscript
# ❌ 나쁜 예
# manager_a.gd
func foo():
    ManagerB.bar()

# manager_b.gd
func bar():
    ManagerA.foo()  # 순환!
```

**✅ 올바른 예:** Signal로 분리
```gdscript
# manager_a.gd
signal action_completed

func foo():
    # ...
    action_completed.emit()

# manager_b.gd
func _ready():
    ManagerA.action_completed.connect(_on_action_completed)
```

---

## 🎯 Best Practices

### 1. Manager는 항상 Autoload
```gdscript
# project.godot
[autoload]
BuildingManager="*res://scripts/managers/building_manager.gd"
```

### 2. Signal 네이밍 컨벤션
```gdscript
# 과거형 (이미 발생)
signal building_placed
signal building_removed

# 현재진행형 (진행 중)
signal building_placing
signal building_removing
```

### 3. Action 메서드는 명확한 이름
```gdscript
# ✅ 좋은 이름
func place_building(...)
func remove_building(...)
func start_placement(...)

# ❌ 나쁜 이름
func do_something(...)
func update(...)
func process(...)
```

### 4. Getter만 public, State는 private
```gdscript
# building_manager.gd
var _buildings: Dictionary = {}  # private

func get_building_at(pos) -> Node:
    return _buildings.get(pos)

func get_all_buildings() -> Array:
    return _buildings.values()
```

---

## 📊 현재 프로젝트 적용

### Flux 구조

```
[Store Layer - Autoload]
├── GameConfig (설정)
├── GridSystem (좌표 시스템)
├── SelectionManager (선택 상태)
├── InputManager (입력 관리)
├── BuildingDatabase (정적 데이터)
└── BuildingManager (건물 상태) ← 핵심 Store

[View Layer - Scene Tree]
main
├── test_map (View)
│   └── BuildingManager 구독 (building_placed)
└── UILayer
    └── ConstructionMenu (View)
        └── BuildingManager 구독 (building_placed, placement_failed)
```

### 데이터 흐름

```
1. User: "주택 버튼 클릭"
   ↓
2. ConstructionMenu (View): Action 발송
   BuildingManager.start_placement(house_data)
   ↓
3. BuildingManager (Store): 상태 변경
   is_placement_mode = true
   ↓
4. BuildingManager (Store): Signal 발송
   building_placement_started.emit(house_data)
   ↓
5. ConstructionMenu (View): UI 업데이트
   _on_placement_started() → 버튼 강조
   ↓
6. User: "맵 클릭"
   ↓
7. test_map (View): Action 발송
   BuildingManager.place_building(grid_pos)
   ↓
8. BuildingManager (Store): 상태 변경 + 엔티티 생성
   buildings[pos] = entity
   ↓
9. BuildingManager (Store): Signal 발송
   building_placed.emit(data, pos)
   ↓
10. Views: UI 업데이트
    - ConstructionMenu: 버튼 강조 해제
    - test_map: 로그 출력
```

---

## 📖 참고 자료

- [Flux 공식 문서](https://facebook.github.io/flux/)
- [Redux (Flux 구현)](https://redux.js.org/)
- [Godot Signals](https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html)
- 현재 프로젝트: `docs/implementation/godot_autoload_guidelines.md`

---

## 요약

### Godot Flux 패턴 = Autoload + Signal

1. **Store = Manager (Autoload)**
   - 전역 상태 관리
   - 최상위 또는 전역에 위치

2. **Action = Manager 메서드 호출**
   - `BuildingManager.place_building()`
   - View → Store 단방향

3. **Dispatcher = Signal**
   - Store → View 알림
   - 여러 View가 구독

4. **View = Scene/UI**
   - Store 구독 (Signal 연결)
   - 읽기 전용 접근
   - Action 발송만

### 🎯 핵심
**Godot는 React가 아닙니다. Godot 철학(Autoload + Signal)으로 Flux를 구현하세요.**
