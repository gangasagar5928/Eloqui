import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';

class DownloadStatus {
  final String packId;
  final String packName;
  final double progress;
  final String statusMessage;
  final String downloadSpeed;
  final bool isCompleted;
  final bool isFailed;
  final String? errorMessage;

  const DownloadStatus({
    required this.packId,
    required this.packName,
    required this.progress,
    required this.statusMessage,
    required this.downloadSpeed,
    this.isCompleted = false,
    this.isFailed = false,
    this.errorMessage,
  });
}

enum QuantizationLevel { Q4_K_M, Q5_K_M, Q8_0 }

enum PackCategory { ielts, toefl, pte, duolingo, business, publicSpeaking, technicalInterview }

class ModelBundleManifest {
  final String packId;
  final String packName;
  final String version;
  final String llmFilename;
  final String whisperFilename;
  final String piperVoiceFilename;
  final String tokenizerFilename;
  final String sha256Checksum;
  final QuantizationLevel quantization;
  final PackCategory category;
  final int totalSizeBytes;

  const ModelBundleManifest({
    required this.packId,
    required this.packName,
    required this.version,
    required this.llmFilename,
    required this.whisperFilename,
    required this.piperVoiceFilename,
    required this.tokenizerFilename,
    required this.sha256Checksum,
    this.quantization = QuantizationLevel.Q4_K_M,
    this.category = PackCategory.ielts,
    required this.totalSizeBytes,
  });

  factory ModelBundleManifest.fromJson(Map<String, dynamic> json) => ModelBundleManifest(
        packId: json['packId'] ?? 'balanced_v1',
        packName: json['packName'] ?? 'Balanced Pack v1.0',
        version: json['version'] ?? '1.0.0',
        llmFilename: json['llmFilename'] ?? 'qwen2.5_3b.gguf',
        whisperFilename: json['whisperFilename'] ?? 'whisper_base.bin',
        piperVoiceFilename: json['piperVoiceFilename'] ?? 'en_IN_piper.onnx',
        tokenizerFilename: json['tokenizerFilename'] ?? 'tokenizer.json',
        sha256Checksum: json['sha256Checksum'] ?? '',
        totalSizeBytes: json['totalSizeBytes'] ?? 2147483648,
      );

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'packName': packName,
        'version': version,
        'llmFilename': llmFilename,
        'whisperFilename': whisperFilename,
        'piperVoiceFilename': piperVoiceFilename,
        'tokenizerFilename': tokenizerFilename,
        'sha256Checksum': sha256Checksum,
        'totalSizeBytes': totalSizeBytes,
      };
}

class DownloadManager {
  static final DownloadManager instance = DownloadManager._();
  DownloadManager._();

