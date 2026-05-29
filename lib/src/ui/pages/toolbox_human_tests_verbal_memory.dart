part of 'toolbox_human_tests.dart';

class VerbalMemoryTestPage extends StatelessWidget {
  const VerbalMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '词汇记忆',
        en: 'Verbal memory',
        ja: 'Verbal memory',
        de: 'Verbal memory',
        fr: 'Mémoire verbale',
        es: 'Memoria verbal',
        ru: 'Вербальная память',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '大脑的内存条有多宽？看你能一口气记住多少词、多少数。',
        en: 'A memory lab for domain words, digit strings, and spatial arrow sequences with custom stage height.',
        ja: 'カスタムステージの高さを持つドメインワード、ディジット文字列、空間矢印シーケンスのメモリラボ。',
        de: 'A memory lab for domain words, digit strings, and spatial arrow sequences with custom stage height.',
        fr: 'A memory lab for domain words, digit strings, and spatial arrow sequences with custom stage height.',
        es: 'Un laboratorio de memoria para palabras de dominio, cadenas de dígitos y secuencias de flechas espaciales con altura de etapa personalizada.',
        ru: 'Лаборатория памяти для доменных слов, цифровых строк и пространственных последовательностей стрелок с пользовательской высотой сцены.',
      ),
      accent: _VerbalMemoryCardState._accent,
      icon: Icons.menu_book_rounded,
      status: pickUiText(
        i18n,
        zh: '记单词、数字串或箭头——选好就开始',
        en: 'Next: choose a mode and start a continuous run',
        ja: 'Next: choose a mode and start a continuous run',
        de: 'Next: choose a mode and start a continuous run',
        fr: 'Suivant : choisissez un mode et lancez une course continue',
        es: 'Siguiente: elegir un modo y comenzar un funcionamiento continuo',
        ru: 'Далее: выберите режим и начните непрерывный бег',
      ),
      child: const _VerbalMemoryCard(),
    );
  }
}

class _VerbalMemoryCard extends StatefulWidget {
  const _VerbalMemoryCard();

  @override
  State<_VerbalMemoryCard> createState() => _VerbalMemoryCardState();
}

class _VerbalMemoryCardState extends State<_VerbalMemoryCard> {
  static const Color _accent = Color(0xFF8F6C45);
  static const int _initialLives = 3;
  static const int _recentResultLimit = 10;

  final math.Random _random = math.Random();
  final TextEditingController _numberController = TextEditingController();
  final Set<String> _seenWordKeys = <String>{};
  final List<_VerbalMemoryWordSpec> _wordHistory = <_VerbalMemoryWordSpec>[];

  Timer? _timer;
  int _roundToken = 0;

  _VerbalMemoryMode _mode = _VerbalMemoryMode.words;
  Set<_VerbalMemoryDomain> _selectedDomains = _verbalMemoryDomainOrder.toSet();
  _VerbalMemoryArrowSet _arrowSet = _VerbalMemoryArrowSet.four;
  int _stageHeight = 220;
  int _previewMs = 1100;
  int _numberBaseLength = 4;
  double _wordRepeatChance = 0.36;

  bool _sessionActive = false;
  bool _showing = false;
  bool _input = false;
  bool _sessionEnded = false;
  bool _reportDialogOpen = false;
  String _feedbackZh = '';
  String _feedbackEn = '';
  String _feedbackJa = '';
  String _feedbackDe = '';
  String _feedbackFr = '';
  String _feedbackEs = '';
  String _feedbackRu = '';

  DateTime? _sessionStartedAt;
  DateTime? _roundStartedAt;
  int _level = 1;
  int _bestLevel = 1;
  int _lives = _initialLives;
  int _attempts = 0;
  int _correct = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _totalResponseMs = 0;
  int? _bestResponseMs;
  int _maxSequenceLength = 0;

