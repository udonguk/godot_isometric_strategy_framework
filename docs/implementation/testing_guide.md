# 테스트 가이드 (GUT Framework)

## GUT (Godot Unit Test) 프레임워크

Godot에서 단위 테스트를 작성하기 위한 프레임워크입니다.

## 설치 방법

### 1. Godot Asset Library에서 설치

1. Godot 에디터 상단 메뉴: **AssetLib** 클릭
2. 검색창에 **"GUT"** 입력
3. **"Gut - Godot Unit Test"** 선택
4. **Download** → **Install** 클릭
5. 설치 경로: `addons/gut/` (기본값 사용)

### 2. 수동 설치 (대안)

```bash
# GitHub에서 다운로드
git clone https://github.com/bitwes/Gut.git
# 또는 릴리스 다운로드
# https://github.com/bitwes/Gut/releases

# addons/ 폴더에 복사
mkdir -p addons
cp -r Gut/addons/gut addons/
```

### 3. 플러그인 활성화

1. Godot 에디터: **프로젝트** → **프로젝트 설정** → **플러그인** 탭
2. **Gut** 플러그인 체크박스 활성화
3. 에디터 하단에 **GUT** 패널이 나타남

---

## 프로젝트 구조

```
isometric-strategy-framework/
├── addons/
│   └── gut/                    # GUT 프레임워크
├── tests/
│   ├── unit/                   # 단위 테스트
│   │   ├── test_grid_system.gd
│   │   └── test_building_manager.gd
│   └── integration/            # 통합 테스트 (추후)
│       └── test_building_construction.gd
└── .gutconfig.json             # GUT 설정 파일
```

---

## 테스트 실행 방법

### 방법 1: Godot 에디터에서 실행

1. 에디터 하단 **GUT** 패널 열기
2. **Run All** 버튼 클릭
3. 테스트 결과 확인

### 방법 2: 커맨드 라인에서 실행

```bash
# Windows
"C:\Users\udong\gamedev\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe" -d -s --path . addons/gut/gut_cmdln.gd

# 특정 테스트만 실행
godot -d -s --path . addons/gut/gut_cmdln.gd -gtest=tests/unit/test_grid_system.gd
```

---

## 테스트 작성 규칙

### 1. 파일명 규칙
- 테스트 파일: `test_*.gd` (예: `test_grid_system.gd`)
- 클래스명: `Test*` (예: `TestGridSystem`)

### 2. 테스트 메서드 규칙
- 메서드명: `test_*` (예: `test_valid_position_1x1()`)
- GUT가 자동으로 인식하여 실행

### 3. Assertion 메서드

```gdscript
# 기본 검증
assert_true(value, message)
assert_false(value, message)
assert_eq(got, expected, message)
assert_ne(got, expected, message)
assert_null(value, message)
assert_not_null(value, message)

# 숫자 비교
assert_gt(got, expected, message)  # greater than
assert_lt(got, expected, message)  # less than
assert_between(value, min, max, message)

# 배열/딕셔너리
assert_has(container, key, message)
assert_does_not_have(container, key, message)
```

### 4. 테스트 생명주기

```gdscript
func before_all():
    # 모든 테스트 전에 한 번 실행

func before_each():
    # 각 테스트 전에 실행

func after_each():
    # 각 테스트 후에 실행

func after_all():
    # 모든 테스트 후에 한 번 실행
```

---

## 예제 테스트 구조

```gdscript
extends GutTest

var grid_system: GridSystemNode

func before_each():
    # 테스트 환경 초기화
    grid_system = GridSystemNode.new()
    add_child(grid_system)

func after_each():
    # 정리
    grid_system.queue_free()

func test_valid_position_1x1():
    # Given (준비)
    var grid_pos = Vector2i(5, 5)
    var grid_size = Vector2i(1, 1)

    # When (실행)
    var result = grid_system.is_valid_position(grid_pos, grid_size)

    # Then (검증)
    assert_true(result, "1x1 건물은 맵 안에 배치 가능해야 함")
```

---

## 참고 자료

- **GUT GitHub**: https://github.com/bitwes/Gut
- **GUT 문서**: https://github.com/bitwes/Gut/wiki
- **예제**: https://github.com/bitwes/Gut/tree/master/test/samples
