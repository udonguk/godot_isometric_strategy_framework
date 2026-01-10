# 제품 요구사항 정의서 (PRD - Product Requirements Document)

## 1. 개요 (Overview)
이 문서는 "Isometric Strategy Framework"의 핵심 기능과 기술 요구사항을 정의합니다.

**목적**: 타이쿤/RTS 스타일 게임을 빠르게 제작할 수 있는 재사용 가능한 베이스 프레임워크 제공

## 2. 핵심 기능 리스트 (Core Features)

### 2.1. 타일 및 맵 시스템 (Tile & Map System)

#### 기능 요구사항
- [x] **그리드 시스템**: Diamond Right 아이소메트릭 좌표 변환
- [x] **좌표 변환**: 그리드 ↔ 월드 좌표 양방향 변환
- [x] **좌표 검증**: 맵 범위 내 유효성 체크
- [x] **UI/Logic 분리**: 텍스처 크기에 독립적인 로직

#### 기술 요구사항
- Godot TileMapLayer + TileSet 사용
- GridSystem (Autoload 싱글톤)
- GameConfig에서 타일 크기 상수 관리

#### 완료 기준
- ✅ 그리드 좌표 (x, y)를 월드 좌표로 정확히 변환
- ✅ 클릭 위치를 그리드 좌표로 정확히 역변환
- ✅ 텍스처 크기 변경 시 로직 수정 불필요

---

### 2.2. 건물 시스템 (Building System)

#### 기능 요구사항
- [x] **건물 배치**: 그리드 좌표에 정확히 배치
- [x] **건물 관리**: 생성/제거/조회 (BuildingManager)
- [x] **상태 시각화**: 건물 상태별 색상/외곽선 표시
- [x] **클릭 감지**: 건물 선택 및 정보 표시
- [ ] **건물 철거**: 배치된 건물 제거
- [ ] **건설 진행도**: 건설 중 상태 시각화
- [ ] **업그레이드**: 건물 레벨업 기능

#### 기술 요구사항
- BuildingEntity 씬 (extends Node2D)
- BuildingManager (건물 목록 관리)
- Dictionary 기반 그리드 매핑 (Vector2i → BuildingEntity)
- GameConfig에서 건물 설정 관리

#### 완료 기준
- ✅ 그리드 (x, y)에 건물 정확히 배치
- ✅ 동일 위치 중복 배치 방지
- ✅ 클릭 시 건물 선택 및 외곽선 표시
- [ ] 건물 철거 시 Navigation 메쉬 복구

---

### 2.3. Navigation 시스템 (Pathfinding & Navigation)

#### 기능 요구사항
- [x] **Navigation 기반**: NavigationServer2D + TileMapLayer 통합
- [x] **좌표 검증**: Navigation 가능 영역 체크
- [x] **장애물 등록**: 건물 배치 시 내부 상태 관리
- [ ] **동적 장애물**: NavigationObstacle2D 통합
- [ ] **경로 재계산**: 건물 배치/철거 시 자동 업데이트
- [ ] **도달 불가 감지**: 목표 위치 도달 가능 여부 체크

#### 기술 요구사항
- NavigationServer2D (Godot 내장)
- NavigationAgent2D (유닛에 부착)
- NavigationObstacle2D (건물에 부착)
- GridSystem.is_valid_navigation_position()
- GridSystem.mark_as_obstacle()

#### 완료 기준
- ✅ TileMapLayer에 Navigation Polygon 베이크
- ✅ 그리드 좌표의 Navigation 가능 여부 검증
- [ ] 건물 주변을 우회하는 경로 생성
- [ ] 유닛이 건물 위를 지나가지 않음

---

### 2.4. 유닛 시스템 (Unit System)

#### 기능 요구사항
- [x] **유닛 생성**: UnitEntity 씬 인스턴스화
- [x] **기본 이동**: NavigationAgent2D 기반 경로 찾기
- [ ] **유닛 선택**: 단일/다중 선택 (Ctrl+클릭)
- [ ] **이동 명령**: 우클릭으로 목표 지점 이동
- [ ] **충돌 회피**: 유닛 간 RVO (Local Avoidance)
- [ ] **Stuck 감지**: 갇힌 유닛 자동 탈출
- [ ] **유닛 정보**: HP, 상태, 스킬 등 (추후 확장)

