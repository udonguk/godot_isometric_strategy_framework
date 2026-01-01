# 캐릭터 시스템 설계

## 1. 개요

아이소메트릭 타이쿤 게임의 캐릭터(유닛/NPC) 시스템 설계 문서

**목적:**
- 플레이어 제어 유닛 및 자율 행동 NPC 구현
- 타일 시스템, Navigation, 애니메이션 통합
- 확장 가능한 캐릭터 타입 아키텍처

## 2. 용어 정의

- **Character (캐릭터)**: 맵 위를 이동 가능한 모든 엔티티의 총칭
- **Unit (유닛)**: 플레이어가 제어 가능한 캐릭터
- **NPC (Non-Player Character)**: 자율 행동하는 캐릭터 (타이쿤 게임의 주민, 직원 등)
- **Animation Direction**: 8방향 애니메이션 (N, NE, E, SE, S, SW, W, NW)

## 3. 핵심 설계 원칙

### 3.1. UI/Logic 분리 원칙 준수

**타일 시스템과 동일한 원칙 적용:**
- 게임 로직은 **그리드 좌표** 기반
- 텍스처 크기는 `GameConfig`에 분리
- 좌표 변환은 `GridSystem`에서만 처리

**예시:**
```gdscript
# ✅ 올바른 예
func move_to(target_grid: Vector2i):
    self.grid_position = target_grid
    self.global_position = GridSystem.grid_to_world(target_grid)

# ❌ 잘못된 예
func move_to(target_pixel: Vector2):
    self.position = target_pixel  # 픽셀 단위 직접 사용
```

### 3.2. 타일 대비 캐릭터 크기 비율

**타이쿤 게임 장르 특성 고려:**
- 타일 크기: 32x32 픽셀
- **캐릭터 크기: 타일의 70% = 22x22 픽셀** (권장)

**선택 이유:**
- ✅ 복도/방에서 여러 NPC 활동 가능
- ✅ 건물/가구와 캐릭터 구분 명확
- ✅ 가독성 우수
- ✅ 타이쿤 장르 관례 (Theme Hospital, Prison Architect 참고)

**크기 변경 시:**
- `GameConfig.UNIT_SIZE`만 수정
- 스프라이트 에셋 교체
- 로직 수정 불필요

### 3.3. Godot 내장 기능 우선 사용

**애니메이션:**
- ✅ `AnimatedSprite2D` 사용 (내장 노드)
- ❌ 수동 프레임 전환 구현 금지

**이동/경로 찾기:**
- ✅ `NavigationAgent2D` + `CharacterBody2D` 사용
- ❌ A* 직접 구현 금지
- Navigation Layers와 통합 (참고: `navigation_system_design.md`)

**물리:**
- ✅ `CharacterBody2D` (이동 가능 엔티티)
- ✅ `Area2D` (상호작용 범위)

## 4. 아키텍처

### 4.1. 씬 구조

**캐릭터 씬 계층:**
```
scenes/
├── entity/
│   ├── base_entity.tscn          # 공통 엔티티 베이스 (미래)
│   ├── unit_entity.tscn          # 플레이어 유닛
│   └── npc_entity.tscn           # 자율 행동 NPC (미래)
└── maps/
    └── test_map.tscn
        └── World/
            └── Entities (z_index = 1)
                ├── Unit1, Unit2...
                └── NPC1, NPC2...
```

**단일 씬 노드 구조 (unit_entity.tscn):**
```
UnitEntity (CharacterBody2D)
├── AnimatedSprite2D           # 애니메이션 스프라이트
├── NavigationAgent2D          # 경로 찾기
├── CollisionShape2D           # 물리 충돌
└── InteractionArea (Area2D)   # 상호작용 범위 (미래)
    └── CollisionShape2D
```

**핵심 노드 역할:**
- `CharacterBody2D`: 이동, 물리 처리 (`move_and_slide`)
- `AnimatedSprite2D`: 8방향 애니메이션 재생
- `NavigationAgent2D`: 자동 경로 찾기 (Godot Navigation과 통합)
- `Area2D`: 클릭 감지, 상호작용 범위

### 4.2. 레이어 통합 (기존 시스템과 연계)

**렌더링 순서:**
```
World (y_sort_enabled = true)
├── GroundTileMapLayer (z_index = 0)      # 바닥
├── StructuresTileMapLayer (z_index = 0)  # 구조물
└── Entities (z_index = 1, y_sort_enabled = true)
    ├── Buildings (Sprite2D)              # 건물
    └── Characters (CharacterBody2D)      # 캐릭터 ← 여기!
```

