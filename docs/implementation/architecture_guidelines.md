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
