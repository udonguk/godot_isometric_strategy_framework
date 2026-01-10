# 타일 시스템 설계

## 1. 개요
아이소메트릭 타일 기반 전파(Spread) 시스템 설계 문서

## 2. 용어 정의

- **Tile (타일)**: TileMapLayer의 바닥 타일 (정적, 시각적 용도)
- **Building (건물)**: 그리드 위에 배치되는 상태를 가진 객체 (감염 대상)
- **Unit (유닛)**: 추후 추가될 이동 가능한 캐릭터 (플레이어, 적 등)

## 3. 핵심 설계 원칙

### 3.1. UI/Visual과 Logic 분리

**원칙:**
- 게임 로직은 **절대** 텍스처 크기, 픽셀 단위에 의존하지 않음
- 모든 로직은 **그리드 좌표** 기반으로 동작
- 비주얼 요소(텍스처, 크기, 색상)는 언제든 변경 가능해야 함

**예시:**

❌ **나쁜 예 (강한 결합):**
```gdscript
# 텍스처 크기에 의존
var tile_size = 32  # 하드코딩!
var world_pos = grid_pos * tile_size  # 텍스처 크기 변경 시 로직 깨짐
```

✅ **좋은 예 (분리):**
```gdscript
# config/game_config.gd (설정 파일)
const TILE_SIZE = Vector2(32, 32)  # 언제든 변경 가능

# scripts/map/grid_system.gd (로직)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
    # 설정에서 가져옴 (로직은 설정과 독립적)
    return Vector2(grid_pos) * GameConfig.TILE_SIZE
```

**적용 지침:**
1. **그리드 좌표로 로직 작성**: 모든 게임 로직은 `Vector2i` 그리드 좌표 사용
2. **설정 파일 분리**: 텍스처 크기, 색상 등은 별도 설정 파일 (`game_config.gd`)
3. **변환 레이어 사용**: `grid_system.gd`에서만 그리드 ↔ 월드 좌표 변환
4. **비주얼은 표현 계층**: `building.gd`의 `update_visual()`은 상태만 반영, 로직 없음

### 3.2. 변경 가능한 요소들

다음 요소들은 언제든 변경될 수 있으므로 하드코딩 금지:

- 타일/건물 텍스처 크기 (32x32 → 64x64 등)
- 스프라이트 에셋 경로
- 색상/이펙트
- 아이소메트릭 비율 (2:1, 1:1 등)
- 애니메이션 속도

**변경 시 영향 범위:**
- ✅ 설정 파일만 수정
- ✅ 에셋 교체
- ❌ 게임 로직 수정 불필요

## 4. 아키텍처

### 4.1. 레이어 구조 (z_index 기반)

**최종 씬 구조:**
```
test_map (Node2D)
└── World (Node2D, y_sort_enabled = true)
    ├── GroundTileMapLayer (y_sort_enabled = true, z_index = 0)    🟦 배경 레이어
    ├── StructuresTileMapLayer (y_sort_enabled = true, z_index = 0) 🟦 배경 레이어
    └── Entities (Node2D, y_sort_enabled = true, z_index = 1)       🟩 엔티티 레이어
        ├── Building1, Building2...  ← BuildingManager가 동적 생성
        └── Unit1, Unit2...          ← UnitManager가 동적 생성
```

**레이어 분리 기준:**
- **z_index = 0**: 바닥 및 구조물 (정적 배경)
- **z_index = 1**: 동적 엔티티 (건물, 유닛)
- **z_index = 2**: 공중 오브젝트 (구름, 새 - 미래 확장)

### 4.2. 렌더링 순서 보장

**Godot의 렌더링 우선순위:**
1. **z_index** (우선순위 최상)
2. **Y-Sort** (같은 z_index 내에서)
3. **노드 트리 순서** (Y좌표도 같을 때)

**결과:**
- 모든 배경 타일 (z_index = 0) 먼저 렌더링
- 모든 엔티티 (z_index = 1) 나중에 렌더링
- 각 레이어 내에서는 Y좌표로 정렬 (Y-Sort)

### 4.3. 레이어별 Y-Sort 설정

**World (루트 컨테이너):**
```gdscript
y_sort_enabled = true  # 직계 자식들을 Y좌표로 정렬
```

**GroundTileMapLayer (배경):**
```gdscript
y_sort_enabled = true   # 타일들끼리 Y좌표로 정렬
z_index = 0             # 배경 레이어
```
- 아이소메트릭 타일들이 올바른 전후관계로 렌더링됨
- Y좌표가 큰 타일이 앞에 그려짐