#### 기술 요구사항
- UnitEntity 씬 (extends CharacterBody2D)
- NavigationAgent2D (경로 찾기)
- CollisionShape2D (물리 충돌)
- SelectionManager (Autoload 싱글톤)
- SelectionIndicator (선택 표시 스프라이트)

#### 완료 기준
- ✅ 유닛이 목표까지 자동으로 이동
- [ ] 클릭으로 유닛 선택, 외곽선 표시
- [ ] Ctrl+클릭으로 여러 유닛 선택
- [ ] 우클릭으로 선택된 유닛들 이동
- [ ] 좁은 통로에서 유닛 간 충돌 없이 통과

---

### 2.5. 카메라 시스템 (Camera System)

#### 기능 요구사항
- [x] **WASD 이동**: 키보드로 카메라 이동
- [x] **부드러운 이동**: 프레임 독립적 움직임
- [ ] **엣지 스크롤**: 마우스를 화면 가장자리로 이동 시 카메라 스크롤
- [ ] **줌 인/아웃**: 마우스 휠로 줌 조절
- [ ] **맵 경계 제한**: 카메라가 맵 밖으로 나가지 않음

#### 기술 요구사항
- RtsCamera2D 씬 (extends Camera2D)
- Input.is_action_pressed() 사용
- GameConfig에서 카메라 속도 설정

#### 완료 기준
- ✅ WASD로 부드럽게 이동
- [ ] 마우스 엣지 스크롤 동작
- [ ] 줌 레벨 제한 (min: 0.5, max: 2.0)
- [ ] 맵 경계 밖으로 이동 불가

---

### 2.6. 입력 처리 시스템 (Input System)

#### 기능 요구사항
- [x] **Entity 클릭 감지**: 건물/유닛 개별 클릭 처리
- [x] **빈 공간 클릭**: 그리드 좌표 출력
- [ ] **우클릭 명령**: 선택된 유닛 이동 지시
- [ ] **드래그 선택**: 박스 드래그로 다중 선택
- [ ] **단축키**: 건물 건설, 유닛 생산 등

#### 기술 요구사항
- _input_event() (Entity별 클릭)
- _unhandled_input() (빈 공간 클릭)
- Input Actions (프로젝트 설정)

#### 완료 기준
- ✅ 건물 클릭 시 선택 표시
- ✅ 빈 공간 클릭 시 그리드 좌표 출력
- [ ] 우클릭으로 유닛 이동
- [ ] 드래그 박스 선택 UI 표시

---

### 2.7. 설정 시스템 (Configuration System)

#### 기능 요구사항
- [x] **중앙 집중 관리**: 모든 설정을 GameConfig에서 관리
- [x] **타입별 분류**: 타일, 건물, 유닛, 맵, Navigation 설정 분리
- [x] **상수 기반**: 매직 넘버 제거
- [x] **타입 안정성**: 타입 힌트 사용

#### 기술 요구사항
- GameConfig (Autoload 싱글톤)
- const 키워드 사용
- 섹션별 주석 구분

#### 완료 기준
- ✅ 모든 설정이 GameConfig에 존재
- ✅ 코드에 매직 넘버 없음
- ✅ 설정 변경 시 한 곳만 수정

---

### 2.8. UI 시스템 (UI System) - 추후 구현

#### 기능 요구사항
- [ ] **HUD**: 자원, 인구, 시간 표시
- [ ] **미니맵**: 맵 전체 축소 뷰 + 카메라 위치 표시
- [ ] **건물 선택 UI**: 건물 정보 패널
- [ ] **유닛 정보 패널**: HP, 상태, 스킬
- [ ] **건설 메뉴**: 건물 목록 및 선택
- [ ] **메뉴 시스템**: 타이틀, 일시정지, 설정

#### 기술 요구사항
- Control 노드 기반 UI
- CanvasLayer (UI 레이어 분리)
- Theme 리소스 (일관된 스타일)

---