  _VerbalMemoryWordSpec? _currentWord;
  bool _currentWordWasSeen = false;
  String _currentNumber = '';
  List<_VerbalMemoryArrowDirection> _currentArrowSequence =
      <_VerbalMemoryArrowDirection>[];
  List<_VerbalMemoryArrowDirection> _enteredArrowSequence =
      <_VerbalMemoryArrowDirection>[];
  List<_VerbalMemoryRoundResult> _roundResults = <_VerbalMemoryRoundResult>[];

  @override
  void dispose() {
    _roundToken += 1;
    _timer?.cancel();
    _numberController.dispose();
    super.dispose();
  }

  bool get _canEditFlowSettings => !_sessionActive && !_reportDialogOpen;

  int get _accuracy =>
      _attempts == 0 ? 0 : (_correct / _attempts * 100).round();

  List<_VerbalMemoryWordSpec> get _activeWordPool {
    final selected = _selectedDomains.isEmpty
        ? _verbalMemoryDomainOrder.toSet()
        : _selectedDomains;
    return _verbalMemoryWordBank
        .where((word) => selected.contains(word.domain))
        .toList(growable: false);
  }

  List<_VerbalMemoryArrowSpec> get _activeArrowSpecs {
    final cardinal = <_VerbalMemoryArrowDirection>{
      _VerbalMemoryArrowDirection.up,
      _VerbalMemoryArrowDirection.left,
      _VerbalMemoryArrowDirection.right,
      _VerbalMemoryArrowDirection.down,
    };
    if (_arrowSet == _VerbalMemoryArrowSet.eight) {
      return _verbalMemoryArrowSpecs;
    }
    return _verbalMemoryArrowSpecs
        .where((spec) => cardinal.contains(spec.direction))
        .toList(growable: false);
  }

  int get _numberLength => (_numberBaseLength + _level - 1).clamp(2, 40);

  int get _arrowLength => (3 + _level - 1).clamp(3, 28);

  double get _effectiveWordRepeatChance =>
      (_wordRepeatChance + (_level - 1) * 0.012).clamp(0.12, 0.72);

  String _domainLabel(AppI18n i18n, _VerbalMemoryDomain domain) {
    final spec = _verbalMemoryDomainSpecs[domain]!;
    return spec.label(i18n);
  }

  String _modeLabel(AppI18n i18n, _VerbalMemoryMode mode) =>
      _verbalMemoryModeLabel(i18n, mode);

  String _domainSummary(AppI18n i18n) {
    if (_selectedDomains.length == _verbalMemoryDomainOrder.length) {
      return pickUiText(
        i18n,
        zh: '全部领域',
        en: 'All domains',
        ja: 'すべてのドメイン',
        de: 'All domains',
        fr: 'All domains',
        es: 'Todos los dominios',
        ru: 'Все домены',
      );
    }
    final labels = _verbalMemoryDomainOrder
        .where(_selectedDomains.contains)
        .map((domain) => _domainLabel(i18n, domain))
        .join(' / ');
    return labels.isEmpty
        ? pickUiText(
            i18n,
            zh: '全部领域',
            en: 'All domains',
            ja: 'すべてのドメイン',
            de: 'All domains',
            fr: 'All domains',
            es: 'Todos los dominios',
            ru: 'Все домены',
          )
        : labels;
  }

