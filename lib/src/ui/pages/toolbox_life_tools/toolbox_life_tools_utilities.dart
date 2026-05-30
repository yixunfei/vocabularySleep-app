part of '../toolbox_life_tools.dart';

class _LifeUtilityToolPage extends StatelessWidget {
  const _LifeUtilityToolPage({required this.tool});

  final _LifeTool tool;

  @override
  Widget build(BuildContext context) {
    return switch (tool.id) {
      'text_count' => const _TextCounterPage(),
      'text_encoding' => const _TextTransformPage(),
      'sup_sub' => const _NumberMarksPage(),
      'unit_converter' => const _UnitConverterToolPage(),
      'work_worth' => const _WorkWorthPage(),
      'offer_select' => const _OfferSelectToolPage(),
      'city_compare' => const _CitySalaryComparePage(),
      'mortgage' => const _MortgageProPage(),
      'date_calculator' => const _DateCalculatorPage(),
      'world_clock' => const _WorldClockToolPage(),
      'bmi' => const _BmiToolPage(),
      'short_link' => const _ShortLinkPage(),
      'qr' => const _QrPage(),
      'image_transform' => const _ImageTransformPage(),
      'image_to_web' => const _ImageToWebToolPage(),
      'id_photo' => const _IdPhotoToolPage(),
      _ => _LifeToolInfoPage(tool: tool),
    };
  }
}

class _LegacyTextCounterPage extends StatefulWidget {
  const _LegacyTextCounterPage();

  @override
  State<_LegacyTextCounterPage> createState() => _LegacyTextCounterPageState();
}

class _LegacyTextCounterPageState extends State<_LegacyTextCounterPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _symbolCount(String text) {
    var count = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final isWord = RegExp(r'[A-Za-z0-9\u4E00-\u9FFF]').hasMatch(char);
      final isWhitespace = RegExp(r'\s').hasMatch(char);
      if (!isWord && !isWhitespace) {
        count += 1;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;
    final total = text.characters.length;
    final symbols = _symbolCount(text);
    final noSymbols = total - symbols;
    final noWhitespace = text.replaceAll(RegExp(r'\s+'), '').characters.length;
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.text_counter.cbbe4083b63c',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.counts_total_symbol_non_symbol_non_w.dfe034300622',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _controller,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.total.80c11663ed42',
                ),
              ),
              trailing: Text('$total'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.symbols.11e6462b50cc',
                ),
              ),
              trailing: Text('$symbols'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.no_symbols.a097692ca216',
                ),
              ),
              trailing: Text('$noSymbols'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.no_whitespace.da904b772103',
                ),
              ),
              trailing: Text('$noWhitespace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextEncodingPage extends StatefulWidget {
  const _TextEncodingPage();

  @override
  State<_TextEncodingPage> createState() => _TextEncodingPageState();
}

class _TextEncodingPageState extends State<_TextEncodingPage> {
  final TextEditingController _input = TextEditingController();
  final TextEditingController _key = TextEditingController(text: 'life-tools');
  String _output = '';

  @override
  void dispose() {
    _input.dispose();
    _key.dispose();
    super.dispose();
  }

