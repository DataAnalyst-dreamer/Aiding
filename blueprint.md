# 아이딩(Aiding) 프로젝트 청사진 (Blueprint)

본 문서는 `GEMINI.md` 제5항(기능 개발 필수 절차)에 따라, 앱의 전체적인 구현 상태와 현재 진행 중인 작업의 상세 계획을 추적하는 핵심 파일입니다. `Aiding_BRD_v2_Final.md`와 `GEMINI.md`를 기반으로 작성되었습니다.

---

## 1. 앱 개요 및 비즈니스 모델 요약

**아이딩(Aiding)**은 첫째 아이를 키우는 30대 초반 맞벌이 부모의 '육아용품 결정 장애'를 AI로 해결하는 큐레이션 서비스입니다. 
- **수익 모델:** B2C 프리미엄 구독 (월 2,900원, Paywall 연동) + B2B 쿠팡/네이버 제휴 커머스 수수료
- **운영 모델:** 1인 창업자(주 4~6시간 투입) + 8-Agent AI 자동화 시스템 (개발, 기획, 데이터, 법무 등 위임)
- **핵심 UI:** Bottom 4탭 구조 (홈 / 추천관 / AI 상담 / 성장 리포트) + M3 민트그린 테마 적용.

---

## 2. 구현된 기능 목록 (기반 아키텍처 상태)

현재 프로젝트는 MVP 전(Phase 0) 단계로 초기 프레임워크 셋업이 일부 진행된 상태입니다.

- [x] **Flutter + Firebase 기본 환경 셋업:** `lib/main.dart` 기반 진입점 설정 및 `firebase_options.dart` 초기화.
- [x] **라우팅 (go_router):** `ShellRoute`를 이용한 탭 내비게이션 및 `/login`, `/onboarding` 등 기본 패스(Path) 뼈대 구축 완료.
- [x] **상태 관리 (Provider):** `ThemeProvider`(다크모드 지원) 및 `AuthProvider`(Firebase 인증 리스너) 전역 설정 완료.
- [x] **디자인 시스템:** `google_fonts` 연동 및 `ThemeData`(Material 3) 기반 색상 정의(`0xFF4ECDC4` 등) 적용.
- [x] **문서화:** `GEMINI.md`, `Aiding_BRD_v2_Final.md`, `task.md` 확립 및 AI 에이전트 지침 스냅샷 완료.

---

## 3. 개발 예정 백로그 (MVP 타임라인)

`BRD`에 정의된 타임라인 및 기능 명세에 맞춰 앞으로 구현될 핵심 기능들을 추적합니다.

### Phase 1: MVP Core (인증 및 온보딩, 기본 추천)
- [ ] 소셜 로그인 (Google/Apple) 연동 (Firebase Auth)
- [ ] 아이 생일 입력 달력 UI 및 Firestore `users` DB 연동
- [ ] Firebase AI SDK(`firebase_ai`) 연계 테스트 및 추천 프롬프트 기초 통신
- [ ] 추천관 UI 카드 구현 및 인앱 브라우저(`url_launcher`) 제휴 링크 연결

### Phase 2: AI & Monetization (수익화 및 리텐션)
- [ ] RevenueCat 결제 모듈 연동 및 Paywall 바텀 시트 노출 (7일 Free Trial)
- [ ] 24시간 AI 육아 상담 챗 UI (무료 3회 카운팅 로직 및 붉은색 면책조항 하드코딩)
- [ ] 매거진(팩트체크 콘텐츠) 리스트 타일 형태 레이아웃 구축
- [ ] FCM 푸시 알림 세팅 (Cloud Functions 연동)

---

## 4. 현재 작업 중인 변경 사항 (Current Sprint)

다음 진행할 작업에 대한 상세 계획과 단계입니다.

### 🔥 [Sprint 1] 수익화 투트랙 구조의 뼈대 설계 및 계층형 아키텍처 개편
- **목표:** 개발을 본격적으로 시작하기 전, `freezed` 모델, `RevenueCat` 결제 준비, API 키 환경변수 세팅 등 기반 작업을 완수합니다. (BRD 5. 앱 아키텍처 및 디자인 가이드 반영)

#### 세부 Task
1. [ ] **패키지 설치 및 셋업:** `url_launcher`, `purchases_flutter` (RevenueCat), `freezed_annotation`, `firebase_ai` 등 필수 라이브러리 `pubspec.yaml` 반영.
2. [ ] **디렉토리 구조 재편:** MVC/MVVM에 준수하는 `models`, `providers`, `screens`, `widgets`, `services` 구성 (`lib/` 하위).
3. [ ] **Theme 고도화:** `lib/config/theme.dart`에 BRD 정의 컬러 팔레트 완벽 이식 (Light/Dark 분기 철저).
4. [ ] `.env` 연동 및 `.gitignore` 은닉 상태 최종 점검 (API 키 노출 방어).

> ⚠️ 이 스프린트 승인 완료 시, 곧바로 `feature/architectural-setup` 브랜치를 생성하여 코드 변경을 시작합니다!