**Entities (엔티티 컨테이너):**
```gdscript
y_sort_enabled = true   # 엔티티들끼리 Y좌표로 정렬
z_index = 1             # 전경 레이어 (항상 배경 위)
```
- 건물, 유닛 등이 Y좌표에 따라 정렬
- 항상 모든 배경 타일 위에 렌더링됨

### 4.4. 분리 이유
- **TileMapLayer**: 바닥 타일 렌더링 최적화, 상태 불필요
- **Building 씬**: 개별 상태 관리 (감염 진행도, 상태 변화)
- **z_index 분리**: 엔티티가 항상 배경 위에 렌더링되도록 보장
- **Entities 컨테이너**: 구조적으로 정리, 관리 용이

## 5. 폴더 구조

```
isometric-strategy-framework/
├── scenes/
│   ├── tiles/                    # 타일 시스템 (소스코드)
│   │   ├── ground_tileset.tres          # 바닥 TileSet 리소스
│   │   ├── ground_tilemaplayer.tscn     # 바닥 TileMapLayer 씬 (Navigation 설정 포함)
│   │   ├── road_tileset.tres            # 도로 TileSet (옵션)
│   │   └── road_tilemaplayer.tscn       # 도로 TileMapLayer (옵션)
│   ├── buildings/
│   │   └── building.tscn         # 건물 씬 (단일 씬, 상태 관리)
│   ├── maps/
│   │   ├── test_map.tscn         # 테스트용 맵
│   │   └── level_01.tscn         # 실제 레벨
│   └── main.tscn
│
├── scripts/
│   ├── buildings/
│   │   ├── building.gd           # 건물 상태 관리
│   │   └── building_manager.gd   # 건물 생성/배치 매니저
│   ├── map/
│   │   ├── grid_system.gd        # 그리드 좌표 변환
│   │   └── spread_logic.gd       # 전파 알고리즘
│   ├── config/
│   │   └── game_config.gd        # 게임 설정 (텍스처 크기 등)
│   └── main.gd
│
├── assets/
│   └── sprites/                  # 정적 자료 (이미지)
│       ├── tiles/
│       │   ├── ground.png               # 바닥 타일 스프라이트
│       │   └── road.png                 # 도로 타일 스프라이트
│       └── buildings/
│           ├── building_normal.png      # 일반 상태
│           ├── building_infecting.png   # 감염 중
│           └── building_infected.png    # 감염 완료
│
└── resources/
    └── building_data.gd          # 건물 데이터 리소스
```

**폴더 구분:**
- `scenes/tiles/`: 타일 시스템 (소스코드)
  - **TileSet (.tres)**: 타일 정의, Navigation Polygon 설정
  - **TileMapLayer (.tscn)**: Navigation Layer 설정 포함, 재사용 가능
- `assets/sprites/`: 정적 자료 (이미지만)
  - 소스코드와 완전히 분리
  - 이미지 파일만 위치
- `scenes/buildings/`: 건물 씬 (감염 대상)
- `scenes/maps/`: 맵 씬들
- `scripts/`: 스크립트 파일들
- `resources/`: 커스텀 리소스 클래스

**TileSet과 TileMapLayer 한 쌍 관리:**
- `ground_tileset.tres` ↔ `ground_tilemaplayer.tscn` (1:1 관계)
- `scenes/tiles/` 폴더에 함께 위치
- Navigation Layer 설정이 씬에 저장되어 재사용 가능

**소스코드 vs 정적 자료 분리:**
- 소스코드: `scenes/`, `scripts/`, `resources/`
- 정적 자료: `assets/sprites/`

### 5.1. Scene Instance Pattern (중요!)

**TileMapLayer Factory 패턴 활용:**

`ground_tilemaplayer.tscn`은 **Factory(템플릿)** 역할:
- 공통 설정만 정의 (TileSet, Navigation Layer, Y-Sort 등)
- 타일 배치는 **없음** (빈 템플릿)
- 여러 맵에서 인스턴스화하여 사용

**각 맵은 인스턴스 + Override:**
```
ground_tilemaplayer.tscn (Factory)
├─ test_map.tscn (인스턴스 - 타일 배치 A)
├─ level_01.tscn (인스턴스 - 타일 배치 B)
└─ level_02.tscn (인스턴스 - 타일 배치 C)
```

**동작 방식:**
1. Factory에서 공통 설정 관리
2. 각 맵에서 `ground_tilemaplayer.tscn` 인스턴스화
3. 타일 배치만 Override → 그 맵에만 저장됨
4. Factory 수정 → 모든 맵에 자동 반영 (타일 배치 제외)

**주의사항:**
- ❌ Factory에 타일 배치하지 말 것 (빈 템플릿 유지)
- ✅ 각 맵에서 타일 배치 (Override)
- Unity의 "Apply to Prefab" 버튼은 없음 (단방향만)

