# 입력 시스템 설계 (Input System Design)

## 🎯 목표 (Objective)

게임 내 모든 입력을 중앙에서 관리하고, **이벤트 전파(Event Propagation) 문제**를 해결하여 정확한 엔티티 선택 및 상호작용을 구현합니다.

**핵심 목표:**
1. 유닛/건물 클릭 시 정확한 엔티티만 선택
2. 빈 공간 클릭 시에만 선택 해제
3. 우선순위 기반 입력 처리 (유닛 > 건물 > 땅)
4. 확장 가능한 입력 시스템 구조

---

## ⚠️ 문제 정의 (Problem Statement)

### 현재 문제: 이벤트 전파 (Event Propagation)

웹의 **이벤트 버블링(Event Bubbling)**과 유사한 문제가 발생하고 있습니다.

```
마우스 클릭 발생
    ↓
┌─────────────────────────────────────┐
│ 모든 곳에서 동시에 이벤트 수신      │
├─────────────────────────────────────┤
│ 1. UnitEntity.input_event          │ <- "유닛 클릭" ✅
│ 2. TestMap._unhandled_input        │ <- "빈 공간" ❌ (잘못!)
│ 3. Main._unhandled_input           │ <- "빈 공간" ❌ (잘못!)
└─────────────────────────────────────┘
    ↓
TestMap/Main에서 SelectionManager.deselect_all() 호출
    ↓
기존 선택 해제됨 (다중 선택 실패!)
```

### 웹 vs Godot 비교

| 웹 (Event Bubbling) | Godot (Input Propagation) |
|---------------------|---------------------------|
| 자식 → 부모 순차 전파 | 씬 트리 전체에 동시 방송 |
| `e.stopPropagation()` | `get_viewport().set_input_as_handled()` |
| DOM 계층 구조 | 입력 처리 순서 |

### 문제의 핵심

**`set_input_as_handled()`가 작동하지 않는 이유:**
- Godot의 입력 처리는 **병렬 실행** 가능
- `_unhandled_input()`이 **이미 실행 중**일 때 `set_input_as_handled()` 호출 → 너무 늦음!

```
타이밍 문제:
1. TestMap._unhandled_input() 시작 ←┐
2. Main._unhandled_input() 시작    │ 이미 실행 중!
3. UnitEntity.input_event 실행     │
4. set_input_as_handled() 호출 ────┘ (효과 없음)
```

---

## 🏗️ 해결 방법: 중앙 컨트롤러 패턴 (Central Controller Pattern)

### 핵심 아이디어

**입력을 전담하는 중앙 컨트롤러(InputManager)를 생성**하고, Physics Query를 사용하여 **우선순위 기반 순차 검사**를 수행합니다.

```
클릭 발생
    ↓
InputManager (단일 진입점)
    ↓
Physics Query (순차적)
    ├─ 1순위: 유닛 레이어 검사
    │   └─ 발견 → 유닛 선택 → return ✅
    │
    ├─ 2순위: 건물 레이어 검사
    │   └─ 발견 → 건물 선택 → return ✅
    │
    └─ 3순위: 빈 공간
        └─ SelectionManager.deselect_all() ✅
```

### 장점

- ✅ **단일 책임 원칙 (SRP)**: 입력 처리가 한 곳에 집중
- ✅ **명확한 우선순위**: 레이어 기반 순차 검사
- ✅ **이벤트 전파 문제 해결**: 중앙에서 제어
- ✅ **확장 가능**: 새 엔티티 타입 추가 용이
- ✅ **테스트 용이**: 입력 로직이 격리됨

---

## 📊 Collision Layer 설계

### Layer 구조

| Layer | 이름 | 용도 | 예시 |
|-------|------|------|------|
| **1** | Ground | 땅, 타일맵 | TileMapLayer |
| **2** | Units | 유닛 | UnitEntity (CharacterBody2D) |
| **3** | Buildings | 건물 | BuildingEntity (Node2D + Area2D) |
| **4** | UI | UI 요소 (미래 확장) | 버튼, 패널 등 |

### Collision Mask 전략

**InputManager의 Physics Query:**
```gdscript
# 1차 검사: 유닛만
query.collision_mask = 0b0010  # Layer 2 (Units)

# 2차 검사: 건물만
query.collision_mask = 0b0100  # Layer 3 (Buildings)

# 3차 검사: 땅 (필요 시)
query.collision_mask = 0b0001  # Layer 1 (Ground)
```

### 엔티티별 설정

