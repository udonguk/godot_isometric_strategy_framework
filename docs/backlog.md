# Product Backlog - Isometric Strategy Framework

## 🧊 Icebox (아이디어 저장소)
향후 고려할 기능 및 아이디어

- [ ] **멀티플레이어**: 네트워크 동기화, 룸 시스템
- [ ] **세이브/로드**: 게임 상태 저장 및 불러오기
- [ ] **모바일 지원**: 터치 입력, UI 스케일링
- [ ] **3D 지원**: 아이소메트릭 3D 변환
- [ ] **모드 지원**: 커스텀 게임 모드 로딩
- [ ] **에디터 툴**: Godot 에디터 내 맵 제작 도구
- [ ] **AI Director**: 동적 난이도 조절
- [ ] **리플레이 시스템**: 게임 녹화 및 재생

---

## 📝 To Do (개발 예정)

### 🎯 Phase 2: 유닛 시스템 완성 (현재 우선순위)

#### Step 2.1: SelectionManager 구현
**목표**: 유닛 선택 상태를 중앙에서 관리
**완료 기준**: 유닛 클릭 시 선택 표시, Ctrl+클릭으로 다중 선택

- [ ] `scripts/managers/selection_manager.gd` 생성 (Autoload)
  - `selected_units: Array[UnitEntity]` 배열
  - `select_unit(unit, multi_select)` 함수
  - `deselect_all()` 함수
  - `get_selected_units()` 함수
- [ ] 프로젝트 설정에 Autoload 등록
  - Path: `res://scripts/managers/selection_manager.gd`
  - Node Name: `SelectionManager`
- [ ] UnitEntity에 클릭 이벤트 연결
  - `input_pickable = true` 설정
  - `input_event` 시그널 연결
  - 좌클릭 시 SelectionManager.select_unit() 호출
- [ ] UnitEntity에 `is_selected` 속성 추가
  - SelectionIndicator 표시/숨김 제어
- [ ] 테스트
  - 유닛 클릭 → 선택 표시 확인
  - Ctrl+클릭 → 다중 선택 확인
  - 빈 공간 클릭 → 선택 해제 확인

---

#### Step 2.2: 이동 명령 처리
**목표**: 우클릭으로 선택된 유닛들 이동 지시
**완료 기준**: 유닛 선택 후 우클릭 → 해당 위치로 이동

- [ ] main.gd 또는 test_map.gd에 우클릭 처리 추가
  - `_unhandled_input()` 함수 수정
  - 우클릭 감지 (`MOUSE_BUTTON_RIGHT`)
  - 마우스 위치 → 월드 좌표 → 그리드 좌표 변환
- [ ] GridSystem.is_valid_navigation_position() 호출
  - 유효한 위치인지 검증
  - 무효한 위치는 경고 출력
- [ ] SelectionManager.get_selected_units() 호출
  - 선택된 모든 유닛에게 move_to() 호출
  - 목표 위치는 월드 좌표로 전달
- [ ] 에러 처리
  - 도달 불가능한 위치 → 경고 메시지
  - NavigationAgent2D.is_target_reachable() 체크
- [ ] 테스트
  - 유닛 선택 후 우클릭 → 이동 확인
  - 여러 유닛 선택 후 우클릭 → 모두 이동 확인
  - 맵 밖 클릭 → 무시되는지 확인

---

#### Step 2.3: 유닛 간 충돌 회피 (RVO)
**목표**: 여러 유닛이 서로 밀지 않고 이동
**완료 기준**: 좁은 통로에서 여러 유닛이 순서대로 통과

- [ ] NavigationAgent2D 설정 (UnitEntity)
  - `avoidance_enabled = true`
  - `avoidance_layers = 1` (Layer 0)
  - `avoidance_mask = 1` (Layer 0 회피)
  - `radius = 16.0` (유닛 반경)
  - `max_speed = speed`
- [ ] 테스트
  - 여러 유닛을 좁은 통로로 이동 → 충돌 없이 통과
  - 반대 방향 유닛 → 서로 피해서 지나감

---

### 🎯 Phase 3: 건물 시스템 확장

#### Step 3.1: BuildingEntity에 NavigationObstacle2D 추가
**목표**: 유닛이 건물을 우회하도록 만들기
**완료 기준**: 건물 배치 시 유닛이 주변을 돌아감

- [ ] `scenes/entity/building_entity.tscn` 수정
  - NavigationObstacle2D 노드 추가
  - 건물 footprint에 맞춰 vertices 설정
  - 예: 1x1 건물 = 다이아몬드 4개 꼭지점
- [ ] BuildingManager.create_building() 수정
  - 건물 생성 후 `await get_tree().physics_frame` 대기
  - NavigationServer2D.map_force_update() 호출
