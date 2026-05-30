import '../i18n/app_i18n.dart';
import '../models/wordbook.dart';
import 'ui_copy.dart';

String localizedWordbookName(
  AppI18n i18n,
  Wordbook? wordbook, {
  String placeholder = '-',
}) {
  if (wordbook == null) return placeholder;
  return localizedWordbookNameByPath(
    i18n,
    path: wordbook.path,
    fallbackName: wordbook.name,
  );
}

String localizedWordbookNameByPath(
  AppI18n i18n, {
  required String path,
  required String fallbackName,
}) {
  final normalizedPath = path.trim();
  final normalizedFallback = fallbackName.trim();
  if (normalizedPath == 'builtin:favorites') {
    return i18n.t('toolbox.sound.soothing.v2.mode.filter.favorites');
  }
  if (normalizedPath == 'builtin:task') {
    return i18n.t('inline.ui.widgets.word_card.task_df1f06');
  }
  if (normalizedFallback.isNotEmpty) return normalizedFallback;
  if (normalizedPath.startsWith('builtin:dict:')) {
    final dictName = normalizedPath.substring('builtin:dict:'.length).trim();
    if (dictName.isNotEmpty) return dictName;
  }
  return normalizedPath.isEmpty ? '-' : normalizedPath;
}
