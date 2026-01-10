# Resource 기반 엔티티 설계 패턴

## 📌 1. 개요

Godot의 **Resource 시스템**을 활용하여 모든 게임 엔티티(건물, 유닛, NPC, 아이템 등)를 **데이터 주도 방식(Data-Driven)**으로 설계하는 패턴입니다.

### 1.1. 핵심 아이디어

**의존성 주입(Dependency Injection) 패턴**을 사용하여 단일 씬으로 다양한 외형과 속성을 가진 엔티티를 구현합니다.

- **Data (Resource)**: 엔티티가 "어떤 데이터"를 가질지 정의
- **View (Scene)**: 데이터를 "어떻게" 표시할지 정의
- **Controller (Manager)**: 씬을 생성하고 데이터를 주입

```
하나의 씬 (building_entity.tscn)
  +
Resource 파일들 (house_01.tres, farm_01.tres...)
  =
무한한 건물 종류!
```

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

## 🎯 2. 왜 이 방식을 사용하는가?

### 2.1. 문제 상황

각 건물(주택, 농장, 상점)이 다른 이미지와 속성을 가져야 하는데, 어떻게 구현할까?

#### ❌ 잘못된 접근 1: 각 건물마다 씬 생성

```
scenes/entity/
  ├─ house_entity.tscn
  ├─ farm_entity.tscn
  └─ shop_01_entity.tscn (건물 100개면 씬 100개!)
```

**단점:**
- 씬 파일 관리 복잡
- 공통 로직 수정 시 모든 씬 수정 필요
- 유지보수 지옥

#### ❌ 잘못된 접근 2: 코드로 분기 처리

```gdscript
func create_building(type: String):
    if type == "house":
        sprite.texture = house_texture
    elif type == "farm":
        sprite.texture = farm_texture
    # ... 건물 100개면 if문 100개!
```

**단점:**
- 확장성 없음 (새 건물 추가 = 코드 수정)
- Open/Closed 원칙 위반
- 기획 변경 = 프로그래머가 수정

#### ❌ 잘못된 접근 3: 하드코딩

```gdscript
# 모든 데이터가 코드에 하드코딩됨
func create_house():
    var house = HouseScene.instantiate()
    house.name = "주택"
    house.cost = 100
    house.health = 500
```

**단점:**
- 새 건물 추가 = 코드 수정 필요
- 데이터 재사용 어려움
- 저장/로드 시스템 복잡

#### ✅ 올바른 접근: Resource 기반 의존성 주입

```gdscript
# 데이터와 로직 분리
var house_data = BuildingDatabase.get_building_by_id("house_01")
var building = BuildingManager.create_building(Vector2i(5, 5), house_data)
# 끝! BuildingEntity가 알아서 처리함
```

**장점:**
- ✅ 씬 1개만 관리
- ✅ 새 건물 추가 = .tres 파일만 생성 (코드 수정 불필요)
- ✅ 기획자가 에디터에서 직접 데이터 편집
- ✅ SOLID 원칙 준수
- ✅ 저장 시스템 호환
- ✅ 데이터 재사용 및 상속 가능
- ✅ 모딩 지원 용이

---

## 🏗️ 3. 아키텍처 설계

### 3.1. 전체 구조

