part of 'toolbox_human_tests.dart';

extension _VerbalMemoryView on _VerbalMemoryCardState {
  Widget _buildVerbalMemoryView(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final modeLabel = _modeLabel(i18n, _mode);
    final sizeMetric = switch (_mode) {
      _VerbalMemoryMode.words => '${_activeWordPool.length}',
      _VerbalMemoryMode.numbers => '$_numberLength',
      _VerbalMemoryMode.arrows => '$_arrowLength',
    };
    final sizeLabel = switch (_mode) {
      _VerbalMemoryMode.words => pickUiText(i18n, zh: '词库', en: 'Pool'),
      _VerbalMemoryMode.numbers => pickUiText(i18n, zh: '位数', en: 'Digits'),
      _VerbalMemoryMode.arrows => pickUiText(i18n, zh: '长度', en: 'Length'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '模式', en: 'Mode'), modeLabel),
            (pickUiText(i18n, zh: '等级', en: 'Level'), '$_level'),
            (pickUiText(i18n, zh: '生命', en: 'Lives'), '$_lives'),
            (pickUiText(i18n, zh: '正确率', en: 'Accuracy'), '$_accuracy%'),
            (sizeLabel, sizeMetric),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildModeStrip(context, i18n),
              const SizedBox(height: 12),
              _buildStage(context, i18n),
              const SizedBox(height: 12),
              _VerbalMemoryFeedback(
                title: _stageStatus(i18n),
                accent: _VerbalMemoryCardState._accent,
              ),
              const SizedBox(height: 12),
              _buildModeInput(context, i18n),
              const SizedBox(height: 12),
              _buildSessionActions(context, i18n),
              const SizedBox(height: 12),
              _buildSettings(context, i18n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeStrip(BuildContext context, AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _VerbalMemoryMode.values
          .map(
            (mode) => ChoiceChip(
              label: Text(_modeLabel(i18n, mode)),
              selected: _mode == mode,
              onSelected: !_canEditFlowSettings
                  ? null
                  : (_) => _applySetting(() => _mode = mode),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: _stageHeight.toDouble(),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _VerbalMemoryCardState._accent.withValues(
              alpha: _sessionActive ? 0.16 : 0.10,
            ),
            colorScheme.surface,
          ],
        ),
        border: Border.all(
          color: _lives <= 0
              ? colorScheme.error.withValues(alpha: 0.55)
              : _VerbalMemoryCardState._accent.withValues(alpha: 0.26),
          width: _lives <= 0 ? 2 : 1,
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildStageContent(context, i18n),
        ),
      ),
    );
  }

  Widget _buildStageContent(BuildContext context, AppI18n i18n) {
    if (!_sessionActive && _attempts == 0) {
      return _StageMessage(
        key: const ValueKey<String>('verbal-memory-ready'),
        title: pickUiText(i18n, zh: '准备开始', en: 'Ready'),
        body: pickUiText(
          i18n,
          zh: '词汇、数字和空间箭头共用连续训练与结果报告。',
          en: 'Words, digits, and spatial arrows share one continuous report.',
        ),
      );
    }
    if (_sessionEnded) {
      return _StageMessage(
        key: const ValueKey<String>('verbal-memory-ended'),
        title: pickUiText(i18n, zh: '已结束', en: 'Ended'),
        body: pickUiText(i18n, zh: '查看报告或重新开始。', en: 'Review or restart.'),
      );
    }
    if (_mode == _VerbalMemoryMode.words) {
      return _buildWordStage(context, i18n);
    }
    if (_mode == _VerbalMemoryMode.numbers) {
      return _buildNumberStage(context, i18n);
    }
    return _buildArrowStage(context, i18n);
  }

