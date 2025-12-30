# 내비게이션 시스템 설계 (Godot 4.x)

## 🎯 목표 (Objective)
아이소메트릭 그리드 상에서 RTS 스타일의 유닛 이동을 위한 견고한 내비게이션 시스템을 구현합니다.
유닛은 다음 기능을 수행할 수 있어야 합니다:
1.  장애물(건물)을 우회하여 경로 찾기.
2.  목표 지점을 향해 부드럽게 이동.
3.  유닛 간 충돌 회피 (선택 사항이지만, `NavigationAgent2D`가 지원함).

## 🛠 접근 방식: Godot NavigationServer2D

AStarGrid2D 대신 Godot 내장 **NavigationServer2D**를 사용합니다.
*   **이유**: 부드러운 경로 탐색, 로컬 회피(RVO)를 지원하며, Godot 4.3+의 `TileMapLayer`와 기본적으로 통합됩니다.
*   **구성 요소**:
	*   `TileSet Navigation`: 타일 자체에 내비게이션 폴리곤을 베이크(Bake)합니다.
	*   `NavigationAgent2D`: 유닛에 부착되어 경로 탐색 쿼리를 처리합니다.
	*   `CharacterBody2D`: 유닛의 물리 및 이동 실행을 담당합니다.

---

## 🏗 시스템 아키텍처 (SOLID 원칙 적용)

### 의존성 구조

```
[고수준 - 게임 로직]
  SelectionManager (Autoload)
	└── 책임: 유닛 선택 상태 관리, 마우스 입력 처리

  UnitManager (Autoload)
	└── 책임: 유닛 인스턴스 생성/제거, 이동 명령 전달

  BuildingManager (기존)
	└── 책임: 건물 배치 시 Navigation 업데이트

		 ↓ (추상화 계층 통해 접근)

[중간 레이어 - 추상화]
  GridSystem (Autoload)
	└── 책임: 좌표 변환, 그리드 유효성 검증

  GameConfig
	└── 책임: 설정값 제공

		 ↓

[저수준 - Godot 내장 / 씬]
  UnitEntity (씬)
	├── CharacterBody2D
	├── NavigationAgent2D
	├── Sprite2D
	└── CollisionShape2D

  TileMapLayer (Navigation)
	└── NavigationServer2D와 자동 연동
```

### SOLID 원칙 적용

#### 1. Single Responsibility (단일 책임)
- **UnitEntity**: 개별 유닛의 이동/애니메이션만 담당
- **UnitManager**: 유닛 목록 관리 및 명령 전달만 담당
- **SelectionManager**: 선택 상태 관리만 담당

#### 2. Dependency Inversion (의존성 역전) ⭐ 핵심!
```gdscript
# ❌ 잘못된 예: UnitManager가 NavigationAgent2D 직접 참조
class_name UnitManager
var units: Array[CharacterBody2D]  # ❌ 저수준 타입 직접 의존

func move_units(target):
	for unit in units:
		unit.get_node("NavigationAgent2D").target_position = target  # ❌

# ✅ 올바른 예: UnitEntity의 추상화된 인터페이스 사용
class_name UnitManager
var units: Array[UnitEntity]  # ✅ 고수준 타입

func move_units(target):
	for unit in units:
		unit.move_to(target)  # ✅ public 메서드만 호출
```

#### 3. 좌표 변환 규칙
- **모든 좌표 변환은 GridSystem을 통해서만 수행**
- 매니저는 `TileMapLayer`를 직접 참조하지 않음
- 예외: UnitEntity 내부에서는 NavigationAgent2D 직접 사용 (캡슐화)

---

## 📅 구현 계획 (Implementation Plan)

### Step 1: TileSet 내비게이션 설정
**목표**: 맵에서 "이동 가능한 영역" 정의.

1.  **TileSet 리소스 설정**:
	*   `resources/tiles/ground_tileset.tres` 열기.
	*   **Navigation Layer** 추가 (Layer 0).
2.  **내비게이션 폴리곤 그리기**:
	*   TileSet 에디터에서 "Ground" 타일 선택.
	*   타일의 다이아몬드 형태 전체를 덮는 **Navigation Polygon** 그리기.
	*   *참고*: 인접한 타일과 폴리곤이 완벽하게 맞물려야 끊김 없는 이동이 가능합니다.

### Step 2: GridSystem 확장 (좌표 검증)
**목표**: Navigation 가능 여부를 검증하는 기능 추가.

