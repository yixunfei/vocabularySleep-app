part of 'toolbox_human_tests.dart';

enum _MicLabMode { low, high, sustain, noise }

class AuditoryLabPanel extends StatelessWidget {
  const AuditoryLabPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: pickUiText(
            i18n,
            zh: '音量校准',
            en: 'Volume calibration',
            ja: 'Volume calibration',
            de: 'Volume calibration',
            fr: 'Étalonnage du volume',
            es: 'Calibración del volumen',
            ru: 'калибровка объема',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '先把播放音量调到合适范围，再开始频率、灵敏度、空间和麦克风测试。',
            en: 'Set playback volume to a comfortable range before frequency, sensitivity, spatial, and mic tests.',
            ja: 'Set playback volume to a comfortable range before frequency, sensitivity, spatial, and mic tests.',
            de: 'Set playback volume to a comfortable range before frequency, sensitivity, spatial, and mic tests.',
            fr: 'Réglez le volume de lecture à une plage confortable avant les tests de fréquence, de sensibilité, d\'espace et de micro.',
            es: 'Establecer el volumen de reproducción a un rango cómodo antes de las pruebas de frecuencia, sensibilidad, espacio y micrófono.',
            ru: 'Установите громкость воспроизведения в удобном диапазоне перед частотными, чувствительными, пространственными и микрофонными тестами.',
          ),
        ),
        const SizedBox(height: 10),
        const _AuditoryVolumeReadinessCard(),
        const SizedBox(height: 12),
        const _AuditoryTestCard(),
      ],
    );
  }
}

class AcousticExperimentTestPage extends StatelessWidget {
  const AcousticExperimentTestPage({super.key});

  static const Color _accent = Color(0xFF7F8B55);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '声学实验',
        en: 'Acoustic experiment',
        ja: '音響実験',
        de: 'Akustiktest',
        fr: 'Expérience acoustique',
        es: 'Experimento acústico',
        ru: 'Акустический тест',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '用麦克风记录低音、高音、持续发声和环境噪声，整理成可读的声学报告。',
        en: 'Record low tone, high tone, vocal sustain, and ambient noise with the microphone, then review a readable acoustic report.',
        ja: 'マイクで低音、高音、持続音、周囲の音を記録し、読みやすい音響レポートで確認します。',
        de: 'Nimm tiefe Töne, hohe Töne, gehaltene Stimme und Umgebungsgeräusche mit dem Mikrofon auf und prüfe sie in einem verständlichen Akustikbericht.',
        fr: 'Enregistrez les graves, les aigus, la tenue vocale et le bruit ambiant au micro, puis consultez un rapport acoustique clair.',
        es: 'Graba tonos graves, agudos, voz sostenida y ruido ambiente con el micrófono, y revisa un informe acústico claro.',
        ru: 'Запишите низкий тон, высокий тон, длительное звучание и шум комнаты, затем посмотрите понятный акустический отчет.',
      ),
      accent: _accent,
      icon: Icons.mic_external_on_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：允许麦克风权限，选择模式后开始采样',
        en: 'Next: allow microphone access, choose a mode, and start sampling',
        ja: '次へ: マイクを許可し、モードを選んで測定を始めます',
        de: 'Weiter: Mikrofon erlauben, Modus wählen und Aufnahme starten',
        fr: 'Étape suivante : autoriser le micro, choisir un mode et lancer la mesure',
        es: 'Siguiente: permite el micrófono, elige un modo y empieza a medir',
        ru: 'Далее: разрешите доступ к микрофону, выберите режим и начните запись',
      ),
      child: const AcousticExperimentPanel(),
    );
  }
}

class AcousticExperimentPanel extends StatelessWidget {
  const AcousticExperimentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: pickUiText(
            i18n,
            zh: '麦克风声学实验',
            en: 'Mic acoustic lab',
            ja: 'マイク音響ラボ',
            de: 'Mikrofon-Akustiklabor',
            fr: 'Laboratoire acoustique micro',
            es: 'Laboratorio acústico de micrófono',
            ru: 'Микрофонная акустика',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '按模式完成采样，查看音量、音高稳定性、持续性和环境噪声表现。结果适合日常练习和环境观察。',
            en: 'Complete each sampling mode to review level, pitch stability, sustain, and ambient noise. Use the results for everyday practice and room checks.',
            ja: '各モードで測定し、音量、音程の安定性、持続、周囲の音を確認します。日々の練習や部屋の確認に使えます。',
            de: 'Schließe jeden Aufnahmemodus ab, um Pegel, Tonhöhenstabilität, Halten und Umgebungsgeräusch zu prüfen. Die Ergebnisse eignen sich für Übung und Raumcheck.',
            fr: 'Terminez chaque mode pour voir le niveau, la stabilité de hauteur, la tenue et le bruit ambiant. Les résultats servent à l’entraînement et au contrôle de la pièce.',
            es: 'Completa cada modo para revisar nivel, estabilidad de tono, sostenido y ruido ambiente. Úsalo para practicar y comprobar la habitación.',
            ru: 'Пройдите каждый режим, чтобы увидеть уровень, стабильность высоты, длительность и шум комнаты. Результаты подходят для практики и проверки помещения.',
          ),
        ),
        const SizedBox(height: 10),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '声学指标',
            en: 'Acoustic metrics',
            ja: '音響メトリック',
            de: 'Acoustic metrics',
            fr: 'Acoustic metrics',
            es: 'métricas acústicas',
            ru: 'Акустические метрики',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '记录 dBFS、峰值、音高、稳定性、持续性、曲线平滑度和环境评分。',
            en: 'Tracks dBFS, peak, pitch, stability, sustain, smoothness, and ambient score.',
            ja: 'Tracks dBFS, peak, pitch, stability, sustain, smoothness, and ambient score.',
            de: 'Tracks dBFS, peak, pitch, stability, sustain, smoothness, and ambient score.',
            fr: 'Voies dBFS, pic, pas, stabilité, maintien, douceur et score ambiant.',
            es: 'Pistas dBFS, pico, campo, estabilidad, sostenimiento, suavidad y puntuación ambiente.',
            ru: 'Треки dBFS, пик, высота, стабильность, устойчивость, плавность и окружающая оценка.',
          ),
          initiallyExpanded: true,
          child: const _AuditoryMicLabCard(),
        ),
      ],
    );
  }
}

class _AuditoryVolumeReadinessCard extends StatefulWidget {
  const _AuditoryVolumeReadinessCard();

  @override
  State<_AuditoryVolumeReadinessCard> createState() =>
      _AuditoryVolumeReadinessCardState();
}

