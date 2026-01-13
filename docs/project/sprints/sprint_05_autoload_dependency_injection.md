# Sprint 05: Autoload 의존성 주입 리팩토링

**관련 설계 문서:** `../../implementation/architecture_guidelines.md` 섹션 3.3.3 "Autoload와 테스트 가능성"

## 🎯 Sprint 목표

**핵심**: BuildingManager를 하이브리드 의존성 주입 패턴으로 리팩토링하여 단위 테스트 가능하게 만들기

**배경:**
- 현재 BuildingManager가 GridSystem Autoload를 직접 참조
- 단위 테스트 작성 시 Mock GridSystem 주입 불가능
- 테스트 실패: "ground_layer가 초기화되지 않았습니다!" 에러 발생

**목표:**
1. BuildingManager에 하이브리드 의존성 주입 패턴 적용
2. 실제 게임: Autoload 편의성 유지
3. 테스트: Mock GridSystem 주입으로 단위 테스트 가능

**범위:**
- ✅ BuildingManager 리팩토링 (전략 2: 하이브리드)
- ✅ 테스트 코드 수정
- ❌ GridSystem은 Autoload로 유지 (전략 1: 리팩토링 불필요)

---

## 📋 리팩토링 전략

### 전략 선택: 하이브리드 접근 (전략 2)

**이유:**
- ✅ BuildingManager는 복잡한 비즈니스 로직 보유
- ✅ 상태 관리 필요 (grid_buildings Dictionary)
- ✅ 단위 테스트 중요성 높음
- ✅ 실제 게임의 Autoload 편의성 유지

**목표 구조:**
```gdscript
# building_manager.gd
var grid_system_ref: GridSystemNode = null

func initialize(parent_node: Node2D, grid_system: GridSystemNode = null):
    buildings_parent = parent_node
    # 의존성 주입: grid_system이 있으면 사용, 없으면 Autoload
    grid_system_ref = grid_system if grid_system else GridSystem

func can_build_at(...):
    # Autoload 직접 참조 대신 주입된 인스턴스 사용
    if not grid_system_ref.is_valid_position(...):
```

---

## 📋 개발 체크리스트

### Phase 1: BuildingManager 리팩토링 ✅

#### 1.1. 멤버 변수 추가
- [ ] `grid_system_ref: GridSystemNode` 멤버 변수 추가
- [ ] 주석으로 의존성 주입 의도 명시

#### 1.2. initialize() 메서드 수정
- [ ] `grid_system: GridSystemNode = null` 파라미터 추가
- [ ] 의존성 주입 로직 추가: `grid_system_ref = grid_system if grid_system else GridSystem`
- [ ] 주석으로 하이브리드 접근법 설명

#### 1.3. GridSystem 사용 코드 수정
- [ ] `can_build_at()`: `GridSystem.is_valid_position()` → `grid_system_ref.is_valid_position()`
- [ ] 기타 GridSystem 직접 참조 검색 및 수정

---

### Phase 2: 테스트 코드 수정

#### 2.1. test_building_manager.gd 수정
- [ ] `before_each()`에서 Mock GridSystem을 `building_manager.initialize()`에 주입
- [ ] 기존 코드:
  ```gdscript
  building_manager.initialize(entities_parent)
  ```
- [ ] 수정 코드:
  ```gdscript
  building_manager.initialize(entities_parent, grid_system)  # Mock 주입
  ```

#### 2.2. test_grid_system.gd 확인
- [ ] GridSystem은 Autoload로 유지하므로 테스트 코드 변경 불필요
- [ ] 단, 통합 테스트로 전환 고려 (선택사항)

---

### Phase 3: 실제 게임 코드 확인

#### 3.1. main.gd 또는 test_map.gd 확인
- [ ] BuildingManager 초기화 코드 검토
- [ ] 기존 코드가 그대로 작동하는지 확인 (Autoload 자동 사용)
- [ ] 선택적으로 명시적 전달 가능:
  ```gdscript
  # 옵션 1: 파라미터 생략 (Autoload 사용)
  BuildingManager.initialize(entities_parent)

  # 옵션 2: 명시적 전달
  BuildingManager.initialize(entities_parent, GridSystem)
  ```

---

### Phase 4: 테스트 실행 및 검증

#### 4.1. 단위 테스트 실행
- [ ] GUT로 `test_building_manager.gd` 실행
- [ ] 모든 테스트 통과 확인 (현재 27개 실패 → 0개 실패)
- [ ] 특히 다음 테스트 확인:
  - `test_can_build_at_valid_position_*`
  - `test_can_build_at_outside_map_*`
  - `test_signal_building_placed_emitted`

#### 4.2. 통합 테스트
- [ ] Godot 에디터에서 게임 실행 (F5)
- [ ] test_map.tscn에서 건물 배치 테스트
- [ ] 정상 작동 확인

