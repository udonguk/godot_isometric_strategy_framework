# Resource 기반 시스템 전환 계획 (Migration Plan)

## 📌 개요

현재 프로젝트의 건설 시스템을 **Resource 기반 아키텍처**로 전환하는 상세 계획입니다.

### 왜 지금 전환하는가?

- ✅ **아직 초기 단계**: Phase 1만 완료되어 리팩토링 비용 낮음
- ✅ **설계 문서 완비**: Phase 2-4 구현 가이드 이미 작성됨
- ✅ **저장 시스템 준비**: 나중에 저장 기능 추가 시 추가 작업 최소화
- ✅ **SOLID 원칙 준수**: 좋은 아키텍처 유지

---

## 📊 현재 상태 분석 (As-Is)

### 1. 구현 완료된 부분

| 항목 | 파일 | 상태 |
|------|------|------|
| **UI 기본 구조** | `scenes/ui/construction_menu.tscn` | ✅ Phase 1 완료 |
| **UI 스크립트** | `scripts/ui/construction_menu.gd` | ✅ 로그만 출력 |
| **BuildingManager** | `scripts/managers/building_manager.gd` | ✅ 기본 기능 있음 |

### 2. 미구현된 부분

| 항목 | 상태 | 문제점 |
|------|------|--------|
| **EntityData 클래스** | ❌ 없음 | Resource 기반 시스템 없음 |
| **BuildingData 클래스** | ❌ 없음 | 데이터와 뷰 분리 안 됨 |
| **.tres Resource 파일** | ❌ 0개 | 건물 데이터 하드코딩 |
| **BuildingDatabase** | ❌ 없음 | 중앙 관리 시스템 없음 |
| **ConstructionManager** | ❌ 없음 | 건설 로직 없음 |

### 3. 현재 BuildingManager 구조 (문제점)

**파일**: `scripts/managers/building_manager.gd`

```gdscript
# 현재 구조 (문제점 있음)
var grid_buildings: Dictionary = {}  # ❌ { Vector2i: BuildingEntity } - Node 직접 참조!
```

**문제점:**
- ❌ **Node를 직접 저장** → 직렬화 불가능 (저장 시스템 추가 시 문제)
- ❌ **데이터와 뷰 미분리** → 건물 속성 정보 없음
- ❌ **Resource 사용 안 함** → 에디터에서 데이터 편집 불가

---

## 🎯 목표 상태 (To-Be)

### 1. Resource 기반 데이터 구조

```
scripts/resources/
├── entity_data.gd           # 베이스 클래스 (extends Resource)
├── building_data.gd         # 건물 데이터 클래스 (extends EntityData)
├── house_01.tres            # 주택 데이터 (Godot 에디터에서 편집)
├── farm_01.tres             # 농장 데이터
└── shop_01.tres             # 상점 데이터 (예정)

scripts/config/
└── building_database.gd     # 건물 목록 중앙 관리
```

### 2. 개선된 BuildingManager 구조

```gdscript
# 개선된 구조 (저장 가능!)
var building_data_grid: Dictionary = {}     # ✅ { Vector2i: BuildingData }
var building_nodes_grid: Dictionary = {}    # ✅ { Vector2i: BuildingEntity } - 비주얼만
```

**장점:**
- ✅ **BuildingData는 직렬화 가능** → 저장 시스템에서 바로 사용
- ✅ **데이터와 뷰 분리** → 테스트 용이
- ✅ **Resource 기반** → 에디터에서 편집 가능

### 3. ConstructionManager 로직

```
scripts/managers/
└── construction_manager.gd  # 건설 로직 (미리보기, 검증, 배치)
```

**기능:**
- 건물 선택 및 미리보기
- 건설 가능 여부 검증
- 클릭/드래그로 건물 배치
- 시그널 기반 UI 통신

---

## 📋 전환 계획 (Phase별)

### 전체 로드맵

```
Phase 2: Resource 시스템 구축 (30분)
    ↓
Phase 3: ConstructionManager 구현 (30분)
    ↓
Phase 4: UI 통합 (15분)
    ↓
(선택) BuildingManager 리팩토링 (30분)
```

**총 소요 시간**: 약 1.5~2시간

---

## 🗂️ Phase 2: Resource 시스템 구축

### 목표