- [ ] 테스트
  - 건물 배치 후 유닛 이동 → 건물 피해서 이동 확인
  - 건물 반대편으로 이동 → 우회 경로 생성 확인

---

#### Step 3.2: 건물 철거 기능
**목표**: 배치된 건물을 제거하고 Navigation 복구
**완료 기준**: 건물 삭제 후 해당 위치로 유닛 이동 가능

- [ ] BuildingManager.remove_building() 함수 추가
  - `grid_buildings` Dictionary에서 제거
  - 건물 씬 queue_free()
  - GridSystem.obstacles에서 제거
- [ ] BuildingEntity에 삭제 UI 추가 (옵션)
  - Delete 키 또는 UI 버튼
- [ ] NavigationServer2D 업데이트
  - NavigationObstacle2D가 자동으로 제거됨
  - map_force_update() 호출
- [ ] 테스트
  - 건물 삭제 → Navigation 복구 확인
  - 해당 위치로 유닛 이동 가능 확인

---

#### Step 3.3: 건설 진행도 표시
**목표**: 건물 건설 중 상태를 시각적으로 표시
**완료 기준**: 건설 중 건물에 진행바 표시

- [ ] BuildingEntity에 ProgressBar 추가 (CanvasLayer)
  - 건물 위에 떠 있는 진행바
  - `construction_progress: float` 변수 (0.0 ~ 1.0)
- [ ] _process(delta) 구현
  - CONSTRUCTING 상태일 때 진행도 증가
  - 100% 도달 시 NORMAL 상태로 전환
- [ ] 테스트
  - 건물 배치 → 진행바 표시 확인
  - 완료 후 진행바 사라짐 확인

---

### 🎯 Phase 4: 카메라 시스템 확장

#### Step 4.1: 엣지 스크롤 활성화
**목표**: 마우스를 화면 가장자리로 이동 시 카메라 스크롤

- [ ] rts_camera.gd의 엣지 스크롤 주석 해제
  - 화면 가장자리 감지 로직 활성화
  - `edge_margin` 변수 조정 (기본값: 20)
- [ ] 테스트
  - 마우스를 상/하/좌/우 가장자리로 → 카메라 스크롤 확인

---

#### Step 4.2: 줌 인/아웃 구현
**목표**: 마우스 휠로 줌 조절

- [ ] rts_camera.gd에 줌 로직 추가
  - `_input(event)` 함수 추가
  - `MOUSE_BUTTON_WHEEL_UP/DOWN` 감지
  - `zoom` 속성 조절 (min: 0.5, max: 2.0)
- [ ] 테스트
  - 마우스 휠 위 → 줌 인
  - 마우스 휠 아래 → 줌 아웃
  - 최소/최대 제한 확인

---

#### Step 4.3: 맵 경계 제한
**목표**: 카메라가 맵 밖으로 나가지 않도록 제한

- [ ] rts_camera.gd에 경계 체크 추가
  - GameConfig.MAP_WIDTH, MAP_HEIGHT 사용
  - GridSystem.grid_to_world()로 맵 경계 계산
  - position 클램핑 (clamp)
- [ ] 테스트
  - 카메라를 맵 밖으로 이동 → 경계에서 멈춤 확인

---

### 🎯 Phase 5: UI 시스템 기초 (계획)

- [ ] HUD 씬 생성
  - 자원 표시 (골드, 나무 등)
  - 현재 인구/최대 인구
  - 미니맵 (추후)
- [ ] 건물 정보 패널
  - 선택된 건물 정보 표시
  - 이름, 상태, HP (추후)
- [ ] 유닛 정보 패널
  - 선택된 유닛 정보 표시
  - HP, 이동 속도, 스킬 (추후)

---

### 🎯 Phase 6: 자원 시스템 (계획)

- [ ] ResourceManager Autoload 생성
  - 자원 타입 정의 (Dictionary)
  - add_resource(), use_resource() 함수
  - Signal로 자원 변경 이벤트
- [ ] 자원 노드 배치
  - 나무, 돌 등 자원 Entity
  - 유닛이 수집 가능
- [ ] HUD 자원 표시 업데이트

---

## 🏃 In Progress (현재 진행 중)

### ✅ Step 0: RTS 카메라 시스템 (완료)
- [x] RtsCamera2D 씬 및 스크립트 생성
- [x] WASD 이동 구현
- [x] test_map.tscn에 인스턴스화

### ✅ Step 1: 건물 표시 및 상태 변경 (완료)
- [x] GameConfig 생성 (건물 상태별 색상)
- [x] BuildingEntity 스크립트 (상태 enum, update_visual)
- [x] test_map.tscn에 건물 배치
- [x] 키 입력으로 상태 변경 테스트

