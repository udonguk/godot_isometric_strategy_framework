# 아키텍처 가이드라인 (Architecture Guidelines)

이 문서는 "isometric_strategy_framework" 프로젝트의 아키텍처 설계 원칙, 디자인 패턴, 그리고 구조적 규칙을 정의합니다.

## 1. 씬 우선 개발 (Scene-First Development)

**핵심**: 모든 기능은 **씬(.tscn) 파일로 먼저** 구현합니다.

### 개발 절차
1. **씬 생성** (`scenes/` 폴더)
   - Godot 에디터에서 씬 생성
   - 필요한 노드 구조 구성

2. **스크립트 작성** (`scripts/` 폴더)
   - 씬에 연결할 로직 작성
   - 노드 타입 상속 (예: `extends Camera2D`)

3. **씬과 스크립트 연결**
   - 에디터에서 스크립트 attach
   - 노드 레퍼런스 설정 (`@onready`)

### 예시: 카메라 시스템

```
✅ 올바른 방법:
1. scenes/camera/rts_camera.tscn 생성 (Camera2D 노드)
2. scripts/camera/rts_camera.gd 작성 (extends Camera2D)
3. 씬에 스크립트 연결
4. test_map.tscn에서 인스턴스화

❌ 잘못된 방법:
- 스크립트만 작성 후 코드로 노드 생성
  var cam = Camera2D.new()
  add_child(cam)
```

### 폴더 구조 규칙
```
scenes/camera/rts_camera.tscn    # 씬 파일
scripts/camera/rts_camera.gd     # 스크립트 (같은 이름)
```

### 장점
- **재사용성**: 여러 씬에서 인스턴스화
- **시각적 편집**: 에디터에서 노드 구조 확인
- **Godot 철학**: "Everything is a Scene"

## 2. 객체 지향 및 교육적 코드 작성 (OOP & Learning)
- **책임 분리**: 각 스크립트는 하나의 명확한 역할만 수행해야 합니다 (단일 책임 원칙).
- **상속 활용**: 공통 기능은 부모 클래스로 추상화합니다 (예: `BaseEnemy` -> `GoblinEnemy`).
- **교육적 주석(Why)**: 특정 디자인 패턴이나 복잡한 구조를 사용할 때는 **"왜 이 패턴을 사용했는지"** 주석으로 설명을 남깁니다.
  ```gdscript
  # [State Pattern] 상태별 로직 분리를 통해 코드 복잡도를 낮추고 유지보수성을 높이기 위해 사용
  # IdleState는 가만히 서있을 때의 행동을 정의합니다.
  class_name IdleState extends State
  ```

## 3. 디자인 패턴 (Design Patterns)

Godot 개발 효율성과 유지보수를 위해 다음 패턴 사용을 권장합니다.

### 3.1. 상태 패턴 (State Pattern)
- **용도**: 캐릭터(플레이어, AI)의 복잡한 상태 전이(대기 -> 이동 -> 공격)를 관리할 때 사용합니다.
- **구조**: `StateMachine` 노드가 현재 상태(`State` 노드)를 관리하며, 각 상태는 별도의 스크립트로 분리합니다.
- **장점**: 거대한 `if-else` 또는 `switch` 문을 피하고, 각 상태별 로직을 독립적으로 관리할 수 있습니다.

### 3.2. 컴포넌트 패턴 (Component Pattern)
- **용도**: 기능의 재사용성을 극대화하기 위해 사용합니다. "상속보다는 구성(Composition over Inheritance)" 원칙을 따릅니다.
- **구조**: `HealthComponent`, `HitboxComponent`와 같이 특정 기능만 수행하는 노드를 만들고, 이를 캐릭터나 오브젝트에 부착하여 조립합니다.
- **장점**: 부모 클래스가 너무 비대해지는 것을 방지하고, 다양한 기능을 유연하게 조합할 수 있습니다.

### 3.3. 싱글톤 패턴 (Singleton Pattern / Autoload)
- **용도**: 게임 전체에서 공유해야 하는 데이터나 매니저(예: `GameManager`, `SoundManager`)에 사용합니다.
- **Godot 구현**: 프로젝트 설정의 **Autoload** 기능을 사용합니다.
- **주의**: 과도한 사용은 의존성을 높이므로 꼭 필요한 전역 관리에만 사용합니다.

#### Autoload 사용 규칙 (중요!)
1. **Autoload 이름 충돌 방지 (Shadowing 금지)**
   - Autoload로 등록된 이름(예: `GridSystem`)과 동일한 이름으로 `preload()`하거나 변수를 선언하지 않습니다.
   - **❌ 잘못된 예**: `const GridSystem = preload(...)` (전역 싱글톤을 가려버림 -> 오류 발생)
   - **✅ 올바른 예**: Autoload 이름은 전역에서 바로 접근 가능하므로 `preload` 없이 사용

2. **명확한 타입 구분 (class_name)**
   - Autoload 스크립트에는 `class_name`을 지정하되, Autoload 이름과 다르게 짓습니다.
   - 예: Autoload 이름이 `GridSystem`이라면, 스크립트 내 `class_name`은 `GridSystemNode`로 지정
   - 이렇게 하면 Godot 파서가 **싱글톤 인스턴스**와 **스크립트 타입**을 명확히 구분할 수 있습니다.

---

#### 3.3.3. Autoload와 테스트 가능성 (Testing with Autoloads)

**핵심 질문**: Autoload는 편리하지만 테스트가 어렵습니다. 어떻게 균형을 잡을까요?

Godot의 Autoload는 **단순함과 강력함**을 제공하지만, **전역 상태(Global State)**로 인해 단위 테스트를 어렵게 만듭니다. 이 섹션은 **실용적 균형**을 찾는 방법을 제시합니다.

---

##### 핵심 원칙: 모든 것을 리팩토링하지 마라!

**중요**: 클래스의 성격에 따라 전략을 선택합니다. 모든 Autoload를 의존성 주입으로 바꿀 필요는 없습니다.

---

##### 전략 1: Autoload 유지 (유틸리티 클래스)