1.  **GridSystem에 메서드 추가** (`scripts/map/grid_system.gd`):
	```gdscript
	# 해당 그리드 위치가 Navigation 가능한지 검증
	static func is_valid_navigation_position(grid_pos: Vector2i) -> bool:
		# 맵 범위 체크
		if not is_valid_position(grid_pos):
			return false

		# NavigationServer2D를 통해 해당 위치에 Navigation 메쉬가 있는지 확인
		# (구현 세부사항은 Step 2 구현 시 추가)
		return true

	# 장애물로 마킹 (건물 배치 시 호출)
	static func mark_as_obstacle(grid_pos: Vector2i, size: Vector2i) -> void:
		# NavigationServer2D에 장애물 등록
		# 또는 내부 장애물 목록에 추가
		pass
	```

2.  **BuildingManager와 통합 준비**:
	*   건물 배치 시 `GridSystem.mark_as_obstacle()` 호출 예정
	*   이를 통해 DIP 원칙 준수 (BuildingManager는 TileMapLayer 직접 참조 안 함)

### Step 3: 장애물 (건물) 처리
**목표**: 유닛이 건물을 통과하지 못하게 방지.

**구현 방식**: NavigationRegion2D가 Static Colliders를 감지하여 장애물을 자동으로 제외한 Navigation Mesh를 생성합니다.

#### 1. 씬 구조

```
World (Node2D)
└─ NavigationRegion2D
   ├─ GroundTileMapLayer (navigation_enabled = false ⚠️ 중요!)
   ├─ StructuresTileMapLayer
   └─ Entities (Node2D)
      ├─ BuildingEntity (StaticBody2D, collision_layer = 4)
      ├─ BuildingEntity (StaticBody2D, collision_layer = 4)
      └─ UnitEntity (CharacterBody2D)
```

**핵심 포인트**:
- ✅ GroundTileMapLayer는 NavigationRegion2D의 **자식 노드**
- ✅ TileSet에 Navigation Polygon은 **반드시 그려야 함** (이동 가능 영역 정의)
- ⚠️ **하지만 `navigation_enabled = false`로 설정!** (NavigationRegion2D와 충돌 방지)

#### 2. TileMapLayer 설정

**GroundTileMapLayer (씬 또는 에디터)**:
```gdscript
# ground_tilemaplayer.tscn 또는 Inspector에서 설정
navigation_enabled = false  # ⚠️ 필수! NavigationRegion2D와 충돌 방지
```

**TileSet 설정** (`ground_tileset.tres`):
- Navigation Layer 0에 각 타일의 다이아몬드 형태 Polygon 그리기
- 이 Polygon들이 NavigationRegion2D의 **기본 이동 가능 영역** 정의

#### 3. NavigationRegion2D 설정

**NavigationPolygon 리소스 설정** (Inspector 또는 에디터에서 Bake):

```
[NavigationPolygon 속성]
parsed_geometry_type = STATIC_COLLIDERS  # StaticBody2D만 감지
parsed_collision_mask = 4                # Layer 3 감지 (2^3 = 4)
source_geometry_mode = GROUPS_WITH_FALLBACK  # 그룹 기반 감지
source_geometry_group_name = navigation_obstacle  # (선택사항)
agent_radius = 8.0  # 유닛 반경에 맞춰 조정
```

**중요한 설정 해설**:

| 설정 | 값 | 설명 |
|------|-----|------|
| `parsed_geometry_type` | `STATIC_COLLIDERS` | StaticBody2D의 충돌 형태만 장애물로 인식 |
| `parsed_collision_mask` | `4` (Layer 3) | **건물이 있는 Physics Layer를 정확히 지정!**<br>Layer 3 = 2^3 = 4<br>Layer 5 = 2^5 = 32 |
| `source_geometry_mode` | `GROUPS_WITH_FALLBACK` | 그룹 이름으로 필터링 (옵션) |
| `agent_radius` | `8.0` | 장애물 주변 여백 (유닛이 벽에 딱 붙지 않음) |

**⚠️ 주의사항**:
- `parsed_collision_mask`는 **비트 마스크** 값입니다!
  - Layer 1 = 1 (2^0)
  - Layer 2 = 2 (2^1)
  - Layer 3 = 4 (2^2)
  - Layer 4 = 8 (2^3)
  - 여러 레이어 감지: 4 | 8 = 12 (Layer 3 + Layer 4)

