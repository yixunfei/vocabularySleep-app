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
      _VerbalMemoryMode.words => i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_view.pool_7ae86f',
      ),
      _VerbalMemoryMode.numbers => i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.digits_f3a6b5',
      ),
      _VerbalMemoryMode.arrows => i18n.t(
        'inline.ui.pages.toolbox_human_tests_typing_widgets.length_f37873',
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('toolbox.sound.piano.mode'), modeLabel),
            (i18n.t('toolbox.sound.pickup.level'), '$_level'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_cognition.lives_1176de',
              ),
              '$_lives',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              '$_accuracy%',
            ),
            (sizeLabel, sizeMetric),
          ],
        ),
        const SizedBox(height: 12),
        _buildSettings(context, i18n),
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
        title: i18n.t('timerIdle'),
        body: i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_view.words_digits_and_spatial_arrows_share_one_continuous_rep_123754',
        ),
      );
    }
    if (_sessionEnded) {
      return _StageMessage(
        key: const ValueKey<String>('verbal-memory-ended'),
        title: i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_view.ended_97c445',
        ),
        body: i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_view.review_or_restart_44de01',
        ),
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
        title: i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_view.word_mode_d35217',
        ),
        body: i18n.t(
          'inline.ui.pages.toolbox_human_tests_verbal_memory_view.start_then_choose_new_or_seen_84cebd',
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
          ? i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.recall_now_d62e6b',
            )
          : i18n.t(
              'inline.ui.pages.toolbox_human_tests_verbal_memory_view.digit_mode_b2602e',
            ),
      body: _input
          ? i18n.t(
              'inline.ui.pages.toolbox_human_tests_verbal_memory_view.type_the_whole_string_634d77',
            )
          : i18n.t(
              'inline.ui.pages.toolbox_human_tests_verbal_memory_view.random_digit_strings_grow_with_level_549d3d',
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
                ? i18n.t(
                    'inline.ui.pages.toolbox_human_tests_verbal_memory_view.memorize_order_2c865a',
                  )
                : i18n.t(
                    'inline.ui.pages.toolbox_human_tests_verbal_memory_view.entered_9b4640',
                  ),
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
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_view.spatial_mode_93cda7',
      ),
      body: i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_view.view_a_set_of_arrows_then_tap_the_directions_in_order_a77d72',
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
          label: i18n.t('toolbox.sleep.winddown.new'),
          icon: Icons.fiber_new_rounded,
          onPressed: enabled ? () => _submitWord(false) : null,
        ),
        OutlinedButton.icon(
          onPressed: enabled ? () => _submitWord(true) : null,
          icon: const Icon(Icons.history_rounded),
          label: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_verbal_memory_view.seen_abb37a',
            ),
          ),
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
            labelText: i18n.t(
              'inline.ui.pages.toolbox_human_tests_verbal_memory_view.type_digits_1408a6',
            ),
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
              label: i18n.t(
                'inline.ui.pages.practice_session_page.submit_4bdd5b',
              ),
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
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_verbal_memory_view.clear_input_58fe91',
                ),
              ),
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
              ? i18n.t(
                  'inline.ui.pages.toolbox_human_tests_action.running_6a424b',
                )
              : _attempts > 0
              ? i18n.t('inline.ui.pages.practice_session_page.restart_8b7fcc')
              : i18n.t('toolbox.breathing.start'),
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
          label: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_verbal_memory_view.end_with_report_7a3bcd',
            ),
          ),
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
          label: Text(i18n.t('toolbox.sleep.assist.reportCard')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(104, 48),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _resetSession,
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(i18n.t('appearanceReset')),
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
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.training_settings_b3bcbb',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_verbal_memory_view.mode_word_bank_difficulty_and_stage_height_shape_the_nex_1f3555',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_verbal_memory_view.stage_height_81f26a',
            ),
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
          '${i18n.t('inline.ui.pages.toolbox_human_tests_verbal_memory_view.domain_word_bank_9a01aa')} · ${_activeWordPool.length}',
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
          label: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_verbal_memory_view.select_all_domains_261d76',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${i18n.t('inline.ui.pages.toolbox_human_tests_verbal_memory_view.base_repeat_rate_99c9d8')} · ${(_wordRepeatChance * 100).round()}%',
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
          '${i18n.t('inline.ui.pages.toolbox_human_tests_verbal_memory_view.view_time_2c724b')} · $_previewMs ms',
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
          '${i18n.t('inline.ui.pages.toolbox_human_tests_number_memory.base_digits_654235')} · $_numberBaseLength',
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
          '${i18n.t('inline.ui.pages.toolbox_human_tests_verbal_memory_view.view_time_2c724b')} · $_previewMs ms',
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
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_verbal_memory_view.direction_set_aecb28',
          ),
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
    _VerbalMemoryMode.words => i18n.t(
      'inline.ui.pages.review_session_page.words_ae56ab',
    ),
    _VerbalMemoryMode.numbers => i18n.t(
      'inline.ui.pages.toolbox_human_tests_dynamic_vision.digits_f3a6b5',
    ),
    _VerbalMemoryMode.arrows => i18n.t(
      'inline.ui.pages.toolbox_human_tests_verbal_memory_view.arrows_9e98ba',
    ),
  };
}

String _verbalMemoryArrowSetLabel(AppI18n i18n, _VerbalMemoryArrowSet set) {
  return switch (set) {
    _VerbalMemoryArrowSet.four => i18n.t(
      'inline.ui.pages.toolbox_human_tests_verbal_memory_view.4_directions_ee3a8b',
    ),
    _VerbalMemoryArrowSet.eight => i18n.t(
      'inline.ui.pages.toolbox_human_tests_verbal_memory_view.8_directions_0a3506',
    ),
  };
}

_VerbalMemoryArrowSpec _arrowSpec(_VerbalMemoryArrowDirection direction) {
  return _verbalMemoryArrowSpecs.firstWhere(
    (spec) => spec.direction == direction,
  );
}