  String _stageStatus(AppI18n i18n) {
    if (!_sessionActive && _attempts == 0) {
      return pickUiText(
        i18n,
        zh: '选好模式后点击开始，结果只用于这次训练复盘。',
        en: 'Pick a mode and press start. Results are counted only for this run.',
        ja: 'Pick a mode and press start. Results are counted only for this run.',
        de: 'Pick a mode and press start. Results are counted only for this run.',
        fr: 'Pick a mode and press start. Results are counted only for this run.',
        es: 'Pick a mode and press start. Results are counted only for this run.',
        ru: 'Pick a mode and press start. Results are counted only for this run.',
      );
    }
    if (_sessionEnded) {
      return pickUiText(
        i18n,
        zh: '训练已结束，可查看报告或重新开始。',
        en: 'Run ended. Review the report or start again.',
        ja: 'Run ended. Review the report or start again.',
        de: 'Run ended. Review the report or start again.',
        fr: 'La course s\'est terminée. Examiner le rapport ou recommencer.',
        es: 'La carrera terminó. Revisa el informe o comienza de nuevo.',
        ru: 'Бег закончился. Просмотрите отчет или начните заново.',
      );
    }
    if (_feedbackZh.isNotEmpty) {
      return pickUiText(
        i18n,
        zh: _feedbackZh,
        en: _feedbackEn,
        ja: _feedbackJa,
        de: _feedbackDe,
        fr: _feedbackFr,
        es: _feedbackEs,
        ru: _feedbackRu,
      );
    }
    if (_mode == _VerbalMemoryMode.words) {
      return pickUiText(
        i18n,
        zh: '判断当前词是否在本轮训练中出现过。',
        en: 'Decide whether this word has appeared in this run.',
        ja: 'Decide whether this word has appeared in this run.',
        de: 'Decide whether this word has appeared in this run.',
        fr: 'Décidez si ce mot est apparu dans cette série.',
        es: 'Decide si esta palabra ha aparecido en esta carrera.',
        ru: 'Решите, появилось ли это слово в этой серии.',
      );
    }
    if (_showing) {
      return pickUiText(
        i18n,
        zh: '观察中，稍后内容会隐藏。',
        en: 'Viewing now. The prompt will hide shortly.',
        ja: 'Viewing now. The prompt will hide shortly.',
        de: 'Viewing now. The prompt will hide shortly.',
        fr: 'Je regarde maintenant. L\'invite se cachera bientôt.',
        es: 'Viendo ahora. El aviso se esconderá pronto.',
        ru: 'Смотреть сейчас. Скоро подсказка скроется.',
      );
    }
    if (_input) {
      return _mode == _VerbalMemoryMode.numbers
          ? pickUiText(
              i18n,
              zh: '输入刚才看到的完整数字串。',
              en: 'Type the full digit string.',
              ja: 'Type the full digit string.',
              de: 'Type the full digit string.',
              fr: 'Saisissez la chaîne à chiffres entiers.',
              es: 'Escribe la cadena de dígitos completos.',
              ru: 'Введите полную цифру строки.',
            )
          : pickUiText(
              i18n,
              zh: '按顺序点击刚才看到的箭头。',
              en: 'Tap the arrows in the same order.',
              ja: 'Tap the arrows in the same order.',
              de: 'Tap the arrows in the same order.',
              fr: 'Appuyez sur les flèches dans le même ordre.',
              es: 'Pulsa las flechas en el mismo orden.',
              ru: 'Нажмите на стрелки в том же порядке.',
            );
    }
    return pickUiText(
      i18n,
      zh: '下一轮准备中。',
      en: 'Preparing the next round.',
      ja: 'Preparing the next round.',
      de: 'Preparing the next round.',
      fr: 'Préparer la prochaine ronde.',
      es: 'Preparando la próxima ronda.',
      ru: 'Подготовка следующего раунда.',
    );
  }

  void _applySetting(VoidCallback updater) {
    if (!_canEditFlowSettings) {
      return;
    }
    setState(updater);
    _clearRoundOnly();
  }

  void _setStageHeight(int value) {
    setState(() => _stageHeight = value);
  }

  void _clearRoundOnly() {
    _roundToken += 1;
    _timer?.cancel();
    _numberController.clear();
    _showing = false;
    _input = false;
    _feedbackZh = '';
    _feedbackEn = '';
    _feedbackJa = '';
    _feedbackDe = '';
    _feedbackFr = '';
    _feedbackEs = '';
    _feedbackRu = '';
    _currentWord = null;
    _currentWordWasSeen = false;
    _currentNumber = '';
    _currentArrowSequence = <_VerbalMemoryArrowDirection>[];
    _enteredArrowSequence = <_VerbalMemoryArrowDirection>[];
    _roundStartedAt = null;
  }

