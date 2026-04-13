class WordbookImportIssue {
  const WordbookImportIssue({
    required this.severity,
    required this.code,
    required this.path,
    required this.message,
  });

  final String severity;
  final String code;
  final String path;
  final String message;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'severity': severity,
      'code': code,
      'path': path,
      'message': message,
    };
  }
}

class WordbookImportAudit {
  const WordbookImportAudit({
    required this.format,
    required this.schemaVersion,
    required this.totalRecords,
    required this.acceptedRecords,
    required this.issues,
    this.bookId,
    this.bookName,
    this.unknownFieldCounts = const <String, int>{},
    this.note = '',
  });

  final String format;
  final String schemaVersion;
  final int totalRecords;
  final int acceptedRecords;
  final List<WordbookImportIssue> issues;
  final String? bookId;
  final String? bookName;
  final Map<String, int> unknownFieldCounts;
  final String note;

  bool get isValid =>
      !issues.any((issue) => issue.severity.toLowerCase() == 'error');

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'format': format,
      'schemaVersion': schemaVersion,
      'bookId': bookId,
      'bookName': bookName,
      'totalRecords': totalRecords,
      'acceptedRecords': acceptedRecords,
      'isValid': isValid,
      'issues': issues.map((item) => item.toJsonMap()).toList(growable: false),
      'unknownFieldCounts': unknownFieldCounts,
      'note': note,
    };
  }
}
