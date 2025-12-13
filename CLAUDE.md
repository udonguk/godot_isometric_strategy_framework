# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 기본 규칙

- **언어**: 모든 답변과 설명은 항상 **한국어**로 작성합니다.

## 프로젝트 개요

**Godot 4.5** 게임 프로젝트 "vampire_spread_isometric" - Godot 엔진으로 제작되는 아이소메트릭 게임입니다. GDScript를 스크립팅 언어로 사용하며 Forward Plus 렌더링 방식을 사용합니다.

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
vampire-spread-isometric/
├── docs/            # 기획 및 디자인 문서 (애자일 구조)
│   ├── design/      # [Design Docs] 시스템 설계 문서
│   │   └── tile_system_design.md  # 타일 시스템 설계 (UI/Logic 분리 원칙 포함)
│   ├── game_design.md # [Living Doc] 게임 기획서 (계속 업데이트)
│   ├── prd.md       # [Living Doc] 핵심 기능 명세서 (계속 업데이트)
│   ├── backlog.md   # [Artifact] 제품 백로그 (전체 할 일)
│   ├── code_convention.md # [Rule] 코드 컨벤션 및 아키텍처
│   ├── sprints/     # [History] 스프린트별 목표 및 회고
│   └── archive/     # [Archive] 폐기되거나 오래된 문서
├── scenes/          # Godot 씬 파일들 (소스코드)
│   ├── tiles/       # 타일 시스템 (TileSet + TileMapLayer 한 쌍으로 관리)
│   │   ├── ground_tileset.tres       # TileSet 리소스
│   │   └── ground_tilemaplayer.tscn  # TileMapLayer 씬 (Navigation 설정 포함)
│   ├── buildings/   # 건물 씬들
│   ├── maps/        # 맵 씬들
│   └── main.tscn    # 메인 씬
├── scripts/         # GDScript 파일들 (소스코드)
│   ├── config/      # 게임 설정
│   ├── buildings/   # 건물 로직
│   ├── map/         # 맵/그리드 시스템
│   └── main.gd
├── assets/          # 정적 자료 (이미지만)
│   └── sprites/
│       ├── tiles/           # 타일 스프라이트
│       └── buildings/       # 건물 스프라이트
├── icon.svg         # 프로젝트 아이콘
├── project.godot    # Godot 프로젝트 설정
└── .godot/          # Godot 에디터 캐시 및 메타데이터 (git 무시)
```

## 아키텍처 노트

- **메인 씬**: `main.tscn`은 간단한 Node2D 루트 노드를 포함
- **스크립트 구성**: 모든 게임 스크립트는 `scripts/` 디렉토리에 위치
- **씬-스크립트 연결**: main.gd 스크립트는 Node2D를 상속하며 표준 `_ready()` 및 `_process(delta)` 생명주기 메서드를 제공

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

## GDScript 규칙

- 스크립트는 Godot 노드 타입을 상속 (예: `extends Node2D`)
- 가능한 경우 타입 힌트 사용 (예: `func _process(delta: float) -> void:`)
- Godot 생명주기 메서드 준수: 초기화는 `_ready()`, 프레임별 업데이트는 `_process(delta)`
- 탭 들여쓰기 사용 (.editorconfig 기준)

## 중요 사항

- `.godot/` 디렉토리는 에디터 캐시를 포함하므로 직접 편집하지 않음
- 씬 파일(.tscn)은 일반적으로 Godot 에디터를 통해 편집하며 수동으로 편집하지 않음
- 프로젝트는 Godot 4.5 기능을 사용하므로 새로운 노드나 기능 추가 시 호환성 확인 필요