  void _resetStats() {
    _sessionStartedAt = null;
    _level = 1;
    _bestLevel = 1;
    _lives = _initialLives;
    _attempts = 0;
    _correct = 0;
    _streak = 0;
    _bestStreak = 0;
    _totalResponseMs = 0;
    _bestResponseMs = null;
    _maxSequenceLength = 0;
    _sessionEnded = false;
    _roundResults = <_VerbalMemoryRoundResult>[];
    _seenWordKeys.clear();
    _wordHistory.clear();
  }

  void _startSession() {
    _roundToken += 1;
    _timer?.cancel();
    _numberController.clear();
    setState(() {
      _sessionActive = true;
      _resetStats();
      _feedbackZh = '';
      _feedbackEn = '';
      _feedbackJa = '';
      _feedbackDe = '';
      _feedbackFr = '';
      _feedbackEs = '';
      _feedbackRu = '';
    });
    _beginNextRound();
  }

  void _resetSession() {
    _roundToken += 1;
    _timer?.cancel();
    _numberController.clear();
    setState(() {
      _sessionActive = false;
      _resetStats();
      _clearRoundOnly();
    });
  }

  void _finishSession({required bool success, bool showReport = true}) {
    _roundToken += 1;
    _timer?.cancel();
    setState(() {
      _sessionActive = false;
      _sessionEnded = true;
      _showing = false;
      _input = false;
      _feedbackZh = success ? '训练已结束，已生成本次报告。' : '生命耗尽，训练已结束。';
      _feedbackEn = success
          ? 'Run ended. The report is ready.'
          : 'Lives are gone. The run has ended.';
      _feedbackJa = success
          ? 'トレーニングが終了しました。レポートを確認できます。'
          : 'ライフがなくなりました。トレーニング終了です。';
      _feedbackDe = success
          ? 'Training beendet. Der Bericht ist bereit.'
          : 'Keine Leben mehr. Das Training ist beendet.';
      _feedbackFr = success
          ? 'Entraînement terminé. Le rapport est prêt.'
          : 'Plus de vies. L’entraînement est terminé.';
      _feedbackEs = success
          ? 'Entrenamiento terminado. El informe está listo.'
          : 'Sin vidas. El entrenamiento terminó.';
      _feedbackRu = success
          ? 'Тренировка завершена. Отчет готов.'
          : 'Жизни закончились. Тренировка завершена.';
    });
    if (showReport) {
      _showReportDialog(success: success);
    }
  }