**적용 대상:**
- ✅ 상태가 없는(Stateless) 클래스
- ✅ 순수 함수(Pure Function) 성격의 유틸리티
- ✅ 전역 설정(Configuration)

**예시:**
```gdscript
# grid_system.gd (Autoload로 유지)
class_name GridSystemNode extends Node

# 순수 함수: 입력만으로 출력 결정, 상태 변경 없음
func grid_to_world(grid_pos: Vector2i) -> Vector2:
    return ground_layer.map_to_local(grid_pos)

# 정적 변환 함수
static func grid_to_string(grid_pos: Vector2i) -> String:
    return "(%d, %d)" % [grid_pos.x, grid_pos.y]
```

**테스트 방법:**
- **통합 테스트 사용**: 실제 TileMapLayer를 포함한 테스트 씬 구성
- 단위 테스트보다 통합 테스트가 더 적합

**적용 사례:**
- `GridSystem` - 좌표 변환 함수
- `GameConfig` - 전역 설정 값

**장점:**
- ✅ Godot 철학 유지 (Autoload의 단순함)
- ✅ 코드 간결성
- ✅ 리팩토링 불필요

**단점:**
- ❌ 단위 테스트 어려움 → 통합 테스트로 대체

---

##### 전략 2: 하이브리드 접근 (선택적 의존성 주입) - **권장**

**적용 대상:**
- ✅ 복잡한 비즈니스 로직을 가진 클래스
- ✅ 상태를 관리하는 매니저 클래스
- ✅ 단위 테스트가 중요한 클래스

**예시:**
```gdscript
# building_manager.gd (하이브리드 방식)
class_name BuildingManager extends Node

# GridSystem 참조를 멤버 변수로 저장
var grid_system_ref: GridSystemNode = null

## BuildingManager 초기화
##
## @param parent_node: 건물 엔티티가 추가될 부모 노드
## @param grid_system: (선택) GridSystem 인스턴스. 생략 시 Autoload 사용
##
## 💡 설계 의도 (하이브리드 접근):
## - 실제 게임: grid_system 생략 → Autoload 사용 (편의성 유지)
## - 테스트: Mock GridSystem 주입 → 단위 테스트 가능 (테스트 용이성)
func initialize(parent_node: Node2D, grid_system: GridSystemNode = null) -> void:
    buildings_parent = parent_node

    # 의존성 주입 (Dependency Injection)
    # grid_system이 제공되면 사용, 없으면 Autoload 사용
    grid_system_ref = grid_system if grid_system else GridSystem

## 건물 건설 가능 여부 검증
func can_build_at(building_data: BuildingData, grid_pos: Vector2i) -> Dictionary:
    # ✅ Autoload 직접 접근 대신, 주입된 인스턴스 사용
    if not grid_system_ref.is_valid_position(grid_pos, building_data.grid_size):
        return {"success": false, "reason": "맵 범위를 벗어났습니다"}
    # ...
```

**실제 게임 사용 (main.gd):**
```gdscript
func _ready():
    # grid_system 생략 → Autoload 사용
    BuildingManager.initialize(entities_parent)
    # 또는 명시적으로 Autoload 전달
    BuildingManager.initialize(entities_parent, GridSystem)
```

**테스트 사용 (test_building_manager.gd):**
```gdscript
func before_each():
    # Mock GridSystem 생성
    var mock_grid_system = GridSystemNode.new()
    mock_grid_system.initialize(mock_ground_layer)

    # Mock 주입! (Autoload 대신 Mock 사용)
    building_manager.initialize(entities_parent, mock_grid_system)
```

**장점:**
- ✅ **실제 게임**: Autoload 편의성 유지 (파라미터 생략 가능)
- ✅ **테스트**: Mock 주입으로 독립적인 단위 테스트 가능
- ✅ **최소 리팩토링**: 기존 코드를 크게 변경하지 않음
- ✅ **유연성**: 런타임에 다른 인스턴스로 교체 가능

**단점:**
- 🟡 초기화 메서드에 선택적 파라미터 추가 필요

**적용 사례:**
- `BuildingManager` - 건물 생성/관리 로직
- `EnemyManager` - 적 AI 로직
- `PathfindingManager` - 경로 찾기 로직

---

##### 전략 3: 완전 의존성 주입 (Autoload 제거) - 선택적

**적용 대상:**
- 대규모 프로젝트
- 팀 개발 환경
- 엄격한 단위 테스트 요구사항

**예시:**
```gdscript
# building_manager.gd (완전 의존성 주입)
var grid_system_ref: GridSystemNode  # 항상 주입 필수

## BuildingManager 초기화
##
## @param parent_node: 건물 엔티티가 추가될 부모 노드
## @param grid_system: GridSystem 인스턴스 (필수!)
func initialize(parent_node: Node2D, grid_system: GridSystemNode) -> void:
    buildings_parent = parent_node
    grid_system_ref = grid_system  # 항상 외부에서 주입
```

**실제 게임 사용 (main.gd):**
```gdscript
func _ready():
    # ⚠️ 항상 명시적으로 전달 필요
    BuildingManager.initialize(entities_parent, GridSystem)
```

**장점:**
- ✅ 완벽한 테스트 가능성
- ✅ SOLID 원칙 완벽 준수
- ✅ 의존성이 명시적으로 드러남

**단점:**
- ❌ 보일러플레이트 코드 증가
- ❌ 초기화 복잡도 증가
- ❌ Godot의 단순함 포기

---

##### 전략 비교표

| 전략 | 적용 대상 | 실제 게임 편의성 | 테스트 가능성 | 리팩토링 비용 | 권장도 |
|------|----------|---------------|-------------|------------|-------|
| **전략 1: Autoload 유지** | 유틸리티 클래스 | ✅ 매우 높음 | 🟡 통합 테스트 | ✅ 0% | 🟢 권장 |
| **전략 2: 하이브리드** | 매니저 클래스 | ✅ 높음 | ✅ 단위 테스트 가능 | 🟡 10-20% | 🟢 **권장** |
| **전략 3: 완전 주입** | 대규모 프로젝트 | 🟡 보통 | ✅ 완벽 | ❌ 50%+ | 🔴 선택적 |

