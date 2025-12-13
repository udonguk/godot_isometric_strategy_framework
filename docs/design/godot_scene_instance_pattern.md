# Godot 씬 인스턴스 패턴 (Scene Instance Pattern)

## 1. 개요

Godot의 **씬 인스턴스(Scene Instance)** 시스템은 Unity의 Prefab과 유사하지만, 동작 방식이 다릅니다. 이 문서는 Godot 4.5+에서 씬 인스턴스를 효과적으로 사용하는 방법을 설명합니다.

## 2. Unity Prefab vs Godot Scene Instance

### Unity의 Prefab (참고용)

```
Prefab (원본)
├─ 인스턴스 1 (씬 A)
├─ 인스턴스 2 (씬 B)
└─ 인스턴스 3 (씬 C)

- 인스턴스 수정 후 "Apply to Prefab" 버튼으로 원본에 반영
- 양방향 동기화 가능
```

### Godot의 Scene Instance

```
Scene (원본/Factory)
├─ 인스턴스 1 (씬 A)
├─ 인스턴스 2 (씬 B)
└─ 인스턴스 3 (씬 C)

- 인스턴스에서 수정 → 그 씬에만 저장 (Override)
- "Apply to Prefab" 버튼 없음
- 단방향: 원본 수정 → 인스턴스에 자동 반영 (Override 제외)
```

### 핵심 차이점

| 항목 | Unity Prefab | Godot Scene Instance |
|------|-------------|---------------------|
| 양방향 동기화 | ✅ (Apply to Prefab) | ❌ (단방향만) |
| 인스턴스 → 원본 | 가능 | **불가능** |
| 원본 → 인스턴스 | 자동 | 자동 (Override 제외) |
| Override | 가능 | 가능 |
| 철학 | 중앙 관리 | **인스턴스 독립성** |

## 3. Godot 철학: "인스턴스는 독립적"

**Godot의 핵심 철학:**
> 인스턴스에서 수정한 것은 그 씬에만 저장된다 (Override)

**의미:**
- 각 인스턴스는 자신만의 특별한 설정을 가질 수 있음
- 원본(Factory)은 공통 기본값만 정의
- 인스턴스는 필요한 부분만 Override

## 4. Scene Instance 동작 메커니즘

### 4.1. 원본 씬 (Factory/Template)

```gdscript
# scenes/tiles/ground_tilemaplayer.tscn
[gd_scene load_steps=2 format=4 uid="uid://chfukxx3gn4tp"]

[ext_resource type="TileSet" path="res://scenes/tiles/ground_tileset.tres" id="1"]

[node name="GroundTileMapLayer" type="TileMapLayer"]
y_sort_enabled = true                    # 공통 설정
tile_set = ExtResource("1")              # 공통 설정
navigation_visibility_mode = 1           # 공통 설정
# tile_map_data 없음! (빈 템플릿)
```

**역할:**
- 공통 설정 정의 (TileSet, Navigation, Y-Sort 등)
- 빈 템플릿 (구체적인 데이터 없음)
- Factory 역할

### 4.2. 인스턴스 씬 (Instance + Override)

```gdscript
# scenes/maps/test_map.tscn
[gd_scene load_steps=2 format=4 uid="uid://xxx"]

[ext_resource type="PackedScene" uid="uid://chfukxx3gn4tp"
              path="res://scenes/tiles/ground_tilemaplayer.tscn" id="1_tile"]

[node name="TestMap" type="Node2D"]

[node name="GroundTileMapLayer" parent="." instance=ExtResource("1_tile")]
tile_map_data = PackedByteArray(...)     # Override! (이 맵만의 타일 배치)
```

**동작:**
1. `instance=ExtResource("1_tile")`: 원본 씬 인스턴스화
2. 원본의 모든 설정 상속 (y_sort, tile_set, navigation 등)
3. `tile_map_data` 추가 → **Override로 저장됨**
4. 원본에는 영향 없음

### 4.3. Override 시각화

