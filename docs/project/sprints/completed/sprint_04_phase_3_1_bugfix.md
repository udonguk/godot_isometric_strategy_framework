# Sprint 04 Phase 3.1 버그 수정: 건설 UI 미작동 문제

## 📋 현재 상태

### 증상
- 주택 버튼 클릭 시 아무 일도 일어나지 않음
- 콘솔 에러: `[ConstructionMenu] BuildingManager가 초기화되지 않았습니다`
- `building_manager`가 null 상태

### 근본 원인

#### 1. 아키텍처 문제
```
main (Node2D)
├── test_map_Node2D
│   └── building_manager (여기서 생성) ← 문제!
└── UILayer (CanvasLayer)
    └── ConstructionMenu
        └── building_manager 참조 필요 ← 형제의 자식을 참조 (계층 위반)
```

**문제점:**
- ConstructionMenu(UILayer의 자식)가 test_map의 자식인 building_manager를 참조
- 계층 구조 위반 (형제의 자식을 참조)
- Flux 패턴 위반 (Store가 View보다 하위)

#### 2. 초기화 타이밍 문제
```gdscript
# test_map.gd _ready()
await _initialize_systems()  # BuildingManager 생성

# main.gd _ready()
await test_map.ready  # ready 신호는 await 이전에 발생!
# 이 시점에 test_map.building_manager는 아직 null
```

Godot의 `ready` 신호는 `_ready()` 함수의 **첫 await 이전**에 발생하므로 타이밍 이슈 발생.

#### 3. BuildingDatabase Autoload 문제
- `class_name BuildingDatabase`와 Autoload 이름 충돌
- `static` 함수를 인스턴스 메서드로 변경 필요

---

## 🔧 해결 방안

### ✅ 최종 결정: BuildingManager를 Autoload로 변경

#### 이유
1. **Godot 철학**: Manager 클래스는 Autoload가 표준
2. **일관성**: 다른 매니저(Input, Selection)와 동일한 패턴
3. **Flux 패턴**: Store는 전역 또는 최상위에 위치
4. **문제 해결**: 초기화 타이밍, 계층 구조 문제 모두 해결

#### Autoload 기준 (Godot)
- ✅ GameConfig: 전역 설정
- ✅ GridSystem: 좌표 시스템
- ✅ SelectionManager: 선택 상태
- ✅ InputManager: 입력 관리
- ✅ BuildingDatabase: 건물 데이터
- ✅ **BuildingManager: 건물 상태 관리** ← 추가

**총 6개 Autoload** (Godot에서 적절한 수준)

---

## 📝 구현 단계

### Phase 1: BuildingManager Autoload 등록 ✅ (이미 완료)

1. **project.godot 수정**
```ini
[autoload]
BuildingManager="*res://scripts/managers/building_manager.gd"
```

2. **building_manager.gd 수정**
```gdscript
extends Node
# class_name 제거 (Autoload 충돌 방지)
```

### Phase 2: test_map.gd 수정 (다음 세션)

**파일**: `scripts/maps/test_map.gd`

**수정 사항:**
```gdscript
# 1. building_manager 변수 선언 제거
# var building_manager: BuildingManager = null  ← 삭제

# 2. _initialize_systems() 수정
func _initialize_systems() -> void:
    GridSystem.initialize(ground_layer)
    await _wait_for_navigation_registration()
    GridSystem.cache_navigation_map()

    # BuildingManager는 이미 Autoload로 존재
    # 맵에 맞게 초기화만 수행
    BuildingManager.initialize(entities_container, null, navigation_region)

# 3. _test_resource_based_buildings() 수정
func _test_resource_based_buildings() -> void:
    # BuildingManager.create_building() 직접 호출
    var house_data = BuildingDatabase.get_building_by_id("house_01")
    if house_data:
        BuildingManager.create_building(Vector2i(3, 3), house_data)
```

### Phase 3: main.gd 수정 (다음 세션)

**파일**: `scripts/main.gd`

**수정 사항:**
```gdscript
extends Node2D

@onready var test_map = $test_map_Node2D
@onready var construction_menu = $UILayer/ConstructionMenu

func _ready() -> void:
    print("[Main] 게임 시작")

    # test_map 초기화 대기 (BuildingManager는 Autoload이므로 대기 불필요)
    await test_map.ready

    # ConstructionMenu 초기화 (Autoload 직접 전달)
    construction_menu.initialize(BuildingManager)
    print("[Main] ConstructionMenu 초기화 완료")
```