---

##### 의사결정 플로우차트

```
이 클래스가 Autoload를 사용하는가?
    ↓ Yes
상태가 없고 순수 함수인가? (예: GridSystem 좌표 변환)
    ↓ Yes → [전략 1] Autoload 유지 + 통합 테스트
    ↓ No
복잡한 비즈니스 로직이나 상태 관리가 있는가? (예: BuildingManager)
    ↓ Yes → [전략 2] 하이브리드 (선택적 의존성 주입)
    ↓ No
엄격한 단위 테스트가 필수인가?
    ↓ Yes → [전략 3] 완전 의존성 주입
    ↓ No → [전략 1] Autoload 유지
```

---

##### 실전 체크리스트

새로운 매니저/시스템을 작성할 때 확인:

1. **클래스 성격 파악**
   - [ ] 이 클래스가 상태를 관리하는가?
   - [ ] 복잡한 비즈니스 로직이 있는가?
   - [ ] 단위 테스트가 필요한가?

2. **전략 선택**
   - [ ] 순수 함수 성격 → 전략 1 (Autoload 유지)
   - [ ] 매니저 성격 → 전략 2 (하이브리드)
   - [ ] 엄격한 테스트 필요 → 전략 3 (완전 주입)

3. **구현 시 확인**
   - [ ] `initialize()` 메서드에 선택적 파라미터 추가
   - [ ] 기본값으로 Autoload 사용 (`= null`)
   - [ ] 테스트에서 Mock 주입 가능

---

##### 프로젝트 적용 가이드

**현재 프로젝트 구조:**

```
[Autoload로 유지 - 전략 1]
  GridSystem (좌표 변환 유틸리티)
  GameConfig (전역 설정)

[하이브리드 접근 - 전략 2]
  BuildingManager (건물 생성/관리)
  EnemyManager (미래 구현)
  ItemManager (미래 구현)
```

**구현 우선순위:**

1. ✅ **GridSystem은 Autoload로 유지**
   - 순수 함수 성격
   - 통합 테스트로 검증

2. ✅ **BuildingManager는 하이브리드로 리팩토링**
   - 복잡한 비즈니스 로직
   - 단위 테스트 필요

3. 🔜 **향후 매니저는 처음부터 하이브리드로 작성**
   - `initialize(required, dependency = null)` 패턴 적용

---

##### 안티 패턴 (피해야 할 것)

**❌ 안티 패턴 1: 모든 것을 완전 의존성 주입으로 변경**
```gdscript
# GridSystem까지 의존성 주입? → 과도한 엔지니어링!
func initialize(parent, grid_system, game_config, sound_manager, ...):
    # 너무 많은 파라미터 → 유지보수 악몽
```

**❌ 안티 패턴 2: Autoload를 직접 참조하면서 테스트 시도**
```gdscript
# building_manager.gd
func can_build_at(...):
    # Autoload 직접 사용 (테스트 불가능)
    if not GridSystem.is_valid_position(...):
```

**✅ 올바른 방법: 하이브리드 접근**
```gdscript
var grid_system_ref = null

func initialize(parent, grid_system = null):
    grid_system_ref = grid_system if grid_system else GridSystem

func can_build_at(...):
    # 주입된 인스턴스 사용 (테스트 가능)
    if not grid_system_ref.is_valid_position(...):
```

---

##### 핵심 교훈

1. **실용성 우선**: Godot의 Autoload는 강력한 도구. 무조건 제거할 필요 없음
2. **선택적 적용**: 클래스 성격에 맞는 전략 선택
3. **하이브리드가 최선**: 실제 게임의 편의성 + 테스트 가능성 확보
4. **점진적 개선**: 모든 것을 한 번에 리팩토링하지 말고, 필요한 부분부터 개선

> "완벽한 아키텍처는 존재하지 않는다. 상황에 맞는 최선의 선택만 있을 뿐이다."
> - Pragmatic Programmer

## 4. Godot 내장 기능 우선 사용 (중요!)

**원칙**: 기능 구현 시 **항상 Godot 내장 기능을 먼저 검토**하고 활용

### 우선순위

1. **Godot 내장 기능** (최우선)
2. Godot 플러그인/에셋
3. 직접 구현 (최후의 수단)

### 주요 내장 기능 활용 예시

| 기능 | ❌ 직접 구현 | ✅ Godot 내장 |
|------|------------|-------------|
| 경로 찾기 | A* 직접 구현 | **NavigationAgent2D + Navigation Layers** |
| 물리 충돌 | 수동 충돌 체크 | **CollisionShape2D + Area2D** |
| 애니메이션 | 수동 프레임 전환 | **AnimatedSprite2D / AnimationPlayer** |
| 타일맵 | 수동 그리드 | **TileMapLayer + TileSet** |
| 입력 처리 | 키보드 직접 체크 | **Input Actions (프로젝트 설정)** |
| 상태 머신 | 수동 구현 | **AnimationTree / 커스텀 노드** |

### 새 기능 추가 시 체크리스트

코드를 작성하기 전에 다음을 확인:

1. [ ] Godot 문서에서 관련 내장 기능 검색
2. [ ] TileMap, Navigation, Physics 등 관련 시스템 확인
3. [ ] 내장 노드 타입 검토 (Node2D, Area2D, CharacterBody2D 등)
4. [ ] 내장 기능이 없는 경우에만 직접 구현

### 예시: 경로 찾기 구현

**❌ 잘못된 접근:**
```gdscript
# A* 알고리즘 직접 구현
func find_path(start, end):
    var open_set = []
    var closed_set = []
    # 100줄의 A* 코드...
```

**✅ 올바른 접근:**
```gdscript
# Godot의 NavigationAgent2D 사용
@onready var nav_agent = $NavigationAgent2D

func move_to(target):
    nav_agent.target_position = target
    # Godot가 자동으로 경로 찾기 처리
```

### 학습 리소스

- **Godot 공식 문서**: 새 기능 전에 항상 확인
- **Built-in 노드 목록**: 에디터에서 "Add Node" 탐색
- **TileMap 시스템**: Navigation Layers, Physics Layers, Custom Data

