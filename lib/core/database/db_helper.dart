import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._();
  DbHelper._();
  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<void> init() async {
    _db = await _initDb();
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'eloqui.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        mode TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        message_count INTEGER DEFAULT 0,
        duration_seconds INTEGER DEFAULT 0,
        summary TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        duration_seconds INTEGER DEFAULT 0,
        score REAL,
        metadata TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE pronunciation_results (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        text TEXT NOT NULL,
        accuracy REAL,
        fluency REAL,
        speed_wpm REAL,
        filler_count INTEGER DEFAULT 0,
        pause_count INTEGER DEFAULT 0,
        pause_duration_sec REAL DEFAULT 0,
        hesitation_count INTEGER DEFAULT 0,
        repeated_words_count INTEGER DEFAULT 0,
        sentence_completion_rate REAL DEFAULT 1.0,
        confidence REAL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE grammar_mistakes (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        original TEXT NOT NULL,
        corrected TEXT NOT NULL,
        rule TEXT NOT NULL,
        explanation TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE vocabulary_cards (
        word TEXT PRIMARY KEY,
        definition TEXT NOT NULL,
        example TEXT,
        synonyms TEXT,
        antonyms TEXT,
        ipa TEXT,
        level TEXT,
        domain TEXT,
        sm2_interval INTEGER DEFAULT 1,
        sm2_repetitions INTEGER DEFAULT 0,
        sm2_ease REAL DEFAULT 2.5,
        next_review INTEGER,
        learned INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE daily_logs (
        date TEXT PRIMARY KEY,
        speaking_seconds INTEGER DEFAULT 0,
        sessions_count INTEGER DEFAULT 0,
        words_learned INTEGER DEFAULT 0,
        grammar_accuracy REAL DEFAULT 0,
        pronunciation_score REAL DEFAULT 0,
        confidence_score REAL DEFAULT 0,
        ai_readiness_score REAL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE ielts_scores (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        fluency REAL,
        lexical REAL,
        grammar REAL,
        pronunciation REAL,
        overall REAL,
        part TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // --- 5. Additional 6 Architecture Tables ---
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        target_cefr TEXT DEFAULT 'B2',
        goal_category TEXT DEFAULT 'IELTS',
        daily_target_minutes INTEGER DEFAULT 15,
        native_accent TEXT DEFAULT 'Indian',
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE mistake_history (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        error_pattern TEXT NOT NULL,
        sample_sentence TEXT NOT NULL,
        correction TEXT NOT NULL,
        frequency INTEGER DEFAULT 1,
        is_resolved INTEGER DEFAULT 0,
        last_occurred INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE downloads (
        pack_id TEXT PRIMARY KEY,
        pack_name TEXT NOT NULL,
        version TEXT NOT NULL,
        expected_checksum TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        is_verified INTEGER DEFAULT 0,
        downloaded_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE custom_topics (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        prompt_instructions TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE weekly_summary (
        week_identifier TEXT PRIMARY KEY,
        total_speaking_min INTEGER DEFAULT 0,
        top_5_mistakes TEXT,
        words_mastered INTEGER DEFAULT 0,
        average_band_score REAL DEFAULT 0,
        generated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        badge_icon TEXT NOT NULL,
        unlocked_at INTEGER,
        is_unlocked INTEGER DEFAULT 0
      )
    ''');

    await _seedDefaultVocabulary(db);
    await _seedDefaultAchievements(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id TEXT PRIMARY KEY,
          target_cefr TEXT DEFAULT 'B2',
          goal_category TEXT DEFAULT 'IELTS',
          daily_target_minutes INTEGER DEFAULT 15,
          native_accent TEXT DEFAULT 'Indian',
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mistake_history (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          error_pattern TEXT NOT NULL,
          sample_sentence TEXT NOT NULL,
          correction TEXT NOT NULL,
          frequency INTEGER DEFAULT 1,
          is_resolved INTEGER DEFAULT 0,
          last_occurred INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS downloads (
          pack_id TEXT PRIMARY KEY,
          pack_name TEXT NOT NULL,
          version TEXT NOT NULL,
          expected_checksum TEXT NOT NULL,
          file_path TEXT NOT NULL,
          file_size_bytes INTEGER NOT NULL,
          is_verified INTEGER DEFAULT 0,
          downloaded_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS custom_topics (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          prompt_instructions TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weekly_summary (
          week_identifier TEXT PRIMARY KEY,
          total_speaking_min INTEGER DEFAULT 0,
          top_5_mistakes TEXT,
          words_mastered INTEGER DEFAULT 0,
          average_band_score REAL DEFAULT 0,
          generated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS achievements (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          badge_icon TEXT NOT NULL,
          unlocked_at INTEGER,
          is_unlocked INTEGER DEFAULT 0
        )
      ''');
    }
  }

  Future<void> _seedDefaultVocabulary(Database db) async {
    final words = [
      {'word': 'eloquent', 'definition': 'Fluent or persuasive in speaking or writing', 'example': 'She gave an eloquent speech.', 'ipa': '/\'el.ə.kwənt/', 'level': 'B2', 'domain': 'IELTS'},
      {'word': 'proficient', 'definition': 'Competent or skilled in doing something', 'example': 'He is proficient in English.', 'ipa': '/prə\'fɪʃ.ənt/', 'level': 'B2', 'domain': 'Business'},
      {'word': 'articulate', 'definition': 'Having or showing the ability to speak fluently', 'example': 'An articulate speaker.', 'ipa': '/ɑː\'tɪk.jʊ.lət/', 'level': 'C1', 'domain': 'IELTS'},
      {'word': 'consequently', 'definition': 'As a result; therefore', 'example': 'Consequently, we reached early.', 'ipa': '/\'kɒn.sɪ.kwənt.li/', 'level': 'B2', 'domain': 'Daily Life'},
      {'word': 'itinerary', 'definition': 'A planned route or journey', 'example': 'We prepared a detailed travel itinerary.', 'ipa': '/aɪˈtɪn.ər.ər.i/', 'level': 'B1', 'domain': 'Travel'},
    ];
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final w in words) {
      await db.insert('vocabulary_cards', {
        ...w,
        'next_review': now,
        'synonyms': '',
        'antonyms': '',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seedDefaultAchievements(Database db) async {
    final badges = [
      {'id': 'streak_3', 'title': '3-Day Streak', 'description': 'Practiced for 3 consecutive days', 'badge_icon': '🔥', 'is_unlocked': 0},
      {'id': 'first_conversation', 'title': 'First Words', 'description': 'Completed your first AI conversation', 'badge_icon': '🎙️', 'is_unlocked': 1},
      {'id': 'ielts_band_7', 'title': 'Band 7 Pioneer', 'description': 'Achieved an estimated IELTS score of 7.0+', 'badge_icon': '🎓', 'is_unlocked': 0},
      {'id': 'vocab_50', 'title': 'Word Master', 'description': 'Mastered 50 vocabulary words', 'badge_icon': '📚', 'is_unlocked': 0},
    ];
    for (final b in badges) {
      await db.insert('achievements', b, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // --- Conversations ---
  Future<void> insertConversation(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('conversations', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getConversations({int limit = 50}) async {
    final db = await database;
    return db.query('conversations', orderBy: 'updated_at DESC', limit: limit);
  }

  Future<void> insertMessage(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('messages', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final db = await database;
    return db.query('messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
        orderBy: 'timestamp ASC');
  }

  // --- Daily logs ---
  Future<void> upsertDailyLog(String date, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('daily_logs', {'date': date, ...data},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDailyLog(String date) async {
    final db = await database;
    final rows = await db.query('daily_logs', where: 'date = ?', whereArgs: [date]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getDailyLogs({int days = 30}) async {
    final db = await database;
    return db.query('daily_logs', orderBy: 'date DESC', limit: days);
  }

  // --- IELTS Scores ---
  Future<void> insertIeltsScore(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('ielts_scores', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getIeltsScores({int limit = 20}) async {
    final db = await database;
    return db.query('ielts_scores', orderBy: 'created_at DESC', limit: limit);
  }

  // --- Vocabulary ---
  Future<List<Map<String, dynamic>>> getVocabularyByCategory({String? level, String? domain}) async {
    final db = await database;
    if (level != null && domain != null) {
      return db.query('vocabulary_cards', where: 'level = ? AND domain = ?', whereArgs: [level, domain]);
    } else if (level != null) {
      return db.query('vocabulary_cards', where: 'level = ?', whereArgs: [level]);
    } else if (domain != null) {
      return db.query('vocabulary_cards', where: 'domain = ?', whereArgs: [domain]);
    }
    return db.query('vocabulary_cards', limit: 100);
  }

  Future<List<Map<String, dynamic>>> getDueVocabularyCards() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.query('vocabulary_cards',
        where: 'next_review <= ?', whereArgs: [now], limit: 20);
  }

  Future<void> updateVocabularyCard(String word, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('vocabulary_cards', data, where: 'word = ?', whereArgs: [word]);
  }

  Future<List<Map<String, dynamic>>> searchVocabulary(String query) async {
    final db = await database;
    return db.query('vocabulary_cards',
        where: 'word LIKE ? OR definition LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 50);
  }

  // --- Grammar Mistakes & History ---
  Future<void> insertGrammarMistake(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('grammar_mistakes', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> trackMistakeHistory(String category, String pattern, String sentence, String correction) async {
    final db = await database;
    final existing = await db.query('mistake_history', where: 'error_pattern = ?', whereArgs: [pattern]);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (existing.isNotEmpty) {
      final freq = (existing.first['frequency'] as int) + 1;
      await db.update('mistake_history', {'frequency': freq, 'last_occurred': now}, where: 'error_pattern = ?', whereArgs: [pattern]);
    } else {
      await db.insert('mistake_history', {
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'category': category,
        'error_pattern': pattern,
        'sample_sentence': sentence,
        'correction': correction,
        'frequency': 1,
        'is_resolved': 0,
        'last_occurred': now,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getTopMistakes({int limit = 5}) async {
    final db = await database;
    return db.query('mistake_history', orderBy: 'frequency DESC', limit: limit);
  }

  // --- Downloads & Manifest Verification ---
  Future<void> saveDownloadRecord(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('downloads', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDownloadRecord(String packId) async {
    final db = await database;
    final rows = await db.query('downloads', where: 'pack_id = ?', whereArgs: [packId]);
    return rows.isEmpty ? null : rows.first;
  }

  // --- Achievements ---
  Future<List<Map<String, dynamic>>> getAchievements() async {
    final db = await database;
    return db.query('achievements');
  }

  // --- Settings ---
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