- BuildingData Resource 클래스 작성
- .tres 파일 생성 (주택, 농장, 상점)
- BuildingDatabase 중앙 관리 시스템
- 테스트 함수로 동작 확인

### 의존성

- ✅ 없음 (완전 독립)

### 소요 시간

- ⏱️ 30분

---

### ✅ Todo 체크리스트

#### 2-1. 폴더 및 파일 생성
- [ ] `scripts/resources/` 폴더 생성
- [ ] `scripts/resources/entity_data.gd` 작성
- [ ] `scripts/resources/building_data.gd` 작성

#### 2-2. Resource 파일 생성
- [ ] `house_01.tres` 생성 (Godot 에디터)
- [ ] `farm_01.tres` 생성 (Godot 에디터)
- [ ] `shop_01.tres` 생성 (Godot 에디터)

#### 2-3. Database 시스템
- [ ] `scripts/config/building_database.gd` 작성

#### 2-4. 테스트
- [ ] 테스트 함수 작성 (`test_map.gd`)
- [ ] Resource 로드 확인
- [ ] 인스턴스 생성 확인

---

### 📝 상세 작업 항목

#### 2-1. EntityData.gd 작성

**파일 생성**: `scripts/resources/entity_data.gd`

**내용**:
```gdscript
# scripts/resources/entity_data.gd
class_name EntityData extends Resource

# 모든 엔티티 공통 속성
@export var entity_id: String = ""           # 고유 ID
@export var entity_name: String = ""         # 표시 이름
@export var description: String = ""         # 설명
@export var icon: Texture2D                  # UI 아이콘
@export var scene_to_spawn: PackedScene      # 실제 씬

func get_id() -> String:
    return entity_id

func get_display_name() -> String:
    return entity_name
```

**참고**: `docs/construction_system_implementation_guide.md` Line 315-331

---

#### 2-2. BuildingData.gd 작성

**파일 생성**: `scripts/resources/building_data.gd`

**내용**:
```gdscript
# scripts/resources/building_data.gd
class_name BuildingData extends EntityData

# 건물 전용 속성
@export var cost_wood: int = 0
@export var cost_stone: int = 0
@export var cost_gold: int = 100
@export var grid_size: Vector2i = Vector2i(1, 1)

# 카테고리
enum BuildingCategory {
    RESIDENTIAL,  # 주거
    PRODUCTION,   # 생산
    MILITARY,     # 군사
    DECORATION    # 장식
}
@export var category: BuildingCategory = BuildingCategory.RESIDENTIAL

# 헬퍼 함수
func get_total_cost() -> Dictionary:
    return {
        "wood": cost_wood,
        "stone": cost_stone,
        "gold": cost_gold
    }
```

**참고**: `docs/construction_system_implementation_guide.md` Line 343-373

---

#### 2-3. house_01.tres 생성 (Godot 에디터)

**방법**:

1. Godot 에디터 열기
2. FileSystem → `scripts/resources/` 우클릭
3. "Create New" → "Resource"
4. 타입 선택: "BuildingData" 검색 → 선택
5. 이름: `house_01.tres`
6. Create

**Inspector에서 데이터 입력**:

```
house_01.tres:
- entity_id: "house_01"
- entity_name: "주택"
- description: "주민이 거주하는 집입니다."
- icon: (일단 비워둠, 나중에 추가)
- scene_to_spawn: [scenes/entity/building_entity.tscn 드래그]
- cost_wood: 50
- cost_stone: 30
- cost_gold: 100
- grid_size: (1, 1)
- category: RESIDENTIAL
```

**참고**: `docs/construction_system_implementation_guide.md` Line 375-403

---

#### 2-4. farm_01.tres, shop_01.tres 생성

**같은 방법으로**:

```
farm_01.tres:
- entity_id: "farm_01"
- entity_name: "농장"
- description: "식량을 생산합니다."
- scene_to_spawn: [building_entity.tscn]
- cost_wood: 60
- cost_stone: 20
- cost_gold: 150
- grid_size: (1, 1)
- category: PRODUCTION

shop_01.tres:
- entity_id: "shop_01"
- entity_name: "상점"
- description: "물건을 판매합니다."
- scene_to_spawn: [building_entity.tscn]
- cost_wood: 40
- cost_stone: 40
- cost_gold: 200
- grid_size: (1, 1)
- category: PRODUCTION
```

---

#### 2-5. BuildingDatabase.gd 작성