  void _showReportDialog({required bool success}) {
    if (!mounted || _reportDialogOpen || _attempts == 0) {
      return;
    }
    setState(() => _reportDialogOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _reportDialogOpen = false;
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _VerbalMemoryReportDialog(
          mode: _mode,
          success: success,
          attempts: _attempts,
          correct: _correct,
          lives: _lives,
          bestLevel: _bestLevel,
          bestStreak: _bestStreak,
          totalResponseMs: _totalResponseMs,
          bestResponseMs: _bestResponseMs,
          maxSequenceLength: _maxSequenceLength,
          stageHeight: _stageHeight,
          previewMs: _previewMs,
          wordPoolSize: _activeWordPool.length,
          domainsSummary: _domainSummary(
            AppI18n(Localizations.localeOf(context).languageCode),
          ),
          wordRepeatChance: _effectiveWordRepeatChance,
          arrowSet: _arrowSet,
          numberBaseLength: _numberBaseLength,
          duration: _sessionStartedAt == null
              ? Duration.zero
              : DateTime.now().difference(_sessionStartedAt!),
          results: List<_VerbalMemoryRoundResult>.unmodifiable(_roundResults),
          accent: _accent,
        ),
      );
      if (mounted) {
        setState(() => _reportDialogOpen = false);
      } else {
        _reportDialogOpen = false;
      }
    });
  }

  void _beginNextRound() {
    if (!_sessionActive || !mounted) {
      return;
    }
    _roundToken += 1;
    _timer?.cancel();
    _numberController.clear();
    setState(() {
      _feedbackZh = '';
      _feedbackEn = '';
      _feedbackJa = '';
      _feedbackDe = '';
      _feedbackFr = '';
      _feedbackEs = '';
      _feedbackRu = '';
      _showing = false;
      _input = false;
      _roundStartedAt = DateTime.now();
      _sessionStartedAt ??= _roundStartedAt;
    });
    switch (_mode) {
      case _VerbalMemoryMode.words:
        _startWordRound();
        return;
      case _VerbalMemoryMode.numbers:
        _startNumberRound();
        return;
      case _VerbalMemoryMode.arrows:
        _startArrowRound();
        return;
    }
  }

  void _startWordRound() {
    final pool = _activeWordPool.isEmpty
        ? _verbalMemoryWordBank
        : _activeWordPool;
    final repeatWindow = math.min(_wordHistory.length, 8 + _level * 2);
    final repeatPool = repeatWindow == 0
        ? const <_VerbalMemoryWordSpec>[]
        : _wordHistory
              .skip(_wordHistory.length - repeatWindow)
              .toList(growable: false);
    final shouldRepeat =
        repeatPool.isNotEmpty &&
        _random.nextDouble() < _effectiveWordRepeatChance;

    _VerbalMemoryWordSpec word;
    var wasSeen = false;
    if (shouldRepeat) {
      word = _sample(_random, repeatPool);
      wasSeen = true;
    } else {
      var unseen = pool
          .where((item) => !_seenWordKeys.contains(item.key))
          .toList(growable: false);
      if (unseen.isEmpty) {
        _seenWordKeys.clear();
        _wordHistory.clear();
        unseen = pool;
      }
      word = _sample(_random, unseen);
      wasSeen = false;
    }

    setState(() {
      _currentWord = word;
      _currentWordWasSeen = wasSeen;
      _currentNumber = '';
      _currentArrowSequence = <_VerbalMemoryArrowDirection>[];
      _enteredArrowSequence = <_VerbalMemoryArrowDirection>[];
      _showing = false;
      _input = true;
    });
  }

  void _startNumberRound() {
    final token = ++_roundToken;
    final value = _generateDigits(_numberLength);
    setState(() {
      _currentWord = null;
      _currentNumber = value;
      _currentArrowSequence = <_VerbalMemoryArrowDirection>[];
      _enteredArrowSequence = <_VerbalMemoryArrowDirection>[];
      _showing = true;
      _input = false;
      _maxSequenceLength = math.max(_maxSequenceLength, value.length);
    });
    _timer = Timer(Duration(milliseconds: _previewMs), () {
      if (!mounted || token != _roundToken) {
        return;
      }
      setState(() {
        _showing = false;
        _input = true;
      });
    });
  }

  void _startArrowRound() {
    final token = ++_roundToken;
    final directions = _activeArrowSpecs.map((spec) => spec.direction).toList();
    final sequence = List<_VerbalMemoryArrowDirection>.generate(
      _arrowLength,
      (_) => _sample(_random, directions),
    );
    setState(() {
      _currentWord = null;
      _currentNumber = '';
      _currentArrowSequence = sequence;
      _enteredArrowSequence = <_VerbalMemoryArrowDirection>[];
      _showing = true;
      _input = false;
      _maxSequenceLength = math.max(_maxSequenceLength, sequence.length);
    });
    _timer = Timer(Duration(milliseconds: _previewMs), () {
      if (!mounted || token != _roundToken) {
        return;
      }
      setState(() {
        _showing = false;
        _input = true;
      });
    });
  }

  String _generateDigits(int length) {
    final buffer = StringBuffer();
    int? previous;
    for (var index = 0; index < length; index += 1) {
      var digit = _random.nextInt(10);
      if (index == 0 && length > 1 && digit == 0) {
        digit = 1 + _random.nextInt(9);
      }
      if (previous != null && digit == previous) {
        digit = (digit + 1 + _random.nextInt(9)) % 10;
      }
      previous = digit;
      buffer.write(digit);
    }
    return buffer.toString();
  }

  void _submitWord(bool seen) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final word = _currentWord;
    if (!_input || word == null) {
      return;
    }
    final correct = seen == _currentWordWasSeen;
    final expectedLabel = _currentWordWasSeen
        ? pickUiText(
            i18n,
            zh: '见过',
            en: 'Seen',
            ja: 'Seen',
            de: 'Seen',
            fr: 'Vu',
            es: 'Visto',
            ru: 'Видимый',
          )
        : pickUiText(
            i18n,
            zh: '新词',
            en: 'New',
            ja: 'New',
            de: 'New',
            fr: 'Nouveau',
            es: 'Nuevo',
            ru: 'Новый',
          );
    final responseLabel = seen
        ? pickUiText(
            i18n,
            zh: '见过',
            en: 'Seen',
            ja: 'Seen',
            de: 'Seen',
            fr: 'Vu',
            es: 'Visto',
            ru: 'Видимый',
          )
        : pickUiText(
            i18n,
            zh: '新词',
            en: 'New',
            ja: 'New',
            de: 'New',
            fr: 'Nouveau',
            es: 'Nuevo',
            ru: 'Новый',
          );
    final stimulusLabel = _wordText(i18n, word);
    _seenWordKeys.add(word.key);
    _wordHistory.add(word);
    _commitRoundResult(
      correct: correct,
      stimulusLabel: stimulusLabel,
      expectedLabel: expectedLabel,
      responseLabel: responseLabel,
      sizeLabel: '${_activeWordPool.length}',
      detailLabel: _domainLabel(i18n, word.domain),
      feedbackCorrectZh: '判断正确，下一轮会提高记忆负荷。',
      feedbackCorrectEn: 'Correct. The next round raises memory load.',
      feedbackCorrectJa: '正解です。次のラウンドは少し難しくなります。',
      feedbackCorrectDe:
          'Richtig. Die nächste Runde erhöht die Gedächtnislast.',
      feedbackCorrectFr:
          'Correct. La prochaine manche augmente la charge de mémoire.',
      feedbackCorrectEs:
          'Correcto. La siguiente ronda sube la carga de memoria.',
      feedbackCorrectRu:
          'Верно. В следующем раунде нагрузка на память вырастет.',
      feedbackWrongZh: '判断错误，已扣除 1 次生命。',
      feedbackWrongEn: 'Wrong. One life was lost.',
      feedbackWrongJa: '違います。ライフが 1 つ減りました。',
      feedbackWrongDe: 'Falsch. Ein Leben wurde abgezogen.',
      feedbackWrongFr: 'Incorrect. Une vie a été retirée.',
      feedbackWrongEs: 'Incorrecto. Perdiste una vida.',
      feedbackWrongRu: 'Неверно. Одна жизнь потеряна.',
    );
  }

  void _submitNumber() {
    if (!_input || _currentNumber.isEmpty) {
      return;
    }
    final answer = _numberController.text.trim();
    _commitRoundResult(
      correct: answer == _currentNumber,
      stimulusLabel: _currentNumber,
      expectedLabel: _currentNumber,
      responseLabel: answer.isEmpty ? '-' : answer,
      sizeLabel: '${_currentNumber.length}',
      detailLabel: '$_previewMs ms',
      feedbackCorrectZh: '数字串复现正确，长度会继续增加。',
      feedbackCorrectEn: 'Digit string matched. Length will keep growing.',
      feedbackCorrectJa: '数字列は正解です。長さが少しずつ伸びます。',
      feedbackCorrectDe: 'Zahlenfolge richtig. Die Länge wächst weiter.',
      feedbackCorrectFr:
          'Suite de chiffres correcte. La longueur va continuer à augmenter.',
      feedbackCorrectEs:
          'Serie de números correcta. La longitud seguirá aumentando.',
      feedbackCorrectRu: 'Цифры совпали. Длина будет увеличиваться.',
      feedbackWrongZh: '数字串不一致，已扣除 1 次生命。',
      feedbackWrongEn: 'Digit string missed. One life was lost.',
      feedbackWrongJa: '数字列が一致しません。ライフが 1 つ減りました。',
      feedbackWrongDe: 'Zahlenfolge verfehlt. Ein Leben wurde abgezogen.',
      feedbackWrongFr: 'Suite de chiffres manquée. Une vie a été retirée.',
      feedbackWrongEs: 'La serie no coincide. Perdiste una vida.',
      feedbackWrongRu: 'Цифры не совпали. Одна жизнь потеряна.',
    );
  }

  void _tapArrow(_VerbalMemoryArrowDirection direction) {
    if (!_input || _currentArrowSequence.isEmpty) {
      return;
    }
    final nextIndex = _enteredArrowSequence.length;
    final expected = _currentArrowSequence[nextIndex];
    final nextInput = <_VerbalMemoryArrowDirection>[
      ..._enteredArrowSequence,
      direction,
    ];
    setState(() => _enteredArrowSequence = nextInput);

    final expectedLabel = _arrowSequenceLabel(_currentArrowSequence);
    final responseLabel = _arrowSequenceLabel(nextInput);
    if (direction != expected) {
      _commitRoundResult(
        correct: false,
        stimulusLabel: expectedLabel,
        expectedLabel: expectedLabel,
        responseLabel: responseLabel,
        sizeLabel: '${_currentArrowSequence.length}',
        detailLabel: _arrowSet == _VerbalMemoryArrowSet.eight ? '8' : '4',
        feedbackCorrectZh: '空间序列复现正确。',
        feedbackCorrectEn: 'Spatial sequence matched.',
        feedbackCorrectJa: '空間の順序が一致しました。',
        feedbackCorrectDe: 'Räumliche Reihenfolge stimmt.',
        feedbackCorrectFr: 'La séquence spatiale correspond.',
        feedbackCorrectEs: 'La secuencia espacial coincide.',
        feedbackCorrectRu: 'Пространственная последовательность совпала.',
        feedbackWrongZh: '箭头顺序不一致，已扣除 1 次生命。',
        feedbackWrongEn: 'Arrow order missed. One life was lost.',
        feedbackWrongJa: '矢印の順序が違います。ライフが 1 つ減りました。',
        feedbackWrongDe: 'Pfeilfolge verfehlt. Ein Leben wurde abgezogen.',
        feedbackWrongFr: 'Ordre des flèches manqué. Une vie a été retirée.',
        feedbackWrongEs: 'El orden de flechas no coincide. Perdiste una vida.',
        feedbackWrongRu: 'Порядок стрелок неверный. Одна жизнь потеряна.',
      );
      return;
    }
    if (nextInput.length >= _currentArrowSequence.length) {
      _commitRoundResult(
        correct: true,
        stimulusLabel: expectedLabel,
        expectedLabel: expectedLabel,
        responseLabel: responseLabel,
        sizeLabel: '${_currentArrowSequence.length}',
        detailLabel: _arrowSet == _VerbalMemoryArrowSet.eight ? '8' : '4',
        feedbackCorrectZh: '空间序列复现正确，长度会继续增加。',
        feedbackCorrectEn:
            'Spatial sequence matched. Length will keep growing.',
        feedbackCorrectJa: '空間の順序が一致しました。長さが少しずつ伸びます。',
        feedbackCorrectDe:
            'Räumliche Reihenfolge stimmt. Die Länge wächst weiter.',
        feedbackCorrectFr:
            'La séquence spatiale correspond. La longueur va augmenter.',
        feedbackCorrectEs:
            'La secuencia espacial coincide. La longitud seguirá aumentando.',
        feedbackCorrectRu:
            'Пространственная последовательность совпала. Длина будет увеличиваться.',
        feedbackWrongZh: '箭头顺序不一致，已扣除 1 次生命。',
        feedbackWrongEn: 'Arrow order missed. One life was lost.',
        feedbackWrongJa: '矢印の順序が違います。ライフが 1 つ減りました。',
        feedbackWrongDe: 'Pfeilfolge verfehlt. Ein Leben wurde abgezogen.',
        feedbackWrongFr: 'Ordre des flèches manqué. Une vie a été retirée.',
        feedbackWrongEs: 'El orden de flechas no coincide. Perdiste una vida.',
        feedbackWrongRu: 'Порядок стрелок неверный. Одна жизнь потеряна.',
      );
    }
  }

  void _clearArrowInput() {
    if (!_input) {
      return;
    }
    setState(() => _enteredArrowSequence = <_VerbalMemoryArrowDirection>[]);
  }

  void _commitRoundResult({
    required bool correct,
    required String stimulusLabel,
    required String expectedLabel,
    required String responseLabel,
    required String sizeLabel,
    required String detailLabel,
    required String feedbackCorrectZh,
    required String feedbackCorrectEn,
    required String feedbackCorrectJa,
    required String feedbackCorrectDe,
    required String feedbackCorrectFr,
    required String feedbackCorrectEs,
    required String feedbackCorrectRu,
    required String feedbackWrongZh,
    required String feedbackWrongEn,
    required String feedbackWrongJa,
    required String feedbackWrongDe,
    required String feedbackWrongFr,
    required String feedbackWrongEs,
    required String feedbackWrongRu,
  }) {
    final levelAtRound = _level;
    final responseMs = _roundStartedAt == null
        ? 0
        : DateTime.now().difference(_roundStartedAt!).inMilliseconds;
    final result = _VerbalMemoryRoundResult(
      mode: _mode,
      correct: correct,
      level: levelAtRound,
      sizeLabel: sizeLabel,
      stimulusLabel: stimulusLabel,
      expectedLabel: expectedLabel,
      responseLabel: responseLabel,
      detailLabel: detailLabel,
      responseMs: responseMs,
    );

    _timer?.cancel();
    setState(() {
      _attempts += 1;
      _totalResponseMs += responseMs;
      _bestResponseMs = _bestResponseMs == null
          ? responseMs
          : math.min(_bestResponseMs!, responseMs);
      if (correct) {
        _correct += 1;
        _streak += 1;
        _bestStreak = math.max(_bestStreak, _streak);
        _level += 1;
        _bestLevel = math.max(_bestLevel, _level);
        _feedbackZh = feedbackCorrectZh;
        _feedbackEn = feedbackCorrectEn;
        _feedbackJa = feedbackCorrectJa;
        _feedbackDe = feedbackCorrectDe;
        _feedbackFr = feedbackCorrectFr;
        _feedbackEs = feedbackCorrectEs;
        _feedbackRu = feedbackCorrectRu;
      } else {
        _lives -= 1;
        _streak = 0;
        _level = math.max(1, _level - 1);
        _feedbackZh = feedbackWrongZh;
        _feedbackEn = feedbackWrongEn;
        _feedbackJa = feedbackWrongJa;
        _feedbackDe = feedbackWrongDe;
        _feedbackFr = feedbackWrongFr;
        _feedbackEs = feedbackWrongEs;
        _feedbackRu = feedbackWrongRu;
      }
      _roundResults = <_VerbalMemoryRoundResult>[
        result,
        ..._roundResults.take(_recentResultLimit - 1),
      ];
      _showing = false;
      _input = false;
      _numberController.clear();
    });

    if (_lives <= 0) {
      _finishSession(success: false);
      return;
    }

    final token = ++_roundToken;
    _timer = Timer(const Duration(milliseconds: 620), () {
      if (!mounted || token != _roundToken) {
        return;
      }
      _beginNextRound();
    });
  }

  String _wordText(AppI18n i18n, _VerbalMemoryWordSpec word) {
    return word.label(i18n);
  }

  String _arrowSequenceLabel(List<_VerbalMemoryArrowDirection> sequence) {
    return sequence.map((direction) => _arrowSpec(direction).symbol).join(' ');
  }

  @override
  Widget build(BuildContext context) => _buildVerbalMemoryView(context);
}