**Godot 에디터에서 확인:**

```
Scene Tree:
TestMap (Node2D)
└─ GroundTileMapLayer [📦 인스턴스 아이콘]
    ↳ scenes/tiles/ground_tilemaplayer.tscn  ← 원본 경로 표시
```

**Inspector (속성 창):**
```
tile_set: ground_tileset.tres           (일반 글씨 - 상속)
y_sort_enabled: true                    (일반 글씨 - 상속)
tile_map_data: <데이터>  [↻]            (굵은 글씨 - Override)
                          └─ 되돌리기 버튼 (Override 취소)
```

**Override된 속성 특징:**
- 굵은 글씨로 표시
- 옆에 [↻] 되돌리기 버튼
- 원본 수정해도 이 값은 유지됨

## 5. 실제 사용 예시: TileMapLayer Factory

### 사용 시나리오

여러 맵에서 같은 TileSet과 Navigation 설정을 사용하지만, 타일 배치는 다르게 하고 싶음.

### Step 1: Factory 씬 생성

```
Godot 에디터:
1. Scene → New Scene
2. Other Node → TileMapLayer
3. Inspector 설정:
   - Tile Set: ground_tileset.tres
   - Y Sort Enabled: true
   - Navigation Visibility Mode: 1
4. 타일 배치하지 않음! (빈 상태 유지)
5. Save: scenes/tiles/ground_tilemaplayer.tscn
```

**결과 파일:**
```gdscript
[node name="GroundTileMapLayer" type="TileMapLayer"]
y_sort_enabled = true
tile_set = ExtResource("1_bf1m4")
navigation_visibility_mode = 1
# tile_map_data 없음 ← 중요!
```

### Step 2: 맵 씬에서 인스턴스화

```
Godot 에디터:
1. Scene → New Scene
2. Node2D 생성 (루트, 이름: TestMap)
3. TestMap 우클릭 → "Instantiate Child Scene"
4. ground_tilemaplayer.tscn 선택
5. 타일 배치 시작 (TileMap Editor 사용)
6. Save: scenes/maps/test_map.tscn
```

**결과 파일:**
```gdscript
[ext_resource type="PackedScene" path="res://scenes/tiles/ground_tilemaplayer.tscn" id="1"]

[node name="TestMap" type="Node2D"]

[node name="GroundTileMapLayer" parent="." instance=ExtResource("1")]
tile_map_data = PackedByteArray(...)  # 이 맵만의 타일!
```

### Step 3: 다른 맵 생성

```
Level 01 생성:
1. Step 2와 동일하게 진행
2. 다른 타일 배치
3. Save: scenes/maps/level_01.tscn
```

**결과:**
```
ground_tilemaplayer.tscn (Factory)
├─ test_map.tscn (타일 배치 A)
├─ level_01.tscn (타일 배치 B)
└─ level_02.tscn (타일 배치 C)

- Navigation 설정: 공유 (Factory에서)
- 타일 배치: 각 맵마다 다름 (Override)
```

## 6. 원본 수정 시 동작

### 시나리오: Navigation Layer 추가

**원본 수정:**
```gdscript
# ground_tilemaplayer.tscn
[node name="GroundTileMapLayer" type="TileMapLayer"]
y_sort_enabled = true
tile_set = ExtResource("1")
navigation_visibility_mode = 0  # 1 → 0 변경!
```

**모든 인스턴스에 자동 반영:**
```
test_map.tscn:     navigation_visibility_mode = 0 (자동 변경)
level_01.tscn:     navigation_visibility_mode = 0 (자동 변경)
level_02.tscn:     navigation_visibility_mode = 0 (자동 변경)
```

**단, Override된 속성은 유지:**
```
test_map.tscn:     tile_map_data = ... (변경 없음, Override)
level_01.tscn:     tile_map_data = ... (변경 없음, Override)
```

## 7. 주의사항

### ❌ 잘못된 사용