**파일 생성**: `scripts/config/building_database.gd`

**내용**:
```gdscript
# scripts/config/building_database.gd
extends Node
class_name BuildingDatabase

# 모든 건물 데이터 배열
const BUILDINGS: Array[BuildingData] = [
    preload("res://scripts/resources/house_01.tres"),
    preload("res://scripts/resources/farm_01.tres"),
    preload("res://scripts/resources/shop_01.tres"),
]

# ID로 건물 찾기
static func get_building_by_id(id: String) -> BuildingData:
    for building in BUILDINGS:
        if building.entity_id == id:
            return building
    return null

# 카테고리별 건물 목록
static func get_buildings_by_category(category: BuildingData.BuildingCategory) -> Array[BuildingData]:
    var result: Array[BuildingData] = []
    for building in BUILDINGS:
        if building.category == category:
            result.append(building)
    return result

# 모든 건물 목록
static func get_all_buildings() -> Array[BuildingData]:
    return BUILDINGS.duplicate()
```

**참고**: `docs/construction_system_implementation_guide.md` Line 419-452

---

#### 2-6. 테스트 함수 작성

**파일 수정**: `scripts/maps/test_map.gd`

**기존 테스트 주석 처리하고 Phase 2 테스트 추가**:

```gdscript
# scripts/maps/test_map.gd
extends Node2D

func _ready():
    print("\n========================================")
    print("Phase 2: Resource 시스템 테스트 시작")
    print("========================================\n")

    test_resource_load()
    test_instance_creation()
    test_database()

# ⭐ 테스트 1: Resource 로드
func test_resource_load():
    print("=== 테스트 1: Resource 로드 ===")

    var house = load("res://scripts/resources/house_01.tres") as BuildingData
    print("건물 ID:", house.entity_id)
    print("건물 이름:", house.entity_name)
    print("건물 비용 (골드):", house.cost_gold)
    print("건물 크기:", house.grid_size)
    print("✅ Resource 로드 성공!\n")

# ⭐ 테스트 2: 인스턴스 생성
func test_instance_creation():
    print("=== 테스트 2: 인스턴스 생성 ===")

    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData

    if not house_data.scene_to_spawn:
        print("❌ scene_to_spawn이 null입니다!")
        return

    var building = house_data.scene_to_spawn.instantiate()
    building.position = Vector2(100, 100)
    add_child(building)

    print("✅ 건물 인스턴스 생성 성공!")
    print("위치:", building.position)
    print("화면에 건물이 나타나야 합니다.\n")

# ⭐ 테스트 3: Database
func test_database():
    print("=== 테스트 3: BuildingDatabase ===")

    var house = BuildingDatabase.get_building_by_id("house_01")
    print("Database에서 조회:", house.entity_name)

    var all_buildings = BuildingDatabase.get_all_buildings()
    print("전체 건물 수:", all_buildings.size())

    print("✅ Database 테스트 성공!\n")
```

**참고**: `docs/construction_system_implementation_guide.md` Line 454-510

---

### ✅ Phase 2 완료 조건

테스트 실행 (F5) 후 다음 확인:

- [ ] 콘솔에 "Resource 로드 성공!" 출력
- [ ] 콘솔에 "인스턴스 생성 성공!" 출력
- [ ] 콘솔에 "Database 테스트 성공!" 출력
- [ ] 화면에 건물 1개 나타남 (100, 100 위치)

**기대 출력**:
```
Phase 2: Resource 시스템 테스트 시작

=== 테스트 1: Resource 로드 ===
건물 ID: house_01
건물 이름: 주택
건물 비용 (골드): 100
건물 크기: (1, 1)
✅ Resource 로드 성공!

=== 테스트 2: 인스턴스 생성 ===
✅ 건물 인스턴스 생성 성공!
위치: (100, 100)
화면에 건물이 나타나야 합니다.

=== 테스트 3: BuildingDatabase ===
Database에서 조회: 주택
전체 건물 수: 3
✅ Database 테스트 성공!
```

---

## ⚙️ Phase 3: ConstructionManager 구현

### 목표

- ConstructionManager 로직 구현
- 건물 선택 및 미리보기 시스템
- 건설 가능 여부 검증
- 클릭으로 건물 배치 테스트

### 의존성

- ✅ Phase 2 (BuildingData 필요)

### 소요 시간

- ⏱️ 30분

