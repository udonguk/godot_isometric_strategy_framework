# Sprint 02: 내비게이션 시스템 구축

**관련 설계 문서:** `../../design/navigation_system_design.md`

## 📝 상세 작업 (Sprint Backlog)

### Phase 1: 기반 구축 ✅ 완료
- [x] **Task 1.1**: `ground_tileset.tres`에 Navigation Layer 추가 및 폴리곤 그리기
- [x] **Task 1.2**: `GridSystem.is_valid_navigation_position()` 구현
- [x] **Task 1.3**: `GridSystem.mark_as_obstacle()` 구현

### Phase 2: 유닛 시스템
- [x] **Task 2.1**: `UnitEntity` 씬 생성 (CharacterBody2D + NavigationAgent2D)
- [x] **Task 2.2**: `unit_entity.gd` 기본 이동 로직 구현
- [x] **Task 2.3**: SelectionIndicator 비주얼 추가
- [x] **Task 2.4**: `test_map.tscn`에 테스트 유닛 배치

### Phase 3: 선택 시스템
- [ ] **Task 3.1**: `SelectionManager` Autoload 생성
- [ ] **Task 3.2**: 유닛 클릭 선택 구현
- [ ] **Task 3.3**: Ctrl+클릭 다중 선택 구현

### Phase 4: 이동 명령
- [ ] **Task 4.1**: `main.gd`에 우클릭 이동 구현
- [ ] **Task 4.2**: GridSystem 좌표 검증 통합
- [ ] **Task 4.3**: 에러 처리 (도달 불가능한 위치)

### Phase 5: 건물 통합
- [ ] **Task 5.1**: `BuildingEntity`에 NavigationObstacle2D 추가
- [ ] **Task 5.2**: `BuildingManager.create_building()` 수정 (장애물 등록)
- [ ] **Task 5.3**: 건물 주변 내비게이션 검증

### Phase 6: 최적화 및 테스트
- [ ] **Task 6.1**: Stuck Detection 구현
- [ ] **Task 6.2**: 다수 유닛 이동 최적화
- [ ] **Task 6.3**: 전체 테스트 시나리오 실행
