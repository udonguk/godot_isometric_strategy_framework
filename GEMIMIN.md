# GEMIMIN.md

This file provides guidance to Gemini when working with code in this repository.

## 기본 규칙

- **언어**: 모든 답변과 설명은 항상 **한국어**로 작성합니다. (Very Important!)
- **커밋 관련 규칙**: `git commit`은 사용자가 명시적으로 요청할 때만 진행합니다.

## 프로젝트 개요

**Godot 4.5** 게임 프로젝트 "isometric_strategy_framework" - Godot 엔진으로 제작되는 아이소메트릭 전략 게임 프레임워크입니다. GDScript를 스크립팅 언어로 사용하며 Forward Plus 렌더링 방식을 사용합니다.

## 개발 환경

- **엔진**: Godot 4.5.1
- **에디터 경로**: `.vscode/settings.json`에 `c:\Users\udong\gamedev\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64.exe`로 설정됨
- **언어**: GDScript (.gd 파일)
- **씬 포맷**: .tscn (Godot 씬 파일)

## 주요 명령어

Godot 프로젝트는 전통적인 빌드/테스트 명령어가 없으며, Godot 에디터를 통해 개발합니다:

- **프로젝트 열기**: Godot 에디터 실행 후 프로젝트 디렉토리 열기
- **게임 실행**: Godot 에디터에서 F5 키 또는 "재생" 버튼 사용
- **현재 씬 실행**: Godot 에디터에서 F6 키
- **스크립트 편집**: Godot 내장 에디터 또는 외부 에디터 사용 (VS Code + Godot Tools 확장)

## 프로젝트 구조

```
isometric-strategy-framework/
├── docs/            # 기획 및 디자인 문서 (5개 폴더 구조)
│   ├── product/     # 제품 기획 (game_design, prd)
│   ├── project/     # 프로젝트 관리 (backlog, sprints, architecture)
│   ├── design/      # 기술 설계 (시스템별 설계 문서)
│   │   └── tile_system_design.md  # 타일 시스템 설계 (UI/Logic 분리 원칙 포함)
│   ├── implementation/ # 구현 가이드 (coding_style, architecture_guidelines, phase guides)
│   │   ├── coding_style.md
│   │   ├── architecture_guidelines.md
│   │   └── construction_system_implementation_guide.md
│   └── maintenance/ # 유지보수 (errors, troubleshooting, migration)
│       ├── archive/ # 폐기 문서 및 완료 보고서 보관
│       │   └── navigation_phase1_report.md
│       └── ...
├── scenes/          # Godot 씬 파일들 (소스코드)
│   ├── tiles/       # 타일 시스템 (TileSet + TileMapLayer 한 쌍으로 관리)
│   │   ├── ground_tileset.tres       # TileSet 리소스
│   │   └── ground_tilemaplayer.tscn  # TileMapLayer 씬 (Navigation 설정 포함)
│   ├── entity/      # 맵 위에 배치되는 모든 엔티티
│   │   ├── building_entity.tscn      # 건물 엔티티
│   │   └── tree_entity.tscn          # 나무 엔티티 (예정)
│   ├── camera/      # 카메라 시스템
│   ├── maps/        # 맵 씬들
│   └── main.tscn    # 메인 씬
├── scripts/         # GDScript 파일들 (소스코드)
│   ├── config/      # 게임 설정
│   ├── entity/      # 엔티티 로직
│   │   ├── base_entity.gd            # 공통 엔티티 로직 (예정)
│   │   └── building_entity.gd        # 건물 전용 로직 (예정)
│   ├── camera/      # 카메라 로직
│   ├── map/         # 맵/그리드 시스템
│   └── main.gd
├── assets/          # 정적 자료 (이미지만)
│   └── sprites/
│       ├── tiles/           # 타일 스프라이트
│       └── entity/          # 엔티티 스프라이트 (건물, 나무 등)
├── icon.svg         # 프로젝트 아이콘
├── project.godot    # Godot 프로젝트 설정
└── .godot/          # Godot 에디터 캐시 및 메타데이터 (git 무시)
```

## 아키텍처 노트

- **메인 씬**: `main.tscn`은 간단한 Node2D 루트 노드를 포함
- **스크립트 구성**: 모든 게임 스크립트는 `scripts/` 디렉토리에 위치
- **씬-스크립트 연결**: main.gd 스크립트는 Node2D를 상속하며 표준 `_ready()` 및 `_process(delta)` 생명주기 메서드를 제공

