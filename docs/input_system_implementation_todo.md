# 입력 시스템 구현 TODO

> **참고 문서**: `docs/design/input_system_design.md`
> **목표**: 중앙 컨트롤러 패턴 기반 입력 시스템 구축

---

## 📋 Phase 1: Collision Layer 설정

### Task 1.1: Project Settings에서 Layer 정의

- [x] Godot 에디터 열기
- [x] `Project → Project Settings` 메뉴 열기
- [x] `Layer Names → 2D Physics` 섹션 찾기
- [x] Layer 이름 설정:
  - [x] Layer 1: `ground`
  - [x] Layer 2: `units`
  - [x] Layer 3: `buildings`
  - [x] Layer 4: `ui` (미래 확장용)
- [x] 설정 저장 (`project.godot` 자동 업데이트됨)

### Task 1.2: UnitEntity Collision Layer 설정

- [x] `scenes/entitys/unit_entity.tscn` 씬 열기
- [x] CharacterBody2D 노드 선택
- [x] Inspector에서 Collision 섹션 찾기
- [x] `Collision Layer` 설정:
  - [x] Layer 2 (units) **체크**
  - [x] 나머지 **체크 해제**
- [x] `Collision Mask` 설정:
  - [x] Layer 1 (ground) **체크** (땅과만 충돌)
  - [x] 나머지 **체크 해제**
- [x] 씬 저장 (Ctrl+S)

### Task 1.3: BuildingEntity Collision Layer 설정

- [x] `scenes/entitys/building_entity.tscn` 씬 열기 (존재하는지 확인)
  - [x] 없다면: BuildingEntity 씬 생성 필요
- [x] BuildingEntity의 Area2D 노드 선택
- [x] Inspector에서 Collision 섹션 찾기
- [x] `Collision Layer` 설정:
  - [x] Layer 3 (buildings) **체크**
  - [x] 나머지 **체크 해제**
- [x] `Collision Mask` 설정:
  - [x] 모두 **체크 해제** (충돌 감지 불필요)
- [x] 씬 저장

### Task 1.4: GroundTileSet Physics Layer 설정

- [x] Godot 에디터에서 `scenes/tiles/ground_tileset.tres` 열기 (더블클릭)
- [x] 하단 TileSet 패널에서 "Physics Layers" 섹션 찾기
- [x] Physics Layer 0 추가 ("Add Element" 버튼)
- [x] Physics Layer 0의 `Collision Layer` 설정:
  - [x] Layer 1 (ground) **체크**
  - [x] 나머지 **체크 해제**
- [x] (선택) 각 타일에 충돌 폴리곤 추가 (아이소메트릭 다이아몬드 모양)
- [x] 저장 (Ctrl+S)

### Task 1.5: 설정 확인

- [x] 게임 실행 (F5)
- [x] 콘솔에 Layer 관련 에러 없는지 확인
- [x] 유닛이 땅 위를 정상적으로 이동하는지 확인

---

## 📋 Phase 2: InputManager 생성

### Task 2.1: InputManager 파일 생성

- [x] `scripts/managers/` 폴더 생성 (없다면)
- [x] `scripts/managers/input_manager.gd` 파일 생성
- [x] 기본 템플릿 작성:
  ```gdscript
  class_name InputManager
  extends Node

  ## 게임 내 모든 입력을 중앙 관리하는 싱글톤
  ## Autoload로 등록하여 사용
  ```

### Task 2.2: Autoload 등록

- [x] `Project → Project Settings` 열기
- [x] `Autoload` 탭 선택
- [x] `Path`에 `scripts/managers/input_manager.gd` 입력
- [x] `Node Name`에 `InputManager` 입력
- [x] `Enable` 체크
- [x] `Add` 버튼 클릭
- [x] 설정 저장

### Task 2.3: ClickPriority Enum 정의

- [x] `input_manager.gd`에 Enum 추가:
  ```gdscript
  enum ClickPriority {
      GROUND = 1,    # 땅 (최하위)
      UNIT = 2,      # 유닛 (최우선)
      BUILDING = 3   # 건물 (2순위)
  }
  ```

### Task 2.4: _unhandled_input() 구현

