part of 'daily_choice_widgets.dart';

Future<bool?> _confirmHideBuiltInRecipe({
  required BuildContext context,
  required AppI18n i18n,
  required DailyChoiceOption option,
  bool isWearModule = false,
  bool isActivityModule = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          pickUiText(
            i18n,
            zh: '确认不喜欢？',
            en: isWearModule
                ? 'Hide this outfit?'
                : (isActivityModule
                      ? 'Hide this action?'
                      : 'Hide this recipe?'),
          ),
        ),
        content: Text(
          pickUiText(
            i18n,
            zh: '「${option.title(i18n)}」会从随机候选中隐藏，之后仍可在管理页恢复。',
            en: '"${option.title(i18n)}" will be hidden from random picks. You can restore it later in Manage.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: Text(pickUiText(i18n, zh: '确认不喜欢', en: 'Hide')),
          ),
        ],
      );
    },
  );
}

List<String> _splitLines(String raw) {
  return raw
      .split(RegExp(r'[\n\r]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _splitTags(String raw) {
  return raw
      .split(RegExp(r'[、，,\s]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);
}