#### 4. BuildingEntity 설정

**씬 구조** (`building_entity.tscn`):
```
BuildingEntity (Node2D)
├─ Area2D (클릭 감지용)
│  └─ CollisionPolygon2D (collision_layer = 4)
├─ StaticBody2D (Navigation 장애물용) ⭐
│  └─ CollisionPolygon2D (collision_layer = 4)  # Layer 3
└─ Sprite2D (비주얼)
```

**StaticBody2D 설정**:
- `collision_layer = 4` (Layer 3) - NavigationRegion2D가 감지할 레이어
- `collision_mask = 0` (아무것도 감지하지 않음)
- CollisionPolygon2D는 건물의 바닥 면적(footprint)에 맞춰 설정

**스크립트** (`building_entity.gd`):
```gdscript
func _ready() -> void:
	# navigation_obstacle 그룹 등록 (선택사항)
	add_to_group("navigation_obstacle")
```

#### 5. 동적 건물 추가/삭제 시 자동 베이킹

**BuildingManager 수정** (`building_manager.gd`):

```gdscript
# NavigationRegion2D 참조 (test_map.gd에서 전달)
var nav_region: NavigationRegion2D = null

func initialize(parent_node: Node2D, navigation_region: NavigationRegion2D) -> void:
	buildings_parent = parent_node
	nav_region = navigation_region

func create_building(grid_pos: Vector2i) -> Node2D:
	# ... 건물 생성 로직 ...

	# 건물 추가 후 Navigation 자동 베이킹
	if nav_region:
		await get_tree().physics_frame  # StaticBody2D 준비 대기
		nav_region.bake_navigation_polygon()
		print("[BuildingManager] Navigation 자동 베이킹 완료")

	return building

func remove_building(grid_pos: Vector2i) -> void:
	# ... 건물 제거 로직 ...

	# 건물 제거 후 Navigation 자동 베이킹
	if nav_region:
		await get_tree().physics_frame
		nav_region.bake_navigation_polygon()
		print("[BuildingManager] Navigation 자동 베이킹 완료")
```

#### 6. 장점 및 단점

**✅ 장점**:
- **간단한 동적 관리**: 건물 추가/삭제 시 `bake_navigation_polygon()` 한 줄로 끝
- **건물 크기 무관**: 1x1, 2x2, 3x3 등 어떤 크기든 자동 처리
- **에디터 미리보기**: Godot 에디터에서 Bake 버튼으로 결과 확인 가능
- **Godot 내장 기능 100% 활용**: 추가 로직 최소화

**⚠️ 주의사항**:
- **TileMapLayer Navigation 충돌**: `navigation_enabled = false` 필수!
- **Physics Layer 정확히 지정**: `parsed_collision_mask` 잘못 설정 시 장애물 감지 안 됨
- **베이킹 비용**: 건물이 매우 많아지면 베이킹 시간 증가 (일반적으로는 문제 없음)

**❌ 단점**:
- 실시간 베이킹이므로 건물이 100개 이상일 때 성능 저하 가능
  - **해결책**: 배치 모드로 여러 건물을 한 번에 배치 후 마지막에 한 번만 베이킹

#### 7. 트러블슈팅

**문제 1**: 에디터에서 베이킹은 성공하는데 게임 실행 시 깨짐
- **원인**: TileMapLayer의 `navigation_enabled = true` 상태
- **해결**: `ground_layer.navigation_enabled = false` 설정

**문제 2**: 건물이 감지되지 않음 (Polygon 0개)
- **원인**: `parsed_collision_mask`가 건물의 Physics Layer와 불일치
- **해결**:
  - BuildingEntity의 `collision_layer` 확인 (예: Layer 3)
  - NavigationRegion2D의 `parsed_collision_mask = 4` (2^3) 설정

**문제 3**: 유닛이 건물을 통과함
- **원인 1**: NavigationRegion2D가 베이킹되지 않음
  - **해결**: 게임 실행 후 또는 건물 배치 후 `bake_navigation_polygon()` 호출
- **원인 2**: 베이킹은 되었지만 유닛이 Navigation을 따르지 않음
  - **해결**: UnitEntity의 NavigationAgent2D 설정 확인

**문제 4**: 건물을 배치했는데 Navigation이 업데이트 안 됨
- **원인**: 자동 베이킹 로직이 없음
- **해결**: BuildingManager에 위의 5번 코드 추가