### 2.9. 자원 시스템 (Resource System) - 추후 구현

#### 기능 요구사항
- [ ] **자원 타입**: 나무, 돌, 식량, 골드 등
- [ ] **자원 수집**: 유닛이 자원 지점에서 수집
- [ ] **자원 소비**: 건물 건설, 유닛 생산 비용
- [ ] **자원 저장**: 창고 건물, 저장 한계
- [ ] **자원 UI**: HUD에 현재 자원량 표시

#### 기술 요구사항
- ResourceManager (Autoload)
- Dictionary 기반 자원 관리
- Signal로 자원 변경 이벤트 전파

---

### 2.10. NPC 시스템 (NPC System) - 추후 구현

#### 기능 요구사항
- [ ] **NPC 생성**: NPCEntity 씬 인스턴스화
- [ ] **자율 이동**: AI 행동 패턴으로 자동 이동
- [ ] **행동 패턴**:
  - **Patrol (순찰)**: 정해진 경로를 반복 (예: 집 → 상점 → 공원 → 집)
  - **Wander (배회)**: 랜덤하게 돌아다님 (예: 맵을 자유롭게 배회)
  - **GoTo (목적지 이동)**: 특정 건물로 이동 (예: 출근, 퇴근, 쇼핑)
  - **Idle (대기)**: 목적지에서 일정 시간 멈춤 (예: 상점에서 5초 대기)
- [ ] **목적지 설정**: 건물을 목적지로 지정 (입장/퇴장)
- [ ] **다중 NPC 관리**: NPCManager로 중앙 관리
- [ ] **NPC 타입**: 주민, 고객, 상인, 농부 등
- [ ] **스케줄링**: 시간대별 행동 패턴 (아침: 출근, 저녁: 퇴근)

#### 기술 요구사항
- NPCEntity 씬 (extends CharacterBody2D)
- NavigationAgent2D (경로 찾기)
- AI State Machine (행동 패턴 전환)
- NPCManager (NPC 생성/관리)
- PathPoints 시스템 (순찰 경로 정의)
- Schedule 시스템 (시간대별 행동, 옵션)

#### 완료 기준
- [ ] NPC가 자동으로 지정된 경로를 순환
- [ ] 건물 목적지에 도착 후 일정 시간 대기
- [ ] 여러 NPC가 동시에 움직이며 충돌 회피
- [ ] 다양한 행동 패턴 적용 가능 (Patrol, Wander, GoTo)

#### UnitEntity와의 차이점
| 항목 | UnitEntity (플레이어 제어) | NPCEntity (자율 행동) |
|------|---------------------------|---------------------|
| 제어 방식 | 플레이어 클릭/명령 | AI 자동 제어 |
| 선택 가능 | ✅ 선택 가능 (SelectionManager) | ❌ 선택 불가 (또는 정보만 표시) |
| 이동 방식 | 우클릭 명령 | 자동 경로 순환 |
| 주요 용도 | 전투, 자원 수집, 건설 | 분위기 연출, 타이쿤 시뮬레이션 |

#### 타이쿤 게임 활용 예시
- **도시 건설**: 주민이 집 ↔ 상점 ↔ 작업장 순환
- **농장 경영**: 농부가 집 → 농장 → 창고 이동
- **상점 운영**: 고객이 입구 → 상점 안 → 퇴장
- **테마파크**: 방문객이 놀이기구 사이를 배회

---

### 2.11. 건설 시스템 (Construction System) - 추후 구현

**핵심 원칙**: Resource 기반 데이터 주도 설계 (Data → Logic → UI 순서)

#### 기능 요구사항
- [ ] **건물 데이터 정의**: BuildingData Resource로 건물 정보 관리
- [ ] **건물 타입 관리**: 여러 종류의 건물 (주택, 농장, 상점 등)
- [ ] **건설 메뉴 UI**: 건물 목록 표시 및 선택
- [ ] **배치 미리보기**: 선택한 건물을 그리드에 반투명 표시
- [ ] **단일 건축**: 클릭으로 건물 1개 배치
- [ ] **드래그 건축**: 드래그하여 연속 배치 (도로, 벽 등)
- [ ] **건설 가능 검증**:
  - 그리드 범위 내인가?
  - 이미 건물이 있는가?
  - 자원이 충분한가?
