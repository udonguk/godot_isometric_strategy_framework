# Product Backlog

## 🧊 Icebox (아이디어 저장소)
- [ ] **특수 유닛 시스템**: '재건 주식회사' 스타일의 유닛 배치 (길막기, 광역 감염 등)
- [ ] **뱀파이어 연구소**: 점령 자원을 소모한 영구적/일시적 스탯 업그레이드
- [ ] 멀티플레이어 모드 고려, 시즌 패스 시스템 등

## 📝 To Do (개발 예정)

### 🎯 Step 0: RTS 카메라 시스템 (최우선 - 개발 편의성)
**목표**: 스타크래프트/AOE 스타일 카메라로 맵 전체를 자유롭게 탐색
**완료 기준**: WASD로 이동 + 마우스를 화면 가장자리로 → 카메라 스크롤

- [ ] `scripts/camera/rts_camera.gd` 생성
  - Camera2D 상속
  - 카메라 이동 속도 설정 (예: 300 pixels/sec)
- [ ] WASD 키보드 이동 구현
  - `_process(delta)`에서 Input.is_action_pressed() 체크
  - W/A/S/D 입력에 따라 position 이동
- [ ] 마우스 엣지 스크롤 구현
  - 화면 가장자리 감지 영역 설정 (예: 가장자리 20px)
  - 마우스 위치가 영역 안에 있으면 해당 방향으로 이동
  - `get_viewport().get_mouse_position()` 사용
- [ ] test_map.tscn에 Camera2D 추가
  - rts_camera.gd 스크립트 연결
  - 초기 위치를 맵 중앙으로 설정
- [ ] (옵션) 카메라 이동 범위 제한
  - 맵 밖으로 나가지 않도록 position 클램핑
- [ ] (옵션) 마우스 휠 줌 인/아웃
  - zoom 속성 조절 (min: 0.5, max: 2.0)
- [ ] 실행 후 테스트
  - WASD로 부드럽게 이동
  - 마우스를 상/하/좌/우 가장자리로 → 카메라 스크롤

---

### 🎯 Step 1: 건물 1개 표시 및 상태 변경 (최소 동작 확인)
**목표**: 화면에 건물 1개 표시 + 키 입력으로 상태 변경 테스트
**완료 기준**: F5 실행 → 건물 보임 → 스페이스바 누르면 색상 변경

- [ ] `scripts/config/game_config.gd` 생성
  - 건물 상태별 색상 정의 (Normal: 흰색, Infecting: 노란색, Infected: 빨간색)
  - 텍스처 크기 상수 정의
- [ ] `scripts/buildings/building.gd` 생성
  - BuildingState enum (NORMAL, INFECTING, INFECTED)
  - 상태 변수, grid_position 변수
  - `update_visual()` 함수 (상태별 modulate 색상 변경)
  - `set_state()` 함수
- [ ] building.tscn에 building.gd 스크립트 연결
- [ ] test_map.tscn 수정
  - BuildingLayer (Node2D) 추가
  - building.tscn 인스턴스 1개 수동 배치
- [ ] main.gd에 테스트 코드 작성
  - 스페이스바 입력 감지
  - 건물 상태를 순환 변경 (Normal → Infecting → Infected → Normal)
  - 현재 상태를 콘솔에 출력

---

### 🎯 Step 2: 그리드 좌표 시스템 (좌표 변환 동작 확인)
**목표**: 그리드 좌표로 건물 배치
**완료 기준**: (0,0), (1,0), (0,1) 위치에 건물 3개 정확히 배치됨

- [ ] `scripts/map/grid_system.gd` 생성 (static 함수만)
  - `grid_to_world(Vector2i) -> Vector2` 함수
  - `world_to_grid(Vector2) -> Vector2i` 함수
  - Diamond Right 아이소메트릭 변환 공식 적용