  Widget _buildWordStage(BuildContext context, AppI18n i18n) {
    final word = _currentWord;
    if (word == null) {
      return _StageMessage(
        key: const ValueKey<String>('verbal-memory-word-empty'),
        title: pickUiText(i18n, zh: '词汇模式', en: 'Word mode'),
        body: pickUiText(
          i18n,
          zh: '点击开始后判断新词或见过。',
          en: 'Start, then choose new or seen.',
        ),
      );
    }
    final domainSpec = _verbalMemoryDomainSpecs[word.domain]!;
    return Column(
      key: ValueKey<String>('word-${word.key}'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _HumanPill(
          text: _domainLabel(i18n, word.domain),
          accent: domainSpec.accent,
        ),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _wordText(i18n, word),
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberStage(BuildContext context, AppI18n i18n) {
    if (_showing && _currentNumber.isNotEmpty) {
      return FittedBox(
        key: ValueKey<String>('number-$_currentNumber'),
        fit: BoxFit.scaleDown,
        child: Text(
          _currentNumber,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      );
    }
    return _StageMessage(
      key: ValueKey<String>('number-hidden-$_currentNumber-$_input'),
      title: _input
          ? pickUiText(i18n, zh: '请复现', en: 'Recall now')
          : pickUiText(i18n, zh: '数字模式', en: 'Digit mode'),
      body: _input
          ? pickUiText(i18n, zh: '输入完整数字串。', en: 'Type the whole string.')
          : pickUiText(
              i18n,
              zh: '随机数字序列会随等级加长。',
              en: 'Random digit strings grow with level.',
            ),
    );
  }

  Widget _buildArrowStage(BuildContext context, AppI18n i18n) {
    final sequence = _showing ? _currentArrowSequence : _enteredArrowSequence;
    if (sequence.isNotEmpty) {
      return Column(
        key: ValueKey<String>(
          'arrows-${_showing ? 'show' : 'input'}-${sequence.length}',
        ),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _showing
                ? pickUiText(i18n, zh: '记住方向顺序', en: 'Memorize order')
                : pickUiText(i18n, zh: '已输入', en: 'Entered'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _ArrowSequenceView(
            sequence: sequence,
            accent: _VerbalMemoryCardState._accent,
          ),
        ],
      );
    }
    return _StageMessage(
      key: const ValueKey<String>('arrow-empty'),
      title: pickUiText(i18n, zh: '空间模式', en: 'Spatial mode'),
      body: pickUiText(
        i18n,
        zh: '观察一组箭头，隐藏后按顺序点击方向。',
        en: 'View a set of arrows, then tap the directions in order.',
      ),
    );
  }

  Widget _buildModeInput(BuildContext context, AppI18n i18n) {
    return switch (_mode) {
      _VerbalMemoryMode.words => _buildWordInput(context, i18n),
      _VerbalMemoryMode.numbers => _buildNumberInput(context, i18n),
      _VerbalMemoryMode.arrows => _buildArrowInput(context, i18n),
    };
  }

  Widget _buildWordInput(BuildContext context, AppI18n i18n) {
    final enabled = _sessionActive && _input && _currentWord != null;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _HumanActionButton(
          label: pickUiText(i18n, zh: '新词', en: 'New'),
          icon: Icons.fiber_new_rounded,
          onPressed: enabled ? () => _submitWord(false) : null,
        ),
        OutlinedButton.icon(
          onPressed: enabled ? () => _submitWord(true) : null,
          icon: const Icon(Icons.history_rounded),
          label: Text(pickUiText(i18n, zh: '见过', en: 'Seen')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(120, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: const ValueKey<String>('verbal-memory-number-input'),
          controller: _numberController,
          enabled: _sessionActive && _input,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: pickUiText(i18n, zh: '输入数字串', en: 'Type digits'),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitNumber(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HumanActionButton(
              label: pickUiText(i18n, zh: '提交', en: 'Submit'),
              icon: Icons.check_rounded,
              onPressed: _sessionActive && _input ? _submitNumber : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArrowInput(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ArrowPad(
          specs: _activeArrowSpecs,
          enabled: _sessionActive && _input,
          onTap: _tapArrow,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed:
                  _sessionActive && _input && _enteredArrowSequence.isNotEmpty
                  ? _clearArrowInput
                  : null,
              icon: const Icon(Icons.backspace_outlined),
              label: Text(pickUiText(i18n, zh: '清空输入', en: 'Clear input')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 48),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionActions(BuildContext context, AppI18n i18n) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _HumanActionButton(
          label: _sessionActive
              ? pickUiText(i18n, zh: '训练中', en: 'Running')
              : _attempts > 0
              ? pickUiText(i18n, zh: '重新开始', en: 'Restart')
              : pickUiText(i18n, zh: '开始', en: 'Start'),
          icon: _sessionActive
              ? Icons.hourglass_top_rounded
              : Icons.play_arrow_rounded,
          onPressed: _sessionActive ? null : _startSession,
        ),
        OutlinedButton.icon(
          onPressed: _sessionActive && _attempts > 0
              ? () => _finishSession(success: true)
              : null,
          icon: const Icon(Icons.flag_rounded),
          label: Text(pickUiText(i18n, zh: '结束并报告', en: 'End with report')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(132, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _attempts == 0 || _reportDialogOpen
              ? null
              : () => _showReportDialog(success: _lives > 0),
          icon: const Icon(Icons.analytics_rounded),
          label: Text(pickUiText(i18n, zh: '报告', en: 'Report')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(104, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _resetSession,
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(104, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return _HumanSettingsSection(
      title: pickUiText(i18n, zh: '训练设置', en: 'Training settings'),
      subtitle: pickUiText(
        i18n,
        zh: '模式、词库、难度和展示高度都会影响下一次训练。',
        en: 'Mode, word bank, difficulty, and stage height shape the next run.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '展示区高度', en: 'Stage height'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Slider(
            value: _stageHeight.toDouble(),
            min: 160,
            max: 360,
            divisions: 20,
            label: '$_stageHeight dp',
            onChanged: (value) => _setStageHeight(value.round()),
          ),
          if (_mode == _VerbalMemoryMode.words) ...<Widget>[
            _buildWordSettings(context, i18n),
          ],
          if (_mode == _VerbalMemoryMode.numbers) ...<Widget>[
            _buildNumberSettings(context, i18n),
          ],
          if (_mode == _VerbalMemoryMode.arrows) ...<Widget>[
            _buildArrowSettings(context, i18n),
          ],
        ],
      ),
    );
  }

  Widget _buildWordSettings(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          '${pickUiText(i18n, zh: '领域词库', en: 'Domain word bank')} · ${_activeWordPool.length}',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _verbalMemoryDomainOrder
              .map((domain) {
                final spec = _verbalMemoryDomainSpecs[domain]!;
                final selected = _selectedDomains.contains(domain);
                final count = _verbalMemoryWordBank
                    .where((word) => word.domain == domain)
                    .length;
                return FilterChip(
                  label: Text('${_domainLabel(i18n, domain)} $count'),
                  selected: selected,
                  selectedColor: spec.accent.withValues(alpha: 0.18),
                  checkmarkColor: spec.accent,
                  onSelected: !_canEditFlowSettings
                      ? null
                      : (_) => _applySetting(() {
                          if (selected && _selectedDomains.length > 1) {
                            _selectedDomains = <_VerbalMemoryDomain>{
                              ..._selectedDomains,
                            }..remove(domain);
                          } else if (!selected) {
                            _selectedDomains = <_VerbalMemoryDomain>{
                              ..._selectedDomains,
                              domain,
                            };
                          }
                        }),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: !_canEditFlowSettings
              ? null
              : () => _applySetting(() {
                  _selectedDomains = _verbalMemoryDomainOrder.toSet();
                }),
          icon: const Icon(Icons.done_all_rounded),
          label: Text(pickUiText(i18n, zh: '选择全部领域', en: 'Select all domains')),
        ),
        const SizedBox(height: 12),
        Text(
          '${pickUiText(i18n, zh: '基础重复率', en: 'Base repeat rate')} · ${(_wordRepeatChance * 100).round()}%',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Slider(
          value: _wordRepeatChance,
          min: 0.18,
          max: 0.62,
          divisions: 22,
          label: '${(_wordRepeatChance * 100).round()}%',
          onChanged: !_canEditFlowSettings
              ? null
              : (value) => _applySetting(() => _wordRepeatChance = value),
        ),
      ],
    );
  }

  Widget _buildNumberSettings(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          '${pickUiText(i18n, zh: '观察时长', en: 'View time')} · $_previewMs ms',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Slider(
          value: _previewMs.toDouble(),
          min: 350,
          max: 2400,
          divisions: 41,
          label: '$_previewMs ms',
          onChanged: !_canEditFlowSettings
              ? null
              : (value) => _applySetting(() => _previewMs = value.round()),
        ),
        Text(
          '${pickUiText(i18n, zh: '起始位数', en: 'Base digits')} · $_numberBaseLength',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Slider(
          value: _numberBaseLength.toDouble(),
          min: 2,
          max: 9,
          divisions: 7,
          label: '$_numberBaseLength',
          onChanged: !_canEditFlowSettings
              ? null
              : (value) =>
                    _applySetting(() => _numberBaseLength = value.round()),
        ),
      ],
    );
  }

  Widget _buildArrowSettings(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          '${pickUiText(i18n, zh: '观察时长', en: 'View time')} · $_previewMs ms',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Slider(
          value: _previewMs.toDouble(),
          min: 350,
          max: 2400,
          divisions: 41,
          label: '$_previewMs ms',
          onChanged: !_canEditFlowSettings
              ? null
              : (value) => _applySetting(() => _previewMs = value.round()),
        ),
        const SizedBox(height: 8),
        Text(
          pickUiText(i18n, zh: '方向集合', en: 'Direction set'),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _VerbalMemoryArrowSet.values
              .map(
                (set) => ChoiceChip(
                  label: Text(_verbalMemoryArrowSetLabel(i18n, set)),
                  selected: _arrowSet == set,
                  onSelected: !_canEditFlowSettings
                      ? null
                      : (_) => _applySetting(() => _arrowSet = set),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

String _verbalMemoryModeLabel(AppI18n i18n, _VerbalMemoryMode mode) {
  return switch (mode) {
    _VerbalMemoryMode.words => pickUiText(i18n, zh: '词汇识别', en: 'Words'),
    _VerbalMemoryMode.numbers => pickUiText(i18n, zh: '数字序列', en: 'Digits'),
    _VerbalMemoryMode.arrows => pickUiText(i18n, zh: '空间箭头', en: 'Arrows'),
  };
}

String _verbalMemoryArrowSetLabel(AppI18n i18n, _VerbalMemoryArrowSet set) {
  return switch (set) {
    _VerbalMemoryArrowSet.four => pickUiText(
      i18n,
      zh: '四方向',
      en: '4 directions',
    ),
    _VerbalMemoryArrowSet.eight => pickUiText(
      i18n,
      zh: '八方向',
      en: '8 directions',
    ),
  };
}

_VerbalMemoryArrowSpec _arrowSpec(_VerbalMemoryArrowDirection direction) {
  return _verbalMemoryArrowSpecs.firstWhere(
    (spec) => spec.direction == direction,
  );
}