---

### Step 4: 유닛 엔티티 생성
**목표**: 기본 이동이 가능한 유닛 생성.

1.  **씬 생성**: `scenes/entity/unit_entity.tscn`
2.  **노드 구조**:
	```
	UnitEntity (CharacterBody2D)
	├── NavigationAgent2D
	├── Sprite2D (유닛 비주얼)
	├── CollisionShape2D (CircleShape2D 권장)
	└── SelectionIndicator (Sprite2D, 초기 비활성)
	```

3.  **스크립트**: `scripts/entity/unit_entity.gd`
	```gdscript
	class_name UnitEntity
	extends CharacterBody2D

	@export var speed: float = 100.0
	@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
	@onready var selection_indicator: Sprite2D = $SelectionIndicator

	var is_selected: bool = false:
		set(value):
			is_selected = value
			selection_indicator.visible = value

	func move_to(target_pos: Vector2) -> void:
		nav_agent.target_position = target_pos

	func _physics_process(delta: float) -> void:
		if nav_agent.is_navigation_finished():
			return

		var next_position = nav_agent.get_next_path_position()
		var direction = global_position.direction_to(next_position)
		velocity = direction * speed
		move_and_slide()
	```

4.  **NavigationAgent2D 설정** (Godot 에디터):
	*   `path_desired_distance`: 4.0
	*   `target_desired_distance`: 4.0
	*   `avoidance_enabled`: true (유닛 간 충돌 회피)
	*   `radius`: 16.0 (유닛 크기에 맞춰 조정)

### Step 5: 유닛 선택 시스템 (SelectionManager)
**목표**: 유닛을 선택하고 선택 상태를 관리.

1.  **Autoload 생성**: `scripts/managers/selection_manager.gd`
	```gdscript
	# scripts/managers/selection_manager.gd
	extends Node

	var selected_units: Array[UnitEntity] = []

	func select_unit(unit: UnitEntity, multi_select: bool = false) -> void:
		if not multi_select:
			deselect_all()

		if unit not in selected_units:
			selected_units.append(unit)
			unit.is_selected = true

	func deselect_all() -> void:
		for unit in selected_units:
			unit.is_selected = false
		selected_units.clear()

	func get_selected_units() -> Array[UnitEntity]:
		return selected_units
	```

2.  **프로젝트 설정에 Autoload 등록**:
	*   Project Settings → Autoload → Add
	*   Path: `res://scripts/managers/selection_manager.gd`
	*   Node Name: `SelectionManager`

3.  **유닛 클릭 처리** (UnitEntity에 추가):
	```gdscript
	# unit_entity.gd에 추가
	func _ready() -> void:
		# 클릭 영역 설정
		input_pickable = true
		input_event.connect(_on_input_event)

	func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var multi_select = Input.is_key_pressed(KEY_CTRL)
				SelectionManager.select_unit(self, multi_select)
	```

### Step 6: 입력 처리 (이동 명령)
**목표**: 우클릭으로 선택된 유닛 이동.

1.  **main.gd 업데이트**:
	```gdscript
	# scripts/main.gd
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				_handle_move_command(event.position)

	func _handle_move_command(screen_pos: Vector2) -> void:
		# 1. 화면 좌표 → 월드 좌표
		var mouse_world_pos = get_global_mouse_position()

		# 2. 월드 좌표 → 그리드 좌표
		var grid_pos = GridSystem.world_to_grid(mouse_world_pos)

		# 3. Navigation 가능 여부 검증
		if not GridSystem.is_valid_navigation_position(grid_pos):
			# TODO: 피드백 (소리, 이펙트 등)
			push_warning("Invalid navigation position: " + str(grid_pos))
			return

		# 4. 최종 목표는 월드 좌표로 전달
		var target_world = GridSystem.grid_to_world(grid_pos)

		# 5. 선택된 유닛들에게 이동 명령
		for unit in SelectionManager.get_selected_units():
			unit.move_to(target_world)
	```

2.  **주요 포인트**:
	*   ✅ GridSystem을 통한 좌표 변환 (DIP 원칙)
	*   ✅ 유효성 검증 후 이동 명령
	*   ✅ SelectionManager를 통한 유닛 접근

---

---

## ⚠️ 에러 처리 및 엣지 케이스

