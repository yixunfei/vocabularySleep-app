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
          i18n.t(
            _managerModuleKey(
              wearKey: 'inline.plan295.daily_choice.hide_this_outfit.a7a55c353895',
              activityKey: 'toolbox.daily_choice.manager.dialog.hide_action',
              eatKey: 'toolbox.daily_choice.manager.dialog.hide_recipe',
              isWearModule: isWearModule,
              isActivityModule: isActivityModule,
            ),
          ),
        ),
        content: Text(
          i18n.t(
            'inline.plan295.daily_choice.option_title_i18n_will_be_hidden_fro.34f412bf6405',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(i18n.t('cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: Text(
              i18n.t('inline.plan295.daily_choice.hide.fce11f87a15c'),
            ),
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
