enum UserDataExportSection {
  wordbooks('wordbooks'),
  todos('todos'),
  notes('notes'),
  progress('progress'),
  timerRecords('timer_records'),
  settings('settings');

  const UserDataExportSection(this.storageKey);

  final String storageKey;
}

class UserDataExportOptions {
  const UserDataExportOptions({
    required this.sections,
    required this.directoryPath,
    required this.fileName,
  });

  final Set<UserDataExportSection> sections;
  final String directoryPath;
  final String fileName;

  bool get hasSelectedSections => sections.isNotEmpty;
}