### ✅ Step 2: 클릭 감지 및 그리드 좌표 변환 (완료)
- [x] GridSystem 생성 (좌표 변환 함수)
- [x] BuildingEntity 클릭 감지
- [x] 빈 공간 클릭 감지

### ✅ Step 3: 그리드 기반 건물 배치 (완료)
- [x] BuildingEntity에 grid_position 속성
- [x] test_map.gd에서 GridSystem 활용 배치
- [x] 클릭으로 그리드 좌표 확인

### ✅ Step 4: 건물 자동 생성 (부분 완료)
- [x] BuildingManager 생성
- [x] create_building(), get_building() 함수
- [x] Dictionary 기반 그리드 매핑
- [ ] 중앙 건물 상태 초기화 (필요 시)

### ✅ Navigation System Phase 1 (완료)
- [x] TileMapLayer에 Navigation Polygon 베이크
- [x] GridSystem에 Navigation 검증 기능 추가
  - [x] is_valid_navigation_position()
  - [x] mark_as_obstacle()
  - [x] cache_navigation_map()
- [x] UnitEntity 기본 구조 생성
  - [x] CharacterBody2D + NavigationAgent2D
  - [x] 기본 이동 로직 (move_to, _physics_process)
  - [x] SelectionIndicator 추가
- [x] test_map.gd 테스트 환경 구축
  - [x] 20x20 타일 자동 배치
  - [x] Navigation 검증 테스트
  - [x] 테스트 유닛 생성

---

## ✅ Done (완료됨)

### 프로젝트 초기 설정
- [x] Godot 4.5 프로젝트 생성
- [x] 기획서 및 PRD 초안 작성
- [x] 프로젝트 구조 설정

### 타일 시스템
- [x] Diamond Right 아이소메트릭 좌표 변환
- [x] GridSystem Autoload 구현
- [x] TileMapLayer + TileSet 설정
- [x] UI/Logic 분리 (GameConfig)

### 건물 시스템
- [x] BuildingEntity 씬 및 스크립트
- [x] BuildingManager 기본 구현
- [x] 건물 상태 관리 (NORMAL, INFECTING, INFECTED 등)
- [x] 클릭 선택 및 외곽선 표시

### Navigation 시스템
- [x] NavigationServer2D + TileMapLayer 통합
- [x] Navigation Polygon 베이크
- [x] 좌표 검증 기능 (is_valid_navigation_position)
- [x] 장애물 등록 시스템 (mark_as_obstacle)

### 유닛 시스템
- [x] UnitEntity 기본 구조 (CharacterBody2D)
- [x] NavigationAgent2D 통합
- [x] 기본 이동 로직 (move_to, _physics_process)
- [x] SelectionIndicator 비주얼

### 카메라 시스템
- [x] RtsCamera2D 씬 및 스크립트
- [x] WASD 키보드 이동
- [x] 부드러운 카메라 이동

### 문서화
- [x] CLAUDE.md (프로젝트 가이드)
- [x] code_convention.md (코드 컨벤션)
- [x] design/tile_system_design.md
- [x] design/navigation_system_design.md
- [x] design/godot_scene_instance_pattern.md
- [x] game_design.md (프레임워크 개요로 수정)
- [x] prd.md (프레임워크 기능 명세로 수정)
- [x] backlog.md (프레임워크 백로그로 수정)

---

## 📊 진행 상황 요약

### 완료된 Phase
- ✅ **Phase 1**: 기반 시스템 구축 (타일, 건물, Navigation 기반, 카메라)

### 현재 진행 중
- 🔄 **Phase 2**: 유닛 시스템 완성 (선택, 이동 명령, 충돌 회피)

### 다음 우선순위
1. SelectionManager 구현
2. 이동 명령 처리
3. 유닛 간 충돌 회피

### 예상 완료 시기
- **Phase 2 완료**: 유닛 선택 및 이동 시스템 완성
- **Phase 3 완료**: 건물 NavigationObstacle2D 통합, 철거 기능
- **Alpha 출시**: Phase 2-3 완료 후

---

## 📌 참고 사항

### 현재 우선순위
1. **P0 (필수)**: 유닛 선택 시스템, 이동 명령 처리
2. **P1 (중요)**: 건물 NavigationObstacle2D, 유닛 충돌 회피
3. **P2 (추가)**: UI 시스템, 자원 시스템

### 다음 스프린트 목표
- [ ] SelectionManager 완성
- [ ] 우클릭 이동 명령 구현
- [ ] test_map.tscn 예제 완성 (Alpha 기준)

### 문서 업데이트 필요
- [ ] framework_architecture.md 생성 (다음 태스크)
- [ ] navigation_phase1_implementation.md 완료 문서화