### 1. 도달 불가능한 위치
```gdscript
# unit_entity.gd에 추가
func move_to(target_pos: Vector2) -> void:
	nav_agent.target_position = target_pos

	# 경로 계산 후 도달 가능 여부 체크
	await get_tree().physics_frame
	if not nav_agent.is_target_reachable():
		push_warning("Target unreachable: " + str(target_pos))
		# TODO: 유저 피드백 (소리, 시각 효과)
```

### 2. 유닛이 갇힌 경우 (Stuck Detection)
```gdscript
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
const STUCK_THRESHOLD: float = 2.0  # 2초 동안 움직임 없으면 갇힌 것으로 판단

func _physics_process(delta: float) -> void:
	# ... 기존 이동 로직 ...

	# Stuck 감지
	if velocity.length() < 10.0:  # 거의 움직임이 없음
		stuck_timer += delta
		if stuck_timer > STUCK_THRESHOLD:
			# 경로 재계산 또는 포기
			nav_agent.target_position = nav_agent.target_position  # 강제 재계산
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
```

### 3. 건물 배치 시 유닛 충돌
```gdscript
# building_manager.gd
func can_place_building(grid_pos: Vector2i) -> bool:
	# 1. 기존 건물 체크
	if has_building_at(grid_pos):
		return false

	# 2. 유닛 충돌 체크 (UnitManager 통해)
	var world_pos = GridSystem.grid_to_world(grid_pos)
	if UnitManager.has_unit_at(world_pos):
		return false

	return true
```

### 4. 맵 경계 처리
```gdscript
# GridSystem에 추가
static func is_valid_navigation_position(grid_pos: Vector2i) -> bool:
	# 맵 범위 체크
	if grid_pos.x < 0 or grid_pos.y < 0:
		return false
	if grid_pos.x >= MAP_WIDTH or grid_pos.y >= MAP_HEIGHT:
		return false

	# ... Navigation 가능 여부 체크 ...
	return true
```

---

## 🚀 성능 최적화

### 1. 경로 재계산 최소화
```gdscript
# NavigationAgent2D 설정
nav_agent.path_desired_distance = 4.0  # 경로 재계산 빈도 감소
nav_agent.target_desired_distance = 4.0

# 목표가 크게 변하지 않으면 재계산 안 함
func move_to(target_pos: Vector2) -> void:
	if global_position.distance_to(target_pos) < 8.0:
		return  # 이미 목표에 근접
	nav_agent.target_position = target_pos
```

### 2. 다수 유닛 이동 시 프레임 분산
```gdscript
# unit_manager.gd
func move_units_to(target: Vector2) -> void:
	var units = SelectionManager.get_selected_units()

	# 프레임 분산: 유닛 수에 따라 지연 추가
	for i in units.size():
		var unit = units[i]
		if i % 5 == 0 and i > 0:
			await get_tree().physics_frame  # 5개마다 1프레임 대기
		unit.move_to(target)
```

### 3. Avoidance Layer 활용
```gdscript
# unit_entity.gd
func _ready() -> void:
	# NavigationAgent2D 설정
	nav_agent.avoidance_enabled = true
	nav_agent.avoidance_layers = 1  # Layer 0
	nav_agent.avoidance_mask = 1    # Layer 0만 회피
	nav_agent.radius = 16.0  # 유닛 반경
	nav_agent.max_speed = speed
```

### 4. Navigation Mesh 업데이트 최적화
```gdscript
# building_manager.gd
func create_building(grid_pos: Vector2i) -> void:
	# ... 건물 생성 ...

	# NavigationServer 업데이트 (배치로 처리)
	# 여러 건물을 한 번에 배치할 때는 마지막에 한 번만 호출
	if not is_batch_mode:
		await get_tree().physics_frame
		NavigationServer2D.map_force_update(get_world_2d().navigation_map)
```

---

## 🧪 테스트 시나리오

### Phase 1: 기본 이동
- [ ] **TC-1.1**: 유닛이 빈 공간으로 이동
  - 유닛 선택 → 우클릭 → 목표까지 이동 → 정지
- [ ] **TC-1.2**: 도착 후 정지 확인
  - `nav_agent.is_navigation_finished() == true` 확인
- [ ] **TC-1.3**: 이동 중 새로운 목표 지정
  - 이동 중 다른 곳 우클릭 → 즉시 경로 변경

### Phase 2: 장애물 회피
- [ ] **TC-2.1**: 건물 주변 우회
  - 건물 반대편 클릭 → 건물 피해서 이동