**Y-Sort 동작:**
- 캐릭터끼리 Y좌표로 정렬
- Y좌표가 큰 캐릭터가 앞에 렌더링
- 건물과 캐릭터도 Y좌표로 정렬 (같은 Entities 레이어)

**참고:** `tile_system_design.md` 12.1절 "레이어 시스템 구현 가이드"

## 5. 캐릭터 타입 시스템

### 5.1. 베이스 클래스 구조 (미래 확장)

**클래스 계층:**
```
BaseEntity (추상, 미래)
├── UnitEntity (플레이어 제어)
└── NPCEntity (자율 행동)
    ├── WorkerNPC (직원)
    ├── CustomerNPC (고객)
    └── EnemyNPC (적)
```

**현재 우선순위:**
- Phase 1: `UnitEntity`만 구현 (플레이어 유닛)
- Phase 2: `NPCEntity` 추가 (자율 행동)
- Phase 3: `BaseEntity` 추상화 (공통 로직 분리)

### 5.2. UnitEntity (플레이어 유닛)

**책임:**
- 플레이어 입력에 따른 이동
- 애니메이션 재생 (idle, walk)
- Navigation 경로 추종
- 상태 관리 (idle, moving, interacting)

**주요 메서드:**
```gdscript
func move_to_grid(target_grid: Vector2i)  # 그리드 좌표로 이동 명령
func stop_movement()                       # 이동 중지
func set_animation(anim_name: String, direction: int)  # 애니메이션 설정
```

### 5.3. NPCEntity (미래 - 타이쿤 게임용)

**책임:**
- 자율적 경로 탐색 (AI)
- 행동 트리 또는 상태 머신
- 목적지 자동 설정
- 직업별 행동 패턴

**예시 시나리오:**
- 직원 NPC: 작업장 → 휴게실 이동
- 고객 NPC: 입구 → 상점 → 계산대 이동
- 청소부 NPC: 쓰레기 위치로 이동

**구현 방향:**
- `NavigationAgent2D`로 자동 이동
- Timer 노드로 행동 주기 제어
- 상태 머신 패턴 사용

## 6. 애니메이션 시스템

### 6.1. 8방향 애니메이션

**방향 정의:**
```gdscript
enum Direction {
    SOUTH = 0,      # 아래 (↓)
    SOUTH_EAST = 1, # 우하 (↘)
    EAST = 2,       # 우 (→)
    NORTH_EAST = 3, # 우상 (↗)
    NORTH = 4,      # 위 (↑)
    NORTH_WEST = 5, # 좌상 (↖)
    WEST = 6,       # 좌 (←)
    SOUTH_WEST = 7  # 좌하 (↙)
}
```

**애니메이션 이름 규칙:**
- `idle_south`, `idle_south_east`, ..., `idle_south_west` (8개)
- `walk_south`, `walk_south_east`, ..., `walk_south_west` (8개)

**총 16개 애니메이션** (2 상태 × 8 방향)

### 6.2. AnimatedSprite2D 설정

**SpriteFrames 리소스 구조:**
```
unit_animations.tres (SpriteFrames)
├── idle_south (animation)
│   └── frames: [프레임1, 프레임2, ...]
├── idle_south_east
├── ... (idle 8개)
├── walk_south
├── walk_south_east
└── ... (walk 8개)
```

**스프라이트 시트 활용:**
- `walk-complete-sprite-sheet.png`: 걷기 애니메이션 (8x8 그리드?)
- `idle-full-sprite-sheet.png`: 대기 애니메이션 (12x8 그리드?)

**프레임 크기:**
- 원본 크기 무관 (GameConfig.UNIT_SIZE에 맞게 스케일 조정)
- 최종 렌더링: 22x22 픽셀 (타일의 70%)

### 6.3. 방향 계산 로직

**이동 방향 → 애니메이션 방향 변환:**
```gdscript
func get_direction_from_velocity(velocity: Vector2) -> int:
    var angle = velocity.angle()  # 라디안 각도
    var degree = rad_to_deg(angle)  # 도 단위 변환

    # 8방향 구간 나누기 (45도씩)
    # 0도 = 동쪽, 90도 = 남쪽 (Godot 좌표계)
    if degree >= -22.5 and degree < 22.5:
        return Direction.EAST
    elif degree >= 22.5 and degree < 67.5:
        return Direction.SOUTH_EAST
    # ... 나머지 방향
```

**또는 간단한 방법 (4방향 우선):**
```gdscript
func get_simple_direction(velocity: Vector2) -> int:
    if abs(velocity.x) > abs(velocity.y):
        return Direction.EAST if velocity.x > 0 else Direction.WEST
    else:
        return Direction.SOUTH if velocity.y > 0 else Direction.NORTH
```