### 씬 우선 개발 원칙 (중요!)

**핵심 원칙**: 새로운 기능 개발 시 **씬(.tscn) 생성을 우선**합니다

#### 개발 순서

1. **씬 생성** (scenes/ 폴더)
   - 해당 기능의 노드 구조를 씬으로 만듦
   - 예: `scenes/camera/rts_camera.tscn` (Camera2D 노드)

2. **스크립트 작성** (scripts/ 폴더)
   - 씬에 연결할 스크립트 작성
   - 예: `scripts/camera/rts_camera.gd` (extends Camera2D)

3. **씬에 스크립트 연결**
   - Godot 에디터에서 씬 열기
   - 루트 노드에 스크립트 attach

#### ✅ 올바른 접근 (씬 기반)

```
예시: RTS 카메라 구현

1. scenes/camera/rts_camera.tscn 생성
   - Camera2D 노드 추가

2. scripts/camera/rts_camera.gd 작성
   extends Camera2D
   # 카메라 로직...

3. 씬에 스크립트 연결
   - rts_camera.tscn 루트 노드에 rts_camera.gd attach

4. 다른 씬에서 재사용
   - test_map.tscn에서 "Instantiate Child Scene" → rts_camera.tscn
```

#### ❌ 피해야 할 접근 (스크립트만)

```
❌ 스크립트만 작성하고 씬 없이 코드로 인스턴스 생성
   var camera = Camera2D.new()
   add_child(camera)
```

#### 씬 생성이 필요한 경우

**Gemini가 다음 작업을 할 때 사용자에게 씬 생성 확인:**

- [ ] 새로운 게임 오브젝트 추가 (캐릭터, 건물, UI 등)
- [ ] 재사용 가능한 컴포넌트 생성
- [ ] 새로운 시스템 추가 (카메라, 매니저 등)

**확인 프로세스:**
1. Gemini가 씬 생성 필요성 파악
2. 사용자에게 씬 생성 여부 문의
3. 사용자 승인 후 Godot 에디터에서 씬 생성 안내
4. 스크립트 작성 진행

#### 장점

- ✅ **재사용성**: 씬을 여러 곳에서 인스턴스화 가능
- ✅ **가독성**: 노드 구조를 에디터에서 시각적으로 확인
- ✅ **유지보수**: 씬 파일에서 노드 구조 수정 용이
- ✅ **Godot 철학**: "씬이 모든 것의 기본" (Everything is a Scene)

### UI/Logic 분리 원칙 (중요!)

**핵심 원칙**: 게임 로직은 텍스처 크기, 픽셀 단위에 **절대** 의존하지 않음

- **로직**: 항상 그리드 좌표(`Vector2i`) 기반으로 작성
- **비주얼**: 텍스처 크기, 색상 등은 `scripts/config/game_config.gd`에 분리
- **변환**: 그리드 ↔ 월드 좌표 변환은 `scripts/map/grid_system.gd`에서만 처리
- **결과**: 텍스처 크기를 32x32에서 64x64로 변경해도 로직 수정 불필요

**자세한 내용**: `docs/design/tile_system_design.md`의 "3. 핵심 설계 원칙" 참고

### Scene Instance Pattern (중요!)

**Godot의 씬 인스턴스 시스템**: Unity의 Prefab과 유사하지만 동작 방식이 다름

**핵심 개념:**
- **Factory 씬**: 공통 설정만 정의 (빈 템플릿)
- **Instance 씬**: Factory를 인스턴스화하고 필요한 부분만 Override
- **단방향 전파**: Factory 수정 → 모든 인스턴스에 반영 (Override 제외)
- **"Apply to Prefab" 없음**: 인스턴스 → Factory 반영 불가능

**예시: TileMapLayer Factory**
```
ground_tilemaplayer.tscn (Factory - 공통 설정만)
├─ test_map.tscn (인스턴스 - 타일 배치 A)
├─ level_01.tscn (인스턴스 - 타일 배치 B)
└─ level_02.tscn (인스턴스 - 타일 배치 C)
```

**장점:**
- Navigation Layer 설정 한 곳에서 관리
- 각 맵은 타일 배치만 다르게 (Override)
- Factory 수정 시 모든 맵에 자동 반영