---

### ✅ Todo 체크리스트

- [ ] `scripts/managers/construction_manager.gd` 생성
- [ ] 기본 구조 및 상태 관리 작성
- [ ] `select_building()` 함수 구현
- [ ] 미리보기 스프라이트 시스템 구현
- [ ] `can_build_at()` 검증 로직 구현
- [ ] `try_place_building()` 배치 로직 구현
- [ ] 입력 처리 (`_unhandled_input()`)
- [ ] test_map.tscn에 노드 추가
- [ ] 테스트: 코드로 강제 호출해서 건물 배치 확인

---

### 📝 상세 작업 항목

#### 3-1. ConstructionManager.gd 작성

**파일 생성**: `scripts/managers/construction_manager.gd`

**내용**:
```gdscript
# scripts/managers/construction_manager.gd
extends Node

# 건설 모드
enum ConstructionMode {
    NONE,
    SINGLE,
    DRAG
}

var current_mode: ConstructionMode = ConstructionMode.NONE
var selected_building: BuildingData = null
var preview_sprite: Sprite2D = null

# 시그널
signal building_selected(building_data: BuildingData)
signal building_placed(building_data: BuildingData, grid_pos: Vector2i)
signal construction_cancelled()

func _ready():
    # 미리보기 스프라이트 생성
    preview_sprite = Sprite2D.new()
    preview_sprite.modulate = Color(1, 1, 1, 0.5)
    preview_sprite.z_index = 100
    preview_sprite.visible = false
    add_child(preview_sprite)

    print("[Phase 3] ConstructionManager 준비 완료")

# 건물 선택
func select_building(building_data: BuildingData, mode: ConstructionMode = ConstructionMode.SINGLE):
    selected_building = building_data
    current_mode = mode

    print("[Phase 3] 건물 선택:", building_data.entity_name)

    # 미리보기 설정
    if building_data and building_data.scene_to_spawn:
        var temp_instance = building_data.scene_to_spawn.instantiate()
        var sprite = temp_instance.get_node("Sprite2D") as Sprite2D
        if sprite:
            preview_sprite.texture = sprite.texture
            preview_sprite.visible = true
        temp_instance.queue_free()

    building_selected.emit(building_data)

# 건설 취소
func cancel_construction():
    selected_building = null
    current_mode = ConstructionMode.NONE
    preview_sprite.visible = false
    print("[Phase 3] 건설 취소")
    construction_cancelled.emit()

# 미리보기 업데이트
func _process(delta):
    if current_mode == ConstructionMode.NONE:
        return

    # 마우스 → 그리드 좌표 변환
    var mouse_pos = get_viewport().get_mouse_position()
    var camera = get_viewport().get_camera_2d()
    if camera:
        mouse_pos = camera.get_global_mouse_position()

    var grid_pos = GridSystem.world_to_grid(mouse_pos)
    var world_pos = GridSystem.grid_to_world(grid_pos)
    preview_sprite.global_position = world_pos

    # 건설 가능 여부에 따라 색상 변경
    if can_build_at(grid_pos):
        preview_sprite.modulate = Color(0.5, 1, 0.5, 0.7)  # 녹색
    else:
        preview_sprite.modulate = Color(1, 0.5, 0.5, 0.7)  # 빨간색

# 건설 가능 여부 검증
func can_build_at(grid_pos: Vector2i) -> bool:
    if not selected_building:
        return false

    # 그리드 범위 체크
    if not GridSystem.is_valid_position(grid_pos):
        return false

    # 이미 건물이 있는지 체크
    if BuildingManager.has_building_at(grid_pos):
        return false

    return true

# 건물 배치 시도
func try_place_building(grid_pos: Vector2i) -> bool:
    if not can_build_at(grid_pos):
        print("[Phase 3] 건설 불가:", grid_pos)
        return false

    # 실제 건물 생성
    var building = selected_building.scene_to_spawn.instantiate()
    building.global_position = GridSystem.grid_to_world(grid_pos)

    # BuildingManager에 등록
    BuildingManager.add_building(building, grid_pos)

    print("[Phase 3] 건물 배치 성공:", selected_building.entity_name, "at", grid_pos)
    building_placed.emit(selected_building, grid_pos)

    return true

# 입력 처리
func _unhandled_input(event):
    if current_mode == ConstructionMode.NONE:
        return

    # ESC로 취소
    if event.is_action_pressed("ui_cancel"):
        cancel_construction()
        get_viewport().set_input_as_handled()
        return

    # 클릭으로 배치
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var mouse_pos = get_viewport().get_mouse_position()
        var camera = get_viewport().get_camera_2d()
        if camera:
            mouse_pos = camera.get_global_mouse_position()

        var grid_pos = GridSystem.world_to_grid(mouse_pos)

        if try_place_building(grid_pos):
            if current_mode == ConstructionMode.SINGLE:
                cancel_construction()

        get_viewport().set_input_as_handled()
```