  void _run(String mode) {
    final text = _input.text;
    setState(() {
      _output = switch (mode) {
        'base64' => base64Encode(utf8.encode(text)),
        'md5' => md5.convert(utf8.encode(text)).toString(),
        'sha256' => sha256.convert(utf8.encode(text)).toString(),
        'morse' => _toMorse(text),
        'beast' => _toBeast(text),
        'rc4' => _rc4(text, _key.text),
        _ => '',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.text_encoding.dff53b3f0a78',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.fun_codes_base64_md5_sha256_morse_be.96af10469db7',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _input,
            maxLines: 4,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.input.ae956811ac06',
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _key,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.key_rc4.edb89da99c4d',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final mode in <String>[
                'base64',
                'md5',
                'sha256',
                'morse',
                'beast',
                'rc4',
              ])
                FilledButton.tonal(
                  onPressed: () => _run(mode),
                  child: Text(switch (mode) {
                    'base64' => 'Base64',
                    'md5' => 'MD5',
                    'sha256' => 'SHA256',
                    'morse' => _lifeI18nText(
                      context,
                      'inline.plan295.life.morse.43afc9300fbb',
                    ),
                    'beast' => _lifeI18nText(
                      context,
                      'inline.plan295.life.beast.90f87d75d9fd',
                    ),
                    'rc4' => 'RC4',
                    _ => mode.toUpperCase(),
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(_output),
        ],
      ),
    );
  }

  String _toMorse(String text) {
    const map = <String, String>{
      'a': '.-',
      'b': '-...',
      'c': '-.-.',
      'd': '-..',
      'e': '.',
      'f': '..-.',
      'g': '--.',
      'h': '....',
      'i': '..',
      'j': '.---',
      'k': '-.-',
      'l': '.-..',
      'm': '--',
      'n': '-.',
      'o': '---',
      'p': '.--.',
      'q': '--.-',
      'r': '.-.',
      's': '...',
      't': '-',
      'u': '..-',
      'v': '...-',
      'w': '.--',
      'x': '-..-',
      'y': '-.--',
      'z': '--..',
      '1': '.----',
      '2': '..---',
      '3': '...--',
      '4': '....-',
      '5': '.....',
      '6': '-....',
      '7': '--...',
      '8': '---..',
      '9': '----.',
      '0': '-----',
    };
    return text
        .toLowerCase()
        .split('')
        .map((char) => map[char] ?? char)
        .join(' ');
  }

  String _toBeast(String text) {
    final bytes = utf8.encode(text);
    return bytes.map((byte) => byte.isEven ? '嗷' : '呜').join();
  }

  String _rc4(String plain, String key) {
    final keyBytes = utf8.encode(key.isEmpty ? 'k' : key);
    final data = utf8.encode(plain);
    final s = List<int>.generate(256, (index) => index);
    var j = 0;
    for (var i = 0; i < 256; i += 1) {
      j = (j + s[i] + keyBytes[i % keyBytes.length]) & 255;
      final tmp = s[i];
      s[i] = s[j];
      s[j] = tmp;
    }
    var i = 0;
    j = 0;
    final out = Uint8List(data.length);
    for (var k = 0; k < data.length; k += 1) {
      i = (i + 1) & 255;
      j = (j + s[i]) & 255;
      final tmp = s[i];
      s[i] = s[j];
      s[j] = tmp;
      final t = (s[i] + s[j]) & 255;
      out[k] = data[k] ^ s[t];
    }
    return base64Encode(out);
  }
}

class _UnitConverterPage extends StatefulWidget {
  const _UnitConverterPage();

