# Sprint 05: 타일 시스템 구현

**관련 설계 문서:** `../../design/tile_system_design.md`

## 📋 구현 우선순위

### Phase 1: 기본 구조 + 설정 분리 ✅ 완료
- [x] 폴더 구조 생성 (`scripts/entity/`, `scripts/config/`)
- [x] `game_config.gd` 생성 (텍스처 크기, 아이소메트릭 설정 등)
- [x] `building_entity.tscn` 씬 생성
- [x] `building_entity.gd` 상태 관리 구현 (UI/Logic 분리, Resource 기반)
- [x] 테스트 맵에 수동 배치 테스트 (`StructuresTileMapLayer`)

### Phase 2: 그리드 시스템 ✅ 완료
- [x] `grid_system.gd` 좌표 변환 (`GameConfig` 참조, `grid_to_world()`, `world_to_grid()`)
- [x] `building_manager.gd` 동적 생성/배치 (`create_building()`, `try_place_building()`)
- [x] 그리드 데이터 구조 (`grid_buildings: Dictionary<Vector2i, BuildingEntity>`)