### 이점

- ✅ 성능 최적화됨
- ✅ 버그 적음
- ✅ 유지보수 쉬움
- ✅ 에디터 통합
- ✅ 개발 속도 빠름

**중요**: 내장 기능을 모르고 직접 구현하면 시간 낭비 + 성능 저하!

## 5. SOLID 원칙 준수 (중요!)

**원칙**: 모든 코드는 **SOLID 원칙**을 준수하여 작성합니다

### 왜 SOLID가 중요한가?

게임 개발은 지속적인 변경과 확장이 필요합니다. SOLID 원칙을 따르지 않으면:
- ❌ 코드 변경 시 여러 곳을 수정해야 함 (유지보수 지옥)
- ❌ 새 기능 추가 시 기존 코드가 망가짐 (회귀 버그)
- ❌ 테스트하기 어려움 (디버깅 시간 증가)

### SOLID 5가지 원칙

#### Single Responsibility (단일 책임 원칙)

**정의**: 하나의 클래스는 하나의 책임만 가져야 함

**❌ 잘못된 예:**
```gdscript
# building_manager.gd
func create_building(grid_pos):
    # 좌표 변환도 직접 함 (책임 2개!)
    var world_pos = ground_layer.map_to_local(grid_pos)
    # 건물 생성
    var building = BuildingScene.instantiate()
```

**✅ 올바른 예:**
```gdscript
# building_manager.gd
func create_building(grid_pos):
    # 좌표 변환은 GridSystem에게 위임 (책임 1개!)
    var world_pos = GridSystem.grid_to_world(grid_pos)
    # 건물 생성만 담당
    var building = BuildingScene.instantiate()
```

**체크리스트:**
- [ ] 각 클래스/매니저가 하나의 명확한 역할만 하는가?
- [ ] 클래스 이름이 그 역할을 정확히 표현하는가?
- [ ] "그리고(AND)"로 역할을 설명해야 한다면 책임이 2개 이상!

---

#### Open/Closed (개방-폐쇄 원칙)

**정의**: 확장에는 열려있고, 수정에는 닫혀있어야 함

**❌ 잘못된 예:**
```gdscript
# building_manager.gd
func create_building(grid_pos):
    var world_pos = ground_layer.map_to_local(grid_pos)  # TileMapLayer 직접 사용
    # → TileMapLayer 변경 시 BuildingManager도 수정 필요!
```

**✅ 올바른 예:**
```gdscript
# building_manager.gd
func create_building(grid_pos):
    var world_pos = GridSystem.grid_to_world(grid_pos)  # 추상화 사용
    # → TileMapLayer 변경 시 GridSystem만 수정하면 됨!
```

**체크리스트:**
- [ ] 시스템 변경 시 한 곳만 수정하면 되는가?
- [ ] 새 기능 추가 시 기존 코드를 수정하지 않는가?

---

#### Liskov Substitution (리스코프 치환 원칙)

**정의**: 자식 클래스는 부모 클래스를 완전히 대체할 수 있어야 함

**적용 예:**
```gdscript
# base_entity.gd
class_name BaseEntity extends Node2D
func take_damage(amount: int) -> void:
    pass  # 기본 구현

# building_entity.gd
extends BaseEntity
func take_damage(amount: int) -> void:
    # 부모의 계약을 위반하지 않음!
    health -= amount
    update_visual()
```

**체크리스트:**
- [ ] 자식 클래스가 부모 클래스의 동작을 보장하는가?
- [ ] 자식 클래스로 교체해도 프로그램이 정상 작동하는가?

---

#### Interface Segregation (인터페이스 분리 원칙)

**정의**: 클라이언트는 사용하지 않는 메서드에 의존하지 않아야 함

**Godot 적용:**
- GDScript는 인터페이스가 없지만, **작은 클래스로 분리**하는 개념 적용

**❌ 잘못된 예:**
```gdscript
# entity_manager.gd (너무 많은 책임!)
func create_building()
func create_enemy()
func create_item()
func update_pathfinding()
func handle_collision()
# → 건물만 필요한데 enemy, item 메서드도 의존!
```

**✅ 올바른 예:**
```gdscript
# building_manager.gd (건물만 담당)
func create_building()
func get_building()

# enemy_manager.gd (적만 담당)
func create_enemy()
func get_enemy()
```

**체크리스트:**
- [ ] 매니저/시스템이 하나의 도메인만 담당하는가?
- [ ] 사용하지 않는 메서드를 억지로 구현하지 않는가?

---

#### Dependency Inversion (의존성 역전 원칙) ⭐ 가장 중요!

**정의**: 고수준 모듈은 저수준 모듈에 의존하지 않고, 추상화에 의존해야 함

**❌ 잘못된 예 (현재 프로젝트에서 발생했던 문제!):**
```gdscript
# building_manager.gd (고수준)
var ground_layer: TileMapLayer  # 저수준에 직접 의존! ❌

func create_building(grid_pos):
    var world_pos = ground_layer.map_to_local(grid_pos)  # TileMapLayer 직접 사용
```

**구조:**
```
BuildingManager (고수준)
    ↓ 직접 의존 ❌
TileMapLayer (저수준 - Godot 내장)
```

**문제:**
- TileMapLayer 변경 → BuildingManager도 수정 필요
- EnemyManager, ItemManager도 모두 TileMapLayer 의존
- 결합도 높음 (Tight Coupling)

**✅ 올바른 예 (리팩토링 후):**
```gdscript
# building_manager.gd (고수준)
# TileMapLayer 참조 제거! ✅

func create_building(grid_pos):
    var world_pos = GridSystem.grid_to_world(grid_pos)  # 추상화에 의존
```

**구조:**
```
BuildingManager (고수준)
    ↓
GridSystem (추상화 레이어) ← 이것이 핵심!
    ↓
TileMapLayer (저수준)
```

**장점:**
- ✅ TileMapLayer 변경 → GridSystem만 수정
- ✅ BuildingManager는 변경 불필요
- ✅ 테스트 시 GridSystem을 Mock으로 교체 가능
- ✅ 결합도 낮음 (Loose Coupling)