```
[Resource Layer - 데이터]
  EntityData (베이스 클래스)
    ├─ sprite_texture: Texture2D
    ├─ sprite_scale: Vector2
    ├─ sprite_offset: Vector2
    ├─ icon: Texture2D
    └─ scene_to_spawn: PackedScene

  BuildingData (extends EntityData)
    ├─ cost_wood: int
    ├─ cost_stone: int
    ├─ cost_gold: int
    └─ category: Enum

  UnitData (extends EntityData)
    ├─ move_speed: float
    ├─ max_health: int
    └─ attack_damage: int

  NPCData (extends EntityData)
    └─ default_behavior: Enum

  ItemData (extends EntityData)
    └─ stack_size: int

[View Layer - 씬]
  BuildingEntity.tscn
    └─ Sprite2D (빈 템플릿)

  BuildingEntity.gd
    ├─ initialize(data: BuildingData)  ← 주입 받는 함수
    └─ _update_visuals()  ← 데이터 → 비주얼 변환

[Controller Layer - 매니저]
  BuildingManager
    └─ create_building(grid_pos, data)
          ↓
       building.initialize(data)  ← 주입!

[Factory Layer - 인스턴스 생성]
  EntityFactory
    └─ create_entity(entity_data, position)

  BuildingFactory (extends EntityFactory)
    └─ create_building(building_data, grid_pos)

[Database Layer - 중앙 관리]
  EntityDatabase
    ├─ get_building_by_id("house_01")
    ├─ get_unit_by_id("soldier_01")
    └─ get_all_buildings()
```

### 3.2. 의존성 방향

```
BuildingManager (고수준)
    ↓ 의존
BuildingData (추상화)
    ↓
Texture2D (저수준 - Godot 내장)
```

**핵심**: 매니저는 Godot 내장 타입(Texture2D)을 직접 다루지 않고, BuildingData를 통해서만 접근합니다.

---

## 📝 4. Resource 클래스 설계

### 4.1. EntityData (베이스 Resource)

**파일**: `scripts/resources/entity_data.gd`

```gdscript
class_name EntityData extends Resource

# 기본 정보
@export_group("Basic Info")
@export var entity_id: String = ""
@export var entity_name: String = ""
@export var description: String = ""

# 비주얼
@export_group("Visuals")
@export var sprite_texture: Texture2D        # 텍스처 (개별 이미지 or Atlas)
@export var sprite_scale: Vector2 = Vector2.ONE    # 크기 조정
@export var sprite_offset: Vector2 = Vector2.ZERO  # 위치 보정
@export var icon: Texture2D                  # UI 아이콘

# 씬
@export_group("Scene")
@export var scene_to_spawn: PackedScene      # 실제 씬

func get_id() -> String:
    return entity_id

func get_display_name() -> String:
    return entity_name
```

**핵심 포인트:**
- `extends Resource` - 직렬화 가능 (저장 시스템 호환)
- `@export` - Inspector에서 편집 가능
- `@export_group` - Inspector 정리

### 4.2. BuildingData (건물 전용 Resource)

**파일**: `scripts/resources/building_data.gd`

```gdscript
class_name BuildingData extends EntityData

# 건물 전용 속성
@export_group("Building Properties")
@export var cost_wood: int = 0
@export var cost_stone: int = 0
@export var cost_gold: int = 100
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var max_health: int = 500

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

### 4.3. UnitData (유닛 전용 Resource)

**파일**: `scripts/resources/unit_data.gd`

```gdscript
class_name UnitData extends EntityData

# 유닛 전용 속성
@export_group("Unit Stats")
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

### 4.4. NPCData (NPC 전용 Resource)

**파일**: `scripts/resources/npc_data.gd`

```gdscript
class_name NPCData extends EntityData

# NPC 전용 속성
@export_group("NPC Behavior")
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

### 4.5. ItemData (아이템 전용 Resource)

**파일**: `scripts/resources/item_data.gd`

```gdscript
class_name ItemData extends EntityData

# 아이템 전용 속성
@export_group("Item Properties")
@export var item_type: ItemType = ItemType.RESOURCE
@export var stack_size: int = 99
@export var sell_price: int = 10

enum ItemType {
    RESOURCE,   # 자원 (나무, 돌)
    CONSUMABLE, # 소비 (포션)
    EQUIPMENT   # 장비 (검, 방패)
}
```

### 4.6. 상속 구조

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

## 🎨 5. 스프라이트 주입 시스템

### 5.1. BuildingEntity (View)

**파일**: `scripts/entity/building_entity.gd`

```gdscript
class_name BuildingEntity extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

# 현재 이 엔티티가 가지고 있는 데이터
var data: BuildingData

