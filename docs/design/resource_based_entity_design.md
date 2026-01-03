# Resource 기반 엔티티 설계 패턴 (Resource-Based Entity Design Pattern)

## 1. 개요

Godot의 **Resource 시스템**을 활용하여 모든 게임 엔티티(건물, 유닛, NPC, 아이템 등)를 **데이터 주도 방식**으로 설계하는 패턴입니다.

### 1.1. 왜 Resource 패턴인가?

**전통적인 방식 (씬 하드코딩):**

```gdscript
# ❌ 나쁜 예: 모든 데이터가 코드에 하드코딩됨
func create_house():
    var house = HouseScene.instantiate()
    house.name = "주택"
    house.cost = 100
    house.health = 500
```

**문제점:**
- ❌ 새 건물 추가 = 코드 수정 필요
- ❌ 기획 변경 = 프로그래머가 수정
- ❌ 데이터 재사용 어려움
- ❌ 저장/로드 시스템 복잡

**Resource 방식 (데이터 주도):**

```gdscript
# ✅ 좋은 예: 데이터와 로직 분리
var house_data = load("res://data/buildings/house.tres")

func create_building(data: BuildingData):
    var building = data.scene_to_build.instantiate()
    # 데이터에서 모든 정보 가져옴
```

**장점:**
- ✅ 코드 수정 없이 새 엔티티 추가
- ✅ 기획자가 에디터에서 직접 데이터 편집
- ✅ 데이터 재사용 및 상속 가능
- ✅ 저장/로드 시스템 단순화
- ✅ 모딩 지원 용이

### 1.2. 핵심 원칙

**데이터 → 로직 → 표현 분리**

```
EntityData (Resource)    ← 데이터 레이어
      ↓
EntityFactory            ← 로직 레이어
      ↓
Entity (Node2D)          ← 표현 레이어
```

---

## 2. Resource 패턴 기본 구조

### 2.1. 1단계: 기본 EntityData 클래스

**파일**: `scripts/resources/entity_data.gd`

```gdscript
# scripts/resources/entity_data.gd
class_name EntityData extends Resource

# 모든 엔티티 공통 속성
@export var entity_id: String = ""           # 고유 ID
@export var entity_name: String = ""         # 표시 이름
@export var description: String = ""         # 설명
@export var icon: Texture2D                  # UI 아이콘
@export var scene_to_spawn: PackedScene      # 실제 씬

# 공통 헬퍼 함수
func get_id() -> String:
    return entity_id

func get_display_name() -> String:
    return entity_name
```

### 2.2. 2단계: 특화된 Resource 상속

**건물 데이터:**

```gdscript
# scripts/resources/building_data.gd
class_name BuildingData extends EntityData

# 건물 전용 속성
@export var cost_wood: int = 0
@export var cost_stone: int = 0
@export var cost_gold: int = 0
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var max_health: int = 500

func get_total_cost() -> Dictionary:
    return {
        "wood": cost_wood,
        "stone": cost_stone,
        "gold": cost_gold
    }
```

**유닛 데이터:**

```gdscript
# scripts/resources/unit_data.gd
class_name UnitData extends EntityData

# 유닛 전용 속성
@export var move_speed: float = 100.0
@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_range: float = 50.0
@export var training_cost_gold: int = 50
@export var training_time: float = 5.0

enum UnitType {
    WORKER,    # 일꾼
    SOLDIER,   # 전사
    ARCHER     # 궁수
}
@export var unit_type: UnitType = UnitType.WORKER
```

**NPC 데이터:**

```gdscript
# scripts/resources/npc_data.gd
class_name NPCData extends EntityData

# NPC 전용 속성
@export var move_speed: float = 80.0
@export var idle_duration: float = 3.0

enum BehaviorPattern {
    PATROL,    # 순찰
    WANDER,    # 배회
    IDLE       # 대기
}
@export var default_behavior: BehaviorPattern = BehaviorPattern.WANDER

# 순찰 경로 (옵션)
@export var patrol_points: Array[Vector2i] = []
```

**아이템 데이터:**

