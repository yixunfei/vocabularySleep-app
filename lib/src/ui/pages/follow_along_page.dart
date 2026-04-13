import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../models/word_entry.dart';
import '../../services/asr_service.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';

class FollowAlongPage extends StatefulWidget {
  const FollowAlongPage({super.key, required this.word});

  final WordEntry word;

  @override
  State<FollowAlongPage> createState() => _FollowAlongPageState();
}

class _FollowAlongPageState extends State<FollowAlongPage> {
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _advancedMode = false;
  String? _recognizedText;
  PronunciationComparison? _comparison;
  String? _error;
  AsrProgress? _progress;
  String? _activeScoringMethod;
  String? _activeScoringEngine;
  Map<String, double> _scoringBreakdown = const <String, double>{};
  late AsrProviderType _activeProvider;
  AsrProviderType? _windowsGuardedProvider;
  late AppState _state;
  bool _boundState = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_boundState) return;
    _state = context.read<AppState>();
    final configuredProvider = _state.config.asr.provider;
    _activeProvider = _sanitizeFollowAlongProvider(configuredProvider);
    _windowsGuardedProvider = _isUnsafeWindowsLocalProvider(configuredProvider)
        ? configuredProvider
        : null;
    _boundState = true;
  }

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool _isUnsafeWindowsLocalProvider(AsrProviderType provider) {
    if (!_isWindowsDesktop) return false;
    return provider == AsrProviderType.multiEngine ||
        provider == AsrProviderType.offline ||
        provider == AsrProviderType.offlineSmall ||
        provider == AsrProviderType.localSimilarity;
  }

  List<AsrProviderType> _availableProviders() {
    if (!_isWindowsDesktop) {
      return AsrProviderType.values;
    }
    return const <AsrProviderType>[
      AsrProviderType.api,
      AsrProviderType.customApi,
    ];
  }

  AsrProviderType _windowsFallbackProvider() {
    final configured = _state.config.asr.provider;
    if (configured == AsrProviderType.customApi) {
      return AsrProviderType.customApi;
    }
    return AsrProviderType.api;
  }

  AsrProviderType _sanitizeFollowAlongProvider(AsrProviderType provider) {
    if (_isUnsafeWindowsLocalProvider(provider)) {
      return _windowsFallbackProvider();
    }
    return provider;
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;
    if (_isRecording) {
      await _stopAndTranscribe();
      return;
    }
    await _startRecording();
  }

  Future<void> _startRecording() async {
    setState(() {
      _error = null;
      _recognizedText = null;
      _comparison = null;
      _progress = null;
      _activeScoringMethod = null;
      _activeScoringEngine = null;
      _scoringBreakdown = const <String, double>{};
    });

    final path = await _state.startAsrRecording(provider: _activeProvider);
    if (!mounted) return;
    if (path == null || path.trim().isEmpty) {
      final i18n = AppI18n(_state.uiLanguage);
      setState(() {
        _error = i18n.t('startRecordingFailed');
      });
      return;
    }

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopAndTranscribe() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _error = null;
      _progress = const AsrProgress(
        stage: 'recording',
        messageKey: 'asrProgressStoppingRecording',
        progress: null,
      );
    });

    try {
      final audioPath = await _state.stopAsrRecording();
      if (!mounted) return;
      if (audioPath == null || audioPath.trim().isEmpty) {
        final i18n = AppI18n(_state.uiLanguage);
        setState(() {
          _error = i18n.t('recordingFailed');
        });
        return;
      }

      final result = await _state.transcribeRecording(
        audioPath,
        expectedText: widget.word.word,
        provider: _activeProvider,
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
          });
        },
      );
      if (!mounted) return;
      final i18n = AppI18n(_state.uiLanguage);

      if (!result.success) {
        setState(() {
          _error = result.error == null
              ? i18n.t('recognitionFailed')
              : i18n.t(result.error!, params: result.errorParams);
          _recognizedText = null;
          _comparison = null;
          _activeScoringMethod = null;
          _activeScoringEngine = null;
          _scoringBreakdown = const <String, double>{};
        });
        return;
      }

      final text = result.text?.trim() ?? '';
      final textComparison = text.isEmpty
          ? null
          : _state.comparePronunciation(widget.word.word, text);
      final acousticSimilarity = result.similarity?.clamp(0.0, 1.0);
      final hasScoringBreakdown = result.scoringBreakdown.isNotEmpty;
      final preferAcousticSimilarity =
          acousticSimilarity != null &&
          (result.similarityFromAcoustic || hasScoringBreakdown);
      final baseThreshold = _similarityPassThreshold();
      final acousticThreshold = hasScoringBreakdown
          ? (baseThreshold - 0.06).clamp(0.60, 0.92).toDouble()
          : baseThreshold;
      final hasHardMismatch = _hasHardTextMismatch(
        expected: widget.word.word,
        recognized: text,
        textComparison: textComparison,
      );
      final compare = preferAcousticSimilarity
          ? PronunciationComparison(
              isCorrect:
                  !hasHardMismatch &&
                  (acousticSimilarity >= acousticThreshold ||
                      (textComparison?.isCorrect ?? false)),
              similarity: hasHardMismatch
                  ? min(
                      acousticSimilarity,
                      ((textComparison?.similarity ?? acousticSimilarity) *
                              1.35)
                          .clamp(0.0, 1.0),
                    )
                  : acousticSimilarity,
              differences: textComparison?.differences ?? const <String>[],
            )
          : acousticSimilarity == null
          ? (textComparison ??
                const PronunciationComparison(
                  isCorrect: false,
                  similarity: 0,
                  differences: <String>[],
                ))
          : textComparison == null
          ? PronunciationComparison(
              isCorrect: acousticSimilarity >= _similarityPassThreshold(),
              similarity: acousticSimilarity,
              differences: const <String>[],
            )
          : PronunciationComparison(
              isCorrect:
                  textComparison.isCorrect ||
                  ((textComparison.similarity * 0.72 +
                          acousticSimilarity * 0.28) >=
                      _similarityPassThreshold()),
              similarity:
                  (textComparison.similarity * 0.72 + acousticSimilarity * 0.28)
                      .clamp(0.0, 1.0),
              differences: textComparison.differences,
            );
      setState(() {
        _recognizedText = text.isEmpty && result.similarity != null
            ? i18n.t('asrLocalSimilarityNoTranscript')
            : text;
        _comparison = compare;
        _activeScoringMethod = result.activeScoringMethod;
        _activeScoringEngine = result.engine;
        _scoringBreakdown = result.scoringBreakdown;
        _progress = const AsrProgress(
          stage: 'done',
          messageKey: 'asrProgressDone',
          progress: 1,
        );
      });
    } catch (_) {
      if (!mounted) return;
      final i18n = AppI18n(_state.uiLanguage);
      setState(() {
        _error = i18n.t('recognitionFailed');
        _progress = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  double _similarityPassThreshold() {
    final length = widget.word.word.trim().runes.length;
    if (length <= 4) return 0.76;
    if (length <= 8) return 0.73;
    return 0.7;
  }

  bool _hasHardTextMismatch({
    required String expected,
    required String recognized,
    required PronunciationComparison? textComparison,
  }) {
    final exp = expected.trim();
    final rec = recognized.trim();
    if (exp.isEmpty || rec.isEmpty) return false;
    final comparison = textComparison;
    if (comparison == null) return false;
    if (comparison.isCorrect) return false;
    if (comparison.similarity >= 0.56) return false;

    final normalizedExpected = _normalizeForHardMatch(exp);
    final normalizedRecognized = _normalizeForHardMatch(rec);
    if (normalizedExpected == normalizedRecognized) return false;

    final expectedTokens = _splitHardMatchTokens(normalizedExpected);
    final recognizedTokens = _splitHardMatchTokens(normalizedRecognized);
    if (expectedTokens.length == 1 && recognizedTokens.length == 1) {
      return true;
    }
    return comparison.differences.any(
      (item) =>
          item.startsWith('replace::') ||
          item.startsWith('missing::') ||
          item.startsWith('extra::'),
    );
  }

  String _normalizeForHardMatch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\u4e00-\u9fff]+', unicode: true), ' ')
        .trim();
  }

  List<String> _splitHardMatchTokens(String value) {
    if (value.isEmpty) return const <String>[];
    return value
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _playReference() async {
    await _state.previewPronunciation(widget.word.word);
  }

  String _formatDifference(AppI18n i18n, String item) {
    if (item.startsWith('missing::')) {
      return i18n.t(
        'pronunciationDiffMissing',
        params: <String, Object?>{'value': item.substring('missing::'.length)},
      );
    }
    if (item.startsWith('extra::')) {
      return i18n.t(
        'pronunciationDiffExtra',
        params: <String, Object?>{'value': item.substring('extra::'.length)},
      );
    }
    if (item.startsWith('replace::')) {
      final payload = item.substring('replace::'.length).split('::');
      if (payload.length == 2) {
        return i18n.t(
          'pronunciationDiffReplace',
          params: <String, Object?>{'from': payload[0], 'to': payload[1]},
        );
      }
    }
    return item;
  }

  String _formatScoringMethod(AppI18n i18n, String raw) {
    PronScoringMethod? method;
    for (final candidate in PronScoringMethod.values) {
      if (candidate.name == raw) {
        method = candidate;
        break;
      }
    }
    if (method == null) return raw;
    return switch (method) {
      PronScoringMethod.sslEmbedding => i18n.t('scorerSslEmbedding'),
      PronScoringMethod.gop => i18n.t('scorerGop'),
      PronScoringMethod.forcedAlignmentPer => i18n.t(
        'scorerForcedAlignmentPer',
      ),
      PronScoringMethod.ppgPosterior => i18n.t('scorerPpgPosterior'),
    };
  }

  @override
  void dispose() {
    if (_boundState) {
      _state.cancelAsrRecording();
      _state.stopAsrProcessing();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final comparison = _comparison;
    final progress = _progress;
    final providers = _availableProviders();
    final guardedProvider = _windowsGuardedProvider;

    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('followAlongTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    widget.word.word,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      pickUiText(i18n, zh: '高级模式', en: 'Advanced mode'),
                    ),
                    subtitle: Text(
                      _advancedMode
                          ? pickUiText(
                              i18n,
                              zh: '已显示引擎选择',
                              en: 'Engine selector is visible',
                            )
                          : pickUiText(
                              i18n,
                              zh: '普通模式仅保留核心跟读流程',
                              en: 'Normal mode keeps the core follow-along flow',
                            ),
                    ),
                    value: _advancedMode,
                    onChanged: (_isRecording || _isProcessing)
                        ? null
                        : (value) {
                            setState(() {
                              _advancedMode = value;
                            });
                          },
                  ),
                  if (!_advancedMode)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        pickUiText(
                          i18n,
                          zh: '当前引擎：${asrProviderLabel(i18n, _activeProvider)}',
                          en: 'Current engine: ${asrProviderLabel(i18n, _activeProvider)}',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (_advancedMode)
                    DropdownButtonFormField<AsrProviderType>(
                      initialValue: _activeProvider,
                      decoration: InputDecoration(
                        labelText: i18n.t('asrProvider'),
                      ),
                      items: <DropdownMenuItem<AsrProviderType>>[
                        for (final provider in providers)
                          DropdownMenuItem<AsrProviderType>(
                            value: provider,
                            child: Text(asrProviderLabel(i18n, provider)),
                          ),
                      ],
                      onChanged: (_isRecording || _isProcessing)
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() {
                                _activeProvider = value;
                                _windowsGuardedProvider = null;
                                _recognizedText = null;
                                _comparison = null;
                                _activeScoringMethod = null;
                                _activeScoringEngine = null;
                                _scoringBreakdown = const <String, double>{};
                                _error = null;
                                _progress = null;
                              });
                            },
                    ),
                  if (guardedProvider != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pickUiText(
                                i18n,
                                zh: 'Windows 下已临时避开 ${asrProviderLabel(i18n, guardedProvider)}，当前页面改用 ${asrProviderLabel(i18n, _activeProvider)}，以避免本地识别链路触发原生闪退。',
                                en: 'Windows temporarily avoids ${asrProviderLabel(i18n, guardedProvider)} here and uses ${asrProviderLabel(i18n, _activeProvider)} instead to prevent a native crash.',
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_advancedMode) const SizedBox(height: 8),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _playReference,
                    icon: const Icon(Icons.volume_up_outlined),
                    label: Text(i18n.t('playPronunciation')),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _toggleRecording,
                      style: FilledButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(26),
                        backgroundColor: _isRecording ? Colors.red : null,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isRecording
                        ? i18n.t('tapToStopRecord')
                        : _isProcessing
                        ? i18n.t('recognizing')
                        : i18n.t('tapToStartRecord'),
                    textAlign: TextAlign.center,
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      i18n.t(
                        progress.messageKey,
                        params: progress.messageParams,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress.progress),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (comparison != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      comparison.isCorrect
                          ? i18n.t('great')
                          : i18n.t('needsPractice'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      i18n.t(
                        'recognizedText',
                        params: {'text': _recognizedText ?? ''},
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.t(
                        'similarity',
                        params: {
                          'score': (comparison.similarity * 100).round(),
                        },
                      ),
                    ),
                    if ((_activeScoringMethod ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        i18n.t(
                          'asrScoringMethodApplied',
                          params: <String, Object?>{
                            'method': _formatScoringMethod(
                              i18n,
                              _activeScoringMethod!,
                            ),
                          },
                        ),
                      ),
                    ],
                    if ((_activeScoringEngine ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        i18n.t(
                          'asrScoringEngineApplied',
                          params: <String, Object?>{
                            'engine': _activeScoringEngine!,
                          },
                        ),
                      ),
                    ],
                    if (_scoringBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(i18n.t('asrScoringBreakdown')),
                      const SizedBox(height: 4),
                      for (final entry in _scoringBreakdown.entries)
                        Text(
                          '- ${_formatScoringMethod(i18n, entry.key)}: ${(entry.value * 100).round()}%',
                        ),
                    ],
                    if (comparison.differences.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(i18n.t('differences')),
                      const SizedBox(height: 4),
                      for (final item in comparison.differences)
                        Text('- ${_formatDifference(i18n, item)}'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
