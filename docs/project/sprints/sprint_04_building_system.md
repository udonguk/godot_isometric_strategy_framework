# Sprint 04: 건설 시스템 구현

**관련 설계 문서:** `../../design/building_construction_system_design.md`

## 🎯 Sprint 목표

건물 건설의 핵심 기능 구현:
1. 건물 구축 로직 (위치 검증 + Navigation bake)
2. 건물 구축 최소 UI
3. UI와 로직 연결

> **범위**: 자원 관리, 도로 인접 등 고급 기능은 **제외** (추후 Sprint에서 구현)

---

## 📋 개발 체크리스트

### Phase 1: 데이터 준비 ✅
- [x] BuildingData.gd 작성
- [x] house_01.tres, farm_01.tres 생성 (+ shop_01.tres 추가)
- [x] BuildingDatabase.gd 작성

---

### Phase 2: 건물 구축 로직

#### 2.1. 건설 가능 검증 ✅
- [x] **위치 검증 로직**
  - [x] `BuildingManager.has_building(grid_pos)` - 기존 건물 존재 여부
  - [x] `GridSystem.is_valid_position(grid_pos, grid_size)` - 맵 범위 검증
  - [x] 건물 크기 고려 (`grid_size`) - 2x2, 3x3 건물 지원

- [x] **Navigation 장애물 등록** ✅
  - [x] ~~TileMapLayer의 `navigation_enabled` 활성화 확인~~ (불필요 - Static Colliders 방식 사용)
  - [x] 건물 배치 시 Navigation 장애물로 등록 (StaticBody2D collision_layer = 4)
  - [x] Navigation bake 자동 트리거 확인 (BuildingManager._bake_navigation_async())

#### 2.2. BuildingManager 메서드 추가 ✅
- [x] `can_build_at(building_data, grid_pos) -> Dictionary`
  - 반환값: `{success: bool, reason: String}`
  - 위치 검증 + 그리드 크기 검증

- [x] `create_building()` 수정
  - `can_build_at()` 호출하여 사전 검증
  - 검증 실패 시 null 반환 + 경고 메시지
  - 건물이 차지하는 모든 타일을 Dictionary에 등록

#### 2.3. 시그널 정의 ✅
```gdscript
# BuildingManager에 추가
signal building_placement_started(building_data: BuildingData)
signal building_placed(building_data: BuildingData, grid_pos: Vector2i)
signal building_placement_failed(reason: String)
```

---

### Phase 3: 건물 구축 UI

#### 3.1. 최소 UI 요구사항
- [ ] **건물 선택 버튼** (3개: house, farm, shop)
  - 각 버튼 클릭 시 건설 모드 진입
  - 선택된 건물 강조 표시

- [ ] **건설 취소 버튼**
  - ESC 키 또는 UI 버튼으로 취소

#### 3.2. UI 구현
- [ ] SimpleConstructionPanel.tscn 생성 (최소 디자인)
  ```
  Panel (좌상단 또는 하단)
  ├── HBoxContainer
  │   ├── BuildingButton (house_01)
  │   ├── BuildingButton (farm_01)
  │   └── BuildingButton (shop_01)
  └── CancelButton
  ```

- [ ] SimpleConstructionPanel.gd 스크립트 작성
  - 버튼 클릭 → `BuildingManager` 시그널 발송
  - 건설 모드 상태 표시

#### 3.3. 미리보기 시스템 (선택)
- [ ] 마우스 커서를 따라다니는 건물 스프라이트
- [ ] 건설 가능/불가 색상 표시 (녹색/빨간색)

---

### Phase 4: UI ↔ 로직 연결

#### 4.1. 시그널 연결
- [ ] UI → BuildingManager
  ```gdscript
  # SimpleConstructionPanel.gd
  func _on_house_button_pressed():
      var house_data = BuildingDatabase.get_building_by_id("house_01")
      BuildingManager.building_placement_started.emit(house_data)
  ```

- [ ] BuildingManager → UI
  ```gdscript
  # SimpleConstructionPanel.gd
  func _ready():
      BuildingManager.building_placed.connect(_on_building_placed)
      BuildingManager.building_placement_failed.connect(_on_placement_failed)
  ```

#### 4.2. 입력 처리
- [ ] 건설 모드에서 맵 클릭 감지
- [ ] 마우스 위치 → 그리드 좌표 변환
- [ ] `BuildingManager.create_building()` 호출

---

### Phase 5: 통합 테스트

#### 5.1. 테스트 시나리오
- [ ] **시나리오 1: 정상 건설**
  1. UI에서 "주택" 버튼 클릭
  2. 맵의 빈 공간 클릭
  3. 건물이 배치되고 Navigation 장애물로 등록됨
  4. Navigation bake 확인 (유닛이 건물 피해감)

- [ ] **시나리오 2: 건설 실패 (위치 중복)**
  1. 이미 건물이 있는 위치 클릭
  2. "이미 건물이 존재합니다" 메시지 출력
  3. 건물이 배치되지 않음

- [ ] **시나리오 3: 건설 취소**
  1. 건설 모드 진입
  2. ESC 키 또는 취소 버튼 클릭
  3. 건설 모드 종료

#### 5.2. Navigation 테스트
- [ ] 건물 배치 후 Navigation 장애물 등록 확인
- [ ] 유닛(또는 테스트 객체)이 건물을 피해서 이동하는지 확인
- [ ] 건물 제거 시 Navigation 장애물 해제 확인

---

## 🚫 범위 외 (추후 Sprint)

다음 기능들은 **이번 Sprint에서 구현하지 않음**:
- ❌ 자원 관리 시스템 (wood, stone, gold)
- ❌ 건설 비용 검증
- ❌ 도로 인접 요구사항
- ❌ 최대 건설 수 제한
- ❌ 건설 진행도 시스템
- ❌ 건물 회전 기능

> 💡 **이유**: 핵심 건설 로직과 UI 연동을 먼저 완성하고, 고급 기능은 점진적으로 추가

---

## 📝 구현 순서 요약

```
1. Phase 2.1, 2.2 (건설 로직 완성)
   → 위치 검증 + Navigation 통합

2. Phase 3.1, 3.2 (최소 UI 생성)
   → 버튼 3개 + 취소 버튼

3. Phase 4 (UI ↔ 로직 연결)
   → 시그널 연결 + 입력 처리

4. Phase 5 (통합 테스트)
   → 전체 워크플로우 + Navigation 검증
```

---

## 🔗 관련 문서

- `../../design/building_construction_system_design.md` - 건설 시스템 설계
- `../../design/tile_system_design.md` - 그리드 시스템 연동
- `../../implementation/architecture_guidelines.md` - UI/Logic 분리 원칙