## 7. 이동 시스템 (Navigation 통합)

### 7.1. NavigationAgent2D 활용

**설정:**
```gdscript
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
    nav_agent.path_desired_distance = 4.0
    nav_agent.target_desired_distance = 4.0
    nav_agent.set_navigation_layers(1)  # Layer 0 (Ground)
```

**이동 명령 (그리드 좌표):**
```gdscript
func move_to_grid(target_grid: Vector2i):
    var target_world = GridSystem.grid_to_world(target_grid)
    nav_agent.target_position = target_world
    current_state = State.MOVING
```

**물리 이동 (`_physics_process`):**
```gdscript
func _physics_process(delta):
    if current_state != State.MOVING:
        return

    if nav_agent.is_navigation_finished():
        current_state = State.IDLE
        velocity = Vector2.ZERO
        play_animation("idle", current_direction)
        return

    var next_pos = nav_agent.get_next_path_position()
    var direction_vec = (next_pos - global_position).normalized()

    velocity = direction_vec * move_speed
    move_and_slide()

    # 애니메이션 방향 업데이트
    current_direction = get_direction_from_velocity(velocity)
    play_animation("walk", current_direction)
```

### 7.2. 입력 처리 (InputManager 통합)

**마우스 클릭 이동:**
```gdscript
# InputManager에서 처리
func _on_ground_clicked(world_pos: Vector2):
    var grid_pos = GridSystem.world_to_grid(world_pos)

    # 선택된 유닛에게 이동 명령
    if selected_unit:
        selected_unit.move_to_grid(grid_pos)
```

**참고:** `input_system_design.md` 참조

### 7.3. 장애물 회피

**NavigationObstacle2D와 연동:**
- 건물에 `NavigationObstacle2D` 설정
- `NavigationAgent2D`가 자동으로 회피 경로 계산
- 수동 충돌 체크 불필요

**참고:** `navigation_system_design.md` 참조

## 8. 상태 시스템

### 8.1. 캐릭터 상태 정의

```gdscript
enum State {
    IDLE,        # 대기 중
    MOVING,      # 이동 중
    INTERACTING  # 상호작용 중 (미래)
}
```

### 8.2. 상태 전환

```
IDLE → MOVING: move_to_grid() 호출 시
MOVING → IDLE: 목적지 도착 시
IDLE → INTERACTING: 상호작용 시작 시 (미래)
INTERACTING → IDLE: 상호작용 종료 시 (미래)
```

### 8.3. 애니메이션 연동

**상태별 애니메이션:**
- `IDLE` → `idle_{direction}` 재생
- `MOVING` → `walk_{direction}` 재생
- `INTERACTING` → `interact_{direction}` 재생 (미래)

## 9. SOLID 원칙 적용

### 9.1. Single Responsibility (단일 책임)

**분리:**
- `UnitEntity`: 캐릭터 상태, 이동, 애니메이션 관리
- `GridSystem`: 좌표 변환만 담당
- `NavigationAgent2D`: 경로 찾기만 담당
- `AnimatedSprite2D`: 애니메이션 재생만 담당

### 9.2. Dependency Inversion (의존성 역전)

**❌ 잘못된 예:**
```gdscript
var ground_layer: TileMapLayer  # 저수준 직접 의존
func move_to(target):
    var world_pos = ground_layer.map_to_local(target)  # ❌
```

**✅ 올바른 예:**
```gdscript
# TileMapLayer 참조 없음!
func move_to_grid(target_grid: Vector2i):
    var world_pos = GridSystem.grid_to_world(target_grid)  # ✅
    nav_agent.target_position = world_pos
```

### 9.3. Open/Closed (개방-폐쇄)

**확장 가능한 구조:**
- 새로운 캐릭터 타입 추가 시 기존 코드 수정 불필요
- `BaseEntity` 상속으로 확장
- 애니메이션 추가 시 SpriteFrames 리소스만 수정

## 10. 파일 구조

```
isometric-strategy-framework/
├── scenes/
│   ├── entity/
│   │   ├── unit_entity.tscn           # 플레이어 유닛 씬
│   │   └── npc_entity.tscn            # NPC 씬 (미래)
│   └── maps/
│       └── test_map.tscn
│
├── scripts/
│   ├── entity/
│   │   ├── base_entity.gd             # 공통 엔티티 (미래)
│   │   ├── unit_entity.gd             # 플레이어 유닛 로직
│   │   └── npc_entity.gd              # NPC 로직 (미래)
│   ├── managers/
│   │   └── unit_manager.gd            # 유닛 생성/관리 (미래)
│   └── config/
│       └── game_config.gd             # UNIT_SIZE 설정
│
├── assets/
│   └── sprites/
│       └── entity/
│           └── unit/
│               ├── walk-complete-sprite-sheet.png
│               ├── idle-full-sprite-sheet.png
│               └── unit_animations.tres  # SpriteFrames 리소스
│
└── docs/
    ├── design/
    │   └── character_system_design.md  # 이 문서
    └── sprints/
        └── sprint_XX_character_system.md  # 개발 계획
```

