# 테스트 가이드

## 📁 디렉토리 구조

```
tests/
├── unit/                           # 단위 테스트
│   ├── test_grid_system.gd         # GridSystem 테스트
│   └── test_building_manager.gd    # BuildingManager 테스트
├── integration/                    # 통합 테스트 (추후)
│   └── test_building_construction.gd
└── README.md                       # 이 파일
```

---

## 🚀 빠른 시작

### 1. GUT 설치

**Godot 에디터에서:**
1. 상단 메뉴: **AssetLib** 클릭
2. 검색: **"GUT"**
3. **"Gut - Godot Unit Test"** → **Download** → **Install**
4. 설치 경로: `addons/gut/` (기본값)

**플러그인 활성화:**
1. **프로젝트** → **프로젝트 설정** → **플러그인** 탭
2. **Gut** 체크박스 활성화

**⚠️ 중요: 에디터 통합 비활성화**

이 프로젝트는 GUT 에디터 통합을 비활성화하고 커맨드 라인으로 테스트를 실행합니다.
- `project.godot`에 `[gut]` 섹션과 `panel_button=0` 설정 추가됨
- Godot 4.5.1과의 호환성 문제 회피
- 에디터 패널 대신 **배치 파일** 또는 **커맨드 라인**으로 테스트 실행

### 2. 테스트 실행

**방법 1: 배치 파일 사용 (가장 간단) ⭐**

```bash
# 모든 테스트 실행
run_tests.bat

# GridSystem 테스트만
run_tests.bat grid

# BuildingManager 테스트만
run_tests.bat building
```

**방법 2: 직접 커맨드 라인 실행**

```bash
# Windows (Godot 4.5.1) - 모든 테스트
"C:\Users\udong\gamedev\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe" -d -s --path . addons/gut/gut_cmdln.gd

# 특정 테스트만 실행
"C:\Users\udong\gamedev\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe" -d -s --path . addons/gut/gut_cmdln.gd -gtest=tests/unit/test_grid_system.gd
```

---

## 📝 작성된 테스트

### test_grid_system.gd

**테스트 대상:** `GridSystem.is_valid_position(grid_pos, grid_size)`

**테스트 시나리오 (총 18개):**

#### 1x1 건물 (5개)
- ✅ `test_valid_position_1x1_inside_map` - 맵 중앙 유효 위치
- ✅ `test_invalid_position_1x1_outside_map_negative` - 음수 좌표
- ✅ `test_invalid_position_1x1_outside_map_too_large` - 맵 범위 초과
- ✅ `test_valid_position_1x1_corner` - 맵 모서리 (0, 0)
- ✅ `test_valid_position_1x1_bottom_right` - 맵 오른쪽 아래 (9, 9)

#### 2x2 건물 (4개)
- ✅ `test_valid_position_2x2_inside_map` - 맵 안 유효 위치
- ✅ `test_invalid_position_2x2_partial_outside` - 일부만 맵 안
- ✅ `test_valid_position_2x2_corner` - 맵 모서리
- ✅ `test_valid_position_2x2_max_valid_position` - 최대 유효 위치 (8, 8)

#### 3x3 건물 (3개)
- ✅ `test_valid_position_3x3_inside_map` - 맵 안 유효 위치
- ✅ `test_invalid_position_3x3_outside_map` - 맵 범위 초과
- ✅ `test_valid_position_3x3_max_valid_position` - 최대 유효 위치 (7, 7)

#### 경계 케이스 (3개)
- ✅ `test_invalid_position_empty_tile` - 빈 타일
- ✅ `test_invalid_position_grid_system_not_initialized` - 초기화 안 됨
- ✅ `test_valid_position_with_default_grid_size` - 기본값 파라미터

---

### test_building_manager.gd

**테스트 대상:** `BuildingManager.can_build_at()`, `create_building()`

**테스트 시나리오 (총 17개):**

