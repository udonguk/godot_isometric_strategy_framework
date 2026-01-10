# 리팩토링 TODO 체크리스트

> **작성일**: 2026-01-03
> **분석 기준**: Godot 시니어 개발자 관점 + SOLID 원칙 + CLAUDE.md 프로젝트 규칙

---

## 📋 Phase 1: 핵심 문제 해결 (우선순위: 높음)

### ✔️ TODO-1: Autoload 접근 방식 통일

**문제:**
- `building_manager.gd:68`에서 `get_node("/root/GridSystem")` 사용
- `input_manager.gd:79`에서 직접 `GridSystem` 사용
- 같은 Autoload를 다른 방식으로 접근하여 불일치 발생

**영향 파일:**
- [x] `scripts/managers/building_manager.gd:68`
- [x] `scripts/managers/input_manager.gd:79, 68` (이미 올바르게 구현됨)

**작업 내용:**
```gdscript
# ❌ 수정 전 (building_manager.gd:68)
var grid_system = get_node("/root/GridSystem")
var world_pos: Vector2 = grid_system.grid_to_world(grid_pos)

# ✅ 수정 후
var world_pos: Vector2 = GridSystem.grid_to_world(grid_pos)
```

**참고:**
- CLAUDE.md의 "Autoload 싱글톤 접근 규칙" 섹션 참조
- `class_name`을 통한 타입 안전한 접근 권장

**예상 작업 시간:** 10분

---

### ✔️ TODO-2: 중복된 GridSystem 초기화 제거

**문제:**
- `main.gd:20`와 `test_map.gd:76` 양쪽에서 GridSystem 초기화
- `main.gd`는 하드코딩된 경로로 접근: `$test_map_Node2D/World/NavigationRegion2D/GroundTileMapLayer`
- 이중 초기화 또는 잘못된 레퍼런스로 인한 버그 가능성

**영향 파일:**
- [x] `scripts/main.gd:10-27`
- [x] `scripts/maps/test_map.gd:76`

**작업 내용:**

**Option 1 (권장): main.gd에서 초기화 제거** ✅ 선택됨
```gdscript
# main.gd - GridSystem 초기화 코드 전체 제거
# 각 맵 씬(test_map.gd)이 자신의 ground_layer로 초기화 담당
```

**Option 2: main.gd만 초기화 담당**
```gdscript
# test_map.gd에서 초기화 제거
# main.gd에서 자식 씬의 ground_layer를 찾아서 초기화
# (하지만 하드코딩 경로 문제 해결 필요)
```

**결정 사항:**
- [x] Option 1 선택
- [x] 선택한 방식으로 코드 수정
- [ ] 테스트: 게임 실행 시 GridSystem이 정상 초기화되는지 확인

**예상 작업 시간:** 20분

---

## 📋 Phase 2: 타입 안전성 개선 (우선순위: 중간)

### ✔️ TODO-3: SelectionManager 타입 힌트 추가

**문제:**
- `selected_building` 변수에 타입 힌트 없음
- 주석에 "순환 참조 방지"라고 되어 있지만, GDScript 4.x에서는 `class_name` 사용 가능

**영향 파일:**
- [x] `scripts/managers/selection_manager.gd:21`
- [x] `scripts/managers/selection_manager.gd:91` (`select_building` 메서드)
- [x] `scripts/managers/selection_manager.gd:119` (`get_selected_building` 메서드)

**작업 내용:**
```gdscript
# ❌ 수정 전
var selected_building = null  # BuildingEntity 타입 (순환 참조 방지)

func select_building(building) -> void:  # BuildingEntity 타입
	...

func get_selected_building():  # BuildingEntity 타입 반환
	...

# ✅ 수정 후
var selected_building: BuildingEntity = null

func select_building(building: BuildingEntity) -> void:
	...

func get_selected_building() -> BuildingEntity:
	...
```

**테스트:**
- [ ] InputManager에서 `select_building()` 호출 시 타입 체크
- [ ] Godot 에디터에서 스크립트 로드 시 타입 에러 없는지 확인

**예상 작업 시간:** 10분

---

## 📋 Phase 3: 코드 품질 개선 (우선순위: 중간-낮음)

### ✅ TODO-4: 에러 처리 일관성 개선