**Factory에 구체적인 데이터 포함:**
```gdscript
# ground_tilemaplayer.tscn (잘못됨!)
[node name="GroundTileMapLayer" type="TileMapLayer"]
tile_map_data = PackedByteArray(...)  # ← 문제!
```

**결과:**
- 모든 맵이 이 타일을 상속받음
- Override하려면 전체 데이터 덮어써야 함
- Factory 역할을 못 함

### ✅ 올바른 사용

**Factory는 빈 템플릿:**
```gdscript
# ground_tilemaplayer.tscn (올바름!)
[node name="GroundTileMapLayer" type="TileMapLayer"]
y_sort_enabled = true
tile_set = ExtResource("1")
# 공통 설정만, 구체적 데이터 없음
```

**인스턴스에서 데이터 추가:**
```gdscript
# test_map.tscn
[node name="GroundTileMapLayer" parent="." instance=ExtResource("1")]
tile_map_data = PackedByteArray(...)  # 여기서만!
```

## 8. Override 되돌리기

**Inspector에서 [↻] 버튼:**
```
tile_map_data: <값>  [↻ 클릭]
→ Override 취소
→ 원본 값으로 복원 (빈 값)
```

**코드로:**
```gdscript
# Override 제거 (원본으로 복원)
$GroundTileMapLayer.property_reset("tile_map_data")
```

## 9. 베스트 프랙티스

### ✅ Factory 설계 원칙

1. **공통 설정만 포함**
   - TileSet, Navigation Layer 설정
   - Y-Sort, Rendering 옵션
   - 공통 스크립트 연결

2. **구체적 데이터 제외**
   - 타일 배치 (tile_map_data)
   - 위치 (position)
   - 개별 속성 값

3. **재사용 가능하게**
   - 범용적으로 사용 가능한 구조
   - 특정 맵에 종속되지 않음

### ✅ 인스턴스 사용 원칙

1. **필요한 것만 Override**
   - 타일 배치만 Override
   - 나머지는 상속

2. **루트 노드 구조**
   ```
   Node2D (맵 루트)
   ├── TileMapLayer (인스턴스)
   ├── BuildingLayer
   └── UnitLayer
   ```

3. **명명 규칙**
   ```
   Factory: ground_tilemaplayer.tscn
   Instance: TestMap/GroundTileMapLayer
   ```

## 10. 다른 활용 예시

### 건물 Factory

```gdscript
# scenes/buildings/building.tscn (Factory)
[node name="Building" type="Sprite2D"]
script = "res://scripts/buildings/building.gd"
# 텍스처, 위치 등은 없음

# scenes/maps/test_map.tscn (Instance)
[node name="Building1" parent="." instance=ExtResource("building")]
position = Vector2(100, 200)  # Override
texture = ...                 # Override
```

### 적 유닛 Factory

```gdscript
# scenes/units/enemy.tscn (Factory)
[node name="Enemy" type="CharacterBody2D"]
script = "res://scripts/units/enemy.gd"
health = 100  # 기본 체력

# scenes/maps/level_01.tscn (Instance)
[node name="Enemy1" parent="." instance=ExtResource("enemy")]
health = 150  # Override (보스)
```

## 11. 요약

**Godot Scene Instance 패턴:**

```
원본(Factory) → 인스턴스들
- 공통 설정 정의
- 빈 템플릿
- 단방향 전파

인스턴스 → Override
- 필요한 부분만 수정
- 그 씬에만 저장
- 원본에 영향 없음
```

**핵심:**
1. Factory는 공통 설정만
2. 인스턴스는 구체적 데이터 Override
3. Unity의 "Apply to Prefab"은 없음
4. 단방향 전파만 지원

**장점:**
- 공통 설정 한 곳에서 관리
- 각 인스턴스의 독립성 보장
- 메모리 효율적
- 유연한 Override

**주의:**
- Factory에 구체적 데이터 넣지 말 것
- 양방향 동기화 불가능 인정
- Override 관리 주의
