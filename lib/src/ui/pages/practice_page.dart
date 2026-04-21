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
part 'practice_page_sections.dart';

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
}
