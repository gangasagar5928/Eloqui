class CueCardTopic {
  final String id;
  final String title;
  final String prompt;
  final List<String> bulletPoints;
  final String category; // Technology, Environment, Culture

  const CueCardTopic({
    required this.id,
    required this.title,
    required this.prompt,
    required this.bulletPoints,
    required this.category,
  });
}

class CueCardBank {
  static const List<CueCardTopic> topics = [
    CueCardTopic(
      id: 'tech_01',
      title: 'An Artificial Intelligence tool you find useful',
      prompt: 'Describe an artificial intelligence tool or application you use regularly.',
      bulletPoints: [
        'What the tool is and how you discovered it',
        'How often you use it in your daily life',
        'What features make it distinctive',
        'And explain how it has impacted your productivity',
      ],
      category: 'Technology',
    ),
    CueCardTopic(
      id: 'env_01',
      title: 'A renewable energy initiative in your country',
      prompt: 'Describe a renewable energy or sustainability project you admire.',
      bulletPoints: [
        'What the initiative is and where it is located',
        'Who is responsible for implementing it',
        'How it benefits the local environment',
        'And explain your view on its long-term viability',
      ],
      category: 'Environment',
    ),
  ];
}