**자세한 내용**: `docs/design/godot_scene_instance_pattern.md` 참고

## 6. 건물 상태 시스템

### 6.1. 상태 정의
```gdscript
enum BuildingState {
    NORMAL,      # 일반 상태 (미감염)
    INFECTING,   # 감염 진행 중
    INFECTED     # 감염 완료
}
```

### 6.2. 단일 씬 + 상태 관리 방식
**하나의 씬 (`building.tscn`)만 사용:**
- 모든 건물이 동일한 구조 (Sprite2D + 스크립트)
- 상태(enum)에 따라 텍스처/색상만 변경
- 메모리 효율적이고 유지보수 용이

**별도 씬 분리 X:**
- `building_infected.tscn`, `building_complete.tscn` 같은 별도 씬 불필요
- 상태만 다르므로 enum으로 충분

### 6.3. 스크립트 예시 (UI/Logic 분리 적용)

**설정 파일 (UI 관련):**
```gdscript
# scripts/config/game_config.gd
extends Node
class_name GameConfig

# 비주얼 설정 (언제든 변경 가능)
const TILE_SIZE = Vector2(32, 32)  # 텍스처 크기 변경 시 여기만 수정
const ISOMETRIC_RATIO = Vector2(2, 1)  # 아이소메트릭 비율

# 스프라이트 경로 (에셋 교체 시 여기만 수정)
const BUILDING_SPRITES = {
    "normal": "res://assets/sprites/buildings/building_normal.png",
    "infecting": "res://assets/sprites/buildings/building_infecting.png",
    "infected": "res://assets/sprites/buildings/building_infected.png"
}
```

**건물 스크립트 (로직):**
```gdscript
# scripts/buildings/building.gd
extends Sprite2D
class_name Building

# 로직 데이터 (그리드 기반, 텍스처 크기와 무관)
var state: BuildingState = BuildingState.NORMAL
var infection_progress: float = 0.0  # 0.0 ~ 1.0
var grid_position: Vector2i          # 그리드 좌표 (로직의 핵심)

func _ready():
    update_visual()

# 상태 변경 (순수 로직)
func set_state(new_state: BuildingState):
    state = new_state
    update_visual()  # 비주얼만 업데이트, 로직 분리

# 비주얼 업데이트 (표현 계층, 로직 없음)
func update_visual():
    match state:
        BuildingState.NORMAL:
            texture = load(GameConfig.BUILDING_SPRITES["normal"])
        BuildingState.INFECTING:
            texture = load(GameConfig.BUILDING_SPRITES["infecting"])
            # 진행도 표시 (비주얼만)
            modulate = Color(1.0, 1.0 - infection_progress * 0.5, 1.0)
        BuildingState.INFECTED:
            texture = load(GameConfig.BUILDING_SPRITES["infected"])
            modulate = Color.WHITE

# 감염 시작 (순수 로직, 텍스처와 무관)
func start_infection(speed_multiplier: float):
    if state == BuildingState.NORMAL:
        state = BuildingState.INFECTING
        # 감염 진행 시작 로직
```

**핵심:**
- `grid_position`으로 로직 처리 (픽셀 단위 사용 안 함)
- 텍스처 크기는 `GameConfig`에서만 참조
- `update_visual()`은 상태를 표현만 함 (로직 없음)

## 7. 그리드 시스템 (UI/Logic 분리 적용)

### 7.1. 좌표 변환
- **그리드 좌표**: `Vector2i(x, y)` - 논리적 그리드 위치 (로직에서 사용)
- **월드 좌표**: `Vector2(x, y)` - 화면상 픽셀 위치 (표현에서 사용)
- `grid_system.gd`에서만 변환 처리 (변환 레이어)

**좌표 변환 예시:**
```gdscript
# scripts/map/grid_system.gd
class_name GridSystem

# 그리드 → 월드 (설정에서 크기 가져옴)
static func grid_to_world(grid_pos: Vector2i) -> Vector2:
    # 텍스처 크기에 의존하지 않고 설정 사용
    var tile_size = GameConfig.TILE_SIZE
    var iso_ratio = GameConfig.ISOMETRIC_RATIO

    # 아이소메트릭 변환
    var world_x = (grid_pos.x - grid_pos.y) * tile_size.x / iso_ratio.x
    var world_y = (grid_pos.x + grid_pos.y) * tile_size.y / iso_ratio.y
    return Vector2(world_x, world_y)

# 월드 → 그리드
static func world_to_grid(world_pos: Vector2) -> Vector2i:
    var tile_size = GameConfig.TILE_SIZE
    var iso_ratio = GameConfig.ISOMETRIC_RATIO

    # 역변환
    var grid_x = int((world_pos.x / tile_size.x * iso_ratio.x + world_pos.y / tile_size.y * iso_ratio.y) / 2)
    var grid_y = int((world_pos.y / tile_size.y * iso_ratio.y - world_pos.x / tile_size.x * iso_ratio.x) / 2)
    return Vector2i(grid_x, grid_y)
```

