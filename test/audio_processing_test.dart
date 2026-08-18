import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:eloqui/core/services/audio_processing_service.dart';

void main() {
  group('AdaptiveSilenceDetector Tests', () {
    late AdaptiveSilenceDetector detector;

    setUp(() {
      detector = AdaptiveSilenceDetector(
        baseSilenceThresholdDb: -45.0,
        dynamicMarginDb: 8.0,
      );
    });

    test('Zero signal returns minimum decibels and triggers silence', () {
      final zeros = Int16List(1600); // 100ms at 16kHz
      final metrics = detector.analyzeFrame(zeros);

      expect(metrics.isSilence, true);
      expect(metrics.rms, 0.0);
      expect(metrics.decibels, -96.0);
    });

    test('High amplitude speech sample triggers active voice', () {
      final speechSamples = Int16List(1600);
      for (int i = 0; i < speechSamples.length; i++) {
        speechSamples[i] = (16000 * (i % 2 == 0 ? 1 : -1)); // loud wave
      }

      final metrics = detector.analyzeFrame(speechSamples);
      expect(metrics.isSilence, false);
      expect(metrics.rms, greaterThan(0.3));
      expect(metrics.decibels, greaterThan(-20.0));
    });

    test('Calibration reset restores baseline noise floor', () {
      detector.resetCalibration();
      expect(detector.ambientNoiseFloorDb, -60.0);
      expect(detector.effectiveSilenceThresholdDb, -45.0);
    });
  });
}