- [x] 기본 입력 처리 메서드 작성:
  ```gdscript
  func _unhandled_input(event: InputEvent) -> void:
      if event is InputEventMouseButton and event.pressed:
          if event.button_index == MOUSE_BUTTON_LEFT:
              _handle_left_click()
          elif event.button_index == MOUSE_BUTTON_RIGHT:
              _handle_right_click()
  ```

### Task 2.5: _handle_left_click() 구현

- [x] 좌클릭 처리 메서드 작성
- [x] 우선순위 순서대로 검사 로직 구현:
  1. [x] 유닛 검사 (1순위)
  2. [x] 건물 검사 (2순위)
  3. [x] 빈 공간 처리 (3순위)
- [x] 각 케이스별 return 처리 추가

### Task 2.6: _handle_right_click() 구현

- [x] 우클릭 처리 메서드 작성 (완전 구현됨 - 이동 명령 포함)
- [x] 이동 명령 구현 완료 (GridSystem 연동)

### Task 2.7: _query_entity_at() 구현

- [x] Physics Query 메서드 작성
- [x] 파라미터: `screen_pos: Vector2`, `layer: ClickPriority`
- [x] 구현 사항:
  - [x] 스크린 좌표 → 월드 좌표 변환
  - [x] `PhysicsPointQueryParameters2D` 생성
  - [x] `collision_mask` 설정 (Layer를 Mask로 비트 변환)
  - [x] `collide_with_areas = true` 설정
  - [x] `collide_with_bodies = true` 설정
  - [x] `space.intersect_point()` 호출
  - [x] 결과 반환 (없으면 빈 Dictionary)

### Task 2.8: _on_unit_clicked() 구현

- [x] 유닛 클릭 핸들러 작성
- [x] Ctrl 키 체크 로직 추가 (`Input.is_key_pressed(KEY_CTRL)`)
- [x] `SelectionManager.select_unit()` 호출
- [x] 디버그 로그 추가: `[InputManager] 유닛 클릭: {name}`

### Task 2.9: _on_building_clicked() 구현

- [x] 건물 클릭 핸들러 작성
- [x] `SelectionManager.select_building()` 호출
- [x] 디버그 로그 추가: `[InputManager] 건물 클릭: {name}`

### Task 2.10: _on_empty_space_clicked() 구현

- [x] 빈 공간 클릭 핸들러 작성
- [x] `SelectionManager.deselect_all()` 호출
- [x] 디버그 로그 추가: `[InputManager] 빈 공간 클릭`

### Task 2.11: InputManager 테스트

- [ ] 게임 실행
- [ ] 각 클릭 타입별 로그 확인:
  - [ ] 유닛 클릭 로그 출력 확인
  - [ ] 빈 공간 클릭 로그 출력 확인
  - [ ] 로그가 **중복되지 않는지** 확인 (한 번만 출력되어야 함)

---

## 📋 Phase 3: 기존 코드 마이그레이션

### Task 3.1: UnitEntity 입력 처리 제거

- [x] `scripts/entity/unit_entity.gd` 파일 열기
- [x] 제거할 코드 확인:
  - [x] `input_pickable = true` 라인
  - [x] `input_event.connect()` 라인
  - [x] `_on_input_event()` 메서드 전체
- [x] 코드 제거 실행
- [x] 파일 저장

### Task 3.2: BuildingEntity 입력 처리 제거

- [x] `scripts/entity/building_entity.gd` 파일 열기
- [x] 제거할 코드 확인:
  - [x] `_on_area_input_event()` 메서드 전체
  - [x] Area2D의 `input_event` 시그널 연결 코드
- [x] 코드 제거 실행
- [x] 파일 저장

### Task 3.3: TestMap 입력 처리 제거

- [x] `scripts/maps/test_map.gd` 파일 열기
- [x] 제거할 코드 확인:
  - [x] `_unhandled_input()` 메서드 전체
  - [x] `_on_empty_click()` 메서드 전체
- [x] 코드 제거 실행
- [x] 파일 저장

### Task 3.4: Main 입력 처리 제거

- [x] `scripts/main.gd` 파일 열기
- [x] 제거할 코드 확인:
  - [x] `_unhandled_input()` 메서드 전체 (선택 관련)
  - [x] `_on_empty_click()` 메서드 전체