### 7.2. 건물 배치
```gdscript
# scripts/buildings/building_manager.gd
func create_building(grid_pos: Vector2i) -> Building:
    var building = BUILDING_SCENE.instantiate()

    # 로직: 그리드 좌표만 저장
    building.grid_position = grid_pos

    # 표현: 변환 레이어 사용
    building.position = GridSystem.grid_to_world(grid_pos)

    building_layer.add_child(building)
    grid_buildings[grid_pos] = building
    return building
```

**핵심:**
- 로직은 항상 `grid_pos` 사용
- 화면 표시는 `GridSystem.grid_to_world()` 사용
- 텍스처 크기 변경 시 `GridSystem`과 `GameConfig`만 수정

### 7.3. Diamond Right 레이아웃 설정

**TileMapLayer 설정:**
- **Layout**: Diamond Right (Godot TileMap 설정)
- **타일 배치**: 다이아몬드(마름모) 형태

**Diamond Right 구조:**
```
       (0,0)
      /    \
  (0,1)    (1,0)
    /  \  /  \
(0,2) (1,1) (2,0)
  \  /  \  /  \
  (1,2) (2,1) (3,0)
```

#### 시작 좌표 설정

**1. 그리드 좌표 (로직 레벨)**

항상 **(0, 0)부터 시작**:
```gdscript
# 5x5 맵 생성
for x in range(5):
    for y in range(5):
        create_building(Vector2i(x, y))  # (0,0)부터 시작
```

**이유:**
- 로직이 단순함
- 배열 인덱스와 일치
- 음수 좌표 처리 불필요

**2. 월드 좌표 (화면 표시 레벨)**

화면 중앙 또는 카메라 기준으로 배치:

```gdscript
# scenes/maps/test_map.tscn의 스크립트
extends Node2D

func _ready():
    # TileMapLayer 위치 설정
    var tilemap = $TileMapLayer

    # 화면 상단-중앙에 배치
    tilemap.position = Vector2(
        get_viewport_rect().size.x / 2,  # 화면 가로 중앙
        100  # 위에서 100픽셀 아래
    )

    # BuildingLayer도 같은 기준점 사용
    var building_layer = $BuildingLayer
    building_layer.position = tilemap.position
```

#### 맵 크기별 권장 설정

**테스트 맵:**
```gdscript
const TEST_MAP_SIZE = Vector2i(5, 5)  # 또는 7x7

# 화면 배치
tilemap.position = Vector2(
    get_viewport_rect().size.x / 2,
    100
)
```

**실제 레벨:**
```gdscript
const LEVEL_MAP_SIZE = Vector2i(50, 50)  # 큰 맵

# 카메라 중심 설정
var camera = $Camera2D
var center_tile = Vector2i(25, 25)  # 맵 중앙
camera.position = GridSystem.grid_to_world(center_tile)
```

#### TileMapLayer와 BuildingLayer 정렬

**중요**: 두 레이어가 같은 기준점을 사용해야 함

```gdscript
# 씬 구조
Node2D (맵 루트)
├── TileMapLayer (바닥)
│   └── position = Vector2(400, 100)
└── BuildingLayer (건물들)
    └── position = Vector2(400, 100)  # TileMap과 동일!
```

**좌표 일치 확인:**
```gdscript
# 그리드 (2, 3) 위치가 두 레이어에서 같은 월드 좌표여야 함
var grid_pos = Vector2i(2, 3)
var world_pos = GridSystem.grid_to_world(grid_pos)

# TileMap의 타일과 Building이 정확히 겹쳐야 함
```

### 7.4. Navigation Layers (경로 찾기 및 유닛 이동)

**Godot 내장 기능 활용** - 경로 찾기를 위한 최적의 방법

#### 개요

Navigation Layers는 Godot의 내장 네비게이션 시스템으로, 다음을 자동으로 제공합니다:
- ✅ A* 경로 찾기 알고리즘
- ✅ 성능 최적화된 구현
- ✅ 타일셋 에디터에서 시각적 설정
- ✅ 여러 레이어로 유닛 타입 구분 (지상/공중 등)

#### 설정 방법 (Godot 에디터)

**Step 1: TileSet 리소스 생성 (ground_tileset.tres)**

