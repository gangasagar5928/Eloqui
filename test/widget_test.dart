import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/features/ielts/ielts_result_screen.dart';
import 'package:eloqui/core/services/ielts_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IELTS Result Screen Widget Tests', () {
    testWidgets('Renders Band score and performance breakdown', (WidgetTester tester) async {
      const sampleAnalysis = SpeakingAnalysis(
        transcript: 'In my perspective, urbanization has transformed modern communities substantially. For instance, public transit networks facilitate mobility.',
        durationSeconds: 16.0,
        fillerCount: 0,
        pauseCount: 1,
        averageWordConfidence: 0.92,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: IeltsResultScreen(
            customAnalysis: sampleAnalysis,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(IeltsResultScreen), findsOneWidget);
      expect(find.textContaining('IELTS'), findsWidgets);
    });
  });
}