**문제:**
- `push_error`, `push_warning`, `print` 사용 기준이 명확하지 않음
- 로그 레벨에 대한 가이드라인 필요

**영향 파일:**
- [x] `scripts/map/grid_system.gd` (전체) - 검토 완료, 수정 불필요
- [x] `scripts/managers/building_manager.gd` (전체) - 검토 완료, 수정 불필요
- [x] `scripts/managers/input_manager.gd` (전체) - 검토 완료, 수정 불필요
- [x] `scripts/managers/selection_manager.gd` (전체) - 검토 완료, 수정 불필요

**작업 내용:**

**1단계: 에러 처리 가이드라인 수립** ✅ 완료
```markdown
## 에러 처리 가이드라인

- **push_error()**: 프로그램 실행 불가능한 치명적 오류
  - 예: 초기화 실패, 필수 노드 없음, null 참조

- **push_warning()**: 계속 실행 가능하지만 의도와 다른 동작
  - 예: 중복 건물 생성, 잘못된 타입, 범위 밖 좌표

- **print()**: 정상 동작 로그 (디버그 정보)
  - 예: 초기화 완료, 엔티티 생성, 상태 변경
```

**2단계: 기존 코드 검토 및 수정** ✅ 완료
- [x] `grid_system.gd`: 에러 처리 레벨 검토 - 이미 올바르게 구현됨
- [x] `building_manager.gd`: 에러 처리 레벨 검토 - 이미 올바르게 구현됨
- [x] `input_manager.gd`: 에러 처리 레벨 검토 - 이미 올바르게 구현됨
- [x] `selection_manager.gd`: 에러 처리 레벨 검토 - 이미 올바르게 구현됨

**검토 결과:**
모든 파일이 이미 에러 처리 가이드라인을 정확히 따르고 있어 추가 수정이 필요하지 않음:
- `push_error()`: 초기화 실패, 필수 참조 없음 등 치명적 오류에 올바르게 사용됨
- `push_warning()`: 중복 생성, 타입 불일치, 유효하지 않은 입력값 등에 올바르게 사용됨
- `print()`: 정상 동작 로그에 올바르게 사용됨

**3단계: 문서화** ✅ 완료
- [x] `../implementation/code_convention.md`에 에러 처리 가이드라인 추가 (5. 에러 처리 가이드라인 섹션)

**실제 작업 시간:** 30분

---

### ✅ TODO-5: Navigation 초기화 프레임 대기 검증

**문제:**
- `test_map.gd:79`에서 `await get_tree().physics_frame` 사용
- 왜 필요한지, 다른 방법은 없는지 검증 필요

**영향 파일:**
- [x] `scripts/maps/test_map.gd:78-82`

**작업 내용:**

**1단계: NavigationRegion2D 동작 방식 조사**
- [x] Godot 문서에서 NavigationRegion2D의 bake 타이밍 확인
- [x] NavigationServer2D가 맵을 등록하는 시점 확인

**2단계: 대안 검토**
```gdscript
# 현재 방식
await get_tree().physics_frame
GridSystem.cache_navigation_map()

# 대안 1: NavigationRegion2D의 시그널 사용
@onready var nav_region = $World/NavigationRegion2D
await nav_region.bake_finished  # 시그널이 있다면
GridSystem.cache_navigation_map()

# 대안 2: 여러 프레임 대기 (안정성)
await get_tree().process_frame
await get_tree().physics_frame
GridSystem.cache_navigation_map()
```

**3단계: 주석 추가**
```gdscript
# NavigationServer2D 업데이트 대기
# 이유: NavigationRegion2D가 씬에 추가된 직후에는 아직 NavigationServer에 등록되지 않음
# physics_frame 대기로 NavigationServer의 맵 등록 보장
await get_tree().physics_frame
```

**테스트:**
- [x] physics_frame 제거 후 동작 확인
- [x] process_frame으로 변경 후 동작 확인
- [x] 여러 프레임 대기 후 동작 확인

**예상 작업 시간:** 30분-1시간

---

### ✅ TODO-6: 미사용 테스트 코드 제거

**문제:**
- `test_map.gd`의 `_create_test_buildings()` 메서드 정의만 있고 호출 안 됨
- 미사용 코드가 프로덕션 코드에 혼재

**영향 파일:**
- [x] `scripts/maps/test_map.gd:99-124` (삭제 완료)