```
Godot 에디터:
1. FileSystem → scenes/tiles/ 우클릭
2. "Create New" → "TileSet"
3. 이름: ground_tileset.tres
4. TileSet 에디터 열기
5. 타일 스프라이트 추가
   - 경로: assets/sprites/tiles/ground.png
6. Navigation 탭 → Navigation Polygon 그리기
   - 일반 지면: 전체 타일에 Polygon
   - 도로: 전체 타일에 Polygon (빠른 이동)
   - 장애물: Navigation 없음
7. 저장
```

**Step 2: TileMapLayer 씬 생성 (ground_tilemaplayer.tscn)**

```
Godot 에디터:
1. Scene → New Scene
2. Other Node → TileMapLayer 선택
3. Inspector에서 설정:
   - Tile Set: scenes/tiles/ground_tileset.tres 할당
   - Navigation → Enabled: true
   - Navigation Layers 추가:
     * Layer 0: "Ground" (지상 유닛)
     * Layer 1: "Vehicle" (옵션)
4. Scene → Save Scene As
   - 위치: scenes/tiles/ground_tilemaplayer.tscn
5. 저장
```

**중요:** 타일 배치하지 말 것! Factory는 빈 템플릿으로 유지

**Step 3: 맵에서 사용 (인스턴스화)**

```
test_map.tscn (scenes/maps/test_map.tscn):
1. MapRoot (Node2D)에 자식 추가
2. "Instantiate Child Scene" 클릭
3. scenes/tiles/ground_tilemaplayer.tscn 선택
4. 이름: GroundTileMapLayer
5. 타일 배치 시작!
```

**결과:**
- Navigation 설정이 씬에 저장됨
- 다른 맵에서도 ground_tilemaplayer.tscn 재사용 가능 (인스턴스화)
- 각 맵의 타일 배치는 Override로 저장됨
- 매번 Navigation 설정 불필요!

**Scene Instance Pattern 활용:**
- Factory: ground_tilemaplayer.tscn (공통 설정)
- Instance: test_map.tscn, level_01.tscn 등 (타일 배치만)
- 자세한 내용: `docs/design/godot_scene_instance_pattern.md`

#### 씬 구조

```
Node2D (MapRoot)
├── TileMapLayer (바닥, Navigation Layers 포함)
│   └── TileSet에 Navigation 설정됨
├── BuildingLayer (Node2D)
│   └── Building 인스턴스들
│       └── NavigationObstacle2D (건물이 경로 막음)
└── UnitLayer (Node2D)
    └── Unit 인스턴스들
        └── NavigationAgent2D (경로 찾기)
```

#### 유닛 이동 구현

**NavigationAgent2D 사용:**

```gdscript
# scripts/units/unit.gd
extends CharacterBody2D  # 물리 이동용
class_name Unit

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var grid_position: Vector2i
var move_speed: float = 100.0

func _ready():
    # NavigationAgent 설정
    nav_agent.path_desired_distance = 4.0
    nav_agent.target_desired_distance = 4.0

    # Navigation Layer 설정 (지상 유닛)
    nav_agent.set_navigation_layers(1)  # Layer 0 = bit 1

# 그리드 좌표로 이동 명령 (UI/Logic 분리 유지)
func move_to_grid(target_grid: Vector2i):
    # 그리드 → 월드 좌표 변환
    var target_world = GridSystem.grid_to_world(target_grid)

    # NavigationAgent에 목표 설정 (자동 경로 찾기)
    nav_agent.target_position = target_world
    grid_position = target_grid

func _physics_process(delta):
    # 목적지 도착 확인
    if nav_agent.is_navigation_finished():
        return

    # 다음 경로 지점 가져오기
    var next_path_pos = nav_agent.get_next_path_position()
    var direction = (next_path_pos - global_position).normalized()

    # 이동
    velocity = direction * move_speed
    move_and_slide()
```

#### 동적 장애물 (건물 배치 시)

**건물이 생길 때 경로 막기:**

```gdscript
# scenes/buildings/building.tscn
Building (Sprite2D)
└── NavigationObstacle2D  # 씬에 미리 추가
    └── radius: 16.0  # 타일 크기의 절반

# scripts/buildings/building.gd
extends Sprite2D
class_name Building

@onready var nav_obstacle: NavigationObstacle2D = $NavigationObstacle2D

func _ready():
    # 장애물 활성화
    nav_obstacle.avoidance_enabled = true

    # 상태에 따라 장애물 on/off
    if state == BuildingState.INFECTED:
        nav_obstacle.avoidance_enabled = false  # 감염되면 통과 가능 (옵션)
```

**또는 TileMap 동적 업데이트:**

