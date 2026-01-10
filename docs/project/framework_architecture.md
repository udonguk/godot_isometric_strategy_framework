# 프레임워크 아키텍처 (Framework Architecture)

## 📋 목차
1. [아키텍처 개요](#아키텍처-개요)
2. [레이어 구조](#레이어-구조)
3. [핵심 시스템](#핵심-시스템)
4. [데이터 흐름](#데이터-흐름)
5. [확장 방법](#확장-방법)
6. [모범 사례](#모범-사례)

---

## 아키텍처 개요

### 설계 철학

**Isometric Strategy Framework**는 다음 원칙을 따릅니다:

1. **SOLID 원칙**: 유지보수 가능한 코드
2. **레이어 분리**: 고수준 ↔ 추상화 ↔ 저수준
3. **Godot-First**: 내장 기능 최대 활용
4. **씬 기반**: 모든 엔티티는 재사용 가능한 씬
5. **UI/Logic 분리**: 비주얼이 로직에 영향 없음

### 핵심 개념

```
[개발자가 작성하는 게임 로직]
           ↓
[프레임워크 추상화 레이어]  ← 이 문서의 주제
           ↓
    [Godot 엔진]
```

**프레임워크의 역할**: 개발자가 Godot 엔진과 직접 상호작용하지 않고, 추상화된 인터페이스를 통해 게임을 만들 수 있게 함

---

## 레이어 구조

### 전체 레이어 다이어그램

```
┌─────────────────────────────────────────────────────────┐
│              [게임 로직 레이어]                          │
│          (개발자가 작성하는 코드)                         │
│   - 게임 규칙 (승리 조건, 자원 관리)                      │
│   - 게임별 UI (HUD, 메뉴)                                │
│   - 게임별 엔티티 (특수 유닛, 특수 건물)                   │
└─────────────────────────────────────────────────────────┘
                        ↓ (사용)
┌─────────────────────────────────────────────────────────┐
│           [매니저 레이어 - 고수준]                        │
│                                                          │
│   BuildingManager    UnitManager    ResourceManager     │
│         ↓                ↓                 ↓            │
│   - 건물 생성/제거   - 유닛 생성      - 자원 관리        │
│   - 건물 조회        - 선택 관리      - 수집/소비        │
│   - 상태 관리        - 이동 명령      - Signal 전파      │
│                                                          │
│              SelectionManager (Autoload)                 │
│                   ↓                                      │
│              - 선택 상태 관리                             │
│              - 다중 선택 지원                             │
└─────────────────────────────────────────────────────────┘
                        ↓ (의존)
┌─────────────────────────────────────────────────────────┐
│           [추상화 레이어 - 중간]                          │
│                                                          │
│    GridSystem (Autoload)    GameConfig (Autoload)       │
│         ↓                         ↓                     │
│   - 좌표 변환               - 모든 설정 상수              │
│   - 좌표 검증               - 타입별 분류                 │
│   - Navigation 검증         - 중앙 집중 관리              │
│   - 장애물 관리                                          │
│                                                          │
│   ⚠️ 핵심: 매니저는 Godot 내장 타입을 직접 참조 금지!    │
│   ✅ 올바른 예: GridSystem.grid_to_world()              │
│   ❌ 잘못된 예: TileMapLayer.map_to_local()             │
└─────────────────────────────────────────────────────────┘
                        ↓ (사용)
┌─────────────────────────────────────────────────────────┐
│           [Godot 엔진 레이어 - 저수준]                    │
│                                                          │
│   TileMapLayer    NavigationAgent2D    CharacterBody2D  │
│   TileSet         NavigationServer2D   CollisionShape2D │
│   Sprite2D        Area2D               Camera2D         │
│                                                          │
│   ⚠️ 이 레이어는 프레임워크가 캡슐화함                    │
│   개발자는 직접 접근하지 않음!                            │
└─────────────────────────────────────────────────────────┘
```

---

## 핵심 시스템

### 1. GridSystem (좌표 변환 추상화)

**역할**: 모든 좌표 변환의 단일 진입점

**파일**: `scripts/map/grid_system.gd` (Autoload)

**핵심 메서드**:
```gdscript
class_name GridSystemNode extends Node

# 그리드 → 월드 변환
static func grid_to_world(grid_pos: Vector2i) -> Vector2

# 월드 → 그리드 변환
static func world_to_grid(world_pos: Vector2) -> Vector2i

# Navigation 가능 여부 검증
func is_valid_navigation_position(grid_pos: Vector2i) -> bool

# 장애물 등록
func mark_as_obstacle(grid_pos: Vector2i, size: Vector2i) -> void
```

**의존성**:
- **사용**: TileMapLayer (내부적으로만)
- **사용됨**: BuildingManager, UnitManager, 모든 매니저

**설계 원칙**:
- ✅ 모든 좌표 변환은 **반드시** GridSystem을 통해서만
- ❌ 매니저가 TileMapLayer.map_to_local() 직접 호출 금지
- ✅ DIP (Dependency Inversion Principle) 준수

---

### 2. GameConfig (설정 관리)

**역할**: 모든 게임 설정의 중앙 집중 관리

**파일**: `scripts/config/game_config.gd` (Autoload)

**구조**:
```gdscript
extends Node

# ============================================================
# 타일 시스템 설정
# ============================================================
const TILE_WIDTH: int = 64
const TILE_HEIGHT: int = 32

# ============================================================
# 건물 시스템 설정
# ============================================================
const BUILDING_COLOR_NORMAL: Color = Color.WHITE
const BUILDING_COLOR_SELECTED: Color = Color(1.0, 0.8, 0.0)

# ============================================================
# 맵 시스템 설정
# ============================================================
const MAP_WIDTH: int = 20
const MAP_HEIGHT: int = 20

# ============================================================
# Navigation 시스템 설정
# ============================================================
const NAVIGATION_TOLERANCE: float = 8.0
```

**설계 원칙**:
- ✅ 모든 매직 넘버를 const로 정의
- ✅ 섹션별 주석으로 구분
- ✅ 타입 힌트 필수

---

### 3. BuildingManager (건물 관리)

**역할**: 건물 생성/제거/조회

**파일**: `scripts/managers/building_manager.gd`

**핵심 메서드**:
```gdscript
class_name BuildingManager extends Node

# 건물 Dictionary (Vector2i → BuildingEntity)
var grid_buildings: Dictionary = {}

# 건물 생성
func create_building(grid_pos: Vector2i) -> BuildingEntity:
    # ✅ GridSystem 사용 (DIP 준수)
    var world_pos = GridSystem.grid_to_world(grid_pos)

    var building = building_scene.instantiate()
    building.global_position = world_pos
    building.grid_position = grid_pos

    add_child(building)
    grid_buildings[grid_pos] = building

    return building

# 건물 조회
func get_building(grid_pos: Vector2i) -> BuildingEntity:
    return grid_buildings.get(grid_pos)

# 건물 존재 여부
func has_building(grid_pos: Vector2i) -> bool:
    return grid_buildings.has(grid_pos)
```

**의존성**:
- **사용**: GridSystem (좌표 변환)
- **사용**: GameConfig (설정값)
- ❌ **사용 금지**: TileMapLayer 직접 참조

---

### 4. SelectionManager (선택 관리)

**역할**: 유닛 선택 상태 중앙 관리

**파일**: `scripts/managers/selection_manager.gd` (Autoload)

**핵심 메서드**:
```gdscript
extends Node

var selected_units: Array[UnitEntity] = []

# 유닛 선택
func select_unit(unit: UnitEntity, multi_select: bool = false) -> void:
    if not multi_select:
        deselect_all()

    if unit not in selected_units:
        selected_units.append(unit)
        unit.is_selected = true

# 전체 선택 해제
func deselect_all() -> void:
    for unit in selected_units:
        unit.is_selected = false
    selected_units.clear()

# 선택된 유닛 조회
func get_selected_units() -> Array[UnitEntity]:
    return selected_units
```

**설계 원칙**:
- ✅ Single Responsibility: 선택 상태 관리만 담당
- ✅ Autoload로 전역 접근 가능
- ✅ Signal 대신 직접 호출 (단순성)

---

### 5. UnitEntity (유닛 엔티티)

**역할**: 개별 유닛의 행동 및 상태

**파일**: `scripts/entity/unit_entity.gd`

**핵심 구조**:
```gdscript
class_name UnitEntity extends CharacterBody2D

@export var speed: float = 100.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var selection_indicator: Sprite2D = $SelectionIndicator

var is_selected: bool = false:
    set(value):
        is_selected = value
        selection_indicator.visible = value

# 이동 명령
func move_to(target_pos: Vector2) -> void:
    nav_agent.target_position = target_pos

# 물리 프로세스
func _physics_process(delta: float) -> void:
    if nav_agent.is_navigation_finished():
        return

    var next_position = nav_agent.get_next_path_position()
    var direction = global_position.direction_to(next_position)
    velocity = direction * speed
    move_and_slide()
```

**설계 원칙**:
- ✅ CharacterBody2D 상속 (Godot 권장)
- ✅ NavigationAgent2D 활용 (직접 구현 X)
- ✅ public 메서드만 노출 (move_to)
- ✅ 내부 구현 캡슐화

---

## 데이터 흐름

### 유닛 이동 명령 예시

```
[1] 사용자 우클릭
       ↓
[2] test_map.gd._unhandled_input()
       ↓
[3] 화면 좌표 → get_global_mouse_position()
       ↓
[4] 월드 좌표 → GridSystem.world_to_grid()
       ↓
[5] 그리드 좌표 → GridSystem.is_valid_navigation_position()
       ↓ (유효한 경우)
[6] 그리드 좌표 → GridSystem.grid_to_world() (최종 목표)
       ↓
[7] SelectionManager.get_selected_units()
       ↓
[8] for unit in selected_units:
       unit.move_to(target_world)
       ↓
[9] NavigationAgent2D.target_position = target_world
       ↓
[10] NavigationServer2D가 자동으로 경로 계산
       ↓
[11] _physics_process()에서 move_and_slide()
```

**핵심 포인트**:
- ✅ **모든 좌표 변환은 GridSystem을 통과**
- ✅ **Navigation 검증 후 이동**
- ✅ **Godot 내장 기능 활용** (NavigationServer2D)

---

### 건물 배치 예시

```
[1] BuildingManager.create_building(grid_pos)
       ↓
[2] GridSystem.grid_to_world(grid_pos) → world_pos
       ↓
[3] BuildingEntity 인스턴스 생성
       ↓
[4] building.global_position = world_pos
    building.grid_position = grid_pos
       ↓
[5] add_child(building)
       ↓
[6] grid_buildings[grid_pos] = building
       ↓
[7] GridSystem.mark_as_obstacle(grid_pos, size)
       ↓
[8] (추후) NavigationObstacle2D 자동 활성화
```

**핵심 포인트**:
- ✅ **BuildingManager가 TileMapLayer를 직접 참조하지 않음**
- ✅ **GridSystem을 통한 좌표 변환**
- ✅ **Dictionary로 빠른 조회 (O(1))**

---

## 확장 방법

### 새 매니저 추가하기

**예시**: ItemManager 추가

#### 1. 매니저 클래스 생성

```gdscript
# scripts/managers/item_manager.gd
class_name ItemManager extends Node

var grid_items: Dictionary = {}  # Vector2i → ItemEntity

func create_item(grid_pos: Vector2i) -> ItemEntity:
    # ✅ GridSystem 사용 (DIP 준수)
    var world_pos = GridSystem.grid_to_world(grid_pos)

    var item = item_scene.instantiate()
    item.global_position = world_pos
    item.grid_position = grid_pos

    add_child(item)
    grid_items[grid_pos] = item

    return item

func get_item(grid_pos: Vector2i) -> ItemEntity:
    return grid_items.get(grid_pos)
```

#### 2. 체크리스트

- [ ] ✅ GridSystem 사용 (TileMapLayer 직접 참조 금지)
- [ ] ✅ GameConfig 사용 (매직 넘버 금지)
- [ ] ✅ 단일 책임 원칙 (아이템 관리만)
- [ ] ✅ 타입 힌트 사용
- [ ] ✅ 주석 작성 (한국어)

---

### 새 엔티티 추가하기

**예시**: TreeEntity 추가

#### 1. 씬 생성

```
scenes/entity/tree_entity.tscn
├── TreeEntity (Node2D)
    ├── Sprite2D (나무 비주얼)
    ├── CollisionShape2D (클릭 감지)
    └── (옵션) NavigationObstacle2D
```

#### 2. 스크립트 작성

```gdscript
# scripts/entity/tree_entity.gd
class_name TreeEntity extends Node2D

@export var grid_position: Vector2i = Vector2i.ZERO
@export var resource_amount: int = 100

@onready var sprite: Sprite2D = $Sprite2D

func harvest(amount: int) -> int:
    var harvested = min(amount, resource_amount)
    resource_amount -= harvested

    if resource_amount <= 0:
        queue_free()  # 자원 고갈 시 제거

    return harvested
```

#### 3. 체크리스트

- [ ] ✅ 씬 우선 생성 (Scene-First)
- [ ] ✅ class_name 정의
- [ ] ✅ grid_position 속성 추가
- [ ] ✅ public 메서드만 노출
- [ ] ✅ 내부 구현 캡슐화

---

### 새 게임 만들기

#### 1. 새 맵 씬 생성

```
scenes/maps/my_game_map.tscn
├── MyGameMap (Node2D)
    ├── GroundTileMapLayer (인스턴스)
    ├── StructuresTileMapLayer (인스턴스)
    ├── Buildings (Node2D)
    ├── Units (Node2D)
    ├── Items (Node2D)
    └── RtsCamera2D (인스턴스)
```

#### 2. 맵 스크립트 작성

```gdscript
# scripts/maps/my_game_map.gd
extends Node2D

@onready var ground_layer = $GroundTileMapLayer
@onready var buildings_container = $Buildings

var building_manager: BuildingManager

func _ready():
    # GridSystem 초기화
    GridSystem.initialize(ground_layer)

    # BuildingManager 생성
    building_manager = BuildingManager.new()
    add_child(building_manager)

    # 게임별 초기화 로직
    _setup_initial_buildings()
    _setup_initial_units()

func _setup_initial_buildings():
    # 시작 건물 배치
    building_manager.create_building(Vector2i(5, 5))
    building_manager.create_building(Vector2i(10, 10))
```

#### 3. 게임 로직 추가

```gdscript
# scripts/game_logic/my_game_logic.gd
extends Node

# 승리 조건
func check_victory() -> bool:
    return ResourceManager.get_resource("gold") >= 1000

# 패배 조건
func check_defeat() -> bool:
    return UnitManager.get_unit_count() == 0
```

---

## 모범 사례

### ✅ DO (이렇게 하세요)

#### 1. GridSystem 사용

```gdscript
# ✅ 좋은 예
func create_building(grid_pos: Vector2i):
    var world_pos = GridSystem.grid_to_world(grid_pos)
    building.global_position = world_pos
```

#### 2. GameConfig 사용

```gdscript
# ✅ 좋은 예
sprite.modulate = GameConfig.BUILDING_COLOR_NORMAL
```

#### 3. 타입 힌트

```gdscript
# ✅ 좋은 예
func get_building(grid_pos: Vector2i) -> BuildingEntity:
    return grid_buildings.get(grid_pos)
```

#### 4. 단일 책임

```gdscript
# ✅ 좋은 예 - BuildingManager는 건물만 관리
class_name BuildingManager extends Node

func create_building(grid_pos: Vector2i) -> BuildingEntity:
    pass

func remove_building(grid_pos: Vector2i) -> void:
    pass
```

---

### ❌ DON'T (이렇게 하지 마세요)

#### 1. TileMapLayer 직접 참조

```gdscript
# ❌ 나쁜 예 - DIP 위반!
class_name BuildingManager
var ground_layer: TileMapLayer  # ❌

func create_building(grid_pos: Vector2i):
    var world_pos = ground_layer.map_to_local(grid_pos)  # ❌
```

#### 2. 매직 넘버

```gdscript
# ❌ 나쁜 예
sprite.modulate = Color(1.0, 0.8, 0.0)  # ❌ 이게 뭔 색?
```

#### 3. 타입 힌트 없음

```gdscript
# ❌ 나쁜 예
func get_building(grid_pos):  # ❌ 타입 불명확
    return grid_buildings.get(grid_pos)
```

#### 4. 다중 책임

```gdscript
# ❌ 나쁜 예 - GameManager가 너무 많은 일을 함
class_name GameManager
func create_building()  # 건물
func create_unit()      # 유닛
func collect_resource() # 자원
func update_ui()        # UI
# → 4개 책임! 분리 필요!
```

---

## 테스트 가이드

### 아키텍처 준수 체크리스트

새 코드 작성 시 확인:

#### DIP (의존성 역전) 체크
- [ ] 매니저가 Godot 내장 타입을 직접 참조하지 않는가?
- [ ] 모든 좌표 변환이 GridSystem을 통하는가?
- [ ] 모든 설정값이 GameConfig를 통하는가?

#### SRP (단일 책임) 체크
- [ ] 각 매니저가 하나의 명확한 역할만 하는가?
- [ ] 클래스 이름이 역할을 정확히 표현하는가?

#### OCP (개방-폐쇄) 체크
- [ ] 기능 추가 시 기존 코드를 수정하지 않는가?
- [ ] 추상화 레이어를 사용하는가?

---

## 참고 문서

- **CLAUDE.md**: 전체 프로젝트 가이드
- **../product/game_design.md**: 프레임워크 개요
- **../product/prd.md**: 기능 요구사항 정의
- **../implementation/code_convention.md**: 코드 컨벤션
- **../design/tile_system_design.md**: 타일 시스템 상세
- **../design/navigation_system_design.md**: Navigation 시스템 상세

---

**마지막 업데이트**: 2025-12-28
**버전**: 1.0 (Alpha)
