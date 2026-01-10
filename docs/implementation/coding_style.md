# 코딩 스타일 가이드 (Coding Style Guide)

이 문서는 "isometric_strategy_framework" 프로젝트의 코드 작성 규칙, 네이밍 컨벤션, 에러 처리 방식을 정의합니다.

## 1. Godot 표준 준수

- Godot 공식 문서의 [GDScript 스타일 가이드](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)를 따릅니다.
- **네이밍 규칙**:
  - 클래스/노드 이름: `PascalCase` (예: `PlayerController`)
  - 변수/함수 이름: `snake_case` (예: `current_health`, `get_player_position()`)
  - 상수 이름: `CONSTANT_CASE` (예: `MAX_SPEED`)
  - 프라이빗 멤버: `_` 접두사 사용 (예: `_calculate_damage()`)

## 2. 정적 타이핑 (Static Typing)

모든 변수와 함수에 타입을 명시하여 코드의 안정성과 가독성을 높입니다.

### 2.1. 변수 선언
```gdscript
# Bad
var health = 100
var player_name

# Good
var health: int = 100
var player_name: String = ""
```

### 2.2. 함수 선언
매개변수와 반환 타입을 반드시 명시합니다. 반환값이 없으면 `-> void`를 사용합니다.
```gdscript
# Bad
func take_damage(amount):
    health -= amount

# Good
func take_damage(amount: int) -> void:
    health -= amount
```

## 3. 에러 처리 가이드라인 (Error Handling)

게임 개발 중 발생하는 다양한 상황에 대한 일관된 에러 처리 방식을 정의합니다.

### 3.1. 로그 레벨 구분

GDScript는 세 가지 로그 레벨을 제공합니다:

#### `push_error()` - 치명적 오류 (Critical Error)
**사용 시점**: 프로그램이 정상적으로 실행될 수 없는 치명적인 오류

**예시:**
- 필수 노드/리소스 초기화 실패
- 필수 레퍼런스가 `null`인 상태에서 접근
- 시스템이 정상 동작할 수 없는 상태

```gdscript
# ✅ 올바른 사용 예
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if not ground_layer:
		push_error("[GridSystem] ground_layer가 초기화되지 않았습니다! initialize()를 먼저 호출하세요.")
		return Vector2.ZERO  # 기본값 반환 (크래시 방지)

func create_building(grid_pos: Vector2i) -> Node2D:
	if not buildings_parent:
		push_error("[BuildingManager] 부모 노드가 설정되지 않았습니다. initialize()를 먼저 호출하세요.")
		return null  # 실행 불가능하므로 null 반환
```

**특징:**
- Godot 에디터 하단에 **빨간색**으로 표시됨
- 스택 트레이스가 함께 출력되어 디버깅에 유용
- 반드시 **안전한 기본값 반환** 또는 **조기 반환**(early return)으로 크래시 방지

---

#### `push_warning()` - 경고 (Warning)
**사용 시점**: 계속 실행 가능하지만 의도와 다르거나 잠재적 문제가 있는 상황

**예시:**
- 중복된 작업 시도 (이미 존재하는 건물 생성)
- 잘못된 타입이 전달됨 (타입 체크 실패)
- 유효하지 않은 입력값 (범위 밖 좌표, Navigation 불가능한 위치)
- 존재하지 않는 엔티티 제거 시도

```gdscript
# ✅ 올바른 사용 예
func create_building(grid_pos: Vector2i) -> Node2D:
	if grid_buildings.has(grid_pos):
		push_warning("[BuildingManager] 이미 건물이 존재: ", grid_pos)
		return grid_buildings[grid_pos]  # 기존 건물 반환 (계속 실행 가능)

func _handle_right_click() -> void:
	if not GridSystem.is_valid_navigation_position(grid_pos):
		push_warning("[InputManager] Navigation 불가능한 위치: ", grid_pos)
		return  # 명령 무시하고 계속 실행

func _on_unit_clicked(unit: Node2D) -> void:
	if not unit is UnitEntity:
		push_warning("[InputManager] 유닛이 아닌 엔티티를 유닛으로 처리하려고 시도: ", unit.name)
		return  # 타입 불일치 시 무시
```

**특징:**
- Godot 에디터 하단에 **노란색**으로 표시됨
- 스택 트레이스 포함
- 게임은 계속 실행되지만 개발자가 수정해야 할 부분을 알려줌

---

#### `print()` - 정보 로그 (Info Log)
**사용 시점**: 정상적인 동작 과정을 기록하는 디버그 정보

