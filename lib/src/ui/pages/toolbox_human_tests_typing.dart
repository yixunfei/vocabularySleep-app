part of 'toolbox_human_tests.dart';

const Color _typingAccent = Color(0xFFC27A37);

enum _TypingMode {
  classic,
  sprint,
  precision,
  blind,
  symbols,
  fixErrors,
  code,
  numbers,
}

enum _TypingLanguage { zh, en, mixed, ja, es }

enum _TypingTopic { all, focus, sleep, tech, story, vocabulary, travel }

enum _TypingLength { short, standard, long }

enum _TypingIssue { letter, cjk, space, punctuation, number, extra, missing }

class TypingTestPage extends StatelessWidget {
  const TypingTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '打字测试',
        en: 'Typing test',
        ja: 'Typing test',
        de: 'Typing test',
        fr: 'Essai de dactylographie',
        es: 'Prueba de clasificación',
        ru: 'Тест на ввод текста',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '选择语言、题材、长度和训练模式，实时查看速度、准确率、错误位置与节奏稳定性。',
        en: 'Choose language, topic, length, and mode while tracking speed, accuracy, errors, and rhythm.',
        ja: 'スピード、正確さ、エラー、リズムを追跡しながら、言語、トピック、長さ、モードを選択します。',
        de: 'Choose language, topic, length, and mode while tracking speed, accuracy, errors, and rhythm.',
        fr: 'Choisissez la langue, le sujet, la longueur et le mode tout en suivant la vitesse, la précision, les erreurs et le rythme.',
        es: 'Elija el idioma, el tema, la longitud y el modo mientras el seguimiento de velocidad, precisión, errores y ritmo.',
        ru: 'Выберите язык, тему, длину и режим, отслеживая скорость, точность, ошибки и ритм.',
      ),
      accent: _typingAccent,
      icon: Icons.keyboard_alt_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择训练组合并开始输入',
        en: 'Next: choose a drill setup and start typing',
        ja: 'Next: choose a drill setup and start typing',
        de: 'Next: choose a drill setup and start typing',
        fr: 'Suivant : choisissez une configuration de foret et commencez à taper',
        es: 'Siguiente: elegir una configuración de taladro y comenzar a escribir',
        ru: 'Далее: выберите настройку дрели и начните печатать',
      ),
      child: const _TypingTestCard(),
    );
  }
}

class _TypingPassage {
  const _TypingPassage({
    required this.zh,
    required this.en,
    required this.language,
    required this.topic,
    this.ja,
    this.es,
  });

  final String zh;
  final String en;
  final String? ja;
  final String? es;
  final _TypingLanguage language;
  final _TypingTopic topic;

  String text(AppI18n i18n) {
    return switch (language) {
      _TypingLanguage.zh => zh,
      _TypingLanguage.en => en,
      _TypingLanguage.ja => ja ?? en,
      _TypingLanguage.es => es ?? en,
      _TypingLanguage.mixed => pickUiText(
        i18n,
        zh: zh,
        en: en,
        ja: ja ?? en,
        de: en,
        fr: en,
        es: es ?? en,
        ru: en,
      ),
    };
  }
}

class _TypingSample {
  const _TypingSample({
    required this.elapsed,
    required this.typedLength,
    required this.correctLength,
    required this.errorCount,
  });

  final Duration elapsed;
  final int typedLength;
  final int correctLength;
  final int errorCount;
}

class _TypingHotspot {
  const _TypingHotspot({
    required this.expected,
    required this.typed,
    required this.count,
  });

  final String expected;
  final String typed;
  final int count;
}

class _TypingReport {
  const _TypingReport({
    required this.wpm,
    required this.rawWpm,
    required this.netWpm,
    required this.cpm,
    required this.accuracy,
    required this.errorCount,
    required this.extraCount,
    required this.missingCount,
    required this.backspaceCount,
    required this.elapsed,
    required this.targetLength,
    required this.typedLength,
    required this.mode,
    required this.language,
    required this.topic,
    required this.length,
    required this.hotspots,
    required this.issueBreakdown,
    required this.consistencyScore,
    required this.peakWpm,
    required this.longPauses,
    required this.correctionRatio,
  });

