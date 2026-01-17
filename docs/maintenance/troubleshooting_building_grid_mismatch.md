# 건물 배치 Grid 좌표 불일치 문제 해결

## 문제 요약

**증상**: 건물을 배치할 때 시각적 위치와 Grid 등록 위치가 1칸 차이남

```
시각적 위치 (실제로 보이는 곳): (12, 1), (12, 2), (13, 1), (13, 2)
Grid 등록 위치 (grid_buildings):  (13, 1), (13, 2), (14, 1), (14, 2)
```

**결과**:
- Navigation mesh가 잘못된 위치에 생성
- 건물 겹침 방지가 제대로 작동하지 않음
- 클릭 감지 영역과 시각적 건물 위치 불일치

---

## 근본 원인

### Godot TileMapLayer의 아이소메트릭 좌표계

Godot의 TileMapLayer는 **표준 아이소메트릭 좌표계와 다른 방식**을 사용합니다.

| 방향 | 표준 아이소메트릭 | Godot TileMapLayer |
|------|------------------|-------------------|
| Grid X+1 | (+half_w, +half_h) 오른쪽 아래 | (+half_w, **-half_h**) 오른쪽 **위** |
| Grid Y+1 | (-half_w, +half_h) 왼쪽 아래 | (+half_w, +half_h) 오른쪽 아래 |

### 실제 로그로 확인

```
Grid (13, 1) → World (240.0, -88.0)
Grid (13, 2) → World (256.0, -80.0)  // Y+1: (+16, +8)
Grid (14, 1) → World (256.0, -96.0)  // X+1: (+16, -8)
Grid (14, 2) → World (272.0, -88.0)
```

기존 코드는 표준 아이소메트릭 공식을 사용했기 때문에, Godot 좌표계에서 1칸 차이가 발생했습니다.

---

## 수정 내용

### 1. `_calculate_center_offset()` - 바닥면 중심 오프셋

**파일**: `scripts/entity/building_entity.gd`

NxM 건물의 바닥면 중심까지의 오프셋 계산

```gdscript
# 이전 (표준 아이소메트릭)
var offset_x: float = (grid_size.x - grid_size.y) * half_w / 2.0
var offset_y: float = (grid_size.x + grid_size.y - 2) * half_h / 2.0

# 수정 (Godot TileMapLayer 좌표계)
var offset_x: float = (grid_size.x + grid_size.y - 2) * half_w / 2.0
var offset_y: float = (grid_size.y - grid_size.x) * half_h / 2.0
```

**계산 결과**:
| 건물 크기 | 이전 | 수정 |
|----------|------|------|
| 1x1 | (0, 0) | (0, 0) |
| 2x2 | (0, 8) | (16, 0) |
| 3x2 | (8, 12) | (24, -4) |
| 2x3 | (-8, 12) | (24, 4) |

### 2. `_update_collision_polygon()` - Collision 영역

**파일**: `scripts/entity/building_entity.gd`

NxM 건물의 외곽 다이아몬드 꼭지점 계산

```gdscript
# 이전 (잘못된 계산)
var top = Vector2(0, -half_h)
var right = Vector2(w * half_w, (w - 1) * half_h)
var bottom = Vector2((w - h) * half_w, (w + h - 1) * half_h)
var left = Vector2(-h * half_w, (h - 1) * half_h)

# 수정 (Godot 좌표계 기준)
# 북쪽: 타일 (w-1, 0)의 북쪽 꼭지점
var top = Vector2((w - 1) * half_w, -w * half_h)
# 동쪽: 타일 (w-1, h-1)의 동쪽 꼭지점
var right = Vector2((w + h - 1) * half_w, (h - w) * half_h)
# 남쪽: 타일 (0, h-1)의 남쪽 꼭지점
var bottom = Vector2((h - 1) * half_w, h * half_h)
# 서쪽: 타일 (0, 0)의 서쪽 꼭지점
var left = Vector2(-half_w, 0)
```

**2x2 건물 예시**:
| 꼭지점 | 이전 | 수정 |
|--------|------|------|
| top | (0, -8) | (16, -16) |
| right | (32, 8) | (48, 0) |
| bottom | (0, 24) | (16, 16) |
| left | (-32, 8) | (-16, 0) |

### 3. `GridSystem` 좌표 변환 - 글로벌/로컬 변환 추가

**파일**: `scripts/map/grid_system.gd`

TileMapLayer의 `map_to_local()` / `local_to_map()`은 **로컬 좌표**를 사용합니다. 글로벌 좌표 변환이 필요합니다.

```gdscript
# 이전 (글로벌/로컬 변환 누락)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
    return ground_layer.map_to_local(grid_pos)

func world_to_grid(world_pos: Vector2) -> Vector2i:
    return ground_layer.local_to_map(world_pos)

# 수정 (to_global / to_local 추가)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
    var local_pos: Vector2 = ground_layer.map_to_local(grid_pos)
    return ground_layer.to_global(local_pos)

func world_to_grid(world_pos: Vector2) -> Vector2i:
    var local_pos: Vector2 = ground_layer.to_local(world_pos)
    return ground_layer.local_to_map(local_pos)
```

---

## 검증 방법

### 디버그 라벨로 좌표 확인

`BuildingPreview`에서 마우스 좌표와 변환된 Grid 좌표를 실시간 표시:

```gdscript
debug_label.text = "Grid: %s | Mouse: %s | Expected: %s" % [
    current_grid_pos,
    mouse_world_pos,
    GridSystem.grid_to_world(current_grid_pos)
]
```

**정상 동작**: Mouse와 Expected 좌표가 타일 크기 범위 내에서 유사해야 함

### 빌딩 배치 로그 확인

```
[BuildingManager] 건물: 주택 | grid_pos: (12, 1) | world_pos: (224.0, -80.0)
[BuildingManager]   등록: Grid (12, 1) → World (224.0, -80.0)
[BuildingManager]   등록: Grid (12, 2) → World (240.0, -72.0)
[BuildingManager]   등록: Grid (13, 1) → World (240.0, -88.0)
[BuildingManager]   등록: Grid (13, 2) → World (256.0, -80.0)
```

**정상 동작**: 시각적으로 보이는 건물 위치와 Grid 등록 위치가 일치해야 함

---

## 교훈

1. **Godot의 좌표계를 먼저 확인하라**: Godot TileMapLayer의 아이소메트릭 좌표계는 표준과 다를 수 있음

2. **로그로 실제 값을 확인하라**: 공식이 맞다고 가정하지 말고, 실제 `grid_to_world` 반환값을 로그로 확인

3. **글로벌/로컬 좌표 변환에 주의하라**: TileMapLayer의 함수들은 로컬 좌표를 사용함

4. **단계별로 문제를 분리하라**:
   - 오프셋 없이 테스트 → 좌표 변환 문제인지 확인
   - Collision polygon과 스프라이트 분리 확인 → 어느 쪽 계산이 잘못됐는지 파악

---

## 관련 파일

- `scripts/entity/building_entity.gd` - center_offset, collision polygon 계산
- `scripts/ui/building_preview.gd` - 미리보기 렌더링
- `scripts/map/grid_system.gd` - 좌표 변환
- `scripts/managers/building_manager.gd` - 건물 생성 및 Grid 등록