func _ready() -> void:
    # ... 기존 초기화 코드 ...

    # 데이터가 있으면 비주얼 업데이트
    if data:
        _update_visuals()

# ⭐ 외부(건설 시스템)에서 호출하는 초기화 함수
func initialize(new_data: BuildingData) -> void:
    data = new_data
    _update_visuals()
    print("[BuildingEntity] initialize() 호출됨: ", data.entity_name)

# ⭐ 뷰를 데이터에 맞게 갱신하는 내부 함수
func _update_visuals() -> void:
    if not data:
        push_warning("BuildingEntity: 데이터가 없습니다!")
        return

    # 텍스처 설정
    if data.sprite_texture:
        sprite.texture = data.sprite_texture

        # 스케일 적용
        if data.sprite_scale != Vector2.ONE:
            sprite.scale = data.sprite_scale

        # 오프셋 적용
        if data.sprite_offset != Vector2.ZERO:
            sprite.position = data.sprite_offset
    else:
        push_warning("BuildingData에 텍스처가 설정되지 않았습니다: %s" % data.entity_name)
```

**핵심 포인트:**
- `initialize(data)` - 의존성 주입 받는 함수
- `_update_visuals()` - 데이터를 비주얼로 변환
- 데이터 → 뷰 단방향 흐름

### 5.2. BuildingManager (Controller)

**파일**: `scripts/managers/building_manager.gd`

```gdscript
func create_building(grid_pos: Vector2i, building_data: BuildingData = null) -> Node2D:
    # ... 유효성 검사 ...

    # BuildingEntity 인스턴스 생성
    var building = BuildingEntityScene.instantiate()

    # 위치 설정
    building.grid_position = grid_pos
    building.position = GridSystem.grid_to_world(grid_pos)

    # 씬 트리에 추가
    buildings_parent.add_child(building)

    # ⭐ Resource 기반 초기화 (의존성 주입!)
    if building_data:
        building.initialize(building_data)
        print("[BuildingManager] 건물 생성 (Resource): ", building_data.entity_name)

    return building
```

**핵심 포인트:**
- `building_data`는 optional parameter (기존 코드 호환)
- 데이터가 있으면 `initialize()` 호출
- 매니저는 데이터만 전달, 세부사항은 BuildingEntity가 처리

---

## 📦 6. Resource 파일 관리

### 6.1. Resource 파일 생성 (Godot 에디터)

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

**Step 2: .tres 파일 생성**

1. FileSystem → `data/buildings/` 우클릭
2. "Create New" → "Resource"
3. 타입: "BuildingData" 검색 → 선택
4. 이름: `house_01.tres`
5. Create

### 6.2. Inspector에서 데이터 입력

```
house_01.tres:

[Basic Info]
- Entity Id: "house_01"
- Entity Name: "주택"
- Description: "주민이 거주하는 집입니다."

[Visuals]
- Sprite Texture: [icon.svg 드래그]
- Sprite Scale: (0.5, 0.5)  ← 절반 크기!
- Sprite Offset: (0, 0)
- Icon: [비워둠]

[Scene]
- Scene To Spawn: [building_entity.tscn 드래그]

[Building Properties]
- Cost Wood: 50
- Cost Stone: 30
- Cost Gold: 100
- Grid Size: (1, 1)
- Category: RESIDENTIAL
- Max Health: 500
```

### 6.3. EntityDatabase (중앙 관리)

**파일**: `scripts/config/entity_database.gd`

```gdscript
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

## 🏭 7. Factory 패턴 (인스턴스 생성)

### 7.1. EntityFactory (기본 클래스)

**파일**: `scripts/factories/entity_factory.gd`

```gdscript
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
    if entity.has_method("initialize"):
        entity.initialize(entity_data)

    return entity

# 그리드 좌표로 생성
static func create_entity_at_grid(entity_data: EntityData, grid_pos: Vector2i) -> Node2D:
    var world_pos = GridSystem.grid_to_world(grid_pos)
    return create_entity(entity_data, world_pos)
```

### 7.2. BuildingFactory (건물 전용)

