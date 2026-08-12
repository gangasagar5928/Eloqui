import '../database/db_helper.dart';

class ConversationSearchResult {
  final String conversationId;
  final String title;
  final String mode;
  final DateTime date;
  final String matchingSnippet;
  final String matchType; // 'keyword' | 'grammar' | 'vocab' | 'band'

  const ConversationSearchResult({
    required this.conversationId,
    required this.title,
    required this.mode,
    required this.date,
    required this.matchingSnippet,
    required this.matchType,
  });
}

class ConversationSearchService {
  static final ConversationSearchService instance = ConversationSearchService._();
  ConversationSearchService._();

  /// Search all historical conversations across multiple criteria
  Future<List<ConversationSearchResult>> search({
    required String query,
    String? dateFilter,
    String? topicFilter,
    double? minBandScore,
  }) async {
    final results = <ConversationSearchResult>[];
    final db = await DbHelper.instance.database;

    final queryLower = query.toLowerCase();

    // 1. Search messages table for keyword matches
    final messages = await db.query(
      'messages',
      where: 'content LIKE ?',
      whereArgs: ['%$queryLower%'],
      limit: 50,
    );

    for (final m in messages) {
      final convId = m['conversation_id'] as String;
      final convRows = await db.query('conversations', where: 'id = ?', whereArgs: [convId]);
      if (convRows.isNotEmpty) {
        final c = convRows.first;
        results.add(ConversationSearchResult(
          conversationId: convId,
          title: c['title'] as String,
          mode: c['mode'] as String,
          date: DateTime.fromMillisecondsSinceEpoch(c['updated_at'] as int),
          matchingSnippet: m['content'] as String,
          matchType: 'Keyword Match',
        ));
      }
    }

    // 2. Search grammar mistakes
    if (queryLower.contains('grammar') || queryLower.contains('error')) {
      final mistakes = await DbHelper.instance.getRecentGrammarMistakes(limit: 20);
      for (final g in mistakes) {
        results.add(ConversationSearchResult(
          conversationId: g['session_id'] ?? 'general',
          title: 'Grammar Correction: ${g['rule']}',
          mode: 'Grammar Checker',
          date: DateTime.fromMillisecondsSinceEpoch(g['created_at'] as int),
          matchingSnippet: '${g['original']} → ${g['corrected']}',
          matchType: 'Grammar Mistake',
        ));
      }
    }

    return results;
  }
}