**자세한 내용**: `docs/design/godot_scene_instance_pattern.md` 참고

## Godot 내장 기능 우선 사용 (중요!)

**원칙**: 기능 구현 시 **항상 Godot 내장 기능을 먼저 검토**하고 활용

### 우선순위

1. **Godot 내장 기능** (최우선)
2. Godot 플러그인/에셋
3. 직접 구현 (최후의 수단)

### 주요 내장 기능 활용 예시

| 기능 | ❌ 직접 구현 | ✅ Godot 내장 |
|------|------------|-------------|
| 경로 찾기 | A* 직접 구현 | **NavigationAgent2D + Navigation Layers** |
| 물리 충돌 | 수동 충돌 체크 | **CollisionShape2D + Area2D** |
| 애니메이션 | 수동 프레임 전환 | **AnimatedSprite2D / AnimationPlayer** |
| 타일맵 | 수동 그리드 | **TileMapLayer + TileSet** |
| 입력 처리 | 키보드 직접 체크 | **Input Actions (프로젝트 설정)** |
| 상태 머신 | 수동 구현 | **AnimationTree / 커스텀 노드** |

### 새 기능 추가 시 체크리스트

코드를 작성하기 전에 다음을 확인:

1. [ ] Godot 문서에서 관련 내장 기능 검색
2. [ ] TileMap, Navigation, Physics 등 관련 시스템 확인
3. [ ] 내장 노드 타입 검토 (Node2D, Area2D, CharacterBody2D 등)
4. [ ] 내장 기능이 없는 경우에만 직접 구현

### 예시: 경로 찾기 구현

**❌ 잘못된 접근:**
```gdscript
# A* 알고리즘 직접 구현
func find_path(start, end):
    var open_set = []
    var closed_set = []
    # 100줄의 A* 코드...
```

**✅ 올바른 접근:**
```gdscript
# Godot의 NavigationAgent2D 사용
@onready var nav_agent = $NavigationAgent2D

func move_to(target):
    nav_agent.target_position = target
    # Godot가 자동으로 경로 찾기 처리
```

### 학습 리소스

- **Godot 공식 문서**: 새 기능 전에 항상 확인
- **Built-in 노드 목록**: 에디터에서 "Add Node" 탐색
- **TileMap 시스템**: Navigation Layers, Physics Layers, Custom Data

### 이점

- ✅ 성능 최적화됨
- ✅ 버그 적음
- ✅ 유지보수 쉬움
- ✅ 에디터 통합
- ✅ 개발 속도 빠름

**중요**: 내장 기능을 모르고 직접 구현하면 시간 낭비 + 성능 저하!

## SOLID 원칙 준수 (중요!)

**원칙**: 모든 코드는 **SOLID 원칙**을 준수하여 작성합니다

### 왜 SOLID가 중요한가?

게임 개발은 지속적인 변경과 확장이 필요합니다. SOLID 원칙을 따르지 않으면:
- ❌ 코드 변경 시 여러 곳을 수정해야 함 (유지보수 지옥)
- ❌ 새 기능 추가 시 기존 코드가 망가짐 (회귀 버그)
- ❌ 테스트하기 어려움 (디버깅 시간 증가)

### SOLID 5가지 원칙

#### 1. **Single Responsibility (단일 책임 원칙)**

**정의**: 하나의 클래스는 하나의 책임만 가져야 함

**❌ 잘못된 예:**
```gdscript
# building_manager.gd
func create_building(grid_pos):
    # 좌표 변환도 직접 함 (책임 2개!)
    var world_pos = ground_layer.map_to_local(grid_pos)
    # 건물 생성
    var building = BuildingScene.instantiate()
```

**✅ 올바른 예:**
```gdscript
# building_manager.gd
func create_building(grid_pos):
    # 좌표 변환은 GridSystem에게 위임 (책임 1개!)
    var world_pos = GridSystem.grid_to_world(grid_pos)
    # 건물 생성만 담당
    var building = BuildingScene.instantiate()
```

**체크리스트:**
- [ ] 각 클래스/매니저가 하나의 명확한 역할만 하는가?
- [ ] 클래스 이름이 그 역할을 정확히 표현하는가?
- [ ] "그리고(AND)"로 역할을 설명해야 한다면 책임이 2개 이상!

---

#### 2. **Open/Closed (개방-폐쇄 원칙)**

