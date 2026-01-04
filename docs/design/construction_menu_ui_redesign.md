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

## 🔧 구현 단계

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

**파일:** `scripts/ui/construction_menu.gd`

```gdscript
# scripts/ui/construction_menu.gd
extends Control

# 노드 참조
@onready var collapsed_bar: Panel = $CollapsedBar
@onready var expanded_panel: Panel = $ExpandedPanel
@onready var expand_button: Button = $CollapsedBar/ExpandButton
@onready var collapse_button: Button = $ExpandedPanel/Header/CollapseButton

@onready var building_list: HBoxContainer = $ExpandedPanel/Content/ScrollContainer/BuildingList
@onready var house_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/HouseButton
@onready var farm_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/FarmButton
@onready var shop_button: Button = $ExpandedPanel/Content/ScrollContainer/BuildingList/ShopButton

# 상태
var is_expanded: bool = false

func _ready():
    # 시그널 연결
    expand_button.pressed.connect(_on_expand_button_pressed)
    collapse_button.pressed.connect(_on_collapse_button_pressed)

    house_button.pressed.connect(_on_house_button_pressed)
    farm_button.pressed.connect(_on_farm_button_pressed)
    shop_button.pressed.connect(_on_shop_button_pressed)

    # 초기 상태: 접힘
    _set_collapsed()

    # 모바일 최적화
    _optimize_for_mobile()

    print("[UI] ConstructionMenu 준비 (하단 바 스타일)")

# 모바일 최적화
func _optimize_for_mobile():
    var viewport_size = get_viewport_rect().size

    # 버튼 크기 동적 조정 (화면 너비 기준)
    var button_width = viewport_size.x * 0.22  # 화면의 22%
    button_width = clamp(button_width, 80, 150)  # 최소 80, 최대 150

    for button in building_list.get_children():
        if button is Button:
            button.custom_minimum_size.x = button_width
            button.custom_minimum_size.y = 120

# 펼치기
func _on_expand_button_pressed():
    _set_expanded()

# 접기
func _on_collapse_button_pressed():
    _set_collapsed()

# 상태 변경: 펼침
func _set_expanded():
    is_expanded = true
    collapsed_bar.visible = false
    expanded_panel.visible = true

    # 애니메이션 (옵션)
    _animate_slide_up()

    print("[UI] 메뉴 펼침")

# 상태 변경: 접힘
func _set_collapsed():
    is_expanded = false
    collapsed_bar.visible = true
    expanded_panel.visible = false
    print("[UI] 메뉴 접힘")

# 슬라이드 애니메이션 (옵션)
func _animate_slide_up():
    # 아래에서 위로 슬라이드
    expanded_panel.position.y = 200
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(expanded_panel, "position:y", 0, 0.3)

# 건물 선택
func _on_house_button_pressed():
    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData
    ConstructionManager.select_building(house_data)
    # ⭐ 메뉴 유지 (닫지 않음)
    print("[UI] 주택 선택")

func _on_farm_button_pressed():
    var farm_data = load("res://scripts/resources/farm_01.tres") as BuildingData
    ConstructionManager.select_building(farm_data)
    print("[UI] 농장 선택")

func _on_shop_button_pressed():
    print("[UI] 상점 (미구현)")

# 외부에서 메뉴 토글 (옵션)
func toggle_menu():
    if is_expanded:
        _set_collapsed()
    else:
        _set_expanded()

# ⭐ B 키 입력 제거! (토글 불필요)
# 모바일에서는 키보드 입력 없음
```

### Step 3: 버튼 디자인 (VBoxContainer 사용)

**BuildingButton 구조:**

```
BuildingButton (Button)
└── VBoxContainer (VBoxContainer)
    ├── IconTexture (TextureRect, 64x64)
    ├── NameLabel (Label, "주택")
    └── CostLabel (Label, "💰 100")
```

**Godot 에디터 설정:**

```
1. HouseButton 선택
2. Add Child Node → VBoxContainer
3. VBoxContainer에 자식 추가:
   - TextureRect (아이콘)
   - Label (이름)
   - Label (비용)
4. VBoxContainer 설정:
   - Alignment: Center
   - Separation: 5
```

**스타일 (Theme Override):**

```gdscript
# Inspector → Theme Overrides:

# Button:
- Colors → Font Color: #FFFFFF
- Colors → Font Hover Color: #FFFF00
- Styles → Normal: StyleBoxFlat (배경 회색)
- Styles → Hover: StyleBoxFlat (테두리 노란색)

# Labels:
- Font Size: 14
- Alignment: Center
```

### Step 4: 테스트

**PC 테스트:**
1. F5 실행
2. "건설 ▲" 클릭 → 메뉴 펼쳐짐
3. 주택 버튼 클릭 → 건설 모드 진입
4. "▼ 접기" 클릭 → 메뉴 접힘