**체크리스트:**
- [ ] 고수준 모듈이 Godot 내장 타입을 직접 참조하지 않는가?
- [ ] 추상화 레이어(매니저, 시스템)를 거쳐서 접근하는가?
- [ ] 의존성 방향이 "고수준 → 추상화 → 저수준"인가?

---

### 실전 적용 가이드

#### 새 매니저/시스템 추가 시 체크리스트

```gdscript
# ❌ 이렇게 하지 마세요!
class_name EnemyManager extends Node

var ground_layer: TileMapLayer  # ❌ TileMapLayer 직접 의존

func create_enemy(grid_pos):
    var world_pos = ground_layer.map_to_local(grid_pos)  # ❌ 직접 호출
```

```gdscript
# ✅ 이렇게 하세요!
class_name EnemyManager extends Node

# ground_layer 참조 없음! ✅

func create_enemy(grid_pos):
    var world_pos = GridSystem.grid_to_world(grid_pos)  # ✅ GridSystem 사용
```

#### SOLID 체크리스트

코드 작성 전에 확인:

1. **Single Responsibility**
   - [ ] 이 클래스가 하는 일을 한 문장으로 설명할 수 있는가?
   - [ ] "그리고(AND)"를 사용하지 않고 설명 가능한가?

2. **Open/Closed**
   - [ ] 기능 추가 시 기존 코드를 수정하지 않는가?
   - [ ] 추상화 레이어를 사용하는가?

3. **Liskov Substitution**
   - [ ] 상속받은 클래스가 부모의 동작을 보장하는가?

4. **Interface Segregation**
   - [ ] 매니저가 하나의 도메인만 담당하는가?

5. **Dependency Inversion** ⭐
   - [ ] Godot 내장 타입을 직접 참조하지 않는가?
   - [ ] GridSystem, GameConfig 같은 추상화를 사용하는가?

---

### 실제 프로젝트 예시

**올바른 의존성 구조:**

```
[고수준 - 게임 로직]
  BuildingManager
  EnemyManager
  ItemManager
       ↓
[추상화 레이어]
  GridSystem (좌표 변환)
  GameConfig (설정)
       ↓
[저수준 - Godot 내장]
  TileMapLayer
  Sprite2D
  Area2D
```

**핵심 규칙:**
- ✅ 매니저는 **절대** Godot 내장 타입을 직접 참조하지 않음
- ✅ 모든 좌표 변환은 **GridSystem**을 통해서만
- ✅ 모든 설정값은 **GameConfig**를 통해서만
- ✅ 각 매니저는 **하나의 도메인**만 담당

---

### 안티 패턴 (절대 하지 말 것!)

```gdscript
# ❌ 안티 패턴 1: 매니저가 TileMapLayer 직접 참조
class_name BuildingManager
var ground_layer: TileMapLayer  # ❌

# ❌ 안티 패턴 2: 매니저가 좌표 변환 직접 구현
func create_building(grid_pos):
    var world_x = (grid_pos.x - grid_pos.y) * 16  # ❌ GridSystem 역할 침범!

# ❌ 안티 패턴 3: 매니저가 여러 도메인 담당
class_name GameManager
func create_building()  # 건물
func create_enemy()     # 적
func handle_ui()        # UI
# → 책임이 3개! 분리 필요!
```

---

### 5.6. 실전 적용: Hidden Dependency 제거 (메서드 설계) ⭐

**핵심 원칙**: 메서드가 필요로 하는 것은 **파라미터로 명시**하라. 숨겨진 의존성은 버그의 온상이다.

> "메서드의 시그니처는 계약(Contract)이다. 무엇을 필요로 하는지 명시적으로 표현해야 한다."
> - Robert C. Martin, "Clean Code"

---

#### 문제: Hidden Dependency (숨겨진 의존성)

**정의**: 메서드가 멤버 변수에 암묵적으로 의존하여, 시그니처만 봐서는 무엇이 필요한지 알 수 없는 상태

**❌ 문제가 있는 코드:**

```gdscript
# building_entity.gd
var data: BuildingData  # 멤버 변수

func _update_visuals() -> void:  # ⚠️ 시그니처에 의존성 표현 안 됨
    if not data:  # 멤버 변수에 암묵적 의존
        push_warning("데이터가 없습니다!")
        return

    sprite.texture = data.sprite_texture
    sprite.scale = data.sprite_scale
```

**왜 문제인가?**

1. **시그니처 불명확**: `_update_visuals()`만 봐서는 `data`가 필요한지 모름
2. **호출 순서 의존 (Temporal Coupling)**: `data`를 먼저 설정해야만 호출 가능
3. **테스트 어려움**: 다양한 데이터로 테스트하려면 매번 멤버 변수 변경 필요
4. **재사용성 저하**: 다른 `BuildingData`로 업데이트 불가능

---

#### 해결: Explicit Parameter (명시적 파라미터)

**✅ 개선된 코드:**

```gdscript
# building_entity.gd
var data: BuildingData  # 멤버 변수는 유지

## 뷰를 데이터에 맞게 갱신하는 내부 함수
## @param building_data: 비주얼 업데이트에 사용할 BuildingData (명시적 의존성)
func _update_visuals(building_data: BuildingData) -> void:  # ✅ 파라미터로 명시
    if not building_data:
        push_warning("데이터가 없습니다!")
        return

    sprite.texture = building_data.sprite_texture
    sprite.scale = building_data.sprite_scale

# 호출 예시
func initialize(new_data: BuildingData) -> void:
    data = new_data
    _update_visuals(data)  # ✅ 명시적으로 전달
```

**장점:**

1. ✅ **명시적 계약**: 시그니처만 봐도 `BuildingData`가 필요함을 즉시 알 수 있음
2. ✅ **호출 순서 무관**: 언제든지 호출 가능 (Temporal Coupling 제거)
3. ✅ **테스트 용이**: 다양한 `BuildingData`를 직접 전달하여 테스트
4. ✅ **재사용성 향상**: 런타임에 다른 데이터로도 업데이트 가능 (예: 건물 업그레이드)
5. ✅ **함수 순수성**: 외부 상태보다 파라미터에 의존 (순수 함수에 가까움)

