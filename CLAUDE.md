# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 기본 규칙

- **언어**: 모든 답변과 설명은 항상 **한국어**로 작성합니다.

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
- **테스트 실행**: Godot 에디터 하단 GUT 패널에서 "Run All" 버튼 클릭 (또는 커맨드 라인)

## 프로젝트 구조

```
isometric-strategy-framework/
├── docs/            # 기획 및 디자인 문서 (5개 폴더 구조)
│   ├── product/     # 제품 기획 (game_design, prd)
│   ├── project/     # 프로젝트 관리 (backlog, sprints, architecture)
│   ├── design/      # 기술 설계 (시스템별 설계 문서)
│   │   └── tile_system_design.md  # 타일 시스템 설계 (UI/Logic 분리 원칙 포함)
│   ├── implementation/ # 구현 가이드 (code_convention, phase guides)
│   │   └── testing_guide.md       # 테스트 작성 가이드 (GUT 사용법)
│   └── maintenance/ # 유지보수 (errors, troubleshooting, migration)
│       └── archive/ # 폐기 문서 보관
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
├── tests/           # 테스트 파일 (GUT 프레임워크)
│   ├── unit/        # 단위 테스트
│   │   ├── test_grid_system.gd       # GridSystem 테스트
│   │   └── test_building_manager.gd  # BuildingManager 테스트
│   ├── integration/ # 통합 테스트
│   └── README.md    # 테스트 실행 가이드
├── assets/          # 정적 자료 (이미지만)
│   └── sprites/
│       ├── tiles/           # 타일 스프라이트
│       └── entity/          # 엔티티 스프라이트 (건물, 나무 등)
├── addons/          # Godot 플러그인
│   └── gut/         # GUT (Godot Unit Test) 프레임워크
├── .gutconfig.json  # GUT 설정 파일
├── icon.svg         # 프로젝트 아이콘
├── project.godot    # Godot 프로젝트 설정
└── .godot/          # Godot 에디터 캐시 및 메타데이터 (git 무시)
```

## 아키텍처 노트

- **메인 씬**: `main.tscn`은 간단한 Node2D 루트 노드를 포함
- **스크립트 구성**: 모든 게임 스크립트는 `scripts/` 디렉토리에 위치
- **씬-스크립트 연결**: main.gd 스크립트는 Node2D를 상속하며 표준 `_ready()` 및 `_process(delta)` 생명주기 메서드를 제공

### 씬 우선 개발 원칙 (중요!)

**핵심 원칙**: 새로운 기능 개발 시 **씬(.tscn) 생성을 우선**합니다.

> 📖 **상세 내용**: `docs/implementation/architecture_guidelines.md` 섹션 1 "씬 우선 개발" 참조

#### 씬 생성이 필요한 경우

**Claude Code가 다음 작업을 할 때 사용자에게 씬 생성 확인:**

- [ ] 새로운 게임 오브젝트 추가 (캐릭터, 건물, UI 등)
- [ ] 재사용 가능한 컴포넌트 생성
- [ ] 새로운 시스템 추가 (카메라, 매니저 등)

**확인 프로세스:**
1. Claude가 씬 생성 필요성 파악
2. 사용자에게 씬 생성 여부 문의
3. 사용자 승인 후 Godot 에디터에서 씬 생성 안내
4. 스크립트 작성 진행

#### 장점

- ✅ **재사용성**: 씬을 여러 곳에서 인스턴스화 가능
- ✅ **가독성**: 노드 구조를 에디터에서 시각적으로 확인
- ✅ **유지보수**: 씬 파일에서 노드 구조 수정 용이
- ✅ **Godot 철학**: "씬이 모든 것의 기본" (Everything is a Scene)

### UI/Logic 분리 원칙 (중요!)

**핵심 원칙**: 게임 로직은 텍스처 크기, 픽셀 단위에 의존하지 않고 **그리드 좌표(`Vector2i`)** 기반으로 작성합니다.

> 📖 **상세 내용**: `docs/implementation/architecture_guidelines.md` 섹션 6 "아키텍처: 로직과 UI 분리" 참조

