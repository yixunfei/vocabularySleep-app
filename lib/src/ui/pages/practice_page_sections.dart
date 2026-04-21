part of 'practice_page.dart';

Widget _buildPracticeRoundSetupCard(
  BuildContext context, {
  required AppI18n i18n,
  required AppState state,
  required WordEntry current,
  required List<WordEntry> wordbookWords,
  required List<WordEntry> scopedWords,
  required List<WordEntry> taskWords,
  required List<WordEntry> favoriteWords,
  required List<WordEntry> weakWords,
  required List<WordEntry> wrongNotebookWords,
}) {
  final settings = state.practiceRoundSettings;
  final sourceWords = _resolvePracticeRoundSourceWords(
    settings.source,
    wordbookWords: wordbookWords,
    scopedWords: scopedWords,
    taskWords: taskWords,
    favoriteWords: favoriteWords,
    weakWords: weakWords,
    wrongNotebookWords: wrongNotebookWords,
  );
  final effectiveRoundSize = sourceWords.isEmpty
      ? settings.roundSize
      : settings.roundSize.clamp(1, sourceWords.length);
  final sourceLabel = _practiceRoundSourceLabel(i18n, settings.source);
  final rotationKey = _buildPracticeRoundRotationKey(
    state,
    source: settings.source,
  );
  final anchorWord = _resolvePracticeRoundAnchorWord(
    settings.startMode,
    sourceWords: sourceWords,
    current: current,
  );
  final previewIndex = state.previewPracticeBatchStartIndex(
    cursorKey: rotationKey,
    sourceWords: sourceWords,
    startMode: settings.startMode,
    anchorWord: anchorWord,
  );
  final previewWord = sourceWords.isEmpty ? '' : sourceWords[previewIndex].word;
  final roundSummary = sourceWords.isEmpty
      ? pickUiText(
          i18n,
          zh: '当前来源还没有可用单词，先切换范围或词本。',
          en: 'No words available for this source yet.',
        )
      : pickUiText(
          i18n,
          zh: '一轮 $effectiveRoundSize 个词，来源：$sourceLabel',
          en: 'One round: $effectiveRoundSize words from $sourceLabel',
        );
  final startSummary = sourceWords.isEmpty
      ? pickUiText(
          i18n,
          zh: '起点会在有可用单词后自动计算。',
          en: 'A starting point will appear once words are available.',
        )
      : switch (settings.startMode) {
          PracticeRoundStartMode.resumeCursor => pickUiText(
            i18n,
            zh: '从上次位置继续：第 ${previewIndex + 1} 个词 $previewWord',
            en: 'Resume from saved position: #${previewIndex + 1} $previewWord',
          ),
          PracticeRoundStartMode.currentWord => pickUiText(
            i18n,
            zh: '从当前词开始：第 ${previewIndex + 1} 个词 $previewWord',
            en: 'Start from current word: #${previewIndex + 1} $previewWord',
          ),
          PracticeRoundStartMode.fromStart => pickUiText(
            i18n,
            zh: '从头开始：第 ${previewIndex + 1} 个词 $previewWord',
            en: 'Start from the beginning: #${previewIndex + 1} $previewWord',
          ),
        };
  final availableSummary = sourceWords.isEmpty
      ? pickUiText(i18n, zh: '可用词数 0', en: '0 words available')
      : pickUiText(
          i18n,
          zh: '当前来源共 ${sourceWords.length} 个词',
          en: '${sourceWords.length} words available',
        );

  return Card(
    key: const ValueKey<String>('practice-round-setup-card'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(i18n, zh: '一轮设置', en: 'Round setup'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(roundSummary),
                    const SizedBox(height: 4),
                    Text(
                      startSummary,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey<String>('practice-round-toggle'),
                onPressed: () {
                  state.updatePracticeRoundSettings(
                    collapsed: !settings.collapsed,
                  );
                },
                icon: Icon(
                  settings.collapsed
                      ? Icons.expand_more_rounded
                      : Icons.expand_less_rounded,
                ),
              ),
            ],
          ),
          if (!settings.collapsed) ...<Widget>[
            const SizedBox(height: 16),
            DropdownButtonFormField<PracticeRoundSource>(
              key: const ValueKey<String>('practice-round-source'),
              initialValue: settings.source,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: pickUiText(i18n, zh: '练习来源', en: 'Practice source'),
              ),
              items: PracticeRoundSource.values
                  .map(
                    (source) => DropdownMenuItem<PracticeRoundSource>(
                      value: source,
                      child: Text(_practiceRoundSourceLabel(i18n, source)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                state.updatePracticeRoundSettings(source: value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PracticeRoundStartMode>(
              key: const ValueKey<String>('practice-round-start-mode'),
              initialValue: settings.startMode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: pickUiText(i18n, zh: '起点规则', en: 'Starting point'),
              ),
              items: PracticeRoundStartMode.values
                  .map(
                    (mode) => DropdownMenuItem<PracticeRoundStartMode>(
                      value: mode,
                      child: Text(_practiceRoundStartModeLabel(i18n, mode)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                state.updatePracticeRoundSettings(startMode: value);
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '每轮单词数', en: 'Words per round'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: settings.roundSize <= 1
                            ? null
                            : () {
                                state.updatePracticeRoundSettings(
                                  roundSize: settings.roundSize - 1,
                                );
                              },
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Text(
                              '$effectiveRoundSize',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              availableSummary,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: sourceWords.isEmpty
                            ? () {
                                state.updatePracticeRoundSettings(
                                  roundSize: settings.roundSize + 1,
                                );
                              }
                            : effectiveRoundSize >= sourceWords.length
                            ? null
                            : () {
                                state.updatePracticeRoundSettings(
                                  roundSize: settings.roundSize + 1,
                                );
                              },
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                pickUiText(i18n, zh: '轮内乱序', en: 'Shuffle within round'),
              ),
              subtitle: Text(
                pickUiText(
                  i18n,
                  zh: '每一轮仍按你设定的起点取词，但轮内顺序会打散。',
                  en: 'Keep the selected start point, but shuffle the order inside each round.',
                ),
              ),
              value: settings.shuffle,
              onChanged: (value) {
                state.updatePracticeRoundSettings(shuffle: value);
              },
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: sourceWords.isEmpty
                  ? null
                  : () => _openPracticeSession(
                      context,
                      title: pickUiText(
                        i18n,
                        zh: '$sourceLabel一轮练习',
                        en: '$sourceLabel round',
                      ),
                      subtitle: sourceWords.isEmpty
                          ? pickUiText(i18n, zh: '暂无单词', en: 'No words')
                          : pickUiText(
                              i18n,
                              zh: '$effectiveRoundSize / ${sourceWords.length} 个词',
                              en: '$effectiveRoundSize of ${sourceWords.length} words',
                            ),
                      words: sourceWords,
                      shuffle: settings.shuffle,
                      rotationKey: rotationKey,
                      rotationSourceWords: sourceWords,
                      rotationBatchSize: effectiveRoundSize,
                      rotationAnchorWord: anchorWord,
                      rotationCursorAdvance: effectiveRoundSize,
                    ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                pickUiText(i18n, zh: '按当前设置开始', en: 'Start this round'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildMemoryLanesCard(
  BuildContext context, {
  required AppI18n i18n,
  required AppState state,
  required List<WordEntry> stableWords,
  required List<WordEntry> recoveryWords,
  required int rememberedToday,
  required int needsReviewToday,
  required bool hasStableWords,
}) {
  final scopeWords = state.visibleWords;

  Future<void> openScopeWarmup() async {
    if (scopeWords.isEmpty) {
      _showNoWordsSnack(context, i18n);
      return;
    }
    await _openPracticeSession(
      context,
      title: pickUiText(i18n, zh: '当前范围会话', en: 'Current scope session'),
      subtitle: pickUiText(
        i18n,
        zh: '共 ${scopeWords.length} 个词',
        en: '${scopeWords.length} words',
      ),
      words: scopeWords,
      shuffle: false,
      rotationKey: _buildPracticeScopeRotationKey(state, slot: 'scope-session'),
      rotationSourceWords: scopeWords,
      rotationBatchSize: scopeWords.length,
      rotationCursorAdvance: 1,
    );
  }

  return Card(
    key: const ValueKey<String>('practice-memory-card'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '记忆轨道', en: 'Memory lanes'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '把每次练习结果分成“已记住”和“待加强”两条轨道，下一步练什么会更清晰。',
              en: 'Split each finished session into stable and recovery lanes so the next drill is always clear.',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _buildStatBadge(
                context,
                icon: Icons.check_circle_outline_rounded,
                value: '$rememberedToday',
                label: pickUiText(i18n, zh: '今日已记住', en: 'Remembered today'),
              ),
              _buildStatBadge(
                context,
                icon: Icons.refresh_rounded,
                value: '$needsReviewToday',
                label: pickUiText(i18n, zh: '今日待复习', en: 'Need review'),
              ),
              _buildStatBadge(
                context,
                icon: Icons.auto_awesome_rounded,
                value: '${stableWords.length}',
                label: pickUiText(i18n, zh: '稳定队列', en: 'Stable queue'),
              ),
              _buildStatBadge(
                context,
                icon: Icons.fitness_center_rounded,
                value: '${recoveryWords.length}',
                label: pickUiText(i18n, zh: '恢复队列', en: 'Recovery queue'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMemoryLane(
            context,
            key: const ValueKey<String>('practice-memory-stable'),
            i18n: i18n,
            icon: Icons.auto_awesome_rounded,
            title: pickUiText(i18n, zh: '稳定轨道', en: 'Stable lane'),
            subtitle: hasStableWords
                ? pickUiText(
                    i18n,
                    zh: '把已记住的单词再练一轮，保持回忆速度和发音稳定性。',
                    en: 'Revisit words you already know to keep recall and pronunciation smooth.',
                  )
                : pickUiText(
                    i18n,
                    zh: '完成一轮练习后，已记住的单词会沉淀到这里。',
                    en: 'Finish one session and the words you remember will collect here.',
                  ),
            words: stableWords,
            actionLabel: hasStableWords
                ? pickUiText(i18n, zh: '复习已记住', en: 'Review remembered')
                : pickUiText(i18n, zh: '先完成一轮', en: 'Start first session'),
            onTap: hasStableWords
                ? () => _openReviewSession(
                    context,
                    i18n,
                    title: pickUiText(
                      i18n,
                      zh: '已记住单词复习',
                      en: 'Remembered word review',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '共 ${stableWords.length} 个已记住单词',
                      en: '${stableWords.length} remembered words',
                    ),
                    words: stableWords,
                  )
                : openScopeWarmup,
          ),
          const SizedBox(height: 12),
          _buildMemoryLane(
            context,
            key: const ValueKey<String>('practice-memory-recovery'),
            i18n: i18n,
            icon: Icons.fitness_center_rounded,
            title: pickUiText(i18n, zh: '恢复轨道', en: 'Recovery lane'),
            subtitle: recoveryWords.isNotEmpty
                ? pickUiText(
                    i18n,
                    zh: '把薄弱词和任务词合并复习，优先补齐还不稳定的词。',
                    en: 'Mix weak and task words into one queue so you can close the gaps quickly.',
                  )
                : pickUiText(
                    i18n,
                    zh: '没记住的单词会留在这里，后续可以集中恢复。',
                    en: 'Words you miss will stay here so you can recover them in focused batches.',
                  ),
            words: recoveryWords,
            actionLabel: recoveryWords.isNotEmpty
                ? pickUiText(i18n, zh: '开始恢复复习', en: 'Start recovery review')
                : pickUiText(i18n, zh: '先完成一轮', en: 'Start first session'),
            onTap: recoveryWords.isNotEmpty
                ? () => _openReviewSession(
                    context,
                    i18n,
                    title: pickUiText(i18n, zh: '恢复轨道', en: 'Recovery lane'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '共 ${recoveryWords.length} 个待加强单词',
                      en: '${recoveryWords.length} words to reinforce',
                    ),
                    words: recoveryWords,
                  )
                : openScopeWarmup,
          ),
        ],
      ),
    ),
  );
}

Widget _buildMemoryLane(
  BuildContext context, {
  required Key key,
  required AppI18n i18n,
  required IconData icon,
  required String title,
  required String subtitle,
  required List<WordEntry> words,
  required String actionLabel,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);

  return Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 10),
        _buildWordPreviewChips(context, i18n, words),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: onTap,
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: Text(actionLabel),
        ),
      ],
    ),
  );
}

Widget _buildWrongNotebookCard(
  BuildContext context, {
  required AppI18n i18n,
  required AppState state,
  required List<WordEntry> notebookWords,
  required int dueCount,
}) {
  final wordbookCount = notebookWords
      .map((entry) => entry.wordbookId)
      .toSet()
      .length;
  final theme = Theme.of(context);
  final hasNotebookWords = notebookWords.isNotEmpty;

  return Card(
    key: const ValueKey<String>('practice-wrong-notebook-card'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '错题本', en: 'Wrong notebook'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasNotebookWords
                ? pickUiText(
                    i18n,
                    zh: '把近期没记住的单词集中管理，支持错题顺序、到期优先、薄弱优先和随机练习。',
                    en: 'Keep missed words in one place with notebook order, due-first, weak-first, and shuffle review.',
                  )
                : pickUiText(
                    i18n,
                    zh: '练习时点击“没记住”后，单词会自动进入错题本，方便后续集中复习。',
                    en: 'When you mark a word as "Not yet" during practice, it will be added here for focused review later.',
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _buildStatBadge(
                context,
                icon: Icons.bookmarks_rounded,
                value: '${notebookWords.length}',
                label: pickUiText(i18n, zh: '错题数', en: 'Notebook words'),
              ),
              _buildStatBadge(
                context,
                icon: Icons.schedule_rounded,
                value: '$dueCount',
                label: pickUiText(i18n, zh: '待复习', en: 'Due now'),
              ),
              _buildStatBadge(
                context,
                icon: Icons.layers_rounded,
                value: '$wordbookCount',
                label: pickUiText(i18n, zh: '涉及词库', en: 'Wordbooks'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildWordPreviewChips(context, i18n, notebookWords),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PracticeNotebookPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(pickUiText(i18n, zh: '打开错题本', en: 'Open notebook')),
              ),
              if (hasNotebookWords)
                OutlinedButton.icon(
                  onPressed: () => _openPracticeSession(
                    context,
                    title: pickUiText(
                      i18n,
                      zh: '错题本练习',
                      en: 'Wrong notebook review',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '共 ${notebookWords.length} 个错题',
                      en: '${notebookWords.length} notebook words',
                    ),
                    words: notebookWords,
                    shuffle: false,
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(pickUiText(i18n, zh: '直接复习', en: 'Start now')),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildRecentHistoryCard(
  BuildContext context, {
  required AppI18n i18n,
  required List<PracticeSessionRecord> history,
}) {
  final theme = Theme.of(context);
  return Card(
    key: const ValueKey<String>('practice-history-card'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '最近练习历史', en: 'Recent session history'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '保留最近几次练习结果，方便回看准确率变化和主要薄弱点。',
              en: 'Keep the latest sessions visible so you can track accuracy and the main weak spots.',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PracticeReviewPage(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_outlined),
              label: Text(
                pickUiText(i18n, zh: '打开复盘页', en: 'Open review page'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '还没有练习历史，完成一轮会话后会自动显示在这里。',
                  en: 'No session history yet. Finish one session and it will appear here.',
                ),
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            ...history.take(5).map((record) {
              final reasonBadges = record.weakReasonCounts.entries.toList(
                growable: false,
              )..sort((left, right) => right.value.compareTo(left.value));
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            record.title.isEmpty
                                ? pickUiText(
                                    i18n,
                                    zh: '练习会话',
                                    en: 'Practice session',
                                  )
                                : record.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          formatPracticeDateTime(i18n, record.practicedAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '正确率 ${(record.accuracy * 100).round()}% · 记住 ${record.remembered}/${record.total} · 错题 ${record.weakCount}',
                        en: 'Accuracy ${(record.accuracy * 100).round()}% · ${record.remembered}/${record.total} remembered · ${record.weakCount} weak',
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (reasonBadges.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: reasonBadges
                            .take(3)
                            .map(
                              (entry) => Chip(
                                visualDensity: VisualDensity.compact,
                                avatar: Icon(
                                  practiceWeakReasonIcon(entry.key),
                                  size: 16,
                                ),
                                label: Text(
                                  '${practiceWeakReasonLabel(i18n, entry.key)} × ${entry.value}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    ),
  );
}

Widget _buildWordPreviewChips(
  BuildContext context,
  AppI18n i18n,
  List<WordEntry> words,
) {
  final theme = Theme.of(context);
  if (words.isEmpty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        pickUiText(i18n, zh: '还没有单词', en: 'No words yet'),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: words
        .take(6)
        .map((word) => Chip(label: Text(word.word)))
        .toList(growable: false),
  );
}

Widget _buildStatBadge(
  BuildContext context, {
  required IconData icon,
  required String value,
  required String label,
}) {
  final theme = Theme.of(context);
  return Container(
    constraints: const BoxConstraints(minWidth: 120),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(value, style: theme.textTheme.titleMedium),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildQuickLaunchCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  return SizedBox(
    width: 160,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}
