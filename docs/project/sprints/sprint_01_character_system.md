# Sprint 01: 캐릭터 시스템 기본 구현

**스프린트 기간:** TBD
**담당:** TBD
**관련 설계 문서:** `docs/design/character_system_design.md`

## 1. 스프린트 목표

**핵심 목표:**
플레이어가 제어 가능한 기본 유닛(Unit) 구현 - 이동, 애니메이션, Navigation 통합

**완료 기준:**
- ✅ 유닛이 마우스 클릭으로 이동 가능
- ✅ 8방향 애니메이션이 이동 방향에 따라 재생
- ✅ Navigation 시스템으로 장애물 자동 회피
- ✅ 그리드 좌표 기반 로직 (UI/Logic 분리 원칙 준수)

## 2. 작업 범위

### Phase 1: 기본 구조 설정 (필수)

#### 1.1. GameConfig 설정 추가
- [x] `scripts/config/game_config.gd`에 `UNIT_SIZE` 상수 추가
  ```gdscript
  ## 유닛 텍스처 크기 (픽셀) - 타일의 70%
  const UNIT_SIZE: Vector2i = Vector2i(22, 22)
  ```

#### 1.2. 유닛 스크립트 작성
- [x] `scripts/entity/unit_entity.gd` 생성
  - CharacterBody2D 상속
  - 상태 시스템 구현 (IDLE, MOVING)
  - 그리드 좌표 기반 이동 로직
  - 8방향 애니메이션 재생 로직
  - NavigationAgent2D 통합

**파일 위치:** `scripts/entity/unit_entity.gd`

**핵심 메서드:**
```gdscript
func move_to_grid(target_grid: Vector2i)  # 그리드 좌표로 이동
func _physics_process(delta)              # 물리 이동 처리
func get_direction_from_velocity(velocity: Vector2) -> int  # 방향 계산
func play_animation(anim_type: String, direction: int)      # 애니메이션 재생
```

#### 1.3. 유닛 씬 생성 (Godot 에디터)
- [x] `scenes/entity/unit_entity.tscn` 씬 생성
  - 루트 노드: CharacterBody2D
  - 자식 노드:
    - AnimatedSprite2D (애니메이션)
    - NavigationAgent2D (경로 찾기)
    - CollisionShape2D (물리 충돌, CircleShape2D 사용)
- [x] `unit_entity.gd` 스크립트 연결

**노드 구조:**
```
UnitEntity (CharacterBody2D) [스크립트: unit_entity.gd]
├── AnimatedSprite2D
├── NavigationAgent2D
└── CollisionShape2D (Shape: CircleShape2D, radius: 10)
```

**Godot 에디터 작업:**
1. Scene → New Scene
2. Other Node → CharacterBody2D 선택
3. 이름: UnitEntity
4. 자식 노드 추가 (위 구조대로)
5. Inspector에서 스크립트 연결: `scripts/entity/unit_entity.gd`
6. Scene → Save Scene As: `scenes/entity/unit_entity.tscn`

### Phase 2: 애니메이션 설정 (필수)

#### 2.1. 스프라이트 시트 준비
- [x] `walk-complete-sprite-sheet.png` 확인
  - 프레임 크기 측정
  - 8방향 레이아웃 확인 (행/열 구조)
- [x] `idle-full-sprite-sheet.png` 확인
  - 프레임 크기 측정
  - 8방향 레이아웃 확인

**작업 방법:**
- Godot 에디터에서 이미지 Import 설정 확인
- 필요 시 외부 에디터에서 프레임 크기 조정 (22x22 픽셀로)

#### 2.2. SpriteFrames 리소스 생성
- [x] `assets/sprites/entity/unit/unit_animations.tres` 생성
  - AnimatedSprite2D의 SpriteFrames 리소스
  - 16개 애니메이션 추가:
    - `idle_south`, `idle_south_east`, ..., `idle_south_west` (8개)
    - `walk_south`, `walk_south_east`, ..., `walk_south_west` (8개)

**Godot 에디터 작업:**
1. `unit_entity.tscn` 열기
2. AnimatedSprite2D 노드 선택
3. Inspector → SpriteFrames → New SpriteFrames
4. SpriteFrames 에디터 열기
5. 애니메이션 추가:
   - "default" 삭제
   - "Add Animation" → `idle_south` 생성
   - 스프라이트 시트에서 해당 프레임들 드래그 앤 드롭
   - FPS 설정 (예: 8fps)
   - 나머지 15개 애니메이션 반복
6. SpriteFrames → Save As: `assets/sprites/entity/unit/unit_animations.tres`

