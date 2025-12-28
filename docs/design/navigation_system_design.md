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

### Step 2: 장애물 (건물) 처리
**목표**: 유닛이 건물을 통과하지 못하게 방지.

1.  **TileSet 물리/내비게이션**:
    *   건물이 타일인 경우: 건물 타일에서 내비게이션 폴리곤 제거.
    *   건물이 씬(`BuildingEntity`)인 경우:
        *   건물 씬에 `NavigationObstacle2D` 노드 추가.
        *   건물의 바닥 면적(footprint)에 맞춰 버텍스 설정.
        *   **대안 (더 간단함)**: 건물을 배치할 때 바닥 TileMap의 내비게이션 데이터를 업데이트 (구멍 뚫기).
        *   *결정*: `BuildingEntity`를 씬으로 사용하므로 초기에는 `NavigationObstacle2D`(동적)를 사용하거나 해당 위치에 내비게이션 메쉬를 두지 않는 방식(정적 구멍)을 사용합니다.
        *   *초기 접근*: `NavigationAgent2D`의 `avoidance_enabled = true`를 설정하거나 단순히 장애물로 정의합니다. 정적인 타일 기반 게임에서는 건물 위치에 내비게이션 폴리곤을 **없애는** 것이 가장 쉽습니다.

### Step 3: 유닛 엔티티 생성
**목표**: 기본 이동이 가능한 유닛 생성.

1.  `scenes/entity/unit_entity.tscn` 생성.
2.  **루트 노드**: `CharacterBody2D` (부드러운 물리 상호작용).
    *   `CollisionShape2D` 추가 (원형 또는 캡슐).
    *   `Sprite2D` 추가 (유닛 비주얼).
    *   **`NavigationAgent2D`** 추가.
3.  **스크립트**: `scripts/entity/unit_entity.gd`.
    *   `func move_to(target_pos: Vector2)`
    *   `_physics_process`:
        *   다음 경로 위치 가져오기: `nav_agent.get_next_path_position()`.
        *   다음 지점을 향한 속도(velocity) 계산.
        *   `move_and_slide()`.

### Step 4: 입력 처리 (RTS 컨트롤러)
**목표**: 우클릭으로 유닛 이동.

1.  `main.gd` 업데이트 또는 새로운 `UnitManager` 생성.
    *   마우스 우클릭 감지.
    *   마우스 위치를 월드 좌표로 변환 (`GridSystem` 사용 또는 2D이므로 `get_global_mouse_position()` 바로 사용 가능).
    *   선택된 유닛들에게 `move_to(target)` 호출.

---

## 📝 상세 작업 (Sprint Backlog)

- [ ] **Task 1**: `ground_tileset.tres`에 Navigation Layer를 추가하고 그라운드 타일에 폴리곤 그리기.
- [ ] **Task 2**: `NavigationAgent2D`를 포함한 `UnitEntity` 씬 생성.
- [ ] **Task 3**: `UnitEntity`에 기본 `move_to` 로직 구현.
- [ ] **Task 4**: `test_map.tscn`에 테스트 유닛 스폰.
- [ ] **Task 5**: `main.gd`에 우클릭 이동 구현.
- [ ] **Task 6**: 건물 주변 내비게이션 검증 (건물을 배치하고 그 옆을 지나가게 해보기).

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