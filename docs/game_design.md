# 프레임워크 개요 (Framework Overview)

## 1. 프로젝트 개요 (Project Overview)
- **프로젝트 명**: Isometric Strategy Framework
- **타입**: 게임 프레임워크 / 베이스 시스템
- **대상 장르**: 아이소메트릭 타이쿤, RTS, 전략 시뮬레이션
- **플랫폼**: PC (Windows)
- **엔진**: Godot 4.5
- **목적**: 타이쿤/RTS 스타일 게임을 빠르게 제작할 수 있는 재사용 가능한 베이스 제공

## 2. 프레임워크 철학 (Framework Philosophy)

### 핵심 원칙
> **"완성된 게임이 아닌, 게임을 만드는 기반"**
>
> 개발자가 즉시 게임 로직에 집중할 수 있도록 핵심 시스템을 미리 구축합니다.

### 설계 원칙
1. **재사용성 (Reusability)**: 다양한 게임에 적용 가능한 범용 시스템
2. **확장성 (Extensibility)**: 새 기능 추가 시 기존 코드 수정 최소화
3. **SOLID 원칙**: 유지보수가 쉬운 깔끔한 아키텍처
4. **Godot 내장 우선**: 직접 구현보다 Godot 기능 최대 활용
5. **UI/Logic 분리**: 비주얼 변경이 게임 로직에 영향 없음

## 3. 핵심 시스템 (Core Systems)

### 3.1. 타일 시스템 (Tile System)
- **Diamond Right 아이소메트릭 그리드**: 2D를 3D처럼 보이게 하는 시각 효과
- **좌표 변환 추상화**: GridSystem을 통한 그리드 ↔ 월드 좌표 변환
- **UI/Logic 분리**: 텍스처 크기 변경 시 로직 수정 불필요
- **TileMapLayer + TileSet**: Godot 내장 타일 시스템 활용

**제공 기능:**
- 그리드 좌표 검증
- 좌표 변환 (그리드 ↔ 월드)
- 타일 유효성 체크

### 3.2. 건물 시스템 (Building System)
- **그리드 기반 배치**: 정확한 타일 위치에 건물 배치
- **상태 관리**: 건물 상태(건설 중, 완료, 파괴 등) 시각화
- **BuildingManager**: 건물 생성/제거/조회 중앙 관리
- **씬 기반 설계**: 건물은 재사용 가능한 씬(Scene)으로 구성

**제공 기능:**
- 건물 생성/제거
- 그리드 위치별 건물 조회
- 건물 상태 관리 (외곽선, 색상 변경 등)
- 클릭 감지 및 선택

### 3.3. Navigation 시스템 (Navigation System)
- **NavigationServer2D**: Godot 내장 경로 찾기 엔진 활용
- **NavigationAgent2D**: 유닛의 자동 경로 탐색
- **장애물 처리**: NavigationObstacle2D를 통한 동적 장애물
- **로컬 회피 (RVO)**: 유닛 간 충돌 방지

**제공 기능:**
- 자동 경로 찾기 (A* 기반)
- 장애물 회피 (건물, 다른 유닛)
- Navigation 가능 영역 검증
- 도달 불가능 위치 감지

### 3.4. 유닛 시스템 (Unit System)
- **UnitEntity**: CharacterBody2D 기반 기본 유닛
- **선택 관리**: SelectionManager를 통한 다중 선택
- **이동 명령**: 우클릭으로 유닛 이동 지시
- **물리 기반 이동**: move_and_slide()를 통한 부드러운 이동

**제공 기능:**
- 유닛 생성/제거
- 단일/다중 선택 (Ctrl+클릭)
- 이동 명령 처리
- 선택 표시 (SelectionIndicator)

### 3.5. 카메라 시스템 (Camera System)
- **RTS 스타일 카메라**: 스타크래프트/AOE 스타일
- **WASD 이동**: 키보드로 맵 탐색
- **엣지 스크롤**: 마우스를 화면 가장자리로 이동 (옵션)
- **줌 인/아웃**: 마우스 휠 지원 (옵션)

**제공 기능:**
- 부드러운 카메라 이동
- 맵 경계 제한 (옵션)
- 줌 레벨 제한 (옵션)

### 3.6. 입력 처리 시스템 (Input System)
- **마우스 클릭**: Entity 감지 및 빈 공간 구분
- **우클릭 명령**: 유닛 이동 지시
- **드래그 선택**: 박스 선택 (계획 중)

### 3.7. 설정 시스템 (Configuration System)
- **GameConfig**: 모든 게임 설정 중앙 관리
- **타입별 분류**: 타일, 건물, 유닛, 맵, Navigation 설정 분리
- **상수 기반**: 매직 넘버 제거, 유지보수 용이

### 3.8. NPC 시스템 (NPC System)
- **자율 행동**: AI가 자동으로 경로 선택 및 이동
- **행동 패턴**: Patrol (순찰), Wander (배회), GoTo (목적지 이동), Idle (대기)
- **타이쿤 연출**: 생동감 있는 마을/도시/농장 구현
- **목적지 시스템**: 건물을 목적지로 설정 (집, 상점, 작업장 등)
- **스케줄링**: 시간대별 행동 패턴 (출근, 퇴근, 쇼핑 등)

