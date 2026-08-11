import 'dart:convert';
import 'dart:io';

class ContentPackMetadata {
  final String id;
  final String name;
  final String version;
  final String category; // 'ielts', 'toefl', 'pte', 'business', 'techInterview'
  final String author;
  final int minAppVersion;

  const ContentPackMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.category,
    required this.author,
    required this.minAppVersion,
  });

  factory ContentPackMetadata.fromJson(Map<String, dynamic> json) => ContentPackMetadata(
        id: json['id'] ?? 'custom_pack',
        name: json['name'] ?? 'Custom Content Pack',
        version: json['version'] ?? '1.0.0',
        category: json['category'] ?? 'general',
        author: json['author'] ?? 'Eloqui Community',
        minAppVersion: json['minAppVersion'] ?? 1,
      );
}

class LessonPack {
  final ContentPackMetadata metadata;
  final List<Map<String, dynamic>> lessons;
  final List<Map<String, dynamic>> quizzes;
  final List<String> promptInstructions;
  final List<String> audioAssets;

  const LessonPack({
    required this.metadata,
    required this.lessons,
    required this.quizzes,
    required this.promptInstructions,
    required this.audioAssets,
  });

  factory LessonPack.fromJson(Map<String, dynamic> json) => LessonPack(
        metadata: ContentPackMetadata.fromJson(json['metadata'] ?? {}),
        lessons: List<Map<String, dynamic>>.from(json['lessons'] ?? []),
        quizzes: List<Map<String, dynamic>>.from(json['quizzes'] ?? []),
        promptInstructions: List<String>.from(json['prompts'] ?? []),
        audioAssets: List<String>.from(json['audio'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'metadata': {
          'id': metadata.id,
          'name': metadata.name,
          'version': metadata.version,
          'category': metadata.category,
          'author': metadata.author,
          'minAppVersion': metadata.minAppVersion,
        },
        'lessons': lessons,
        'quizzes': quizzes,
        'prompts': promptInstructions,
        'audio': audioAssets,
      };
}

class ContentPackManager {
  static final ContentPackManager instance = ContentPackManager._();
  ContentPackManager._();

  /// Parse plugin content pack from JSON file
  Future<LessonPack?> loadPackFromFile(File file) async {
    try {
      final jsonStr = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonStr);
      return LessonPack.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