---

#### Before / After 비교

| 항목 | Before (멤버 변수 의존) | After (파라미터 전달) |
|------|------------------------|---------------------|
| **명시성** | ❌ 숨겨진 의존성 | ✅ 시그니처에 명시 |
| **호출 순서** | ⚠️ data 먼저 설정 필요 | ✅ 순서 무관 |
| **테스트** | ⚠️ 상태 설정 필요 | ✅ 직접 전달 가능 |
| **재사용성** | ⚠️ data만 사용 가능 | ✅ 다른 BuildingData도 가능 |
| **SOLID 원칙** | 🟡 Open/Closed 위반 가능 | ✅ 완벽 준수 |

---

#### 실전 체크리스트

메서드 작성 시 다음을 확인하세요:

1. **의존성 검토**
   - [ ] 이 메서드가 멤버 변수를 사용하는가?
   - [ ] 그 멤버 변수가 메서드의 핵심 입력값인가?

2. **명시성 확인**
   - [ ] 시그니처만 봐도 무엇이 필요한지 알 수 있는가?
   - [ ] 다른 개발자가 메서드 구현부를 읽지 않고도 사용할 수 있는가?

3. **테스트 가능성**
   - [ ] 다양한 입력값으로 쉽게 테스트 가능한가?
   - [ ] 상태 설정 없이 메서드를 호출할 수 있는가?

**결정 규칙:**
- ✅ 위 3가지 중 하나라도 "아니오"라면 → **파라미터로 변경**
- 🟡 멤버 변수가 객체의 "핵심 상태"이고, 자주 변경되지 않으면 → 유지 가능

---

#### 예외 상황: 멤버 변수 사용이 정당한 경우

**다음 경우에는 멤버 변수 의존이 허용됩니다:**

1. **불변 상태 (Immutable State)**
   ```gdscript
   class_name BuildingEntity
   var entity_id: int  # 생성 시 한 번만 설정, 이후 불변

   func save_to_database() -> void:
       # entity_id는 객체의 정체성이므로 멤버 변수 사용 정당
       Database.save(entity_id, self.to_dict())
   ```

2. **객체의 핵심 정체성**
   ```gdscript
   class_name Player
   var health: int  # 플레이어의 핵심 상태

   func is_alive() -> bool:
       # health는 Player의 정체성이므로 멤버 변수 사용 정당
       return health > 0
   ```

3. **내부 캐시/헬퍼 변수**
   ```gdscript
   class_name PathFinder
   var _grid_cache: Dictionary  # 내부 최적화용 캐시

   func _calculate_distance(a: Vector2i, b: Vector2i) -> float:
       # _grid_cache는 내부 구현 세부사항이므로 파라미터 불필요
       if _grid_cache.has(a):
           return _grid_cache[a].distance_to(b)
   ```

**핵심 구분 기준:**
- **입력 데이터** → 파라미터로 전달 ✅
- **객체의 상태** → 멤버 변수 유지 가능 🟡
- **내부 구현 세부사항** → 멤버 변수 유지 🟡

---

#### 실제 프로젝트 적용 사례

**파일**: `scripts/entity/building_entity.gd`

**리팩토링 전 (Hidden Dependency):**
```gdscript
var data: BuildingData

func _update_visuals() -> void:
    if not data:  # ❌ 숨겨진 의존성
        return
    sprite.texture = data.sprite_texture
```

**리팩토링 후 (Explicit Parameter):**
```gdscript
var data: BuildingData

func _update_visuals(building_data: BuildingData) -> void:
    if not building_data:  # ✅ 명시적 파라미터
        return
    sprite.texture = building_data.sprite_texture

func initialize(new_data: BuildingData) -> void:
    data = new_data
    _update_visuals(data)  # ✅ 명시적 전달
```

**개선 효과:**
- ✅ Dependency Inversion 원칙 완벽 준수
- ✅ 테스트 시 다양한 BuildingData로 검증 가능
- ✅ 향후 건물 업그레이드 기능 추가 시 재사용 가능

---

#### 실제 프로젝트 적용 사례 2: 추가 리팩토링 사례

이 섹션에서는 프로젝트에서 실제로 발견되고 개선된 Hidden Dependency 패턴들을 소개합니다.

---

##### 사례 1: TestMap.gd - Temporal Coupling 제거

**파일**: `scripts/maps/test_map.gd`

**문제**: 초기화 순서가 암묵적으로 정해져 있어, 순서를 변경하면 시스템이 망가짐

**리팩토링 전:**
```gdscript
func _ready() -> void:
    # GridSystem 초기화 (최우선!)
    GridSystem.initialize(ground_layer)

    # NavigationRegion2D가 NavigationServer2D에 등록될 때까지 대기
    # (보통 2-3 physics_frame 필요)
    await get_tree().physics_frame  # ❌ 왜 필요한지 불명확
    await get_tree().physics_frame
    await get_tree().physics_frame

    # GridSystem에 Navigation Map 캐싱
    GridSystem.cache_navigation_map()  # ❌ 사전 조건 숨김

    # BuildingManager 생성 및 초기화
    building_manager = BuildingManager.new()
    add_child(building_manager)
    building_manager.initialize(entities_container)

    _create_test_units()
    _test_resource_based_buildings()
```

**문제점:**
- ❌ `await get_tree().physics_frame` 호출의 목적이 불명확
- ❌ `cache_navigation_map()` 호출 전에 `initialize()`가 필요한지 시그니처만 봐서는 알 수 없음
- ❌ 초기화 순서를 변경하면 Navigation 시스템 오류 발생
- ❌ 50줄 이상의 긴 `_ready()` 메서드 (SRP 위반)