## 11. 성능 고려사항

### 11.1. AnimatedSprite2D 최적화

- ✅ Godot 내장 최적화 활용
- ✅ 필요한 프레임만 로드 (스프라이트 시트 분할)
- ✅ 화면 밖 캐릭터는 애니메이션 일시정지 (미래)

### 11.2. NavigationAgent2D 최적화

- ✅ `path_desired_distance` 적절히 설정 (경로 갱신 빈도 조절)
- ✅ 대량 유닛 시 경로 계산 프레임 분산 (미래)

### 11.3. Y-Sort 최적화

- ✅ 이동 중인 캐릭터만 Y좌표 변경
- ✅ 정지 상태는 Y-Sort 비용 낮음

## 12. 테스트 시나리오

### 12.1. 기본 이동 테스트

**test_map.tscn에서:**
1. 유닛 1개 배치
2. 마우스 클릭으로 이동 명령
3. Navigation 경로 따라 이동 확인
4. 애니메이션 방향 전환 확인

### 12.2. 장애물 회피 테스트

1. 건물 배치
2. 건물 너머로 이동 명령
3. 자동 우회 경로 생성 확인

### 12.3. 다중 유닛 테스트 (미래)

1. 유닛 10개 배치
2. 동시 이동 명령
3. 충돌 회피 확인
4. 성능 측정

## 13. 구현 우선순위

**자세한 일정은 `docs/sprints/sprint_XX_character_system.md` 참조**

### Phase 1: 기본 유닛 구현
- [ ] GameConfig에 UNIT_SIZE 추가
- [ ] unit_entity.tscn 씬 생성 (CharacterBody2D + AnimatedSprite2D)
- [ ] unit_entity.gd 기본 로직 (상태, 이동)
- [ ] 8방향 애니메이션 리소스 설정
- [ ] 테스트 맵에 유닛 배치 및 수동 이동 테스트

### Phase 2: Navigation 통합
- [ ] NavigationAgent2D 설정
- [ ] 그리드 좌표 기반 이동 구현
- [ ] 장애물 회피 테스트
- [ ] InputManager 연동 (마우스 클릭 이동)

### Phase 3: NPC 시스템 (미래)
- [ ] npc_entity.tscn 씬 생성
- [ ] 자율 행동 AI 구현
- [ ] 행동 패턴 정의 (직원, 고객 등)
- [ ] UnitManager 추가 (다중 유닛 관리)

### Phase 4: 확장 기능 (미래)
- [ ] BaseEntity 추상화
- [ ] 상호작용 시스템 (Area2D)
- [ ] 유닛 선택 UI
- [ ] 다중 선택 및 그룹 이동

## 14. 참고 문서

- `tile_system_design.md`: 타일 시스템, UI/Logic 분리 원칙
- `navigation_system_design.md`: Navigation Layers, NavigationAgent2D
- `input_system_design.md`: 입력 처리 시스템
- `code_convention.md`: 코드 컨벤션, SOLID 원칙
- `godot_scene_instance_pattern.md`: 씬 인스턴스 패턴

## 15. 주의사항

### UI/Logic 분리 체크리스트

- [ ] 캐릭터 이동 로직이 픽셀 단위를 직접 사용하는가? → ❌
- [ ] 그리드 좌표로 이동 명령을 받는가? → ✅
- [ ] 크기 설정이 GameConfig에 있는가? → ✅
- [ ] 좌표 변환을 GridSystem에서만 하는가? → ✅
- [ ] TileMapLayer를 직접 참조하는가? → ❌

### Godot 내장 기능 활용 체크리스트

- [ ] AnimatedSprite2D 사용? → ✅
- [ ] NavigationAgent2D 사용? → ✅
- [ ] CharacterBody2D 사용? → ✅
- [ ] 수동 A* 구현? → ❌
- [ ] 수동 프레임 전환? → ❌

### SOLID 원칙 체크리스트

- [ ] 각 클래스가 하나의 책임만 가지는가?
- [ ] 저수준(TileMapLayer) 직접 의존하지 않는가?
- [ ] 추상화 레이어(GridSystem) 사용하는가?
