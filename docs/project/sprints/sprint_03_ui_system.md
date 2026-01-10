# Sprint 03: UI 시스템 구현

**관련 설계 문서:** 
- `../../design/ui_system_design.md`
- `../../design/construction_menu_ui_redesign.md`

## 🗓️ 전체 구현 로드맵

### Week 1: 최소 UI (즉시 테스트 가능)

**Day 1-2: 건설 메뉴 (Phase 1)**
- [ ] SimpleConstructionMenu.tscn 생성
- [ ] 버튼 3개 (주택, 농장, 상점)
- [ ] ConstructionManager 간단 버전
- [ ] B 키로 열기/닫기
- [ ] 테스트: 건물 배치 성공

**Day 3-4: 기본 HUD**
- [ ] HUD.tscn 생성
- [ ] 자원 표시 (하드코딩)
- [ ] 인구 표시 (하드코딩)

---

### Week 2: Resource 통합

**Day 5-7: Resource 시스템**
- [ ] EntityData.gd, BuildingData.gd 작성
- [ ] house_01.tres, farm_01.tres, shop_01.tres 생성
- [ ] BuildingDatabase.gd 작성

**Day 8-10: 건설 메뉴 (Phase 2)**
- [ ] ConstructionMenu.tscn (동적 버전)
- [ ] BuildingButton.tscn 프리팹
- [ ] populate_buildings() 구현
- [ ] 테스트: Resource 기반 동작 확인

---

### Week 3: 고급 기능

**Day 11-13: 정보 패널**
- [ ] BuildingInfoPanel.tscn 생성
- [ ] 건물 선택 시스템 연동
- [ ] 업그레이드/철거 버튼

**Day 14-15: 미니맵**
- [ ] Minimap.tscn 생성
- [ ] SubViewport 설정
- [ ] 카메라 범위 표시
- [ ] 클릭으로 이동

---

### Week 4: 폴리싱

**Day 16-18: 테마 적용**
- [ ] main_theme.tres 생성
- [ ] 모든 UI에 테마 적용
- [ ] 색상/폰트 통일

**Day 19-20: 고급 기능**
- [ ] 툴팁 시스템
- [ ] 건설 불가 메시지
- [ ] 애니메이션 효과

---

## ✅ 상세 체크리스트

### Phase 1: 최소 UI (30분)
- [ ] SimpleConstructionMenu.tscn 생성
- [ ] 버튼 3개 추가
- [ ] ConstructionManager 간단 버전
- [ ] B 키로 열기/닫기 동작
- [ ] 건물 배치 테스트 성공

### Phase 2: Resource 통합 (2시간)
- [ ] BuildingData.gd 작성
- [ ] .tres 파일 3개 생성
- [ ] ConstructionMenu 동적 버전
- [ ] BuildingButton 프리팹
- [ ] Resource 기반 동작 확인

### Phase 3: 추가 UI (4시간)
- [ ] HUD 생성 및 표시
- [ ] BuildingInfoPanel 생성
- [ ] Minimap 생성
- [ ] 테마 적용

---

## 🔧 건설 메뉴 하단 바 재설계 구현 단계 (Redesign)

### Step 1: 노드 구조 생성 (Godot 에디터)

**기존 구조 삭제:**
1. `construction_menu.tscn` 열기
2. 기존 Panel 노드 삭제

**새 구조 추가:**

```
1. ConstructionMenu (Control)
   - Layout: Full Rect

2. CollapsedBar (Panel) 추가
   - Layout: Bottom
   - Anchor: Left=0, Right=1, Top=1, Bottom=1
   - Offset: Top=-50, Bottom=0
   - 크기: 자동 (화면 너비 x 50)

3. ExpandButton (Button) 추가 (CollapsedBar 자식)
   - Text: "건설 ▲"
   - Size: (120, 50)
   - Alignment: Left

4. ExpandedPanel (Panel) 추가
   - Layout: Bottom
   - Anchor: Left=0, Right=1, Top=1, Bottom=1
   - Offset: Top=-200, Bottom=0
   - Visible: false

5. Header (HBoxContainer) 추가 (ExpandedPanel 자식)
   - Size: (화면 너비, 40)

6. TitleLabel (Label) + CollapseButton (Button) 추가

7. Content (VBoxContainer) 추가

8. ScrollContainer (ScrollContainer) 추가
   - Horizontal Enabled: true
   - Vertical Enabled: false

9. BuildingList (HBoxContainer) 추가
   - Separation: 10

10. 건물 버튼 4개 추가 (HouseButton, FarmButton, etc.)
    - Custom Minimum Size: (100, 120)
```

### Step 2: 스크립트 작성
- `scripts/ui/construction_menu.gd` 작성 (설계 문서 참조)

### Step 3: 버튼 디자인
- BuildingButton (VBoxContainer 사용) 구조 생성

### Step 4: 테스트
- [ ] 접힌 바가 화면 하단에 보임
- [ ] "건설 ▲" 클릭 → 메뉴 펼쳐짐
- [ ] "▼ 접기" 클릭 → 메뉴 접힘
- [ ] 건물 선택 후에도 메뉴 유지
- [ ] 가로 스크롤 동작
- [ ] B 키 입력 코드 제거됨

### 모바일 테스트
- [ ] 터치로 펼침/접기 동작
- [ ] 스와이프로 건물 목록 스크롤
- [ ] 버튼 터치 영역 충분함 (최소 48x48)
- [ ] 세로 모드에서 정상 표시
- [ ] 가로 모드에서 정상 표시
- [ ] 다양한 해상도에서 버튼 크기 적절