class _AuditoryVolumeReadinessCardState
    extends State<_AuditoryVolumeReadinessCard> {
  ToolboxAudioVolumeSnapshot? _snapshot;
  bool _loading = true;
  bool _applying = false;
  bool _promptShown = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshVolumeState());
    });
  }

  Future<void> _refreshVolumeState() async {
    if (!mounted) {
      return;
    }
    if (!_isAutoAdjustEnabled(context)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = null;
        _loading = false;
        _applying = false;
        _statusText = 'auto_disabled';
      });
      return;
    }
    setState(() {
      _loading = true;
      _statusText = null;
    });
    try {
      final snapshot = await ToolboxAudioVolumeService.inspectPlaybackVolume(
        recommendedRatio: 0.65,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _statusText = snapshot.message ?? 'ok';
      });
      if (!_isAutoAdjustEnabled(context)) {
        setState(() => _statusText = 'auto_disabled');
        return;
      }
      if (snapshot.needsAdjustment && snapshot.canAutoApply) {
        if (!mounted) {
          return;
        }
        setState(() => _statusText = 'auto_applying');
        await _applyRecommendedVolume();
      } else if (!snapshot.canAutoApply &&
          snapshot.needsAdjustment &&
          !_promptShown) {
        _promptShown = true;
        await _showManualAdjustmentPrompt(snapshot);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _statusText = 'read_failed';
      });
    }
  }

  Future<void> _applyRecommendedVolume() async {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.canAutoApply || _applying) {
      return;
    }
    if (!_isAutoAdjustEnabled(context)) {
      setState(() => _statusText = 'auto_disabled');
      return;
    }
    setState(() => _applying = true);
    try {
      final applied =
          await ToolboxAudioVolumeService.applyRecommendedPlaybackVolume(
            recommendedRatio: snapshot.recommendedRatio,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = applied;
        _applying = false;
        _statusText =
            applied.message ?? (applied.needsAdjustment ? 'auto_failed' : 'ok');
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _applying = false;
        _statusText = 'auto_failed';
      });
    }
  }

  bool _isAutoAdjustEnabled(BuildContext context) {
    try {
      return ProviderScope.containerOf(
        context,
        listen: false,
      ).read(appStateProvider).toolboxAutoAdjustSystemVolumeEnabled;
    } catch (_) {
      return false;
    }
  }

  void _setAutoAdjustEnabled(BuildContext context, bool enabled) {
    try {
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(appStateProvider).setToolboxAutoAdjustSystemVolumeEnabled(enabled);
    } catch (_) {
      // Tests and standalone embeddings may not provide AppState.
    }
  }

  Future<void> _showManualAdjustmentPrompt(
    ToolboxAudioVolumeSnapshot snapshot,
  ) async {
    if (!mounted) {
      return;
    }
    final context = this.context;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            pickUiText(
              i18n,
              zh: '请手动调整系统音量',
              en: 'Adjust system volume manually',
              ja: 'システム音量を手動で調整する',
              de: 'Adjust system volume manually',
              fr: 'Adjust system volume manually',
              es: 'Ajuste manualmente el volumen del sistema',
              ru: 'Регулировать объем системы вручную',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '当前设备无法自动改动系统媒体音量，请先把音量调到推荐范围再继续测试。',
                  en: 'This device cannot change the system media volume automatically. Please move the volume into the recommended range before continuing.',
                  ja: 'This device cannot change the system media volume automatically. Please move the volume into the recommended range before continuing.',
                  de: 'This device cannot change the system media volume automatically. Please move the volume into the recommended range before continuing.',
                  fr: 'Ce périphérique ne peut pas changer automatiquement le volume des médias système. Veuillez déplacer le volume dans la plage recommandée avant de continuer.',
                  es: 'Este dispositivo no puede cambiar el volumen multimedia del sistema automáticamente. Por favor, mueva el volumen al rango recomendado antes de continuar.',
                  ru: 'Это устройство не может автоматически изменять объем системных носителей. Пожалуйста, переместите объем в рекомендуемый диапазон, прежде чем продолжить.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pickUiText(
                  i18n,
                  zh: '当前值: ${(snapshot.currentRatio * 100).round()}%  推荐值: ${(snapshot.recommendedRatio * 100).round()}%',
                  en: 'Current: ${(snapshot.currentRatio * 100).round()}%  Recommended: ${(snapshot.recommendedRatio * 100).round()}%',
                  ja: 'Current: ${(snapshot.currentRatio * 100).round()}%  Recommended: ${(snapshot.recommendedRatio * 100).round()}%',
                  de: 'Current: ${(snapshot.currentRatio * 100).round()}%  Recommended: ${(snapshot.recommendedRatio * 100).round()}%',
                  fr: 'Actuellement : ${(snapshot.currentRatio * 100).round()}% Recommandé : ${(snapshot.recommendedRatio * 100).round()}%',
                  es: 'Corriente: 0/% Recomendado: <v1/%',
                  ru: 'Текущее значение: ${(snapshot.currentRatio * 100).round()}% Рекомендовано: ${(snapshot.recommendedRatio * 100).round()}%',
                ),
              ),
              if (snapshot.currentIndex != null &&
                  snapshot.maxIndex != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '系统音量档位: ${snapshot.currentIndex}/${snapshot.maxIndex}',
                    en: 'System volume index: ${snapshot.currentIndex}/${snapshot.maxIndex}',
                    ja: 'System volume index: ${snapshot.currentIndex}/${snapshot.maxIndex}',
                    de: 'System volume index: ${snapshot.currentIndex}/${snapshot.maxIndex}',
                    fr: 'Indice de volume du système: ${snapshot.currentIndex}/${snapshot.maxIndex}',
                    es: 'Índice de volumen del sistema:',
                    ru: 'Индекс объема системы: ${snapshot.currentIndex}/${snapshot.maxIndex}',
                  ),
                ),
              ],
              if (snapshot.currentDb != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '参考输出: ${snapshot.currentDb!.toStringAsFixed(1)} dB',
                    en: 'Reference output: ${snapshot.currentDb!.toStringAsFixed(1)} dB',
                    ja: 'Reference output: ${snapshot.currentDb!.toStringAsFixed(1)} dB',
                    de: 'Reference output: ${snapshot.currentDb!.toStringAsFixed(1)} dB',
                    fr: 'Sortie de référence : ${snapshot.currentDb!.toStringAsFixed(1)} dB',
                    es: 'Resultado de referencia:',
                    ru: 'Ссылочный выход: ${snapshot.currentDb!.toStringAsFixed(1)} dB',
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '稍后',
                  en: 'Later',
                  ja: 'Later',
                  de: 'Later',
                  fr: 'Plus tard',
                  es: 'Más tarde',
                  ru: 'Позже',
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _refreshVolumeState();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '我已调整',
                  en: 'I adjusted it',
                  ja: 'I adjusted it',
                  de: 'I adjusted it',
                  fr: 'Je l\'ai ajusté.',
                  es: 'Lo ajusté.',
                  ru: 'Я скорректировал его.',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _volumeStatusMessage(
    AppI18n i18n,
    ToolboxAudioVolumeSnapshot? snapshot,
  ) {
    if (_statusText == 'auto_disabled') {
      return pickUiText(
        i18n,
        zh: '自动调整系统媒体音量已关闭；需要时可在此快捷开启，或手动使用音量键校准。',
        en: 'Automatic system media volume adjustment is off. Enable it here when needed, or calibrate manually with volume keys.',
        ja: 'Automatic system media volume adjustment is off. Enable it here when needed, or calibrate manually with volume keys.',
        de: 'Automatic system media volume adjustment is off. Enable it here when needed, or calibrate manually with volume keys.',
        fr: 'Le réglage automatique du volume média système est désactivé. Activez-le ici si nécessaire ou calibrez manuellement.',
        es: 'El ajuste automático del volumen multimedia del sistema está desactivado. Actívalo aquí si hace falta o calibra manualmente.',
        ru: 'Автоматическая регулировка громкости системных медиа отключена. Включите ее здесь при необходимости или настройте вручную.',
      );
    }
    if (_statusText == 'auto_applying') {
      return pickUiText(
        i18n,
        zh: '正在自动调整系统媒体音量...',
        en: 'Adjusting system media volume automatically...',
        ja: 'システムメディアボリュームを自動的に調整しています...',
        de: 'Adjusting system media volume automatically...',
        fr: 'Adjusting system media volume automatically...',
        es: 'Ajuste del volumen de medios del sistema automáticamente...',
        ru: 'Регулировка объема медиасистемы автоматически...',
      );
    }
    if (_statusText == 'read_failed') {
      return pickUiText(
        i18n,
        zh: '无法读取系统媒体音量。请手动把媒体音量调到约 65%。',
        en: 'Cannot read system media volume. Set media volume near 65% manually.',
        ja: 'システムメディアボリュームを読み取れません。メディアボリュームを手動で65%近くに設定します。',
        de: 'Cannot read system media volume. Set media volume near 65% manually.',
        fr: 'Impossible de lire le volume des médias système. Réglez le volume des médias près de 65% manuellement.',
        es: 'No se puede leer volumen de medios de sistema. Establecer volumen de medios cerca del 65% manualmente.',
        ru: 'Не может читать объем системных носителей. Установить объем медиа около 65% вручную.',
      );
    }
    if (_statusText == 'auto_failed') {
      return pickUiText(
        i18n,
        zh: '自动调整未完成。请手动调整系统媒体音量后重新检查。',
        en: 'Automatic adjustment did not complete. Adjust media volume manually and recheck.',
        ja: '自動調整が完了しませんでした。 メディアの音量を手動で調整し、再確認します。',
        de: 'Automatic adjustment did not complete. Adjust media volume manually and recheck.',
        fr: 'Le réglage automatique n\'a pas été effectué. Ajustez manuellement le volume des médias et revérifiez.',
        es: 'El ajuste automático no se completó. Ajuste manualmente el volumen multimedia y vuelva a comprobar.',
        ru: 'Автоматическая настройка не была завершена. Настройте объем медиа вручную и перепроверьте.',
      );
    }
    if (snapshot == null) {
      return pickUiText(
        i18n,
        zh: '等待设备音量检查。',
        en: 'Waiting for volume check.',
        ja: 'Waiting for volume check.',
        de: 'Waiting for volume check.',
        fr: 'Attendre le contrôle du volume.',
        es: 'Esperando un cheque de volumen.',
        ru: 'В ожидании проверки объема.',
      );
    }
    if (!snapshot.isSupported) {
      return pickUiText(
        i18n,
        zh: '当前平台不支持读取系统音量，请按设备音量键手动校准。',
        en: 'This platform cannot report system volume; calibrate manually with volume keys.',
        ja: 'This platform cannot report system volume; calibrate manually with volume keys.',
        de: 'This platform cannot report system volume; calibrate manually with volume keys.',
        fr: 'Cette plate-forme ne peut pas rapporter le volume du système; calibrer manuellement avec les touches de volume.',
        es: 'Esta plataforma no puede reportar volumen del sistema; calibrar manualmente con teclas de volumen.',
        ru: 'Эта платформа не может сообщать об объеме системы; калибровать вручную с помощью клавиш громкости.',
      );
    }
    if (snapshot.needsAdjustment) {
      return snapshot.canAutoApply
          ? pickUiText(
              i18n,
              zh: '音量不在建议范围内，可使用自动调整或手动调到推荐值。',
              en: 'Volume is outside the recommended range. Use auto adjust or set it manually.',
              ja: 'Volume is outside the recommended range. Use auto adjust or set it manually.',
              de: 'Volume is outside the recommended range. Use auto adjust or set it manually.',
              fr: 'Le volume est hors de la plage recommandée. Utilisez le réglage automatique ou le régler manuellement.',
              es: 'El volumen está fuera del rango recomendado. Utilice el ajuste automático o ajustarlo manualmente.',
              ru: 'Объем находится за пределами рекомендуемого диапазона. Используйте авторегулировку или установите ее вручную.',
            )
          : pickUiText(
              i18n,
              zh: '音量不在建议范围内，请手动调到推荐值再开始测试。',
              en: 'Volume is outside the recommended range. Set it manually before testing.',
              ja: 'Volume is outside the recommended range. Set it manually before testing.',
              de: 'Volume is outside the recommended range. Set it manually before testing.',
              fr: 'Le volume est hors de la plage recommandée. Réglez-le manuellement avant de tester.',
              es: 'El volumen está fuera del rango recomendado. Ponlo manualmente antes de probar.',
              ru: 'Объем находится за пределами рекомендуемого диапазона. Установите его вручную перед тестированием.',
            );
    }
    return pickUiText(
      i18n,
      zh: '系统媒体音量已处于建议范围。',
      en: 'System media volume is in the recommended range.',
      ja: 'System media volume is in the recommended range.',
      de: 'System media volume is in the recommended range.',
      fr: 'Le volume des médias système est dans la plage recommandée.',
      es: 'El volumen de los medios de comunicación del sistema está en el rango recomendado.',
      ru: 'Объем системных носителей находится в рекомендуемом диапазоне.',
    );
  }

  Widget _buildAutoAdjustDisabledCard(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.volume_off_rounded,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pickUiText(
                        i18n,
                        zh: '自动调整系统音量已关闭',
                        en: 'Auto system volume adjustment is off',
                        ja: '自動システム音量調整はオフです',
                        de: 'Auto system volume adjustment is off',
                        fr: 'Réglage automatique du volume désactivé',
                        es: 'Ajuste automático de volumen desactivado',
                        ru: 'Автонастройка громкости отключена',
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '声学测试不会在未说明的情况下修改你的系统媒体音量。开启后，本页会先检查当前音量，并在支持的平台上把媒体音量调到建议范围。',
                        en: 'The acoustic test will not change your system media volume without notice. If enabled, this page checks the current volume first, then sets media volume to the recommended range on supported platforms.',
                        ja: 'The acoustic test will not change your system media volume without notice. If enabled, this page checks the current volume first, then sets media volume to the recommended range on supported platforms.',
                        de: 'The acoustic test will not change your system media volume without notice. If enabled, this page checks the current volume first, then sets media volume to the recommended range on supported platforms.',
                        fr: 'Le test acoustique ne modifie pas le volume média système sans avertissement. Une fois activé, il vérifie d’abord le volume puis l’ajuste sur les plateformes prises en charge.',
                        es: 'La prueba acústica no cambiará el volumen multimedia del sistema sin aviso. Si se activa, primero comprueba el volumen y luego lo ajusta en plataformas compatibles.',
                        ru: 'Акустический тест не изменит системную громкость без предупреждения. После включения он сначала проверит громкость, а затем настроит ее на поддерживаемых платформах.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () async {
                  _setAutoAdjustEnabled(context, true);
                  await _refreshVolumeState();
                },
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '快捷开启并检查',
                    en: 'Enable and check',
                    ja: 'Enable and check',
                    de: 'Enable and check',
                    fr: 'Activer et vérifier',
                    es: 'Activar y comprobar',
                    ru: 'Включить и проверить',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final autoAdjustEnabled = _isAutoAdjustEnabled(context);
    if (!autoAdjustEnabled) {
      return _buildAutoAdjustDisabledCard(context, i18n);
    }
    final snapshot = _snapshot;
    final current = snapshot?.currentRatio ?? 0;
    final recommended = snapshot?.recommendedRatio ?? 0.65;
    final needsAdjustment = snapshot?.needsAdjustment ?? false;
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '平台',
                  en: 'Platform',
                  ja: 'Platform',
                  de: 'Platform',
                  fr: 'Plateforme',
                  es: 'Plataforma',
                  ru: 'Платформа',
                ),
                value: snapshot?.platformName ?? '--',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '当前',
                  en: 'Current',
                  ja: '現在',
                  de: 'Current',
                  fr: 'Actuellement',
                  es: 'Corriente',
                  ru: 'текущий',
                ),
                value: '${(current * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '推荐',
                  en: 'Recommended',
                  ja: 'Recommended',
                  de: 'Recommended',
                  fr: 'Recommandation',
                  es: 'Recomendado',
                  ru: 'рекомендованный',
                ),
                value: '${(recommended * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '自动调整',
                  en: 'Auto adjust',
                  ja: '自動調整',
                  de: 'Auto adjust',
                  fr: 'Réglage automatique',
                  es: 'Ajuste automático',
                  ru: 'Автоматическая настройка',
                ),
                value: snapshot == null
                    ? '--'
                    : snapshot.canAutoApply
                    ? pickUiText(
                        i18n,
                        zh: '可用',
                        en: 'Yes',
                        ja: 'Yes',
                        de: 'Yes',
                        fr: 'Oui',
                        es: 'Sí.',
                        ru: 'Да.',
                      )
                    : pickUiText(
                        i18n,
                        zh: '手动',
                        en: 'Manual',
                        ja: 'Manual',
                        de: 'Manual',
                        fr: 'Manuel',
                        es: 'Manual',
                        ru: 'Ручной',
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: current.clamp(0.0, 1.0).toDouble(),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _loading
                ? pickUiText(
                    i18n,
                    zh: '正在检查系统音量...',
                    en: 'Checking system volume...',
                    ja: 'システムボリュームを確認しています...',
                    de: 'Checking system volume...',
                    fr: 'Contrôle du volume du système...',
                    es: 'Comprobando el volumen del sistema...',
                    ru: 'Проверка объема системы...',
                  )
                : needsAdjustment
                ? pickUiText(
                    i18n,
                    zh: '音量未落在推荐范围内，请先调整再开始测试。',
                    en: 'The volume is outside the recommended range. Adjust it before starting the test.',
                    ja: 'The volume is outside the recommended range. Adjust it before starting the test.',
                    de: 'The volume is outside the recommended range. Adjust it before starting the test.',
                    fr: 'Le volume est hors de la plage recommandée. Réglez-le avant de commencer le test.',
                    es: 'El volumen está fuera del rango recomendado. Ajustarlo antes de comenzar la prueba.',
                    ru: 'Объем находится за пределами рекомендуемого диапазона. Отрегулируйте его перед началом теста.',
                  )
                : pickUiText(
                    i18n,
                    zh: '系统音量已适合当前听觉测试。',
                    en: 'The system volume is ready for the current hearing test.',
                    ja: 'The system volume is ready for the current hearing test.',
                    de: 'The system volume is ready for the current hearing test.',
                    fr: 'Le volume du système est prêt pour le test d\'audition actuel.',
                    es: 'El volumen del sistema está listo para la prueba auditiva actual.',
                    ru: 'Объем системы готов к текущему тесту на слух.',
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (snapshot?.message != null &&
              snapshot!.message!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _volumeStatusMessage(i18n, snapshot),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _loading ? null : _refreshVolumeState,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '重新检查',
                    en: 'Recheck',
                    ja: 'Recheck',
                    de: 'Recheck',
                    fr: 'Revérifier',
                    es: 'Rechazo',
                    ru: 'перепроверять',
                  ),
                ),
              ),
              if (snapshot != null && snapshot.canAutoApply)
                FilledButton.tonalIcon(
                  onPressed: _applying ? null : _applyRecommendedVolume,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(
                    _applying
                        ? pickUiText(
                            i18n,
                            zh: '正在调整',
                            en: 'Adjusting',
                            ja: '調整中',
                            de: 'Adjusting',
                            fr: 'Adjusting',
                            es: 'Ajuste',
                            ru: 'корректировка',
                          )
                        : pickUiText(
                            i18n,
                            zh: '自动调整',
                            en: 'Auto adjust',
                            ja: '自動調整',
                            de: 'Auto adjust',
                            fr: 'Réglage automatique',
                            es: 'Ajuste automático',
                            ru: 'Автоматическая настройка',
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicModeSpec {
  const _MicModeSpec({
    required this.zhLabel,
    required this.enLabel,
    required this.jaLabel,
    required this.deLabel,
    required this.frLabel,
    required this.esLabel,
    required this.ruLabel,
    required this.zhDescription,
    required this.enDescription,
    required this.jaDescription,
    required this.deDescription,
    required this.frDescription,
    required this.esDescription,
    required this.ruDescription,
    required this.icon,
    required this.targetMinHz,
    required this.targetMaxHz,
  });

  final String zhLabel;
  final String enLabel;
  final String jaLabel;
  final String deLabel;
  final String frLabel;
  final String esLabel;
  final String ruLabel;
  final String zhDescription;
  final String enDescription;
  final String jaDescription;
  final String deDescription;
  final String frDescription;
  final String esDescription;
  final String ruDescription;
  final IconData icon;
  final double targetMinHz;
  final double targetMaxHz;

  String label(AppI18n i18n) => pickUiText(
    i18n,
    zh: zhLabel,
    en: enLabel,
    ja: jaLabel,
    de: deLabel,
    fr: frLabel,
    es: esLabel,
    ru: ruLabel,
  );

  String description(AppI18n i18n) => pickUiText(
    i18n,
    zh: zhDescription,
    en: enDescription,
    ja: jaDescription,
    de: deDescription,
    fr: frDescription,
    es: esDescription,
    ru: ruDescription,
  );
}

class _MicRecorderProfile {
  const _MicRecorderProfile({
    required this.id,
    required this.config,
    required this.sampleRate,
  });

  final String id;
  final RecordConfig config;
  final int sampleRate;
}

class _MicFrameSample {
  const _MicFrameSample({
    required this.elapsedMs,
    required this.rms,
    required this.peak,
    required this.dbfs,
    required this.zeroCrossingRate,
    required this.clippingRatio,
    required this.pitchStability,
    required this.sustainScore,
    required this.ambientScore,
    required this.curveSmoothness,
    required this.levelConsistency,
    this.pitchHz,
  });

  final int elapsedMs;
  final double rms;
  final double peak;
  final double dbfs;
  final double zeroCrossingRate;
  final double clippingRatio;
  final double pitchStability;
  final double sustainScore;
  final double ambientScore;
  final double curveSmoothness;
  final double levelConsistency;
  final double? pitchHz;

  double get peakDbfs => peak <= 1e-6
      ? -120.0
      : (20 * math.log(peak) / math.ln10).clamp(-120.0, 0.0).toDouble();
}

class _MicLabCapture {
  _MicLabCapture({
    required this.mode,
    required this.sampleCount,
    required this.durationMs,
    required this.averageDbfs,
    required this.minDbfs,
    required this.maxDbfs,
    required this.peakDbfs,
    required this.averageLevel,
    required this.peakLevel,
    required this.averagePitchHz,
    required this.minPitchHz,
    required this.maxPitchHz,
    required this.pitchStdDevHz,
    required this.pitchStability,
    required this.sustainScore,
    required this.ambientScore,
    required this.curveSmoothness,
    required this.levelConsistency,
    required this.zeroCrossingRate,
    required this.clippingRatio,
    required this.voicedRatio,
    required this.dynamicRangeDb,
    required this.crestFactorDb,
    required this.snrDb,
    required this.targetHitRatio,
    required this.emptyChunkRatio,
    required this.qualityScore,
  });

  factory _MicLabCapture.fromSamples({
    required _MicLabMode mode,
    required _MicModeSpec spec,
    required List<_MicFrameSample> samples,
    required double? noiseFloorDbfs,
  }) {
    final voicedSamples = samples
        .where((sample) => sample.pitchHz != null && sample.dbfs > -62)
        .toList(growable: false);
    final pitchSamples = voicedSamples
        .map((sample) => sample.pitchHz)
        .whereType<double>()
        .toList(growable: false);
    final levels = samples.map((sample) => sample.rms).toList(growable: false);
    final dbValues = samples
        .map((sample) => sample.dbfs)
        .toList(growable: false);
    final voicedRatio = samples.isEmpty
        ? 0.0
        : pitchSamples.length / samples.length;
    final averagePitch = _averageOrNull(pitchSamples);
    final pitchStdDev = averagePitch == null
        ? 0.0
        : _stdDev(pitchSamples, averagePitch);
    final averageDbfs = _averageOrZero(dbValues);
    final averageLevel = _averageOrZero(levels);
    final peakLevel = samples
        .map((sample) => sample.peak)
        .fold<double>(0, math.max);
    final targetHitRatio = _targetHitRatio(mode, spec, samples);
    final clippingRatio = _averageOrZero(
      samples.map((sample) => sample.clippingRatio),
    );
    final dynamicRangeDb = dbValues.isEmpty
        ? 0.0
        : (dbValues.reduce(math.max) - dbValues.reduce(math.min));
    final peakDbfs = samples.isEmpty
        ? -120.0
        : samples.map((sample) => sample.peakDbfs).reduce(math.max);
    final crestFactorDb = averageLevel <= 1e-6 || peakLevel <= 1e-6
        ? 0.0
        : (20 * math.log(peakLevel / averageLevel) / math.ln10)
              .clamp(0.0, 60.0)
              .toDouble();
    final snrDb = noiseFloorDbfs == null || mode == _MicLabMode.noise
        ? null
        : (averageDbfs - noiseFloorDbfs).clamp(-40.0, 80.0).toDouble();
    final pitchStability = _averageOrZero(
      samples.map((sample) => sample.pitchStability),
    );
    final sustainScore = _averageOrZero(
      samples.map((sample) => sample.sustainScore),
    );
    final ambientScore = _averageOrZero(
      samples.map((sample) => sample.ambientScore),
    );
    final smoothness = _averageOrZero(
      samples.map((sample) => sample.curveSmoothness),
    );
    final levelConsistency = _averageOrZero(
      samples.map((sample) => sample.levelConsistency),
    );
    final qualityScore = _qualityScore(
      mode: mode,
      pitchStability: pitchStability,
      sustainScore: sustainScore,
      ambientScore: ambientScore,
      smoothness: smoothness,
      levelConsistency: levelConsistency,
      targetHitRatio: targetHitRatio,
      clippingRatio: clippingRatio,
      voicedRatio: voicedRatio,
    );

    return _MicLabCapture(
      mode: mode,
      sampleCount: samples.length,
      durationMs: samples.last.elapsedMs,
      averageDbfs: averageDbfs,
      minDbfs: dbValues.isEmpty ? -120.0 : dbValues.reduce(math.min),
      maxDbfs: dbValues.isEmpty ? -120.0 : dbValues.reduce(math.max),
      peakDbfs: peakDbfs,
      averageLevel: averageLevel,
      peakLevel: peakLevel,
      averagePitchHz: averagePitch,
      minPitchHz: pitchSamples.isEmpty ? null : pitchSamples.reduce(math.min),
      maxPitchHz: pitchSamples.isEmpty ? null : pitchSamples.reduce(math.max),
      pitchStdDevHz: pitchStdDev,
      pitchStability: pitchStability,
      sustainScore: sustainScore,
      ambientScore: ambientScore,
      curveSmoothness: smoothness,
      levelConsistency: levelConsistency,
      zeroCrossingRate: _averageOrZero(
        samples.map((sample) => sample.zeroCrossingRate),
      ),
      clippingRatio: clippingRatio,
      voicedRatio: voicedRatio,
      dynamicRangeDb: dynamicRangeDb,
      crestFactorDb: crestFactorDb,
      snrDb: snrDb,
      targetHitRatio: targetHitRatio,
      emptyChunkRatio: samples.isEmpty
          ? 0.0
          : samples.where((sample) => sample.rms <= 0.001).length /
                samples.length,
      qualityScore: qualityScore,
    );
  }

  final _MicLabMode mode;
  final int sampleCount;
  final int durationMs;
  final double averageDbfs;
  final double minDbfs;
  final double maxDbfs;
  final double peakDbfs;
  final double averageLevel;
  final double peakLevel;
  final double? averagePitchHz;
  final double? minPitchHz;
  final double? maxPitchHz;
  final double pitchStdDevHz;
  final double pitchStability;
  final double sustainScore;
  final double ambientScore;
  final double curveSmoothness;
  final double levelConsistency;
  final double zeroCrossingRate;
  final double clippingRatio;
  final double voicedRatio;
  final double dynamicRangeDb;
  final double crestFactorDb;
  final double? snrDb;
  final double targetHitRatio;
  final double emptyChunkRatio;
  final double qualityScore;

  double get seconds => durationMs / 1000;

  static double _targetHitRatio(
    _MicLabMode mode,
    _MicModeSpec spec,
    List<_MicFrameSample> samples,
  ) {
    if (samples.isEmpty) {
      return 0;
    }
    if (mode == _MicLabMode.noise) {
      final quietCount = samples.where((sample) => sample.dbfs <= -52).length;
      return quietCount / samples.length;
    }
    final voicedSamples = samples
        .where((sample) => sample.pitchHz != null && sample.dbfs > -62)
        .toList(growable: false);
    if (voicedSamples.isEmpty) {
      return 0;
    }
    final pitchSamples = samples
        .map((sample) => sample.pitchHz)
        .whereType<double>()
        .toList(growable: false);
    final inRange = pitchSamples
        .where(
          (pitch) => pitch >= spec.targetMinHz && pitch <= spec.targetMaxHz,
        )
        .length;
    return inRange / voicedSamples.length;
  }

  static double _qualityScore({
    required _MicLabMode mode,
    required double pitchStability,
    required double sustainScore,
    required double ambientScore,
    required double smoothness,
    required double levelConsistency,
    required double targetHitRatio,
    required double clippingRatio,
    required double voicedRatio,
  }) {
    final clippingSafety = (1 - clippingRatio * 8).clamp(0.0, 1.0).toDouble();
    final base = switch (mode) {
      _MicLabMode.noise =>
        ambientScore * 0.58 + smoothness * 0.24 + clippingSafety * 0.18,
      _MicLabMode.sustain =>
        sustainScore * 0.34 +
            pitchStability * 0.24 +
            levelConsistency * 0.18 +
            smoothness * 0.12 +
            targetHitRatio * 0.08 +
            clippingSafety * 0.04,
      _ =>
        pitchStability * 0.28 +
            targetHitRatio * 0.24 +
            levelConsistency * 0.18 +
            voicedRatio * 0.12 +
            smoothness * 0.10 +
            clippingSafety * 0.08,
    };
    return base.clamp(0.0, 1.0).toDouble();
  }

  static double _averageOrZero(Iterable<double> values) {
    var count = 0;
    var sum = 0.0;
    for (final value in values) {
      count += 1;
      sum += value;
    }
    return count == 0 ? 0 : sum / count;
  }

  static double? _averageOrNull(List<double> values) {
    if (values.isEmpty) {
      return null;
    }
    return _averageOrZero(values);
  }

  static double _stdDev(List<double> values, double mean) {
    if (values.length < 2) {
      return 0;
    }
    final variance =
        values.fold<double>(
          0,
          (sum, value) => sum + math.pow(value - mean, 2).toDouble(),
        ) /
        values.length;
    return math.sqrt(variance);
  }
}

class _AuditoryMicLabCard extends StatefulWidget {
  const _AuditoryMicLabCard();

  @override
  State<_AuditoryMicLabCard> createState() => _AuditoryMicLabCardState();
}

class _AuditoryMicLabCardState extends State<_AuditoryMicLabCard> {
  static const Map<_MicLabMode, _MicModeSpec>
  _modeSpecs = <_MicLabMode, _MicModeSpec>{
    _MicLabMode.low: _MicModeSpec(
      zhLabel: '低音',
      enLabel: 'Low tone',
      jaLabel: '低音',
      deLabel: 'Tiefton',
      frLabel: 'Son grave',
      esLabel: 'Tono grave',
      ruLabel: 'Низкий тон',
      zhDescription: '请用低沉、稳定的声音持续发声，检查低频音高、幅度和稳定性。',
      enDescription:
          'Produce a low, steady hum and check low-frequency pitch, level, and stability.',
      jaDescription: '低く安定した声を出し、低音の高さ、音量、安定性を確認します。',
      deDescription:
          'Erzeuge einen tiefen, gleichmäßigen Ton und prüfe Tonhöhe, Pegel und Stabilität.',
      frDescription:
          'Produisez un son grave et stable pour vérifier hauteur, niveau et stabilité.',
      esDescription:
          'Emite un tono grave y estable para comprobar altura, nivel y estabilidad.',
      ruDescription:
          'Произнесите низкий ровный звук, чтобы проверить высоту, уровень и стабильность.',
      icon: Icons.arrow_downward_rounded,
      targetMinHz: 110,
      targetMaxHz: 240,
    ),
    _MicLabMode.high: _MicModeSpec(
      zhLabel: '高音',
      enLabel: 'High tone',
      jaLabel: '高音',
      deLabel: 'Hochton',
      frLabel: 'Son aigu',
      esLabel: 'Tono agudo',
      ruLabel: 'Высокий тон',
      zhDescription: '请用较高的声音持续发声，观察高频音高与曲线平滑程度。',
      enDescription:
          'Produce a higher tone and observe the high-frequency pitch and curve smoothness.',
      jaDescription: '高めの声を出し、高音の高さと曲線のなめらかさを確認します。',
      deDescription:
          'Erzeuge einen höheren Ton und beobachte Tonhöhe und Kurvenglätte.',
      frDescription:
          'Produisez un son plus aigu et observez la hauteur ainsi que la régularité de la courbe.',
      esDescription:
          'Emite un tono más alto y observa la altura y la suavidad de la curva.',
      ruDescription:
          'Произнесите более высокий звук и оцените высоту и плавность кривой.',
      icon: Icons.arrow_upward_rounded,
      targetMinHz: 360,
      targetMaxHz: 860,
    ),
    _MicLabMode.sustain: _MicModeSpec(
      zhLabel: '持续',
      enLabel: 'Sustain',
      jaLabel: '持続',
      deLabel: 'Halten',
      frLabel: 'Tenue',
      esLabel: 'Sostenido',
      ruLabel: 'Длительность',
      zhDescription: '保持均匀发声 5 秒以上，系统会给出持续性和波动指标。',
      enDescription:
          'Hold a steady sound for 5+ seconds and measure sustain and variation.',
      jaDescription: '5 秒以上声を安定して伸ばし、持続と揺れを確認します。',
      deDescription:
          'Halte einen gleichmäßigen Ton mindestens 5 Sekunden und prüfe Dauer und Schwankung.',
      frDescription:
          'Tenez un son régulier plus de 5 secondes pour mesurer tenue et variation.',
      esDescription:
          'Mantén un sonido estable más de 5 segundos para medir sostenido y variación.',
      ruDescription:
          'Держите ровный звук более 5 секунд, чтобы измерить длительность и колебания.',
      icon: Icons.graphic_eq_rounded,
      targetMinHz: 160,
      targetMaxHz: 420,
    ),
    _MicLabMode.noise: _MicModeSpec(
      zhLabel: '噪声仪',
      enLabel: 'Noise meter',
      jaLabel: '騒音計',
      deLabel: 'Geräuschmesser',
      frLabel: 'Sonomètre',
      esLabel: 'Medidor de ruido',
      ruLabel: 'Шумомер',
      zhDescription: '保持安静，测量环境噪声、峰值和相对分贝。',
      enDescription:
          'Stay quiet to measure ambient noise, peak, and relative dBFS.',
      jaDescription: '静かにして、周囲の音、ピーク、相対 dBFS を測ります。',
      deDescription:
          'Bleibe ruhig und miss Umgebungsgeräusch, Spitzenwert und relative dBFS.',
      frDescription:
          'Restez silencieux pour mesurer le bruit ambiant, le pic et le dBFS relatif.',
      esDescription:
          'Mantén silencio para medir ruido ambiente, pico y dBFS relativo.',
      ruDescription:
          'Сохраняйте тишину, чтобы измерить шум комнаты, пик и относительный dBFS.',
      icon: Icons.hearing_disabled_rounded,
      targetMinHz: 0,
      targetMaxHz: 0,
    ),
  };

  static const int _primarySampleRate = 44100;
  static const int _fallbackSampleRate = 16000;
  static const Duration _firstFrameTimeout = Duration(milliseconds: 1600);
  static const int _digitalSilenceFrameLimit = 10;
  static const double _digitalSilencePeakFloor = 0.00008;

  static const List<_MicRecorderProfile> _recorderProfiles =
      <_MicRecorderProfile>[
        _MicRecorderProfile(
          id: 'default_44100',
          sampleRate: _primarySampleRate,
          config: RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _primarySampleRate,
            numChannels: 1,
            autoGain: true,
            echoCancel: false,
            noiseSuppress: false,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.defaultSource,
              manageBluetooth: true,
            ),
            iosConfig: IosRecordConfig(
              categoryOptions: <IosAudioCategoryOption>[
                IosAudioCategoryOption.allowBluetooth,
                IosAudioCategoryOption.allowBluetoothA2DP,
              ],
            ),
            audioInterruption: AudioInterruptionMode.pause,
            streamBufferSize: 4096,
          ),
        ),
        _MicRecorderProfile(
          id: 'mic_44100',
          sampleRate: _primarySampleRate,
          config: RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _primarySampleRate,
            numChannels: 1,
            autoGain: false,
            echoCancel: false,
            noiseSuppress: false,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.mic,
              manageBluetooth: true,
            ),
            iosConfig: IosRecordConfig(
              categoryOptions: <IosAudioCategoryOption>[
                IosAudioCategoryOption.allowBluetooth,
                IosAudioCategoryOption.allowBluetoothA2DP,
              ],
            ),
            audioInterruption: AudioInterruptionMode.pause,
            streamBufferSize: 4096,
          ),
        ),
        _MicRecorderProfile(
          id: 'voice_recognition_16000',
          sampleRate: _fallbackSampleRate,
          config: RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _fallbackSampleRate,
            numChannels: 1,
            autoGain: true,
            echoCancel: false,
            noiseSuppress: false,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.voiceRecognition,
              manageBluetooth: true,
            ),
            iosConfig: IosRecordConfig(
              categoryOptions: <IosAudioCategoryOption>[
                IosAudioCategoryOption.allowBluetooth,
                IosAudioCategoryOption.allowBluetoothA2DP,
              ],
            ),
            audioInterruption: AudioInterruptionMode.pause,
            streamBufferSize: 2048,
          ),
        ),
        _MicRecorderProfile(
          id: 'unprocessed_44100',
          sampleRate: _primarySampleRate,
          config: RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _primarySampleRate,
            numChannels: 1,
            autoGain: false,
            echoCancel: false,
            noiseSuppress: false,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.unprocessed,
              manageBluetooth: false,
            ),
            iosConfig: IosRecordConfig(
              categoryOptions: <IosAudioCategoryOption>[
                IosAudioCategoryOption.allowBluetooth,
                IosAudioCategoryOption.allowBluetoothA2DP,
              ],
            ),
            audioInterruption: AudioInterruptionMode.pause,
            streamBufferSize: 4096,
          ),
        ),
      ];

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmSubscription;
  StreamSubscription<RecordState>? _stateSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _firstFrameWatchdog;
  final List<double> _levelHistory = List<double>.filled(72, 0);
  final List<double> _pitchWindow = <double>[];
  final List<_MicFrameSample> _samples = <_MicFrameSample>[];
  final Map<_MicLabMode, _MicLabCapture> _captures =
      <_MicLabMode, _MicLabCapture>{};
  final Stopwatch _stopwatch = Stopwatch();

  _MicLabMode _mode = _MicLabMode.low;
  bool _starting = false;
  bool _running = false;
  bool _preferCompatibilityInput = false;
  bool _switchingInput = false;
  String? _error;
  String? _statusCode;
  String? _profileNoticeCode;
  String? _activeRecorderProfileId;
  String? _inputDeviceLabel;
  int _activeSampleRate = _primarySampleRate;
  int _streamRestartCount = 0;
  int _emptyChunkCount = 0;
  int _digitalSilenceFrameCount = 0;
  int _activeProfileSequenceIndex = -1;
  int? _lastPcmFrameMs;
  int? _firstFrameMs;
  bool _hasSeenFrame = false;
  double _level = 0;
  double _peak = 0;
  double _dbfs = -120;
  double? _pitchHz;
  double _pitchStability = 0;
  double _sustainScore = 0;
  double _ambientScore = 0;
  double _lastCurveSmoothness = 0;
  double _levelConsistencyScore = 0;
  double _zeroCrossingRate = 0;
  double _clippingRatio = 0;
  int _frameCount = 0;
  double? _noiseFloorDbfs;

  @override
  void dispose() {
    _firstFrameWatchdog?.cancel();
    unawaited(_pcmSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_amplitudeSubscription?.cancel());
    unawaited(_recorder.dispose());
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _setMode(_MicLabMode mode) {
    if (_mode == mode || _running || _starting) {
      return;
    }
    setState(() {
      _mode = mode;
      _error = null;
      _statusCode = null;
      _profileNoticeCode = null;
      _samples.clear();
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _levelConsistencyScore = 0;
      _zeroCrossingRate = 0;
      _clippingRatio = 0;
      _frameCount = 0;
      _digitalSilenceFrameCount = 0;
      _lastPcmFrameMs = null;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
    });
  }

  Future<void> _startMonitoring() async {
    if (_starting || _running) {
      return;
    }
    setState(() {
      _starting = true;
      _switchingInput = false;
      _error = null;
      _statusCode = 'checking_input';
      _profileNoticeCode = null;
      _samples.clear();
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _frameCount = 0;
      _streamRestartCount = 0;
      _emptyChunkCount = 0;
      _digitalSilenceFrameCount = 0;
      _firstFrameMs = null;
      _lastPcmFrameMs = null;
      _hasSeenFrame = false;
      _activeRecorderProfileId = null;
      _activeProfileSequenceIndex = -1;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _levelConsistencyScore = 0;
      _zeroCrossingRate = 0;
      _clippingRatio = 0;
    });
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        if (!mounted) {
          return;
        }
        setState(() {
          _starting = false;
          _switchingInput = false;
          _error = 'microphone_permission_denied';
          _statusCode = 'permission_denied';
        });
        return;
      }

      final supported = await _recorder.isEncoderSupported(
        AudioEncoder.pcm16bits,
      );
      if (!supported) {
        if (!mounted) {
          return;
        }
        setState(() {
          _starting = false;
          _running = false;
          _switchingInput = false;
          _error = 'pcm_stream_not_supported';
          _statusCode = 'unsupported';
        });
        return;
      }

      await _refreshInputDeviceLabel();
      await _startWithBestRecorderProfile();

      _stateSubscription ??= _recorder.onStateChanged().listen((state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _running = state == RecordState.record || state == RecordState.pause;
        });
      });

      if (!mounted) {
        return;
      }
      _stopwatch
        ..reset()
        ..start();
      setState(() {
        _starting = false;
        _running = true;
        _statusCode = 'waiting_for_signal';
      });
      _armFirstFrameWatchdog();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppLogService.instance.e(
        'toolbox_acoustic_lab',
        'start monitoring failed',
        error: error,
      );
      setState(() {
        _starting = false;
        _running = false;
        _switchingInput = false;
        _error = '$error';
        _statusCode = 'start_failed';
      });
    }
  }

  Future<void> _refreshInputDeviceLabel() async {
    try {
      final devices = await _recorder.listInputDevices();
      if (!mounted) {
        return;
      }
      final label = devices.isEmpty
          ? null
          : devices.first.label.trim().isEmpty
          ? devices.first.id
          : devices.first.label.trim();
      setState(() => _inputDeviceLabel = label);
    } catch (_) {
      if (mounted) {
        setState(() => _inputDeviceLabel = null);
      }
    }
  }

  List<int> _recorderProfileSequence() {
    if (_preferCompatibilityInput) {
      return const <int>[2, 0, 1, 3];
    }
    return const <int>[0, 1, 2, 3];
  }

  bool _hasNextRecorderProfile() {
    final sequence = _recorderProfileSequence();
    return _activeProfileSequenceIndex >= 0 &&
        _activeProfileSequenceIndex + 1 < sequence.length;
  }

  Future<void> _startWithBestRecorderProfile({
    int startSequenceIndex = 0,
  }) async {
    Object? lastError;
    StackTrace? lastStack;
    final sequence = _recorderProfileSequence();
    for (
      var orderIndex = startSequenceIndex;
      orderIndex < sequence.length;
      orderIndex += 1
    ) {
      final profile = _recorderProfiles[sequence[orderIndex]];
      try {
        await _startStreamWithProfile(profile, sequenceIndex: orderIndex);
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStack = stackTrace;
        AppLogService.instance.w(
          'toolbox_acoustic_lab',
          'recorder profile failed',
          data: <String, Object?>{
            'profile': profile.id,
            'sampleRate': profile.sampleRate,
            'error': '$error',
          },
        );
        await _pcmSubscription?.cancel();
        _pcmSubscription = null;
        try {
          await _recorder.stop();
        } catch (_) {}
      }
    }
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStack ?? StackTrace.current);
    }
    throw StateError('No recorder profile is available.');
  }

  Future<void> _startStreamWithProfile(
    _MicRecorderProfile profile, {
    required int sequenceIndex,
  }) async {
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    final stream = await _recorder.startStream(profile.config);
    _pcmSubscription = stream.listen(
      (chunk) => _handlePcmChunk(chunk, sampleRate: profile.sampleRate),
      onError: (Object error, StackTrace stackTrace) {
        AppLogService.instance.e(
          'toolbox_acoustic_lab',
          'pcm stream error',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{'profile': profile.id},
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _error = '$error';
          _running = false;
          _starting = false;
          _switchingInput = false;
          _statusCode = 'stream_error';
        });
      },
      onDone: () {
        if (!mounted) {
          return;
        }
        if (!_hasSeenFrame && _hasNextRecorderProfile()) {
          unawaited(_retryNextRecorderProfile('no_pcm_frames'));
          return;
        }
        setState(() {
          _running = false;
          _starting = false;
          _switchingInput = false;
          _statusCode = _hasSeenFrame ? 'stream_done' : 'no_pcm_frames';
        });
      },
      cancelOnError: false,
    );
    await _subscribeAmplitudeUpdates();
    _activeSampleRate = profile.sampleRate;
    _activeRecorderProfileId = profile.id;
    _activeProfileSequenceIndex = sequenceIndex;
    _digitalSilenceFrameCount = 0;
    _lastPcmFrameMs = null;
    _streamRestartCount += 1;
  }

  Future<void> _subscribeAmplitudeUpdates() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 220))
        .listen(
          _handleAmplitudeSample,
          onError: (Object error, StackTrace stackTrace) {
            AppLogService.instance.w(
              'toolbox_acoustic_lab',
              'amplitude stream failed',
              data: <String, Object?>{'error': '$error'},
            );
          },
        );
  }

  Future<void> _retryNextRecorderProfile(String reason) async {
    if (_switchingInput || !_hasNextRecorderProfile()) {
      if (!_hasNextRecorderProfile()) {
        await _failRecorderProfiles(reason, exhausted: true);
      }
      return;
    }
    final nextSequenceIndex = _activeProfileSequenceIndex + 1;
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
    if (mounted) {
      setState(() {
        _switchingInput = true;
        _starting = true;
        _running = false;
        _error = null;
        _statusCode = 'switching_input';
        _profileNoticeCode = reason;
      });
    }
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _samples.clear();
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _frameCount = 0;
      _emptyChunkCount = 0;
      _digitalSilenceFrameCount = 0;
      _firstFrameMs = null;
      _lastPcmFrameMs = null;
      _hasSeenFrame = false;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _levelConsistencyScore = 0;
      _zeroCrossingRate = 0;
      _clippingRatio = 0;
    });
    try {
      await _startWithBestRecorderProfile(
        startSequenceIndex: nextSequenceIndex,
      );
      if (!mounted) {
        return;
      }
      _stopwatch
        ..reset()
        ..start();
      setState(() {
        _switchingInput = false;
        _starting = false;
        _running = true;
        _statusCode = 'waiting_for_signal';
      });
      _armFirstFrameWatchdog();
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'toolbox_acoustic_lab',
        'recorder retry failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'reason': reason},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _switchingInput = false;
        _starting = false;
        _running = false;
        _error = '$error';
        _statusCode = 'start_failed';
      });
    }
  }

  Future<void> _failRecorderProfiles(
    String reason, {
    bool exhausted = false,
  }) async {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _switchingInput = false;
      _starting = false;
      _running = false;
      _profileNoticeCode = exhausted ? 'exhausted_$reason' : reason;
      _statusCode = 'no_usable_input';
      _error = reason == 'digital_silence' ? 'silent_input' : 'no_pcm_frames';
    });
  }

  void _armFirstFrameWatchdog() {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = Timer(_firstFrameTimeout, () {
      if (!mounted || !_running || _hasSeenFrame) {
        return;
      }
      if (_hasNextRecorderProfile()) {
        unawaited(_retryNextRecorderProfile('no_pcm_frames'));
        return;
      }
      setState(() {
        _statusCode = 'no_pcm_frames';
        _error = 'no_pcm_frames';
      });
      AppLogService.instance.w(
        'toolbox_acoustic_lab',
        'no pcm frame after start',
        data: <String, Object?>{
          'profile': _activeRecorderProfileId,
          'sampleRate': _activeSampleRate,
        },
      );
    });
  }

  Future<void> _stopMonitoring() async {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _running = false;
      _starting = false;
      _switchingInput = false;
      _statusCode = _samples.isEmpty ? 'stopped_without_samples' : 'stopped';
    });
  }

  Future<void> _finishCapture() async {
    if (_running || _starting) {
      await _stopMonitoring();
    }
    if (_samples.length < 3) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'capture_too_short');
      return;
    }
    final spec = _modeSpecs[_mode]!;
    final capture = _MicLabCapture.fromSamples(
      mode: _mode,
      spec: spec,
      samples: List<_MicFrameSample>.of(_samples),
      noiseFloorDbfs: _noiseFloorDbfs,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _captures[_mode] = capture;
      if (_mode == _MicLabMode.noise) {
        _noiseFloorDbfs = capture.averageDbfs;
      }
      _error = null;
      _statusCode = 'sample_added';
    });
  }

  void _reset() {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
    setState(() {
      _switchingInput = false;
      _error = null;
      _statusCode = null;
      _profileNoticeCode = null;
      _samples.clear();
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _levelConsistencyScore = 0;
      _zeroCrossingRate = 0;
      _clippingRatio = 0;
      _frameCount = 0;
      _emptyChunkCount = 0;
      _digitalSilenceFrameCount = 0;
      _firstFrameMs = null;
      _lastPcmFrameMs = null;
      _hasSeenFrame = false;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
    });
  }

  Future<void> _resetCurrentRun() async {
    if (_running || _starting || _switchingInput) {
      await _stopMonitoring();
    }
    if (!mounted) {
      return;
    }
    _reset();
  }

  void _handlePcmChunk(Uint8List chunk, {required int sampleRate}) {
    final byteData = ByteData.sublistView(chunk);
    final sampleCount = byteData.lengthInBytes ~/ 2;
    if (sampleCount < 256) {
      _emptyChunkCount += 1;
      return;
    }
    if (!_hasSeenFrame) {
      _firstFrameWatchdog?.cancel();
      _firstFrameWatchdog = null;
      _hasSeenFrame = true;
      _firstFrameMs = _stopwatch.elapsedMilliseconds;
      if (_error == 'no_pcm_frames') {
        _error = null;
      }
    }

    var peak = 0.0;
    var sumSquares = 0.0;
    var zeroCrossings = 0;
    var clippedSamples = 0;
    var previousValue = 0.0;
    final samples = List<double>.filled(sampleCount, 0);
    for (var i = 0; i < sampleCount; i += 1) {
      final value = byteData.getInt16(i * 2, Endian.little) / 32768.0;
      samples[i] = value;
      final absValue = value.abs();
      if (absValue > peak) {
        peak = absValue;
      }
      if (i > 0 &&
          ((previousValue < 0 && value >= 0) ||
              (previousValue > 0 && value <= 0))) {
        zeroCrossings += 1;
      }
      if (absValue >= 0.985) {
        clippedSamples += 1;
      }
      previousValue = value;
      sumSquares += value * value;
    }

    final rms = math.sqrt(sumSquares / sampleCount);
    final dbfs = rms <= 1e-6
        ? -120.0
        : (20 * math.log(rms) / math.ln10).clamp(-120.0, 0.0).toDouble();
    if (peak <= _digitalSilencePeakFloor && rms <= _digitalSilencePeakFloor) {
      _digitalSilenceFrameCount += 1;
      if (_digitalSilenceFrameCount >= _digitalSilenceFrameLimit &&
          _hasNextRecorderProfile()) {
        unawaited(_retryNextRecorderProfile('digital_silence'));
        return;
      }
    } else {
      _digitalSilenceFrameCount = 0;
    }
    final detectedPitch = _detectPitch(samples, sampleRate);
    _pushLevelHistory(rms);
    if (detectedPitch != null) {
      _pitchWindow.add(detectedPitch);
      if (_pitchWindow.length > 10) {
        _pitchWindow.removeAt(0);
      }
    } else if (_pitchWindow.length > 6) {
      _pitchWindow.removeAt(0);
    }

    final smoothPitch = _smoothedPitch();
    final stability = _pitchStabilityScore(smoothPitch);
    final sustain = _sustainScoreForMode(rms, smoothPitch);
    final ambientScore = _ambientNoiseScore(dbfs);
    final curveSmoothness = _curveSmoothness();
    final levelConsistency = _levelConsistency();
    final zeroCrossingRate = zeroCrossings / math.max(1, sampleCount - 1);
    final clippingRatio = clippedSamples / sampleCount;
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    _lastPcmFrameMs = elapsedMs;
    final frameSample = _MicFrameSample(
      elapsedMs: elapsedMs,
      rms: rms.clamp(0.0, 1.0).toDouble(),
      peak: peak.clamp(0.0, 1.0).toDouble(),
      dbfs: dbfs,
      zeroCrossingRate: zeroCrossingRate,
      clippingRatio: clippingRatio,
      pitchStability: stability,
      sustainScore: sustain,
      ambientScore: ambientScore,
      curveSmoothness: curveSmoothness,
      levelConsistency: levelConsistency,
      pitchHz: smoothPitch,
    );
    _samples.add(frameSample);
    if (_samples.length > 360) {
      _samples.removeRange(0, _samples.length - 360);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _frameCount += 1;
      _level = rms.clamp(0.0, 1.0).toDouble();
      _peak = peak.clamp(0.0, 1.0).toDouble();
      _dbfs = dbfs;
      _pitchHz = smoothPitch;
      _pitchStability = stability;
      _sustainScore = sustain;
      _ambientScore = ambientScore;
      _lastCurveSmoothness = curveSmoothness;
      _levelConsistencyScore = levelConsistency;
      _zeroCrossingRate = zeroCrossingRate;
      _clippingRatio = clippingRatio;
      _statusCode = 'sampling';
      if (_error == 'no_pcm_frames') {
        _error = null;
      }
    });
  }

  void _handleAmplitudeSample(Amplitude amplitude) {
    if (!mounted || (!_running && !_starting)) {
      return;
    }
    final currentDbfs = amplitude.current;
    if (!currentDbfs.isFinite || currentDbfs <= -155) {
      return;
    }
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final lastPcmFrameMs = _lastPcmFrameMs;
    if (lastPcmFrameMs != null && elapsedMs - lastPcmFrameMs < 650) {
      return;
    }
    final dbfs = currentDbfs.clamp(-120.0, 0.0).toDouble();
    final level = math.pow(10, dbfs / 20).clamp(0.0, 1.0).toDouble();
    if (level <= _digitalSilencePeakFloor) {
      return;
    }
    if (!_hasSeenFrame) {
      _firstFrameWatchdog?.cancel();
      _firstFrameWatchdog = null;
      _hasSeenFrame = true;
      _firstFrameMs = elapsedMs;
    }
    _pushLevelHistory(level);
    final ambientScore = _ambientNoiseScore(dbfs);
    final curveSmoothness = _curveSmoothness();
    final levelConsistency = _levelConsistency();
    final sustain = _sustainScoreForMode(level, null);
    final frameSample = _MicFrameSample(
      elapsedMs: elapsedMs,
      rms: level,
      peak: level,
      dbfs: dbfs,
      zeroCrossingRate: 0,
      clippingRatio: dbfs >= -1.0 ? 0.01 : 0,
      pitchStability: 0,
      sustainScore: sustain,
      ambientScore: ambientScore,
      curveSmoothness: curveSmoothness,
      levelConsistency: levelConsistency,
    );
    _samples.add(frameSample);
    if (_samples.length > 360) {
      _samples.removeRange(0, _samples.length - 360);
    }
    setState(() {
      _frameCount += 1;
      _level = level;
      _peak = math.max(_peak * 0.96, level).clamp(0.0, 1.0).toDouble();
      _dbfs = dbfs;
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = sustain;
      _ambientScore = ambientScore;
      _lastCurveSmoothness = curveSmoothness;
      _levelConsistencyScore = levelConsistency;
      _zeroCrossingRate = 0;
      _clippingRatio = dbfs >= -1.0 ? 0.01 : 0;
      _statusCode = 'sampling';
      if (_error == 'no_pcm_frames' || _error == 'silent_input') {
        _error = null;
      }
    });
  }

  void _pushLevelHistory(double level) {
    _levelHistory.removeAt(0);
    _levelHistory.add(level.clamp(0.0, 1.0).toDouble());
  }

  double? _smoothedPitch() {
    if (_pitchWindow.isEmpty) {
      return null;
    }
    final sorted = List<double>.of(_pitchWindow)..sort();
    return sorted[sorted.length ~/ 2];
  }

  double _pitchStabilityScore(double? pitch) {
    if (pitch == null || _pitchWindow.length < 3) {
      return 0;
    }
    final mean =
        _pitchWindow.fold<double>(0, (sum, value) => sum + value) /
        _pitchWindow.length;
    final variance =
        _pitchWindow.fold<double>(
          0,
          (sum, value) => sum + math.pow(value - mean, 2).toDouble(),
        ) /
        _pitchWindow.length;
    final deviation = math.sqrt(variance);
    final normalized = 1 - (deviation / math.max(1.0, mean * 0.08));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  double _sustainScoreForMode(double level, double? pitch) {
    if (_mode == _MicLabMode.noise) {
      return 0;
    }
    final spec = _modeSpecs[_mode]!;
    final targetCenter = (spec.targetMinHz + spec.targetMaxHz) / 2;
    final targetSpan = math.max(1.0, spec.targetMaxHz - spec.targetMinHz);
    final pitchScore = pitch == null
        ? 0.0
        : (1 - ((pitch - targetCenter).abs() / (targetSpan * 0.75)))
              .clamp(0.0, 1.0)
              .toDouble();
    final levelConsistency = _levelConsistency();
    return (pitchScore * 0.6 + levelConsistency * 0.4)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _ambientNoiseScore(double dbfs) {
    final quiet = dbfs <= -52;
    if (quiet) {
      return 1.0;
    }
    final normalized = 1 - (((dbfs + 52) / 38).clamp(0.0, 1.0));
    return normalized.toDouble();
  }

  double _levelConsistency() {
    final values = _levelHistory.where((value) => value > 0.001).toList();
    if (values.length < 3) {
      return 0;
    }
    final mean =
        values.fold<double>(0, (sum, value) => sum + value) / values.length;
    final meanDelta =
        values
            .map((value) => (value - mean).abs())
            .fold<double>(0, (sum, value) => sum + value) /
        values.length;
    final normalized = 1 - (meanDelta / math.max(0.08, mean * 0.9));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  double _curveSmoothness() {
    final values = _levelHistory.where((value) => value > 0.001).toList();
    if (values.length < 4) {
      return 0;
    }
    var delta = 0.0;
    for (var i = 1; i < values.length; i += 1) {
      delta += (values[i] - values[i - 1]).abs();
    }
    final normalized = 1 - (delta / math.max(0.2, values.length * 0.18));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  String _noiseLabel(AppI18n i18n) {
    if (_dbfs <= -52) {
      return pickUiText(
        i18n,
        zh: '安静',
        en: 'Quiet',
        ja: 'Quiet',
        de: 'Quiet',
        fr: 'Du calme',
        es: 'Silencio.',
        ru: 'Тихо',
      );
    }
    if (_dbfs <= -38) {
      return pickUiText(
        i18n,
        zh: '中等',
        en: 'Moderate',
        ja: 'Moderate',
        de: 'Moderate',
        fr: 'Modéré',
        es: 'Moderado',
        ru: 'умеренный',
      );
    }
    return pickUiText(
      i18n,
      zh: '偏吵',
      en: 'Noisy',
      ja: 'Noisy',
      de: 'Noisy',
      fr: 'Bruit',
      es: 'Noisy',
      ru: 'шумный',
    );
  }

  String _captureQualityLabel(AppI18n i18n, double score) {
    if (score >= 0.82) {
      return pickUiText(
        i18n,
        zh: '优秀',
        en: 'Excellent',
        ja: 'Excellent',
        de: 'Excellent',
        fr: 'Excellent',
        es: 'Excelente',
        ru: 'Отлично',
      );
    }
    if (score >= 0.64) {
      return pickUiText(
        i18n,
        zh: '良好',
        en: 'Good',
        ja: 'Good',
        de: 'Good',
        fr: 'Bonne',
        es: 'Bien.',
        ru: 'Хорошо.',
      );
    }
    if (score >= 0.42) {
      return pickUiText(
        i18n,
        zh: '可参考',
        en: 'Usable',
        ja: 'Usable',
        de: 'Usable',
        fr: 'Utilisable',
        es: 'Usable',
        ru: 'удобный',
      );
    }
    return pickUiText(
      i18n,
      zh: '需重测',
      en: 'Retest',
      ja: 'Retest',
      de: 'Retest',
      fr: 'Répétition',
      es: 'Retest',
      ru: 'Протестовать',
    );
  }

  String _captureReadiness(AppI18n i18n) {
    if (_switchingInput || _statusCode == 'switching_input') {
      return pickUiText(
        i18n,
        zh: '正在切换到更兼容的麦克风输入，请继续保持发声。',
        en: 'Switching to a more compatible microphone input. Keep making sound.',
        ja: 'より互換性の高いマイク入力へ切り替えています。音を出し続けてください。',
        de: 'Wechsle zu einem kompatibleren Mikrofoneingang. Halte den Ton weiter.',
        fr: 'Passage à une entrée micro plus compatible. Continuez le son.',
        es: 'Cambiando a una entrada de micrófono más compatible. Mantén el sonido.',
        ru: 'Переключаемся на более совместимый микрофон. Продолжайте звук.',
      );
    }
    if (_starting) {
      return pickUiText(
        i18n,
        zh: '正在检查麦克风和 PCM 实时流，请稍候。',
        en: 'Checking the microphone and live PCM stream...',
        ja: 'マイクとライブ PCM ストリームを確認しています...',
        de: 'Mikrofon und Live-PCM-Stream werden geprüft...',
        fr: 'Vérification du micro et du flux PCM en direct...',
        es: 'Comprobando el micrófono y el flujo PCM en vivo...',
        ru: 'Проверяем микрофон и поток PCM...',
      );
    }
    if (_running) {
      if (!_hasSeenFrame) {
        return pickUiText(
          i18n,
          zh: '录音已启动，正在等待第一帧声音数据。',
          en: 'Recording has started; waiting for the first audio frame.',
          ja: '録音は開始済みです。最初の音声フレームを待っています。',
          de: 'Die Aufnahme läuft; warte auf den ersten Audio-Frame.',
          fr: 'L’enregistrement a démarré ; attente de la première trame audio.',
          es: 'La grabación comenzó; esperando el primer fotograma de audio.',
          ru: 'Запись началась; ожидаем первый аудиофрейм.',
        );
      }
      if (_stopwatch.elapsedMilliseconds < 2800) {
        return pickUiText(
          i18n,
          zh: '继续采样，建议至少 3 秒。',
          en: 'Keep sampling; at least 3 seconds is recommended.',
          ja: 'Keep sampling; at least 3 seconds is recommended.',
          de: 'Keep sampling; at least 3 seconds is recommended.',
          fr: 'Conserver l\'échantillonnage; il est recommandé de faire au moins 3 secondes.',
          es: 'Mantenga el muestreo; al menos 3 segundos se recomienda.',
          ru: 'Держите выборку; рекомендуется не менее 3 секунд.',
        );
      }
      return pickUiText(
        i18n,
        zh: '样本已经够用，可以停止并加入报告。',
        en: 'The sample is ready; stop and add it to the report.',
        ja: 'The sample is ready; stop and add it to the report.',
        de: 'The sample is ready; stop and add it to the report.',
        fr: 'L\'échantillon est prêt; arrêtez et ajoutez-le au rapport.',
        es: 'La muestra está lista; pare y agréguela al informe.',
        ru: 'Образец готов, остановитесь и добавьте его в отчет.',
      );
    }
    if (_statusCode == 'sample_added') {
      return pickUiText(
        i18n,
        zh: '样本已写入报告，可以继续切换到下一个模式。',
        en: 'Sample saved to the report. You can move to the next mode.',
        ja: 'サンプルをレポートに保存しました。次のモードへ進めます。',
        de: 'Probe im Bericht gespeichert. Du kannst zum nächsten Modus wechseln.',
        fr: 'Échantillon ajouté au rapport. Vous pouvez passer au mode suivant.',
        es: 'Muestra guardada en el informe. Puedes pasar al siguiente modo.',
        ru: 'Образец сохранен в отчет. Можно перейти к следующему режиму.',
      );
    }
    final capture = _captures[_mode];
    if (capture != null) {
      return pickUiText(
        i18n,
        zh: '这个模式已有样本，再测一次会替换当前结果。',
        en: 'This mode already has a sample. A new run will replace it.',
        ja: 'This mode already has a sample. A new run will replace it.',
        de: 'This mode already has a sample. A new run will replace it.',
        fr: 'Ce mode a déjà un échantillon. Une nouvelle course le remplacera.',
        es: 'Este modo ya tiene una muestra. Una nueva carrera lo reemplazará.',
        ru: 'Этот режим уже имеет образец. Новый проект заменит его.',
      );
    }
    return pickUiText(
      i18n,
      zh: '选择模式后开始采样，结束时加入声学报告。',
      en: 'Choose a mode, start sampling, then add it to the acoustic report.',
      ja: 'モードを選択してサンプリングを開始し、音響レポートに追加します。',
      de: 'Choose a mode, start sampling, then add it to the acoustic report.',
      fr: 'Choisissez un mode, commencez l\'échantillonnage, puis ajoutez-le au rapport acoustique.',
      es: 'Elija un modo, inicie el muestreo, luego agréguelo al informe acústico.',
      ru: 'Выберите режим, начните отбор проб, затем добавьте его в акустический отчет.',
    );
  }

  String _protocolText(AppI18n i18n) {
    return switch (_mode) {
      _MicLabMode.low => pickUiText(
        i18n,
        zh: '低音：距离麦克风 20-30 cm，稳定发声 3-6 秒，尽量不要喷麦或碰到设备。',
        en: 'Low tone: stay 20-30 cm from the mic, hum steadily for 3-6 seconds, and avoid plosives or touching the device.',
        ja: 'Low tone: stay 20-30 cm from the mic, hum steadily for 3-6 seconds, and avoid plosives or touching the device.',
        de: 'Low tone: stay 20-30 cm from the mic, hum steadily for 3-6 seconds, and avoid plosives or touching the device.',
        fr: 'Ton bas : rester de 20-30 cm du micro, humer régulièrement pendant 3-6 secondes, et éviter les plosifs ou toucher l\'appareil.',
        es: 'Tono bajo: Mantener 20-30 cm desde el micrófono, hum firmemente durante 3-6 segundos, y evitar los plosivos o tocar el dispositivo.',
        ru: 'Низкий тон: держитесь на расстоянии 20-30 см от микрофона, постоянно жужжите в течение 3-6 секунд и избегайте ударов или прикосновений к устройству.',
      ),
      _MicLabMode.high => pickUiText(
        i18n,
        zh: '高音：用舒服的高音持续 3-6 秒，不用喊，重点看音高是否稳定。',
        en: 'High tone: hold a comfortable high tone for 3-6 seconds without shouting, and watch pitch stability.',
        ja: 'High tone: hold a comfortable high tone for 3-6 seconds without shouting, and watch pitch stability.',
        de: 'High tone: hold a comfortable high tone for 3-6 seconds without shouting, and watch pitch stability.',
        fr: 'Haut ton : tenir un haut ton confortable pendant 3-6 secondes sans crier, et regarder la stabilité du pas.',
        es: 'Tono alto: mantener un tono alto cómodo durante 3-6 segundos sin gritar, y ver la estabilidad del campo.',
        ru: 'Высокий тон: держите комфортный высокий тон в течение 3-6 секунд без крика и следите за стабильностью шага.',
      ),
      _MicLabMode.sustain => pickUiText(
        i18n,
        zh: '持续：任选一个舒服的音高保持 5 秒以上，报告会看响度、音高和曲线是否稳定。',
        en: 'Sustain: hold a comfortable pitch for 5+ seconds. The report checks whether level, pitch, and curve stay steady.',
        ja: 'Sustain: hold a comfortable pitch for 5+ seconds. The report checks whether level, pitch, and curve stay steady.',
        de: 'Sustain: hold a comfortable pitch for 5+ seconds. The report checks whether level, pitch, and curve stay steady.',
        fr: 'Sustain: tenir un pas confortable pendant 5+ secondes. Le rapport vérifie si le niveau, le tangage et la courbe restent stables.',
        es: 'Sostenga: mantenga un campo cómodo durante 5+ segundos. El informe comprueba si el nivel, el campo y la curva permanecen estables.',
        ru: 'Устойчиво: держите удобный шаг в течение 5+ секунд. Отчет проверяет, остаются ли уровень, шаг и кривая устойчивыми.',
      ),
      _MicLabMode.noise => pickUiText(
        i18n,
        zh: '噪声：保持房间安静 5 秒，先记录环境底噪，后续样本会用它估算信噪比。',
        en: 'Noise: keep the room quiet for 5 seconds to capture the room floor. Later samples use it to estimate SNR.',
        ja: 'Noise: keep the room quiet for 5 seconds to capture the room floor. Later samples use it to estimate SNR.',
        de: 'Noise: keep the room quiet for 5 seconds to capture the room floor. Later samples use it to estimate SNR.',
        fr: 'Bruit: garder la chambre tranquille pendant 5 secondes pour capturer le plancher de la chambre. Des échantillons ultérieurs l\'utilisent pour estimer le RNS.',
        es: 'Noise: mantener la habitación tranquila durante 5 segundos para capturar el piso de la habitación. Las muestras posteriores lo usan para estimar SNR.',
        ru: 'Шум: держите комнату в тишине в течение 5 секунд, чтобы захватить пол комнаты. Более поздние образцы используют его для оценки SNR.',
      ),
    };
  }

  String _statusLabel(AppI18n i18n) {
    if (_switchingInput || _statusCode == 'switching_input') {
      return pickUiText(
        i18n,
        zh: '切换输入',
        en: 'Switching input',
        ja: '入力切替中',
        de: 'Eingang wechseln',
        fr: 'Changement entrée',
        es: 'Cambiando entrada',
        ru: 'Смена входа',
      );
    }
    if (_starting) {
      return pickUiText(
        i18n,
        zh: '启动中',
        en: 'Starting',
        ja: '起動中',
        de: 'Startet',
        fr: 'Démarrage',
        es: 'Iniciando',
        ru: 'Запуск',
      );
    }
    if (_running && !_hasSeenFrame) {
      return pickUiText(
        i18n,
        zh: '等待声音',
        en: 'Waiting for audio',
        ja: '音声待機中',
        de: 'Warte auf Audio',
        fr: 'Attente audio',
        es: 'Esperando audio',
        ru: 'Ожидание звука',
      );
    }
    if (_running) {
      return pickUiText(
        i18n,
        zh: '采样中',
        en: 'Sampling',
        ja: 'サンプリング中',
        de: 'Messung läuft',
        fr: 'Mesure en cours',
        es: 'Muestreando',
        ru: 'Идет замер',
      );
    }
    if (_error != null) {
      return pickUiText(
        i18n,
        zh: '需要处理',
        en: 'Needs attention',
        ja: '確認が必要',
        de: 'Prüfen',
        fr: 'À vérifier',
        es: 'Revisar',
        ru: 'Требует внимания',
      );
    }
    if (_statusCode == 'sample_added') {
      return pickUiText(
        i18n,
        zh: '已写入',
        en: 'Saved',
        ja: '保存済み',
        de: 'Gespeichert',
        fr: 'Enregistré',
        es: 'Guardado',
        ru: 'Сохранено',
      );
    }
    return pickUiText(
      i18n,
      zh: '就绪',
      en: 'Ready',
      ja: '準備完了',
      de: 'Bereit',
      fr: 'Prêt',
      es: 'Listo',
      ru: 'Готово',
    );
  }

  String _profileLabel(AppI18n i18n) {
    final profile = _activeRecorderProfileId;
    if (profile == null) {
      return pickUiText(
        i18n,
        zh: '未启动',
        en: 'Not started',
        ja: '未開始',
        de: 'Nicht gestartet',
        fr: 'Non démarré',
        es: 'Sin iniciar',
        ru: 'Не запущено',
      );
    }
    if (profile.contains('unprocessed')) {
      return pickUiText(
        i18n,
        zh: '原始麦克风',
        en: 'Raw mic',
        ja: 'Raw mic',
        de: 'Raw mic',
        fr: 'Micro brut',
        es: 'Micrófono directo',
        ru: 'Чистый микрофон',
      );
    }
    if (profile.contains('default')) {
      return pickUiText(
        i18n,
        zh: '自动输入',
        en: 'Auto input',
        ja: '自動入力',
        de: 'Auto-Eingang',
        fr: 'Entrée auto',
        es: 'Entrada auto',
        ru: 'Авто вход',
      );
    }
    if (profile.contains('voice_recognition')) {
      return pickUiText(
        i18n,
        zh: '兼容模式',
        en: 'Compat mode',
        ja: '互換モード',
        de: 'Kompatibel',
        fr: 'Mode compatible',
        es: 'Modo compatible',
        ru: 'Совместимый режим',
      );
    }
    return pickUiText(
      i18n,
      zh: '标准麦克风',
      en: 'Standard mic',
      ja: '標準マイク',
      de: 'Standardmikro',
      fr: 'Micro standard',
      es: 'Micrófono estándar',
      ru: 'Стандартный микрофон',
    );
  }

  String _inputLabel(AppI18n i18n) {
    final label = _inputDeviceLabel;
    if (label != null && label.trim().isNotEmpty) {
      return label;
    }
    return pickUiText(
      i18n,
      zh: '默认输入',
      en: 'Default input',
      ja: '既定入力',
      de: 'Standardeingang',
      fr: 'Entrée par défaut',
      es: 'Entrada predeterminada',
      ru: 'Вход по умолчанию',
    );
  }

  String _formatFirstFrame(AppI18n i18n) {
    final firstFrameMs = _firstFrameMs;
    if (firstFrameMs == null) {
      return _hasSeenFrame
          ? '< 1 ms'
          : pickUiText(
              i18n,
              zh: '等待中',
              en: 'Waiting',
              ja: '待機中',
              de: 'Wartet',
              fr: 'Attente',
              es: 'Esperando',
              ru: 'Ожидание',
            );
    }
    return '$firstFrameMs ms';
  }

  String _errorMessage(AppI18n i18n) {
    final error = _error;
    if (error == 'microphone_permission_denied') {
      return pickUiText(
        i18n,
        zh: '麦克风权限被拒绝，请在系统设置中允许本应用使用麦克风后再开始。',
        en: 'Microphone permission was denied. Allow microphone access in system settings and try again.',
        ja: 'マイク権限が拒否されました。システム設定でマイクを許可してから再試行してください。',
        de: 'Mikrofonzugriff wurde verweigert. Erlaube den Zugriff in den Systemeinstellungen und versuche es erneut.',
        fr: 'L’autorisation du micro a été refusée. Autorisez le micro dans les réglages système puis réessayez.',
        es: 'Se denegó el permiso del micrófono. Permite el acceso en los ajustes del sistema e inténtalo de nuevo.',
        ru: 'Доступ к микрофону отклонен. Разрешите микрофон в настройках системы и повторите попытку.',
      );
    }
    if (error == 'pcm_stream_not_supported') {
      return pickUiText(
        i18n,
        zh: '当前平台不支持 PCM 实时流，无法进行声学频谱与音高分析。',
        en: 'This platform does not support live PCM streaming, so acoustic and pitch analysis cannot run.',
        ja: 'この環境ではライブ PCM ストリームに対応していないため、音響・音高解析を実行できません。',
        de: 'Diese Plattform unterstützt kein Live-PCM-Streaming; Akustik- und Tonhöhenanalyse können nicht laufen.',
        fr: 'Cette plateforme ne prend pas en charge le flux PCM en direct ; l’analyse acoustique ne peut pas fonctionner.',
        es: 'Esta plataforma no admite flujo PCM en vivo; no se puede analizar acústica ni tono.',
        ru: 'Платформа не поддерживает поток PCM, поэтому анализ акустики и высоты недоступен.',
      );
    }
    if (error == 'no_pcm_frames') {
      return pickUiText(
        i18n,
        zh: '录音已启动但没有收到声音帧。请确认系统麦克风权限、隐私开关和外接耳机麦克风，然后重新开始。',
        en: 'Recording started, but no audio frames arrived. Check microphone permission, privacy switches, and headset mic routing, then start again.',
        ja: '録音は開始しましたが音声フレームを受信できません。権限、プライバシー設定、外部マイク経路を確認して再開してください。',
        de: 'Die Aufnahme startete, aber es kamen keine Audio-Frames an. Prüfe Berechtigung, Datenschutzschalter und Headset-Mikrofon und starte neu.',
        fr: 'L’enregistrement a démarré mais aucune trame audio n’est arrivée. Vérifiez l’autorisation, les réglages de confidentialité et le micro du casque, puis relancez.',
        es: 'La grabación comenzó, pero no llegaron fotogramas de audio. Revisa permisos, privacidad y micrófono del auricular, y vuelve a iniciar.',
        ru: 'Запись началась, но аудиофреймы не поступают. Проверьте разрешения, приватность и микрофон гарнитуры, затем перезапустите.',
      );
    }
    if (error == 'silent_input') {
      return pickUiText(
        i18n,
        zh: '麦克风流只返回数字静音。已尝试可用输入源，请检查系统麦克风、蓝牙耳机路由、通话/录屏占用后再试。',
        en: 'The microphone stream only returned digital silence. Available inputs were tried; check system mic access, Bluetooth routing, calls, or screen recording and try again.',
        ja: 'マイク入力がデジタル無音だけを返しました。権限、Bluetooth 経路、通話や画面収録を確認して再試行してください。',
        de: 'Der Mikrofonstream liefert nur digitale Stille. Prüfe Mikrofonzugriff, Bluetooth-Routing, Anruf oder Bildschirmaufnahme und versuche es erneut.',
        fr: 'Le flux micro ne renvoie que du silence numérique. Vérifiez l’accès micro, le Bluetooth, un appel ou l’enregistrement d’écran, puis réessayez.',
        es: 'El flujo del micrófono solo devuelve silencio digital. Revisa permisos, Bluetooth, llamadas o grabación de pantalla y prueba de nuevo.',
        ru: 'Поток микрофона возвращает только цифровую тишину. Проверьте доступ, Bluetooth, звонки или запись экрана и повторите.',
      );
    }
    if (error == 'capture_too_short') {
      return pickUiText(
        i18n,
        zh: '样本过短，请至少采样 3 秒后加入报告。',
        en: 'The sample is too short. Capture at least 3 seconds before adding it to the report.',
        ja: 'サンプルが短すぎます。少なくとも 3 秒測定してからレポートに追加してください。',
        de: 'Die Probe ist zu kurz. Miss mindestens 3 Sekunden, bevor du sie dem Bericht hinzufügst.',
        fr: 'L’échantillon est trop court. Mesurez au moins 3 secondes avant de l’ajouter au rapport.',
        es: 'La muestra es demasiado corta. Captura al menos 3 segundos antes de añadirla al informe.',
        ru: 'Образец слишком короткий. Записывайте не менее 3 секунд перед добавлением в отчет.',
      );
    }
    return error ?? '';
  }

  String? _profileNoticeMessage(AppI18n i18n) {
    final code = _profileNoticeCode;
    if (code == null) {
      return null;
    }
    if (code == 'exhausted_digital_silence') {
      return pickUiText(
        i18n,
        zh: '已试完可用输入源，但仍只收到静音。请检查系统麦克风权限、蓝牙路由、通话或录屏占用。',
        en: 'All available inputs were tried, but only silence came through. Check microphone access, Bluetooth routing, calls, or screen recording.',
        ja: '利用可能な入力をすべて試しましたが、無音しか返りません。権限、Bluetooth 経路、通話や画面収録を確認してください。',
        de: 'Alle Eingänge wurden versucht, aber es kam nur Stille an. Prüfe Zugriff, Bluetooth-Routing, Anruf oder Bildschirmaufnahme.',
        fr: 'Tous les entrées disponibles ont été essayées, mais seul le silence revient. Vérifiez le micro, le Bluetooth, un appel ou l’enregistrement d’écran.',
        es: 'Se probaron todas las entradas disponibles, pero solo llegó silencio. Revisa micrófono, Bluetooth, llamadas o grabación de pantalla.',
        ru: 'Испробованы все входы, но пришла только тишина. Проверьте доступ, Bluetooth, звонки или запись экрана.',
      );
    }
    if (code == 'exhausted_no_pcm_frames') {
      return pickUiText(
        i18n,
        zh: '已试完可用输入源，但仍没有收到声音帧。请检查麦克风权限、系统隐私开关和设备路由。',
        en: 'All available inputs were tried, but no audio frames arrived. Check microphone permission, privacy switches, and device routing.',
        ja: '利用可能な入力をすべて試しましたが、音声フレームが届きません。権限、プライバシー設定、デバイス経路を確認してください。',
        de: 'Alle Eingänge wurden versucht, aber es kamen keine Audioframes an. Prüfe Berechtigung, Datenschalter und Geräterouting.',
        fr: 'Tous les entrées ont été essayées, mais aucune trame audio n’est arrivée. Vérifiez l’autorisation, les réglages de confidentialité et le routage.',
        es: 'Se probaron todas las entradas, pero no llegaron frames de audio. Revisa permisos, privacidad y el enrutamiento del dispositivo.',
        ru: 'Испробованы все входы, но аудиокадры не пришли. Проверьте разрешения, приватность и маршрутизацию устройства.',
      );
    }
    if (code == 'digital_silence') {
      return pickUiText(
        i18n,
        zh: '上一输入源启动成功但只返回静音，已自动切到更稳的麦克风路径。',
        en: 'The previous input started but returned silence, so the lab switched to a steadier mic path.',
        ja: '前の入力は起動しましたが無音だったため、より安定したマイク経路へ切り替えました。',
        de: 'Der vorige Eingang startete, blieb aber stumm. Das Labor nutzt nun einen stabileren Mikrofonpfad.',
        fr: 'L’entrée précédente a démarré sans signal ; le labo utilise un chemin micro plus stable.',
        es: 'La entrada anterior inició sin señal; el laboratorio cambió a una ruta de micrófono más estable.',
        ru: 'Предыдущий вход запустился без сигнала; выбран более надежный путь микрофона.',
      );
    }
    if (code == 'no_pcm_frames') {
      return pickUiText(
        i18n,
        zh: '上一输入源没有送达声音帧，已自动尝试下一个输入配置。',
        en: 'The previous input delivered no audio frames, so the next input profile was tried.',
        ja: '前の入力から音声フレームが届かなかったため、次の入力設定を試しました。',
        de: 'Der vorige Eingang lieferte keine Audioframes; das nächste Profil wurde versucht.',
        fr: 'L’entrée précédente n’a livré aucune trame audio ; le profil suivant a été essayé.',
        es: 'La entrada anterior no entregó frames de audio; se probó el siguiente perfil.',
        ru: 'Предыдущий вход не дал аудиокадров; попробован следующий профиль.',
      );
    }
    return null;
  }

  String _reportSummary(AppI18n i18n) {
    if (_captures.isEmpty) {
      return pickUiText(
        i18n,
        zh: '还没有样本。建议先测环境噪声，再测低音、高音和持续发声。',
        en: 'No samples yet. Start with ambient noise, then low tone, high tone, and sustain.',
        ja: 'No samples yet. Start with ambient noise, then low tone, high tone, and sustain.',
        de: 'No samples yet. Start with ambient noise, then low tone, high tone, and sustain.',
        fr: 'Pas encore d\'échantillons. Commencez par le bruit ambiant, puis le ton bas, le ton haut et maintenir.',
        es: 'Aún no hay muestras. Comience con ruido ambiente, luego tono bajo, tono alto y sostener.',
        ru: 'Пока нет образцов. Начните с окружающего шума, затем низкий тон, высокий тон и выдерживайте.',
      );
    }
    final averageScore =
        _captures.values.fold<double>(
          0,
          (sum, capture) => sum + capture.qualityScore,
        ) /
        _captures.length;
    final best = _captures.values.reduce(
      (a, b) => a.qualityScore >= b.qualityScore ? a : b,
    );
    final weakest = _captures.values.reduce(
      (a, b) => a.qualityScore <= b.qualityScore ? a : b,
    );
    return pickUiText(
      i18n,
      zh: '已完成 ${_captures.length}/4 项，综合质量 ${_captureQualityLabel(i18n, averageScore)}。最佳：${_modeSpecs[best.mode]!.label(i18n)}；优先复测：${_modeSpecs[weakest.mode]!.label(i18n)}。',
      en: '${_captures.length}/4 modes complete. Overall quality: ${_captureQualityLabel(i18n, averageScore)}. Best: ${_modeSpecs[best.mode]!.label(i18n)}; retest priority: ${_modeSpecs[weakest.mode]!.label(i18n)}.',
      ja: '${_captures.length}/4つのモードが完了しました。全体的な品質：${_captureQualityLabel(i18n, averageScore)}。ベスト：${_modeSpecs[best.mode]!.label(i18n)};再テストの優先度： ${_modeSpecs[weakest.mode]!.label(i18n)}。',
      de: '${_captures.length}/4 modes complete. Overall quality: ${_captureQualityLabel(i18n, averageScore)}. Best: ${_modeSpecs[best.mode]!.label(i18n)}; retest priority: ${_modeSpecs[weakest.mode]!.label(i18n)}.',
      fr: '${_captures.length}/4 modes complete. Overall quality: ${_captureQualityLabel(i18n, averageScore)}. Best: ${_modeSpecs[best.mode]!.label(i18n)}; retest priority: ${_modeSpecs[weakest.mode]!.label(i18n)}.',
      es: 'Se completan los modos de contacto. Calidad general: יv1/ título. Mejor: <v2/ título; retest priority: יv3/año.',
      ru: '${_captures.length}/4 режимы завершены. Общее качество: ${_captureQualityLabel(i18n, averageScore)} Лучше всего: ${_modeSpecs[best.mode]!.label(i18n)}; приоритет повторного тестирования: ${_modeSpecs[weakest.mode]!.label(i18n)}.',
    );
  }

  String _recommendedNextStep(AppI18n i18n) {
    if (!_captures.containsKey(_MicLabMode.noise)) {
      return pickUiText(
        i18n,
        zh: '建议下一步：先测噪声仪，建立本机本房间的环境底噪。',
        en: 'Next: measure the noise meter first to establish the room floor on this device.',
        ja: '次は騒音計で部屋のノイズフロアを測り、この端末の基準を作ります。',
        de: 'Nächster Schritt: zuerst den Geräuschmesser messen, um den Raumpegel auf diesem Gerät zu erfassen.',
        fr: 'Étape suivante : mesurez d’abord le sonomètre pour établir le bruit de fond de cette pièce.',
        es: 'Siguiente: mide primero el ruido ambiente para fijar el piso de sala en este dispositivo.',
        ru: 'Далее: сначала измерьте шум комнаты, чтобы задать базовый фон на этом устройстве.',
      );
    }
    for (final mode in <_MicLabMode>[
      _MicLabMode.low,
      _MicLabMode.high,
      _MicLabMode.sustain,
    ]) {
      if (!_captures.containsKey(mode)) {
        return pickUiText(
          i18n,
          zh: '建议下一步：完成 ${_modeSpecs[mode]!.label(i18n)} 样本，保持同一距离和音量。',
          en: 'Next: capture ${_modeSpecs[mode]!.label(i18n)} with the same distance and level.',
          ja: '次は ${_modeSpecs[mode]!.label(i18n)} を同じ距離と音量で測ります。',
          de: 'Nächster Schritt: ${_modeSpecs[mode]!.label(i18n)} mit gleichem Abstand und Pegel aufnehmen.',
          fr: 'Étape suivante : mesurez ${_modeSpecs[mode]!.label(i18n)} avec la même distance et le même niveau.',
          es: 'Siguiente: captura ${_modeSpecs[mode]!.label(i18n)} con la misma distancia y nivel.',
          ru: 'Далее: запишите ${_modeSpecs[mode]!.label(i18n)} на той же дистанции и громкости.',
        );
      }
    }
    final weakest = _captures.values.reduce(
      (a, b) => a.qualityScore <= b.qualityScore ? a : b,
    );
    return pickUiText(
      i18n,
      zh: '四项已完成。若要提高可比性，优先复测 ${_modeSpecs[weakest.mode]!.label(i18n)}。',
      en: 'All four modes are complete. To improve comparability, retest ${_modeSpecs[weakest.mode]!.label(i18n)} first.',
      ja: '4 つのモードが完了しました。比較精度を上げるなら ${_modeSpecs[weakest.mode]!.label(i18n)} を優先して再測します。',
      de: 'Alle vier Modi sind vollständig. Für bessere Vergleichbarkeit zuerst ${_modeSpecs[weakest.mode]!.label(i18n)} erneut messen.',
      fr: 'Les quatre modes sont terminés. Pour améliorer la comparaison, recommencez d’abord ${_modeSpecs[weakest.mode]!.label(i18n)}.',
      es: 'Los cuatro modos están completos. Para mejorar la comparación, repite primero ${_modeSpecs[weakest.mode]!.label(i18n)}.',
      ru: 'Все четыре режима завершены. Для лучшего сравнения сначала повторите ${_modeSpecs[weakest.mode]!.label(i18n)}.',
    );
  }

  String _baselineHint(AppI18n i18n) {
    if (_noiseFloorDbfs != null) {
      return pickUiText(
        i18n,
        zh: '环境底噪 ${_noiseFloorDbfs!.toStringAsFixed(1)} dBFS，后续报告会用它估算信噪比。',
        en: 'Room floor: ${_noiseFloorDbfs!.toStringAsFixed(1)} dBFS. Later samples use it for SNR.',
        ja: 'ノイズフロア: ${_noiseFloorDbfs!.toStringAsFixed(1)} dBFS。以後のサンプルで SNR 推定に使います。',
        de: 'Raumpegel: ${_noiseFloorDbfs!.toStringAsFixed(1)} dBFS. Spätere Proben nutzen ihn für SNR.',
        fr: 'Bruit de fond : ${_noiseFloorDbfs!.toStringAsFixed(1)} dBFS. Les autres mesures l’utilisent pour le SNR.',
        es: 'Piso de ruido: ${_noiseFloorDbfs!.toStringAsFixed(1)} dBFS. Las muestras posteriores lo usan para SNR.',
        ru: 'Фон комнаты: ${_noiseFloorDbfs!.toStringAsFixed(1)} dBFS. Позже он используется для SNR.',
      );
    }
    return pickUiText(
      i18n,
      zh: '尚未建立环境底噪。先测噪声仪，低音/高音/持续的信噪比会更可信。',
      en: 'No room floor yet. Measure noise first so low, high, and sustain SNR are more useful.',
      ja: 'まだノイズフロアがありません。先に騒音を測ると、低音・高音・持続の SNR が役立ちます。',
      de: 'Noch kein Raumpegel. Miss zuerst Geräusch, damit SNR für Tiefton, Hochton und Halten nützlicher wird.',
      fr: 'Aucun bruit de fond pour l’instant. Mesurez le bruit d’abord pour rendre le SNR plus utile.',
      es: 'Aún no hay piso de ruido. Mide ruido primero para que el SNR sea más útil.',
      ru: 'Фон комнаты еще не измерен. Сначала измерьте шум, чтобы SNR был полезнее.',
    );
  }

  String _pitchNoteLabel(double frequency) {
    final midi = (69 + 12 * math.log(frequency / 440.0) / math.ln2).round();
    const noteNames = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final noteName = noteNames[((midi % 12) + 12) % 12];
    final octave = (midi ~/ 12) - 1;
    return '$noteName$octave';
  }

  double? _detectPitch(List<double> samples, int sampleRate) {
    if (samples.length < 2048) {
      return null;
    }
    final window = samples.length > 4096
        ? samples.sublist(samples.length - 4096)
        : List<double>.of(samples);
    final mean =
        window.fold<double>(0, (sum, value) => sum + value) / window.length;
    for (var i = 0; i < window.length; i += 1) {
      window[i] -= mean;
    }

    final minLag = math.max(24, sampleRate ~/ 1000);
    final maxLag = math.min(window.length ~/ 2, sampleRate ~/ 65);
    var bestLag = 0;
    var bestScore = 0.0;
    var secondBestScore = 0.0;

    for (var lag = minLag; lag <= maxLag; lag += 1) {
      var correlation = 0.0;
      var energyA = 0.0;
      var energyB = 0.0;
      for (var i = 0; i < window.length - lag; i += 1) {
        final a = window[i];
        final b = window[i + lag];
        correlation += a * b;
        energyA += a * a;
        energyB += b * b;
      }
      final denominator = math.sqrt(energyA * energyB);
      if (denominator <= 1e-9) {
        continue;
      }
      final score = correlation / denominator;
      if (score > bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestLag = lag;
      } else if (score > secondBestScore) {
        secondBestScore = score;
      }
    }

    if (bestLag == 0 || bestScore < 0.72) {
      return null;
    }
    final refinedLag = _refineLag(window, bestLag);
    final frequency = sampleRate / refinedLag;
    if (frequency < 65 || frequency > 1400) {
      return null;
    }
    if ((bestScore - secondBestScore) < 0.08) {
      return null;
    }
    return frequency;
  }

  double _refineLag(List<double> window, int lag) {
    if (lag <= 1 || lag >= window.length - 1) {
      return lag.toDouble();
    }
    var y0 = 0.0;
    var y1 = 0.0;
    var y2 = 0.0;
    for (var i = 0; i < window.length - lag - 1; i += 1) {
      y0 += window[i] * window[i + lag - 1];
      y1 += window[i] * window[i + lag];
      y2 += window[i] * window[i + lag + 1];
    }
    final denominator = 2 * (y0 - 2 * y1 + y2);
    if (denominator.abs() < 1e-9) {
      return lag.toDouble();
    }
    final offset = (y0 - y2) / denominator;
    return lag + offset;
  }

  String _modeSummary(AppI18n i18n) {
    final spec = _modeSpecs[_mode]!;
    return switch (_mode) {
      _MicLabMode.low => pickUiText(
        i18n,
        zh: '目标: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        en: 'Target: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        ja: 'Target: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        de: 'Target: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        fr: 'Objectif : ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        es: 'Objetivo: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        ru: 'Цель: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Гц',
      ),
      _MicLabMode.high => pickUiText(
        i18n,
        zh: '目标: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        en: 'Target: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        ja: 'Target: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        de: 'Target: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        fr: 'Objectif : ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        es: 'Objetivo: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        ru: 'Цель: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Гц',
      ),
      _MicLabMode.sustain => pickUiText(
        i18n,
        zh: '保持稳定 5 秒以上，系统会读持续性和波动。',
        en: 'Hold steady for 5+ seconds; the system reads sustain and variation.',
        ja: 'Hold steady for 5+ seconds; the system reads sustain and variation.',
        de: 'Hold steady for 5+ seconds; the system reads sustain and variation.',
        fr: 'Tenez-vous stable pendant 5+ secondes ; le système lit soutenir et variation.',
        es: 'Mantenerse firme durante 5+ segundos; el sistema lee sostenimiento y variación.',
        ru: 'Оставайтесь на месте в течение 5+ секунд; система считывает устойчивость и изменение.',
      ),
      _MicLabMode.noise => pickUiText(
        i18n,
        zh: '保持安静，读环境噪声底和峰值。',
        en: 'Stay quiet and read the ambient floor and peaks.',
        ja: 'Stay quiet and read the ambient floor and peaks.',
        de: 'Stay quiet and read the ambient floor and peaks.',
        fr: 'Restez calme et lisez le plancher ambiant et les pics.',
        es: 'Manténgase tranquilo y leer el suelo ambiente y los picos.',
        ru: 'Оставайтесь спокойными и читайте окружающий пол и пики.',
      ),
    };
  }

  Color _meterColor() {
    if (_mode == _MicLabMode.noise) {
      if (_dbfs <= -52) {
        return const Color(0xFF22C55E);
      }
      if (_dbfs <= -38) {
        return const Color(0xFFF59E0B);
      }
      return const Color(0xFFEF4444);
    }
    if (_pitchStability >= 0.82) {
      return const Color(0xFF22C55E);
    }
    if (_pitchStability >= 0.55) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFFF97316);
  }

  Future<void> _showProfessionalReport() async {
    if (!mounted) {
      return;
    }
    final context = this.context;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final captures = Map<_MicLabMode, _MicLabCapture>.from(_captures);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final orderedCaptures = <_MicLabCapture>[
          for (final mode in _MicLabMode.values)
            if (captures[mode] != null) captures[mode]!,
        ];
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        pickUiText(
                          i18n,
                          zh: '声学报告',
                          en: 'Acoustic report',
                          ja: '音響レポート',
                          de: 'Akustikbericht',
                          fr: 'Rapport acoustique',
                          es: 'Informe acústico',
                          ru: 'Акустический отчет',
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>(
                        'acoustic_report_close_button',
                      ),
                      tooltip: pickUiText(
                        i18n,
                        zh: '关闭',
                        en: 'Close',
                        ja: '閉じる',
                        de: 'Close',
                        fr: 'Fermer',
                        es: 'Cerca',
                        ru: 'Закрыть',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _reportSummary(i18n),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Text(
                    pickUiText(
                      i18n,
                      zh: '说明：手机和电脑麦克风会受设备、距离和环境影响。结果适合练习、对比和观察房间噪声，不能替代专业检查。',
                      en: 'Note: phone and computer microphones vary by device, distance, and room. Use these results for practice, comparison, and room-noise checks; they do not replace a professional check.',
                      ja: '注: スマホやパソコンのマイクは、機種、距離、部屋の影響を受けます。結果は練習や比較、部屋の音の確認に使い、専門的な確認の代わりにはしないでください。',
                      de: 'Hinweis: Mikrofone in Telefonen und Computern reagieren je nach Gerät, Abstand und Raum anders. Die Ergebnisse helfen beim Üben, Vergleichen und Prüfen des Raumgeräuschs, ersetzen aber keine fachliche Kontrolle.',
                      fr: 'Remarque : les micros de téléphone et d’ordinateur varient selon l’appareil, la distance et la pièce. Ces résultats servent à pratiquer, comparer et vérifier le bruit de la pièce ; ils ne remplacent pas un contrôle professionnel.',
                      es: 'Nota: los micrófonos de teléfonos y ordenadores cambian según el dispositivo, la distancia y la habitación. Usa estos resultados para practicar, comparar y revisar el ruido de la habitación; no sustituyen una revisión profesional.',
                      ru: 'Примечание: микрофоны телефона и компьютера зависят от устройства, расстояния и комнаты. Используйте результаты для практики, сравнения и проверки шума в помещении; они не заменяют профессиональную проверку.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (orderedCaptures.isEmpty)
                  _HumanPanel(
                    child: Text(
                      pickUiText(
                        i18n,
                        zh: '暂无样本。请先完成至少一个模式并点击“加入报告”。',
                        en: 'No samples yet. Complete at least one mode and tap “Add to report”.',
                        ja: 'No samples yet. Complete at least one mode and tap “Add to report”.',
                        de: 'No samples yet. Complete at least one mode and tap “Add to report”.',
                        fr: 'Pas encore d\'échantillons. Compléter au moins un mode et appuyez sur Ajouter au rapport.',
                        es: 'Aún no hay muestras. Completa al menos un modo y pulsa “Añadir al informe”.',
                        ru: 'Пока нет образцов. Заполните хотя бы один режим и нажмите «Добавить в отчет».',
                      ),
                    ),
                  )
                else
                  for (final capture in orderedCaptures) ...<Widget>[
                    _AcousticReportCaptureCard(
                      capture: capture,
                      spec: _modeSpecs[capture.mode]!,
                      i18n: i18n,
                      qualityLabel: _captureQualityLabel(
                        i18n,
                        capture.qualityScore,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '复测建议：如果削波高于 1%、音高命中低于 60% 或曲线平滑低于 45%，可以拉远一点或放轻音量再测；如果环境噪声高于 -38 dBFS，先换到更安静的位置。',
                    en: 'Retest tip: if clipping is above 1%, pitch hit is below 60%, or smoothness is below 45%, move back a little or lower your voice and try again. If ambient noise is above -38 dBFS, move somewhere quieter first.',
                    ja: 'Retest tip: if clipping is above 1%, pitch hit is below 60%, or smoothness is below 45%, move back a little or lower your voice and try again. If ambient noise is above -38 dBFS, move somewhere quieter first.',
                    de: 'Retest tip: if clipping is above 1%, pitch hit is below 60%, or smoothness is below 45%, move back a little or lower your voice and try again. If ambient noise is above -38 dBFS, move somewhere quieter first.',
                    fr: 'Astuce de contre-test : si la coupure est supérieure à 1%, la hauteur est inférieure à 60%, ou la douceur est inférieure à 45%, reculez un peu ou baissez votre voix et essayez à nouveau. Si le bruit ambiant est supérieur à -38 dBFS, déplacez-vous d\'abord dans un endroit plus calme.',
                    es: 'Retest tip: si el recorte es superior al 1%, el golpe de lanzamiento es inferior al 60%, o la suavidad es inferior al 45%, retrocede un poco o baja la voz y vuelva a intentarlo. Si el ruido ambiente está por encima de -38 dBFS, mueva un lugar más tranquilo primero.',
                    ru: 'Совет: если обрезка выше 1%, удар ниже 60%, или плавность ниже 45%, немного отойдите назад или понизьте голос и попробуйте снова. Если шум окружающей среды выше -38 дБФС, сначала перейдите в более тихое место.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeSelector(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _MicLabMode.values
          .map((mode) {
            final modeSpec = _modeSpecs[mode]!;
            return ChoiceChip(
              avatar: Icon(modeSpec.icon, size: 18),
              label: Text(modeSpec.label(i18n)),
              selected: _mode == mode,
              onSelected: _running || _starting || _switchingInput
                  ? null
                  : (_) => _setMode(mode),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildActionRow(AppI18n i18n) {
    final canReset =
        _running ||
        _starting ||
        _switchingInput ||
        _samples.isNotEmpty ||
        _error != null ||
        _statusCode != null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          key: const ValueKey<String>('acoustic_start_button'),
          onPressed: _starting || _switchingInput
              ? null
              : _running
              ? _stopMonitoring
              : _startMonitoring,
          icon: Icon(_running ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(
            _starting || _switchingInput
                ? pickUiText(
                    i18n,
                    zh: '正在准备',
                    en: 'Preparing',
                    ja: '準備中',
                    de: 'Vorbereiten',
                    fr: 'Préparation',
                    es: 'Preparando',
                    ru: 'Подготовка',
                  )
                : _running
                ? pickUiText(
                    i18n,
                    zh: '停止监测',
                    en: 'Stop',
                    ja: '停止',
                    de: 'Stop',
                    fr: 'Arrêter',
                    es: 'Detener',
                    ru: 'Стоп',
                  )
                : pickUiText(
                    i18n,
                    zh: '打开麦克风',
                    en: 'Open mic',
                    ja: 'マイクを開く',
                    de: 'Mikro öffnen',
                    fr: 'Ouvrir le micro',
                    es: 'Abrir micrófono',
                    ru: 'Открыть микрофон',
                  ),
          ),
        ),
        FilledButton.icon(
          onPressed: (_running || (!_starting && _samples.length >= 3))
              ? _finishCapture
              : null,
          icon: const Icon(Icons.assignment_turned_in_rounded),
          label: Text(
            pickUiText(
              i18n,
              zh: '加入报告',
              en: 'Add to report',
              ja: 'レポートに追加',
              de: 'Zum Bericht hinzufügen',
              fr: 'Ajouter au rapport',
              es: 'Añadir al informe',
              ru: 'Добавить в отчет',
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _showProfessionalReport,
          icon: const Icon(Icons.summarize_rounded),
          label: Text(
            pickUiText(
              i18n,
              zh: '声学报告',
              en: 'Acoustic report',
              ja: '音響レポート',
              de: 'Akustikbericht',
              fr: 'Rapport acoustique',
              es: 'Informe acústico',
              ru: 'Акустический отчет',
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: canReset ? () => unawaited(_resetCurrentRun()) : null,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(
            pickUiText(
              i18n,
              zh: '重置',
              en: 'Reset',
              ja: 'Reset',
              de: 'Zurücksetzen',
              fr: 'Réinitialiser',
              es: 'Reiniciar',
              ru: 'Сброс',
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCoreMetrics(
    AppI18n i18n,
    String pitchLabel,
    _MicLabCapture? activeCapture,
  ) {
    return <Widget>[
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '状态',
          en: 'Status',
          ja: '状態',
          de: 'Status',
          fr: 'État',
          es: 'Estado',
          ru: 'Статус',
        ),
        value: _statusLabel(i18n),
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '电平',
          en: 'Level',
          ja: 'Level',
          de: 'Level',
          fr: 'Niveau',
          es: 'Nivel',
          ru: 'Уровень',
        ),
        value: '${(_level * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '峰值',
          en: 'Peak',
          ja: 'Peak',
          de: 'Peak',
          fr: 'Pic',
          es: 'Peak',
          ru: 'Пик',
        ),
        value: '${(_peak * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: 'dBFS',
          en: 'dBFS',
          ja: 'dBFS',
          de: 'dBFS',
          fr: 'dBFS',
          es: 'dBFS',
          ru: 'dBFS',
        ),
        value: _dbfs.toStringAsFixed(1),
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '音高',
          en: 'Pitch',
          ja: 'Pitch',
          de: 'Pitch',
          fr: 'Hauteur',
          es: 'Tono',
          ru: 'Высота',
        ),
        value: pitchLabel,
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '稳定性',
          en: 'Stability',
          ja: 'Stability',
          de: 'Stability',
          fr: 'Stabilité',
          es: 'Estabilidad',
          ru: 'Стабильность',
        ),
        value: '${(_pitchStability * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '持续性',
          en: 'Sustain',
          ja: 'Sustain',
          de: 'Sustain',
          fr: 'Tenue',
          es: 'Sostenido',
          ru: 'Длительность',
        ),
        value: '${(_sustainScore * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '曲线平滑',
          en: 'Smoothness',
          ja: 'Smoothness',
          de: 'Smoothness',
          fr: 'Lissage',
          es: 'Suavidad',
          ru: 'Плавность',
        ),
        value: '${(_lastCurveSmoothness * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '响度一致',
          en: 'Level hold',
          ja: 'Level hold',
          de: 'Level hold',
          fr: 'Tenue niveau',
          es: 'Nivel estable',
          ru: 'Удержание',
        ),
        value: '${(_levelConsistencyScore * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '环境评分',
          en: 'Ambient',
          ja: 'Ambient',
          de: 'Ambient',
          fr: 'Ambiant',
          es: 'Ambiente',
          ru: 'Фон',
        ),
        value: '${(_ambientScore * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '过零率',
          en: 'ZCR',
          ja: 'ZCR',
          de: 'ZCR',
          fr: 'ZCR',
          es: 'ZCR',
          ru: 'ZCR',
        ),
        value: _zeroCrossingRate.toStringAsFixed(3),
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '削波',
          en: 'Clipping',
          ja: 'クリッピング',
          de: 'Clipping',
          fr: 'Écrêtage',
          es: 'Recorte',
          ru: 'Клиппинг',
        ),
        value: '${(_clippingRatio * 100).toStringAsFixed(1)}%',
      ),
      ToolboxMetricCard(
        label: pickUiText(
          i18n,
          zh: '动态范围',
          en: 'Range',
          ja: 'Range',
          de: 'Range',
          fr: 'Plage',
          es: 'Rango',
          ru: 'Диапазон',
        ),
        value: activeCapture == null
            ? '--'
            : '${activeCapture.dynamicRangeDb.toStringAsFixed(1)} dB',
      ),
    ];
  }

  Widget _buildDiagnostics(AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _preferCompatibilityInput,
          onChanged: _running || _starting || _switchingInput
              ? null
              : (value) => setState(() => _preferCompatibilityInput = value),
          secondary: const Icon(Icons.settings_input_component_rounded),
          title: Text(
            pickUiText(
              i18n,
              zh: '兼容输入优先',
              en: 'Compatibility input first',
              ja: '互換入力を優先',
              de: 'Kompatiblen Eingang zuerst',
              fr: 'Entrée compatible d’abord',
              es: 'Entrada compatible primero',
              ru: 'Сначала совместимый вход',
            ),
          ),
          subtitle: Text(
            pickUiText(
              i18n,
              zh: '部分手机的原始/标准输入会启动但没有信号，开启后会先使用语音识别输入。',
              en: 'Some phones start a raw or standard input with no signal. This starts with the voice-recognition input instead.',
              ja: '一部の端末では標準入力が無音になるため、音声認識入力から開始します。',
              de: 'Einige Geräte starten ohne Signal. Diese Option beginnt mit dem Spracherkennungseingang.',
              fr: 'Certains téléphones démarrent sans signal ; cette option commence par l’entrée de reconnaissance vocale.',
              es: 'Algunos teléfonos inician sin señal; esta opción empieza con la entrada de reconocimiento de voz.',
              ru: 'Некоторые телефоны запускают вход без сигнала; этот режим сначала использует распознавание речи.',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: pickUiText(
                i18n,
                zh: '采样率',
                en: 'Sample rate',
                ja: 'Sample rate',
                de: 'Sample rate',
                fr: 'Échantillonnage',
                es: 'Muestreo',
                ru: 'Частота',
              ),
              value: _running || _activeRecorderProfileId != null
                  ? '${(_activeSampleRate / 1000).toStringAsFixed(_activeSampleRate % 1000 == 0 ? 0 : 1)} kHz'
                  : '--',
            ),
            ToolboxMetricCard(
              label: pickUiText(
                i18n,
                zh: '输入',
                en: 'Input',
                ja: 'Input',
                de: 'Input',
                fr: 'Entrée',
                es: 'Entrada',
                ru: 'Вход',
              ),
              value: _inputLabel(i18n),
            ),
            ToolboxMetricCard(
              label: pickUiText(
                i18n,
                zh: '流模式',
                en: 'Stream',
                ja: 'Stream',
                de: 'Stream',
                fr: 'Flux',
                es: 'Flujo',
                ru: 'Поток',
              ),
              value: _profileLabel(i18n),
            ),
            ToolboxMetricCard(
              label: pickUiText(
                i18n,
                zh: '首帧',
                en: 'First frame',
                ja: 'First frame',
                de: 'First frame',
                fr: '1re trame',
                es: 'Primer frame',
                ru: 'Первый кадр',
              ),
              value: _formatFirstFrame(i18n),
            ),
            ToolboxMetricCard(
              label: pickUiText(
                i18n,
                zh: '样本',
                en: 'Frames',
                ja: 'Frames',
                de: 'Frames',
                fr: 'Cadres',
                es: 'Frames',
                ru: 'Кадры',
              ),
              value: '$_frameCount',
            ),
            ToolboxMetricCard(
              label: pickUiText(
                i18n,
                zh: '空帧',
                en: 'Blank frames',
                ja: 'Blank frames',
                de: 'Leere Frames',
                fr: 'Trames vides',
                es: 'Frames vacíos',
                ru: 'Пустые кадры',
              ),
              value: '$_emptyChunkCount',
            ),
            ToolboxMetricCard(
              label: pickUiText(
                i18n,
                zh: '启动尝试',
                en: 'Starts',
                ja: 'Starts',
                de: 'Starts',
                fr: 'Démarrages',
                es: 'Inicios',
                ru: 'Запуски',
              ),
              value: '$_streamRestartCount',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final spec = _modeSpecs[_mode]!;
    final meterColor = _meterColor();
    final levelPercent =
        (_mode == _MicLabMode.noise
                ? ((_dbfs + 120) / 120).clamp(0.0, 1.0)
                : _level.clamp(0.0, 1.0))
            .toDouble();
    final pitchLabel = _pitchHz == null
        ? '--'
        : '${_pitchHz!.toStringAsFixed(1)} Hz · ${_pitchNoteLabel(_pitchHz!)}';
    final activeCapture = _captures[_mode];
    final error = _error == null ? null : _errorMessage(i18n);
    final profileNotice = _profileNoticeMessage(i18n);
    return _HumanPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildModeSelector(i18n),
          const SizedBox(height: 12),
          _AcousticLiveStage(
            icon: spec.icon,
            title: spec.label(i18n),
            subtitle: spec.description(i18n),
            summary: _modeSummary(i18n),
            status: _statusLabel(i18n),
            readiness: _captureReadiness(i18n),
            primaryValue: _hasSeenFrame
                ? '${_dbfs.toStringAsFixed(1)} dBFS'
                : '-- dBFS',
            secondaryValue: _mode == _MicLabMode.noise
                ? _noiseLabel(i18n)
                : pitchLabel,
            levelPercent: levelPercent,
            levelCaption: _mode == _MicLabMode.noise
                ? '${_noiseLabel(i18n)} · ${_dbfs.toStringAsFixed(1)} dBFS'
                : _mode == _MicLabMode.sustain
                ? '${(_sustainScore * 100).round()}% · ${(_lastCurveSmoothness * 100).round()}%'
                : '${(_pitchStability * 100).round()}% · ${(_lastCurveSmoothness * 100).round()}%',
            levelHistory: _levelHistory,
            accent: meterColor,
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: 10),
            _AcousticStatusBanner(
              icon: Icons.error_outline_rounded,
              message: error,
              color: theme.colorScheme.error,
            ),
          ],
          if (profileNotice != null) ...<Widget>[
            const SizedBox(height: 10),
            _AcousticStatusBanner(
              icon: Icons.alt_route_rounded,
              message: profileNotice,
              color: theme.colorScheme.primary,
            ),
          ],
          const SizedBox(height: 12),
          _buildActionRow(i18n),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _buildCoreMetrics(i18n, pitchLabel, activeCapture),
          ),
          if (activeCapture != null) ...<Widget>[
            const SizedBox(height: 10),
            _AcousticCaptureSummary(
              capture: activeCapture,
              label: _captureQualityLabel(i18n, activeCapture.qualityScore),
              accent: meterColor,
            ),
          ],
          const SizedBox(height: 12),
          _AcousticReportSummaryCard(
            summary: _reportSummary(i18n),
            nextStep: _recommendedNextStep(i18n),
            completedText: '${_captures.length}/4',
            onOpen: _showProfessionalReport,
            i18n: i18n,
          ),
          const SizedBox(height: 12),
          _HumanSettingsSection(
            title: pickUiText(
              i18n,
              zh: '采样指南',
              en: 'Sampling guide',
              ja: 'Sampling guide',
              de: 'Sampling guide',
              fr: 'Guide de mesure',
              es: 'Guía de muestreo',
              ru: 'Руководство',
            ),
            subtitle: _baselineHint(i18n),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _AcousticProtocolPanel(
                  icon: spec.icon,
                  title: spec.label(i18n),
                  protocol: _protocolText(i18n),
                  readiness: _captureReadiness(i18n),
                  accent: meterColor,
                ),
                const SizedBox(height: 10),
                _AcousticStatusBanner(
                  icon: Icons.tips_and_updates_rounded,
                  message: pickUiText(
                    i18n,
                    zh: '低音/高音保持单一持续音；持续模式保持同一音高；噪声仪保持安静，并让手机远离风扇和桌面震动。',
                    en: 'For low and high modes, keep one steady sound. For sustain, hold one pitch. For the noise meter, stay quiet and keep the phone away from fans and table vibration.',
                    ja: '低音/高音は安定した一音を保ち、持続は同じ音高を伸ばします。騒音計では静かにし、風や机の振動を避けます。',
                    de: 'Halte bei tief/hoch einen gleichmäßigen Ton. Beim Halten bleibt eine Tonhöhe stabil. Für Geräusch bleib ruhig und meide Lüfter oder Tischvibration.',
                    fr: 'Gardez un son stable en grave/aigu, une hauteur en tenue, et le silence pour le bruit. Éloignez le téléphone des ventilateurs et vibrations.',
                    es: 'En bajo/agudo mantén un sonido estable. En sostenido mantén un tono. En ruido, guarda silencio y evita ventiladores o vibración.',
                    ru: 'Для низкого/высокого тона держите ровный звук. Для длительности держите высоту. Для шума сохраняйте тишину и избегайте вибрации.',
                  ),
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _HumanSettingsSection(
            title: pickUiText(
              i18n,
              zh: '采集诊断',
              en: 'Capture diagnostics',
              ja: 'Capture diagnostics',
              de: 'Capture diagnostics',
              fr: 'Diagnostic de capture',
              es: 'Diagnóstico de captura',
              ru: 'Диагностика',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '查看输入源、首帧、空帧和兼容模式；真机无声时优先打开这里。',
              en: 'Check input source, first frame, blank frames, and compatibility mode. Open this first if a real device stays silent.',
              ja: '入力、初回フレーム、空フレーム、互換モードを確認します。実機で無音ならここを開きます。',
              de: 'Prüfe Eingang, ersten Frame, Leerframes und Kompatibilitätsmodus, wenn ein Gerät stumm bleibt.',
              fr: 'Vérifiez l’entrée, la première trame, les trames vides et le mode compatible si l’appareil reste muet.',
              es: 'Revisa entrada, primer frame, frames vacíos y modo compatible si el dispositivo queda sin señal.',
              ru: 'Проверьте вход, первый кадр, пустые кадры и режим совместимости, если устройство молчит.',
            ),
            initiallyExpanded: _error != null || _profileNoticeCode != null,
            child: _buildDiagnostics(i18n),
          ),
        ],
      ),
    );
  }
}

class _AcousticLiveStage extends StatelessWidget {
  const _AcousticLiveStage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.status,
    required this.readiness,
    required this.primaryValue,
    required this.secondaryValue,
    required this.levelPercent,
    required this.levelCaption,
    required this.levelHistory,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String summary;
  final String status;
  final String readiness;
  final String primaryValue;
  final String secondaryValue;
  final double levelPercent;
  final String levelCaption;
  final List<double> levelHistory;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _HumanPill(text: status, accent: accent),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _HumanPill(text: readiness, accent: accent),
              _HumanPill(
                text: secondaryValue,
                accent: accent.withValues(alpha: 0.78),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final chartHeight = compact ? 92.0 : 110.0;
              return Column(
                children: <Widget>[
                  SizedBox(
                    height: chartHeight,
                    child: CustomPaint(
                      painter: _MicLevelHistoryPainter(
                        levelHistory: levelHistory,
                        accent: accent,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: levelPercent,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        levelCaption,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            primaryValue,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondaryValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcousticReportSummaryCard extends StatelessWidget {
  const _AcousticReportSummaryCard({
    required this.summary,
    required this.nextStep,
    required this.completedText,
    required this.onOpen,
    required this.i18n,
  });

  final String summary;
  final String nextStep;
  final String completedText;
  final VoidCallback onOpen;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '声学报告',
                    en: 'Acoustic report',
                    ja: '音響レポート',
                    de: 'Akustikbericht',
                    fr: 'Rapport acoustique',
                    es: 'Informe acústico',
                    ru: 'Акустический отчет',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _HumanPill(text: completedText, accent: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 10),
          _HumanPill(text: nextStep, accent: colorScheme.secondary),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onOpen,
              icon: const Icon(Icons.summarize_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '打开声学报告',
                  en: 'Acoustic report',
                  ja: 'レポートを開く',
                  de: 'Bericht öffnen',
                  fr: 'Ouvrir le rapport',
                  es: 'Abrir informe',
                  ru: 'Открыть отчет',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcousticStatusBanner extends StatelessWidget {
  const _AcousticStatusBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicLevelHistoryPainter extends CustomPainter {
  const _MicLevelHistoryPainter({
    required this.levelHistory,
    required this.accent,
  });

  final List<double> levelHistory;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      background,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i += 1) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fill = Path();
    final count = levelHistory.length;
    for (var i = 0; i < count; i += 1) {
      final level = levelHistory[i].clamp(0.0, 1.0);
      final x = count <= 1 ? 0.0 : size.width * i / (count - 1);
      final y = size.height - (level * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          accent.withValues(alpha: 0.34),
          accent.withValues(alpha: 0.02),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fill, fillPaint);

    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MicLevelHistoryPainter oldDelegate) {
    return oldDelegate.levelHistory != levelHistory ||
        oldDelegate.accent != accent;
  }
}

class _AcousticProtocolPanel extends StatelessWidget {
  const _AcousticProtocolPanel({
    required this.icon,
    required this.title,
    required this.protocol,
    required this.readiness,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String protocol;
  final String readiness;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  protocol,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  readiness,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcousticCaptureSummary extends StatelessWidget {
  const _AcousticCaptureSummary({
    required this.capture,
    required this.label,
    required this.accent,
  });

  final _MicLabCapture capture;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Text(
        '${capture.seconds.toStringAsFixed(1)} s · '
        '${capture.averageDbfs.toStringAsFixed(1)} dBFS · '
        '${(capture.qualityScore * 100).round()}% · $label',
        style: theme.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AcousticReportCaptureCard extends StatelessWidget {
  const _AcousticReportCaptureCard({
    required this.capture,
    required this.spec,
    required this.i18n,
    required this.qualityLabel,
  });

  final _MicLabCapture capture;
  final _MicModeSpec spec;
  final AppI18n i18n;
  final String qualityLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _qualityColor(capture.qualityScore);
    final pitch = capture.averagePitchHz == null
        ? '--'
        : '${capture.averagePitchHz!.toStringAsFixed(1)} Hz';
    final snr = capture.snrDb == null
        ? '--'
        : '${capture.snrDb!.toStringAsFixed(1)} dB';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(spec.icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  spec.label(i18n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _HumanPill(text: qualityLabel, accent: accent),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '时长',
                  en: 'Duration',
                  ja: 'Duration',
                  de: 'Duration',
                  fr: 'Durée',
                  es: 'Duración',
                  ru: 'Продолжительность',
                ),
                value: '${capture.seconds.toStringAsFixed(1)} s',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '均值',
                  en: 'Mean',
                  ja: 'Mean',
                  de: 'Mean',
                  fr: 'Moyenne',
                  es: 'Significa',
                  ru: 'Значение',
                ),
                value: '${capture.averageDbfs.toStringAsFixed(1)} dBFS',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '峰值',
                  en: 'Peak',
                  ja: 'Peak',
                  de: 'Peak',
                  fr: 'Pic',
                  es: 'Peak',
                  ru: 'пик',
                ),
                value: '${capture.peakDbfs.toStringAsFixed(1)} dBFS',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '音高',
                  en: 'Pitch',
                  ja: 'Pitch',
                  de: 'Pitch',
                  fr: 'Emplacement',
                  es: 'Pitch',
                  ru: 'стучать',
                ),
                value: pitch,
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '音高波动',
                  en: 'Pitch SD',
                  ja: 'Pitch SD',
                  de: 'Pitch SD',
                  fr: 'Emplacement SD',
                  es: 'Pitch SD',
                  ru: 'Pitch SD',
                ),
                value: '${capture.pitchStdDevHz.toStringAsFixed(1)} Hz',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '命中',
                  en: 'Target hit',
                  ja: 'Target hit',
                  de: 'Target hit',
                  fr: 'Cible atteinte',
                  es: 'Objetivo alcanzado',
                  ru: 'Цель ранена.',
                ),
                value: '${(capture.targetHitRatio * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '信噪比',
                  en: 'SNR',
                  ja: 'SNR',
                  de: 'SNR',
                  fr: 'SNR',
                  es: 'SNR',
                  ru: 'SNR',
                ),
                value: snr,
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '有效声',
                  en: 'Voiced',
                  ja: 'Voiced',
                  de: 'Stimmhaft',
                  fr: 'Voisé',
                  es: 'Sonoro',
                  ru: 'Голос',
                ),
                value: '${(capture.voicedRatio * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '动态',
                  en: 'Range',
                  ja: 'Range',
                  de: 'Range',
                  fr: 'Plage',
                  es: 'Rango',
                  ru: 'Диапазон',
                ),
                value: '${capture.dynamicRangeDb.toStringAsFixed(1)} dB',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '峰均比',
                  en: 'Crest',
                  ja: 'Crest',
                  de: 'Crest',
                  fr: 'Crête',
                  es: 'Cresta',
                  ru: 'Пик/ср.',
                ),
                value: '${capture.crestFactorDb.toStringAsFixed(1)} dB',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '削波',
                  en: 'Clipping',
                  ja: 'クリッピング',
                  de: 'Clipping',
                  fr: 'Clippage',
                  es: 'Clipping',
                  ru: 'клиппинг',
                ),
                value: '${(capture.clippingRatio * 100).toStringAsFixed(1)}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '空白帧',
                  en: 'Blank',
                  ja: 'Blank',
                  de: 'Leer',
                  fr: 'Blanc',
                  es: 'Vacío',
                  ru: 'Пусто',
                ),
                value: '${(capture.emptyChunkRatio * 100).toStringAsFixed(1)}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '帧数',
                  en: 'Frames',
                  ja: 'Frames',
                  de: 'Frames',
                  fr: 'Trames',
                  es: 'Frames',
                  ru: 'Кадры',
                ),
                value: '${capture.sampleCount}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _interpretation(i18n, capture),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Color _qualityColor(double score) {
    if (score >= 0.82) {
      return const Color(0xFF16A34A);
    }
    if (score >= 0.64) {
      return const Color(0xFF2563EB);
    }
    if (score >= 0.42) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFDC2626);
  }

  String _interpretation(AppI18n i18n, _MicLabCapture capture) {
    if (capture.mode == _MicLabMode.noise) {
      if (capture.averageDbfs <= -52) {
        return pickUiText(
          i18n,
          zh: '环境噪声底较低，适合作为其他声学测试的参考环境。',
          en: 'The ambient noise floor is low, suitable as a reference environment for the other acoustic tests.',
          ja: 'The ambient noise floor is low, suitable as a reference environment for the other acoustic tests.',
          de: 'The ambient noise floor is low, suitable as a reference environment for the other acoustic tests.',
          fr: 'Le plancher de bruit ambiant est bas, adapté comme environnement de référence pour les autres essais acoustiques.',
          es: 'El suelo de ruido ambiente es bajo, adecuado como ambiente de referencia para las otras pruebas acústicas.',
          ru: 'Уровень шума в окружающей среде низкий, подходит в качестве эталонной среды для других акустических тестов.',
        );
      }
      return pickUiText(
        i18n,
        zh: '环境噪声偏高，可能压低后续信噪比与音高识别稳定性，建议换到更安静的位置。',
        en: 'Ambient noise is elevated and may reduce later SNR and pitch stability. Move to a quieter place if possible.',
        ja: 'は上昇し、後のSNRとピッチの安定性を低下 させる可能性があります。 可能であれば、より静かな場所に移動してください。',
        de: 'Ambient noise is elevated and may reduce later SNR and pitch stability. Move to a quieter place if possible.',
        fr: 'Le bruit ambiant est élevé et peut réduire la stabilité du SNR et du pas. Déplacez-vous dans un endroit plus calme si possible.',
        es: 'El ruido ambiente es elevado y puede reducir más tarde SNR y la estabilidad del campo. Muévete a un lugar más tranquilo si es posible.',
        ru: 'Шум окружающей среды повышен и может снизить более позднюю SNR и стабильность шага. По возможности перейдите в более тихое место.',
      );
    }
    if (capture.clippingRatio > 0.01) {
      return pickUiText(
        i18n,
        zh: '检测到削波风险，说明输入过响或距离过近；请降低音量或拉远麦克风后重测。',
        en: 'Clipping risk is present, suggesting the input is too loud or too close. Lower the level or increase mic distance and retest.',
        ja: 'クリッピングのリスクがあり、入力が大きすぎるか近すぎることを示唆しています。レベルを下げるか、マイク距離を増やして再テストします。',
        de: 'Clipping risk is present, suggesting the input is too loud or too close. Lower the level or increase mic distance and retest.',
        fr: 'Le risque de pincement est présent, ce qui suggère que l\'entrée est trop forte ou trop proche. Abaissez le niveau ou augmentez la distance micro et retestez.',
        es: 'El riesgo de deslizamiento está presente, sugiriendo que la entrada es demasiado alta o demasiado cercana. Bajar el nivel o aumentar la distancia de micrófono y retest.',
        ru: 'Риск скольжения присутствует, предполагая, что вход слишком громкий или слишком близко. Понизить уровень или увеличить дистанцию микрофона и повторно протестировать.',
      );
    }
    if (capture.targetHitRatio < 0.55) {
      return pickUiText(
        i18n,
        zh: '音高落在目标区间的比例偏低，建议用更稳定、更单一的音重测。',
        en: 'Pitch target-hit ratio is low. Retest with a steadier, single tone.',
        ja: 'Pitch target-hit ratio is low. Retest with a steadier, single tone.',
        de: 'Pitch target-hit ratio is low. Retest with a steadier, single tone.',
        fr: 'Le rapport cible-coup est faible. Retestez avec un ton plus stable.',
        es: 'La relación objetivo-hit de Pitch es baja. Retesta con un tono más firme y sencillo.',
        ru: 'Коэффициент попадания в цель низкий. Повторяйте с более устойчивым, единичным тоном.',
      );
    }
    if (capture.pitchStability >= 0.78 && capture.levelConsistency >= 0.66) {
      return pickUiText(
        i18n,
        zh: '音高和响度都较稳定，样本质量足够用于前后对比。',
        en: 'Pitch and level are stable; this sample is strong enough for before-and-after comparison.',
        ja: 'Pitch and level are stable; this sample is strong enough for before-and-after comparison.',
        de: 'Pitch and level are stable; this sample is strong enough for before-and-after comparison.',
        fr: 'Pitch and level are stable; this sample is strong enough for before-and-after comparison.',
        es: 'Pitch and level are stable; this sample is strong enough for before-and-after comparison.',
        ru: 'Pitch and level are stable; this sample is strong enough for before-and-after comparison.',
      );
    }
    return pickUiText(
      i18n,
      zh: '样本可用于参考，但音高或响度仍有波动；若要比较训练变化，建议按同一距离和音量复测。',
      en: 'The sample is usable, but pitch or level still fluctuates. For training comparison, repeat with the same distance and level.',
      ja: 'The sample is usable, but pitch or level still fluctuates. For training comparison, repeat with the same distance and level.',
      de: 'The sample is usable, but pitch or level still fluctuates. For training comparison, repeat with the same distance and level.',
      fr: 'L\'échantillon est utilisable, mais la hauteur ou le niveau fluctue encore. Pour comparer la formation, répéter avec la même distance et le même niveau.',
      es: 'La muestra es usable, pero el campo o el nivel todavía fluctúa. Para la comparación de entrenamiento, repita con la misma distancia y nivel.',
      ru: 'Образец можно использовать, но высота или уровень все еще колеблется. Для сравнения тренировок повторите с той же дистанцией и уровнем.',
    );
  }
}
