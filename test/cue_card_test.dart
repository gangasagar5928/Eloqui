import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/models/cue_card_topics.dart';

void main() {
  group('CueCardBank Tests', () {
    test('Contains curated topics with 4 bullet points', () {
      expect(CueCardBank.topics.length, greaterThanOrEqual(2));
      for (final topic in CueCardBank.topics) {
        expect(topic.bulletPoints.length, 4);
        expect(topic.prompt.isNotEmpty, true);
      }
    });
  });
}
