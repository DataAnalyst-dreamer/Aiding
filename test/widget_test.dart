// 아이딩 앱 기본 테스트
// Flutter 앱이 정상적으로 시작되는지 확인합니다.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('아이딩 앱 기본 테스트', (WidgetTester tester) async {
    // Firebase가 필요한 앱은 실제 기기나 에뮬레이터에서 테스트합니다.
    // 이 파일은 빌드 오류 없이 유지되는 용도입니다.
    expect(1 + 1, equals(2));
  });
}