- [ ] **건설 비용 차감**: 건물 배치 시 자원 소비
- [ ] **건설 취소**: ESC 키로 건설 모드 해제

#### 기술 요구사항

**Resource 시스템:**
- BuildingData (extends Resource)
  - 건물 이름, 아이콘, 비용, 씬 파일
  - 크기 (1x1, 2x2 등)
  - 건설 시간 (옵션)
- BuildingDatabase (Array[BuildingData])
  - 모든 건물 데이터 중앙 관리

**건설 로직:**
- ConstructionManager (Autoload)
  - 건설 모드 상태 관리
  - 선택된 건물 데이터 추적
  - 배치 미리보기 표시
  - 건설 가능 여부 검증
- BuildingPlacer (Node)
  - 실제 건물 인스턴스 생성
  - Resource에서 씬 로드

**UI:**
- ConstructionMenu (Control)
  - 건물 버튼 목록
  - BuildingData 기반 동적 생성
  - 버튼 클릭 → Signal 발송
- BuildingButton (Button)
  - 건물 아이콘 표시
  - 비용 표시
  - 구매 가능 여부 시각화

#### 완료 기준
- [ ] BuildingData Resource로 건물 정보 정의
- [ ] 에디터에서 .tres 파일로 건물 데이터 생성 (최소 3종)
- [ ] 건설 메뉴에서 건물 선택 시 미리보기 표시
- [ ] 클릭으로 건물 배치 성공
- [ ] 드래그로 연속 건축 성공 (같은 건물 여러 개)
- [ ] 자원 부족 시 건설 불가 메시지 표시
- [ ] 중복 배치 방지 (빨간색 미리보기)

#### 구현 순서 (권장)

**Phase 1: 데이터 정의 (Resource)**
1. BuildingData.gd 작성
2. 에디터에서 House.tres, Farm.tres, Shop.tres 생성
3. BuildingDatabase.gd로 목록 관리

**Phase 2: 핵심 로직 (Placement)**
1. ConstructionManager.gd 작성
2. 코드로 강제 선택 (`current_building = House.tres`)
3. 클릭 시 건물 인스턴스 생성 테스트
4. 그리드 정렬 확인

**Phase 3: UI 연결**
1. ConstructionMenu.tscn 생성
2. BuildingButton 동적 생성
3. 버튼 클릭 → 건설 모드 전환
4. 미리보기 스프라이트 표시

**Phase 4: 고급 기능**
1. 드래그 건축 구현
2. 비용 시스템 연동
3. 건설 불가 시각화 (빨간색)
4. 건설 취소 (ESC)

#### Resource 시스템 장점

**✅ 재사용성**
- 같은 데이터로 UI, 로직, 저장 시스템 모두 사용
- 새 건물 추가 = .tres 파일 1개 생성

**✅ 데이터 주도 개발**
- 코드 수정 없이 건물 추가
- 기획자가 직접 건물 데이터 편집 가능

**✅ 확장성**
- 나중에 업그레이드, 효과, 애니메이션 추가 용이
- 모딩 지원 쉬움

#### 참고 문서
- `../design/building_construction_system_design.md`: 건설 시스템 상세 설계
- `../design/resource_based_entity_design.md`: Resource 기반 엔티티 설계 패턴

---

### 2.12. 저장/로드 시스템 (Save/Load System) - 추후 구현

**핵심 원칙**: FileAccess + JSON 기반 게임 상태 직렬화

#### 기능 요구사항
- [ ] **게임 저장**: 현재 게임 상태를 JSON 파일로 저장
  - 건물 목록 (위치, 상태, 레벨 등)
  - 유닛 목록 (위치, HP, 상태 등)
  - 자원 현황
  - 카메라 위치
  - 게임 시간/진행도
- [ ] **게임 불러오기**: JSON 파일에서 게임 상태 복원
- [ ] **여러 슬롯 지원**: 최소 3개 이상의 저장 슬롯
- [ ] **자동 저장**: 일정 시간마다 자동 저장 (옵션)
- [ ] **빠른 저장/불러오기**: F5/F9 키로 빠른 저장/로드
- [ ] **저장 파일 관리**:
  - 저장 날짜/시간 표시
  - 저장 파일 삭제
  - 저장 파일 덮어쓰기 경고