**참고**: `docs/construction_system_implementation_guide.md` Line 585-724

---

#### 3-2. test_map.tscn에 노드 추가

**Godot 에디터**:

1. `scenes/maps/test_map.tscn` 열기
2. `Managers` 노드 우클릭
3. Add Child Node → Node
4. 이름: `ConstructionManager`
5. Inspector → Script → Attach Script
6. 경로: `scripts/managers/construction_manager.gd`

**결과 구조**:
```
TestMap (Node2D)
├── World
├── Managers (Node)
│   ├── BuildingManager
│   └── ConstructionManager (Node) ← 새로 추가
└── UI
```

---

#### 3-3. Autoload 등록 (권장)

**프로젝트 설정**:

1. Project → Project Settings
2. Autoload 탭
3. Path: `scripts/managers/construction_manager.gd`
4. Name: `ConstructionManager`
5. Enable 클릭

**장점**: 어디서든 `ConstructionManager.select_building()` 호출 가능

---

#### 3-4. 테스트 함수 추가

**파일 수정**: `scripts/maps/test_map.gd`

```gdscript
# scripts/maps/test_map.gd
func _ready():
    # Phase 2 테스트...
    test_resource_load()
    test_instance_creation()
    test_database()

    # ⭐ Phase 3 테스트
    call_deferred("test_construction_manager")

func test_construction_manager():
    print("\n========================================")
    print("Phase 3: ConstructionManager 테스트")
    print("========================================\n")

    # 건물 데이터 로드
    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData

    # 강제로 건물 선택
    ConstructionManager.select_building(house_data)

    # 잠시 대기 (미리보기 확인용)
    await get_tree().create_timer(1.0).timeout

    # 강제로 배치 시도
    var test_pos = Vector2i(5, 5)
    var success = ConstructionManager.try_place_building(test_pos)

    if success:
        print("✅ ConstructionManager 배치 성공!")
        print("화면에서 그리드 (5, 5) 위치에 건물 확인\n")
    else:
        print("❌ ConstructionManager 배치 실패!")
```

**참고**: `docs/construction_system_implementation_guide.md` Line 766-799

---

### ✅ Phase 3 완료 조건

테스트 실행 (F5) 후 다음 확인:

- [ ] 콘솔에 "건물 선택: 주택" 출력
- [ ] 미리보기가 마우스 따라다님 (반투명)
- [ ] 녹색/빨간색으로 색상 변경
- [ ] 콘솔에 "건물 배치 성공" 출력
- [ ] 화면에 건물이 그리드 (5, 5) 위치에 배치됨

**기대 출력**:
```
[Phase 3] ConstructionManager 준비 완료
[Phase 3] 건물 선택: 주택
[Phase 3] 건물 배치 성공: 주택 at (5, 5)
✅ ConstructionManager 배치 성공!
화면에서 그리드 (5, 5) 위치에 건물 확인
```

---

## 🔗 Phase 4: UI 통합

### 목표

- Phase 1 UI + Phase 2 Resource + Phase 3 Logic 연결
- 버튼 클릭 → 실제 건물 배치 동작
- 전체 워크플로우 완성

### 의존성

- ✅ Phase 1 + Phase 2 + Phase 3 (모두 필요)

### 소요 시간

- ⏱️ 15분

---

### ✅ Todo 체크리스트

- [ ] `construction_menu.gd` 수정 (Resource 연결)
- [ ] 테스트 함수 비활성화
- [ ] 전체 워크플로우 테스트

---

### 📝 상세 작업 항목

#### 4-1. construction_menu.gd 수정

**파일 수정**: `scripts/ui/construction_menu.gd`

**변경 사항**: 버튼 클릭 핸들러에 Resource 로드 추가