**작업 내용:**

**Option 1: 완전 제거 (권장)** ✅ 선택됨
```gdscript
# _create_test_buildings() 메서드 전체 삭제
```

**Option 2: 디버그 플래그로 조건부 호출**
```gdscript
func _ready() -> void:
	# ... 기존 코드 ...

	# 디버그 모드에서만 테스트 건물 생성
	if OS.is_debug_build() and GameConfig.DEBUG_CREATE_TEST_BUILDINGS:
		_create_test_buildings()
```

**결정 사항:**
- [x] Option 1 선택 (완전 제거)
- [x] `_create_test_buildings()` 메서드 및 섹션 헤더 삭제 완료

**실제 작업 시간:** 3분

---

### ✅ TODO-7: UnitEntity 코드 섹션 재배치

**문제:**
- 선택 인디케이터 메서드(`_update_selection_indicator`)가 파일 맨 끝(라인 286)에 위치
- BuildingEntity는 중간(라인 96)에 위치
- 코드 구조 일관성 부족

**영향 파일:**
- [x] `scripts/entity/unit_entity.gd:286-291`
- [x] `scripts/entity/building_entity.gd` (노드 참조 / 상태 변수 순서 수정)

**작업 내용:**

**권장 코드 섹션 순서:**
```gdscript
# 1. class_name 및 extends
# 2. 상태 정의 (enum State, enum Direction)
# 3. 노드 참조 (@onready)
# 4. 상태 변수 (current_state, grid_position, is_selected 등)
# 5. 생명주기 (_ready, _physics_process)
# 6. 상태별 처리 (_process_idle, _process_moving, _arrive_at_destination)
# 7. 공개 메서드 (move_to_grid, stop_movement)
# 8. 애니메이션 관련 (play_animation, get_direction_from_velocity 등)
# 9. 선택 인디케이터 (_update_selection_indicator) ← 여기로 이동!
# 10. 디버그 메서드 (_to_string)
```

**작업:**
- [x] `_update_selection_indicator` 메서드를 라인 165 근처(stop_movement 다음)로 이동
- [x] BuildingEntity도 동일한 구조로 맞춤 (노드 참조 → 상태 변수 순서로 수정)

**실제 작업 시간:** 5분

---

## 📊 작업 우선순위 요약

| Phase | TODO | 중요도 | 작업량 | 예상 시간 |
|-------|------|--------|--------|-----------|
| 1 | TODO-1: Autoload 접근 통일 | 높음 | 낮음 | 10분 |
| 1 | TODO-2: 중복 초기화 제거 | 높음 | 중간 | 20분 |
| 2 | TODO-3: 타입 힌트 추가 | 중간 | 낮음 | 10분 |
| 3 | TODO-4: 에러 처리 개선 | 중간 | 높음 | 1-2시간 |
| 3 | TODO-5: Navigation 검증 | 중간 | 중간 | 30분-1시간 |
| 3 | TODO-6: 미사용 코드 제거 | 낮음 | 낮음 | 5분 |
| 3 | TODO-7: 코드 재배치 | 낮음 | 낮음 | 10분 |

**총 예상 시간:** 3-5시간

---

## 🎯 권장 작업 순서

**1차 리팩토링 (필수):**
1. TODO-1 (Autoload 접근 통일)
2. TODO-2 (중복 초기화 제거)
3. TODO-3 (타입 힌트 추가)

**2차 리팩토링 (권장):**
4. TODO-6 (미사용 코드 제거)
5. TODO-7 (코드 재배치)

**3차 리팩토링 (선택):**
6. TODO-5 (Navigation 검증)
7. TODO-4 (에러 처리 개선)

---

## 📝 체크리스트 사용법

1. 각 TODO 항목의 체크박스를 진행하면서 체크
2. 작업 완료 후 전체 TODO 제목의 ✅를 ✔️로 변경
3. 모든 Phase 완료 시 이 문서를 `../maintenance/archive/`로 이동

---

## 🔗 관련 문서

- `../implementation/code_convention.md` - 코드 컨벤션 및 아키텍처
- `CLAUDE.md` - 프로젝트 개발 가이드
- `../design/tile_system_design.md` - UI/Logic 분리 원칙

---

**마지막 업데이트:** 2026-01-03