---

## 🔍 상세 구현 가이드

### 1. BuildingManager 리팩토링 (Before/After)

#### Before (현재 코드)
```gdscript
# building_manager.gd

# ❌ GridSystem Autoload 직접 참조
func can_build_at(building_data: BuildingData, grid_pos: Vector2i) -> Dictionary:
    var grid_size: Vector2i = building_data.grid_size

    # ❌ Autoload 직접 호출 (테스트 불가능)
    if not GridSystem.is_valid_position(grid_pos, grid_size):
        return {"success": false, "reason": "맵 범위를 벗어났습니다"}
    # ...
```

#### After (리팩토링 후)
```gdscript
# building_manager.gd

# ============================================================
# 의존성
# ============================================================

## GridSystem 참조 (의존성 주입)
##
## ✅ 하이브리드 접근법:
## - 실제 게임: initialize() 호출 시 생략 → Autoload 자동 사용
## - 테스트: Mock GridSystem 주입 → 단위 테스트 가능
var grid_system_ref: GridSystemNode = null


# ============================================================
# 초기화
# ============================================================

## BuildingManager 초기화
##
## @param parent_node: 건물 엔티티가 추가될 부모 노드 (필수)
## @param grid_system: (선택) GridSystem 인스턴스. 생략 시 Autoload 사용
##
## 💡 설계 의도 (Dependency Injection - 하이브리드 접근):
## - 실제 게임에서는 grid_system 파라미터를 생략하면 Autoload가 자동으로 사용됨
## - 테스트에서는 Mock GridSystem을 주입하여 독립적인 단위 테스트 가능
## - 이 방식으로 Autoload의 편의성과 테스트 가능성을 모두 확보
##
## 예시:
##   # 실제 게임 (main.gd)
##   BuildingManager.initialize(entities_parent)  # Autoload 자동 사용
##
##   # 테스트 (test_building_manager.gd)
##   var mock_grid = GridSystemNode.new()
##   BuildingManager.initialize(entities_parent, mock_grid)  # Mock 주입
func initialize(parent_node: Node2D, grid_system: GridSystemNode = null) -> void:
    buildings_parent = parent_node

    # 의존성 주입 (Dependency Injection)
    # grid_system이 제공되면 사용, 없으면 Autoload 사용
    grid_system_ref = grid_system if grid_system else GridSystem

    print("[BuildingManager] 초기화 완료")


# ============================================================
# 건물 생성
# ============================================================

## 특정 위치에 건물을 건설할 수 있는지 검증
func can_build_at(building_data: BuildingData, grid_pos: Vector2i) -> Dictionary:
    if not building_data:
        return {"success": false, "reason": "건물 데이터가 없습니다"}

    var grid_size: Vector2i = building_data.grid_size

    # ✅ 주입된 GridSystem 인스턴스 사용 (Autoload 직접 참조 X)
    if not grid_system_ref.is_valid_position(grid_pos, grid_size):
        return {"success": false, "reason": "맵 범위를 벗어났습니다"}

    # 건물이 차지하는 모든 타일에 기존 건물이 있는지 확인
    for x in range(grid_size.x):
        for y in range(grid_size.y):
            var check_pos = grid_pos + Vector2i(x, y)
            if has_building(check_pos):
                return {"success": false, "reason": "이미 건물이 존재합니다 (Grid: %s)" % grid_system_ref.grid_to_string(check_pos)}

    return {"success": true, "reason": ""}
```

**주요 변경 사항:**
1. ✅ `grid_system_ref` 멤버 변수 추가
2. ✅ `initialize()` 메서드에 `grid_system` 선택적 파라미터 추가
3. ✅ `GridSystem` 직접 호출 → `grid_system_ref` 사용
4. ✅ 상세한 주석으로 설계 의도 명시

---

### 2. 테스트 코드 수정 (Before/After)

#### Before (현재 코드)
```gdscript
# test_building_manager.gd

func before_each():
    # GridSystem Mock 생성
    grid_system = GridSystemNode.new()
    add_child(grid_system)

    # Ground Layer 설정
    ground_layer = TileMapLayer.new()
    add_child(ground_layer)
    # ... TileSet 설정

    # GridSystem 초기화
    grid_system.initialize(ground_layer)

    # BuildingManager 생성
    building_manager = BuildingManagerScript.new()
    add_child(building_manager)

    entities_parent = Node2D.new()
    add_child(entities_parent)

    # ❌ GridSystem Mock을 주입하지 않음!
    building_manager.initialize(entities_parent)
    # → BuildingManager 내부에서 GridSystem Autoload 참조
    # → Autoload는 테스트 환경에서 초기화되지 않음
    # → 에러 발생!
```