- [ ] **세이브 파일 검증**: 손상된 파일 감지 및 오류 처리

#### 기술 요구사항

**저장 기술 스택: FileAccess + JSON**
- **FileAccess** (Godot 내장)
  - user:// 경로 사용 (OS별 자동 매핑)
  - FileAccess.open(path, FileAccess.WRITE)
  - FileAccess.open(path, FileAccess.READ)
- **JSON** (Godot 내장)
  - JSON.stringify(dictionary) → String
  - JSON.parse_string(json_text) → Dictionary
  - 딕셔너리를 JSON 텍스트로 변환하여 저장
  - **장점**: 가장 보편적이고 데이터 호환성이 좋음

**SaveManager (Autoload 싱글톤)**
```gdscript
# 주요 메서드
func save_game(slot: int) -> void
func load_game(slot: int) -> bool
func get_save_info(slot: int) -> Dictionary
func delete_save(slot: int) -> void
func get_save_path(slot: int) -> String
```

**데이터 직렬화 인터페이스**
- 각 매니저가 Dictionary 반환 메서드 제공:
  - BuildingManager.serialize() → Dictionary
  - UnitManager.serialize() → Dictionary (예정)
  - ResourceManager.serialize() → Dictionary (예정)
- SaveManager가 모든 데이터를 모아서 JSON으로 변환

**저장 경로 구조**
```
user://saves/
  ├── slot_1.save (JSON 파일)
  ├── slot_2.save
  ├── slot_3.save
  └── autosave.save
```

#### 완료 기준
- [ ] F5로 게임 저장 성공 (JSON 파일 생성)
- [ ] F9로 저장된 게임 불러오기 성공
- [ ] 건물 위치 및 상태가 정확히 복원됨
- [ ] 유닛 위치 및 상태가 정확히 복원됨
- [ ] 자원 수량이 정확히 복원됨
- [ ] 저장 슬롯 UI에서 저장/로드/삭제 동작
- [ ] 손상된 JSON 파일 로드 시 오류 메시지 표시
- [ ] 자동 저장 기능 동작 (10분 간격)

#### 구현 순서 (권장)

**Phase 1: 기본 저장/로드 (FileAccess + JSON)**
1. SaveManager.gd 작성 (Autoload)
2. 단일 슬롯 저장 구현
   ```gdscript
   var save_data = {"test": "hello"}
   var json_string = JSON.stringify(save_data)
   var file = FileAccess.open("user://test.save", FileAccess.WRITE)
   file.store_string(json_string)
   file.close()
   ```
3. JSON 로드 테스트
   ```gdscript
   var file = FileAccess.open("user://test.save", FileAccess.READ)
   var json_string = file.get_as_text()
   var save_data = JSON.parse_string(json_string)
   ```
4. 간단한 데이터 저장/로드 검증

**Phase 2: 전체 상태 직렬화**
1. BuildingManager.serialize() 구현
   ```gdscript
   func serialize() -> Dictionary:
       var data = []
       for building in buildings.values():
           data.append({
               "type": building.building_type,
               "grid_pos": {"x": building.grid_position.x, "y": building.grid_position.y},
               "health": building.health
           })
       return {"buildings": data}
   ```
2. SaveManager에서 모든 매니저 데이터 수집
3. 전체 게임 상태 JSON 저장
4. 복원 테스트

**Phase 3: 슬롯 시스템**
1. 여러 슬롯 지원 (slot_1.save, slot_2.save, slot_3.save)
2. 저장 파일 메타데이터 추가
   ```gdscript
   {
     "version": "1.0.0",
     "timestamp": Time.get_unix_time_from_system(),
     "playtime": 3600,
     "game_state": { ... }
   }
   ```
3. get_save_info() 구현 (메타데이터만 읽기)
4. 저장 슬롯 UI 제작

