# Navigation 시스템 문제 해결 기록

## 📋 목표

유닛이 건물을 자동으로 피해서 이동하도록 Navigation 시스템 구현

---

## ✅ 완료된 작업

### 1. InputManager 구현 (성공)
- **상태**: ✅ 완료 및 정상 작동
- **구현 내용**:
  - 중앙 컨트롤러 패턴 기반 입력 시스템
  - Physics Query를 통한 클릭 우선순위 처리 (유닛 > 건물 > 땅)
  - SelectionManager와 연동한 선택/해제
  - 우클릭 이동 명령 구현
- **결과**: 유닛/건물 선택 및 이동 명령 정상 작동

### 2. BuildingEntity 구조 설정
- **완료 항목**:
  - `class_name BuildingEntity` 추가
  - Area2D + CollisionPolygon2D (클릭 감지) - Layer 3
  - StaticBody2D + CollisionPolygon2D (물리 충돌) - Layer 3
  - `navigation_obstacle` 그룹 등록

### 3. Scene 구조 변경
- **변경 전**:
  ```
  World
  ├─ GroundTileMapLayer
  ├─ StructuresTileMapLayer
  └─ Entities
  ```

- **변경 후**:
  ```
  World
  └─ NavigationRegion2D
     ├─ GroundTileMapLayer
     └─ StructuresTileMapLayer
  └─ Entities
  ```

- **경로 수정**: `test_map.gd`의 노드 참조 경로 업데이트

---

## ❌ 시도했으나 실패한 방법들

### 시도 1: NavigationObstacle2D 사용
- **시도**: BuildingEntity에 NavigationObstacle2D 추가
- **결과**: ❌ 실패
- **이유**:
  - NavigationObstacle2D는 동적 회피(avoidance)용
  - Navigation Mesh 자체는 변경하지 않음
  - Visible Navigation에 여전히 건물 위치가 포함됨

### 시도 2: StaticBody2D만으로 해결
- **시도**: BuildingEntity에 StaticBody2D 추가
- **결과**: ⚠️ 부분 성공
- **장점**: 물리적으로 유닛이 건물을 통과하지 못함
- **단점**:
  - NavigationAgent2D가 건물을 지나가는 경로를 계산함
  - 유닛이 건물 앞에서 멈춰서 "갈 수 없는데 가려고 시도"
  - 길찾기가 망가짐

### 시도 3: NavigationRegion2D + Bake (현재 상태)
- **시도**: NavigationRegion2D로 Navigation Mesh Bake
- **설정**:
  ```
  NavigationPolygon:
    - parsed_geometry_type: STATIC_COLLIDERS
    - parsed_collision_mask: 4 (Layer 3 - buildings)
    - source_geometry_mode: GROUPS_WITH_FALLBACK
    - source_geometry_group_name: navigation_obstacle
  ```
- **결과**: ❌ 실패
- **디버그 로그**:
  ```
  [TestMap] 감지된 장애물 수: 24  ✅
  [TestMap] Polygons: 0  ❌
  ```
- **문제**:
  - BuildingEntity들은 감지되지만 Polygon이 생성되지 않음
  - Navigation Mesh가 비어있음

---

## 🔍 현재 문제 분석

### 핵심 문제: Polygon 0개

**원인 추정**:
1. **GroundTileMapLayer Navigation vs NavigationRegion2D 충돌**
   - TileMapLayer는 자체적으로 Navigation을 생성 (이미 작동 중)
   - NavigationRegion2D는 별도의 Navigation 생성 시도
   - 두 시스템이 충돌하여 Polygon 생성 실패

2. **Bake 원리 이해**:
   ```
   최종 Navigation Mesh = 이동 가능 영역 - 장애물
   ```
   - **이동 가능 영역**: GroundTileMapLayer의 Navigation Polygon
   - **장애물**: BuildingEntity의 StaticBody2D
   - 현재 상태: 장애물은 감지되지만, 빼낼 "이동 가능 영역"이 없음?

### 디버그 정보

**GroundTileMapLayer TileSet 확인**:
- `navigation_layer_0/layers = 1` ✅ 존재
- `0:0/0/navigation_layer_0/polygon = SubResource(...)` ✅ 타일 0:0에 Navigation Polygon 있음
- 모든 타일이 0:0으로 배치됨 → 모든 타일에 Navigation이 있어야 함

**BuildingEntity 확인**:
- `navigation_obstacle` 그룹 등록 ✅
- StaticBody2D collision_layer = 4 ✅
- 24개 감지됨 ✅

---

## 🚀 앞으로 시도할 방법

### 방법 1: TileMapLayer 자체 Navigation 사용 (권장)

**개념**:
- NavigationRegion2D 제거
- TileMapLayer의 자체 Navigation 활용
- 건물 위치의 Ground 타일을 런타임에 제거