```gdscript
# scripts/buildings/building_manager.gd
func create_building(grid_pos: Vector2i) -> Building:
    var building = BUILDING_SCENE.instantiate()
    # ... 건물 생성

    # 해당 위치의 네비게이션 타일 제거
    update_navigation_at(grid_pos, false)

    return building

func update_navigation_at(grid_pos: Vector2i, enabled: bool):
    var tilemap = get_node("../TileMapLayer")

    if not enabled:
        # 타일 제거 (네비게이션도 제거됨)
        tilemap.erase_cell(0, grid_pos)
    else:
        # 타일 복원
        tilemap.set_cell(0, grid_pos, 0, Vector2i(0, 0))
```

#### 그리드 메타데이터와 병행 사용

**Navigation Layers + 그리드 메타데이터 조합:**

```gdscript
# scripts/map/grid_system.gd
static var grid_metadata: Dictionary = {}

class TileMetadata:
    var buildable: bool = true  # 건물 배치 가능 여부
    var tile_type: TileType
    # walkable은 Navigation이 처리하므로 불필요

enum TileType {
    GROUND,      # 일반 지면
    ROAD,        # 도로 (전파 빠름)
    OBSTACLE     # 장애물
}

# 건물 배치 가능 여부만 체크
static func is_buildable(grid_pos: Vector2i) -> bool:
    if grid_metadata.has(grid_pos):
        return grid_metadata[grid_pos].buildable
    return true

# 경로 찾기는 NavigationAgent가 자동 처리
```

#### 전파 속도 가중치 적용

```gdscript
# scripts/map/spread_logic.gd
func get_spread_multiplier(grid_pos: Vector2i) -> float:
    var multiplier = 1.0

    # 타일 타입에 따른 전파 속도
    var tile_type = GridSystem.get_tile_type(grid_pos)
    match tile_type:
        GridSystem.TileType.ROAD:
            multiplier *= 1.5  # 도로는 50% 빠른 전파
        GridSystem.TileType.OBSTACLE:
            multiplier = 0.0   # 장애물은 전파 불가

    # 인접 감염 건물 수에 따른 가중치
    var neighbor_count = get_infected_neighbor_count(grid_pos)
    multiplier *= get_neighbor_multiplier(neighbor_count)

    return multiplier
```

#### 장점 요약

| 기능 | 수동 구현 | Navigation Layers |
|------|----------|-------------------|
| 경로 찾기 | 직접 A* 구현 | ✅ 자동 제공 |
| 성능 | 최적화 필요 | ✅ 최적화됨 |
| 동적 장애물 | 직접 처리 | ✅ NavigationObstacle2D |
| 디버깅 | 어려움 | ✅ 에디터에서 시각화 |
| 복잡도 | 높음 | ✅ 낮음 |

#### 주의사항

- **UI/Logic 분리 유지**: 이동 명령은 그리드 좌표 사용, 내부적으로만 월드 좌표 변환
- **Navigation 업데이트**: 건물 배치/제거 시 네비게이션 정보 갱신 필요
- **Layer 비트 마스크**: `set_navigation_layers(1 << 0)` = Layer 0, `1 << 1` = Layer 1

## 8. 전파 로직 (PRD 2.2 연계)

### 8.1. 인접 건물 감지 (그리드 기반 로직)
```gdscript
# scripts/map/spread_logic.gd
const NEIGHBORS = [
    Vector2i(1, 0),   # 우
    Vector2i(-1, 0),  # 좌
    Vector2i(0, 1),   # 하
    Vector2i(0, -1)   # 상
]

func get_infected_neighbor_count(grid_pos: Vector2i) -> int:
    var count = 0
    for offset in NEIGHBORS:
        var neighbor_pos = grid_pos + offset
        var building = building_manager.get_building(neighbor_pos)
        if building and building.state == BuildingState.INFECTED:
            count += 1
    return count
```

### 8.2. 감염 속도 가중치
- 1면 포위: 1.0x
- 2면 포위: 1.5x
- 3면 포위: 2.0x
- 4면 포위: 3.0x

**중요**: 이 로직은 순수하게 그리드 좌표만 사용하므로 텍스처 크기와 완전히 독립적입니다.

## 9. 맵 종류 및 구분

### 10.1. 테스트 맵 (test_map.tscn)

**목적**: 개발 중 기능 검증

**특징:**
- 작은 크기 (5x5 ~ 10x10 그리드)
- 단순한 배치 (정사각형, 일자 배치)
- 디버그 정보 표시 (그리드 좌표, 상태 텍스트)
- 빠른 테스트 시나리오
  - 감염 전파 속도 확인
  - 포위 가중치 테스트
  - 상태 전환 확인

**씬 구성 예시:**
```
[test_map.tscn]
├── TileMapLayer (5x5 바닥)
├── BuildingLayer
│   ├── Building (0,0) - 초기 감염
│   ├── Building (1,0)
│   └── ... (25개 건물)
├── DebugLabel (상태 정보 표시)
└── Camera2D (고정)
```

