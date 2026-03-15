# GEMINI.md — 아이딩(Aiding) 프로젝트 Agent Rules (v2)

---

## 1. 프로젝트 정체성 (Agent가 항상 기억할 것)

```
앱 이름:     아이딩 (Aiding) — AI + 아이(child) + 돕다(Aiding) 삼중 의미
핵심 가치:   초보 부모(0~36개월 첫째 아이, 30대 초반 맞벌이)의 육아용품 결정 장애를 AI로 해결
수익 모델:   쿠팡파트너스/네이버 제휴 수수료 기반 무료 서비스 (광고 없음)
UI 색상:     민트그린(#4ECDC4) / 웜화이트(#FAFAF8) / 코랄(#FF6B6B) 포인트
앱 구조:     Bottom 4탭 — [홈] [Aiding 매거진] [큐레이션(쇼핑)] [AI 챗]
출시 목표:   iOS + Android 동시 출시
운영 모델:   1인 창업자, 주 4~6시간 운영, 80~90% AI 에이전트 자동화
```

---

## 2. 기술 스택 (임의 변경 금지)

| 영역 | 선택 | 이유 |
|------|------|------|
| 앱 프레임워크 | **Flutter (Firebase Studio 기반)** | iOS·Android 동시, Code OSS IDE 통합 |
| AI 코드 생성 | **AI 코딩 어시스턴트 (Gemini in Firebase Studio)** | 전 기능 코드 생성 도구 |
| 백엔드/DB | **Firebase (Firestore + Functions)** | 서버리스, 실시간 DB |
| 인증(로그인) | **Firebase Auth** (Google/Apple 소셜) | 직접 구현 불필요 |
| AI 기능 | **Firebase AI SDK (firebase_ai)** | Gemini API 보안 통합, App Check 연동 |
| 제휴 커머스 | **쿠팡파트너스 + 네이버 쇼핑 API** | 클릭당 수수료 |
| 앱 빌드/배포 | **Firebase App Distribution → 앱스토어** | EAS 대안 |
| 분석 | **Firebase Analytics + Google Looker Studio** | 무료 대시보드 |
| 푸시 알림 | **Firebase Cloud Messaging (FCM)** | 월령 맞춤 선제적 알림 핵심 |
| 상태 관리 | **Provider (ChangeNotifierProvider)** | 공식 권장, 비개발자 친화 |
| 라우팅 | **go_router** | 딥링크 지원, 선언적 라우팅 |

> ⚠️ 새 패키지·외부 서비스 추가 시 반드시 이유와 예상 비용을 먼저 알리고 승인받는다.

---

## 3. 개발 환경 설정 (Firebase Studio)

### dev.nix 구성

`.idx/dev.nix` 파일은 워크스페이스 환경의 선언적 설정 파일이다. AI는 이 파일의 역할을 이해하고, 필요한 시스템 도구·IDE 확장·환경 변수·시작 명령어가 올바르게 설정되어 있는지 확인한다.

### 프리뷰 서버 활용

- Firebase Studio의 프리뷰 서버(웹/Android 에뮬레이터)는 Hot Reload를 자동 제공한다.
- AI는 코드 변경 후 프리뷰 서버의 콘솔 로그, 에러 메시지, 시각적 렌더링을 확인하여 실시간 피드백을 수집한다.
- 구조적 변경, 의존성 업데이트, 또는 해결되지 않는 이슈가 있을 경우 프리뷰 환경의 Full Reload 또는 Hard Restart를 실행한다.

### Firebase 통합

