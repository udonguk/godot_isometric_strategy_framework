# 건설 메뉴 UI 재설계 (하단 바 - 모바일 호환)

## 📌 개요

기존의 "B 키 토글 방식"에서 **하단 고정 바 메뉴**로 변경합니다. 모바일 환경에서도 사용 가능한 직관적인 UI를 목표로 합니다.

### 변경 이유

**기존 방식 (B 키 토글):**
- ❌ 메뉴를 열었다가 닫아야 함 (불편)
- ❌ 단축키를 외워야 함 (모바일 불가능)
- ❌ 화면 중앙을 가림

**새 방식 (하단 고정 바):**
- ✅ 메뉴가 항상 화면 하단에 보임 (접근성 좋음)
- ✅ 필요시 접어서 화면 확보
- ✅ 터치/클릭으로 직관적인 조작
- ✅ **모바일 게임의 표준 UI 레이아웃**
- ✅ 카이로 소프트 게임과 유사한 친숙한 UX

---

## 🎨 UI 레이아웃 설계

### 하단 바 (Bottom Bar)

**화면 하단에 가로 배치**

#### 접힌 상태 (높이: 50px)

```
게임 화면:
┌─────────────────────────┐
│                         │
│                         │
│      게임 월드          │
│                         │
│                         │
├─────────────────────────┤
│  건설 ▲               │ ← 접힌 탭 (높이: 50px)
└─────────────────────────┘
```

**특징:**
- 화면 하단 50px만 차지
- "건설 ▲" 버튼만 표시 (탭 형태)
- 게임 화면 대부분 확보

#### 펼쳐진 상태 (높이: 200px)

```
게임 화면:
┌─────────────────────────┐
│                         │
│      게임 월드          │
│                         │
├─────────────────────────┤
│ 건설 메뉴            ▼ │ ← 헤더 (높이: 40px)
├─────────────────────────┤
│                         │ ← 건물 목록 (높이: 160px)
│ 🏠 주택 │ 🌾 농장 │ 🏪 상점 │
│ 금화100 │ 금화150 │ 금화200 │
│                         │
└─────────────────────────┘
```

**특징:**
- 화면 하단 200px 차지
- 건물 아이콘을 가로로 나열 (스크롤 가능)
- 모바일에서 터치하기 쉬운 크기

---

## 🏗️ 노드 구조

```
ConstructionMenu (Control, Full Rect)
├── CollapsedBar (Panel)  # 접힌 상태 바
│   └── ExpandButton (Button, text: "건설 ▲")
└── ExpandedPanel (Panel)  # 펼쳐진 상태
    ├── Header (HBoxContainer)
    │   ├── TitleLabel (Label, text: "건설 메뉴")
    │   └── CollapseButton (Button, text: "▼ 접기")
    └── Content (VBoxContainer)
        └── ScrollContainer (ScrollContainer, horizontal)
            └── BuildingList (HBoxContainer)  # 가로 배치!
                ├── HouseButton (Button)
                ├── FarmButton (Button)
                ├── ShopButton (Button)
                └── RoadButton (Button)
```

### 레이아웃 설정

#### CollapsedBar (접힌 바)
```gdscript
# Inspector 설정:
- Layout: Bottom (Full Width)
- Anchor Left: 0
- Anchor Right: 1
- Anchor Top: 1
- Anchor Bottom: 1
- Offset Top: -50
- Offset Bottom: 0
- Size: (화면 너비, 50)
- Visible: true (초기 상태)
```

#### ExpandedPanel (펼쳐진 패널)
```gdscript
# Inspector 설정:
- Layout: Bottom (Full Width)
- Anchor Left: 0
- Anchor Right: 1
- Anchor Top: 1
- Anchor Bottom: 1
- Offset Top: -200
- Offset Bottom: 0
- Size: (화면 너비, 200)
- Visible: false (초기 숨김)
```

#### BuildingList (HBoxContainer)
```gdscript
# Inspector 설정:
- Alignment: Begin
- Theme Overrides → Constants → Separation: 10
```

#### ScrollContainer
```gdscript
# Inspector 설정:
- Horizontal Scroll: Enabled
- Vertical Scroll: Disabled
- Follow Focus: true
```

---

## 🎮 동작 방식

### 1. 초기 상태

```
✓ CollapsedBar: 보임 (접힌 바만, 하단 50px)
✗ ExpandedPanel: 숨김
```

### 2. "건설 ▲" 버튼 클릭/터치 → 펼침

```gdscript
func _on_expand_button_pressed():
    collapsed_bar.visible = false
    expanded_panel.visible = true
    print("[UI] 메뉴 펼침")
```

**결과:**
- 접힌 바 사라짐
- 펼쳐진 패널 나타남 (하단 200px)
- 부드러운 슬라이드 애니메이션 (옵션)

### 3. 건물 버튼 클릭/터치

```gdscript
func _on_house_button_pressed():
    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData
    ConstructionManager.select_building(house_data)
    # ⭐ 메뉴는 그대로 유지 (닫지 않음)
    print("[UI] 주택 선택")
```

**결과:**
- 건설 모드 진입 (미리보기 표시)
- 메뉴는 **펼쳐진 상태 유지** → 다른 건물 빠르게 선택 가능

### 4. "▼ 접기" 버튼 클릭/터치 → 접힘

```gdscript
func _on_collapse_button_pressed():
    expanded_panel.visible = false
    collapsed_bar.visible = true
    print("[UI] 메뉴 접힘")
```