### 10.2. 실제 맵 (level_01.tscn, level_02.tscn, ...)

**목적**: 플레이어가 플레이하는 레벨

**특징:**
- 큰 크기 (50x50 ~ 100x100)
- 게임 디자인된 배치
  - 장애물, 전략적 요충지
  - 적 배치 위치
  - 난이도 조절
- UI/HUD 포함
- 승리/패배 조건
- 레벨별 고유 목표
  - "70% 영역 감염"
  - "3분 안에 클리어"

**씬 구성 예시:**
```
[level_01.tscn]
├── TileMapLayer (50x50 바닥)
├── BuildingLayer (수백 개 건물)
├── EnemyLayer
├── PlayerSpawn
├── UI (HUD, 미니맵)
├── LevelManager (스크립트)
└── Camera2D (플레이어 추적)
```

### 10.3. 개발 워크플로우

```
1. 새 기능 개발
   → test_map.tscn에서 테스트

2. 기능 검증 완료
   → level_01.tscn에 적용

3. 밸런스/난이도 조정
   → 실제 맵에서만 진행
```

### 10.4. 맵 폴더 구조 (선택적 확장)

프로젝트 규모가 커지면 다음과 같이 세분화 가능:

```
scenes/maps/
├── test_map.tscn           # 기본 기능 테스트
├── test_spread.tscn        # 전파 로직 전용 테스트
├── test_performance.tscn   # 대량 건물 성능 테스트
└── levels/
    ├── level_01.tscn       # 튜토리얼 레벨
    ├── level_02.tscn
    └── boss_level.tscn
```

## 11. 참고사항

### UI/Logic 분리 체크리스트
구현 시 아래 사항을 항상 확인:

- [ ] 게임 로직이 픽셀/텍스처 크기를 직접 사용하는가? → ❌ 금지
- [ ] 그리드 좌표(`Vector2i`)로 로직을 작성했는가? → ✅ 필수
- [ ] 비주얼 설정이 `GameConfig`에 있는가? → ✅ 필수
- [ ] 좌표 변환을 `GridSystem`에서만 하는가? → ✅ 필수
- [ ] 텍스처 크기를 변경해도 로직이 깨지지 않는가? → ✅ 검증

### 기타
- TileMapLayer의 타일셋은 Godot 에디터에서 설정
- 아이소메트릭 좌표 변환 공식은 `GridSystem`에 구현
- 성능 최적화: 감염 중인 건물만 `_process` 활성화

## 12. 레이어 시스템 구현 가이드

### 12.1. 새로운 엔티티 추가 방법

**예시: 유닛 추가**

```gdscript
# scripts/managers/unit_manager.gd
class_name UnitManager

var entities_container: Node2D  # Entities 컨테이너 참조

func initialize(entities: Node2D):
    entities_container = entities

func create_unit(grid_pos: Vector2i) -> Unit:
    var unit = UnitScene.instantiate()

    # 그리드 좌표 설정
    unit.grid_position = grid_pos

    # 월드 좌표 변환
    unit.global_position = GridSystem.grid_to_world(grid_pos)

    # Entities 컨테이너에 추가 (자동으로 z_index = 1, Y-Sort 적용)
    entities_container.add_child(unit)

    return unit
```

**핵심:**
- ✅ Entities 컨테이너에 추가하면 자동으로 올바른 레이어에 배치
- ✅ Y-Sort 자동 적용
- ✅ 항상 배경 타일 위에 렌더링

### 12.2. 공중 레이어 추가 (미래 확장)

**Step 1: test_map.tscn에 Sky 컨테이너 추가**

```
World (y_sort_enabled = true)
├── GroundTileMapLayer (z_index = 0)
├── StructuresTileMapLayer (z_index = 0)
├── Entities (z_index = 1)
└── Sky (Node2D, y_sort_enabled = true, z_index = 2)  ← 추가
    └── Cloud1, Bird1...
```

**Step 2: Godot 에디터에서 설정**

```
1. World 노드 우클릭 → Add Child Node → Node2D
2. 이름: Sky
3. Inspector:
   - CanvasItem → Ordering → Z Index: 2
   - CanvasItem → Ordering → Y Sort Enabled: true
4. 저장
```

**Step 3: 사용 예시**

```gdscript
# scripts/managers/sky_manager.gd
class_name SkyManager

var sky_container: Node2D

func initialize(sky: Node2D):
    sky_container = sky

func create_cloud(grid_pos: Vector2i) -> Cloud:
    var cloud = CloudScene.instantiate()
    cloud.global_position = GridSystem.grid_to_world(grid_pos)

    # Sky 컨테이너에 추가 (z_index = 2, 모든 것 위에)
    sky_container.add_child(cloud)

    return cloud
```

