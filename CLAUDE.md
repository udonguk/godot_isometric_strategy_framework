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
│   ├── game_design.md # [Living Doc] 게임 기획서 (계속 업데이트)
│   ├── prd.md       # [Living Doc] 핵심 기능 명세서 (계속 업데이트)
│   ├── backlog.md   # [Artifact] 제품 백로그 (전체 할 일)
│   ├── code_convention.md # [Rule] 코드 컨벤션 및 아키텍처
│   ├── sprints/     # [History] 스프린트별 목표 및 회고
│   └── archive/     # [Archive] 폐기되거나 오래된 문서
├── scripts/          # GDScript 파일들
│   └── main.gd      # 메인 씬 스크립트 (Node2D 상속)
├── main.tscn        # 메인 씬 파일
├── icon.svg         # 프로젝트 아이콘
├── project.godot    # Godot 프로젝트 설정
└── .godot/          # Godot 에디터 캐시 및 메타데이터 (git 무시)
```

## 아키텍처 노트

- **메인 씬**: `main.tscn`은 간단한 Node2D 루트 노드를 포함
- **스크립트 구성**: 모든 게임 스크립트는 `scripts/` 디렉토리에 위치
- **씬-스크립트 연결**: main.gd 스크립트는 Node2D를 상속하며 표준 `_ready()` 및 `_process(delta)` 생명주기 메서드를 제공

## GDScript 규칙

- 스크립트는 Godot 노드 타입을 상속 (예: `extends Node2D`)
- 가능한 경우 타입 힌트 사용 (예: `func _process(delta: float) -> void:`)
- Godot 생명주기 메서드 준수: 초기화는 `_ready()`, 프레임별 업데이트는 `_process(delta)`
- 탭 들여쓰기 사용 (.editorconfig 기준)

## 중요 사항

- `.godot/` 디렉토리는 에디터 캐시를 포함하므로 직접 편집하지 않음
- 씬 파일(.tscn)은 일반적으로 Godot 에디터를 통해 편집하며 수동으로 편집하지 않음
- 프로젝트는 Godot 4.5 기능을 사용하므로 새로운 노드나 기능 추가 시 호환성 확인 필요