**제공 기능:**
- NPC 자동 생성 및 관리
- 다양한 행동 패턴 (순찰, 배회, 목적지 이동)
- 건물 입장/퇴장 로직
- 대기 시간 설정
- 충돌 회피 (RVO)

**활용 예시:**
- 도시 건설: 주민이 집 ↔ 상점 ↔ 작업장 순환
- 농장 경영: 농부가 집 → 농장 → 창고 이동
- 상점 운영: 고객이 입구 → 상점 → 퇴장
- 테마파크: 방문객이 놀이기구 사이를 배회

## 4. 아키텍처 원칙 (Architecture Principles)

### 4.1. 의존성 역전 (Dependency Inversion)
```
[고수준 - 게임 로직]
  BuildingManager, UnitManager
       ↓
[추상화 레이어]
  GridSystem, GameConfig
       ↓
[저수준 - Godot 내장]
  TileMapLayer, NavigationAgent2D
```

**규칙:**
- 매니저는 절대 Godot 내장 타입을 직접 참조하지 않음
- 모든 좌표 변환은 GridSystem을 통해서만
- 모든 설정값은 GameConfig를 통해서만

### 4.2. 씬 우선 개발 (Scene-First Development)
- 새 기능 추가 시 **씬(.tscn) 생성을 우선**
- 재사용 가능한 컴포넌트는 모두 씬으로 관리
- 스크립트는 씬에 연결하여 사용

### 4.3. Godot 내장 우선 (Godot-First Approach)
- 직접 구현 전에 Godot 내장 기능 확인
- NavigationServer2D, TileMapLayer 등 적극 활용
- 퍼포먼스 최적화된 내장 기능 우선 사용

## 5. 개발 로드맵 (Development Roadmap)

### Phase 1: 기반 시스템 구축 ✅ 완료
- [x] 타일 시스템 (GridSystem)
- [x] 건물 시스템 (BuildingManager)
- [x] RTS 카메라
- [x] Navigation 기반 구축

### Phase 2: 유닛 시스템 🔄 진행 중
- [x] UnitEntity 기본 구조
- [ ] SelectionManager (다중 선택)
- [ ] 이동 명령 처리
- [ ] 유닛 간 충돌 회피

### Phase 3: 건물 시스템 확장 📋 계획
- [ ] NavigationObstacle2D 통합
- [ ] 건물 철거 기능
- [ ] 건물 업그레이드 시스템
- [ ] 건설 진행도 표시

### Phase 4: UI 시스템 📋 계획
- [ ] HUD (자원, 미니맵)
- [ ] 건물 선택 UI
- [ ] 유닛 정보 패널
- [ ] 메뉴 시스템

### Phase 5: 자원 시스템 📋 계획
- [ ] 자원 타입 정의
- [ ] 자원 수집 로직
- [ ] 자원 소비 (건물 건설, 유닛 생산)
- [ ] 자원 UI

### Phase 6: 고급 기능 📋 계획
- [ ] 유닛 AI (patrol, attack)
- [ ] 전투 시스템
- [ ] 포그 오브 워 (Fog of War)
- [ ] 미니맵

### Phase 7: NPC 시스템 📋 계획
- [ ] NPCEntity 기본 구조
- [ ] AI State Machine (행동 패턴)
- [ ] Patrol 패턴 (순찰)
- [ ] Wander 패턴 (배회)
- [ ] GoTo 패턴 (목적지 이동)
- [ ] 건물 목적지 연동
- [ ] 스케줄링 시스템 (옵션)

## 6. 사용 예시 (Use Cases)

이 프레임워크로 다음과 같은 게임을 빠르게 제작할 수 있습니다:

### 타이쿤 게임
- 도시 건설 시뮬레이션
- 농장 경영 게임
- 테마파크 관리 게임

### RTS 게임
- 실시간 전략 게임
- 타워 디펜스
- 자원 수집 전략 게임

### 기타
- 턴제 전략 게임 (일부 수정 필요)
- 퍼즐 게임 (그리드 기반)

## 7. 문서 구조 (Documentation Structure)

- **game_design.md** (이 문서): 프레임워크 전체 개요
- **prd.md**: 핵심 기능 상세 명세
- **backlog.md**: 개발 백로그 및 진행 상황
- **framework_architecture.md**: 아키텍처 상세 설명
- **code_convention.md**: 코드 컨벤션 및 규칙
- **design/**: 시스템별 설계 문서
  - `tile_system_design.md`
  - `navigation_system_design.md`
  - 등등...

## 8. 시작하기 (Getting Started)

### 프레임워크 사용 방법
1. 프로젝트 클론
2. `docs/framework_architecture.md` 읽기
3. `scenes/maps/test_map.tscn` 참고하여 새 맵 제작
4. 게임 로직 추가 (자원, 승리 조건 등)

### 새 게임 제작 체크리스트
- [ ] 새 맵 씬 생성 (`scenes/maps/`)
- [ ] 타일 배치 (ground_tilemaplayer 인스턴스)
- [ ] 게임별 설정 추가 (GameConfig)
- [ ] 게임 로직 작성 (매니저 확장)
- [ ] UI 구현

---

**참고**: 자세한 아키텍처 설명은 `docs/framework_architecture.md`를 참조하세요.