- [x] 코드 제거 실행
- [x] 파일 저장
- [x] 참고: `_input()` 메서드는 스페이스바 테스트용이므로 유지됨

### Task 3.5: 이동 명령 로직 이동

- [x] `test_map.gd`의 `_on_move_command()` 메서드 찾기
- [x] 해당 로직을 `input_manager.gd`의 `_handle_right_click()`으로 이동
- [x] `test_map.gd`에서 `_on_move_command()` 제거
- [x] 좌표 변환이 필요하다면 `GridSystem` 사용 확인
- [x] 파일 저장

### Task 3.6: 코드 정리 확인

- [x] `scripts/entity/` 폴더 내 모든 엔티티 스크립트 검토
- [x] 입력 관련 코드가 남아있지 않은지 확인
- [x] `scripts/maps/` 폴더 내 모든 맵 스크립트 검토
- [x] `scripts/main.gd` 최종 검토

---

## 📋 Phase 4: 통합 및 테스트

### Task 4.1: SelectionManager 연동 확인

- [x] `SelectionManager`가 Autoload로 등록되어 있는지 확인
- [x] `SelectionManager.select_unit()` 메서드 존재 확인
- [x] `SelectionManager.select_building()` 메서드 존재 확인
- [x] `SelectionManager.deselect_all()` 메서드 존재 확인
- [x] `SelectionManager.get_selected_units()` 메서드 존재 확인

### Task 4.2: GridSystem 좌표 변환 확인

- [x] `GridSystem`이 Autoload로 등록되어 있는지 확인
- [x] `GridSystem.grid_to_world()` 메서드 존재 확인
- [x] `GridSystem.world_to_grid()` 메서드 존재 확인
- [x] `GridSystem.is_valid_navigation_position()` 메서드 존재 확인
- [x] InputManager에서 좌표 변환 사용 중

---

## 📋 Phase 5: 전체 테스트 (Test Cases)

### TC-1: 유닛 단일 선택

- [ ] 게임 실행 (F5)
- [ ] 유닛1 클릭
  - [ ] 유닛1이 선택되는지 확인 (시각적 피드백)
  - [ ] 로그: `[InputManager] 유닛 클릭: UnitEntity` 출력 확인
- [ ] 다른 유닛2 클릭
  - [ ] 유닛1 선택 해제 확인
  - [ ] 유닛2 선택 확인
- [ ] **통과 기준**: 한 번에 하나의 유닛만 선택됨

### TC-2: 유닛 다중 선택 (Ctrl+클릭)

- [ ] Ctrl 키를 누른 상태로 유닛1 클릭
  - [ ] 유닛1 선택 확인
- [ ] Ctrl 키를 누른 상태로 유닛2 클릭
  - [ ] 유닛1, 유닛2 **모두** 선택 확인
  - [ ] 로그: `[SelectionManager] 유닛 선택됨 (총 2개)` 출력 확인
- [ ] Ctrl 키를 누른 상태로 유닛3 클릭
  - [ ] 유닛1, 2, 3 모두 선택 확인
- [ ] **통과 기준**: 다중 선택이 정상 작동, 기존 선택 유지됨

### TC-3: 건물 선택

- [ ] 건물 클릭
  - [ ] 건물이 선택되는지 확인 (외곽선 표시 등)
  - [ ] 로그: `[InputManager] 건물 클릭: BuildingEntity` 출력 확인
- [ ] 유닛 선택 후 건물 클릭
  - [ ] 유닛 선택 해제 확인
  - [ ] 건물 선택 확인
- [ ] **통과 기준**: 건물과 유닛은 동시에 선택되지 않음

### TC-4: 빈 공간 클릭

- [ ] 유닛 선택
- [ ] 빈 공간(땅) 클릭
  - [ ] 모든 선택 해제 확인
  - [ ] 로그: `[InputManager] 빈 공간 클릭` 출력 확인
  - [ ] **중요**: 로그가 **한 번만** 출력되는지 확인 (중복 없음!)
- [ ] 건물 선택
- [ ] 빈 공간 클릭
  - [ ] 건물 선택 해제 확인
- [ ] **통과 기준**: 빈 공간 클릭 시 로그 중복 없음

### TC-5: 우선순위 검증