- `flutterfire configure`로 생성된 `firebase_options.dart`를 통해 Firebase 서비스를 연결한다.
- `lib/main.dart`에서 Firebase 초기화가 앱 시작 전에 반드시 완료되어야 한다:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}
```

### Firebase MCP 서버 설정

Firebase MCP 연동이 필요한 경우, `.idx/mcp.json`에 아래 내용만 추가한다:

```json
{
    "mcpServers": {
        "firebase": {
            "command": "npx",
            "args": [
                "-y",
                "firebase-tools@latest",
                "experimental:mcp"
            ]
        }
    }
}
```

---

## 4. 핵심 기능 목록 (MVP 범위 기준)

아래 기능이 MVP의 전부다. 목록에 없는 기능은 요청 없이 추가하지 않는다.

| 기능 | 설명 | 우선순위 |
|------|------|---------|
| 온보딩 | 아이 생년월일 입력 → Firestore 저장 → 즉각 개인화 | ⭐⭐⭐ |
| 월령 맞춤 AI 추천 | Firebase AI SDK(Gemini) 기반 월령별 육아용품 큐레이션 카드 | ⭐⭐⭐ |
| 선제적 푸시 알림 | FCM + 월령 데이터 기반 "지금 필요한 것" 알림 | ⭐⭐⭐ |
| 제휴 커머스 링크 | 쿠팡파트너스/네이버 제휴 링크 인앱 브라우저 연결 | ⭐⭐⭐ |
| AI 챗 (육아 Q&A) | Firebase AI SDK(Gemini) 기반 24시간 육아 상담 챗봇 | ⭐⭐ |
| Aiding 매거진 | 공식 기관 데이터 기반 팩트체크 육아 콘텐츠 | ⭐⭐ |
| 소셜 프루프 UI | "현재 N명이 이 상품 관심" 표시 | ⭐ |

> 💡 **Firebase DB 구조 원칙:** Firestore Collection은 `users`(사용자 및 온보딩), `products`(큐레이션 상품 및 제휴 링크), `contents`(Aiding 매거진) 3개로 단순 유지한다. 불필요한 서브컬렉션을 만들지 않는다.

---

## 5. 기능 개발 필수 절차

모든 신규 기능 개발은 아래 6단계를 반드시 순서대로 따른다.

```
1단계 — 요청 확인
  요청 내용을 한국어로 다시 요약하여 맞게 이해했는지 확인한다.

2단계 — 계획 제시 및 blueprint.md 업데이트
  만들거나 수정할 파일과 기능 목록을 먼저 보여준다.
  완성 후 사용자(부모) 입장에서 어떻게 보이는지 설명한다.
  프로젝트 루트의 blueprint.md를 업데이트하여 현재 변경 계획을 기록한다.
  ※ blueprint.md 구성:
    - 앱 개요 및 현재 구현 상태
    - 구현된 기능 목록 (초기 버전~현재 버전)
    - 현재 작업 중인 변경 사항의 계획과 단계

3단계 — 승인 대기
  1~2단계 내용에 대해 승인을 받은 후에만 다음으로 넘어간다.

4단계 — 브랜치 생성 (필수 — 절대 생략 불가)
  main 브랜치에서 기능 전용 브랜치를 생성한다.
  브랜치 이름 규칙: feature/기능명-간략설명
  예시:
    feature/onboarding-birthdate-input
    feature/gemini-product-recommendation
    feature/fcm-push-notification
    feature/affiliate-link-browser

  실행 명령어 (승인 후):
    git checkout main
    git pull origin main
    git checkout -b feature/[기능명]

5단계 — 코드 작성 및 자동 검증
  브랜치 생성이 확인된 후에만 코드를 작성한다.
  작업 중 의미 있는 단위마다 커밋(commit)한다.
  커밋 메시지 규칙: [기능명] 작업 내용 한 줄 요약
  예시: [onboarding] 아이 생년월일 입력 화면 구현

  코드 작성 후 §6 자동 검증 절차를 반드시 수행한다.

6단계 — 완료 보고 및 병합 안내
  작업 완료 후 §11 보고 형식에 따라 보고한다.
  main 브랜치로의 병합(merge)은 직접 실행하지 않고
  "병합할 준비가 되었습니다. 병합할까요?" 로 확인을 받는다.
