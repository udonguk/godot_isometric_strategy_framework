# Sprint 05: 타일 시스템 구현

**관련 설계 문서:** `../../design/tile_system_design.md`

## 📋 구현 우선순위

### Phase 1: 기본 구조 + 설정 분리
- [ ] 폴더 구조 생성 (`buildings/`, `config/` 포함)
- [ ] `game_config.gd` 생성 (텍스처 크기, 경로 등)
- [ ] `building.tscn` 씬 생성
- [ ] `building.gd` 상태 관리 구현 (UI/Logic 분리 적용)
- [ ] 테스트 맵에 수동 배치 테스트

### Phase 2: 그리드 시스템
- [ ] `grid_system.gd` 좌표 변환 (GameConfig 참조)
- [ ] `building_manager.gd` 동적 생성/배치
- [ ] 그리드 데이터 구조 (`Dictionary<Vector2i, Building>`)

### Phase 3: 전파 로직
- [ ] `spread_logic.gd` 인접 감지 (순수 그리드 로직)
- [ ] 감염 진행 시스템 (`_process`에서 `infection_progress` 업데이트)
- [ ] 포위 수에 따른 가중치 적용