  final double wpm;
  final double rawWpm;
  final double netWpm;
  final double cpm;
  final double accuracy;
  final int errorCount;
  final int extraCount;
  final int missingCount;
  final int backspaceCount;
  final Duration elapsed;
  final int targetLength;
  final int typedLength;
  final _TypingMode mode;
  final _TypingLanguage language;
  final _TypingTopic topic;
  final _TypingLength length;
  final List<_TypingHotspot> hotspots;
  final Map<_TypingIssue, int> issueBreakdown;
  final double consistencyScore;
  final double peakWpm;
  final int longPauses;
  final double correctionRatio;
}

class _TypingTestCard extends StatefulWidget {
  const _TypingTestCard();

  @override
  State<_TypingTestCard> createState() => _TypingTestCardState();
}

class _TypingTestCardState extends State<_TypingTestCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Stopwatch _stopwatch = Stopwatch();
  final math.Random _random = math.Random();
  final List<_TypingReport> _recentReports = <_TypingReport>[];
  final List<_TypingSample> _samples = <_TypingSample>[];

  _TypingMode _mode = _TypingMode.classic;
  _TypingLanguage _language = _TypingLanguage.en;
  _TypingTopic _topic = _TypingTopic.all;
  _TypingLength _length = _TypingLength.standard;
  _TypingPassage? _passage;
  _TypingReport? _report;
  String _lastInput = '';
  int _backspaces = 0;
  int _lastChangeElapsedMs = 0;
  int _longPauses = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_TypingPassage> get _passages => _typingPassages;

  List<_TypingPassage> _passagePool({
    _TypingLanguage? language,
    _TypingTopic? topic,
  }) {
    final selectedLanguage = language ?? _language;
    final selectedTopic = topic ?? _topic;
    final exact = _passages
        .where(
          (item) =>
              item.language == selectedLanguage &&
              (selectedTopic == _TypingTopic.all ||
                  item.topic == selectedTopic),
        )
        .toList(growable: false);
    if (exact.isNotEmpty) {
      return exact;
    }
    final sameLanguage = _passages
        .where((item) => item.language == selectedLanguage)
        .toList(growable: false);
    return sameLanguage.isEmpty ? _passages : sameLanguage;
  }

  _TypingPassage _selectPassage() {
    final scoped = _passagePool();
    return scoped[_random.nextInt(scoped.length)];
  }

  void _ensurePassage() {
    _passage ??= _selectPassage();
  }

  String _targetText(AppI18n i18n) {
    final base = _lengthAdjustedText(i18n);
    return switch (_mode) {
      _TypingMode.symbols => '$base ${_symbolTrail(base)}',
      _TypingMode.fixErrors => base,
      _TypingMode.code => _codeTarget(base),
      _TypingMode.numbers => _numberTarget(base),
      _TypingMode.classic ||
      _TypingMode.sprint ||
      _TypingMode.precision ||
      _TypingMode.blind => base,
    };
  }

  String _lengthAdjustedText(AppI18n i18n) {
    final selected = _passage ?? _selectPassage();
    final base = selected.text(i18n);
    return switch (_length) {
      _TypingLength.short => _firstSentence(base),
      _TypingLength.standard => base,
      _TypingLength.long => _longPassageText(i18n, selected, base),
    };
  }

  String _firstSentence(String text) {
    final separators = <String>['。', '！', '？', '.', '!', '?'];
    var cut = -1;
    for (final separator in separators) {
      final index = text.indexOf(separator);
      if (index >= 18 && (cut < 0 || index < cut)) {
        cut = index;
      }
    }
    return cut < 0 ? text : text.substring(0, cut + 1);
  }

  String _longPassageText(AppI18n i18n, _TypingPassage selected, String base) {
    final companions = _passagePool()
        .where((item) => item != selected)
        .take(2)
        .map((item) => item.text(i18n));
    return <String>[base, ...companions].join(' ');
  }

  String? _challengePrompt(AppI18n i18n, String target) {
    return switch (_mode) {
      _TypingMode.fixErrors => _makeFixErrorsText(target),
      _TypingMode.code => pickUiText(
        i18n,
        zh: '格式专项：注意大小写、括号、引号和换行。',
        en: 'Format drill: preserve case, brackets, quotes, and line breaks.',
        ja: 'Format drill: preserve case, brackets, quotes, and line breaks.',
        de: 'Format drill: preserve case, brackets, quotes, and line breaks.',
        fr: 'Perceuse de format : conservez le boîtier, les crochets, les guillemets et les sauts de ligne.',
        es: 'Taladro de formato: caja de conservación, corchetes, citas y roturas de línea.',
        ru: 'Формат сверла: сохранение корпуса, скобки, котировки и разрывы линий.',
      ),
      _TypingMode.numbers => pickUiText(
        i18n,
        zh: '数字专项：注意空格、分隔符、时间和百分号。',
        en: 'Number drill: watch spaces, separators, time, and percent signs.',
        ja: 'Number drill: watch spaces, separators, time, and percent signs.',
        de: 'Number drill: watch spaces, separators, time, and percent signs.',
        fr: 'Perceuse numérique : espaces de montre, séparateurs, temps et pourcentage de panneaux.',
        es: 'Número de perforación: ver espacios, separadores, tiempo y por ciento de signos.',
        ru: 'Численность дрели: часовые пространства, разделители, время и процентные знаки.',
      ),
      _TypingMode.symbols => pickUiText(
        i18n,
        zh: '符号专项：句尾会加入真实键盘切换组合。',
        en: 'Symbol drill: the ending adds realistic keyboard switching.',
        ja: 'Symbol drill: the ending adds realistic keyboard switching.',
        de: 'Symbol drill: the ending adds realistic keyboard switching.',
        fr: 'Perceuse symbolique : la fin ajoute un changement de clavier réaliste.',
        es: 'Perforación de símbolo: el final añade conmutación de teclado realista.',
        ru: 'Символьная дрель: окончание добавляет реалистичное переключение клавиатуры.',
      ),
      _ => null,
    };
  }

  String _symbolTrail(String base) {
    final seed = base.characters.length;
    final code = (seed * 7 + 42) % 100;
    return '#42 @focus / sleep + review = calm; code:${code.toString().padLeft(2, '0')}';
  }

  String _codeTarget(String base) {
    final variable = switch (_topic) {
      _TypingTopic.all => 'typingNote',
      _TypingTopic.focus => 'focusNote',
      _TypingTopic.sleep => 'sleepCue',
      _TypingTopic.tech => 'systemNote',
      _TypingTopic.story => 'storyLine',
      _TypingTopic.vocabulary => 'wordMemory',
      _TypingTopic.travel => 'travelPlan',
    };
    final value = base
        .replaceAll('\n', ' ')
        .replaceAll('"', "'")
        .characters
        .take(44)
        .join();
    return 'final $variable = "$value";\nif ($variable.length > 8) {\n  savePracticeNote($variable);\n}';
  }

  String _numberTarget(String base) {
    final seed =
        base.characters.length + _topic.index * 31 + _language.index * 17;
    final first = 120 + seed % 780;
    final second = 2400 + (seed * 13) % 6400;
    final minute = (seed * 5) % 60;
    final percent = 72 + seed % 27;
    final ticket = (seed * 97 + 314) % 10000;
    return '$first-$second | 08:${minute.toString().padLeft(2, '0')} | $percent% | id:${ticket.toString().padLeft(4, '0')}';
  }

  String _makeFixErrorsText(String source) {
    final words = source.split(RegExp(r'\s+'));
    if (words.length >= 5) {
      final swapped = List<String>.from(words);
      final first = swapped[1];
      swapped[1] = swapped[math.min(3, swapped.length - 1)];
      swapped[math.min(3, swapped.length - 1)] = first;
      return swapped.join(' ');
    }
    final chars = source.characters.toList(growable: false);
    if (chars.length < 6) {
      return '$source typo';
    }
    final first = chars[1];
    chars[1] = chars[math.min(4, chars.length - 1)];
    chars[math.min(4, chars.length - 1)] = first;
    return chars.join();
  }

  void _reset({bool pickNew = true}) {
    _controller.clear();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      if (pickNew) {
        _passage = _selectPassage();
      }
      _report = null;
      _lastInput = '';
      _backspaces = 0;
      _samples.clear();
      _lastChangeElapsedMs = 0;
      _longPauses = 0;
    });
  }

  void _setMode(_TypingMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() => _mode = mode);
    _reset();
  }

  void _setLanguage(_TypingLanguage language) {
    if (_language == language) {
      return;
    }
    setState(() => _language = language);
    _reset();
  }

  void _setTopic(_TypingTopic topic) {
    if (_topic == topic) {
      return;
    }
    setState(() => _topic = topic);
    _reset();
  }

  void _setLength(_TypingLength length) {
    if (_length == length) {
      return;
    }
    setState(() => _length = length);
    _reset(pickNew: false);
  }

  void _startSuggestedDrill(_TypingReport report) {
    final nextMode = _typingSuggestedMode(report);
    setState(() => _mode = nextMode);
    _reset();
  }

  void _onChanged(AppI18n i18n, String value) {
    if (_report != null) {
      return;
    }
    if (value.length < _lastInput.length) {
      _backspaces += 1;
    }
    _lastInput = value;
    if (!_stopwatch.isRunning && value.isNotEmpty) {
      _stopwatch.start();
    }
    final target = _targetText(i18n);
    final stats = _typingStats(value, target);
    if (value.isNotEmpty) {
      _recordSample(value, stats);
    }
    final complete = _isComplete(value, target, stats);
    if (complete) {
      _stopwatch.stop();
      final report = _createReport(value, target, stats);
      setState(() {
        _report = report;
        _recentReports.insert(0, report);
        if (_recentReports.length > 5) {
          _recentReports.removeLast();
        }
      });
      return;
    }
    setState(() {});
  }

  void _recordSample(
    String input,
    ({int correct, int errors, int comparable}) stats,
  ) {
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    if (elapsedMs <= 0) {
      return;
    }
    if (_lastChangeElapsedMs > 0 && elapsedMs - _lastChangeElapsedMs >= 1600) {
      _longPauses += 1;
    }
    _lastChangeElapsedMs = elapsedMs;
    final shouldSample =
        _samples.isEmpty ||
        elapsedMs - _samples.last.elapsed.inMilliseconds >= 250;
    if (!shouldSample) {
      return;
    }
    _samples.add(
      _TypingSample(
        elapsed: Duration(milliseconds: elapsedMs),
        typedLength: input.characters.length,
        correctLength: stats.correct,
        errorCount: stats.errors,
      ),
    );
  }

  bool _isComplete(
    String input,
    String target,
    ({int correct, int errors, int comparable}) stats,
  ) {
    if (_mode == _TypingMode.precision) {
      return input == target;
    }
    return input.characters.length >= target.characters.length &&
        stats.comparable >= target.characters.length;
  }

  ({int correct, int errors, int comparable}) _typingStats(
    String input,
    String target,
  ) {
    final inputChars = input.characters.toList(growable: false);
    final targetChars = target.characters.toList(growable: false);
    var correct = 0;
    var errors = 0;
    final comparable = math.min(inputChars.length, targetChars.length);
    for (var i = 0; i < comparable; i += 1) {
      if (inputChars[i] == targetChars[i]) {
        correct += 1;
      } else {
        errors += 1;
      }
    }
    if (inputChars.length > targetChars.length) {
      errors += inputChars.length - targetChars.length;
    }
    return (correct: correct, errors: errors, comparable: comparable);
  }

  _TypingReport _createReport(
    String input,
    String target,
    ({int correct, int errors, int comparable}) stats,
  ) {
    final elapsed = _stopwatch.elapsed;
    final minutes = math.max(elapsed.inMilliseconds / 60000, 0.001);
    final typedLength = input.characters.length;
    final targetLength = target.characters.length;
    final safeTypedLength = math.max(typedLength, 1);
    final accuracy = (stats.correct / safeTypedLength * 100).clamp(0, 100);
    final extraCount = math.max(typedLength - targetLength, 0);
    final missingCount = math.max(targetLength - typedLength, 0);
    return _TypingReport(
      wpm: (stats.correct / 5) / minutes,
      rawWpm: (typedLength / 5) / minutes,
      netWpm: math.max((typedLength - stats.errors) / 5 / minutes, 0),
      cpm: stats.correct / minutes,
      accuracy: accuracy.toDouble(),
      errorCount: stats.errors,
      extraCount: extraCount,
      missingCount: missingCount,
      backspaceCount: _backspaces,
      elapsed: elapsed,
      targetLength: targetLength,
      typedLength: typedLength,
      mode: _mode,
      language: _language,
      topic: _topic,
      length: _length,
      hotspots: _hotspots(input, target),
      issueBreakdown: _issueBreakdown(input, target),
      consistencyScore: _consistencyScore(),
      peakWpm: _peakWpm(),
      longPauses: _longPauses,
      correctionRatio: _backspaces / math.max(stats.errors + _backspaces, 1),
    );
  }

  List<_TypingHotspot> _hotspots(String input, String target) {
    final inputChars = input.characters.toList(growable: false);
    final targetChars = target.characters.toList(growable: false);
    final counts = <String, int>{};
    for (
      var index = 0;
      index < math.min(inputChars.length, targetChars.length);
      index += 1
    ) {
      if (inputChars[index] == targetChars[index]) {
        continue;
      }
      final key = '${targetChars[index]}\u0000${inputChars[index]}';
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    if (inputChars.length > targetChars.length) {
      for (
        var index = targetChars.length;
        index < inputChars.length;
        index += 1
      ) {
        final key = '\u0000${inputChars[index]}';
        counts.update(key, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(8)
        .map((entry) {
          final parts = entry.key.split('\u0000');
          return _TypingHotspot(
            expected: parts.first,
            typed: parts.length > 1 ? parts[1] : '',
            count: entry.value,
          );
        })
        .toList(growable: false);
  }

  Map<_TypingIssue, int> _issueBreakdown(String input, String target) {
    final inputChars = input.characters.toList(growable: false);
    final targetChars = target.characters.toList(growable: false);
    final issues = <_TypingIssue, int>{};
    void add(_TypingIssue issue, int count) {
      issues.update(issue, (value) => value + count, ifAbsent: () => count);
    }

    for (
      var index = 0;
      index < math.min(inputChars.length, targetChars.length);
      index += 1
    ) {
      if (inputChars[index] != targetChars[index]) {
        add(_classifyIssue(targetChars[index]), 1);
      }
    }
    if (inputChars.length > targetChars.length) {
      add(_TypingIssue.extra, inputChars.length - targetChars.length);
    }
    if (targetChars.length > inputChars.length) {
      add(_TypingIssue.missing, targetChars.length - inputChars.length);
    }
    return issues;
  }

  _TypingIssue _classifyIssue(String char) {
    if (char.trim().isEmpty) {
      return _TypingIssue.space;
    }
    final rune = char.runes.isEmpty ? 0 : char.runes.first;
    if (rune >= 0x30 && rune <= 0x39) {
      return _TypingIssue.number;
    }
    if ((rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A)) {
      return _TypingIssue.letter;
    }
    if ((rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0x3040 && rune <= 0x30FF) ||
        (rune >= 0xAC00 && rune <= 0xD7AF)) {
      return _TypingIssue.cjk;
    }
    return _TypingIssue.punctuation;
  }

  double _currentWpm(String input) {
    if (!_stopwatch.isRunning && _report == null) {
      return 0;
    }
    final elapsedMs =
        _report?.elapsed.inMilliseconds ?? _stopwatch.elapsedMilliseconds;
    final minutes = math.max(elapsedMs / 60000, 0.001);
    return (input.characters.length / 5) / minutes;
  }

  double _currentNetWpm(
    String input,
    ({int correct, int errors, int comparable}) stats,
  ) {
    if (!_stopwatch.isRunning && _report == null) {
      return 0;
    }
    final elapsedMs =
        _report?.elapsed.inMilliseconds ?? _stopwatch.elapsedMilliseconds;
    final minutes = math.max(elapsedMs / 60000, 0.001);
    return math.max((input.characters.length - stats.errors) / 5 / minutes, 0);
  }

  double _currentCpm(String input) {
    if (!_stopwatch.isRunning && _report == null) {
      return 0;
    }
    final elapsedMs =
        _report?.elapsed.inMilliseconds ?? _stopwatch.elapsedMilliseconds;
    final minutes = math.max(elapsedMs / 60000, 0.001);
    return input.characters.length / minutes;
  }

  double _peakWpm() {
    final speeds = _samples
        .where((sample) => sample.elapsed.inMilliseconds >= 400)
        .map((sample) {
          final minutes = math.max(
            sample.elapsed.inMilliseconds / 60000,
            0.001,
          );
          return (sample.typedLength / 5) / minutes;
        })
        .toList(growable: false);
    if (speeds.isEmpty) {
      return 0;
    }
    return speeds.reduce(math.max);
  }

  double _consistencyScore() {
    final speeds = _samples
        .where(
          (sample) =>
              sample.elapsed.inMilliseconds >= 700 && sample.typedLength >= 3,
        )
        .map((sample) {
          final minutes = math.max(
            sample.elapsed.inMilliseconds / 60000,
            0.001,
          );
          return (sample.correctLength / 5) / minutes;
        })
        .where((speed) => speed.isFinite && speed > 0)
        .toList(growable: false);
    if (speeds.length < 3) {
      return 100;
    }
    final mean = speeds.reduce((a, b) => a + b) / speeds.length;
    if (mean <= 0) {
      return 0;
    }
    final variance =
        speeds
            .map((speed) => math.pow(speed - mean, 2))
            .reduce((a, b) => a + b) /
        speeds.length;
    final volatility = math.sqrt(variance) / mean;
    return (100 - volatility * 100).clamp(0, 100).toDouble();
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(1)} s';
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    _ensurePassage();
    final target = _targetText(i18n);
    final input = _controller.text;
    final stats = _typingStats(input, target);
    final inputLength = math.max(input.characters.length, 1);
    final accuracy = input.isEmpty
        ? 0.0
        : (stats.correct / inputLength * 100).clamp(0, 100).toDouble();
    final progress = target.isEmpty
        ? 0.0
        : (stats.comparable / target.characters.length).clamp(0.0, 1.0);
    final elapsed = _report?.elapsed ?? _stopwatch.elapsed;
    final liveWpm = _report?.wpm ?? _currentWpm(input);
    final liveNetWpm = _report?.netWpm ?? _currentNetWpm(input, stats);
    final liveCpm = _report?.cpm ?? _currentCpm(input);
    final consistency = _report?.consistencyScore ?? _consistencyScore();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '速度',
                en: 'Speed',
                ja: 'Speed',
                de: 'Speed',
                fr: 'Vitesse',
                es: 'Speed',
                ru: 'Скорость',
              ),
              '${liveWpm.round()} WPM',
            ),
            (
              pickUiText(
                i18n,
                zh: '净速',
                en: 'Net',
                ja: 'Net',
                de: 'Net',
                fr: 'Montant net',
                es: 'Net',
                ru: 'нет',
              ),
              '${liveNetWpm.round()} WPM',
            ),
            (
              pickUiText(
                i18n,
                zh: '字符',
                en: 'Chars',
                ja: '文字',
                de: 'Chars',
                fr: 'Chars',
                es: 'Chars',
                ru: 'Чары',
              ),
              '${liveCpm.round()} CPM',
            ),
            (
              pickUiText(
                i18n,
                zh: '准确率',
                en: 'Accuracy',
                ja: '精度',
                de: 'Accuracy',
                fr: 'Accuracy',
                es: 'Precisión',
                ru: 'точность',
              ),
              input.isEmpty ? '-' : '${accuracy.round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '错误',
                en: 'Errors',
                ja: 'Errors',
                de: 'Errors',
                fr: 'Erreurs',
                es: 'Errores',
                ru: 'ошибки',
              ),
              '${stats.errors}',
            ),
            (
              pickUiText(
                i18n,
                zh: '稳定性',
                en: 'Stability',
                ja: 'Stability',
                de: 'Stability',
                fr: 'Stabilité',
                es: 'Estabilidad',
                ru: 'Стабильность',
              ),
              input.isEmpty ? '-' : '${consistency.round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '回退',
                en: 'Backspaces',
                ja: 'バックス',
                de: 'Backspaces',
                fr: 'Espaces arrière',
                es: 'Backspaces',
                ru: 'Задние пространства',
              ),
              '$_backspaces',
            ),
            (
              pickUiText(
                i18n,
                zh: '用时',
                en: 'Time',
                ja: 'Time',
                de: 'Time',
                fr: 'Heure',
                es: 'Hora',
                ru: 'Время',
              ),
              elapsed == Duration.zero ? '-' : _formatDuration(elapsed),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _typingBuildPassageStage(
                this,
                context,
                i18n,
                target,
                input,
                progress,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('typing-test-input'),
                controller: _controller,
                focusNode: _focusNode,
                enabled: _report == null,
                maxLines: _mode == _TypingMode.blind
                    ? 1
                    : _mode == _TypingMode.code
                    ? 6
                    : 4,
                obscureText: _mode == _TypingMode.blind,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    i18n,
                    zh: '输入上方内容',
                    en: 'Type the content above',
                    ja: 'Type the content above',
                    de: 'Type the content above',
                    fr: 'Tapez le contenu ci-dessus',
                    es: 'Escriba el contenido anterior',
                    ru: 'Введите содержимое выше',
                  ),
                  helperText: _typingModeHint(i18n, _mode),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => _onChanged(i18n, value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: pickUiText(
                      i18n,
                      zh: '重新开始',
                      en: 'Restart',
                      ja: 'Restart',
                      de: 'Restart',
                      fr: 'Redémarrer',
                      es: 'Restart',
                      ru: 'Перезапустить',
                    ),
                    icon: Icons.restart_alt_rounded,
                    onPressed: () => _reset(pickNew: false),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '换一段',
                        en: 'New passage',
                        ja: 'New passage',
                        de: 'New passage',
                        fr: 'Nouveau passage',
                        es: 'Nuevo pasaje',
                        ru: 'Новый проход',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _focusNode.requestFocus(),
                    icon: const Icon(Icons.keyboard_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '聚焦输入',
                        en: 'Focus input',
                        ja: 'Focus input',
                        de: 'Focus input',
                        fr: 'Élément central',
                        es: 'Introducción focal',
                        ru: 'Внимание',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '打字设置',
            en: 'Typing settings',
            ja: 'Typing settings',
            de: 'Typing settings',
            fr: 'Paramètres de dactylographie',
            es: 'Ajustes de clasificación',
            ru: 'Настройки для печатания',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '模式、语言、题材和长度会收纳到结构化设置区，节省移动端空间。',
            en: 'Mode, language, topic, and length settings fold away to save space.',
            ja: 'Mode, language, topic, and length settings fold away to save space.',
            de: 'Mode, language, topic, and length settings fold away to save space.',
            fr: 'Mode, langue, sujet et paramètres de longueur se replient pour économiser de l\'espace.',
            es: 'Modo, lenguaje, tema y configuración de longitud se doblan para guardar espacio.',
            ru: 'Режим, язык, тема и параметры длины складываются, чтобы сэкономить место.',
          ),
          child: _typingBuildSettings(this, context, i18n),
        ),
        if (_report != null) ...<Widget>[
          const SizedBox(height: 12),
          _typingBuildReport(this, context, i18n, _report!),
        ],
        if (_recentReports.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _typingBuildRecentReports(this, context, i18n),
        ],
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '训练边界',
            en: 'Training boundary',
            ja: 'Training boundary',
            de: 'Training boundary',
            fr: 'Limite de la formation',
            es: 'Límite de capacitación',
            ru: 'Граница подготовки',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '模式、语言、题材和长度只影响当前页面即时训练。',
            en: 'Mode, language, topic, and length only affect this practice page.',
            ja: 'Mode, language, topic, and length only affect this practice page.',
            de: 'Mode, language, topic, and length only affect this practice page.',
            fr: 'Mode, language, topic, and length only affect this practice page.',
            es: 'Mode, language, topic, and length only affect this practice page.',
            ru: 'Mode, language, topic, and length only affect this practice page.',
          ),
          child: Text(
            pickUiText(
              i18n,
              zh: '结果报告不会写入学习记录。建议先用经典模式建立基准，再切换冲刺、精准、盲打、符号、格式和数字模式做专项练习。',
              en: 'Reports are not saved to study history. Start with Classic, then use Sprint, Precision, Blind, Symbols, Format, and Numbers for focused practice.',
              ja: 'Reports are not saved to study history. Start with Classic, then use Sprint, Precision, Blind, Symbols, Format, and Numbers for focused practice.',
              de: 'Reports are not saved to study history. Start with Classic, then use Sprint, Precision, Blind, Symbols, Format, and Numbers for focused practice.',
              fr: 'Reports are not saved to study history. Start with Classic, then use Sprint, Precision, Blind, Symbols, Format, and Numbers for focused practice.',
              es: 'Reports are not saved to study history. Start with Classic, then use Sprint, Precision, Blind, Symbols, Format, and Numbers for focused practice.',
              ru: 'Reports are not saved to study history. Start with Classic, then use Sprint, Precision, Blind, Symbols, Format, and Numbers for focused practice.',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}
