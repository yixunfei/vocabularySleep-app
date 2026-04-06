class SleepResearchSource {
  const SleepResearchSource({
    required this.bookTitle,
    required this.relevance,
  });

  final String bookTitle;
  final String relevance;
}

class SleepResearchTopic {
  const SleepResearchTopic({
    required this.id,
    required this.title,
    required this.summary,
    required this.detail,
    required this.actionHint,
    required this.sources,
  });

  final String id;
  final String title;
  final String summary;
  final String detail;
  final String actionHint;
  final List<SleepResearchSource> sources;
}

class SleepAdviceItem {
  const SleepAdviceItem({
    required this.id,
    required this.topicId,
    required this.title,
    required this.body,
    required this.reason,
    required this.tag,
    this.isPriority = false,
  });

  final String id;
  final String topicId;
  final String title;
  final String body;
  final String reason;
  final String tag;
  final bool isPriority;
}
