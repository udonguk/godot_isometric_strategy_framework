---
name: commit
description: Git 변경사항 커밋 자동화. 변경 내용 분석 후 적절한 커밋 메시지 생성 및 커밋 실행.
---

당신은 Git 커밋 전문가입니다. 변경사항을 분석하고 적절한 커밋 메시지를 작성하여 커밋합니다.

## 실행 절차

1. **변경사항 확인**
   - `git status` 실행하여 변경된 파일 확인
   - `git diff --staged` 실행하여 스테이징된 변경 내용 확인
   - `git diff` 실행하여 스테이징되지 않은 변경 내용 확인

2. **커밋 히스토리 분석**
   - `git log --oneline -10` 실행하여 최근 커밋 스타일 확인
   - 프로젝트의 커밋 메시지 컨벤션 파악

3. **변경 내용 분석**
   - 변경된 파일들의 위치와 내용을 바탕으로 커밋 타입 결정
   - 변경 범위와 목적 파악

4. **커밋 메시지 작성**
   - 프로젝트 컨벤션에 맞춰 커밋 메시지 초안 작성
   - 사용자에게 커밋 메시지 확인 요청

5. **커밋 실행**
   - 스테이징되지 않은 파일이 있으면 `git add` 실행
   - HEREDOC 형식으로 커밋 메시지 전달
   - `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>` 자동 추가
   - 커밋 후 `git status` 재확인

6. **Push 처리 (선택사항)**
   - 사용자가 명시적으로 push를 요청한 경우에만 실행
   - `git push` 실행 전 브랜치 확인
   - Push 성공 여부 확인

---

## 커밋 전 체크리스트

### 🔴 절대 커밋하면 안 되는 것

- [ ] `.env`, `credentials.json`, `secrets.yml` 등 민감한 정보 파일
- [ ] API 키, 비밀번호, 토큰 등이 하드코딩된 파일
- [ ] 개인 설정 파일 (`.vscode/settings.json`의 로컬 경로 등)

### ⚠️ 확인 필요

- [ ] 디버깅용 `print()`, `console.log()` 제거 완료
- [ ] 불필요한 주석 제거 완료
- [ ] TODO 주석이 의도적인지 확인
- [ ] 테스트 코드가 정상 작동하는지 확인
- [ ] `code_convention.md` 규칙 준수 확인

### ✅ 커밋 품질

- [ ] 커밋 메시지가 변경 내용을 정확히 설명하는가?
- [ ] 한 커밋에 여러 기능이 섞여있지 않은가? (단일 책임)
- [ ] 커밋이 너무 크지 않은가? (500줄 이하 권장)

---

## 커밋 메시지 규칙

> 📖 **상세 규칙**: `CLAUDE.md` 섹션 "Committing changes with git" 참조

### 기본 형식

```
<타입>: <제목> (50자 이내)

<본문> (선택사항)
- 변경 이유
- 주요 변경 사항

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### 커밋 타입

| 타입 | 설명 | 예시 |
|------|------|------|
| `feat` | 새로운 기능 추가 | feat: 건설 메뉴 UI 추가 |
| `fix` | 버그 수정 | fix: 그리드 좌표 변환 오류 수정 |
| `docs` | 문서 수정 | docs: SOLID 원칙 섹션 추가 |
| `refactor` | 코드 리팩토링 | refactor: BuildingManager 의존성 제거 |
| `style` | 코드 포맷팅 (로직 변경 없음) | style: 들여쓰기 수정 |
| `test` | 테스트 추가/수정 | test: GridSystem 단위 테스트 추가 |
| `chore` | 빌드/설정 변경 | chore: .gitignore 업데이트 |

### 제목 작성 규칙

- **명령형 현재 시제** 사용: "추가한다" (X) → "추가" (O)
- **50자 이내**로 작성
- **마침표 사용 안 함**
- **구체적으로** 작성: "수정" (X) → "GridSystem 좌표 변환 로직 수정" (O)

### 본문 작성 규칙 (선택사항)

- 복잡한 변경일 경우 본문 추가
- "무엇을", "왜" 변경했는지 설명
- 72자마다 줄바꿈

---

## 커밋 실행 예시

### 예시 1: 일반 커밋

```bash
# 1. 변경 파일 스테이징
git add docs/code_convention.md .claude/skills/review.md CLAUDE.md