#### can_build_at() - 정상 케이스 (3개)
- ✅ `test_can_build_at_valid_position_1x1` - 1x1 건물 유효 위치
- ✅ `test_can_build_at_valid_position_2x2` - 2x2 건물 유효 위치
- ✅ `test_can_build_at_valid_position_3x3` - 3x3 건물 유효 위치

#### can_build_at() - 맵 범위 초과 (3개)
- ✅ `test_can_build_at_outside_map_1x1` - 맵 밖 위치
- ✅ `test_can_build_at_outside_map_2x2_partial` - 2x2 일부만 맵 안
- ✅ `test_can_build_at_negative_position` - 음수 좌표

#### can_build_at() - 건물 중복 (3개)
- ✅ `test_can_build_at_overlapping_building_1x1` - 1x1 건물 중복
- ✅ `test_can_build_at_overlapping_building_2x2` - 2x2 건물과 겹침
- ✅ `test_can_build_at_adjacent_building` - 인접 위치 (성공)

#### can_build_at() - null 체크 (1개)
- ✅ `test_can_build_at_null_building_data` - null building_data

#### create_building() - 통합 테스트 (4개)
- ✅ `test_create_building_success` - 정상 생성
- ✅ `test_create_building_failure_outside_map` - 맵 밖 실패
- ✅ `test_create_building_failure_overlapping` - 중복 실패
- ✅ `test_create_building_2x2_occupies_all_tiles` - 2x2 영역 차지

#### 시그널 테스트 (2개)
- ✅ `test_signal_building_placed_emitted` - building_placed 시그널
- ✅ `test_signal_building_placement_failed_emitted` - building_placement_failed 시그널

---

## ⚠️ 중요 사항

### Autoload 의존성 문제

**BuildingManager**는 `GridSystem` Autoload에 의존합니다. 테스트에서 이 문제를 해결하는 방법:

**현재 구현 (임시):**
- 테스트에서 새로운 `GridSystemNode` 인스턴스 생성
- `BuildingManager`는 여전히 Autoload `GridSystem` 참조

**권장 해결책 (추후 리팩토링):**
1. **Dependency Injection**: `BuildingManager`에 `GridSystem`을 주입
2. **GUT의 Double 기능**: Autoload를 Mock으로 대체

```gdscript
# 예시: Dependency Injection
func initialize(parent_node: Node2D, grid_system_ref: GridSystemNode):
    buildings_parent = parent_node
    grid_system = grid_system_ref  # 주입받은 GridSystem 사용
```

### project.godot 설정 필요

현재 테스트가 정상 동작하려면 **GridSystem Autoload**가 설정되어 있어야 합니다.

**project.godot:**
```ini
[autoload]
GridSystem="*res://scripts/map/grid_system.gd"
BuildingManager="*res://scripts/managers/building_manager.gd"
```

---

## 📊 테스트 커버리지

| 모듈 | 테스트 개수 | 커버리지 항목 |
|------|------------|--------------|
| GridSystem | 18개 | `is_valid_position()` - 맵 범위, 건물 크기, 경계 케이스 |
| BuildingManager | 17개 | `can_build_at()`, `create_building()`, 시그널 |
| **합계** | **35개** | 위치 검증 로직 완전 커버 |

---

## 🔧 문제 해결

### 테스트가 실패하는 경우

**1. GUT 패널이 안 보임**
- 플러그인 활성화 확인: **프로젝트** → **프로젝트 설정** → **플러그인**

**2. "GridSystem Autoload not found" 에러**
- `project.godot`에 GridSystem Autoload 추가 확인

**3. "BuildingEntity scene not found" 에러**
- `res://scenes/entitys/building_entity.tscn` 파일 존재 확인

**4. Mock 데이터 생성 실패**
- `BuildingData.gd`가 올바르게 로드되는지 확인

---

## 📚 추가 자료

- **GUT GitHub**: https://github.com/bitwes/Gut
- **GUT 문서**: https://github.com/bitwes/Gut/wiki
- **프로젝트 테스트 가이드**: `../docs/implementation/testing_guide.md`