**예시:**
- 초기화 완료 메시지
- 엔티티 생성/삭제 로그
- 상태 변경 로그
- 사용자 입력 처리 로그

```gdscript
# ✅ 올바른 사용 예
func initialize(tile_layer: TileMapLayer) -> void:
	ground_layer = tile_layer
	print("[GridSystem] 초기화 완료 - Ground Layer: ", tile_layer.name)

func create_building(grid_pos: Vector2i) -> Node2D:
	# ... 건물 생성 로직 ...
	print("[BuildingManager] 건물 생성: Grid ", grid_pos, " → World ", world_pos)
	return building

func _handle_left_click() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	print("[InputManager] 좌클릭 - 마우스 위치: ", mouse_pos)
```

**특징:**
- Godot 에디터 하단에 **흰색**으로 표시됨
- 스택 트레이스 없음 (가벼움)
- 게임 흐름을 추적하는 용도

---

### 3.2. 에러 메시지 작성 규칙

#### 형식
```gdscript
"[매니저/시스템명] 상황 설명 + 해결 방법"
```

#### 예시

**❌ 나쁜 예:**
```gdscript
push_error("초기화 안됨")  # 어떤 시스템? 어떻게 해결?
push_warning("잘못된 값")   # 무엇이 잘못됨? 어떤 값?
```

**✅ 좋은 예:**
```gdscript
push_error("[GridSystem] ground_layer가 초기화되지 않았습니다! initialize()를 먼저 호출하세요.")
push_warning("[BuildingManager] 이미 건물이 존재: Grid(5, 3)")
push_warning("[InputManager] Navigation 불가능한 위치: Grid(10, 15)")
```

#### 포함 요소
1. **시스템 이름**: `[GridSystem]`, `[BuildingManager]` 등 (어디서 발생?)
2. **상황 설명**: 무엇이 잘못되었는지
3. **컨텍스트**: 관련 변수 값 (그리드 좌표, 엔티티 이름 등)
4. **해결 방법** (선택): `initialize()를 먼저 호출하세요` 등

---

### 3.3. 실전 체크리스트

코드 작성 시 다음 질문으로 로그 레벨을 결정하세요:

1. **"이 상황에서 게임이 정상 동작할 수 있는가?"**
   - 아니요 → `push_error()`
   - 예 → 2번으로

2. **"개발자가 알아야 할 잠재적 문제인가?"**
   - 예 → `push_warning()`
   - 아니요 → `print()`

3. **"에러 메시지에 문제 해결 힌트가 포함되어 있는가?"**
   - 아니요 → 메시지에 해결 방법 추가

---

### 3.4. 안티 패턴 (하지 말 것)

**❌ 정상 동작을 `push_error()`로 처리**
```gdscript
# 잘못된 예: 건물이 없는 것은 정상 상황일 수 있음
func get_building(grid_pos: Vector2i):
	if not grid_buildings.has(grid_pos):
		push_error("건물 없음!")  # ❌ 과도한 에러
		return null
```

**✅ 올바른 처리:**
```gdscript
func get_building(grid_pos: Vector2i):
	if not grid_buildings.has(grid_pos):
		return null  # 정상 흐름 - 에러 아님
```

---

**❌ `push_warning()`을 남발**
```gdscript
# 잘못된 예: 정상 입력도 warning으로 처리
func move_to_grid(grid_pos: Vector2i) -> void:
	push_warning("이동 시작")  # ❌ 정상 동작인데 warning?
```

**✅ 올바른 처리:**
```gdscript
func move_to_grid(grid_pos: Vector2i) -> void:
	print("[UnitEntity] 이동 시작: Grid ", grid_pos)  # ✅ 정상 로그
```

---

**❌ 에러 메시지에 컨텍스트 부족**
```gdscript
push_error("실패")  # ❌ 무엇이? 왜?
```

**✅ 올바른 처리:**
```gdscript
push_error("[BuildingManager] 건물 생성 실패 - 부모 노드가 설정되지 않았습니다. initialize()를 먼저 호출하세요.")
```

---

### 3.5. 요약 표

| 로그 레벨 | 사용 시점 | 색상 | 스택 트레이스 | 예시 |
|----------|----------|------|-------------|------|
| `push_error()` | 치명적 오류 (실행 불가) | 빨강 | O | 초기화 실패, null 참조 |
| `push_warning()` | 경고 (실행 가능, 문제 있음) | 노랑 | O | 중복 생성, 잘못된 입력 |
| `print()` | 정상 동작 로그 | 흰색 | X | 초기화 완료, 엔티티 생성 |
