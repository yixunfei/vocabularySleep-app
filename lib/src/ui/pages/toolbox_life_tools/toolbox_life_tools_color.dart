part of '../toolbox_life_tools.dart';

class _ColorHelperToolPage extends StatefulWidget {
  const _ColorHelperToolPage();

  @override
  State<_ColorHelperToolPage> createState() => _ColorHelperToolPageState();
}

class _ColorHelperToolPageState extends State<_ColorHelperToolPage> {
  late final Future<_LifePaletteBundle> _bundleFuture;
  late final TextEditingController _queryController;
  late final ScrollController _scrollController;

  String _query = '';
  String? _expandedColorKey;
  bool _pageColorPreviewEnabled = false;
  Color? _pagePreviewColor;

  ui.Image? _image;
  ByteData? _pixels;
  Color? _picked;
  int _width = 0;
  int _height = 0;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _LifePaletteRepository.load();
    _queryController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _queryController.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.color_helper.10ac659af588',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.search_match_copy_color_values_and_s.23475628085d',
      ),
      backgroundColor: _pageColorPreviewEnabled ? _pagePreviewColor : null,
      scrollController: _scrollController,
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'life_color_back_to_top',
        tooltip: _lifeI18nText(
          context,
          'inline.ui.pages.toolbox_daily_choice.daily_choice_manager_sheet.back_to_top_b9ffaa',
        ),
        onPressed: _scrollToTop,
        child: const Icon(Icons.keyboard_arrow_up_rounded),
      ),
      child: FutureBuilder<_LifePaletteBundle>(
        future: _bundleFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LifeSettingsPanel(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.palette_load_failed.16e844fcd131',
              ),
              subtitle: _lifeI18nText(
                context,
                'inline.plan295.life.the_local_palette_assets_are_unavail.2a53f7912d3c',
              ),
              children: <Widget>[SelectableText('${snapshot.error}')],
            );
          }

          if (!snapshot.hasData) {
            return _LifeSettingsPanel(
              title: _lifeI18nText(
                context,
                'inline.plan295.life.loading_palettes.d18b4e4cc453',
              ),
              subtitle: _lifeI18nText(
                context,
                'inline.plan295.life.reading_local_palette_data.ffb2e62bb098',
              ),
              children: const <Widget>[LinearProgressIndicator()],
            );
          }

          final allColors = _unifiedColors(snapshot.data!);
          final filteredColors = _filterColors(allColors, _query);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildImageSampler(context),
              const SizedBox(height: 12),
              _LifeColorSearchPanel(
                controller: _queryController,
                query: _query,
                total: allColors.length,
                filtered: filteredColors.length,
                pagePreviewEnabled: _pageColorPreviewEnabled,
                onTogglePagePreview: _setPagePreviewEnabled,
                onChanged: (value) => setState(() {
                  _query = value;
                  _expandedColorKey = null;
                  _pagePreviewColor = null;
                }),
                onClear: () {
                  _queryController.clear();
                  setState(() {
                    _query = '';
                    _expandedColorKey = null;
                    _pagePreviewColor = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (filteredColors.isEmpty)
                _emptyPanel(
                  context,
                  text: _lifeI18nText(
                    context,
                    'inline.plan295.life.no_color_matched_try_another_name_ph.d47b88211d5f',
                  ),
                )
              else
                _UnifiedColorWall(
                  colors: filteredColors,
                  expandedKey: _expandedColorKey,
                  pagePreviewEnabled: _pageColorPreviewEnabled,
                  onToggle: (entry) => setState(() {
                    final closing = _expandedColorKey == entry.stableKey;
                    _expandedColorKey = closing ? null : entry.stableKey;
                    _pagePreviewColor = closing ? null : entry.color;
                  }),
                  onTogglePagePreview: _setPagePreviewEnabled,
                  onCopyHex: (entry) => _copyText(
                    entry.hex,
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.hex.a731c686157b',
                    ),
                  ),
                  onCopyName: (entry) => _copyText(
                    entry.name,
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.name.0a0a54c8e406',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<_LifePaletteColor> _unifiedColors(_LifePaletteBundle bundle) {
    return bundle.allColors.toList(growable: false)
      ..sort(_compareUnifiedColors);
  }

  void _setPagePreviewEnabled(bool value) {
    setState(() {
      _pageColorPreviewEnabled = value;
    });
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  int _compareUnifiedColors(_LifePaletteColor left, _LifePaletteColor right) {
    final leftHsv = HSVColor.fromColor(left.color);
    final rightHsv = HSVColor.fromColor(right.color);
    final leftNeutral = leftHsv.saturation < 0.12 || leftHsv.value < 0.18;
    final rightNeutral = rightHsv.saturation < 0.12 || rightHsv.value < 0.18;

    if (leftNeutral != rightNeutral) {
      return leftNeutral ? 1 : -1;
    }
    if (leftNeutral && rightNeutral) {
      return rightHsv.value.compareTo(leftHsv.value);
    }

    final hueCompare = leftHsv.hue.compareTo(rightHsv.hue);
    if (hueCompare != 0) {
      return hueCompare;
    }
    final saturationCompare = rightHsv.saturation.compareTo(leftHsv.saturation);
    if (saturationCompare != 0) {
      return saturationCompare;
    }
    return rightHsv.value.compareTo(leftHsv.value);
  }

  Widget _buildImageSampler(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.auxiliary_image_sampler.c763e8e3c3b7',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.import_a_local_image_then_tap_anywhe.fee20011e43f',
      ),
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: _pickImage,
          icon: const Icon(Icons.upload_file_rounded),
          label: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.import_image.040a2e597dc0',
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_image == null)
          _LifePreviewFrame(
            child: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.a_tappable_image_preview_will_appear.6d3f97e8fb00',
              ),
            ),
          )
        else
          _LifePreviewFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.tap_anywhere_on_the_image_to_sample.2c1f2c306984',
                  ),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 240,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boxSize = constraints.biggest;
                      return GestureDetector(
                        onTapDown: (details) {
                          final sampled = _sampleFromPreview(
                            details.localPosition,
                            boxSize,
                          );
                          setState(() => _picked = sampled);
                        },
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _image!.width.toDouble(),
                            height: _image!.height.toDouble(),
                            child: RawImage(image: _image),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        if (_picked != null) ...<Widget>[
          const SizedBox(height: 12),
          _sampledColorPanel(context, _picked!),
        ],
      ],
    );
  }

  List<_LifePaletteColor> _filterColors(
    List<_LifePaletteColor> colors,
    String query,
  ) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return colors;
    }
    final lower = normalized.toLowerCase();
    return colors
        .where((entry) {
          final haystack = <String>[
            entry.name,
            entry.phonetic,
            entry.upperPhonetic,
            entry.hex,
          ].join(' ').toLowerCase();
          return haystack.contains(lower) ||
              _matchesHexQuery(normalized, entry.hex);
        })
        .toList(growable: false);
  }

  bool _matchesHexQuery(String rawQuery, String hex) {
    if (!_looksLikeHexQuery(rawQuery)) {
      return false;
    }
    final value = _normalizeHexToken(hex);
    final pattern = _normalizeHexToken(rawQuery, allowWildcard: true);
    if (pattern.isEmpty || pattern.length > value.length) {
      return false;
    }
    if (pattern.contains('?')) {
      return _matchesWildcardHex(pattern, value);
    }
    return value.contains(pattern);
  }

  bool _looksLikeHexQuery(String rawQuery) {
    final trimmed = rawQuery.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (trimmed.startsWith('#') || trimmed.contains('?')) {
      return true;
    }
    return RegExp(r'^[0-9a-fA-F]{2,6}$').hasMatch(trimmed);
  }

  bool _matchesWildcardHex(String pattern, String value) {
    for (var offset = 0; offset <= value.length - pattern.length; offset += 1) {
      var matched = true;
      for (var index = 0; index < pattern.length; index += 1) {
        final code = pattern.codeUnitAt(index);
        if (code != 0x3F && code != value.codeUnitAt(offset + index)) {
          matched = false;
          break;
        }
      }
      if (matched) {
        return true;
      }
    }
    return false;
  }

  String _normalizeHexToken(String value, {bool allowWildcard = false}) {
    final buffer = StringBuffer();
    for (final codeUnit in value.toUpperCase().codeUnits) {
      final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
      final isHexLetter = codeUnit >= 0x41 && codeUnit <= 0x46;
      final isWildcard = allowWildcard && codeUnit == 0x3F;
      if (isDigit || isHexLetter || isWildcard) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) {
      return;
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final pixelData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (!mounted) {
      image.dispose();
      return;
    }

    final previousImage = _image;
    setState(() {
      _image = image;
      _pixels = pixelData;
      _width = image.width;
      _height = image.height;
      _picked = null;
    });
    previousImage?.dispose();
  }

  Color _sampleFromPreview(Offset local, Size boxSize) {
    if (_pixels == null || _width == 0 || _height == 0) {
      return Colors.black;
    }

    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(_width.toDouble(), _height.toDouble()),
      boxSize,
    );
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & boxSize,
    );
    final clampedDx = local.dx.clamp(destination.left, destination.right);
    final clampedDy = local.dy.clamp(destination.top, destination.bottom);
    final rx = ((clampedDx - destination.left) / destination.width).clamp(
      0.0,
      1.0,
    );
    final ry = ((clampedDy - destination.top) / destination.height).clamp(
      0.0,
      1.0,
    );
    final x = (rx * (_width - 1)).round();
    final y = (ry * (_height - 1)).round();
    final index = (y * _width + x) * 4;
    final bytes = _pixels!.buffer.asUint8List();

    return Color.fromARGB(
      bytes[index + 3],
      bytes[index],
      bytes[index + 1],
      bytes[index + 2],
    );
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeI18nText(
            context,
            'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.color.copied.9321f48be5',
            params: <String, Object?>{'label': label, 'text': text},
          ),
        ),
      ),
    );
  }

  Widget _sampledColorPanel(BuildContext context, Color color) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.sample_result.3a4d72a89bc0',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(_hexFromColor(color)),
                  ],
                ),
              ),
              IconButton(
                tooltip: _lifeI18nText(
                  context,
                  'inline.plan295.life.copy_hex.a889d770d5d5',
                ),
                onPressed: () => _copyText(
                  _hexFromColor(color),
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.hex.a731c686157b',
                  ),
                ),
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _valueChip(
                context,
                label: 'RGB',
                value: _rgbTextFromColor(color),
              ),
              _valueChip(
                context,
                label: 'HSV',
                value: _hsvTextFromColor(color),
              ),
              _valueChip(
                context,
                label: 'CMYK',
                value: _cmykTextFromColor(color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyPanel(BuildContext context, {required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(text),
    );
  }

  Widget _valueChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: <InlineSpan>[
            TextSpan(
              text: '$label ',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _hexFromColor(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  String _rgbTextFromColor(Color color) {
    final red = (color.r * 255.0).round().clamp(0, 255);
    final green = (color.g * 255.0).round().clamp(0, 255);
    final blue = (color.b * 255.0).round().clamp(0, 255);
    return '$red, $green, $blue';
  }

  String _hsvTextFromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    return '${hsv.hue.toStringAsFixed(1)}, ${hsv.saturation.toStringAsFixed(2)}, ${hsv.value.toStringAsFixed(2)}';
  }

  String _cmykTextFromColor(Color color) {
    final red = color.r;
    final green = color.g;
    final blue = color.b;
    final key = 1 - math.max(red, math.max(green, blue));

    if (key >= 0.999) {
      return '0%, 0%, 0%, 100%';
    }

    final denom = 1 - key;
    final cyan = ((1 - red - key) / denom * 100).clamp(0, 100);
    final magenta = ((1 - green - key) / denom * 100).clamp(0, 100);
    final yellow = ((1 - blue - key) / denom * 100).clamp(0, 100);

    return '${cyan.toStringAsFixed(1)}%, ${magenta.toStringAsFixed(1)}%, ${yellow.toStringAsFixed(1)}%, ${(key * 100).toStringAsFixed(1)}%';
  }
}
