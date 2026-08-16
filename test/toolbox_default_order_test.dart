import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/core/module_system/module_id.dart';
import 'package:vocabulary_sleep_app/src/i18n/app_i18n.dart';
import 'package:vocabulary_sleep_app/src/models/settings_dto.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox/toolbox_page_content.dart';
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_crypto_security.dart';

void main() {
  test('toolbox default order prioritizes frequent modules', () {
    final entries = orderedToolboxEntries(
      buildAllToolboxSections(AppI18n('en')),
      layoutState: ToolboxLayoutState.defaults,
      isModuleEnabled: (_) => true,
    );
    final ids = entries.map((entry) => entry.moduleId).toList(growable: false);

    expect(ids.take(8), <String>[
      ModuleIds.toolboxHumanTests,
      ModuleIds.toolboxLifeTools,
      ModuleIds.toolboxCryptoSecurity,
      ModuleIds.toolboxSoundDeck,
      ModuleIds.toolboxFreeChimes,
      ModuleIds.toolboxZenSand,
      ModuleIds.toolboxDailyDecision,
      ModuleIds.toolboxBreathing,
    ]);
    expect(ids.sublist(ids.length - 2), <String>[
      ModuleIds.toolboxSleepAssistant,
      ModuleIds.toolboxMiniGames,
    ]);
  });

  testWidgets('crypto security hub prioritizes common modules', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: CryptoSecurityHubPage()));
    await tester.pumpAndSettle();

    final labels = <String>[
      'My passwords',
      'Password generator',
      'Media steganography',
      'File encryption',
      'Text encryption',
    ];
    final topOffsets = <double>[
      for (final label in labels) tester.getTopLeft(find.text(label).last).dy,
    ];

    for (var i = 1; i < topOffsets.length; i += 1) {
      expect(topOffsets[i], greaterThan(topOffsets[i - 1]));
    }
  });
}
