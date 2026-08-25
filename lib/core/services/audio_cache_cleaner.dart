import 'dart:io';

class CacheCleanupResult {
  final int filesDeleted;
  final int bytesFreed;

  const CacheCleanupResult({
    required this.filesDeleted,
    required this.bytesFreed,
  });
}

class AudioCacheCleaner {
  final int maxCacheBytes;

  const AudioCacheCleaner({
    this.maxCacheBytes = 50 * 1024 * 1024, // 50MB default
  });

  Future<CacheCleanupResult> purgeOldestFiles(Directory cacheDir) async {
    if (!await cacheDir.exists()) {
      return const CacheCleanupResult(filesDeleted: 0, bytesFreed: 0);
    }

    final entities = await cacheDir.list().toList();
    final files = entities.whereType<File>().toList();

    int totalBytes = 0;
    final fileStats = <Map<String, dynamic>>[];

    for (final file in files) {
      try {
        final stat = await file.stat();
        totalBytes += stat.size;
        fileStats.add({
          'file': file,
          'size': stat.size,
          'modified': stat.modified,
        });
      } catch (_) {}
    }

    if (totalBytes <= maxCacheBytes) {
      return const CacheCleanupResult(filesDeleted: 0, bytesFreed: 0);
    }

    // Sort oldest first (LRU)
    fileStats.sort((a, b) =>
        (a['modified'] as DateTime).compareTo(b['modified'] as DateTime));

    int deletedCount = 0;
    int freedBytes = 0;

    for (final item in fileStats) {
      if (totalBytes - freedBytes <= maxCacheBytes) break;
      final f = item['file'] as File;
      final size = item['size'] as int;
      try {
        await f.delete();
        deletedCount++;
        freedBytes += size;
      } catch (_) {}
    }

    return CacheCleanupResult(
      filesDeleted: deletedCount,
      bytesFreed: freedBytes,
    );
  }
}