```gdscript
# scripts/resources/item_data.gd
class_name ItemData extends EntityData

# 아이템 전용 속성
@export var item_type: ItemType = ItemType.RESOURCE
@export var stack_size: int = 99
@export var sell_price: int = 10

enum ItemType {
    RESOURCE,   # 자원 (나무, 돌)
    CONSUMABLE, # 소비 (포션)
    EQUIPMENT   # 장비 (검, 방패)
}
```

### 2.3. 상속 구조 요약

```
Resource (Godot 내장)
   ↓
EntityData (공통 베이스)
   ├── BuildingData (건물)
   ├── UnitData (유닛)
   ├── NPCData (NPC)
   ├── ItemData (아이템)
   └── ProjectileData (투사체, 미래)
```

---

## 3. Resource 파일 생성 및 관리

### 3.1. Resource 파일 생성 (Godot 에디터)

**Step 1: 폴더 구조 생성**

```
scripts/
└── resources/
    ├── entity_data.gd          # 베이스 클래스
    ├── building_data.gd        # 건물 데이터 클래스
    ├── unit_data.gd            # 유닛 데이터 클래스
    └── npc_data.gd             # NPC 데이터 클래스

data/  ← 실제 .tres 파일들
├── buildings/
│   ├── house_01.tres
│   ├── farm_01.tres
│   └── barracks_01.tres
├── units/
│   ├── worker_01.tres
│   ├── soldier_01.tres
│   └── archer_01.tres
├── npcs/
│   ├── villager_01.tres
│   ├── merchant_01.tres
│   └── farmer_01.tres
└── items/
    ├── wood.tres
    ├── stone.tres
    └── gold.tres
```

**Step 2: Resource 파일 생성**

```
Godot 에디터:
1. FileSystem → data/buildings/ 우클릭
2. "Create New" → "Resource"
3. 타입 선택: "BuildingData"
4. 이름: house_01.tres
5. Inspector에서 데이터 입력:
   - entity_id: "house_01"
   - entity_name: "주택"
   - description: "주민이 거주하는 집"
   - icon: [아이콘 이미지 드래그]
   - scene_to_spawn: [씬 파일 드래그]
   - cost_gold: 100
   - grid_size: (1, 1)
6. 저장 (Ctrl+S)
```

### 3.2. Database 패턴 (중앙 관리)

**파일**: `scripts/config/entity_database.gd`

```gdscript
# scripts/config/entity_database.gd
extends Node
class_name EntityDatabase

# 건물 데이터베이스
const BUILDINGS: Array[BuildingData] = [
    preload("res://data/buildings/house_01.tres"),
    preload("res://data/buildings/farm_01.tres"),
    preload("res://data/buildings/barracks_01.tres"),
]

# 유닛 데이터베이스
const UNITS: Array[UnitData] = [
    preload("res://data/units/worker_01.tres"),
    preload("res://data/units/soldier_01.tres"),
    preload("res://data/units/archer_01.tres"),
]

# NPC 데이터베이스
const NPCS: Array[NPCData] = [
    preload("res://data/npcs/villager_01.tres"),
    preload("res://data/npcs/merchant_01.tres"),
]

# 범용 검색 함수
static func get_entity_by_id(id: String) -> EntityData:
    # 건물 검색
    for building in BUILDINGS:
        if building.entity_id == id:
            return building

    # 유닛 검색
    for unit in UNITS:
        if unit.entity_id == id:
            return unit

    # NPC 검색
    for npc in NPCS:
        if npc.entity_id == id:
            return npc

    return null

# 타입별 검색
static func get_building_by_id(id: String) -> BuildingData:
    for building in BUILDINGS:
        if building.entity_id == id:
            return building
    return null

static func get_unit_by_id(id: String) -> UnitData:
    for unit in UNITS:
        if unit.entity_id == id:
            return unit
    return null

static func get_all_buildings() -> Array[BuildingData]:
    return BUILDINGS.duplicate()

static func get_all_units() -> Array[UnitData]:
    return UNITS.duplicate()
```

---

## 4. Factory 패턴 (인스턴스 생성)

### 4.1. EntityFactory 기본 클래스

**파일**: `scripts/factories/entity_factory.gd`