**애니메이션 이름 규칙:**
- 방향 순서: south(0), south_east(1), east(2), north_east(3), north(4), north_west(5), west(6), south_west(7)
- 상태: idle, walk

#### 2.3. 스프라이트 스케일 조정
- [ ] AnimatedSprite2D의 `scale` 속성 조정
  - 목표: 최종 렌더링 크기 22x22 픽셀
  - 계산: `scale = 22 / 원본_프레임_크기`
  - 예: 원본이 16x16이면 scale = 1.375

**Godot 에디터 작업:**
1. unit_entity.tscn에서 AnimatedSprite2D 선택
2. Inspector → Transform → Scale 조정
3. 또는 `unit_entity.gd`의 `_ready()`에서 코드로 설정:
   ```gdscript
   $AnimatedSprite2D.scale = Vector2(1.375, 1.375)
   ```

### Phase 3: Navigation 통합 (필수)

#### 3.1. NavigationAgent2D 설정
- [x] `unit_entity.tscn`에서 NavigationAgent2D 노드 설정
  - Path Desired Distance: 4.0
  - Target Desired Distance: 4.0
  - Navigation Layers: Layer 0 활성화 (Ground)

**Godot 에디터 작업:**
1. unit_entity.tscn에서 NavigationAgent2D 선택
2. Inspector 설정:
   - Pathfinding → Path Desired Distance: 4.0
   - Pathfinding → Target Desired Distance: 4.0
   - Avoidance → Avoidance Enabled: true (옵션)
   - Layers → Navigation Layers → Layer 1 (Ground) 체크

#### 3.2. 이동 로직 구현
- [x] `unit_entity.gd`에서 NavigationAgent2D 사용
  - `move_to_grid()` 메서드 구현
  - `_physics_process()`에서 경로 추종
  - 도착 시 상태 전환 (MOVING → IDLE)

**구현 예시:**
```gdscript
func move_to_grid(target_grid: Vector2i):
    var target_world = GridSystem.grid_to_world(target_grid)
    nav_agent.target_position = target_world
    current_state = State.MOVING

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

    current_direction = get_direction_from_velocity(velocity)
    play_animation("walk", current_direction)
```

### Phase 4: 테스트 및 통합 (필수)

#### 4.1. 테스트 맵 설정
- [x] `scenes/maps/test_map.tscn`에 유닛 배치
  - Entities 컨테이너에 unit_entity.tscn 인스턴스 추가
  - 초기 위치 설정 (그리드 좌표)

**Godot 에디터 작업:**
1. test_map.tscn 열기
2. World/Entities 노드 선택
3. 우클릭 → Instantiate Child Scene
4. `scenes/entity/unit_entity.tscn` 선택
5. 이름: TestUnit
6. Inspector → Position 설정 (또는 스크립트에서 설정)

#### 4.2. InputManager 연동
- [x] 마우스 클릭 시 유닛 이동 명령
  - InputManager에서 클릭 이벤트 처리
  - 클릭한 그리드 좌표를 유닛에게 전달

**test_map.gd 수정 예시:**
```gdscript
extends Node2D

@onready var test_unit = $World/Entities/TestUnit

func _ready():
    # InputManager 시그널 연결 (이미 구현된 경우)
    pass

func _input(event):
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var world_pos = get_global_mouse_position()
        var grid_pos = GridSystem.world_to_grid(world_pos)

        # 유닛에게 이동 명령
        test_unit.move_to_grid(grid_pos)
```

#### 4.3. 기본 테스트 시나리오
- [x] 테스트 1: 빈 타일 클릭 → 유닛 이동 확인
- [x] 테스트 2: 건물 너머 클릭 → 자동 우회 확인
- [x] 테스트 3: 이동 중 애니메이션 방향 확인
- [x] 테스트 4: 도착 후 idle 애니메이션 확인

**테스트 체크리스트:**
- [x] 유닛이 클릭한 위치로 이동하는가?
- [x] 이동 중 walk 애니메이션이 재생되는가?
- [x] 이동 방향에 따라 애니메이션 방향이 바뀌는가?
- [x] 도착 후 idle 애니메이션으로 전환되는가?
- [x] 건물을 자동으로 우회하는가?
- [x] 그리드 좌표 기반 로직이 정상 작동하는가?

### Phase 5: 문서화 및 정리 (옵션)

#### 5.1. 코드 주석 추가
- [ ] `unit_entity.gd`에 주석 추가
  - 각 메서드의 목적 설명
  - 복잡한 로직 설명 (방향 계산 등)