**구현**:
```gdscript
# 건물 위치의 타일 제거
for obstacle in get_tree().get_nodes_in_group("navigation_obstacle"):
    var world_pos = obstacle.global_position
    var grid_pos = GridSystem.world_to_grid(world_pos)
    ground_layer.erase_cell(grid_pos)
```

**장점**:
- ✅ TileMapLayer가 자동으로 Navigation 업데이트
- ✅ Godot 내장 기능 활용
- ✅ Bake 불필요

**단점**:
- ⚠️ 건물 추가/삭제 시 타일 관리 필요
- ⚠️ 실시간 변경에 수동 처리

**우선순위**: ⭐⭐⭐⭐⭐ (가장 먼저 시도)

---

### 방법 2: NavigationRegion2D 설정 재검토

**시도할 설정**:
1. `Source Geometry Mode` 변경:
   - `ROOT_NODE_CHILDREN` 시도
   - `GROUPS_EXPLICIT` 시도

2. `Agent Radius` 조정:
   - 현재: 기본값
   - 시도: 8.0, 16.0 등

3. `Cell Size` 조정:
   - TileMapLayer의 타일 크기와 일치시키기

4. `Parse Layers` 확인:
   - Navigation Layer 0 포함 여부

**우선순위**: ⭐⭐⭐

---

### 방법 3: 수동 NavigationPolygon 설정

**개념**:
- NavigationPolygon을 코드로 직접 생성
- 건물 위치를 제외한 영역을 수동으로 그림

**구현**:
```gdscript
var nav_poly = NavigationPolygon.new()

# 외곽 윤곽선 (전체 맵)
var outline = PackedVector2Array([
    Vector2(0, 0),
    Vector2(640, 0),
    Vector2(640, 320),
    Vector2(0, 320)
])
nav_poly.add_outline(outline)

# 건물 위치에 구멍 추가
for building in buildings:
    var hole = PackedVector2Array([...])
    nav_poly.add_outline(hole)

nav_poly.make_polygons_from_outlines()
nav_region.navigation_polygon = nav_poly
```

**우선순위**: ⭐⭐ (복잡함)

---

### 방법 4: NavigationServer2D 직접 사용

**개념**:
- NavigationServer2D API를 사용하여 수동으로 Navigation 관리
- Region, Map, Link 등을 직접 제어

**우선순위**: ⭐ (가장 복잡, 최후의 수단)

---

## 📊 다음 단계 우선순위

1. **[최우선] 방법 1 시도**: TileMapLayer 자체 Navigation + 타일 제거
2. **[차선] 방법 2 시도**: NavigationRegion2D 설정 변경
3. **[검토] Godot 버전 확인**: Navigation 시스템 버전별 차이 확인
4. **[최후] 방법 3-4**: 수동 구현

---

## 🔧 현재 코드 상태

### test_map.gd
- NavigationRegion2D 런타임 Bake 구현 ✅
- 디버그 로그 추가 ✅
- bake_finished 시그널 연결 ✅

### building_entity.gd
- `navigation_obstacle` 그룹 등록 ✅

### building_entity.tscn
- StaticBody2D 추가 ✅
- `affect_navigation_mesh = true` ✅ (사용자 추가)
- `carve_navigation_mesh = true` ✅ (사용자 추가)

---

## 📝 참고 자료

### Godot 4.x Navigation 시스템 원리

1. **TileMapLayer 방식**:
   - TileSet에 Navigation Layer 설정
   - 각 타일에 Navigation Polygon 그리기
   - TileMapLayer가 자동으로 NavigationServer2D에 등록

2. **NavigationRegion2D 방식**:
   - NavigationPolygon 리소스에 영역 정의
   - Bake를 통해 장애물 제외
   - 수동 관리 필요

3. **혼용 시 문제**:
   - 두 방식이 충돌할 수 있음
   - 하나만 선택해야 함

---

## 🎯 예상 해결책

**최종 권장 방법**:
```gdscript
# 1. NavigationRegion2D 제거 (또는 비활성화)
# 2. TileMapLayer 자체 Navigation 사용
# 3. 건물 위치 타일 제거로 Navigation 구멍 생성

func _ready():
    # ... 기존 초기화 ...

    # 건물 로드 완료 대기
    await get_tree().process_frame
    await get_tree().process_frame

    # 건물 위치 타일 제거
    for building in get_tree().get_nodes_in_group("navigation_obstacle"):
        var grid_pos = GridSystem.world_to_grid(building.global_position)
        ground_layer.erase_cell(grid_pos)

    # NavigationServer 업데이트 대기
    await get_tree().physics_frame
```

---

**작성일**: 2025-12-29
**상태**: 진행 중
**다음 작업**: 방법 1 구현 및 테스트