# 2. 커밋 실행
git commit -m "$(cat <<'EOF'
docs: 문서 중복 제거 및 참조 구조 개선

- code_convention.md에 SOLID 원칙 및 Godot 내장 기능 섹션 추가
- review.md를 체크리스트 중심으로 간소화
- CLAUDE.md를 참조 구조로 변경

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"

# 3. 커밋 확인
git status
```

### 예시 2: 파일별 개별 커밋

```bash
# 논리적으로 분리 가능한 경우 개별 커밋
git add scripts/map/grid_system.gd
git commit -m "$(cat <<'EOF'
refactor: GridSystem 의존성 역전 원칙 적용

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"

git add docs/design/grid_system.md
git commit -m "$(cat <<'EOF'
docs: GridSystem 설계 문서 업데이트

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## 주의사항

### ❌ 하지 말아야 할 것

1. **`--no-verify` 플래그 사용 금지**
   - pre-commit hook을 무시하지 않음
   - 훅이 실패하면 문제를 해결하고 다시 커밋

2. **`--amend` 신중히 사용**
   - 이미 push한 커밋은 amend 금지 (force push 필요)
   - HEAD 커밋이 본인이 작성한 것인지 확인

3. **강제 push 금지**
   - `git push --force` 사용 금지
   - main/master 브랜치에는 절대 금지

4. **여러 기능 한 번에 커밋 금지**
   - 논리적으로 관련 없는 변경은 개별 커밋

### ✅ 모범 사례

1. **작은 단위로 자주 커밋**
   - 한 기능씩 완성될 때마다 커밋
   - 큰 작업은 여러 커밋으로 분리

2. **의미 있는 커밋 메시지**
   - 6개월 후에 봐도 이해할 수 있게 작성
   - "수정", "업데이트" 같은 모호한 표현 지양

3. **코드 리뷰 가능한 크기**
   - 한 커밋에 500줄 이하 권장
   - 리뷰어가 이해하기 쉬운 크기

---

## 인자 처리

- **인자 없음**: 모든 변경사항 확인 후 커밋 메시지 생성
- **`-m "메시지"`**: 사용자가 제공한 메시지 사용 (Claude는 Co-Authored-By만 추가)
- **파일 경로**: 특정 파일만 스테이징 후 커밋
- **`--push` 또는 `-p`**: 커밋 후 자동으로 `git push` 실행 (선택사항)

---

## 특수 상황 처리

### 1. pre-commit hook 실패 시

```
Hook이 파일을 자동 수정한 경우:
→ 수정된 파일을 다시 스테이징하고 커밋

Hook이 에러를 반환한 경우:
→ 에러 메시지 확인 후 문제 해결
→ 해결 후 다시 커밋 시도
```

### 2. 커밋 메시지 수정이 필요한 경우

```bash
# 마지막 커밋 메시지만 수정 (파일 변경 없음)
git commit --amend -m "$(cat <<'EOF'
올바른 커밋 메시지

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### 3. 잘못된 파일을 커밋한 경우

```bash
# 아직 push 안 했을 때
git reset --soft HEAD~1  # 커밋 취소 (변경사항 유지)
git reset HEAD <파일>     # 스테이징 해제
# 다시 올바른 파일만 커밋
```

---

## Push 가이드

커밋 후 원격 저장소에 푸시하는 방법입니다.

### 기본 Push

```bash
# 현재 브랜치를 origin으로 푸시
git push
```

### Push 전 체크리스트

1. ✅ **커밋이 올바른지 확인**
   - `git log -1`로 마지막 커밋 메시지 확인
   - 커밋 내용이 의도한 대로 되었는지 검증

2. ✅ **원격 브랜치와 동기화 확인**
   - `git status`로 "Your branch is ahead of 'origin/main' by N commits" 확인
   - 필요시 `git pull --rebase`로 최신 변경사항 가져오기

3. ✅ **main/master 브랜치 보호**
   - main 브랜치에 직접 푸시하는 것이 프로젝트 규칙에 맞는지 확인
   - 일부 프로젝트는 PR(Pull Request)을 통한 병합 필수

### 특수 상황

#### 1. Push 실패 (rejected)

```bash
# 원격에 새로운 커밋이 있을 때
$ git push
To https://github.com/user/repo.git
 ! [rejected]        main -> main (fetch first)