```gdscript
# scripts/factories/entity_factory.gd
class_name EntityFactory extends Node

# Resource에서 엔티티 인스턴스 생성
static func create_entity(entity_data: EntityData, position: Vector2) -> Node2D:
    if not entity_data or not entity_data.scene_to_spawn:
        push_error("Invalid entity data or scene")
        return null

    # 씬 인스턴스화
    var entity = entity_data.scene_to_spawn.instantiate()

    # 위치 설정
    entity.global_position = position

    # 엔티티에 데이터 전달 (옵션)
    if entity.has_method("set_entity_data"):
        entity.set_entity_data(entity_data)

    return entity

# 그리드 좌표로 생성
static func create_entity_at_grid(entity_data: EntityData, grid_pos: Vector2i) -> Node2D:
    var world_pos = GridSystem.grid_to_world(grid_pos)
    return create_entity(entity_data, world_pos)
```

### 4.2. 특화된 Factory 클래스

**BuildingFactory:**

```gdscript
# scripts/factories/building_factory.gd
class_name BuildingFactory extends EntityFactory

# 건물 전용 생성 로직
static func create_building(building_data: BuildingData, grid_pos: Vector2i) -> Node2D:
    var building = create_entity_at_grid(building_data, grid_pos)

    if building:
        # 건물 전용 초기화
        if building.has_method("set_grid_size"):
            building.set_grid_size(building_data.grid_size)

        if building.has_method("set_max_health"):
            building.set_max_health(building_data.max_health)

    return building
```

**UnitFactory:**

```gdscript
# scripts/factories/unit_factory.gd
class_name UnitFactory extends EntityFactory

# 유닛 전용 생성 로직
static func create_unit(unit_data: UnitData, grid_pos: Vector2i) -> CharacterBody2D:
    var unit = create_entity_at_grid(unit_data, grid_pos)

    if unit:
        # 유닛 전용 초기화
        if unit.has_method("set_stats"):
            unit.set_stats(
                unit_data.max_health,
                unit_data.move_speed,
                unit_data.attack_damage
            )

    return unit
```

---

## 5. Entity 클래스 (씬 스크립트)

### 5.1. 엔티티가 데이터를 받는 방법

**패턴 1: 생성 후 데이터 전달**

```gdscript
# scenes/entity/building_entity.gd
extends Node2D
class_name BuildingEntity

var entity_data: BuildingData  # Resource 참조
var current_health: int
var grid_size: Vector2i

# Factory에서 호출
func set_entity_data(data: BuildingData):
    entity_data = data

    # 데이터로부터 초기화
    current_health = data.max_health
    grid_size = data.grid_size

    # 비주얼 업데이트
    update_visual()

func update_visual():
    # 스프라이트 설정 등
    pass
```

**패턴 2: @export로 에디터에서 할당**

```gdscript
# 씬에 직접 배치하는 경우 (맵 에디터용)
extends Node2D

@export var entity_data: BuildingData  # 에디터에서 할당

func _ready():
    if entity_data:
        current_health = entity_data.max_health
```

### 5.2. 데이터 기반 동작

```gdscript
# scripts/entity/unit_entity.gd
extends CharacterBody2D
class_name UnitEntity

var entity_data: UnitData
var current_health: int
var move_speed: float

func set_entity_data(data: UnitData):
    entity_data = data
    current_health = data.max_health
    move_speed = data.move_speed

func _physics_process(delta):
    # 데이터의 move_speed 사용
    velocity = direction * move_speed
    move_and_slide()

func attack(target):
    # 데이터의 attack_damage 사용
    target.take_damage(entity_data.attack_damage)
```

---

## 6. 실전 활용 예시

### 6.1. 건물 건설 시스템

```gdscript
# scripts/managers/construction_manager.gd
var selected_building_data: BuildingData

func select_building_from_menu(building_id: String):
    # Database에서 데이터 로드
    selected_building_data = EntityDatabase.get_building_by_id(building_id)

func place_building(grid_pos: Vector2i):
    # Factory로 인스턴스 생성
    var building = BuildingFactory.create_building(selected_building_data, grid_pos)

    # 씬에 추가
    BuildingManager.add_building(building, grid_pos)
```

### 6.2. 유닛 생성 시스템