**정의**: 확장에는 열려있고, 수정에는 닫혀있어야 함

**❌ 잘못된 예:**
```gdscript
# building_manager.gd
func create_building(grid_pos):
    var world_pos = ground_layer.map_to_local(grid_pos)  # TileMapLayer 직접 사용
    # → TileMapLayer 변경 시 BuildingManager도 수정 필요!
```

**✅ 올바른 예:**
```gdscript
# building_manager.gd
func create_building(grid_pos):
    var world_pos = GridSystem.grid_to_world(grid_pos)  # 추상화 사용
    # → TileMapLayer 변경 시 GridSystem만 수정하면 됨!
```

**체크리스트:**
- [ ] 시스템 변경 시 한 곳만 수정하면 되는가?
- [ ] 새 기능 추가 시 기존 코드를 수정하지 않는가?

---

#### 3. **Liskov Substitution (리스코프 치환 원칙)**

**정의**: 자식 클래스는 부모 클래스를 완전히 대체할 수 있어야 함

**적용 예:**
```gdscript
# base_entity.gd
class_name BaseEntity extends Node2D
func take_damage(amount: int) -> void:
    pass  # 기본 구현

# building_entity.gd
extends BaseEntity
func take_damage(amount: int) -> void:
    # 부모의 계약을 위반하지 않음!
    health -= amount
    update_visual()
```

**체크리스트:**
- [ ] 자식 클래스가 부모 클래스의 동작을 보장하는가?
- [ ] 자식 클래스로 교체해도 프로그램이 정상 작동하는가?

---

#### 4. **Interface Segregation (인터페이스 분리 원칙)**

**정의**: 클라이언트는 사용하지 않는 메서드에 의존하지 않아야 함

**Godot 적용:**
- GDScript는 인터페이스가 없지만, **작은 클래스로 분리**하는 개념 적용

**❌ 잘못된 예:**
```gdscript
# entity_manager.gd (너무 많은 책임!)
func create_building()
func create_enemy()
func create_item()
func update_pathfinding()
func handle_collision()
# → 건물만 필요한데 enemy, item 메서드도 의존!
```

**✅ 올바른 예:**
```gdscript
# building_manager.gd (건물만 담당)
func create_building()
func get_building()

# enemy_manager.gd (적만 담당)
func create_enemy()
func get_enemy()
```

**체크리스트:**
- [ ] 매니저/시스템이 하나의 도메인만 담당하는가?
- [ ] 사용하지 않는 메서드를 억지로 구현하지 않는가?

---

#### 5. **Dependency Inversion (의존성 역전 원칙)** ⭐ 가장 중요!

**정의**: 고수준 모듈은 저수준 모듈에 의존하지 않고, 추상화에 의존해야 함

**❌ 잘못된 예 (현재 프로젝트에서 발생했던 문제!):**
```gdscript
# building_manager.gd (고수준)
var ground_layer: TileMapLayer  # 저수준에 직접 의존! ❌

func create_building(grid_pos):
    var world_pos = ground_layer.map_to_local(grid_pos)  # TileMapLayer 직접 사용
```

**구조:**
```
BuildingManager (고수준)
    ↓ 직접 의존 ❌
TileMapLayer (저수준 - Godot 내장)
```

**문제:**
- TileMapLayer 변경 → BuildingManager도 수정 필요
- EnemyManager, ItemManager도 모두 TileMapLayer 의존
- 결합도 높음 (Tight Coupling)

**✅ 올바른 예 (리팩토링 후):**
```gdscript
# building_manager.gd (고수준)
# TileMapLayer 참조 제거! ✅

func create_building(grid_pos):
    var world_pos = GridSystem.grid_to_world(grid_pos)  # 추상화에 의존
```

**구조:**
```
BuildingManager (고수준)
    ↓
GridSystem (추상화 레이어) ← 이것이 핵심!
    ↓
TileMapLayer (저수준)
```

**장점:**
- ✅ TileMapLayer 변경 → GridSystem만 수정
- ✅ BuildingManager는 변경 불필요
- ✅ 테스트 시 GridSystem을 Mock으로 교체 가능
- ✅ 결합도 낮음 (Loose Coupling)

**체크리스트:**
- [ ] 고수준 모듈이 Godot 내장 타입을 직접 참조하지 않는가?
- [ ] 추상화 레이어(매니저, 시스템)를 거쳐서 접근하는가?
- [ ] 의존성 방향이 "고수준 → 추상화 → 저수준"인가?

