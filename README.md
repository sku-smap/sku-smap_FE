# 🚀 SMAP-Frontend

SMAP Flutter 프론트엔드 프로젝트 협업을 위한 Git 및 코드 작성 규칙입니다.

---

# 🛠 Tech Stack

| Category         | Stack            |
| ---------------- | ---------------- |
| Framework        | Flutter 3.47     |
| Language         | Dart             |
| Platform         | Android, iOS, Web |
| Routing          | go_router        |
| State Management | Riverpod         |
| HTTP Client      | Dio              |
| Asset            | flutter_svg      |
| Code Quality     | flutter_lints, dart format |

---

# 🌿 Branch Convention

안정적인 배포와 독립적인 기능 개발을 위해 Git Flow를 사용합니다.

- 🔵 **main** : 항상 배포 가능한 운영 브랜치
  - 직접 작업 금지
  - Pull Request를 통해서만 병합
- 🟣 **develop** : 다음 배포를 준비하는 통합 개발 브랜치
- 🟢 **feature** : 기능 또는 이슈 단위로 `develop`에서 생성하는 작업 브랜치

```text
main
 └── develop
      ├── feat/10-home-screen
      ├── feat/11-street-view
      ├── fix/15-tab-bar
      └── chore/1-lint-setting
```

---

# 📌 Branch Naming Convention

## 구조

```text
prefix/이슈번호-작업내용
```

## 예시

```text
feat/10-search-screen
fix/23-splash-animation
docs/5-update-readme
design/12-home-bottom-sheet
refactor/30-route-state
chore/1-lint-setting
```

| Prefix     | 설명                   |
| ---------- | ---------------------- |
| `feat`     | 새로운 기능 추가       |
| `fix`      | 버그 수정              |
| `hotfix`   | 긴급 버그 수정         |
| `design`   | 화면 UI 및 위젯 스타일 수정 |
| `refactor` | 코드 리팩토링          |
| `docs`     | 문서 수정              |
| `chore`    | 설정 파일 및 환경 변경 |

## 작성 규칙

- 영문 소문자와 숫자를 사용합니다.
- 단어 구분은 하이픈 `-`을 사용합니다.
- 브랜치명에는 `#`을 사용하지 않습니다.
- 한 브랜치는 하나의 이슈만 담당합니다.

```text
feat/10-search-screen   ✅
fix/23-splash-animation ✅

feat/#10-search         ❌
feature/SearchScreen    ❌
```

---

# 📝 Commit Convention

커밋 메시지는 아래 형식으로 작성합니다.

```text
이모지 Type: 작업 내용
```

## 예시

```text
🎉 Start: Flutter 프로젝트 초기 설정

✨ Feat: 도착지 검색 화면 구현

🐛 Fix: 스플래시 화면 전환 오류 수정

🚑 Hotfix: 배포 환경 길안내 오류 긴급 수정

🎨 Design: 홈 건물 시트 스타일 수정

♻️ Refactor: 거리뷰 단계 카드 위젯 분리

🔧 Settings: 라우트 및 assets 경로 등록

🗃️ Comment: 경로 탐색 로직 주석 추가

➕ Dependency/Plugin: go_router 추가

📝 Docs: README 협업 규칙 수정

🔀 Merge: 검색 기능 브랜치 병합

🚀 Deploy: 운영 환경 배포

🚚 Rename: 제보 화면 파일명 변경

🔥 Remove: 사용하지 않는 위젯 삭제

⏪ Revert: 길안내 로직 이전 버전으로 복구
```

| 이모지 | Type                | 설명                             |
| ------ | ------------------- | -------------------------------- |
| 🎉     | `Start`             | 프로젝트 생성 및 초기 설정       |
| ✨     | `Feat`              | 새로운 기능 구현                 |
| 🐛     | `Fix`               | 버그 수정                        |
| 🚑     | `Hotfix`            | 긴급 버그 수정                   |
| 🎨     | `Design`            | 화면 UI 및 위젯 스타일 변경      |
| ♻️     | `Refactor`          | 기능 변경 없는 코드 구조 개선    |
| 🔧     | `Settings`          | 개발 환경 및 설정 파일 변경      |
| 🗃️     | `Comment`           | 주석 추가 및 수정                |
| ➕     | `Dependency/Plugin` | 패키지 및 플러그인 추가          |
| 📝     | `Docs`              | 문서 추가 및 수정                |
| 🔀     | `Merge`             | 브랜치 병합                      |
| 🚀     | `Deploy`            | 배포 관련 작업                   |
| 🚚     | `Rename`            | 파일 및 폴더 이름 변경 또는 이동 |
| 🔥     | `Remove`            | 파일 및 코드 삭제                |
| ⏪     | `Revert`            | 이전 커밋으로 되돌리기           |

## 커밋 작성 규칙

- 제목 끝에 마침표를 붙이지 않습니다.
- 한 커밋에는 하나의 논리적 변경만 포함합니다.
- `수정`, `작업`, `변경`처럼 모호한 표현만 사용하지 않습니다.
- 가능하면 기능 변경과 UI 변경을 분리합니다.

```text
🐛 Fix: 버그 수정                           ❌
🐛 Fix: 길찾기 버튼 중복 실행 오류 수정     ✅
```