```gdscript
# scripts/managers/unit_spawner.gd
func spawn_unit_from_barracks(unit_id: String, spawn_pos: Vector2i):
    # Database에서 데이터 로드
    var unit_data = EntityDatabase.get_unit_by_id(unit_id)

    # Factory로 생성
    var unit = UnitFactory.create_unit(unit_data, spawn_pos)

    # 씬에 추가
    UnitManager.add_unit(unit)
```

### 6.3. NPC 배치 시스템

```gdscript
# scripts/managers/npc_manager.gd
func spawn_npc(npc_id: String, spawn_pos: Vector2i):
    var npc_data = EntityDatabase.get_npc_by_id(npc_id)
    var npc = EntityFactory.create_entity_at_grid(npc_data, spawn_pos)

    # NPC 행동 패턴 설정
    if npc.has_method("set_behavior"):
        npc.set_behavior(npc_data.default_behavior)

    add_child(npc)
```

### 6.4. 저장/로드 시스템

**저장:**

```gdscript
# scripts/systems/save_system.gd
func save_game():
    var save_data = {
        "buildings": []
    }

    # 모든 건물의 ID와 위치만 저장
    for building in BuildingManager.get_all_buildings():
        save_data["buildings"].append({
            "id": building.entity_data.entity_id,
            "grid_pos": building.grid_position
        })

    # 파일로 저장
    var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
```

**로드:**

```gdscript
func load_game():
    var file = FileAccess.open("user://savegame.json", FileAccess.READ)
    var save_data = JSON.parse_string(file.get_as_text())

    # ID로 건물 복원
    for building_info in save_data["buildings"]:
        var building_data = EntityDatabase.get_building_by_id(building_info["id"])
        var building = BuildingFactory.create_building(building_data, building_info["grid_pos"])
        BuildingManager.add_building(building, building_info["grid_pos"])
```

**장점:**
- ✅ ID만 저장하므로 파일 크기 작음
- ✅ 데이터 변경 시 저장 파일 호환성 유지
- ✅ 밸런스 패치 후에도 기존 세이브 파일 사용 가능

---

## 7. 고급 패턴

### 7.1. Resource 상속 (데이터 재사용)

**기본 주택:**

```
house_basic.tres:
- entity_id: "house_basic"
- cost_gold: 100
- max_health: 500
```

**업그레이드된 주택 (상속):**

```gdscript
# 에디터에서 house_basic.tres를 복사
house_upgraded.tres:
- entity_id: "house_upgraded"
- cost_gold: 200  # 재정의
- max_health: 1000  # 재정의
# 나머지는 house_basic에서 상속
```

### 7.2. 동적 데이터 로드 (모딩 지원)

```gdscript
# 모드 폴더에서 커스텀 건물 로드
func load_mod_buildings(mod_path: String):
    var dir = DirAccess.open(mod_path)

    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()

        while file_name != "":
            if file_name.ends_with(".tres"):
                var building_data = load(mod_path + "/" + file_name)
                if building_data is BuildingData:
                    # 동적으로 데이터베이스에 추가
                    EntityDatabase.BUILDINGS.append(building_data)

            file_name = dir.get_next()
```

### 7.3. 데이터 검증 시스템

```gdscript
# scripts/resources/building_data.gd
func _validate_property(property: Dictionary):
    # cost_gold는 0 이상이어야 함
    if property.name == "cost_gold":
        if cost_gold < 0:
            push_error("cost_gold must be >= 0")
            cost_gold = 0

    # grid_size는 1x1 이상이어야 함
    if property.name == "grid_size":
        if grid_size.x < 1 or grid_size.y < 1:
            push_error("grid_size must be at least 1x1")
            grid_size = Vector2i(1, 1)
```

---

## 8. 비교: Resource vs 다른 방식

### 8.1. Resource vs 하드코딩

| 항목 | 하드코딩 | Resource |
|------|---------|----------|
| 새 엔티티 추가 | 코드 수정 필요 | .tres 파일 생성 |
| 밸런스 조정 | 코드 재컴파일 | 에디터에서 수정 |
| 데이터 재사용 | 어려움 | 쉬움 (복사/상속) |
| 저장/로드 | 복잡함 | 간단함 (ID만) |
| 모딩 지원 | 불가능 | 가능 |

### 8.2. Resource vs JSON/CSV