**리팩토링 후:**
```gdscript
func _ready() -> void:
    # ... 기본 설정

    if not _validate_node_references():
        return

    # 게임 시스템 초기화 (순서 중요!)
    await _initialize_systems()  # ✅ 초기화 로직 캡슐화

    _create_test_units()
    _test_resource_based_buildings()


## 게임 시스템들을 올바른 순서로 초기화합니다.
##
## 초기화 순서가 중요한 이유:
## 1. GridSystem.initialize() - TileMapLayer를 GridSystem에 등록해야 좌표 변환 가능
## 2. await _wait_for_navigation_registration() - NavigationRegion2D가 NavigationServer2D에 등록 대기
## 3. GridSystem.cache_navigation_map() - Navigation Map ID를 캐싱 (1, 2 완료 후에만 가능)
## 4. BuildingManager.initialize() - 건물 생성 시 GridSystem 사용 (1, 3 완료 후에만 가능)
##
## ⚠️ 주의: 이 순서를 변경하면 Navigation 시스템이 정상 작동하지 않습니다!
func _initialize_systems() -> void:
    GridSystem.initialize(ground_layer)
    await _wait_for_navigation_registration()
    GridSystem.cache_navigation_map()

    building_manager = BuildingManager.new()
    add_child(building_manager)
    building_manager.initialize(entities_container)


## NavigationRegion2D가 NavigationServer2D에 완전히 등록될 때까지 대기합니다.
##
## Godot 4.x에서는 NavigationRegion2D 노드가 씬 트리에 추가된 후
## 최소 3 physics frame이 지나야 NavigationServer2D에 완전히 등록됩니다.
##
## 이 대기 시간이 없으면:
## - NavigationServer2D.map_get_path() 호출 시 빈 경로 반환
## - GridSystem.cache_navigation_map()에서 유효하지 않은 Map ID 획득
## - 유닛의 NavigationAgent2D가 경로를 찾지 못함
func _wait_for_navigation_registration() -> void:
    await get_tree().physics_frame
    await get_tree().physics_frame
    await get_tree().physics_frame
```

**개선 효과:**
- ✅ **초기화 순서 명시화**: 주석으로 각 단계의 이유 설명
- ✅ **await 목적 명확화**: `_wait_for_navigation_registration()` 메서드명과 주석
- ✅ **유지보수성 향상**: 다른 개발자가 순서 변경 시 위험성을 즉시 인식
- ✅ **SRP 준수**: `_ready()`가 20줄로 단축, 각 헬퍼 메서드는 단일 책임

---

##### 사례 2: RtsCamera2D.gd - 멤버 변수 Hidden Dependency 제거

**파일**: `scripts/camera/rts_camera_2d.gd`

**문제**: `velocity` 멤버 변수를 암묵적으로 수정하는 메서드들

**리팩토링 전:**
```gdscript
# 현재 이동 방향 벡터
var velocity: Vector2 = Vector2.ZERO  # ❌ 멤버 변수

func _process(delta: float) -> void:
    velocity = Vector2.ZERO

    # WASD 키보드 입력 처리
    _handle_keyboard_input()  # ❌ velocity를 암묵적으로 수정

    # 카메라 이동 적용
    if velocity.length() > 0:
        velocity = velocity.normalized() * speed
        position += velocity * delta


## WASD 키보드 입력 처리
func _handle_keyboard_input() -> void:  # ❌ 반환값 없음
    if Input.is_action_pressed("ui_up"):
        velocity.y -= 1  # ❌ 멤버 변수 직접 수정
    if Input.is_action_pressed("ui_down"):
        velocity.y += 1
    # ...
```

**문제점:**
- ❌ `_handle_keyboard_input()` 시그니처만 봐서는 `velocity`를 수정하는지 알 수 없음
- ❌ Temporal Coupling: `velocity = Vector2.ZERO` → `_handle_keyboard_input()` 순서 의존
- ❌ 테스트 어려움: 다양한 입력 조합을 테스트하려면 멤버 변수 상태 설정 필요
- ❌ Side Effect: 메서드가 외부 상태를 변경함

**리팩토링 후:**
```gdscript
# velocity 멤버 변수 제거! ✅

func _process(delta: float) -> void:
    # 입력 방향 수집 (명시적 반환값 사용)
    var keyboard_direction = _get_keyboard_input_direction()  # ✅ 반환값
    var mouse_edge_direction = _get_mouse_edge_scroll_direction()

    # 모든 입력 방향 합산
    var movement_direction = keyboard_direction + mouse_edge_direction

    # 카메라 이동 적용
    if movement_direction.length() > 0:
        var velocity = movement_direction.normalized() * speed  # ✅ 지역 변수
        position += velocity * delta


## 키보드 입력(WASD, 방향키)을 기반으로 이동 방향을 계산합니다.
##
## @return 정규화되지 않은 입력 방향 벡터 (-1~1 범위, 대각선은 길이 sqrt(2))
##
## ✅ Hidden Dependency 제거: velocity 멤버 변수 대신 반환값 사용
## ✅ 테스트 용이: 다양한 입력 조합을 독립적으로 테스트 가능
## ✅ 순수 함수: 외부 상태를 변경하지 않음 (side effect 없음)
func _get_keyboard_input_direction() -> Vector2:  # ✅ 명시적 반환
    var direction = Vector2.ZERO

    if Input.is_action_pressed("ui_up"):
        direction.y -= 1  # ✅ 지역 변수 수정
    if Input.is_action_pressed("ui_down"):
        direction.y += 1
    # ...

    return direction  # ✅ 명시적 반환
```

**개선 효과:**
- ✅ **명시성**: 메서드 시그니처가 반환값을 명확히 표현
- ✅ **순수 함수**: Side Effect 제거 (외부 상태 변경 없음)
- ✅ **테스트 가능**: 입력 조합을 독립적으로 테스트 가능
- ✅ **재사용성**: 다른 곳에서도 입력 방향 계산 메서드 사용 가능
- ✅ **Temporal Coupling 제거**: 호출 순서에 의존하지 않음

---

##### 사례 3: ConstructionMenu.gd - UI 상태 관리 개선

**파일**: `scripts/ui/construction_menu.gd`

**문제**: 상태 변경 메서드가 중복되고, Signal이 없어 확장성 부족