```gdscript
# scripts/ui/construction_menu.gd

# ⭐ Phase 4: Resource 연결!
func _on_house_button_pressed():
    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData
    ConstructionManager.select_building(house_data)
    # ⭐ 메뉴 유지 (닫지 않음) - 빠른 재선택 가능
    print("[Phase 4] 주택 선택 → ConstructionManager 호출")
    get_viewport().set_input_as_handled()

func _on_farm_button_pressed():
    var farm_data = load("res://scripts/resources/farm_01.tres") as BuildingData
    ConstructionManager.select_building(farm_data)
    # ⭐ 메뉴 유지
    print("[Phase 4] 농장 선택 → ConstructionManager 호출")
    get_viewport().set_input_as_handled()

func _on_shop_button_pressed():
    var shop_data = load("res://scripts/resources/shop_01.tres") as BuildingData
    ConstructionManager.select_building(shop_data)
    # ⭐ 메뉴 유지
    print("[Phase 4] 상점 선택 → ConstructionManager 호출")
    get_viewport().set_input_as_handled()
```

**참고**: `docs/construction_system_implementation_guide.md` Line 860-933

---

#### 4-2. 테스트 함수 비활성화

**파일 수정**: `scripts/maps/test_map.gd`

```gdscript
# scripts/maps/test_map.gd
func _ready():
    # ⭐ Phase 4: 이전 테스트 함수 비활성화 (주석 처리)
    # test_resource_load()
    # test_instance_creation()
    # test_database()
    # call_deferred("test_construction_manager")

    print("\n========================================")
    print("Phase 4: 통합 테스트")
    print("========================================")
    print("하단의 '건설 ▲' 버튼을 클릭하여 메뉴를 열고 건물을 선택하세요.\n")
```

---

### ✅ Phase 4 완료 조건

테스트 실행 (F5) 후 다음 시나리오 확인:

**시나리오**:
1. 하단 "건설 ▲" 버튼 클릭
   - [ ] 건설 메뉴 펼쳐짐

2. "주택" 버튼 클릭
   - [ ] 메뉴 유지 (펼쳐진 상태)
   - [ ] 반투명 주택이 마우스 따라다님
   - [ ] 녹색/빨간색으로 색상 변경

3. 빈 공간 클릭
   - [ ] 건물 배치됨
   - [ ] 미리보기 사라짐
   - [ ] 메뉴는 여전히 펼쳐진 상태

4. "농장" 버튼 클릭
   - [ ] 농장 미리보기 나타남

5. ESC 키
   - [ ] 건설 취소
   - [ ] 미리보기 사라짐

6. "▼ 접기" 버튼 클릭
   - [ ] 메뉴 접힘

**기대 출력**:
```
Phase 4: 통합 테스트
하단의 '건설 ▲' 버튼을 클릭하여 메뉴를 열고 건물을 선택하세요.

[Phase 4] 주택 선택 → ConstructionManager 호출
[Phase 3] 건물 선택: 주택
[Phase 3] 건물 배치 성공: 주택 at (10, 8)

[Phase 4] 농장 선택 → ConstructionManager 호출
[Phase 3] 건물 선택: 농장
[Phase 3] 건설 취소
```

---

## 🔧 (선택) BuildingManager 리팩토링

### 목표

BuildingManager를 Resource 기반으로 개선 (저장 시스템 준비)

### 필요성

- **지금 안 해도 됨**: 현재 구조로도 동작함
- **나중에 저장 시스템 추가 시 필수**: 그때 리팩토링해도 됨
- **지금 하면 좋은 점**: 아키텍처가 더 깔끔해짐

### 소요 시간

- ⏱️ 30분

---

### 📝 리팩토링 내용

#### 현재 구조

```gdscript
# scripts/managers/building_manager.gd (현재)
var grid_buildings: Dictionary = {}  # { Vector2i: BuildingEntity }
```

#### 개선된 구조