- [ ] 씬 에디터에서 유닛과 건물을 겹치는 위치에 배치
- [ ] 게임 실행
- [ ] 겹친 위치 클릭
  - [ ] 유닛이 선택되는지 확인 (**유닛 우선**)
  - [ ] 로그: `[InputManager] 유닛 클릭` 출력 (건물 아님!)
- [ ] **통과 기준**: 유닛 > 건물 우선순위 정상 작동

### TC-6: 이동 명령 (우클릭)

- [ ] 유닛 선택
- [ ] 땅 위에 우클릭
  - [ ] 유닛이 클릭 위치로 이동하는지 확인
- [ ] 여러 유닛 선택 (Ctrl+클릭)
- [ ] 땅 위에 우클릭
  - [ ] **모든** 선택된 유닛이 이동하는지 확인
- [ ] **통과 기준**: 이동 명령 정상 작동

### TC-7: 회귀 테스트 (기존 기능 보존)

- [ ] 게임의 다른 기능들이 정상 작동하는지 확인:
  - [ ] 카메라 이동 (WASD)
  - [ ] 카메라 줌 (마우스 휠)
  - [ ] 기타 게임 로직
- [ ] **통과 기준**: 입력 시스템 변경이 다른 기능에 영향 없음

---

## 📋 Phase 6: 최종 검증

### Task 6.1: 성공 기준 체크

- [ ] ✅ 유닛 다중 선택이 정상 작동 (Ctrl+클릭)
- [ ] ✅ "빈 공간 클릭" 로그가 중복되지 않음 (한 번만 출력)
- [ ] ✅ 우선순위가 정확함 (유닛 > 건물 > 땅)
- [ ] ✅ 모든 입력 처리가 InputManager에 집중됨
- [ ] ✅ 엔티티 클래스가 입력 로직을 포함하지 않음 (관심사 분리)

### Task 6.2: 코드 리뷰

- [x] SOLID 원칙 준수 확인:
  - [x] **Single Responsibility**: InputManager만 입력 처리 담당
  - [x] **Dependency Inversion**: GridSystem, SelectionManager 같은 추상화 사용
- [x] 주석 및 문서화 확인:
  - [x] 각 메서드에 독스트링 추가
  - [x] 복잡한 로직에 주석 추가
- [x] 코드 컨벤션 준수 확인 (class_name, extends, 타입 힌트 등)

### Task 6.3: 문서 업데이트

- [ ] `docs/design/input_system_design.md` 업데이트:
  - [ ] "구현 완료" 상태로 변경
  - [ ] 실제 구현과 차이점이 있다면 기록
- [ ] `docs/backlog.md` 업데이트:
  - [ ] 입력 시스템 구현 항목 완료 표시
- [ ] `CHANGELOG.md` 추가 (있다면):
  - [ ] 입력 시스템 변경 사항 기록

---

## 🎯 완료 조건

**모든 Phase의 체크박스가 체크되었을 때 입력 시스템 구현 완료!**

---

## 📝 참고 사항

### 주의사항

1. **Layer 비트 변환 주의**
   - Layer 1 → Mask `0b0001` (1 << 0)
   - Layer 2 → Mask `0b0010` (1 << 1)
   - Layer 3 → Mask `0b0100` (1 << 2)

2. **좌표 변환**
   - 스크린 좌표 → 월드 좌표: `get_viewport().get_canvas_transform().affine_inverse() * screen_pos`
   - 월드 좌표 → 그리드 좌표: `GridSystem.world_to_grid()`

3. **디버깅 팁**
   - 로그 출력으로 입력 흐름 추적
   - Godot 에디터의 Remote 탭에서 런타임 씬 트리 확인
   - F12 디버거로 브레이크포인트 설정

### 문제 발생 시

- [ ] `docs/design/input_system_design.md` 재확인
- [ ] Godot 공식 문서 참고:
  - [PhysicsPointQueryParameters2D](https://docs.godotengine.org/en/stable/classes/class_physicspointqueryparameters2d.html)
  - [Collision Layers and Masks](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html#collision-layers-and-masks)
- [ ] 기존 코드에 입력 처리 로직이 남아있는지 재확인

---

**작업 시작일**: ___________
**작업 완료일**: ___________
**담당자**: ___________