**리팩토링 전:**
```gdscript
var is_expanded: bool = false

func _on_expand_button_pressed():
    _set_expanded()  # ❌ 하드코딩된 상태

func _on_collapse_button_pressed():
    _set_collapsed()  # ❌ 하드코딩된 상태

# 상태 변경: 펼침
func _set_expanded():  # ❌ 중복 코드
    is_expanded = true
    collapsed_bar.visible = false
    expanded_panel.visible = true

# 상태 변경: 접힘
func _set_collapsed():  # ❌ 중복 코드
    is_expanded = false
    collapsed_bar.visible = true
    expanded_panel.visible = false
```

**문제점:**
- ❌ 2개 메서드(`_set_expanded`, `_set_collapsed`)가 유사한 로직 중복
- ❌ Signal 없음: 다른 시스템이 메뉴 상태 변경을 알 수 없음
- ❌ UI 업데이트 로직이 산재: 향후 애니메이션 추가 시 여러 곳 수정 필요
- ❌ 파라미터 없음: 외부에서 상태를 직접 제어하기 어려움

**리팩토링 후:**
```gdscript
## 메뉴의 확장 상태가 변경될 때 발생
signal expansion_state_changed(expanded: bool)  # ✅ Signal 추가

var is_expanded: bool = false


## 메뉴의 확장 상태를 설정합니다.
##
## @param expanded: true면 메뉴를 펼치고, false면 접습니다.
##
## ✅ Hidden Dependency 제거: 상태를 파라미터로 명시적으로 전달
## ✅ 단일 진입점: _set_expanded()/_set_collapsed() 대신 하나의 메서드로 통합
## ✅ Signal 발생: 상태 변경 시 다른 시스템에 알림 가능
func set_expansion_state(expanded: bool) -> void:  # ✅ 파라미터로 명시
    # 동일한 상태로 변경 시 무시 (불필요한 Signal 방지)
    if is_expanded == expanded:
        return

    is_expanded = expanded
    _update_ui_visibility(expanded)  # ✅ UI 업데이트 분리
    expansion_state_changed.emit(is_expanded)  # ✅ Signal 발생


## 확장 상태에 맞게 UI 요소들의 가시성을 업데이트합니다.
##
## @param expanded: true면 expanded_panel을 보이고, false면 collapsed_bar를 보입니다.
##
## 💡 설계 의도: UI 업데이트 로직을 별도 메서드로 분리하여
##    향후 애니메이션 추가나 추가 UI 요소 처리 시 확장 용이
func _update_ui_visibility(expanded: bool) -> void:  # ✅ 헬퍼 메서드
    collapsed_bar.visible = not expanded
    expanded_panel.visible = expanded


# 버튼 핸들러
func _on_expand_button_pressed() -> void:
    set_expansion_state(true)  # ✅ 명시적 호출

func _on_collapse_button_pressed() -> void:
    set_expansion_state(false)  # ✅ 명시적 호출
```

**개선 효과:**
- ✅ **중복 제거**: 2개 메서드 → 1개 통합 메서드 (`set_expansion_state`)
- ✅ **Observer 패턴**: `expansion_state_changed` Signal로 다른 시스템 통보
- ✅ **확장 가능**: `_update_ui_visibility()`로 UI 로직 집중화 (애니메이션 추가 용이)
- ✅ **명시성**: 파라미터로 의도를 명확히 표현
- ✅ **SRP 준수**: UI 업데이트 로직이 별도 메서드로 분리

---

##### 리팩토링 사례 요약

| 파일 | 문제 유형 | 해결 방법 | 핵심 개선 |
|------|----------|----------|----------|
| **test_map.gd** | Temporal Coupling (호출 순서 의존) | 초기화 헬퍼 메서드 + 문서화 주석 | 초기화 순서 명시화, 유지보수성 향상 |
| **rts_camera_2d.gd** | velocity 멤버 변수 Hidden Dependency | 순수 함수로 변환 (반환값 사용) | Side Effect 제거, 테스트 가능성 향상 |
| **construction_menu.gd** | 중복 메서드 + Signal 부재 | 단일 메서드 통합 + Signal 추가 | 중복 제거, Observer 패턴 적용 |

**공통 교훈:**
1. ✅ **메서드 시그니처는 계약이다**: 필요한 것은 파라미터로 명시
2. ✅ **순수 함수를 선호하라**: Side Effect 제거 → 테스트 용이
3. ✅ **초기화 순서는 문서화하라**: 주석으로 "왜" 설명
4. ✅ **Signal로 결합도를 낮춰라**: 직접 호출보다 이벤트 기반

---

#### 관련 SOLID 원칙

이 패턴은 다음 SOLID 원칙과 연결됩니다:

1. **Single Responsibility**
   - 메서드가 "데이터 가져오기"와 "비주얼 업데이트"를 동시에 하지 않음
   - 데이터는 외부에서 주입 → 메서드는 업데이트만 담당

2. **Open/Closed**
   - 다른 타입의 데이터로 확장 가능 (파라미터만 변경)
   - 메서드 내부는 수정 불필요

3. **Dependency Inversion**
   - 메서드가 구체적 멤버 변수보다 추상적 파라미터에 의존
   - 결합도 낮춤 (Loose Coupling)

---

## 6. 아키텍처: 로직과 UI 분리

게임 로직(데이터/상태)과 UI(표현)를 엄격하게 분리하여, UI가 변경되어도 게임 로직에 영향을 주지 않도록 합니다.

### 6.1. 의존성 방향
- **로직 -> UI (X)**: 게임 로직 스크립트는 UI 노드를 직접 참조하거나 제어하지 않아야 합니다.
- **UI -> 로직 (O)**: UI 스크립트는 게임 로직(데이터)을 참조하여 화면을 갱신합니다.

### 6.2. 통신 방식 (Signals - Observer Pattern)
- 게임 로직 상태가 변경되면 **Signal**을 방출(emit)합니다.
- UI는 해당 Signal을 연결(connect)하여 화면을 업데이트합니다.

```gdscript
# Player.gd (Logic)
signal health_changed(new_health: int)

func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health) # UI 업데이트를 위해 신호만 방출

# HUD.gd (UI)
func _ready() -> void:
    player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(new_health: int) -> void:
    health_bar.value = new_health # UI 변경 로직
```
