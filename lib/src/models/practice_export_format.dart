enum PracticeExportFormat {
  json,
  csv;

  String get extension => switch (this) {
    PracticeExportFormat.json => 'json',
    PracticeExportFormat.csv => 'csv',
  };
}
