# Resource 기반 스프라이트 주입 시스템

## 📌 개요

Godot 4.5에서 **의존성 주입(Dependency Injection) 패턴**을 사용하여 단일 씬으로 다양한 외형을 가진 엔티티를 구현하는 방법입니다.

### 핵심 아이디어

- **Data (Resource)**: 엔티티가 "어떤 이미지"를 사용할지 정의
- **View (Scene)**: 이미지를 "어디에" 표시할지 정의
- **Controller (Manager)**: 씬을 생성하고 데이터를 주입

---

## 🎯 왜 이 방식을 사용하는가?

### 문제 상황

각 건물(주택, 농장, 상점)이 다른 이미지를 가져야 하는데, 어떻게 구현할까?

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

#### ✅ 올바른 접근: Resource 기반 의존성 주입

```
하나의 씬 (building_entity.tscn)
  +
Resource 파일들 (house_01.tres, farm_01.tres...)
  =
무한한 건물 종류!
```

**장점:**
- ✅ 씬 1개만 관리
- ✅ 새 건물 추가 = .tres 파일만 생성 (코드 수정 불필요)
- ✅ SOLID 원칙 준수
- ✅ 저장 시스템 호환

---

## 🏗️ 아키텍처 설계

### 전체 구조

```
[Resource Layer - 데이터]
  EntityData (베이스 클래스)
    ├─ sprite_texture: Texture2D
    ├─ sprite_scale: Vector2
    └─ sprite_offset: Vector2

  BuildingData (extends EntityData)
    ├─ cost_wood: int
    └─ category: Enum

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

[Database Layer - 중앙 관리]
  BuildingDatabase
    ├─ get_building_by_id("house_01")
    └─ get_all_buildings()
```

### 의존성 방향

```
BuildingManager (고수준)
    ↓ 의존
BuildingData (추상화)
    ↓
Texture2D (저수준 - Godot 내장)
```

**핵심**: 매니저는 Godot 내장 타입(Texture2D)을 직접 다루지 않고, BuildingData를 통해서만 접근합니다.

---

## 📝 구현 상세

### 1. EntityData (베이스 Resource)

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
```

**핵심 포인트:**
- `extends Resource` - 직렬화 가능 (저장 시스템 호환)
- `@export` - Inspector에서 편집 가능
- `@export_group` - Inspector 정리

---

### 2. BuildingData (건물 전용 Resource)

**파일**: `scripts/resources/building_data.gd`

```gdscript
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

---

### 3. BuildingEntity (View)

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

---

### 4. BuildingManager (Controller)

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

### 5. BuildingDatabase (중앙 관리)

**파일**: `scripts/config/building_database.gd`

```gdscript
class_name BuildingDatabase extends Node

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

# 모든 건물 목록
static func get_all_buildings() -> Array[BuildingData]:
    return BUILDINGS.duplicate()
```

---

## 🎮 사용 방법

### 1. .tres 파일 생성 (Godot 에디터)

1. FileSystem → `scripts/resources/` 우클릭
2. "Create New" → "Resource"
3. 타입: "BuildingData" 검색 → 선택
4. 이름: `house_01.tres`
5. Create

### 2. Inspector에서 데이터 입력

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

[BuildingData 전용]
- Cost Wood: 50
- Cost Stone: 30
- Cost Gold: 100
- Grid Size: (1, 1)
- Category: RESIDENTIAL
```

### 3. 코드에서 건물 생성

```gdscript
# 데이터 로드
var house_data = BuildingDatabase.get_building_by_id("house_01")

# 건물 생성 (의존성 주입!)
var building = BuildingManager.create_building(Vector2i(5, 5), house_data)

# 끝! BuildingEntity가 알아서 텍스처 설정함
```

---

## ✅ 장점

### 1. SOLID 원칙 준수

#### Single Responsibility (단일 책임)
- EntityData: 데이터만 담당
- BuildingEntity: 비주얼만 담당
- BuildingManager: 생성만 담당

#### Open/Closed (개방-폐쇄)
- 새 건물 추가 = .tres 파일만 생성 (코드 수정 불필요)
- 확장에는 열려있고, 수정에는 닫혀있음

#### Dependency Inversion (의존성 역전)
- 매니저는 Texture2D를 직접 다루지 않음
- BuildingData라는 추상화를 통해서만 접근

### 2. 실용적 이점

- ✅ **씬 1개만 관리** - 유지보수 쉬움
- ✅ **에디터에서 편집** - 코드 수정 없이 밸런스 조정
- ✅ **저장 시스템 호환** - Resource는 직렬화 가능
- ✅ **확장성** - 건물 100개 추가해도 코드 변경 없음
- ✅ **타입 안전** - BuildingData 타입으로 컴파일 타임 체크

### 3. 성능

- ✅ preload로 미리 로딩 (런타임 부하 없음)
- ✅ Resource 재사용 (메모리 효율적)

---

## ⚠️ 제약사항

### 1. Node는 Resource에 저장 불가

```gdscript
# ❌ 불가능
@export var sprite_node: Sprite2D  # Error!

# ✅ 가능
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2
```

**이유**: Resource는 직렬화 가능한 데이터만 저장 (Texture2D, int, Vector2 등)

**해결**: 속성을 분리해서 저장 (texture, scale, offset 등)

### 2. 속성 하나씩 추가해야 함

Sprite2D의 모든 속성을 자동으로 복사할 수 없고, 필요한 속성을 직접 추가해야 합니다.

**권장**: 자주 쓰는 속성만 추가
- sprite_texture (필수)
- sprite_scale (자주 씀)
- sprite_offset (가끔 씀)
- sprite_modulate (필요시)

---

## 🐛 트러블슈팅

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
Cannot load resource at path 'res://scripts/resources/house_01.tres'
```

**원인**: 경로 오류

**해결:**
- ✅ `res://scripts/resources/house_01.tres`
- ❌ `scripts/resources/house_01.tres` (res:// 빠짐)

---

## 📚 참고: 다른 엔진과 비교

### Unity (Prefab + ScriptableObject)

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

### Unreal (DataAsset + Blueprint)

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

---

## 🎯 결론

**Resource 기반 스프라이트 주입 시스템**은:
- ✅ SOLID 원칙을 준수하는 깔끔한 아키텍처
- ✅ 확장성과 유지보수성이 뛰어남
- ✅ 실무에서 검증된 패턴 (Unity, Unreal도 유사)
- ✅ Godot 철학과 완벽히 일치

**새 건물 추가 = .tres 파일 1개 생성 + Database에 1줄 추가**

코드 수정 없이 무한한 종류의 건물을 만들 수 있습니다! 🎉

---

## 📄 관련 문서

- `docs/resource_migration_plan.md` - Phase별 구현 가이드
- `docs/design/building_construction_system_design.md` - 건설 시스템 설계
- `docs/code_convention.md` - SOLID 원칙 및 코드 컨벤션