**Phase 4: 고급 기능**
1. 자동 저장 (Timer 노드 + autosave.save)
2. 빠른 저장/로드 단축키 (F5/F9)
3. JSON 파싱 오류 처리
4. 버전 호환성 체크

#### 저장 데이터 구조 예시 (JSON)

```json
{
  "version": "1.0.0",
  "timestamp": 1704362400,
  "playtime": 3600,
  "game_state": {
    "buildings": [
      {
        "type": "House",
        "grid_pos": {"x": 5, "y": 3},
        "level": 2,
        "health": 100
      }
    ],
    "units": [
      {
        "type": "Worker",
        "grid_pos": {"x": 10, "y": 7},
        "health": 50,
        "state": "idle"
      }
    ],
    "resources": {
      "wood": 500,
      "stone": 300,
      "gold": 1000
    },
    "camera": {
      "position": {"x": 512, "y": 384},
      "zoom": 1.0
    }
  }
}
```

#### FileAccess + JSON 방식의 장점

**✅ 보편성**
- 가장 널리 사용되는 데이터 포맷
- 다른 도구에서도 쉽게 읽기/편집 가능
- 웹 기반 도구와 호환성 좋음

**✅ 가독성**
- 텍스트 파일이라 직접 열어서 확인 가능
- 디버깅 시 저장 파일 내용 확인 용이
- Git으로 버전 관리 가능 (텍스트 diff)

**✅ 확장성**
- 새 필드 추가 용이
- 클라우드 저장소 연동 쉬움 (JSON API)
- 모딩 지원 시 커뮤니티가 쉽게 편집 가능

**✅ Godot 통합**
- Godot 내장 JSON 파서 사용
- 별도 라이브러리 불필요
- Dictionary ↔ JSON 변환 간단

#### 주의 사항

**❌ JSON으로 저장하면 안 되는 것:**
- 씬 인스턴스 참조 (PackedScene)
- 노드 참조 (Node)
- 시그널 연결 상태
- 함수/콜백

**✅ JSON으로 저장해야 하는 것:**
- 기본 타입 (int, float, String, bool)
- Dictionary, Array
- Vector2i → {"x": 5, "y": 3} 형태로 변환
- Enum → int 또는 String으로 변환

**보안 고려사항:**
- user:// 경로는 OS별로 자동 매핑 (안전)
- 민감 정보는 암호화 필요 (추후 고려)
- JSON 파싱 오류 처리 필수

#### 참고 문서
- Godot 공식 문서: "Saving games" (FileAccess + JSON 예제)
- Godot 공식 문서: "File I/O" (FileAccess 클래스)
- `scripts/managers/save_manager.gd`: 저장 시스템 구현 (예정)

---

## 3. 우선순위 (Priorities)

### P0 (필수 구현 - MVP)
현재 프레임워크의 최소 기능

- ✅ 타일 시스템 (좌표 변환)
- ✅ 건물 시스템 (배치, 선택)
- ✅ Navigation 기반 구축
- ✅ 유닛 기본 이동
- ✅ RTS 카메라
- [ ] **유닛 선택 시스템** ← 다음 우선순위
- [ ] **이동 명령 처리** ← 다음 우선순위

### P1 (중요 - 프레임워크 완성도)
프레임워크를 실제로 사용 가능하게 만드는 기능

- [ ] 건물 NavigationObstacle2D 통합
- [ ] 유닛 간 충돌 회피
- [ ] 드래그 박스 선택
- [ ] 건물 철거 기능
- [ ] 카메라 엣지 스크롤, 줌
- [ ] 맵 경계 제한

### P2 (추가 기능 - 확장성)
게임 제작 시 필요한 추가 기능

- [ ] **건설 시스템** (Resource 기반)
  - [ ] BuildingData Resource 정의
  - [ ] 건설 메뉴 UI
  - [ ] 배치 미리보기
  - [ ] 드래그 건축
- [ ] 자원 시스템
- [ ] UI 시스템 (HUD, 미니맵)
- [ ] 건설 진행도 표시
- [ ] 유닛 정보 패널
- [ ] 건물 업그레이드
- [ ] **NPC 시스템** (타이쿤 게임용)
- [ ] **저장/로드 시스템** (FileAccess + JSON)
  - [ ] SaveManager 구현
  - [ ] 게임 상태 직렬화
  - [ ] 여러 슬롯 지원
  - [ ] 자동 저장