```

> ⚠️ 브랜치 없이 main에서 직접 코드를 작성하지 않는다.
> ⚠️ 계획(2단계) 없이 바로 코드를 작성하거나 파일을 생성하지 않는다.

---

## 6. 코드 작성 규칙 및 자동 검증 절차

### 코드 품질 기준

- **관심사 분리**: UI 로직(위젯)과 비즈니스 로직(Provider/Service)을 분리한다.
- **const 활용**: 변경되지 않는 위젯에는 반드시 `const` 생성자를 사용한다.
- **async/await**: 비동기 작업에는 try-catch 블록과 `mounted` 체크를 반드시 포함한다.
- **네이밍**: Dart 공식 컨벤션을 따른다 (클래스: PascalCase, 변수/함수: camelCase, 파일: snake_case).
- **build() 내 금지**: 비용이 큰 연산이나 I/O 작업을 build 메서드 안에서 직접 실행하지 않는다.

### 프로젝트 폴더 구조

```
lib/
├── main.dart                     # 앱 진입점
├── config/
│   └── theme.dart                # 테마 설정 (색상, 폰트, 컴포넌트)
├── models/                       # 데이터 모델
├── providers/                    # 상태 관리 (ChangeNotifier)
├── services/                     # Firebase, API 연동 서비스
├── screens/                      # 화면별 위젯
│   ├── home/
│   ├── magazine/
│   ├── curation/
│   └── chat/
└── widgets/                      # 공용 위젯 컴포넌트
```

### 패키지 관리

- 일반 의존성 추가: `flutter pub add <package_name>`
- 개발 의존성 추가: `flutter pub add dev:<package_name>`
- 코드 생성이 필요한 경우 (freezed, json_serializable 등):
  1. `build_runner`가 dev_dependencies에 있는지 확인
  2. `dart run build_runner build --delete-conflicting-outputs` 실행

### 자동 검증 절차 (모든 코드 변경 후 필수)

```
1. 린트/포맷:     dart format .
2. 의존성 확인:   flutter pub get (pubspec.yaml 변경 시)
3. 코드 생성:     dart run build_runner build --delete-conflicting-outputs (필요 시)
4. 정적 분석:     flutter analyze (경고/에러 확인)
5. 자동 수정:     flutter fix --apply . (분석 에러 발견 시 우선 시도)
6. 프리뷰 확인:   프리뷰 서버의 시각적 렌더링 및 런타임 에러 확인
7. 테스트 실행:   flutter test (테스트가 있는 경우)
```

> 위 절차에서 에러가 발견되면 자동 수정을 시도한다. 자동 수정 불가 시 §10 형식으로 보고한다.

---

## 7. 터미널 명령어 실행 규칙

명령어 실행 전 반드시 확인을 받는다.

```
[실행할 명령어] 예: flutter pub add firebase_messaging
[하는 일] 푸시 알림(FCM) 기능을 프로젝트에 추가합니다.
[생기는 변화] pubspec.yaml에 firebase_messaging 항목이 추가됩니다.
→ 실행해도 될까요?
```

파일 삭제 / Firestore 데이터 초기화 / 앱스토어 배포 명령은 **두 번 확인**한다.

---

## 8. UI/UX 설계 규칙

### Material Design 3 테마 적용

앱 전체에 Material 3 디자인 시스템을 적용한다. 테마는 `lib/config/theme.dart`에 중앙 관리한다.

```dart
// lib/config/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AidingTheme {
  static const Color mintGreen = Color(0xFF4ECDC4);
  static const Color warmWhite = Color(0xFFFAFAF8);
  static const Color coral = Color(0xFFFF6B6B);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mintGreen,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: warmWhite,
    textTheme: GoogleFonts.notoSansKrTextTheme(),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: mintGreen,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.notoSansKrTextTheme(),
  );
}
```

### 비주얼 디자인 원칙

- **모바일 우선**: 모든 화면은 모바일 기준으로 설계하고, 웹에서도 정상 동작하도록 반응형 처리한다.
- **여백과 균형**: 깔끔한 간격, 정돈된 레이아웃으로 초보 부모가 직관적으로 탐색할 수 있게 한다.
- **색상 활용**: 민트그린은 주요 액션, 코랄은 주의/강조 포인트에만 제한 사용한다.
- **아이콘**: `Icons` 클래스(Material Design)를 기본 사용하고, 커스텀 아이콘은 `assets/icons/`에 선언 후 사용한다.
- **이미지**: 네트워크 이미지에는 반드시 `loadingBuilder`와 `errorBuilder`를 포함한다. 실제 이미지가 없는 경우 적절한 플레이스홀더를 제공한다.
- **접근성(A11Y)**: 모든 인터랙티브 요소에 의미 있는 시맨틱 레이블을 제공하고, 최소 터치 영역 48x48을 준수한다.

### 라우팅 (go_router)

```dart
final GoRouter router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child), // Bottom 4탭 쉘
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/magazine', builder: (_, __) => const MagazineScreen()),
        GoRoute(path: '/curation', builder: (_, __) => const CurationScreen()),
        GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      ],
    ),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
  ],
);
```

---

## 9. AI 기능 구현 규칙 (Firebase AI SDK)

### Gemini API 연동 — firebase_ai 패키지 사용

AI 기능은 반드시 `firebase_ai` 패키지를 통해 호출한다. API 키를 직접 코드에 포함하지 않으며, Firebase App Check가 보안을 관리한다.

```dart
import 'package:firebase_ai/firebase_ai.dart';