**핵심 변경:**
- `test_map.building_manager` → `BuildingManager` (Autoload)
- 초기화 타이밍 문제 해결 (Autoload는 항상 존재)

### Phase 4: construction_menu.gd 수정 (다음 세션)

**파일**: `scripts/ui/construction_menu.gd`

**현재 코드 (98줄):**
```gdscript
building_manager = manager  # 올바름
```

**변경 불필요** - 이미 올바르게 작성됨

### Phase 5: 디버그 로그 제거 (다음 세션)

테스트 완료 후 추가한 디버그 로그 제거:
- `main.gd`: 23-40줄
- `construction_menu.gd`: 91-92, 99, 159, 163, 165, 168, 172줄
- `test_map.gd`: 200, 203-213줄

---

## 🧪 테스트 시나리오

### 1. 게임 시작 테스트
```
[Main] 게임 시작
[TestMap] 테스트 맵 초기화
[BuildingManager] 초기화 완료
[TestMap] house_01 로드 성공: 주택  ← BuildingDatabase 작동
[Main] ConstructionMenu 초기화 완료  ← 초기화 성공
```

### 2. 건설 모드 테스트
```
1. 주택 버튼 클릭
   → [ConstructionMenu] 주택 건설 모드 시작
   → [BuildingManager] 건설 모드 시작: 주택
   → [InputManager] 건설 모드 활성 - 입력 통과

2. 맵 클릭
   → [BuildingManager] 건물 생성 (Resource): 주택 at Grid (10, 10)
   → [TestMap] 건물 배치 성공: (10, 10)
   → 화면에 건물 표시

3. ESC 키
   → [BuildingManager] 건설 모드 취소
   → 건설 모드 종료
```

### 3. 다중 건물 테스트
- 주택, 농장, 상점 각각 배치
- 중복 위치 배치 시 에러 메시지
- 맵 범위 밖 배치 시 에러 메시지

---

## 📁 수정 파일 목록

### 이미 수정된 파일 (현재 세션)
1. ✅ `project.godot` - BuildingDatabase Autoload 추가
2. ✅ `scripts/config/building_database.gd` - class_name 제거, static 제거
3. ✅ `scripts/managers/input_manager.gd` - 건설 모드 플래그 추가
4. ✅ `scripts/managers/building_manager.gd` - InputManager 플래그 설정 추가

### 다음 세션에서 수정할 파일
1. ⏳ `project.godot` - BuildingManager Autoload 추가
2. ⏳ `scripts/managers/building_manager.gd` - class_name 제거
3. ⏳ `scripts/maps/test_map.gd` - building_manager 변수 제거, Autoload 사용
4. ⏳ `scripts/main.gd` - Autoload 직접 전달
5. ⏳ 디버그 로그 제거 (main.gd, construction_menu.gd, test_map.gd)

---

## 🎯 다음 세션 시작 방법

### 1. 현재 상태 확인
```bash
# project.godot에 BuildingDatabase Autoload 등록되어 있는지 확인
grep "BuildingDatabase" project.godot
```

### 2. BuildingManager Autoload 등록
```ini
# project.godot [autoload] 섹션에 추가
BuildingManager="*res://scripts/managers/building_manager.gd"
```

### 3. 순서대로 파일 수정
- building_manager.gd → test_map.gd → main.gd → 테스트

---

## 📖 관련 문서

- `docs/implementation/godot_autoload_guidelines.md` - Autoload 사용 가이드
- `docs/implementation/godot_flux_pattern.md` - Godot Flux 패턴 가이드
- `docs/project/sprints/sprint_04_building_system.md` - 원래 Sprint 문서

---

## 🎓 교훈

### Godot vs React
- **React**: "전역 상태를 피하라, Props로 전달하라"
- **Godot**: "Autoload를 사용하라, 시그널로 통신하라"

### Manager 패턴
- Godot에서 `XxxManager` 클래스는 **항상 Autoload**
- 게임 전역에서 사용되는 상태/기능은 Autoload가 적절
- 계층 구조보다 **기능적 역할**이 우선

### 초기화 순서
- `ready` 신호는 `_ready()` 첫 `await` **이전**에 발생
- 자식 노드의 초기화를 기다려야 할 때는 커스텀 시그널 사용
- Autoload는 항상 존재하므로 초기화 순서 문제 없음
