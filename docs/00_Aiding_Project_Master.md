# Aiding 앱 프로젝트 마스터 인덱스 (Project Master Index)

이 문서는 Aiding 앱 개발 및 비즈니스 기획과 관련된 핵심 문서들을 통합 관리하기 위한 프로젝트 마스터 인덱스입니다. AI 에이전트와 사용자(CEO)가 언제든지 전체 프로젝트의 맥락(Context)을 쉽게 파악하고 최신 상태로 유지할 수 있도록 구성되었습니다.

## 📂 핵심 문서 목록 (Core Documents)

1. **[비즈니스 타당성 분석 (Business Viability Analysis)](business_viability_analysis.md)**
   - 1인 창업가 관점에서 Aiding 앱의 재무/수익 모델(구독, 제휴 등), 예상 유지보수 비용, 손익분기점(BEP), 그리고 향후 성장 예측을 다룬 문서입니다.

2. **[비즈니스 모델 피벗 전략 (Business Model Pivot Strategy)](business_model_pivot_strategy.md)** 
   - 구독 모델의 한계와 마케팅 리스크를 극복하기 위해, '100% 무료화 + 커머스 올인' 및 '선제적 푸시 알림 기반'으로 사업 구조를 공격적으로 전환하는 핵심 전략 보고서입니다.

3. **[오리지널 콘텐츠 확보 및 UI/UX 전략 (Content Strategy & UX)](content_strategy_and_ux.md)** 
   - 부모들의 일일 접속(Retention)을 유도하기 위해, AI 톤을 배제하고 전문 기관의 팩트(RAG)만을 정제하여 매거진 형태로 제공하는 파이프라인과 하단 탭 배치안입니다.

4. **[콘텐츠 법무 및 저작권 가이드라인 (Content Legal Guidelines)](content_legal_guidelines.md)** 
   - AI 에이전트가 오리지널 콘텐츠를 수집하고 요약할 때 발생할 수 있는 저작권 침해 및 의료 정보 컴플라이언스(법적 책임) 리스크를 원천 차단하기 위한 3대 안전 수칙입니다.

5. **[비즈니스 요구사항 정의서 (BRD - Business Requirement Document)](brd_aiding_app.md)**
   - 제품의 비전, 해결하고자 하는 문제, 타겟 고객층, 그리고 릴리즈(출시)를 위한 최소 기능 요건(MVP Features)을 명확하게 정의한 기획서입니다.

6. **[유저 스토리 라인 (User Storylines)](user_storylines.md)**
   - 사용자가 처음 앱을 인지하고 설치하는 순간부터, 핵심 기능(수면기록 등)을 사용하고 꾸준히 앱을 유지(Retention)하게 되기까지의 고객 여정 지도를 시나리오로 작성한 문서입니다.

7. **[코드베이스 리뷰 (Codebase Review)](codebase_review.md)**
   - 기존에 작성된 Aiding 앱 프론트엔드/백엔드 서버 코드의 구조, 사용된 기술 스택(React, Firebase 등), 그리고 보안 및 성능상의 개선점 등을 정리한 기술 부채 및 아키텍처 검토 보고서입니다.

8. **[AI 멀티 에이전트 운영 전략 (Multi-Agent Operations v2)](multi_agent_operations_v2.md)**
   - 1인 체제에서 벗어나, 총 8개의 AI 에이전트(개발, PM, QA, CS/VoC, 데이터기획, 퍼포먼스 마케팅, CFO, 리걸)에게 실무의 90%를 위임하고 CEO는 의사결정(Approve)만 담당하는 '주 4시간 자동화 비즈니스 모델'의 아키텍처 가이드라인입니다.

9. **[GEMINI 에이전트 룰 리뷰 (Gemini AI Rules Review)](gemini_md_review.md)** *(NEW)*
   - AI 코딩 어시스턴트 통제를 위해 작성된 `Gemini.md` 파일이 아이딩 앱의 비즈니스 전략(1인 무인화, 커머스 몰빵, 팩트 콘텐츠 등)과 일치하는지 점검한 S급 호환성 검토 보고서입니다.

---

## 💡 AI 에이전트용 메모리 컨텍스트 최적화 (For Antigravity)
*   **Context Scope:** Aiding 앱과 관련된 새로운 코드를 작성하거나 비즈니스 기능을 제안할 때는 항상 이 `00_Aiding_Project_Master.md`를 기점으로 연결된 요구사항 및 에이전트 운영 전략을 선제적으로 참조할 것.
*   **Location:** 이 문서들과 하위 명세서들은 언제나 `C:\Users\freer\.gemini\antigravity\scratch\Aiding\docs` 디렉토리 하위에 보관 및 업데이트됨.