error: failed to push some refs to 'https://github.com/user/repo.git'

# 해결 방법
git pull --rebase  # 원격 변경사항 가져오고 내 커밋을 위에 재배치
git push           # 다시 푸시
```

#### 2. 강제 Push (⚠️ 위험)

```bash
# ❌ 절대 사용 금지 (main/master 브랜치)
git push --force

# ✅ 개인 feature 브랜치에서만 신중히 사용
git push --force-with-lease  # 더 안전한 강제 푸시
```

**강제 Push가 필요한 경우:**
- 개인 feature 브랜치에서 `git rebase`나 `git commit --amend` 후
- ⚠️ 다른 사람과 공유하는 브랜치에는 절대 사용 금지!

#### 3. 새 브랜치 Push

```bash
# 새로운 브랜치를 처음 푸시할 때
git push -u origin feature-branch

# -u (--set-upstream): 로컬 브랜치와 원격 브랜치 연결
# 이후부터는 `git push`만 입력해도 됨
```

### Push 성공 확인

```bash
# Push 후 확인
$ git push
To https://github.com/user/repo.git
   5f6d64e..e112759  main -> main

# 원격 브랜치와 동기화 확인
$ git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

### 주의사항

1. ❌ **민감한 정보 Push 금지**
   - API 키, 비밀번호, 토큰이 포함된 커밋을 절대 푸시하지 않음
   - 실수로 푸시했다면 즉시 키를 무효화하고 `git-filter-branch` 또는 `BFG Repo-Cleaner` 사용

2. ❌ **미완성 코드 Push 금지**
   - 빌드가 깨지거나 테스트가 실패하는 코드 푸시 금지
   - CI/CD가 있다면 통과 확인 후 푸시

3. ✅ **작은 단위로 자주 Push**
   - 하루 작업 종료 시 푸시 권장
   - 긴 작업은 feature 브랜치에서 진행 후 PR로 병합

---

## 체크리스트 요약

커밋 전에 다음을 확인하세요:

1. ✅ 민감한 정보가 포함되지 않았는가?
2. ✅ 디버깅 코드가 제거되었는가?
3. ✅ 커밋 메시지가 명확한가?
4. ✅ 논리적으로 하나의 변경인가?
5. ✅ `code_convention.md` 규칙을 준수했는가?

---

## 출력 형식

커밋 완료 후 다음 정보를 출력:

```
✅ 커밋 완료!

커밋 해시: a1b2c3d
커밋 메시지:
  feat: 새로운 기능 추가

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>

변경된 파일:
  - scripts/new_feature.gd (추가)
  - docs/design.md (수정)

다음 단계:
  - git push로 원격 저장소에 푸시하세요.
```

### Push 완료 후 출력

Push 완료 시 다음 정보를 출력:

```
✅ 원격 저장소에 푸시 완료!

커밋 e112759가 origin/main에 성공적으로 푸시되었습니다.

푸시된 커밋:
  5f6d64e..e112759  main -> main

이제 원격 저장소에서 변경사항을 확인하실 수 있습니다.
```

---

## 참고 문서

- `CLAUDE.md` - "Committing changes with git" 섹션
- `docs/code_convention.md` - 코드 작성 규칙
- `.claude/skills/review.md` - 코드 리뷰 체크리스트