```gdscript
# scripts/managers/building_manager.gd (개선)
var building_data_grid: Dictionary = {}     # { Vector2i: BuildingData }
var building_nodes_grid: Dictionary = {}    # { Vector2i: BuildingEntity }

# 건물 추가
func add_building(building: Node2D, grid_pos: Vector2i, data: BuildingData):
    entities_container.add_child(building)
    building_data_grid[grid_pos] = data       # 데이터 저장 (직렬화 가능!)
    building_nodes_grid[grid_pos] = building  # 노드 저장 (비주얼)

# 건물 존재 여부
func has_building_at(grid_pos: Vector2i) -> bool:
    return building_data_grid.has(grid_pos)

# 건물 데이터 조회
func get_building_data_at(grid_pos: Vector2i) -> BuildingData:
    return building_data_grid.get(grid_pos)

# 저장용 데이터 추출 (나중에 사용)
func get_save_data() -> Dictionary:
    var save_dict = {}
    for grid_pos in building_data_grid.keys():
        var data = building_data_grid[grid_pos]
        save_dict[str(grid_pos)] = {
            "building_id": data.entity_id,
            "grid_pos": grid_pos
        }
    return save_dict
```

---

### ✅ 리팩토링 체크리스트

- [ ] `building_data_grid` 변수 추가
- [ ] `building_nodes_grid` 변수 추가
- [ ] `add_building()` 메서드 수정 (data 파라미터 추가)
- [ ] `get_building_data_at()` 메서드 추가
- [ ] `get_save_data()` 메서드 추가 (저장 준비)
- [ ] ConstructionManager에서 호출 부분 수정
- [ ] 테스트: 건물 배치 후 데이터 조회 확인

---

## 📊 전체 진행 상황 추적

### Phase별 체크리스트

#### Phase 2: Resource 시스템
- [ ] EntityData.gd 작성
- [ ] BuildingData.gd 작성
- [ ] house_01.tres 생성
- [ ] farm_01.tres 생성
- [ ] shop_01.tres 생성
- [ ] BuildingDatabase.gd 작성
- [ ] 테스트 함수 작성
- [ ] 테스트 성공 확인

#### Phase 3: ConstructionManager
- [ ] construction_manager.gd 작성
- [ ] select_building() 구현
- [ ] 미리보기 시스템 구현
- [ ] can_build_at() 구현
- [ ] try_place_building() 구현
- [ ] 입력 처리 구현
- [ ] test_map.tscn에 노드 추가
- [ ] Autoload 등록
- [ ] 테스트 성공 확인

#### Phase 4: UI 통합
- [ ] construction_menu.gd 수정
- [ ] 테스트 함수 비활성화
- [ ] 전체 워크플로우 테스트

#### (선택) BuildingManager 리팩토링
- [ ] building_data_grid 추가
- [ ] building_nodes_grid 추가
- [ ] add_building() 수정
- [ ] get_building_data_at() 추가
- [ ] 테스트

---

## ⚠️ 주의사항

### 1. 파일 경로 확인

Resource 경로는 **반드시** `res://`로 시작:
```gdscript
✅ load("res://scripts/resources/house_01.tres")
❌ load("scripts/resources/house_01.tres")
```

### 2. Godot 에디터에서 씬 생성 필수

- ConstructionManager 노드는 **Godot 에디터**에서 추가
- 스크립트로 `ConstructionManager.new()` 하지 말 것

### 3. scene_to_spawn 설정 확인

.tres 파일 생성 후 **반드시** Inspector에서 `scene_to_spawn` 연결:
```
scene_to_spawn: [scenes/entity/building_entity.tscn 드래그]
```

### 4. Autoload 등록 순서

GridSystem, BuildingManager가 먼저 등록되어 있어야 함:
```
Autoload 순서:
1. GridSystem
2. BuildingManager
3. ConstructionManager
```

### 5. 테스트는 단계별로

- Phase 2 완료 → 테스트 통과 확인
- Phase 3 완료 → 테스트 통과 확인
- Phase 4 완료 → 전체 테스트

**한 번에 모두 하지 말 것!**

---

## 🐛 예상 문제 및 해결

### 문제 1: Resource 로드 실패

**증상**:
```
Cannot load resource at path 'res://scripts/resources/house_01.tres'
```

**해결**:
1. FileSystem에서 파일 경로 확인
2. .tres 파일 더블클릭해서 열리는지 확인
3. BuildingData 타입인지 확인

---

### 문제 2: scene_to_spawn이 null

**증상**:
```
[Phase 2] ❌ scene_to_spawn이 null입니다!
```

**해결**:
1. .tres 파일 열기
2. Inspector → scene_to_spawn
3. `scenes/entity/building_entity.tscn` 드래그해서 연결

---

### 문제 3: 미리보기 안 나타남

**원인**: Sprite2D 노드 못 찾음