  @override
  State<_UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<_UnitConverterPage> {
  final TextEditingController _controller = TextEditingController(text: '1');
  String _mode = 'length';
  String _result = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _convert() {
    final value = double.tryParse(_controller.text) ?? 0;
    setState(() {
      _result = switch (_mode) {
        'length' =>
          '${value} 米 = ${(value * 100).toStringAsFixed(2)} 厘米 = ${(value * 3.28084).toStringAsFixed(4)} 英尺',
        'weight' => '${value} 千克 = ${(value * 2.20462).toStringAsFixed(4)} 磅',
        'temp' =>
          '${value} 摄氏度 = ${(value * 9 / 5 + 32).toStringAsFixed(2)} 华氏度',
        _ => '',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.unit_converter.53644e92a340',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.convert_common_units_including_lengt.3af885c8005c',
      ),
      child: Column(
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _mode,
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(
                value: 'length',
                child: Text(
                  _lifeI18nText(
                    context,
                    'inline.ui.pages.toolbox_human_tests_typing_widgets.length_f37873',
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'weight',
                child: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.weight.a353a17dc3f6',
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'temp',
                child: Text(
                  _lifeI18nText(
                    context,
                    'inline.ui.pages.toolbox_daily_choice.daily_choice_wear_module.temperature_fb37d5',
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _mode = value ?? 'length'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _convert,
            child: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.convert.46d20ffe33a5',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(_result),
        ],
      ),
    );
  }
}

class _LegacyWorkWorthPage extends StatefulWidget {
  const _LegacyWorkWorthPage();

  @override
  State<_LegacyWorkWorthPage> createState() => _LegacyWorkWorthPageState();
}

class _LegacyWorkWorthPageState extends State<_LegacyWorkWorthPage> {
  final TextEditingController _salary = TextEditingController(text: '20000');
  final TextEditingController _cost = TextEditingController(text: '9000');
  final TextEditingController _insurance = TextEditingController(text: '3500');
  double _health = 0.5;
  String _result = '';

  void _compute() {
    final salary = double.tryParse(_salary.text) ?? 0;
    final cost = double.tryParse(_cost.text) ?? 0;
    final insurance = double.tryParse(_insurance.text) ?? 0;
    final remain = salary - cost - insurance;
    final score = remain * (0.6 + _health * 0.8);
    setState(() {
      _result =
          '月净可支配：${remain.toStringAsFixed(0)}\n综合得分：${score.toStringAsFixed(1)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.work_value_calculator.766dbe3047f2',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.includes_living_cost_insurance_fund.2ce3e76c9b72',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _salary,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.monthly_income.5af85bd8e221',
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cost,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.monthly_cost.fea07322cec3',
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _insurance,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.insurance_and_fund.589a9e0e7a04',
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _health,
            onChanged: (value) => setState(() => _health = value),
            min: 0,
            max: 1,
            divisions: 10,
            label: _health.toStringAsFixed(1),
          ),
          FilledButton(
            onPressed: _compute,
            child: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.calculate.d89e10c4a2ce',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(_result),
        ],
      ),
    );
  }
}

class _MortgagePage extends StatefulWidget {
  const _MortgagePage();

  @override
  State<_MortgagePage> createState() => _MortgagePageState();
}

class _MortgagePageState extends State<_MortgagePage> {
  final TextEditingController _principal = TextEditingController(
    text: '1000000',
  );
  final TextEditingController _rate = TextEditingController(text: '3.6');
  final TextEditingController _years = TextEditingController(text: '30');
  String _result = '';

  void _calc() {
    final p = double.tryParse(_principal.text) ?? 0;
    final annualRatePercent = double.tryParse(_rate.text) ?? -1;
    final years = int.tryParse(_years.text) ?? 0;
    if (p <= 0 || years <= 0 || annualRatePercent < 0) {
      setState(() => _result = '参数无效');
      return;
    }
    final result = const ToolboxMortgageService().calculate(
      MortgageInput(
        repaymentMethod: MortgageRepaymentMethod.equalInstallment,
        calculationMode: MortgageCalculationMode.loanAmount,
        termYears: years,
        annualRatePercent: annualRatePercent,
        firstPaymentDate: DateTime.now(),
        loanAmountYuan: p,
      ),
    );
    setState(() {
      _result =
          '月供：${result.firstMonthlyPayment.toStringAsFixed(2)}\n总还款：${result.contractTotalPayment.toStringAsFixed(2)}\n总利息：${result.contractTotalInterest.toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.mortgage_calculator.3e4f4dddc3e6',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.quickly_estimate_monthly_payments_an.5755ce4df71b',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _principal,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.loan_amount.63ea87de3c18',
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rate,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.annual_rate.cf9b736de5ab',
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _years,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.loan_term.a43ba990427a',
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _calc,
            child: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.calculate.d89e10c4a2ce',
              ),
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(_result),
        ],
      ),
    );
  }
}

class _SupSubPage extends StatefulWidget {
  const _SupSubPage();

  @override
  State<_SupSubPage> createState() => _SupSubPageState();
}

class _SupSubPageState extends State<_SupSubPage> {
  final TextEditingController _controller = TextEditingController();
  bool _subscript = false;
  String _output = '';

  static const Map<String, String> _supMap = <String, String>{
    '0': '^0',
    '1': '^1',
    '2': '^2',
    '3': '^3',
    '4': '^4',
    '5': '^5',
    '6': '^6',
    '7': '^7',
    '8': '^8',
    '9': '^9',
    '+': '^+',
    '-': '^-',
    '=': '^=',
    '(': '^(',
    ')': '^)',
    'n': '^n',
    'i': '^i',
  };

  static const Map<String, String> _subMap = <String, String>{
    '0': '_0',
    '1': '_1',
    '2': '_2',
    '3': '_3',
    '4': '_4',
    '5': '_5',
    '6': '_6',
    '7': '_7',
    '8': '_8',
    '9': '_9',
    '+': '_+',
    '-': '_-',
    '=': '_=',
    '(': '_(',
    ')': '_)',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _convert() {
    final map = _subscript ? _subMap : _supMap;
    final text = _controller.text;
    final buf = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      buf.write(map[char] ?? char);
    }
    setState(() => _output = buf.toString());
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.super_or_subscript.725857aea674',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.convert_text_and_numbers_to_superscr.933439c94c1e',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _subscript,
            title: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.use_subscript.34f2b7330592',
              ),
            ),
            onChanged: (value) => setState(() => _subscript = value),
          ),
          FilledButton(
            onPressed: _convert,
            child: Text(
              _lifeI18nText(
                context,
                'inline.plan295.life.convert.46d20ffe33a5',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(_output),
        ],
      ),
    );
  }
}