// 텍스트 생성 (월령 맞춤 추천, AI 챗 등)
Future<String> generateRecommendation(String prompt) async {
  try {
    final model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',  // 속도-성능 균형 모델
    );
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? '추천 결과를 가져올 수 없습니다.';
  } catch (e) {
    return '오류가 발생했습니다: $e';
  }
}
```

### AI 프롬프트 안전 규칙

모든 Gemini 호출 프롬프트에 아래 시스템 지시문을 포함한다:

```
당신은 0~36개월 영유아 부모를 돕는 육아 어시스턴트입니다.
규칙:
- 의학적 진단이나 처방을 하지 않습니다. 이상 증상은 반드시 "전문의 진료를 받으세요"로 안내합니다.
- 특정 제품의 효과를 보장하는 표현을 하지 않습니다.
- 출처가 불명확한 민간요법을 추천하지 않습니다.
- 월령 정보를 기반으로 발달 단계에 맞는 실용적 조언을 제공합니다.
```

---

## 10. 콘텐츠 생성 규칙 (Aiding 매거진)

AI 콘텐츠는 반드시 아래 파이프라인을 따른다.

```
허용 소스만 사용 (화이트리스트)
  🟢 1급: 보건복지부, 질병관리청, 식약처 공식 자료
  🟡 2급: 서울대병원 의학정보, 대한소아청소년과학회, AAP(미국소아과학회)
  🔴 금지: 맘카페 게시글, 타사 앱 칼럼, 인플루언서 피드, 네이버 프리미엄

AI 톤 제거 제어 프롬프트 (반드시 적용)
  - "요즘 날씨가~", "오늘 알아볼까요?" 같은 블로그 말투 금지
  - 이모지, 감성 표현 금지
  - 오직 수치·팩트·행동 지침만 건조한 언론사 톤으로 3줄 요약

법적 면책 조항 (모든 콘텐츠 하단 하드코딩 필수)
  "본 콘텐츠는 공공기관 자료를 요약한 참고용 정보입니다.
   의학적 이상 증상이 있을 경우 반드시 전문의의 진료를 받으세요."

금지 표현 (AI가 절대 생성하지 않도록 Negative Prompt 적용)
  - "이 제품만 먹으면 낫는다" / "효과가 보장된다" 등 결과 확언 표현
  - 의약(외)품에 대한 과대 광고성 문구
```

---

## 11. 보안 및 개인정보 규칙 (필수 — 아동 데이터 취급 앱)

### API 키 보안 — Firebase AI SDK 우선 사용

Firebase AI SDK(`firebase_ai`)를 사용하면 Gemini API 키가 코드에 포함되지 않으며 Firebase App Check가 보안을 관리한다. 따라서 Gemini API 호출 시 `.env`에 별도 키를 저장할 필요가 없다.

### .env 파일 관리 (Firebase AI SDK 외 키가 필요한 경우)

쿠팡파트너스, 네이버 쇼핑 API 등 Firebase 외부 서비스 키가 필요한 경우에만 `.env` 파일을 사용한다.

**1. .env 파일 생성**
```
# 아이딩(Aiding) 환경변수 — 절대 외부에 공유하지 말 것
COUPANG_API_KEY=여기에_발급받은_키_입력
NAVER_CLIENT_ID=여기에_발급받은_키_입력
NAVER_CLIENT_SECRET=여기에_발급받은_키_입력
```

**2. .gitignore에 .env 등록 (생성 즉시 처리)**
```
# 환경변수 파일 — Git에 절대 업로드되지 않도록 차단
.env
.env.local
.env.*.local
```
> ⚠️ `.gitignore` 등록 전에 `git add` 또는 `git commit`을 실행하지 않는다.

**3. 코드에서 환경변수 참조 방법**
```dart
// ❌ 절대 금지 — 키를 코드에 직접 입력
final apiKey = "XXXXXXXXXXXXXXX";