#### 5.2. 스프린트 회고 작성
- [ ] `docs/sprints/sprint_01_retrospective.md` 작성
  - 완료된 작업
  - 발생한 문제 및 해결 방법
  - 다음 스프린트 개선 사항

## 3. 체크리스트 요약

### 필수 작업

- [x] **설정**
  - [x] GameConfig에 UNIT_SIZE 추가
  - [x] scripts/entity/unit_entity.gd 작성
  - [x] scenes/entity/unit_entity.tscn 생성 (Godot 에디터)

- [x] **애니메이션**
  - [x] 스프라이트 시트 확인 및 준비
  - [x] SpriteFrames 리소스 생성 (16개 애니메이션)
  - [ ] 스프라이트 스케일 조정 (22x22 픽셀) - 스킵됨 (투명 영역으로 적절한 크기)

- [x] **Navigation**
  - [x] NavigationAgent2D 설정
  - [x] 이동 로직 구현 (move_to_grid, _physics_process)

- [x] **테스트**
  - [x] test_map.tscn에 유닛 배치
  - [x] InputManager 연동 (마우스 클릭 이동)
  - [x] 기본 테스트 시나리오 실행

### 옵션 작업

- [ ] 코드 주석 추가
- [ ] 스프린트 회고 작성
- [ ] 성능 측정 (다중 유닛 시)

## 4. 완료 조건 (Definition of Done)

- ✅ 유닛이 마우스 클릭으로 이동 가능
- ✅ 8방향 애니메이션 정상 재생
- ✅ Navigation 경로 찾기 동작
- ✅ 건물 자동 우회
- ✅ 그리드 좌표 기반 로직 (UI/Logic 분리 준수)
- ✅ SOLID 원칙 준수 (의존성 역전 - GridSystem 사용)
- ✅ 코드 리뷰 완료
- ✅ 테스트 시나리오 통과

## 5. 블로커 및 의존성

### 의존성
- ✅ Navigation 시스템 구현 완료 (`navigation_system_design.md` 참조)
- ✅ GridSystem 구현 완료 (`tile_system_design.md` 참조)
- ✅ InputManager 구현 완료 및 통합 검증 완료 (`input_system_design.md` 참조)

### 잠재적 블로커
- 스프라이트 시트 프레임 크기가 예상과 다를 경우
  → 해결: 외부 에디터에서 크기 조정 또는 scale 조정
- Navigation Layers 설정 누락
  → 해결: TileMapLayer에 Navigation 활성화 확인
- 애니메이션 방향이 예상과 다를 경우
  → 해결: 방향 계산 로직 디버깅

## 6. 다음 스프린트 (Sprint 02)

**예정 작업:**
- [ ] NPC 시스템 기본 구현 (자율 행동)
- [ ] UnitManager 추가 (다중 유닛 관리)
- [ ] 유닛 선택 UI
- [ ] BaseEntity 추상화

**참고 문서:**
- `docs/design/character_system_design.md` - Phase 3: NPC 시스템

## 7. 참고 자료

### 설계 문서
- `docs/design/character_system_design.md` - 캐릭터 시스템 전체 설계
- `docs/design/tile_system_design.md` - UI/Logic 분리 원칙
- `docs/design/navigation_system_design.md` - Navigation 시스템
- `docs/design/input_system_design.md` - 입력 처리

### 코드 컨벤션
- `docs/code_convention.md` - SOLID 원칙, 네이밍 규칙

### Godot 문서
- [AnimatedSprite2D](https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html)
- [NavigationAgent2D](https://docs.godotengine.org/en/stable/classes/class_navigationagent2d.html)
- [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)

## 8. 노트

### UI/Logic 분리 체크포인트

**작업 중 확인 사항:**
- [x] TileMapLayer를 직접 참조하지 않는가?
- [x] 모든 이동 명령이 그리드 좌표(`Vector2i`)를 사용하는가?
- [x] 좌표 변환은 GridSystem을 통해서만 하는가?
- [x] 크기 설정은 GameConfig에서만 가져오는가?

### Godot 내장 기능 활용 체크포인트

**작업 중 확인 사항:**
- [x] AnimatedSprite2D를 사용하는가? (수동 프레임 전환 금지)
- [x] NavigationAgent2D를 사용하는가? (A* 직접 구현 금지)
- [x] CharacterBody2D의 move_and_slide()를 사용하는가?

### 스프린트 진행 상황 추적

**일일 업데이트:**
- 작업 시작 전: 체크리스트 확인
- 작업 완료 시: 체크박스 체크
- 블로커 발생 시: "5. 블로커 및 의존성" 섹션 업데이트