**결과:**
- 펼쳐진 패널 숨김
- 접힌 바만 표시 (하단 50px)

### 5. ESC 키 (PC만)

```gdscript
# ConstructionManager에서만 처리
# 메뉴 상태는 변경 없음
```

**결과:**
- 건설 모드 취소 (미리보기 사라짐)
- 메뉴는 현재 상태 유지

---

## 🎨 비주얼 디자인

### 접힌 바 (CollapsedBar)

```
전체 화면 너비
┌─────────────────────────────────────┐
│  건설 ▲                            │ ← 높이: 50px
└─────────────────────────────────────┘
```

**스타일:**
- 배경: 반투명 검은색 (`Color(0, 0, 0, 0.7)`)
- 버튼: 흰색 텍스트, 왼쪽 정렬
- 버튼 크기: (120, 50)
- 아이콘: ▲ (위쪽 화살표)

### 펼쳐진 패널 (ExpandedPanel)

```
전체 화면 너비
┌─────────────────────────────────────┐
│ 건설 메뉴                 ▼ 접기   │ ← 헤더 (40px)
├─────────────────────────────────────┤
│                                     │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│ │ 🏠  │ │ 🌾  │ │ 🏪  │ │ 🛤️  │  │ ← 버튼 영역
│ │주택 │ │농장 │ │상점 │ │도로 │  │   (160px)
│ │100💰│ │150💰│ │200💰│ │ 50💰│  │
│ └─────┘ └─────┘ └─────┘ └─────┘  │
│         ← 가로 스크롤 가능 →      │
└─────────────────────────────────────┘
   총 높이: 200px
```

**스타일:**

**Header:**
- 배경: 반투명 검은색 (`Color(0, 0, 0, 0.8)`)
- 높이: 40px
- TitleLabel: 흰색, 폰트 크기 18
- CollapseButton: 우측 정렬, 크기 (100, 40)

**BuildingButton:**
- 크기: 100x120 (세로로 긴 버튼)
- 배경: 반투명 회색 (`Color(0.3, 0.3, 0.3, 0.9)`)
- 테두리: 흰색 2px
- 레이아웃:
  ```
  ┌─────────┐
  │   🏠    │ ← 아이콘 (64x64)
  │  주택   │ ← 이름
  │ 금화100 │ ← 비용
  └─────────┘
  ```
- Hover/Press: 노란색 테두리 (`Color(1, 1, 0, 1)`)

**ScrollContainer:**
- 배경: 투명
- 스크롤바: 반투명 흰색

---

## 📱 모바일 최적화

### 터치 영역

**최소 터치 크기: 48x48 (권장)**

- ExpandButton: 120x50 ✅
- CollapseButton: 100x40 ⚠️ → **100x50으로 수정**
- BuildingButton: 100x120 ✅

### 스크롤

```gdscript
# ScrollContainer 설정
- Horizontal Scroll Enabled: true
- Scroll Deadzone: 0  # 즉시 반응
- Follow Focus: true  # 선택된 버튼 따라가기
```

**모바일 제스처:**
- 좌우 스와이프: 건물 목록 스크롤
- 탭: 버튼 선택

### 해상도 대응

**기준 해상도: 1280x720 (16:9)**

```gdscript
# 동적 크기 조정
func _ready():
    var viewport_size = get_viewport_rect().size

    # 화면 너비의 25%를 버튼 너비로
    var button_width = viewport_size.x * 0.25
    button_width = clamp(button_width, 80, 150)  # 최소/최대 제한

    for button in building_list.get_children():
        button.custom_minimum_size.x = button_width
```

**세로 모드 (Portrait):**
- 펼쳐진 높이: 250px (더 높게)
- 버튼 2줄 배치 가능

**가로 모드 (Landscape):**
- 펼쳐진 높이: 200px
- 버튼 1줄 가로 스크롤

---

## 🚀 구현 완료 후

**하단 바 UI가 완성되면:**
- ✅ 직관적인 건설 메뉴 완성!
- ✅ 모바일 게임처럼 자연스러운 조작
- ✅ PC와 모바일 모두 지원
- ✅ 카이로 소프트 스타일의 친숙한 UX

**다음 단계:**
1. 카테고리 탭 추가
2. 건물 정보 툴팁
3. 비용 부족 시 빨간색 표시
4. 건물 아이콘 추가

---

## 📚 참고 이미지

**모바일 게임 예시:**
- Clash of Clans: 하단 건물 바
- Hay Day: 하단 상점 바
- 카이로 소프트 게임: 하단 메뉴 바

**레이아웃:**
```
┌─────────────────────┐
│                     │
│   게임 화면         │  ← 대부분 게임에 할애
│                     │
├─────────────────────┤
│ 건물 건물 건물      │  ← 하단 150-200px
└─────────────────────┘
```

---

## 🎉 최종 요약

### 핵심 변경사항

1. **위치**: 중앙 → 하단
2. **조작**: B 키 → 버튼 터치/클릭
3. **배치**: 세로 → 가로 (스크롤)
4. **플랫폼**: PC 전용 → PC + 모바일
5. **지속성**: 건물 선택 후 메뉴 유지

### 장점

- ✅ 모바일 호환
- ✅ 직관적 조작
- ✅ 화면 효율
- ✅ 무한 확장 가능
- ✅ 친숙한 UX

**구현 완료 시: 카이로 소프트 스타일의 하단 바 건설 메뉴 완성! 🎊**
