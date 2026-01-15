# Godot Autoload 사용 가이드

## 📖 개요

이 문서는 Godot 프로젝트에서 Autoload(싱글톤) 사용 시 올바른 패턴과 주의사항을 정리합니다.

**핵심 원칙**: Godot에서 Autoload는 안티패턴이 아니라 **공식 권장 패턴**입니다.

---

## 🎯 Autoload란?

### Godot 공식 정의

> **"Autoload is Godot's way to create global singletons."**
>
> "Use them for data or functionality that is always available, regardless of the current scene."
>
> — [Godot 공식 문서](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)

### 특징
- 게임 시작 시 자동으로 로드
- 모든 씬에서 접근 가능
- 씬 전환에도 유지됨
- 전역 변수처럼 사용

---

## ✅ Autoload 사용이 적절한 경우

### 1. 게임 전역 상태
```gdscript
# game_manager.gd (Autoload)
extends Node

var score: int = 0
var level: int = 1
var player_health: int = 100

func game_over():
    score = 0
    level = 1
```

**예시:**
- 플레이어 데이터 (체력, 점수, 레벨)
- 게임 진행 상태 (현재 챕터, 퀘스트)
- 인벤토리 시스템
- **건물 목록 (BuildingManager)** ← 현재 프로젝트

### 2. 시스템 매니저
```gdscript
# audio_manager.gd (Autoload)
extends Node

func play_sfx(sound_name: String):
    var player = AudioStreamPlayer.new()
    add_child(player)
    player.stream = load("res://sounds/" + sound_name + ".ogg")
    player.play()
```

**예시:**
- 오디오 관리 (AudioManager)
- 입력 관리 (InputManager) ← 현재 프로젝트
- 씬 전환 관리 (SceneManager)
- 저장/로드 관리 (SaveManager)

### 3. 공유 유틸리티/설정
```gdscript
# game_config.gd (Autoload)
extends Node

const TILE_SIZE: int = 32
const GRAVITY: float = 980.0
const MAX_SPEED: float = 200.0
```

**예시:**
- 게임 설정값 (GameConfig) ← 현재 프로젝트
- 좌표 시스템 (GridSystem) ← 현재 프로젝트
- 상수 모음
- 정적 데이터베이스 (BuildingDatabase) ← 현재 프로젝트

### 4. 전역 선택/포커스 상태
```gdscript
# selection_manager.gd (Autoload)
extends Node

var selected_units: Array = []
var selected_building: Node = null

func select_unit(unit: Node):
    selected_units.append(unit)
```

**예시:**
- 선택 관리 (SelectionManager) ← 현재 프로젝트
- 카메라 포커스
- 커서 상태

---

## ❌ Autoload 사용이 부적절한 경우

### 1. 씬별 로컬 상태
```gdscript
# ❌ 나쁜 예: UI 상태를 Autoload로
extends Node  # Autoload

var is_menu_open: bool = false
var current_tab: int = 0
```

**이유**: UI 상태는 해당 씬/노드가 관리해야 함

**✅ 올바른 방법:**
```gdscript
# menu.gd (일반 스크립트)
extends Control

var is_open: bool = false
var current_tab: int = 0
```

### 2. 일시적인 상태
```gdscript
# ❌ 나쁜 예: 애니메이션 상태
extends Node  # Autoload

var is_animating: bool = false
var animation_progress: float = 0.0
```

**이유**: 애니메이션은 해당 노드가 관리

### 3. 씬 내부의 데이터 컬렉션
```gdscript
# ❌ 나쁜 예: 현재 맵의 적 목록
extends Node  # Autoload

var enemies: Array[Node] = []
```

**이유**: 적 목록은 맵(씬)이 소유해야 함

**✅ 올바른 방법:**
```gdscript
# map.gd (씬 스크립트)
extends Node2D

var enemies: Array[Node] = []
```

---

## 🏗️ Node 계층 구조와 Autoload

### 문제 상황: 계층 위반

```
main (Node2D)
├── GameWorld
│   └── EnemyManager (Node, 여기서 생성)
└── UI
    └── HealthBar
        └── EnemyManager 참조 필요 ← 문제!
```

**문제점:**
- `HealthBar`가 `GameWorld`의 자식인 `EnemyManager`를 참조
- 형제의 자식을 참조 (계층 구조 위반)
- 의존성 방향이 복잡해짐

### ❌ 안티패턴: 경로로 접근
```gdscript
# health_bar.gd
func _ready():
    var enemy_manager = get_node("../../GameWorld/EnemyManager")  # 나쁨!
```

**문제:**
- 경로가 깨지기 쉬움
- 씬 구조 변경 시 모든 참조 수정 필요
- 테스트 불가능

### ⚠️ 차선책: 의존성 주입
```gdscript
# health_bar.gd
var enemy_manager: Node = null

func initialize(manager: Node):
    enemy_manager = manager

# main.gd
func _ready():
    var enemy_manager = $GameWorld/EnemyManager
    $UI/HealthBar.initialize(enemy_manager)
```

**단점:**
- 초기화 순서 관리 복잡
- 모든 참조자에게 전달 필요
- Props drilling과 유사

### ✅ Godot 권장: Autoload
```gdscript
# enemy_manager.gd (Autoload)
extends Node

var enemies: Array[Node] = []

func get_enemy_count() -> int:
    return enemies.size()

# health_bar.gd (어디서든 접근)
func _process(_delta):
    label.text = "Enemies: %d" % EnemyManager.get_enemy_count()
```