```gdscript
# UnitEntity (CharacterBody2D)
collision_layer = 2   # Layer 2 (Units)
collision_mask = 1    # 땅과만 충돌

# BuildingEntity (Area2D)
collision_layer = 4   # Layer 3 (Buildings)
collision_mask = 0    # 충돌 감지 불필요

# GroundTileMapLayer
collision_layer = 1   # Layer 1 (Ground)
```

---

## 🔧 InputManager 아키텍처

### 클래스 구조

```gdscript
class_name InputManager
extends Node

## Godot Autoload 싱글톤으로 등록
## 게임 내 모든 입력을 중앙 관리

# ============================================================
# 입력 처리 우선순위
# ============================================================

enum ClickPriority {
	UNIT = 2,      # 유닛 (최우선)
	BUILDING = 3,  # 건물 (2순위)
	GROUND = 1     # 땅 (최하위)
}

# ============================================================
# 입력 처리
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click()


## 좌클릭 처리 (선택)
func _handle_left_click() -> void:
	var mouse_pos = get_viewport().get_mouse_position()

	# 1순위: 유닛 검사
	var unit = _query_entity_at(mouse_pos, ClickPriority.UNIT)
	if unit:
		_on_unit_clicked(unit)
		return

	# 2순위: 건물 검사
	var building = _query_entity_at(mouse_pos, ClickPriority.BUILDING)
	if building:
		_on_building_clicked(building)
		return

	# 3순위: 빈 공간
	_on_empty_space_clicked(mouse_pos)


## 우클릭 처리 (이동 명령)
func _handle_right_click() -> void:
	# 선택된 유닛들 이동
	pass


## 특정 레이어의 엔티티 검색
func _query_entity_at(screen_pos: Vector2, layer: ClickPriority):
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var space = get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collision_mask = 1 << (layer - 1)  # Layer를 Mask로 변환
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var result = space.intersect_point(query, 1)

	if result.is_empty():
		return null

	return result[0].collider


## 유닛 클릭 처리
func _on_unit_clicked(unit) -> void:
	var multi_select = Input.is_key_pressed(KEY_CTRL)
	SelectionManager.select_unit(unit, multi_select)
	print("[InputManager] 유닛 클릭: ", unit.name)


## 건물 클릭 처리
func _on_building_clicked(building) -> void:
	SelectionManager.select_building(building)
	print("[InputManager] 건물 클릭: ", building.name)


## 빈 공간 클릭 처리
func _on_empty_space_clicked(mouse_pos: Vector2) -> void:
	SelectionManager.deselect_all()
	print("[InputManager] 빈 공간 클릭")
```

---

## 📅 구현 계획 (Implementation Plan)

### Phase 1: Collision Layer 설정 ✅

**Task 1.1: Project Settings에서 Layer 정의**
- Project Settings → Layer Names → 2D Physics
- Layer 1: "ground"
- Layer 2: "units"
- Layer 3: "buildings"

**Task 1.2: 각 엔티티의 Collision Layer 설정**
- UnitEntity 씬: `collision_layer = 2`
- BuildingEntity 씬: Area2D의 `collision_layer = 4` (2^2)
- GroundTileMapLayer: `collision_layer = 1`

---

### Phase 2: InputManager 생성

**Task 2.1: InputManager Autoload 생성**
- 파일: `scripts/managers/input_manager.gd`
- Autoload 등록: Project Settings → Autoload

**Task 2.2: 기본 입력 처리 구현**
- `_unhandled_input()` 구현
- `_handle_left_click()` 구현
- `_handle_right_click()` 구현

**Task 2.3: Physics Query 구현**
- `_query_entity_at()` 구현
- Layer별 순차 검사 로직

---

### Phase 3: 기존 코드 마이그레이션

**Task 3.1: 엔티티 입력 처리 제거**
- UnitEntity: `input_event` 연결 제거
- BuildingEntity: `input_event` 연결 제거

**Task 3.2: TestMap/Main 입력 처리 제거**
- `test_map.gd`: `_unhandled_input()` 제거
- `main.gd`: `_unhandled_input()` 제거
- 빈 공간 클릭 로직 → InputManager로 이동

**Task 3.3: 이동 명령 로직 이동**
- `test_map.gd`의 `_on_move_command()` → InputManager

---

### Phase 4: 통합 및 테스트

**Task 4.1: InputManager 통합**
- SelectionManager와 연동 확인
- GridSystem 좌표 변환 확인