### 12.3. 레이어별 렌더링 순서 정리

| z_index | 레이어 | 내용 | Y-Sort |
|---------|--------|------|--------|
| 0 | 배경 | GroundTileMapLayer, StructuresTileMapLayer | ✅ 타일들끼리 |
| 1 | 엔티티 | Buildings, Units | ✅ 엔티티들끼리 |
| 2 | 공중 | Clouds, Birds (미래) | ✅ 공중 오브젝트끼리 |

**렌더링 흐름:**
1. 모든 배경 타일 렌더링 (z_index = 0, Y-Sort 적용)
2. 모든 엔티티 렌더링 (z_index = 1, Y-Sort 적용)
3. 모든 공중 오브젝트 렌더링 (z_index = 2, Y-Sort 적용)

### 12.4. 매니저 초기화 패턴

**test_map.gd 예시:**

```gdscript
# scripts/maps/test_map.gd
extends Node2D

@onready var world_container: Node2D = $World
@onready var entities_container: Node2D = $World/Entities
@onready var sky_container: Node2D = $World/Sky  # 미래

var building_manager: BuildingManager
var unit_manager: UnitManager
var sky_manager: SkyManager  # 미래

func _ready():
    # BuildingManager 초기화
    building_manager = BuildingManager.new()
    add_child(building_manager)
    building_manager.initialize(entities_container)  # Entities에 추가

    # UnitManager 초기화
    unit_manager = UnitManager.new()
    add_child(unit_manager)
    unit_manager.initialize(entities_container)  # 같은 컨테이너

    # SkyManager 초기화 (미래)
    # sky_manager = SkyManager.new()
    # add_child(sky_manager)
    # sky_manager.initialize(sky_container)  # Sky에 추가
```

**핵심 패턴:**
- 모든 동적 엔티티는 `entities_container`에 추가
- 각 매니저는 컨테이너 참조만 받음
- z_index와 Y-Sort는 컨테이너가 자동 처리

### 12.5. 디버깅 팁

**렌더링 순서 확인:**

```gdscript
# 디버그용 스크립트 (test_map.gd에 추가)
func _input(event):
    if event.is_action_pressed("ui_accept"):  # Space 키
        print("=== 렌더링 순서 디버그 ===")
        print_tree_pretty()

func print_tree_pretty():
    for child in world_container.get_children():
        print("- %s (z_index: %d, y_sort: %s)" % [
            child.name,
            child.z_index,
            child.y_sort_enabled
        ])
        if child.get_child_count() > 0:
            for grandchild in child.get_children():
                print("  - %s (pos.y: %.1f)" % [
                    grandchild.name,
                    grandchild.global_position.y
                ])
```

**Godot Remote 탭에서 확인:**
- Scene 트리에서 노드 순서 확인
- z_index, y_sort_enabled 속성 확인
- 유닛이 Entities 컨테이너 아래에 있는지 확인

### 12.6. 주의사항

**❌ 하지 말아야 할 것:**
```gdscript
# 잘못된 예: World에 직접 추가
world_container.add_child(unit)  # ❌ z_index가 명확하지 않음

# 잘못된 예: 별도 컨테이너 추가 후 z_index 누락
var units = Node2D.new()
world_container.add_child(units)
# z_index 설정 안 함! ❌
units.add_child(unit)
```

**✅ 올바른 방법:**
```gdscript
# 올바른 예: Entities 컨테이너 사용
entities_container.add_child(unit)  # ✅ z_index = 1 자동 적용

# 올바른 예: 새 컨테이너 추가 시 z_index 명시
var units = Node2D.new()
units.y_sort_enabled = true
units.z_index = 1  # ✅ 명시적 설정
world_container.add_child(units)
```

## 13. 성능 고려사항

### 13.1. Y-Sort 비용

**Y-Sort는 매 프레임 정렬을 수행하므로 비용이 있음**

**최적화 방법:**
- ✅ 정적 오브젝트는 Y-Sort 비활성화 (배경 타일 제외)
- ✅ 엔티티가 이동하지 않으면 Y좌표 변경 최소화
- ✅ 대량의 엔티티는 필요한 것만 Y-Sort

**예시:**
```gdscript
# 고정된 건물은 Y좌표가 변하지 않으므로 Y-Sort 비용 낮음
# 이동하는 유닛만 매 프레임 재정렬됨
```

### 13.2. z_index 활용

**z_index는 Y-Sort보다 빠름 (정수 비교만)**

**권장 구조:**
- 레이어는 z_index로 분리 (빠름)
- 각 레이어 내부만 Y-Sort (필요한 곳만)