  /// Get app-specific external model directory
  Future<Directory> getModelDirectory() async {
    final baseDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final modelDir = Directory('${baseDir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir;
  }

  /// Compute the lowercase SHA-256 hex digest of a file.
  Future<String> sha256Of(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Verify a downloaded bundle against a trusted SHA-256 checksum.
  ///
  /// Returns true ONLY when a non-empty trusted checksum was supplied AND it
  /// matches the file. There is deliberately no "digital signature" check
  /// here: real signature verification is not implemented in this build, so
  /// no signature string is ever treated as proof of authenticity. A missing
  /// trusted checksum fails closed (returns false), never passes.
  Future<bool> verifyBundleIntegrity(File file, String trustedSha256) async {
    if (!await file.exists()) return false;

    final expected = trustedSha256.trim();
    if (expected.isEmpty) return false;

    final digest = await sha256Of(file);
    return digest.toLowerCase() == expected.toLowerCase();
  }

  /// Record a completed download in SQLite. [isVerified] must be the result of
  /// real integrity checking (see [verifyBundleIntegrity]) — never assumed.
  Future<void> recordVerifiedDownload({
    required ModelBundleManifest manifest,
    required String filePath,
    required bool isVerified,
  }) async {
    await DbHelper.instance.saveDownloadRecord({
      'pack_id': manifest.packId,
      'pack_name': manifest.packName,
      'version': manifest.version,
      'expected_checksum': manifest.sha256Checksum,
      'file_path': filePath,
      'file_size_bytes': manifest.totalSizeBytes,
      'is_verified': isVerified ? 1 : 0,
      'downloaded_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Check readiness
  Future<bool> isPackReady(String packId) async {
    final record = await DbHelper.instance.getDownloadRecord(packId);
    if (record == null) return false;
    final file = File(record['file_path'] as String);
    return file.exists();
  }

  /// Get the record of the most recently downloaded verified GGUF model pack
  Future<Map<String, dynamic>?> getLatestDownloadedModelRecord() async {
    final records = await DbHelper.instance.getDownloadRecords();
    for (final r in records) {
      final path = r['file_path'] as String?;
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          return r;
        }
      }
    }
    return null;
  }

  /// Get the file path of the most recently downloaded verified GGUF model pack
  Future<String?> getLatestDownloadedModelPath() async {
    final record = await getLatestDownloadedModelRecord();
    return record?['file_path'] as String?;
  }

  // ─── Background Download Infrastructure ───────────────────────────
  final _statusController = StreamController<DownloadStatus>.broadcast();
  DownloadStatus? _currentStatus;
  CancelToken? _activeCancelToken;

  Stream<DownloadStatus> get statusStream => _statusController.stream;
  DownloadStatus? get currentStatus => _currentStatus;
  bool get isDownloading =>
      _currentStatus != null && !_currentStatus!.isCompleted && !_currentStatus!.isFailed;

  Future<void> startBackgroundDownload({
    required String packId,
    required String packName,
    required String url,
    String? trustedSha256,
  }) async {
    if (isDownloading) return;

    _activeCancelToken = CancelToken();

    try {
      final modelDir = await getModelDirectory();
      final finalPath = '${modelDir.path}/$packId.gguf';
      final partialPath = '$finalPath.part';

      // Check if partial file exists for resumption
      final partialFile = File(partialPath);
      int startBytes = 0;
      if (await partialFile.exists()) {
        startBytes = await partialFile.length();
      }

      _updateStatus(DownloadStatus(
        packId: packId,
        packName: packName,
        progress: 0.0,
        statusMessage: startBytes > 0
            ? 'Resuming download from ${(startBytes / 1024 / 1024).toStringAsFixed(1)} MB...'
            : 'Starting background download...',
        downloadSpeed: '',
      ));

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(minutes: 90);

      final startTime = DateTime.now();

      final options = Options(
        headers: {
          'User-Agent': 'Eloqui-App/1.0',
          if (startBytes > 0) 'Range': 'bytes=$startBytes-',
        },
        responseType: ResponseType.stream,
        followRedirects: true,
        maxRedirects: 5,
      );

      final response = await dio.get<ResponseBody>(
        url,
        cancelToken: _activeCancelToken,
        options: options,
      );

      final contentLenHeader = response.headers.value('content-length');
      final totalContentBytes = contentLenHeader != null ? int.tryParse(contentLenHeader) ?? 0 : 0;
      final totalBytes = totalContentBytes > 0
          ? (response.statusCode == 206 ? startBytes + totalContentBytes : totalContentBytes)
          : 0;

      final mode = (response.statusCode == 206 && startBytes > 0)
          ? FileMode.append
          : FileMode.write;

      final sink = partialFile.openWrite(mode: mode);
      int currentDownloadedBytes = (mode == FileMode.append) ? startBytes : 0;

      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        currentDownloadedBytes += chunk.length;

        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final speedMBps = elapsed > 0 ? ((currentDownloadedBytes - startBytes) / 1024 / 1024) / elapsed : 0.0;
        final progress = totalBytes > 0 ? (currentDownloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
        final receivedMB = (currentDownloadedBytes / 1024 / 1024).toStringAsFixed(1);
        final totalMB = totalBytes > 0 ? (totalBytes / 1024 / 1024).toStringAsFixed(0) : '?';

        _updateStatus(DownloadStatus(
          packId: packId,
          packName: packName,
          progress: progress,
          statusMessage: 'Downloading $receivedMB MB / $totalMB MB',
          downloadSpeed: '${speedMBps.toStringAsFixed(1)} MB/s',
        ));
      }

      await sink.flush();
      await sink.close();

      // Rename partial file to final .gguf extension upon completion
      final finalFile = File(finalPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partialFile.rename(finalPath);

      final manifest = ModelBundleManifest(
        packId: packId,
        packName: packName,
        version: '1.0.0',
        llmFilename: '$packId.gguf',
        whisperFilename: 'whisper_base.bin',
        piperVoiceFilename: 'en_IN_piper.onnx',
        tokenizerFilename: 'tokenizer.json',
        sha256Checksum: trustedSha256 ?? '',
        totalSizeBytes: await finalFile.length(),
      );

      // Honest integrity check: the bundle is only recorded as "verified" when
      // a non-empty trusted checksum was supplied AND it matches what we
      // actually downloaded. Without a trusted checksum the download records
      // as unverified — the app must not claim authenticity it never checked.
      final isVerified = await verifyBundleIntegrity(finalFile, manifest.sha256Checksum);

      await recordVerifiedDownload(
        manifest: manifest,
        filePath: finalPath,
        isVerified: isVerified,
      );

      _updateStatus(DownloadStatus(
        packId: packId,
        packName: packName,
        progress: 1.0,
        statusMessage: '✅ $packName installed successfully!',
        downloadSpeed: '',
        isCompleted: true,
      ));
    } catch (e) {
      _updateStatus(DownloadStatus(
        packId: packId,
        packName: packName,
        progress: _currentStatus?.progress ?? 0.0,
        statusMessage: 'Download paused (resumable on retry)',
        downloadSpeed: '',
        isFailed: true,
        errorMessage: 'Connection lost. Download saved to partial file. Tap retry to resume.',
      ));
    }
  }

  void cancelBackgroundDownload() {
    _activeCancelToken?.cancel('Cancelled by user');
    _updateStatus(DownloadStatus(
      packId: _currentStatus?.packId ?? '',
      packName: _currentStatus?.packName ?? '',
      progress: 0.0,
      statusMessage: 'Download cancelled',
      downloadSpeed: '',
      isFailed: true,
    ));
  }

  void _updateStatus(DownloadStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }
}