**Task 4.2: 전체 테스트**
- 유닛 단일 선택
- 유닛 다중 선택 (Ctrl+클릭)
- 건물 선택
- 빈 공간 클릭 시 선택 해제
- 우클릭 이동 명령

---

## 🔄 기존 코드와의 통합

### 제거할 코드

#### UnitEntity (unit_entity.gd)

```gdscript
# ❌ 제거
func _ready():
	input_pickable = true
	input_event.connect(_on_input_event)

func _on_input_event(...):
	# 전체 제거
```

#### BuildingEntity (building_entity.gd)

```gdscript
# ❌ 제거
func _on_area_input_event(...):
	# 전체 제거
```

#### TestMap (test_map.gd)

```gdscript
# ❌ 제거
func _unhandled_input(event):
	# 전체 제거

func _on_empty_click():
	# 전체 제거

func _on_move_command():
	# InputManager로 이동
```

#### Main (main.gd)

```gdscript
# ❌ 제거
func _unhandled_input(event):
	# 전체 제거

func _on_empty_click():
	# 전체 제거
```

---

## 🧪 테스트 시나리오

### TC-1: 유닛 단일 선택
- [ ] 유닛 클릭 → 선택됨
- [ ] 다른 유닛 클릭 → 이전 유닛 해제, 새 유닛 선택
- [ ] 로그: `[InputManager] 유닛 클릭: UnitEntity`

### TC-2: 유닛 다중 선택
- [ ] Ctrl+유닛1 클릭 → 유닛1 선택
- [ ] Ctrl+유닛2 클릭 → 유닛1, 2 모두 선택
- [ ] 로그: `[SelectionManager] 유닛 선택됨 (총 2개)`

### TC-3: 건물 선택
- [ ] 건물 클릭 → 선택됨 (외곽선 표시)
- [ ] 유닛 선택 후 건물 클릭 → 유닛 해제, 건물 선택
- [ ] 로그: `[InputManager] 건물 클릭: BuildingEntity`

### TC-4: 빈 공간 클릭
- [ ] 유닛 선택 후 빈 공간 클릭 → 모든 선택 해제
- [ ] 로그: `[InputManager] 빈 공간 클릭`
- [ ] "빈 공간 클릭" 로그가 **한 번만** 출력되어야 함 (중복 제거 확인)

### TC-5: 우선순위 검증
- [ ] 유닛과 건물이 겹친 위치 클릭 → 유닛 선택 (우선순위 높음)
- [ ] 로그: `[InputManager] 유닛 클릭` (건물 클릭 아님)

### TC-6: 이동 명령
- [ ] 유닛 선택 후 우클릭 → 유닛 이동
- [ ] 여러 유닛 선택 후 우클릭 → 모든 유닛 이동

---

## 🎯 성공 기준 (Success Criteria)

1. ✅ 유닛 다중 선택이 정상 작동 (Ctrl+클릭)
2. ✅ "빈 공간 클릭" 로그가 중복되지 않음 (한 번만 출력)
3. ✅ 우선순위가 정확함 (유닛 > 건물 > 땅)
4. ✅ 모든 입력 처리가 InputManager에 집중됨
5. ✅ 엔티티 클래스가 입력 로직을 포함하지 않음 (관심사 분리)

---

## 📝 참고 자료 (References)

### Godot 공식 문서
- [Input Event](https://docs.godotengine.org/en/stable/classes/class_inputevent.html)
- [Viewport.set_input_as_handled()](https://docs.godotengine.org/en/stable/classes/class_viewport.html#class-viewport-method-set-input-as-handled)
- [PhysicsPointQueryParameters2D](https://docs.godotengine.org/en/stable/classes/class_physicspointqueryparameters2d.html)
- [Collision Layers and Masks](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html#collision-layers-and-masks)

### 관련 설계 문서
- `tile_system_design.md`: 타일 시스템 설계
- `navigation_system_design.md`: 내비게이션 시스템 설계 (Phase 3 참고)

---

## 🔧 향후 확장 (Future Enhancements)

### 드래그 선택 (Drag Selection)
- 마우스 드래그로 여러 유닛 동시 선택
- `_input()` 에서 드래그 시작/끝 감지
- 선택 영역 내 유닛들을 Physics Query로 검색

### 우클릭 컨텍스트 메뉴
- 건물 우클릭 → 건물 옵션 메뉴
- 유닛 우클릭 → 유닛 명령 메뉴

### 단축키 시스템
- InputMap 활용
- `_shortcut_input()` 구현

### 모바일 터치 지원
- `InputEventScreenTouch` 처리
- 롱 프레스 감지
