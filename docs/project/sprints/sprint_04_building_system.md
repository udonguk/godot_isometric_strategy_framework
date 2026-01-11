# Sprint 04: 건설 시스템 구현

**관련 설계 문서:** `../../design/building_construction_system_design.md`

## 📋 개발 체크리스트

### Phase 1: 데이터
- [x] BuildingData.gd 작성
- [x] house_01.tres, farm_01.tres 생성 (+ shop_01.tres 추가)
- [x] BuildingDatabase.gd 작성

### Phase 2: 로직
- [x] ConstructionManager.gd 작성 (BuildingManager.gd로 구현)
- [ ] 미리보기 시스템 구현
- [~] 건설 가능 검증 로직 (위치 검증만 완료, 비용/조건 검증 미구현)
- [ ] 시그널 정의 및 구현

### Phase 3: UI
- [ ] SimpleConstructionMenu.tscn 생성 (최소 UI) (스킵됨)
- [x] ConstructionMenu.tscn 생성 (Resource 기반)
- [ ] BuildingButton.tscn 생성 (ConstructionMenu에 직접 통합)
- [~] 시그널 연결 (UI 내부만 연결, 건설 로직과 미연결)

### Phase 4: 통합
- [x] test_map.tscn에 통합
- [ ] 전체 워크플로우 테스트