**파일**: `scripts/factories/building_factory.gd`

```gdscript
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

### 7.3. UnitFactory (유닛 전용)

**파일**: `scripts/factories/unit_factory.gd`

```gdscript
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

## 🎮 8. Entity 클래스 구현

### 8.1. 엔티티가 데이터를 받는 방법

**패턴 1: 생성 후 데이터 전달**

```gdscript
# scenes/entity/building_entity.gd
extends Node2D
class_name BuildingEntity

var entity_data: BuildingData  # Resource 참조
var current_health: int
var grid_size: Vector2i

# Factory에서 호출
func initialize(data: BuildingData):
    entity_data = data

    # 데이터로부터 초기화
    current_health = data.max_health
    grid_size = data.grid_size

    # 비주얼 업데이트
    _update_visuals()

func _update_visuals():
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

### 8.2. 데이터 기반 동작

```gdscript
# scripts/entity/unit_entity.gd
extends CharacterBody2D
class_name UnitEntity

var entity_data: UnitData
var current_health: int
var move_speed: float

func initialize(data: UnitData):
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

## 🎯 9. 실전 활용 예시

### 9.1. 건물 건설 시스템

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

### 9.2. 유닛 생성 시스템

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

### 9.3. NPC 배치 시스템

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

### 9.4. 저장/로드 시스템

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

## 🚀 10. 고급 패턴

### 10.1. Resource 상속 (데이터 재사용)

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

### 10.2. 동적 데이터 로드 (모딩 지원)

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

### 10.3. 데이터 검증 시스템

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

## 🐛 11. 트러블슈팅

### 문제 1: 텍스처가 안 보임

**증상:**
```
[BuildingEntity] initialize() 호출됨: 주택
(텍스처 설정 로그 없음)
```

**원인**: BuildingData의 `sprite_texture`가 null

**해결:**
1. .tres 파일 열기
2. Inspector → Visuals → Sprite Texture
3. 이미지 파일 드래그

---

### 문제 2: 건물이 너무 큼/작음

**해결:**
1. .tres 파일 열기
2. Inspector → Visuals → Sprite Scale
3. 값 조정:
   - (1.0, 1.0) = 원본 크기
   - (0.5, 0.5) = 절반 크기
   - (2.0, 2.0) = 2배 크기

---

### 문제 3: Resource 로드 실패

**증상:**
```
Cannot load resource at path 'res://data/buildings/house_01.tres'
```

**원인**: 경로 오류

