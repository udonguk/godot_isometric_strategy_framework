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

### 4.1. 레이어 구조
```
Scene 구조:
├── TileMapLayer (바닥)      # 정적 배경, 시각적 용도
└── BuildingLayer (Node2D)   # 상태를 가진 건물들
    ├── Building (인스턴스 1)
    ├── Building (인스턴스 2)
    └── ...
```

### 4.2. 분리 이유
- **TileMapLayer**: 바닥 타일 렌더링 최적화, 상태 불필요
- **Building 씬**: 개별 상태 관리 (감염 진행도, 상태 변화)

## 5. 폴더 구조

```
vampire-spread-isometric/
├── scenes/
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
│   ├── buildings/
│   │   └── sprites/
│   │       ├── building_normal.png      # 일반 상태
│   │       ├── building_infecting.png   # 감염 중
│   │       └── building_infected.png    # 감염 완료
│   ├── tiles/
│   │   └── tilesets/
│   │       └── ground_tileset.tres      # 바닥 타일셋
│   └── ...
│
└── resources/
    └── building_data.gd          # 건물 데이터 리소스
```

**폴더 구분:**
- `tiles/`: 바닥 타일 에셋 (TileMapLayer용)
- `buildings/`: 상태를 가진 건물 (감염 대상)
- `units/` (추후): 이동 가능한 유닛들
- `config/`: 게임 설정 파일 (UI와 로직 분리)

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
    "normal": "res://assets/buildings/sprites/building_normal.png",
    "infecting": "res://assets/buildings/sprites/building_infecting.png",
    "infected": "res://assets/buildings/sprites/building_infected.png"
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

## 9. 구현 우선순위

### Phase 1: 기본 구조 + 설정 분리
- [ ] 폴더 구조 생성 (`buildings/`, `config/` 포함)
- [ ] `game_config.gd` 생성 (텍스처 크기, 경로 등)
- [ ] `building.tscn` 씬 생성
- [ ] `building.gd` 상태 관리 구현 (UI/Logic 분리 적용)
- [ ] 테스트 맵에 수동 배치 테스트

### Phase 2: 그리드 시스템
- [ ] `grid_system.gd` 좌표 변환 (GameConfig 참조)
- [ ] `building_manager.gd` 동적 생성/배치
- [ ] 그리드 데이터 구조 (`Dictionary<Vector2i, Building>`)

### Phase 3: 전파 로직
- [ ] `spread_logic.gd` 인접 감지 (순수 그리드 로직)
- [ ] 감염 진행 시스템 (`_process`에서 `infection_progress` 업데이트)
- [ ] 포위 수에 따른 가중치 적용

## 10. 맵 종류 및 구분

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
