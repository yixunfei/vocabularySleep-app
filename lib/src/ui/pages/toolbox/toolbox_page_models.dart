import 'package:flutter/material.dart';

class ToolboxSectionData {
  const ToolboxSectionData({
    required this.title,
    required this.subtitle,
    required this.entries,
  });

  final String title;
  final String subtitle;
  final List<ToolboxEntryData> entries;
}

class ToolboxEntryData {
  const ToolboxEntryData({
    required this.moduleId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.pageBuilder,
  });

  final String moduleId;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget Function() pageBuilder;
}
