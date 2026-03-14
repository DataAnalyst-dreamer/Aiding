// ─────────────────────────────────────────────────────────────
// lib/services/gemini_service.dart
//
// Gemini API 연동 서비스
// - API 키를 .env 파일에서 안전하게 불러옴
// - 싱글톤(Singleton) 패턴: 앱 전체에서 하나의 인스턴스만 사용
// ─────────────────────────────────────────────────────────────

import 'dart:convert'; // JSON 파싱용
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ── 상품 추천 데이터 모델 ──────────────────────────────────────
// Gemini가 추천하는 상품 1개를 담는 데이터 클래스
class ProductRecommendation {
  final String name;       // 상품명    예: "에르고베이비 옴니 브리즈 허리띠"
  final String reason;     // 추천이유  예: "신생아부터 20kg까지 사용 가능하고..."
  final String priceRange; // 가격대    예: "30~50만원"

  ProductRecommendation({
    required this.name,
    required this.reason,
    required this.priceRange,
  });

  // JSON(Map)에서 객체 생성
  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      name: json['name']?.toString() ?? '이름 없음',
      reason: json['reason']?.toString() ?? '',
      priceRange: json['priceRange']?.toString() ?? '',
    );
  }

  @override
  String toString() => 'ProductRecommendation(name: $name, priceRange: $priceRange)';
}

// ── GeminiService 클래스 ────────────────────────────────────
class GeminiService {
  // 앱 어디서든 GeminiService.instance 로 호출 가능 (싱글톤)
  static GeminiService? _instance;
  late final GenerativeModel _model;

  GeminiService._internal() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty || apiKey == '여기에_실제_API_키를_입력하세요') {
      throw Exception(
        'GEMINI_API_KEY가 .env 파일에 설정되지 않았습니다.\n'
        '.env 파일을 열고 실제 API 키를 입력해주세요.',
      );
    }

    _model = GenerativeModel(
      // gemini-1.5-flash: 빠르고 저렴한 모델 (추천)
      // gemini-1.5-pro: 더 똑똑하지만 느리고 비쌈
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7, // 창의성 (0.0 정확 ~ 1.0 창의적)
        maxOutputTokens: 2048,
      ),
    );
  }

  static GeminiService get instance {
    _instance ??= GeminiService._internal();
    return _instance!;
  }

  // ── ① 기본 텍스트 생성 (내부 공통 함수) ──────────────────────
  Future<String> generateText(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? '응답을 생성할 수 없습니다.';
    } on GenerativeAIException catch (e) {
      throw Exception('Gemini API 오류: ${e.message}');
    } catch (e) {
      throw Exception('알 수 없는 오류: $e');
    }
  }

  // ── ② 육아용품 자유 상담 (AI상담 화면 채팅용) ─────────────────
  Future<String> recommendBabyProduct({
    required String childName,
    required int ageInMonths,
    required String question,
  }) async {
    final prompt = '''
당신은 10년 경력의 육아 전문가입니다.
아래 아이 정보를 참고하여 육아용품을 추천해주세요.

[아이 정보]
- 이름: $childName
- 나이: $ageInMonths개월

[부모의 질문]
$question

[답변 규칙]
1. 한국어로 친근하고 따뜻하게 답변해주세요.
2. 구체적인 상품 카테고리와 선택 기준을 알려주세요.
3. 이 나이대 아이에게 특히 중요한 점을 강조해주세요.
4. 200자 이내로 간결하게 답변해주세요.
''';
    return generateText(prompt);
  }

  // ── ③ 아이 발달 정보 조회 ──────────────────────────────────
  Future<String> getGrowthInfo({
    required String childName,
    required int ageInMonths,
  }) async {
    final prompt = '''
$childName이(가) $ageInMonths개월 아기입니다.
이 시기 아기의 발달 특징과 꼭 필요한 육아용품 3가지를 알려주세요.
한국어로 간결하게 답변해주세요. (150자 이내)
''';
    return generateText(prompt);
  }

  // ── ④ 월령별 육아용품 추천 리스트 ─────────────────────────────
  //
  // 입력: ageInMonths(개월수), category(카테고리)
  // 출력: ProductRecommendation 리스트 5개
  //       파싱 실패 시 빈 리스트([]) 반환
  //
  // 사용 예:
  //   final list = await GeminiService.instance.getProductRecommendations(
  //     ageInMonths: 6,
  //     category: '수유용품',
  //   );
  Future<List<ProductRecommendation>> getProductRecommendations({
    required int ageInMonths,
    required String category,
  }) async {
    final prompt = '''
당신은 10년 경력의 한국 육아 전문 큐레이터입니다.
월령에 맞는 육아용품을 추천할 때는 안전성, 발달 적합성, 실용성을 기준으로 추천해주세요.
응답은 반드시 아래 JSON 형식으로만 답하세요. 설명 텍스트 없이 JSON 배열만 반환하세요.

[{"name": "상품명", "reason": "추천이유", "priceRange": "가격대"}]

[요청 정보]
- 아이 나이: $ageInMonths개월
- 카테고리: $category
- 추천 개수: 정확히 5개

[가격대 표기 방법]
숫자+단위 형식 예시: "2~5만원", "15만원대", "3만원 이하"
''';

    try {
      final rawText = await generateText(prompt);

      // Gemini가 ```json ... ``` 코드블록으로 감쌀 때 제거
      final cleaned = rawText
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*', multiLine: true), '')
          .trim();

      // JSON 배열 파싱
      final jsonList = jsonDecode(cleaned) as List<dynamic>;

      return jsonList
          .map((item) => ProductRecommendation.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      // JSON 파싱 실패 또는 API 오류 시 빈 리스트 반환
      // (앱이 크래시 나지 않도록 안전하게 처리)
      return [];
    }
  }
}