**모바일 테스트 (에뮬레이터):**
1. 프로젝트 설정 → Display → Window → Size: 720x1280 (세로)
2. 터치 시뮬레이션 활성화
3. 스크롤 동작 확인
4. 버튼 터치 반응 확인

---

## 📋 비교표

| 기능 | 기존 (B 키 토글) | 새 방식 (하단 바) |
|------|------------------|-------------------|
| 메뉴 열기 | B 키 | "건설 ▲" 버튼 클릭/터치 |
| 메뉴 닫기 | B 키 | "▼ 접기" 버튼 클릭/터치 |
| 위치 | 화면 중앙 | 화면 하단 |
| 초기 상태 | 숨김 | 접힌 바 보임 (50px) |
| 건물 선택 후 | 메뉴 닫힘 | 메뉴 유지 |
| 화면 가림 | 중앙 가림 | 하단만 가림 |
| PC 지원 | 키보드 필요 | 마우스만 |
| 모바일 지원 | ❌ 불가능 | ✅ 터치 가능 |
| 가로 스크롤 | ❌ 없음 | ✅ 건물 많아도 OK |

---

## ✅ 개선 효과

### 1. 모바일 호환성 ⭐
- ✅ 터치 조작 최적화
- ✅ 스와이프로 스크롤
- ✅ 최소 터치 크기 준수 (48x48)
- ✅ 세로/가로 모드 모두 대응

### 2. 접근성 향상
- ✅ 메뉴가 항상 화면에 보임 (바 형태)
- ✅ 단축키 불필요 (버튼만)

### 3. 화면 활용
- ✅ 접힌 상태: 하단 50px만 차지
- ✅ 펼쳐진 상태: 하단 200px
- ✅ 게임 화면 대부분 확보

### 4. UX 개선
- ✅ 건물 선택 후에도 메뉴 유지 → 빠른 변경
- ✅ 가로 스크롤로 무한 확장 가능
- ✅ 직관적인 버튼 조작

### 5. 확장성
- ✅ 건물 100개 추가해도 가로 스크롤로 해결
- ✅ 카테고리 탭 추가 가능 (헤더에)

---

## 📱 모바일 전용 추가 기능 (옵션)

### 1. 제스처 지원

```gdscript
# 위로 스와이프 → 메뉴 펼침
# 아래로 스와이프 → 메뉴 접힘

var swipe_start: Vector2 = Vector2.ZERO
var swipe_threshold: float = 50.0

func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            swipe_start = event.position
        else:
            var swipe_delta = event.position.y - swipe_start.y

            if swipe_delta < -swipe_threshold:
                # 위로 스와이프
                _set_expanded()
            elif swipe_delta > swipe_threshold:
                # 아래로 스와이프
                _set_collapsed()
```

### 2. 햅틱 피드백 (진동)

```gdscript
func _on_house_button_pressed():
    # 모바일 진동 (짧게)
    if OS.has_feature("mobile"):
        Input.vibrate_handheld(50)  # 50ms

    var house_data = load("res://scripts/resources/house_01.tres") as BuildingData
    ConstructionManager.select_building(house_data)
```

### 3. 더블탭 방지

```gdscript
var last_tap_time: float = 0.0
var double_tap_threshold: float = 0.3

func _on_house_button_pressed():
    var current_time = Time.get_ticks_msec() / 1000.0

    # 더블탭 방지 (0.3초 이내 재클릭 무시)
    if current_time - last_tap_time < double_tap_threshold:
        return

    last_tap_time = current_time

    # 정상 처리...
```

---

## 🎯 고급 기능 (선택 사항)

### 1. 카테고리 탭 추가

**Header에 탭 추가:**

```
┌─────────────────────────────────────┐
│ [전체] [주거] [생산] [군사]  ▼ 접기│ ← 카테고리 탭
├─────────────────────────────────────┤
│ 🏠 주택 │ 🏘️ 아파트 │ ...         │
└─────────────────────────────────────┘
```

```gdscript
func _on_category_tab_pressed(category: BuildingData.BuildingCategory):
    # 해당 카테고리 건물만 필터링
    var filtered = BuildingDatabase.get_buildings_by_category(category)
    _update_building_list(filtered)
```

### 2. 검색 기능

```
┌─────────────────────────────────────┐
│ 건설 메뉴  [🔍 검색]        ▼ 접기│
├─────────────────────────────────────┤
```

### 3. 즐겨찾기

```gdscript
var favorites: Array[String] = []

func _on_favorite_button_pressed(building_id: String):
    if favorites.has(building_id):
        favorites.erase(building_id)
    else:
        favorites.append(building_id)

    # 즐겨찾기 목록 갱신
```

---

## 🔄 기존 코드 제거 항목

**삭제할 부분:**

```gdscript
# construction_menu.gd에서 삭제:
func _input(event):
    if event.is_action_pressed("ui_text_backspace"):  # ❌ 삭제
        visible = !visible
```

**삭제할 노드:**
- 기존 중앙 Panel (화면 중앙에 위치했던 것)

---

## ✅ 완료 조건

### PC 테스트
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