- [ ] building.gd에 `grid_position: Vector2i` 속성 추가
- [ ] test_map.gd 생성
  - `_ready()`에서 건물 3개를 수동으로 배치
  - 각 건물의 position을 `GridSystem.grid_to_world()`로 설정
  - 그리드 좌표를 화면에 Label로 표시 (디버그용)
- [ ] 실행 후 건물 위치가 그리드에 맞게 배치되는지 확인

---

### 🎯 Step 3: 건물 자동 생성 (매니저 시스템)
**목표**: 여러 건물을 자동으로 생성
**완료 기준**: 3x3 그리드에 9개 건물이 자동 배치됨

- [ ] `scripts/buildings/building_manager.gd` 생성
  - `grid_buildings: Dictionary` (Vector2i → Building 매핑)
  - `create_building(grid_pos: Vector2i) -> Building` 함수
  - `get_building(grid_pos: Vector2i) -> Building` 함수
- [ ] test_map.gd 수정
  - BuildingManager 인스턴스 생성
  - 이중 for문으로 3x3 건물 생성
- [ ] 중앙 건물(1,1)을 INFECTED 상태로 초기화 (시각적 구분)
- [ ] 실행 후 9개 건물이 올바른 위치에 표시되는지 확인

---

### 🎯 Step 4: 인접 건물 감지 (전파 준비)
**목표**: 특정 건물의 인접 건물 찾기
**완료 기준**: 건물 클릭 → 상하좌우 인접 건물이 노란색으로 하이라이트

- [ ] `scripts/map/spread_logic.gd` 생성
  - `NEIGHBORS` 상수 배열 (상하좌우 오프셋)
  - `get_neighbors(grid_pos: Vector2i) -> Array[Building]` 함수
  - `get_infected_neighbor_count(grid_pos: Vector2i) -> int` 함수
- [ ] building.gd에 마우스 클릭 이벤트 추가
  - `_input_event()` 구현
  - 클릭 시 인접 건물들을 노란색으로 변경
- [ ] 실행 후 건물 클릭 → 인접 4개 건물 하이라이트 확인

---

### 🎯 Step 5: 기본 전파 로직 (감염 퍼지기)
**목표**: 감염이 시간에 따라 주변으로 퍼짐
**완료 기준**: 중앙 건물 감염 → 5초 후 인접 건물 감염 시작 → 전체로 확산

- [ ] building.gd에 감염 진행 로직 추가
  - `infection_progress: float` (0.0 ~ 1.0)
  - `infection_speed: float` 변수
  - `_process(delta)` 구현 (INFECTING 상태일 때만 진행도 증가)
  - 진행도 100% 도달 시 INFECTED로 전환
- [ ] spread_logic.gd에 전파 시작 함수 추가
  - `start_spread_from(grid_pos: Vector2i)` 함수
  - 인접한 NORMAL 건물을 INFECTING으로 전환
  - 포위 수(1~4면)에 따른 속도 가중치 계산
- [ ] building.gd 수정
  - INFECTED 상태가 되면 자동으로 인접 건물에 전파 시작
- [ ] test_map.gd 수정
  - 중앙 건물(1,1)을 초기 감염원으로 설정
- [ ] 실행 후 감염이 퍼지는 과정 확인
  - 1면 포위: 느리게, 4면 포위: 빠르게

---

### 우선순위 중간 (Medium Priority) - 추후 작업
- [ ] 플레이어 기본 이동 구현
- [ ] 기본 공격 (근접) 구현
- [ ] 적 기본 AI (추적)
- [ ] UI: 체력바

### 우선순위 낮음 (Low Priority)
- [ ] 배경 음악 선정

## 🏃 In Progress (현재 스프린트 진행 중)
> 현재 진행 중인 작업은 `sprints/sprint_XX.md`에서 상세 관리하거나 여기에 요약합니다.

## ✅ Done (완료됨)
- [x] 프로젝트 초기 설정
- [x] 기획서 및 PRD 초안 작성