| 항목 | JSON/CSV | Resource |
|------|----------|----------|
| 에디터 통합 | 없음 | ✅ Inspector에서 편집 |
| 타입 안정성 | 없음 | ✅ GDScript 타입 |
| 씬 참조 | 경로만 | ✅ 직접 드래그 |
| 유효성 검증 | 수동 | ✅ 자동 (_validate_property) |
| 파일 크기 | 작음 | 약간 큼 |

**결론:** 소규모 프로젝트는 Resource, 대규모 데이터는 JSON+Resource 하이브리드

---

## 9. 베스트 프랙티스

### 9.1. 파일 구조 권장사항

```
scripts/
├── resources/
│   ├── entity_data.gd          # 베이스 클래스
│   ├── building_data.gd
│   ├── unit_data.gd
│   └── npc_data.gd
├── factories/
│   ├── entity_factory.gd       # 베이스 Factory
│   ├── building_factory.gd
│   └── unit_factory.gd
└── config/
    └── entity_database.gd      # 중앙 데이터베이스

data/  ← .tres 파일들만
├── buildings/
├── units/
└── npcs/

scenes/
└── entity/
    ├── building_entity.tscn    # 건물 씬
    ├── unit_entity.tscn        # 유닛 씬
    └── npc_entity.tscn         # NPC 씬
```

### 9.2. 네이밍 컨벤션

**Resource 클래스:**
- `EntityData`, `BuildingData`, `UnitData` (접미사 `Data`)

**Resource 파일:**
- `house_01.tres`, `soldier_basic.tres` (소문자 + 언더스코어)

**ID 규칙:**
- `"house_01"`, `"unit_soldier_basic"` (타입 접두사 옵션)

### 9.3. 개발 순서

```
1. EntityData 베이스 클래스 정의
   ↓
2. 특화된 Resource 클래스 (BuildingData 등)
   ↓
3. .tres 파일 3~5개 생성 (테스트용)
   ↓
4. EntityDatabase 작성
   ↓
5. EntityFactory 구현
   ↓
6. Manager에서 Factory 사용
   ↓
7. UI 연동
```

---

## 10. 실전 체크리스트

### Phase 1: Resource 시스템 구축
- [ ] EntityData.gd 작성
- [ ] BuildingData.gd 상속 클래스 작성
- [ ] UnitData.gd 상속 클래스 작성
- [ ] house_01.tres, farm_01.tres 생성
- [ ] EntityDatabase.gd 작성

### Phase 2: Factory 시스템
- [ ] EntityFactory.gd 작성
- [ ] BuildingFactory.gd 작성
- [ ] UnitFactory.gd 작성
- [ ] 테스트: Resource → 인스턴스 생성

### Phase 3: Manager 통합
- [ ] BuildingManager에서 Factory 사용
- [ ] UnitManager에서 Factory 사용
- [ ] 테스트: ID로 엔티티 생성

### Phase 4: UI 연동
- [ ] 건설 메뉴에서 BuildingData 사용
- [ ] 유닛 생산 UI에서 UnitData 사용
- [ ] 아이콘, 비용 등 동적 표시

### Phase 5: 고급 기능
- [ ] 저장/로드 시스템
- [ ] 데이터 검증 시스템
- [ ] 모딩 지원 (옵션)

---

## 11. 참고 문서

- `docs/design/building_construction_system_design.md`: 건설 시스템 구체적 구현
- `docs/prd.md`: 전체 시스템 요구사항
- Godot 공식 문서:
  - [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)
  - [@export](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html)

---

## 12. 결론

**Resource 패턴의 핵심:**

```
데이터 (Resource .tres)
   ↓
로직 (Factory)
   ↓
표현 (Entity Scene)
```

이 패턴을 따르면:
- ✅ 코드와 데이터가 완전히 분리됨
- ✅ 기획자가 에디터에서 직접 작업 가능
- ✅ 새 콘텐츠 추가가 매우 쉬움
- ✅ 확장성과 유지보수성 향상
- ✅ 모딩 및 DLC 지원 가능

**다음 단계:**
1. `building_construction_system_design.md`의 BuildingData 구현
2. UnitData, NPCData로 패턴 확장
3. 저장/로드 시스템에 Resource ID 활용

**핵심 기억:**
> "씬은 표현, Resource는 데이터, Factory는 연결고리"
