import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/ssml_service.dart';

void main() {
  group('SsmlTagBuilder Tests', () {
    test('Wraps prompt with speaking rate and pause', () {
      final ssml = SsmlTagBuilder.formatForIeltsExaminer('Could you tell me your full name?');
      expect(ssml, contains('<speak>'));
      expect(ssml, contains('rate="95%"'));
      expect(ssml, contains('<break time="400ms"/>'));
      expect(ssml, contains('</speak>'));
    });
  });
}
