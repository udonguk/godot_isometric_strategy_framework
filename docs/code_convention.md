# 코드 컨벤션 (Code Convention)

이 문서는 "Vampire Spread Isometric" 프로젝트의 코드 작성 규칙 및 아키텍처 가이드를 정의합니다.

## 1. 기본 원칙 (General Principles)

### 1.1. Godot 표준 준수
- Godot 공식 문서의 [GDScript 스타일 가이드](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)를 따릅니다.
- **네이밍 규칙**:
  - 클래스/노드 이름: `PascalCase` (예: `PlayerController`)
  - 변수/함수 이름: `snake_case` (예: `current_health`, `get_player_position()`)
  - 상수 이름: `CONSTANT_CASE` (예: `MAX_SPEED`)
  - 프라이빗 멤버: `_` 접두사 사용 (예: `_calculate_damage()`)

### 1.2. 객체 지향 및 교육적 코드 작성 (OOP & Learning)
- **책임 분리**: 각 스크립트는 하나의 명확한 역할만 수행해야 합니다 (단일 책임 원칙).
- **상속 활용**: 공통 기능은 부모 클래스로 추상화합니다 (예: `BaseEnemy` -> `GoblinEnemy`).
- **교육적 주석(Why)**: 특정 디자인 패턴이나 복잡한 구조를 사용할 때는 **"왜 이 패턴을 사용했는지"** 주석으로 설명을 남깁니다.
  ```gdscript
  # [State Pattern] 상태별 로직 분리를 통해 코드 복잡도를 낮추고 유지보수성을 높이기 위해 사용
  # IdleState는 가만히 서있을 때의 행동을 정의합니다.
  class_name IdleState extends State
  ```

## 2. 디자인 패턴 (Design Patterns)

Godot 개발 효율성과 유지보수를 위해 다음 패턴 사용을 권장합니다.

### 2.1. 상태 패턴 (State Pattern)
- **용도**: 캐릭터(플레이어, AI)의 복잡한 상태 전이(대기 -> 이동 -> 공격)를 관리할 때 사용합니다.
- **구조**: `StateMachine` 노드가 현재 상태(`State` 노드)를 관리하며, 각 상태는 별도의 스크립트로 분리합니다.
- **장점**: 거대한 `if-else` 또는 `switch` 문을 피하고, 각 상태별 로직을 독립적으로 관리할 수 있습니다.

### 2.2. 컴포넌트 패턴 (Component Pattern)
- **용도**: 기능의 재사용성을 극대화하기 위해 사용합니다. "상속보다는 구성(Composition over Inheritance)" 원칙을 따릅니다.
- **구조**: `HealthComponent`, `HitboxComponent`와 같이 특정 기능만 수행하는 노드를 만들고, 이를 캐릭터나 오브젝트에 부착하여 조립합니다.
- **장점**: 부모 클래스가 너무 비대해지는 것을 방지하고, 다양한 기능을 유연하게 조합할 수 있습니다.

### 2.3. 싱글톤 패턴 (Singleton Pattern / Autoload)
- **용도**: 게임 전체에서 공유해야 하는 데이터나 매니저(예: `GameManager`, `SoundManager`)에 사용합니다.
- **Godot 구현**: 프로젝트 설정의 **Autoload** 기능을 사용합니다.
- **주의**: 과도한 사용은 의존성을 높이므로 꼭 필요한 전역 관리에만 사용합니다.

## 3. 정적 타이핑 (Static Typing)

모든 변수와 함수에 타입을 명시하여 코드의 안정성과 가독성을 높입니다.

### 3.1. 변수 선언
```gdscript
# Bad
var health = 100
var player_name

# Good
var health: int = 100
var player_name: String = ""
```

### 3.2. 함수 선언
매개변수와 반환 타입을 반드시 명시합니다. 반환값이 없으면 `-> void`를 사용합니다.
```gdscript
# Bad
func take_damage(amount):
    health -= amount

# Good
func take_damage(amount: int) -> void:
    health -= amount
```

## 4. 아키텍처: 로직과 UI 분리

게임 로직(데이터/상태)과 UI(표현)를 엄격하게 분리하여, UI가 변경되어도 게임 로직에 영향을 주지 않도록 합니다.

### 4.1. 의존성 방향
- **로직 -> UI (X)**: 게임 로직 스크립트는 UI 노드를 직접 참조하거나 제어하지 않아야 합니다.
- **UI -> 로직 (O)**: UI 스크립트는 게임 로직(데이터)을 참조하여 화면을 갱신합니다.

### 4.2. 통신 방식 (Signals - Observer Pattern)
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