// ✅ 올바른 방법 — 환경변수에서 불러오기
final apiKey = const String.fromEnvironment('COUPANG_API_KEY');
```

**4. 보안 체크리스트 (새 기능 개발 시작 전 자동 점검)**
```
☐ .gitignore에 .env가 등록되어 있는가?
☐ 이번 기능에 새로 필요한 외부 API 키가 .env에 추가되었는가?
☐ 코드 어디에도 키 값이 직접 입력된 곳이 없는가?
☐ Firebase AI SDK로 처리 가능한 호출을 .env 키로 우회하고 있지 않은가?
```

### 그 외 보안 규칙

- Firestore 보안 규칙: **인증된 사용자만 본인 데이터 접근 가능**으로 설정. 다른 설정은 보안 위반이다.
- 아이 생년월일·사진 등 민감 데이터는 암호화 후 저장.
- 앱스토어 제출 시 Apple App Privacy + Google Data Safety 항목 반드시 입력 안내.
- 개인정보처리방침 + 이용약관은 앱 내 접근 가능한 위치에 항상 노출.

---

## 12. 오류 발생 시 보고 형식

```
[어떤 오류] 예: Gemini API 응답이 없습니다.
[왜 생겼는가] Firebase AI SDK 초기화가 누락되었거나 호출 횟수 초과입니다.
[해결 방법 A - 권장] Firebase 초기화 코드를 확인하고 재설정합니다.
[해결 방법 B] 캐시된 응답으로 임시 대체합니다. (권장하지 않음, 이유: 데이터 부정확)
→ 어떻게 진행할까요?
```

같은 오류 3번 반복 시 → "현재 방법을 바꿔야 할 것 같습니다. 다른 접근을 제안할까요?" 로 전환.

---

## 13. 작업 완료 보고 형식

```
✅ 완료: (부모 사용자 입장에서 무엇이 달라졌는지)
📁 변경된 파일: (파일명 목록)
▶️ 확인 방법: (앱 에뮬레이터 또는 실기기에서 어떻게 확인하는지)
💰 비용 영향: (API 호출 증가 등 있을 경우)
🔒 보안 확인: (Firestore 규칙, 개인정보 관련 있을 경우)
⚠️ 다음 단계: (이후 해야 할 것이 있다면)
```

---

## 14. 디버깅 및 로깅 규칙

### dart:developer 활용

`print()` 대신 `dart:developer`의 `log()` 함수를 사용하여 구조화된 로깅을 한다.

```dart
import 'dart:developer' as developer;

// 일반 로그
developer.log('온보딩 완료: 월령 ${months}개월', name: 'aiding.onboarding');

// 에러 로그
try {
  // ...
} catch (e, s) {
  developer.log(
    'Gemini 추천 생성 실패',
    name: 'aiding.ai',
    level: 1000,  // SEVERE
    error: e,
    stackTrace: s,
  );
}
```

### 에러 핸들링 원칙

- 모든 Firebase 및 API 호출에 try-catch를 적용한다.
- 사용자에게는 친절한 한국어 에러 메시지를 보여주고, 기술적 상세는 로그에 기록한다.
- `setState` 호출 전 반드시 `mounted` 체크를 수행한다.
- `dispose()` 메서드에서 리소스(컨트롤러, 스트림 구독 등)를 반드시 해제한다.

---

## 15. 금지 사항

- 요청하지 않은 기능을 임의로 추가하지 않는다.
- MVP 목록에 없는 기능(관리자 대시보드, 소셜 공유 등)을 선제적으로 구현하지 않는다.
- 허용되지 않은 소스에서 콘텐츠를 크롤링하지 않는다.
- 보안 규칙을 "일단 테스트 목적"으로 완화하지 않는다.
- 내가 이해하지 못하는 기술 용어를 설명 없이 사용하지 않는다.
- `localStorage`/`sessionStorage` 등 브라우저 스토리지 API를 사용하지 않는다 (Flutter 앱에서는 지원되지 않음).

---

*파일 위치: `프로젝트폴더/.gemini/GEMINI.md`*
*전역 규칙과 충돌 시 이 파일(프로젝트 규칙)이 우선 적용된다.*