**해결**:
```gdscript
var sprite = temp_instance.get_node("Sprite2D") as Sprite2D
if sprite:  # ✅ null 체크 추가
    preview_sprite.texture = sprite.texture
else:
    print("경고: Sprite2D 노드를 찾을 수 없습니다!")
```

---

### 문제 4: 건물 배치 안 됨

**원인**: GridSystem, BuildingManager 없음

**해결**:
- GridSystem이 Autoload로 등록되어 있는지 확인
- BuildingManager가 test_map.tscn에 있는지 확인
- `has_building_at()` 메서드가 있는지 확인

---

## 📚 참고 문서

| 문서 | 내용 |
|------|------|
| `docs/construction_system_implementation_guide.md` | Phase별 구현 가이드 (이 계획의 기반) |
| `docs/design/building_construction_system_design.md` | 건설 시스템 설계 |
| `docs/design/ui_system_design.md` | UI 시스템 설계 |
| `docs/code_convention.md` | 코드 컨벤션 및 SOLID 원칙 |

---

## ✅ 최종 확인 체크리스트

### 모든 Phase 완료 시 확인

- [ ] 하단 "건설 ▲" 버튼으로 메뉴 펼침
- [ ] 버튼 클릭 → 미리보기 표시
- [ ] 미리보기가 마우스 따라다님
- [ ] 녹색/빨간색으로 건설 가능 여부 표시
- [ ] 클릭으로 건물 배치
- [ ] 건물 배치 후에도 메뉴 유지
- [ ] "▼ 접기" 버튼으로 메뉴 접힘
- [ ] ESC로 건설 취소
- [ ] 여러 건물 연속 배치 가능

### 파일 생성 확인

```
scripts/resources/
├── entity_data.gd           ✅
├── building_data.gd         ✅
├── house_01.tres            ✅
├── farm_01.tres             ✅
└── shop_01.tres             ✅

scripts/config/
└── building_database.gd     ✅

scripts/managers/
└── construction_manager.gd  ✅

scripts/ui/
└── construction_menu.gd     ✅ (수정됨)
```

---

## 🎉 완료 후 다음 단계

Phase 4 완료 후 가능한 확장:

1. **건설 메뉴 개선**
   - BuildingButton 프리팹
   - 동적 버튼 생성
   - 카테고리별 분류

2. **드래그 건축**
   - ConstructionMode.DRAG 활용
   - 도로 연속 배치

3. **자원 시스템**
   - ResourceManager 추가
   - 비용 차감 로직

4. **건물 정보 패널**
   - 선택 시 정보 표시
   - 업그레이드/철거 버튼

5. **저장 시스템 (핵심!)**
   - SaveGame 시스템 구현
   - `BuildingManager.get_save_data()` 활용
   - Resource 기반이라 매우 쉬움!

---

## 📊 예상 타임라인

| Phase | 작업 | 예상 시간 |
|-------|------|----------|
| **Phase 2** | Resource 시스템 구축 | 30분 |
| **Phase 3** | ConstructionManager 구현 | 30분 |
| **Phase 4** | UI 통합 | 15분 |
| **(선택)** | BuildingManager 리팩토링 | 30분 |
| **총계** | | **1.5~2시간** |

---

## 💡 핵심 요약

### 왜 Resource 기반으로 전환하는가?

1. **저장 시스템 준비**
   - BuildingData는 직렬화 가능 (Resource)
   - 나중에 저장 시스템 추가 시 `ResourceSaver.save()` 한 줄로 끝

2. **데이터와 뷰 분리**
   - BuildingData (데이터) vs BuildingEntity (비주얼)
   - 테스트 용이, 재사용성 높음

3. **에디터에서 편집 가능**
   - .tres 파일 → Inspector에서 수정
   - 코드 수정 없이 밸런스 조정 가능

4. **확장성**
   - 새 건물 추가 = .tres 파일 1개 + Database에 1줄 추가
   - 코드 수정 최소화

### 지금 하는 것이 가장 효율적!

- ✅ Phase 1만 완료된 상태 → 리팩토링 비용 낮음
- ✅ 설계 문서 완비 → 따라하기만 하면 됨
- ✅ 나중에 저장 시스템 무료로 얻음

---

**축하합니다!** 이 계획을 따라하면 Resource 기반 건설 시스템이 완성됩니다! 🎉