**장점:**
- 계층 구조와 무관
- 초기화 순서 문제 없음
- 어디서든 동일한 방식으로 접근

---

## 📊 판단 기준: Manager는 Autoload

### "Manager"의 정의

게임 개발에서 `XxxManager`는:
- ✅ 게임 전역에서 사용
- ✅ 한 개의 인스턴스만 존재
- ✅ 씬 전환에도 살아있음
- ✅ 여러 씬/노드에서 공유

→ **이것이 Autoload의 정의 그 자체**

### Godot 커뮤니티 관행

```gdscript
// 게임별 Manager 예시
AudioManager (Autoload)      // 모든 게임
InputManager (Autoload)      // 모든 게임
SaveManager (Autoload)       // RPG, 전략
SceneManager (Autoload)      // 대부분 게임
QuestManager (Autoload)      // RPG
BuildingManager (Autoload)   // 전략, 시뮬레이션 ← 현재 프로젝트
UnitManager (Autoload)       // 전략, RTS
```

---

## 🎮 현재 프로젝트 적용

### Autoload 목록 (6개)

```ini
[autoload]
GameConfig="*res://scripts/config/game_config.gd"
GridSystem="*res://scripts/map/grid_system.gd"
SelectionManager="*res://scripts/managers/selection_manager.gd"
InputManager="*res://scripts/managers/input_manager.gd"
BuildingDatabase="*res://scripts/config/building_database.gd"
BuildingManager="*res://scripts/managers/building_manager.gd"
```

### 역할 분석

| Autoload | 역할 | 이유 |
|----------|------|------|
| GameConfig | 전역 설정값 | ✅ 모든 곳에서 사용 |
| GridSystem | 좌표 시스템 | ✅ 좌표 변환은 전역 기능 |
| SelectionManager | 선택 상태 | ✅ 게임 전역 선택 |
| InputManager | 입력 관리 | ✅ 입력은 하나 |
| BuildingDatabase | 건물 스펙 | ✅ 정적 데이터 |
| BuildingManager | 건물 상태 | ✅ 게임 전역 건물 목록 |

**총 6개는 적절한 수준** (보통 5-10개)

---

## ⚖️ Autoload vs Props Drilling

### React/웹 프레임워크와의 차이

| 측면 | React | Godot |
|------|-------|-------|
| 철학 | "Props로 전달" | "Autoload 사용" |
| 전역 상태 | Context API (복잡) | Autoload (간단) |
| 이유 | SPA, 페이지별 상태 | 지속 세션, 게임 상태 |

### Godot는 다른 패러다임
```
React: 컴포넌트 트리 → Props drilling
Godot: 씬 트리 + Autoload 레이어
```

---

## 🚫 안티패턴 모음

### 1. 과도한 Autoload
```ini
# ❌ 나쁜 예: 20개 이상의 Autoload
[autoload]
Manager1="..."
Manager2="..."
...
Manager20="..."
```

**기준**: 5-10개 정도가 적절

### 2. 데이터를 Autoload로
```gdscript
# ❌ 나쁜 예: 모든 데이터를 Autoload에
extends Node  # Autoload

var all_items: Array = [...]  # 1000개
var all_enemies: Array = [...]  # 500개
```

**해결**: 리소스 파일(.tres)로 관리

### 3. Autoload 간 순환 참조
```gdscript
# manager_a.gd (Autoload)
func foo():
    ManagerB.bar()  # ManagerB 참조

# manager_b.gd (Autoload)
func bar():
    ManagerA.foo()  # ManagerA 참조 (순환!)
```

**해결**: 시그널로 통신

---

## 🎯 Best Practices

### 1. Autoload는 Node 상속
```gdscript
# ✅ 올바른 예
extends Node  # 또는 Node2D, Node3D

# ❌ 나쁜 예
extends Object  # Autoload는 씬 트리에 있어야 함
```

### 2. class_name과 Autoload 이름 다르게
```gdscript
# building_manager.gd
extends Node
# class_name BuildingManager  ← 제거!

# project.godot
[autoload]
BuildingManager="*res://scripts/managers/building_manager.gd"
```

**이유**: Godot 4.x에서 동일 이름 충돌

### 3. 초기화 메서드 제공
```gdscript
# building_manager.gd (Autoload)
extends Node

var buildings: Dictionary = {}

# 맵 전환 시 호출
func initialize_for_map(container: Node2D):
    clear_all_buildings()
    buildings_parent = container
```

### 4. 시그널로 통신
```gdscript
# building_manager.gd (Autoload)
signal building_placed(building_data, grid_pos)

func place_building(...):
    # ...
    building_placed.emit(data, pos)

# ui.gd (다른 씬)
func _ready():
    BuildingManager.building_placed.connect(_on_building_placed)
```

---

## 📖 참고 자료

- [Godot 공식 문서 - Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [Godot Best Practices - When to use Autoload](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html)
- 현재 프로젝트: `docs/implementation/godot_flux_pattern.md`

---

## 요약

### ✅ Autoload 사용 시
- Manager 클래스
- 게임 전역 상태
- 여러 씬에서 공유되는 기능
- 계층 구조와 무관하게 접근 필요

### ❌ Autoload 사용 금지
- 씬별 로컬 상태
- UI 내부 상태
- 일시적/임시 변수
- 씬 소유 데이터 (적 목록 등)

### 🎯 핵심
**Godot에서 Autoload는 안티패턴이 아니라 표준 패턴입니다.**