- [ ] **TC-2.2**: 복잡한 미로 통과
  - 여러 건물 사이를 지나는 경로
- [ ] **TC-2.3**: 건물 위 클릭 시 처리
  - 건물 위 우클릭 → 경고 또는 가장 가까운 유효 위치로 이동

### Phase 3: 엣지 케이스
- [ ] **TC-3.1**: 도달 불가능한 위치
  - 완전히 막힌 공간 클릭 → 경고 메시지
- [ ] **TC-3.2**: 맵 밖 클릭
  - 맵 경계 밖 클릭 → 무시 또는 경계로 이동
- [ ] **TC-3.3**: 유닛이 갇힌 경우
  - 건물 사이에 유닛 배치 → 자동 탈출 또는 경고

### Phase 4: 다중 유닛
- [ ] **TC-4.1**: 여러 유닛 동시 선택
  - Ctrl+클릭으로 다중 선택 → 모두 선택 표시
- [ ] **TC-4.2**: 다중 유닛 이동
  - 여러 유닛 선택 → 우클릭 → 모두 이동
- [ ] **TC-4.3**: 유닛 간 충돌 회피
  - 좁은 통로에 여러 유닛 → 서로 밀지 않고 통과

### Phase 5: 동적 환경
- [ ] **TC-5.1**: 이동 중 건물 배치
  - 유닛 이동 중 경로에 건물 배치 → 자동 경로 재계산
- [ ] **TC-5.2**: 건물 제거
  - 건물 제거 → Navigation 메쉬 복구 확인
- [ ] **TC-5.3**: 성능 테스트
  - 50개 유닛 동시 이동 → FPS 60 유지 확인

---

## 📝 상세 작업 (Sprint Backlog)

### Phase 1: 기반 구축 ✅ 완료
- [x] **Task 1.1**: `ground_tileset.tres`에 Navigation Layer 추가 및 폴리곤 그리기
- [x] **Task 1.2**: `GridSystem.is_valid_navigation_position()` 구현
- [x] **Task 1.3**: `GridSystem.mark_as_obstacle()` 구현

### Phase 2: 유닛 시스템
- [x] **Task 2.1**: `UnitEntity` 씬 생성 (CharacterBody2D + NavigationAgent2D)
- [x] **Task 2.2**: `unit_entity.gd` 기본 이동 로직 구현
- [x] **Task 2.3**: SelectionIndicator 비주얼 추가
- [x] **Task 2.4**: `test_map.tscn`에 테스트 유닛 배치

### Phase 3: 선택 시스템
- [ ] **Task 3.1**: `SelectionManager` Autoload 생성
- [ ] **Task 3.2**: 유닛 클릭 선택 구현
- [ ] **Task 3.3**: Ctrl+클릭 다중 선택 구현

### Phase 4: 이동 명령
- [ ] **Task 4.1**: `main.gd`에 우클릭 이동 구현
- [ ] **Task 4.2**: GridSystem 좌표 검증 통합
- [ ] **Task 4.3**: 에러 처리 (도달 불가능한 위치)

### Phase 5: 건물 통합
- [ ] **Task 5.1**: `BuildingEntity`에 NavigationObstacle2D 추가
- [ ] **Task 5.2**: `BuildingManager.create_building()` 수정 (장애물 등록)
- [ ] **Task 5.3**: 건물 주변 내비게이션 검증

### Phase 6: 최적화 및 테스트
- [ ] **Task 6.1**: Stuck Detection 구현
- [ ] **Task 6.2**: 다수 유닛 이동 최적화
- [ ] **Task 6.3**: 전체 테스트 시나리오 실행

## 🔍 기술 세부 사항 (Technical Details)

### 아이소메트릭 내비게이션 폴리곤
표준 아이소메트릭 타일(w: 64, h: 32)의 경우, 내비게이션 폴리곤은 다이아몬드 형태여야 합니다:
*   상: (0, -16)
*   우: (32, 0)
*   하: (0, 16)
*   좌: (-32, 0)
*(`game_config.gd`의 실제 타일 크기에 맞춰 조정)*

### 이동 로직 (보일러플레이트)
```gdscript
func _physics_process(delta):
	if nav_agent.is_navigation_finished():
		return

	var current_agent_position = global_position
	var next_path_position = nav_agent.get_next_path_position()
	var new_velocity = current_agent_position.direction_to(next_path_position) * speed
	
	velocity = new_velocity
	move_and_slide()
```
