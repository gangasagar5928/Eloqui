import 'dart:math';
import 'dart:typed_data';

class AudioEnergyMetrics {
  final double rms;
  final double decibels;
  final bool isSilence;

  const AudioEnergyMetrics({
    required this.rms,
    required this.decibels,
    required this.isSilence,
  });
}

class AdaptiveSilenceDetector {
  final double baseSilenceThresholdDb;
  final double dynamicMarginDb;
  double _ambientNoiseFloorDb = -60.0;
  int _noiseSamplesCount = 0;

  AdaptiveSilenceDetector({
    this.baseSilenceThresholdDb = -45.0,
    this.dynamicMarginDb = 8.0,
  });

  double get ambientNoiseFloorDb => _ambientNoiseFloorDb;
  double get effectiveSilenceThresholdDb =>
      max(baseSilenceThresholdDb, _ambientNoiseFloorDb + dynamicMarginDb);

  AudioEnergyMetrics analyzeFrame(Int16List pcmSamples) {
    if (pcmSamples.isEmpty) {
      return const AudioEnergyMetrics(
        rms: 0.0,
        decibels: -96.0,
        isSilence: true,
      );
    }

    double sumSquares = 0.0;
    for (int i = 0; i < pcmSamples.length; i++) {
      final norm = pcmSamples[i] / 32768.0;
      sumSquares += norm * norm;
    }

    final rms = sqrt(sumSquares / pcmSamples.length);
    final decibels = rms > 1e-6 ? 20.0 * (log(rms) / ln10) : -96.0;

    // Adapt ambient noise floor during quiet periods
    if (_noiseSamplesCount < 50 && decibels < baseSilenceThresholdDb) {
      _ambientNoiseFloorDb =
          (_ambientNoiseFloorDb * _noiseSamplesCount + decibels) /
          (_noiseSamplesCount + 1);
      _noiseSamplesCount++;
    }

    final isSilence = decibels < effectiveSilenceThresholdDb;

    return AudioEnergyMetrics(
      rms: rms,
      decibels: decibels,
      isSilence: isSilence,
    );
  }

  void resetCalibration() {
    _ambientNoiseFloorDb = -60.0;
    _noiseSamplesCount = 0;
  }
}