---

### 실전 적용 가이드

#### 새 매니저/시스템 추가 시 체크리스트

```gdscript
# ❌ 이렇게 하지 마세요!
class_name EnemyManager extends Node

var ground_layer: TileMapLayer  # ❌ TileMapLayer 직접 의존

func create_enemy(grid_pos):
    var world_pos = ground_layer.map_to_local(grid_pos)  # ❌ 직접 호출
```

```gdscript
# ✅ 이렇게 하세요!
class_name EnemyManager extends Node

# ground_layer 참조 없음! ✅

func create_enemy(grid_pos):
    var world_pos = GridSystem.grid_to_world(grid_pos)  # ✅ GridSystem 사용
```

#### SOLID 체크리스트

코드 작성 전에 확인:

1. **Single Responsibility**
   - [ ] 이 클래스가 하는 일을 한 문장으로 설명할 수 있는가?
   - [ ] "그리고(AND)"를 사용하지 않고 설명 가능한가?

2. **Open/Closed**
   - [ ] 기능 추가 시 기존 코드를 수정하지 않는가?
   - [ ] 추상화 레이어를 사용하는가?

3. **Liskov Substitution**
   - [ ] 상속받은 클래스가 부모의 동작을 보장하는가?

4. **Interface Segregation**
   - [ ] 매니저가 하나의 도메인만 담당하는가?

5. **Dependency Inversion** ⭐
   - [ ] Godot 내장 타입을 직접 참조하지 않는가?
   - [ ] GridSystem, GameConfig 같은 추상화를 사용하는가?

---

### 실제 프로젝트 예시

**올바른 의존성 구조:**

```
[고수준 - 게임 로직]
  BuildingManager
  EnemyManager
  ItemManager
       ↓
[추상화 레이어]
  GridSystem (좌표 변환)
  GameConfig (설정)
       ↓
[저수준 - Godot 내장]
  TileMapLayer
  Sprite2D
  Area2D
```

**핵심 규칙:**
- ✅ 매니저는 **절대** Godot 내장 타입을 직접 참조하지 않음
- ✅ 모든 좌표 변환은 **GridSystem**을 통해서만
- ✅ 모든 설정값은 **GameConfig**를 통해서만
- ✅ 각 매니저는 **하나의 도메인**만 담당

---

### 안티 패턴 (절대 하지 말 것!)

```gdscript
# ❌ 안티 패턴 1: 매니저가 TileMapLayer 직접 참조
class_name BuildingManager
var ground_layer: TileMapLayer  # ❌

# ❌ 안티 패턴 2: 매니저가 좌표 변환 직접 구현
func create_building(grid_pos):
    var world_x = (grid_pos.x - grid_pos.y) * 16  # ❌ GridSystem 역할 침범!

# ❌ 안티 패턴 3: 매니저가 여러 도메인 담당
class_name GameManager
func create_building()  # 건물
func create_enemy()     # 적
func handle_ui()        # UI
# → 책임이 3개! 분리 필요!
```

---

### Autoload 싱글톤 접근 규칙 (중요!)

이 규칙은 `docs/implementation/architecture_guidelines.md`의 "3.3. 싱글톤 패턴 (Singleton Pattern / Autoload)" 섹션을 참조하십시오. Autoload 사용 시 발생할 수 있는 이름 충돌(Shadowing) 문제 및 `class_name` 사용 권장 사항 등 상세 규칙이 설명되어 있습니다.

---

## GDScript 규칙

- 스크립트는 Godot 노드 타입을 상속 (예: `extends Node2D`)
- 가능한 경우 타입 힌트 사용 (예: `func _process(delta: float) -> void:`)
- Godot 생명주기 메서드 준수: 초기화는 `_ready()`, 프레임별 업데이트는 `_process(delta)`
- 탭 들여쓰기 사용 (.editorconfig 기준)

## 중요 사항

- `.godot/` 디렉토리는 에디터 캐시를 포함하므로 직접 편집하지 않음
- 씬 파일(.tscn)은 일반적으로 Godot 에디터를 통해 편집하며 수동으로 편집하지 않음
- 프로젝트는 Godot 4.5 기능을 사용하므로 새로운 노드나 기능 추가 시 호환성 확인 필요