#### After (수정 후)
```gdscript
# test_building_manager.gd

func before_each():
    # GridSystem Mock 생성
    grid_system = GridSystemNode.new()
    add_child(grid_system)

    # Ground Layer 설정
    ground_layer = TileMapLayer.new()
    add_child(ground_layer)
    # ... TileSet 설정

    # GridSystem 초기화
    grid_system.initialize(ground_layer)

    # BuildingManager 생성
    building_manager = BuildingManagerScript.new()
    add_child(building_manager)

    entities_parent = Node2D.new()
    add_child(entities_parent)

    # ✅ Mock GridSystem을 명시적으로 주입!
    building_manager.initialize(entities_parent, grid_system)
    # → BuildingManager는 주입된 grid_system을 사용
    # → Autoload 대신 Mock 사용으로 독립적인 테스트 가능

    # Mock BuildingData 생성
    _create_mock_building_data()
```

**주요 변경 사항:**
- ✅ `building_manager.initialize(entities_parent, grid_system)` - Mock 주입

---

## 📊 예상 효과

### Before (현재 상태)
- ❌ 테스트 실패: 31개 중 27개 실패 (87%)
- ❌ 에러: "ground_layer가 초기화되지 않았습니다!"
- ❌ Autoload 의존으로 단위 테스트 불가능

### After (리팩토링 후)
- ✅ 테스트 통과: 31개 중 31개 성공 (100%)
- ✅ Mock 주입으로 독립적인 단위 테스트 가능
- ✅ 실제 게임: Autoload 편의성 유지
- ✅ SOLID 원칙 준수 (Dependency Inversion)

---

## 🚀 실행 순서

1. **문서 검토** (5분)
   - `architecture_guidelines.md` 섹션 3.3.3 읽기
   - 하이브리드 접근법 이해

2. **BuildingManager 리팩토링** (15분)
   - `grid_system_ref` 멤버 변수 추가
   - `initialize()` 메서드 수정
   - `can_build_at()` 수정

3. **테스트 코드 수정** (5분)
   - `test_building_manager.gd` 수정
   - Mock 주입 코드 추가

4. **테스트 실행** (5분)
   - GUT로 테스트 실행
   - 결과 확인

5. **통합 테스트** (5분)
   - Godot 에디터에서 게임 실행
   - 건물 배치 테스트

**예상 소요 시간:** 30-40분

---

## 🔗 관련 문서

- `../../implementation/architecture_guidelines.md` - 섹션 3.3.3 "Autoload와 테스트 가능성"
- `../../implementation/testing_guide.md` - GUT 테스트 작성 가이드
- `sprint_04_building_system.md` - 건설 시스템 구현

---

## 📝 참고 사항

### 왜 GridSystem은 리팩토링하지 않는가?

**GridSystem은 Autoload로 유지 (전략 1 적용):**
- ✅ 순수 함수(Pure Function) 성격
- ✅ 상태가 없음 (Stateless)
- ✅ 좌표 변환 유틸리티
- ✅ 통합 테스트로 충분히 검증 가능

**BuildingManager는 하이브리드 (전략 2 적용):**
- ✅ 복잡한 비즈니스 로직
- ✅ 상태 관리 (grid_buildings Dictionary)
- ✅ 단위 테스트 필요성 높음

### 향후 매니저 작성 시

새로운 매니저(EnemyManager, ItemManager 등)를 작성할 때는 **처음부터 하이브리드 패턴**을 적용하세요:

```gdscript
class_name NewManager extends Node

var grid_system_ref: GridSystemNode = null

func initialize(parent: Node2D, grid_system: GridSystemNode = null):
    # ...
    grid_system_ref = grid_system if grid_system else GridSystem
```

---

## ✅ 완료 기준

- [ ] BuildingManager에 `grid_system_ref` 멤버 변수 추가
- [ ] `initialize()` 메서드에 선택적 `grid_system` 파라미터 추가
- [ ] `can_build_at()`에서 `grid_system_ref` 사용
- [ ] 테스트 코드에서 Mock GridSystem 주입
- [ ] 모든 단위 테스트 통과 (31/31)
- [ ] 실제 게임 정상 작동 확인
- [ ] 리팩토링 내용 커밋

---

## 🎓 학습 포인트

이 Sprint를 통해 배울 수 있는 것:

1. **의존성 주입 패턴**: Autoload의 편의성과 테스트 가능성의 균형
2. **하이브리드 접근법**: 선택적 파라미터로 두 마리 토끼 잡기
3. **SOLID 원칙**: Dependency Inversion의 실전 적용
4. **TDD**: 테스트 가능한 코드 작성의 중요성
5. **실용주의**: 모든 것을 리팩토링하지 않는 지혜
