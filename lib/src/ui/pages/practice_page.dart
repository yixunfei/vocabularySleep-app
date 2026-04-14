import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/settings_dto.dart';
import '../../models/practice_session_record.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../ui_copy.dart';
import '../wordbook_localization.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/setting_tile.dart';
import 'follow_along_page.dart';
import 'practice_notebook_page.dart';
import 'practice_review_page.dart';
import 'practice_support.dart';
import 'practice_session_page.dart';
import 'review_session_page.dart';

part 'practice_page_helpers.dart';

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.practice)) {
      return ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.practice);
    }
    final current = state.currentWord;
    if (state.selectedWordbook == null || current == null) {
      return EmptyStateView(
        icon: Icons.fitness_center_rounded,
        title: pickUiText(i18n, zh: '还没有练习材料', en: 'No practice material yet'),
        message: i18n.t('noWordbookYet'),
      );
    }

    final wordbookWords = state.words;
    final scopedWords = state.visibleWords;
    final taskWords = wordbookWords
        .where((word) => state.isTaskEntry(word))
        .toList(growable: false);
    final favoriteWords = wordbookWords
        .where((word) => state.isFavoriteEntry(word))
        .toList(growable: false);
    final rememberedWords = state.recentRememberedWordEntries;
    final weakWords = state.recentWeakWordEntries;
    final wrongNotebookWords = state.practiceWrongNotebookEntries;
    final needsReviewCount =
        (state.practiceTodayReviewed - state.practiceTodayRemembered).clamp(
          0,
          state.practiceTodayReviewed,
        );
    final stableWords = _mergeWordCollections(rememberedWords, favoriteWords);
    final recoveryWords = _mergeWordCollections(weakWords, taskWords);
    final todayAccuracy = (state.practiceTodayAccuracy * 100).round();
    final totalAccuracy = (state.practiceTotalAccuracy * 100).round();
    final hasWeakWords = weakWords.isNotEmpty;
    final hasStableWords = stableWords.isNotEmpty;
    final noPracticeToday = state.practiceTodaySessions == 0;
    final needsReinforce =
        !hasWeakWords && !noPracticeToday && state.practiceTodayAccuracy < 0.75;
    final warmupWords = scopedWords.length <= 7
        ? scopedWords
        : scopedWords.take(7).toList(growable: false);
    final currentSprintSourceWords = _containsWordEntry(scopedWords, current)
        ? scopedWords
        : wordbookWords;
    final recentHistory = state.practiceSessionHistory;
    final notebookDueCount = wrongNotebookWords.where((word) {
      final nextReview = state.memoryProgressForWordEntry(word)?.nextReview;
      return nextReview == null || !nextReview.isAfter(DateTime.now());
    }).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        PageHeader(
          eyebrow: pickUiText(
            i18n,
            zh: '练习',
            en: 'Practice',
            ja: '練習',
            de: 'Übung',
            fr: 'Pratique',
            es: 'Práctica',
            ru: 'Практика',
          ),
          title: pickUiText(i18n, zh: '练习中心', en: 'Practice hub'),
          subtitle: pickUiText(
            i18n,
            zh: '从单词面板升级为会话式练习：范围选择、连续作答、结果反馈。',
            en: 'Move from single-word tools to session-based practice with progress and feedback.',
          ),
        ),
        const SizedBox(height: 16),
        _buildPracticeRoundSetupCard(
          context,
          i18n: i18n,
          state: state,
          current: current,
          wordbookWords: wordbookWords,
          scopedWords: scopedWords,
          taskWords: taskWords,
          favoriteWords: favoriteWords,
          weakWords: weakWords,
          wrongNotebookWords: wrongNotebookWords,
        ),
        const SizedBox(height: 16),
        _buildMemoryLanesCard(
          context,
          i18n: i18n,
          state: state,
          stableWords: stableWords,
          recoveryWords: recoveryWords,
          rememberedToday: state.practiceTodayRemembered,
          needsReviewToday: needsReviewCount,
          hasStableWords: hasStableWords,
        ),
        const SizedBox(height: 16),
        _buildWrongNotebookCard(
          context,
          i18n: i18n,
          state: state,
          notebookWords: wrongNotebookWords,
          dueCount: notebookDueCount,
        ),
        const SizedBox(height: 16),
        _buildRecentHistoryCard(context, i18n: i18n, history: recentHistory),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(
                    i18n,
                    zh: '当前练习快照',
                    en: 'Current practice snapshot',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  pickUiText(
                    i18n,
                    zh: '当前词：${current.word}',
                    en: 'Current word: ${current.word}',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '当前词本：${localizedWordbookName(i18n, state.selectedWordbook)}',
                    en: 'Wordbook: ${localizedWordbookName(i18n, state.selectedWordbook)}',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '可练习范围：${scopedWords.length}（任务 ${taskWords.length} / 收藏 ${favoriteWords.length}）',
                    en: 'Scope: ${scopedWords.length} (Task ${taskWords.length} / Favorite ${favoriteWords.length})',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  pickUiText(
                    i18n,
                    zh: '今日会话：${state.practiceTodaySessions} 次，练习 ${state.practiceTodayReviewed} 词，正确率 $todayAccuracy%',
                    en: 'Today: ${state.practiceTodaySessions} sessions, ${state.practiceTodayReviewed} reviewed, $todayAccuracy% accuracy',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '累计会话：${state.practiceTotalSessions} 次，累计正确率 $totalAccuracy%',
                    en: 'All time: ${state.practiceTotalSessions} sessions, $totalAccuracy% accuracy',
                  ),
                ),
                if (state.practiceLastSessionTitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '上次会话：${state.practiceLastSessionTitle}',
                      en: 'Last session: ${state.practiceLastSessionTitle}',
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _buildStatBadge(
                      context,
                      icon: Icons.local_fire_department_rounded,
                      value: '${state.practiceTodayReviewed}',
                      label: pickUiText(
                        i18n,
                        zh: '今日练习词',
                        en: 'Reviewed today',
                        ja: '今日の練習語',
                        de: 'Heute geuebt',
                        fr: 'Revise aujourd’hui',
                        es: 'Repasadas hoy',
                      ),
                    ),
                    _buildStatBadge(
                      context,
                      icon: Icons.psychology_alt_outlined,
                      value: '${weakWords.length}',
                      label: pickUiText(
                        i18n,
                        zh: '薄弱词',
                        en: 'Weak words',
                        ja: '苦手単語',
                        de: 'Schwaechen',
                        fr: 'Mots faibles',
                        es: 'Palabras debiles',
                      ),
                    ),
                    _buildStatBadge(
                      context,
                      icon: Icons.task_alt_rounded,
                      value: '${taskWords.length}',
                      label: pickUiText(
                        i18n,
                        zh: '任务词',
                        en: 'Task words',
                        ja: 'タスク単語',
                        de: 'Aufgabenwoerter',
                        fr: 'Mots de tache',
                        es: 'Palabras de tarea',
                      ),
                    ),
                    _buildStatBadge(
                      context,
                      icon: Icons.favorite_rounded,
                      value: '${favoriteWords.length}',
                      label: pickUiText(
                        i18n,
                        zh: '收藏词',
                        en: 'Favorites',
                        ja: 'お気に入り',
                        de: 'Favoriten',
                        fr: 'Favoris',
                        es: 'Favoritos',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(i18n, zh: '今日建议', en: 'Today suggestion'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  hasWeakWords
                      ? pickUiText(
                          i18n,
                          zh: '建议优先复习最近薄弱词，再进入整本会话做二次巩固。',
                          en: 'Review recent weak words first, then do a full wordbook session.',
                        )
                      : noPracticeToday
                      ? pickUiText(
                          i18n,
                          zh: '你今天还未开始练习，建议先从“当前范围会话”启动。',
                          en: 'No practice yet today. Start with current scope session.',
                        )
                      : needsReinforce
                      ? pickUiText(
                          i18n,
                          zh: '今天正确率偏低，建议开启整本词本会话进行强化。',
                          en: 'Today accuracy is lower than expected. Try full wordbook session.',
                        )
                      : pickUiText(
                          i18n,
                          zh: '今天状态不错，可继续跟读练习提升发音稳定性。',
                          en: 'You are doing well today. Continue with follow-along for pronunciation.',
                        ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    if (hasWeakWords)
                      FilledButton.icon(
                        onPressed: () => _openReviewSession(
                          context,
                          i18n,
                          title: pickUiText(
                            i18n,
                            zh: '最近薄弱词复习',
                            en: 'Recent weak words',
                          ),
                          subtitle: pickUiText(
                            i18n,
                            zh: '共 ${weakWords.length} 个薄弱词',
                            en: '${weakWords.length} weak words',
                          ),
                          words: weakWords,
                        ),
                        icon: const Icon(Icons.psychology_alt_outlined),
                        label: Text(
                          pickUiText(
                            i18n,
                            zh: '开始薄弱词复习',
                            en: 'Start weak-word review',
                          ),
                        ),
                      )
                    else if (noPracticeToday)
                      FilledButton.icon(
                        onPressed: () => _openPracticeSession(
                          context,
                          title: pickUiText(
                            i18n,
                            zh: '当前范围会话',
                            en: 'Current scope session',
                          ),
                          subtitle: pickUiText(
                            i18n,
                            zh: '共 ${scopedWords.length} 个词',
                            en: '${scopedWords.length} words',
                          ),
                          words: scopedWords,
                          shuffle: false,
                          rotationKey: _buildPracticeScopeRotationKey(
                            state,
                            slot: 'scope-session',
                          ),
                          rotationSourceWords: scopedWords,
                          rotationBatchSize: scopedWords.length,
                          rotationCursorAdvance: 1,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          pickUiText(i18n, zh: '开始当前范围会话', en: 'Start now'),
                        ),
                      )
                    else if (needsReinforce)
                      FilledButton.icon(
                        onPressed: () => _openPracticeSession(
                          context,
                          title: pickUiText(
                            i18n,
                            zh: '整本词本会话',
                            en: 'Whole wordbook session',
                          ),
                          subtitle: pickUiText(
                            i18n,
                            zh: '共 ${wordbookWords.length} 个词',
                            en: '${wordbookWords.length} words',
                          ),
                          words: wordbookWords,
                          shuffle: true,
                        ),
                        icon: const Icon(Icons.library_books_rounded),
                        label: Text(
                          pickUiText(
                            i18n,
                            zh: '开启整本强化',
                            en: 'Start reinforcement',
                          ),
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FollowAlongPage(word: current),
                            ),
                          );
                        },
                        icon: const Icon(Icons.mic_external_on_rounded),
                        label: Text(
                          pickUiText(i18n, zh: '去跟读练习', en: 'Go follow along'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(
                    i18n,
                    zh: '快速开始',
                    en: 'Quick start',
                    ja: 'クイック開始',
                    de: 'Schnellstart',
                    fr: 'Demarrage rapide',
                    es: 'Inicio rapido',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  pickUiText(
                    i18n,
                    zh: '把常用热身、乱序冲刺与发音训练集中到一个区域，减少来回切换。',
                    en: 'Keep warmups, shuffled sprints, and pronunciation drills together so you can start faster.',
                    ja: 'ウォームアップ、シャッフル練習、発音トレーニングをひとまとめにして、すばやく始められます。',
                    de: 'Warm-up, Shuffle-Sprints und Aussprachetraining sind hier gebuendelt, damit Sie schneller starten koennen.',
                    fr: 'Regroupez echauffement, sessions melangees et prononciation pour demarrer plus vite.',
                    es: 'Reune calentamiento, sprints aleatorios y pronunciacion para empezar mas rapido.',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _buildQuickLaunchCard(
                      context,
                      icon: Icons.flash_on_rounded,
                      title: pickUiText(
                        i18n,
                        zh: '当前词速练',
                        en: 'Current word sprint',
                      ),
                      subtitle: pickUiText(
                        i18n,
                        zh: '1 题热身',
                        en: '1-card warmup',
                        ja: '1枚で準備運動',
                        de: 'Warm-up mit 1 Karte',
                        fr: 'Echauffement en 1 carte',
                        es: 'Calentamiento de 1 tarjeta',
                      ),
                      onTap: () => _openPracticeSession(
                        context,
                        title: pickUiText(
                          i18n,
                          zh: '当前词速练',
                          en: 'Current word sprint',
                        ),
                        subtitle: pickUiText(
                          i18n,
                          zh: '1 题短会话',
                          en: 'Single-item mini session',
                        ),
                        words: <WordEntry>[current],
                        shuffle: false,
                        rotationKey: _buildPracticeScopeRotationKey(
                          state,
                          slot: 'current-word',
                        ),
                        rotationSourceWords: currentSprintSourceWords,
                        rotationBatchSize: 1,
                        rotationAnchorWord: current,
                      ),
                    ),
                    _buildQuickLaunchCard(
                      context,
                      icon: Icons.local_fire_department_rounded,
                      title: pickUiText(
                        i18n,
                        zh: '7 词热身',
                        en: '7-word warmup',
                        ja: '7語ウォームアップ',
                        de: '7-Woerter-Warm-up',
                        fr: 'Echauffement 7 mots',
                        es: 'Calentamiento de 7 palabras',
                      ),
                      subtitle: pickUiText(
                        i18n,
                        zh: '从当前范围快速起步',
                        en: 'Start fast from current scope',
                        ja: '現在の範囲から素早く開始',
                        de: 'Schnell aus dem aktuellen Bereich starten',
                        fr: 'Demarrer vite depuis la portee actuelle',
                        es: 'Empezar rapido desde el alcance actual',
                      ),
                      onTap: warmupWords.isEmpty
                          ? () => _showNoWordsSnack(context, i18n)
                          : () => _openPracticeSession(
                              context,
                              title: pickUiText(
                                i18n,
                                zh: '7 词热身',
                                en: '7-word warmup',
                              ),
                              subtitle: pickUiText(
                                i18n,
                                zh: '共 ${warmupWords.length} 个词',
                                en: '${warmupWords.length} words',
                              ),
                              words: scopedWords,
                              shuffle: false,
                              rotationKey: _buildPracticeScopeRotationKey(
                                state,
                                slot: 'warmup-7',
                              ),
                              rotationSourceWords: scopedWords,
                              rotationBatchSize: 7,
                            ),
                    ),
                    _buildQuickLaunchCard(
                      context,
                      icon: Icons.shuffle_rounded,
                      title: pickUiText(
                        i18n,
                        zh: '乱序冲刺',
                        en: 'Shuffle sprint',
                        ja: 'シャッフル練習',
                        de: 'Shuffle-Sprint',
                        fr: 'Sprint melange',
                        es: 'Sprint aleatorio',
                      ),
                      subtitle: pickUiText(
                        i18n,
                        zh: '随机打散当前范围',
                        en: 'Shuffle the current scope',
                        ja: '現在の範囲をシャッフル',
                        de: 'Aktuellen Bereich mischen',
                        fr: 'Melanger la portee actuelle',
                        es: 'Mezclar el alcance actual',
                      ),
                      onTap: scopedWords.isEmpty
                          ? () => _showNoWordsSnack(context, i18n)
                          : () => _openPracticeSession(
                              context,
                              title: pickUiText(
                                i18n,
                                zh: '乱序冲刺',
                                en: 'Shuffle sprint',
                              ),
                              subtitle: pickUiText(
                                i18n,
                                zh: '共 ${scopedWords.length} 个词',
                                en: '${scopedWords.length} words',
                              ),
                              words: scopedWords,
                              shuffle: true,
                            ),
                    ),
                    _buildQuickLaunchCard(
                      context,
                      icon: Icons.mic_external_on_rounded,
                      title: pickUiText(
                        i18n,
                        zh: '发音跟读',
                        en: 'Pronunciation drill',
                        ja: '発音トレーニング',
                        de: 'Aussprachetraining',
                        fr: 'Exercice de prononciation',
                        es: 'Practica de pronunciacion',
                      ),
                      subtitle: pickUiText(
                        i18n,
                        zh: '当前词即时跟读',
                        en: 'Follow along with current word',
                        ja: '現在の単語ですぐ練習',
                        de: 'Mit dem aktuellen Wort direkt ueben',
                        fr: 'Suivre immediatement avec le mot courant',
                        es: 'Practicar de inmediato con la palabra actual',
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FollowAlongPage(word: current),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!state.practiceRoundSettings.collapsed) ...<Widget>[
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.flash_on_rounded,
            title: pickUiText(i18n, zh: '当前词速练', en: 'Current word sprint'),
            subtitle: pickUiText(
              i18n,
              zh: '仅针对当前词做一题一反馈，快速热身。',
              en: 'Quick one-item session for the current word.',
            ),
            onTap: () => _openPracticeSession(
              context,
              title: pickUiText(i18n, zh: '当前词速练', en: 'Current word sprint'),
              subtitle: pickUiText(
                i18n,
                zh: '1 题短会话',
                en: 'Single-item mini session',
              ),
              words: <WordEntry>[current],
              shuffle: false,
              rotationKey: _buildPracticeScopeRotationKey(
                state,
                slot: 'current-word',
              ),
              rotationSourceWords: currentSprintSourceWords,
              rotationBatchSize: 1,
              rotationAnchorWord: current,
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.view_list_rounded,
            title: pickUiText(i18n, zh: '当前范围会话', en: 'Current scope session'),
            subtitle: pickUiText(
              i18n,
              zh: '基于当前筛选范围连续练习。',
              en: 'Practice continuously within current filtered scope.',
            ),
            onTap: () {
              if (scopedWords.isEmpty) {
                _showNoWordsSnack(context, i18n);
                return;
              }
              _openPracticeSession(
                context,
                title: pickUiText(
                  i18n,
                  zh: '当前范围会话',
                  en: 'Current scope session',
                ),
                subtitle: pickUiText(
                  i18n,
                  zh: '共 ${scopedWords.length} 个词',
                  en: '${scopedWords.length} words',
                ),
                words: scopedWords,
                shuffle: false,
                rotationKey: _buildPracticeScopeRotationKey(
                  state,
                  slot: 'scope-session',
                ),
                rotationSourceWords: scopedWords,
                rotationBatchSize: scopedWords.length,
                rotationCursorAdvance: 1,
              );
            },
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.library_books_rounded,
            title: pickUiText(i18n, zh: '整本词本会话', en: 'Whole wordbook session'),
            subtitle: pickUiText(
              i18n,
              zh: '覆盖当前词本全部词条，可随机顺序。',
              en: 'Cover the whole wordbook with optional shuffle.',
            ),
            onTap: () => _openPracticeSession(
              context,
              title: pickUiText(
                i18n,
                zh: '整本词本会话',
                en: 'Whole wordbook session',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '共 ${wordbookWords.length} 个词',
                en: '${wordbookWords.length} words',
              ),
              words: wordbookWords,
              shuffle: true,
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.task_alt_rounded,
            title: pickUiText(i18n, zh: '任务词复习', en: 'Task word review'),
            subtitle: pickUiText(
              i18n,
              zh: '针对任务词开启复习会话。',
              en: 'Review session focused on task words.',
            ),
            onTap: () => _openReviewSession(
              context,
              i18n,
              title: pickUiText(i18n, zh: '任务词复习', en: 'Task word review'),
              subtitle: pickUiText(
                i18n,
                zh: '共 ${taskWords.length} 个任务词',
                en: '${taskWords.length} task words',
              ),
              words: taskWords,
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.favorite_rounded,
            title: pickUiText(i18n, zh: '收藏词复习', en: 'Favorite word review'),
            subtitle: pickUiText(
              i18n,
              zh: '复习收藏列表并快速进入会话。',
              en: 'Review favorite words and start a session quickly.',
            ),
            onTap: () => _openReviewSession(
              context,
              i18n,
              title: pickUiText(i18n, zh: '收藏词复习', en: 'Favorite word review'),
              subtitle: pickUiText(
                i18n,
                zh: '共 ${favoriteWords.length} 个收藏词',
                en: '${favoriteWords.length} favorite words',
              ),
              words: favoriteWords,
            ),
          ),
          if (weakWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            SettingTile(
              icon: Icons.psychology_alt_outlined,
              title: pickUiText(i18n, zh: '最近薄弱词复习', en: 'Recent weak words'),
              subtitle: pickUiText(
                i18n,
                zh: '根据历史会话自动沉淀，建议优先复习。',
                en: 'Auto-collected from session history. Recommended next step.',
              ),
              onTap: () => _openReviewSession(
                context,
                i18n,
                title: pickUiText(i18n, zh: '最近薄弱词复习', en: 'Recent weak words'),
                subtitle: pickUiText(
                  i18n,
                  zh: '共 ${weakWords.length} 个薄弱词',
                  en: '${weakWords.length} weak words',
                ),
                words: weakWords,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.mic_external_on_rounded,
            title: pickUiText(i18n, zh: '跟读练习', en: 'Follow along'),
            subtitle: pickUiText(
              i18n,
              zh: '使用当前词进行录音、识别与发音评分。',
              en: 'Record, transcribe, and score pronunciation for current word.',
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FollowAlongPage(word: current),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

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
    final previewWord = sourceWords.isEmpty
        ? ''
        : sourceWords[previewIndex].word;
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
                  labelText: pickUiText(
                    i18n,
                    zh: '练习来源',
                    en: 'Practice source',
                  ),
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
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
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
        rotationKey: _buildPracticeScopeRotationKey(
          state,
          slot: 'scope-session',
        ),
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
                  label: Text(
                    pickUiText(i18n, zh: '打开错题本', en: 'Open notebook'),
                  ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
}