### Scene Instance Pattern (중요!)

**핵심 원칙**: 씬 재사용 시 Factory(템플릿)와 Instance(Override) 패턴을 사용합니다.

> 📖 **상세 내용**: `docs/implementation/architecture_guidelines.md` 섹션 1 및 `docs/design/godot_scene_instance_pattern.md` 참고

## 코드 작성 규칙 (중요!)

모든 코드 작성 시 다음 규칙을 준수해야 합니다:

### Godot 내장 기능 우선 사용

> 📖 **상세 내용**: `docs/implementation/architecture_guidelines.md` 섹션 2.4 "Godot 내장 기능 우선 사용" 참조

**원칙**: 기능 구현 시 **항상 Godot 내장 기능을 먼저 검토**하고 활용

**우선순위**: Godot 내장 기능 → Godot 플러그인/에셋 → 직접 구현 (최후의 수단)

### SOLID 원칙 준수

> 📖 **상세 내용**: `docs/implementation/architecture_guidelines.md` 섹션 2.5 "SOLID 원칙 준수" 참조

**원칙**: 모든 코드는 **SOLID 원칙**을 준수하여 작성합니다

**핵심 규칙:**
- ✅ 매니저는 **절대** Godot 내장 타입(TileMapLayer, Sprite2D 등)을 직접 참조하지 않음
- ✅ 모든 좌표 변환은 **GridSystem**을 통해서만
- ✅ 모든 설정값은 **GameConfig**를 통해서만
- ✅ 각 클래스는 **하나의 책임**만 담당

### Autoload 싱글톤 접근 규칙

> 📖 **상세 내용**: `docs/implementation/architecture_guidelines.md` 섹션 2.3 "싱글톤 패턴 (Singleton Pattern / Autoload)" 참조

- Autoload 사용 시 이름 충돌(Shadowing) 주의
- `class_name` 사용 권장 사항 준수

---

## GDScript 규칙

- 스크립트는 Godot 노드 타입을 상속 (예: `extends Node2D`)
- 가능한 경우 타입 힌트 사용 (예: `func _process(delta: float) -> void:`)
- Godot 생명주기 메서드 준수: 초기화는 `_ready()`, 프레임별 업데이트는 `_process(delta)`
- 탭 들여쓰기 사용 (.editorconfig 기준)

---

## 테스트 (TDD)

이 프로젝트는 **GUT (Godot Unit Test)** 프레임워크를 사용하여 테스트를 작성합니다.

> 📖 **상세 가이드**: `docs/implementation/testing_guide.md` 및 `tests/README.md` 참조

### 테스트 작성 원칙

**테스트 파일 위치:**
- 단위 테스트: `tests/unit/test_*.gd`
- 통합 테스트: `tests/integration/test_*.gd`

**테스트 작성 규칙:**
- 파일명: `test_*.gd` (예: `test_grid_system.gd`)
- 클래스: `extends GutTest`
- 메서드명: `test_*` (예: `test_valid_position_1x1()`)

**테스트 실행:**
- Godot 에디터: 하단 **GUT** 패널 → **Run All** 버튼
- 커맨드 라인: `.gutconfig.json` 참조

**현재 테스트 커버리지:**
- ✅ `GridSystem.is_valid_position()` - 18개 테스트
- ✅ `BuildingManager.can_build_at()` - 17개 테스트
- 총 35개 테스트 작성 완료

### 새로운 기능 추가 시

**TDD 워크플로우:**
1. 기능 설계 문서 작성 (`docs/design/`)
2. **테스트 작성** (`tests/unit/test_*.gd`)
3. 구현 코드 작성 (`scripts/`)
4. 테스트 실행 및 검증
5. 리팩토링 (테스트가 안전망 역할)

---

## 중요 사항

- `.godot/` 디렉토리는 에디터 캐시를 포함하므로 직접 편집하지 않음
- 씬 파일(.tscn)은 일반적으로 Godot 에디터를 통해 편집하며 수동으로 편집하지 않음
- 프로젝트는 Godot 4.5 기능을 사용하므로 새로운 노드나 기능 추가 시 호환성 확인 필요