### P3 (고급 기능 - 선택사항)
특정 장르에만 필요한 고급 기능

- [ ] 유닛 AI (patrol, attack)
- [ ] 전투 시스템
- [ ] 포그 오브 워
- [ ] 유닛 스킬 시스템
- [ ] 멀티플레이어 (추후 고려)

---

## 4. 비기능 요구사항 (Non-Functional Requirements)

### 4.1. 성능 (Performance)
- **목표 FPS**: 60 FPS 유지
- **유닛 수**: 최소 50개 동시 이동 지원
- **건물 수**: 최소 100개 건물 배치 지원
- **맵 크기**: 100x100 타일 이상

### 4.2. 코드 품질 (Code Quality)
- **SOLID 원칙**: 모든 매니저/시스템 준수
- **타입 안정성**: 모든 함수에 타입 힌트
- **주석**: 복잡한 로직에 한국어 주석
- **문서화**: 각 시스템별 설계 문서 존재

### 4.3. 유지보수성 (Maintainability)
- **설정 분리**: GameConfig 중앙 관리
- **UI/Logic 분리**: 비주얼 변경이 로직에 영향 없음
- **모듈화**: 각 시스템 독립적 동작 가능
- **확장성**: 새 기능 추가 시 기존 코드 최소 수정

### 4.4. 재사용성 (Reusability)
- **씬 기반**: 모든 엔티티는 재사용 가능한 씬
- **범용 설계**: 특정 게임에 종속되지 않음
- **예제 제공**: test_map.tscn으로 사용법 제시

---

## 5. 제약 사항 (Constraints)

### 5.1. 기술 제약
- **엔진**: Godot 4.5 이상 필수
- **플랫폼**: PC (Windows) 우선 지원
- **언어**: GDScript (C# 미지원)
- **2D 전용**: 3D는 고려하지 않음

### 5.2. 디자인 제약
- **아이소메트릭**: Diamond Right 방식 고정
- **그리드 기반**: 모든 배치는 그리드 단위
- **실시간**: 턴제는 부분 지원 (일부 수정 필요)

### 5.3. 범위 제약
- **네트워크**: 멀티플레이어 미지원 (추후 고려)
- **세이브/로드**: P2 우선순위로 구현 예정 (FileAccess + JSON 방식)
- **모바일**: PC 전용 (터치 미지원)

---

## 6. 성공 지표 (Success Metrics)

### 6.1. 개발자 경험
- **새 게임 제작 시간**: 기본 맵 + 건물 배치 < 1시간
- **학습 곡선**: README + 문서 읽고 사용 가능
- **코드 재사용률**: 80% 이상 코드 재사용

### 6.2. 기술 지표
- **테스트 시나리오 통과율**: 100%
- **FPS**: 유닛 50개 + 건물 100개 환경에서 60 FPS
- **버그**: Critical 버그 0개

---

## 7. 출시 기준 (Release Criteria)

### Alpha (현재 목표)
- [x] 타일 시스템 동작
- [x] 건물 배치/선택 동작
- [x] 유닛 기본 이동 동작
- [ ] 유닛 선택/이동 명령 동작
- [ ] test_map.tscn 예제 완성

### Beta (다음 목표)
- [ ] Navigation 장애물 통합
- [ ] UI 시스템 기초 (HUD)
- [ ] 자원 시스템 기초
- [ ] 문서 완성 (framework_architecture.md)

### 1.0 Release
- [ ] 모든 P0, P1 기능 구현
- [ ] 전체 테스트 시나리오 통과
- [ ] 예제 게임 1개 제작 가능
- [ ] 사용 가이드 문서 완성

---

## 8. 참고 문서 (References)

- **game_design.md**: 프레임워크 전체 개요
- **backlog.md**: 개발 진행 상황 및 백로그
- **framework_architecture.md**: 아키텍처 상세 설명
- **code_convention.md**: 코드 작성 규칙
- **design/**: 시스템별 설계 문서