**해결:**
- ✅ `res://data/buildings/house_01.tres`
- ❌ `data/buildings/house_01.tres` (res:// 빠짐)

---

### 문제 4: Node는 Resource에 저장 불가

```gdscript
# ❌ 불가능
@export var sprite_node: Sprite2D  # Error!

# ✅ 가능
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2
```

**이유**: Resource는 직렬화 가능한 데이터만 저장 (Texture2D, int, Vector2 등)

**해결**: 속성을 분리해서 저장 (texture, scale, offset 등)

---

## 📊 12. 비교 및 베스트 프랙티스

### 12.1. Resource vs 다른 방식

#### Resource vs 하드코딩

| 항목 | 하드코딩 | Resource |
|------|---------|----------|
| 새 엔티티 추가 | 코드 수정 필요 | .tres 파일 생성 |
| 밸런스 조정 | 코드 재컴파일 | 에디터에서 수정 |
| 데이터 재사용 | 어려움 | 쉬움 (복사/상속) |
| 저장/로드 | 복잡함 | 간단함 (ID만) |
| 모딩 지원 | 불가능 | 가능 |

#### Resource vs JSON/CSV

| 항목 | JSON/CSV | Resource |
|------|----------|----------|
| 에디터 통합 | 없음 | ✅ Inspector에서 편집 |
| 타입 안정성 | 없음 | ✅ GDScript 타입 |
| 씬 참조 | 경로만 | ✅ 직접 드래그 |
| 유효성 검증 | 수동 | ✅ 자동 (_validate_property) |
| 파일 크기 | 작음 | 약간 큼 |

**결론:** 소규모 프로젝트는 Resource, 대규모 데이터는 JSON+Resource 하이브리드

### 12.2. 파일 구조 권장사항

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

### 12.3. 네이밍 컨벤션

**Resource 클래스:**
- `EntityData`, `BuildingData`, `UnitData` (접미사 `Data`)

**Resource 파일:**
- `house_01.tres`, `soldier_basic.tres` (소문자 + 언더스코어)

**ID 규칙:**
- `"house_01"`, `"unit_soldier_basic"` (타입 접두사 옵션)

### 12.4. 개발 순서

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

## ✅ 13. 장점 정리 (SOLID 원칙)

### 13.1. Single Responsibility (단일 책임)
- EntityData: 데이터만 담당
- BuildingEntity: 비주얼만 담당
- BuildingManager: 생성만 담당

### 13.2. Open/Closed (개방-폐쇄)
- 새 건물 추가 = .tres 파일만 생성 (코드 수정 불필요)
- 확장에는 열려있고, 수정에는 닫혀있음

### 13.3. Dependency Inversion (의존성 역전)
- 매니저는 Texture2D를 직접 다루지 않음
- BuildingData라는 추상화를 통해서만 접근

### 13.4. 실용적 이점

- ✅ **씬 1개만 관리** - 유지보수 쉬움
- ✅ **에디터에서 편집** - 코드 수정 없이 밸런스 조정
- ✅ **저장 시스템 호환** - Resource는 직렬화 가능
- ✅ **확장성** - 건물 100개 추가해도 코드 변경 없음
- ✅ **타입 안전** - BuildingData 타입으로 컴파일 타임 체크

### 13.5. 성능

- ✅ preload로 미리 로딩 (런타임 부하 없음)
- ✅ Resource 재사용 (메모리 효율적)

---

## 📋 14. 실전 체크리스트

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

## 📚 15. 참고 자료

### 15.1. 다른 엔진과 비교

#### Unity (Prefab + ScriptableObject)

```csharp
// Unity 방식 (유사)
[CreateAssetMenu]
public class BuildingData : ScriptableObject {
    public Sprite sprite;
    public Vector2 scale;
}

public class Building : MonoBehaviour {
    public void Initialize(BuildingData data) {
        spriteRenderer.sprite = data.sprite;
        transform.localScale = data.scale;
    }
}
```

#### Unreal (DataAsset + Blueprint)

```cpp
// Unreal 방식 (유사)
UCLASS(BlueprintType)
class UBuildingData : public UDataAsset {
    UPROPERTY(EditAnywhere)
    UTexture2D* Texture;

    UPROPERTY(EditAnywhere)
    FVector2D Scale;
};
```

**결론**: Godot의 Resource 시스템은 Unity의 ScriptableObject, Unreal의 DataAsset과 동일한 패턴입니다.

### 15.2. 관련 문서

- `docs/design/building_construction_system_design.md`: 건설 시스템 구체적 구현
- `docs/prd.md`: 전체 시스템 요구사항
- Godot 공식 문서:
  - [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)
  - [@export](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html)

---

## 🎯 16. 결론

**Resource 기반 엔티티 설계 패턴**은:

- ✅ SOLID 원칙을 준수하는 깔끔한 아키텍처
- ✅ 확장성과 유지보수성이 뛰어남
- ✅ 실무에서 검증된 패턴 (Unity, Unreal도 유사)
- ✅ Godot 철학과 완벽히 일치

### 핵심 기억

```
데이터 (Resource .tres)
   ↓
로직 (Factory)
   ↓
표현 (Entity Scene)
```

> **"씬은 표현, Resource는 데이터, Factory는 연결고리"**

**새 건물 추가 = .tres 파일 1개 생성 + Database에 1줄 추가**

코드 수정 없이 무한한 종류의 건물을 만들 수 있습니다! 🎉

---

**마지막 업데이트**: 2026-01-04
**문서 버전**: 2.0 (통합 버전)
