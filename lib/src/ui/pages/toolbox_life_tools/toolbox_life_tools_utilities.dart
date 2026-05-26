part of '../toolbox_life_tools.dart';

class _LifeUtilityToolPage extends StatelessWidget {
  const _LifeUtilityToolPage({required this.tool});

  final _LifeTool tool;

  @override
  Widget build(BuildContext context) {
    return switch (tool.id) {
      'text_count' => const _TextCounterPage(),
      'text_encoding' => const _TextEncodingPage(),
      'rc4' => const _TextEncodingPage(),
      'sup_sub' => const _SupSubPage(),
      'unit_converter' => const _UnitConverterPage(),
      'work_worth' => const _WorkWorthPage(),
      'mortgage' => const _MortgagePage(),
      'date_calculator' => const _DateCalculatorPage(),
      'bmi' => const _BmiPage(),
      'short_link' => const _ShortLinkPage(),
      'qr' => const _QrPage(),
      'image_compress' => const _ImageCompressPage(),
      'pinyin' => const _PinyinPage(),
      _ => _LifeToolInfoPage(tool: tool),
    };
  }
}

class _TextCounterPage extends StatefulWidget {
  const _TextCounterPage();

  @override
  State<_TextCounterPage> createState() => _TextCounterPageState();
}

class _TextCounterPageState extends State<_TextCounterPage> {
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
      title: _lifeText(context, zh: '字数计算', en: 'Text counter'),
      subtitle: _lifeText(
        context,
        zh: '统计总字符、符号、去符号、去空白。',
        en: 'Counts total/symbol/non-symbol/non-whitespace.',
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
              title: Text(_lifeText(context, zh: '总字符数', en: 'Total')),
              trailing: Text('$total'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(_lifeText(context, zh: '符号数', en: 'Symbols')),
              trailing: Text('$symbols'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(_lifeText(context, zh: '去符号字符数', en: 'No symbols')),
              trailing: Text('$noSymbols'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(
                _lifeText(context, zh: '去空白字符数', en: 'No whitespace'),
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
      title: _lifeText(context, zh: '文本编码', en: 'Text encoding'),
      subtitle: _lifeText(
        context,
        zh: '趣味编码 + Base64 + MD5 + SHA256 + RC4。',
        en: 'Fun codes + Base64 + MD5 + SHA256 + RC4.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _input,
            maxLines: 4,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _lifeText(context, zh: '输入文本', en: 'Input'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _key,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _lifeText(context, zh: '密钥（RC4）', en: 'Key (RC4)'),
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
                    'morse' => _lifeText(context, zh: '摩斯', en: 'Morse'),
                    'beast' => _lifeText(context, zh: '兽语', en: 'Beast'),
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
      title: _lifeText(context, zh: '全能单位换算', en: 'Unit converter'),
      subtitle: _lifeText(
        context,
        zh: '一期包含长度、重量、温度，后续继续扩展。',
        en: 'Phase-1 includes length, weight, and temperature.',
      ),
      child: Column(
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _mode,
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(
                value: 'length',
                child: Text(_lifeText(context, zh: '长度', en: 'Length')),
              ),
              DropdownMenuItem(
                value: 'weight',
                child: Text(_lifeText(context, zh: '重量', en: 'Weight')),
              ),
              DropdownMenuItem(
                value: 'temp',
                child: Text(_lifeText(context, zh: '温度', en: 'Temperature')),
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
            child: Text(_lifeText(context, zh: '转换', en: 'Convert')),
          ),
          const SizedBox(height: 12),
          SelectableText(_result),
        ],
      ),
    );
  }
}

class _WorkWorthPage extends StatefulWidget {
  const _WorkWorthPage();

  @override
  State<_WorkWorthPage> createState() => _WorkWorthPageState();
}

class _WorkWorthPageState extends State<_WorkWorthPage> {
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
      title: _lifeText(context, zh: '工作性价比计算器', en: 'Work value calculator'),
      subtitle: _lifeText(
        context,
        zh: '增加生活开销、保险公积金与健康因子。',
        en: 'Includes living cost, insurance/fund, and health factor.',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _salary,
            decoration: InputDecoration(
              labelText: _lifeText(context, zh: '月收入', en: 'Monthly income'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cost,
            decoration: InputDecoration(
              labelText: _lifeText(context, zh: '月生活开销', en: 'Monthly cost'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _insurance,
            decoration: InputDecoration(
              labelText: _lifeText(
                context,
                zh: '五险一金',
                en: 'Insurance and fund',
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
            child: Text(_lifeText(context, zh: '计算', en: 'Calculate')),
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
    final annual = (double.tryParse(_rate.text) ?? 0) / 100;
    final n = (int.tryParse(_years.text) ?? 0) * 12;
    final r = annual / 12;
    if (p <= 0 || n <= 0 || r <= 0) {
      setState(() => _result = '参数无效');
      return;
    }
    final m = p * r * math.pow(1 + r, n) / (math.pow(1 + r, n) - 1);
    final total = m * n;
    setState(() {
      _result =
          '月供：${m.toStringAsFixed(2)}\n总还款：${total.toStringAsFixed(2)}\n总利息：${(total - p).toStringAsFixed(2)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '房贷计算器', en: 'Mortgage calculator'),
      subtitle: _lifeText(
        context,
        zh: '一期实现等额本息快速估算。',
        en: 'Phase-1 provides amortized quick estimate.',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _principal,
            decoration: InputDecoration(
              labelText: _lifeText(context, zh: '贷款金额', en: 'Loan amount'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rate,
            decoration: InputDecoration(
              labelText: _lifeText(
                context,
                zh: '年利率(%)',
                en: 'Annual rate (%)',
              ),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _years,
            decoration: InputDecoration(
              labelText: _lifeText(context, zh: '贷款年限', en: 'Loan term'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _calc,
            child: Text(_lifeText(context, zh: '计算', en: 'Calculate')),
          ),
          const SizedBox(height: 8),
          SelectableText(_result),
        ],
      ),
    );
  }
}

class _DateCalculatorPage extends StatefulWidget {
  const _DateCalculatorPage();

  @override
  State<_DateCalculatorPage> createState() => _DateCalculatorPageState();
}

class _DateCalculatorPageState extends State<_DateCalculatorPage> {
  DateTime _start = DateTime.now().subtract(const Duration(days: 1));
  DateTime _end = DateTime.now();
  String _result = '';

  void _recompute() {
    final diff = _end.difference(_start);
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    final endOfYear = DateTime(now.year + 1, 1, 1);
    setState(() {
      _result =
          '相差：${diff.inDays} 天 ${diff.inHours % 24} 小时 ${diff.inMinutes % 60} 分 ${diff.inSeconds % 60} 秒\n'
          '本周剩余：${endOfWeek.difference(now).inHours} 小时\n'
          '本月剩余：${endOfMonth.difference(now).inDays} 天\n'
          '本年剩余：${endOfYear.difference(now).inDays} 天';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '日期计算器', en: 'Date calculator'),
      subtitle: _lifeText(
        context,
        zh: '计算时间差与阶段剩余时长。',
        en: 'Compute date diff and time remaining.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FilledButton.tonal(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
                initialDate: _start,
              );
              if (date != null) {
                setState(() => _start = date);
                _recompute();
              }
            },
            child: Text(
              _lifeText(
                context,
                zh: '起始：${_start.toIso8601String().split('T').first}',
                en: 'Start: ${_start.toIso8601String().split("T").first}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime(2200),
                initialDate: _end,
              );
              if (date != null) {
                setState(() => _end = date);
                _recompute();
              }
            },
            child: Text(
              _lifeText(
                context,
                zh: '结束：${_end.toIso8601String().split('T').first}',
                en: 'End: ${_end.toIso8601String().split("T").first}',
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _recompute,
            child: Text(_lifeText(context, zh: '计算', en: 'Calculate')),
          ),
          const SizedBox(height: 8),
          SelectableText(_result),
        ],
      ),
    );
  }
}

class _BmiPage extends StatefulWidget {
  const _BmiPage();

  @override
  State<_BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<_BmiPage> {
  final TextEditingController _height = TextEditingController(text: '170');
  final TextEditingController _weight = TextEditingController(text: '65');
  String _result = '';

  void _compute() {
    final h = (double.tryParse(_height.text) ?? 0) / 100;
    final w = double.tryParse(_weight.text) ?? 0;
    if (h <= 0 || w <= 0) {
      setState(() => _result = '参数无效');
      return;
    }
    final bmi = w / (h * h);
    final tag = bmi < 18.5
        ? '偏瘦'
        : (bmi < 24 ? '正常' : (bmi < 28 ? '超重' : '肥胖'));
    setState(() => _result = 'BMI = ${bmi.toStringAsFixed(2)} ($tag)');
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: 'BMI 计算器', en: 'BMI'),
      subtitle: _lifeText(
        context,
        zh: '身体质量指数计算。',
        en: 'Body mass index calculator.',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _height,
            decoration: InputDecoration(
              labelText: _lifeText(context, zh: '身高 cm', en: 'Height cm'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weight,
            decoration: InputDecoration(
              labelText: _lifeText(context, zh: '体重 kg', en: 'Weight kg'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _compute,
            child: Text(_lifeText(context, zh: '计算', en: 'Calculate')),
          ),
          const SizedBox(height: 8),
          Text(_result),
        ],
      ),
    );
  }
}

class _ShortLinkPage extends StatefulWidget {
  const _ShortLinkPage();

  @override
  State<_ShortLinkPage> createState() => _ShortLinkPageState();
}

class _ShortLinkPageState extends State<_ShortLinkPage> {
  final TextEditingController _url = TextEditingController();
  String _short = '';
  String _resolved = '';

  Future<void> _shorten() async {
    final target = _url.text.trim();
    if (target.isEmpty) {
      return;
    }
    final uri = Uri.parse(
      'https://tinyurl.com/api-create.php?url=${Uri.encodeComponent(target)}',
    );
    final response = await http.get(uri);
    if (!mounted) {
      return;
    }
    setState(() => _short = response.body.trim());
  }

  Future<void> _resolve() async {
    final target = _url.text.trim();
    if (target.isEmpty) {
      return;
    }
    final response = await http.get(
      Uri.parse(target),
      headers: const <String, String>{'User-Agent': 'Mozilla/5.0'},
    );
    if (!mounted) {
      return;
    }
    setState(() => _resolved = response.request?.url.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '短链接工具', en: 'Short link tool'),
      subtitle: _lifeText(
        context,
        zh: '使用公开 API 创建短链并解析跳转目标。',
        en: 'Create tiny URL and resolve destination.',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _url,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: _lifeText(context, zh: '网址', en: 'URL'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _shorten,
                  child: Text(_lifeText(context, zh: '生成短链', en: 'Shorten')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _resolve,
                  child: Text(_lifeText(context, zh: '解析短链', en: 'Resolve')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(_short),
          const SizedBox(height: 8),
          SelectableText(_resolved),
        ],
      ),
    );
  }
}

class _QrPage extends StatefulWidget {
  const _QrPage();

  @override
  State<_QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<_QrPage> {
  final TextEditingController _controller = TextEditingController(
    text: 'https://example.com',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = Uri.encodeComponent(
      _controller.text.trim().isEmpty ? ' ' : _controller.text.trim(),
    );
    final url =
        'https://api.qrserver.com/v1/create-qr-code/?size=420x420&data=$query';
    return ToolboxToolPage(
      title: _lifeText(context, zh: '二维码生成', en: 'QR generator'),
      subtitle: _lifeText(
        context,
        zh: '输入内容后即时生成二维码。',
        en: 'Generate QR from input content.',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => setState(() {}),
            child: Text(_lifeText(context, zh: '生成', en: 'Generate')),
          ),
          const SizedBox(height: 12),
          Image.network(url, height: 240, width: 240),
        ],
      ),
    );
  }
}

class _PinyinPage extends StatefulWidget {
  const _PinyinPage();

  @override
  State<_PinyinPage> createState() => _PinyinPageState();
}

class _PinyinPageState extends State<_PinyinPage> {
  final TextEditingController _controller = TextEditingController();
  String _output = '';
  static const Map<String, String> _map = <String, String>{
    '你': 'ni',
    '好': 'hao',
    '我': 'wo',
    '们': 'men',
    '中': 'zhong',
    '国': 'guo',
    '生': 'sheng',
    '活': 'huo',
    '工': 'gong',
    '具': 'ju',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '中文转拼音', en: 'Chinese to pinyin'),
      subtitle: _lifeText(
        context,
        zh: '一期内置常用字映射，未覆盖字符会原样保留。',
        en: 'Phase-1 includes common-character mapping; unknown chars remain unchanged.',
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              setState(() {
                _output = _controller.text
                    .split('')
                    .map((char) => _map[char] ?? char)
                    .join(' ');
              });
            },
            child: Text(_lifeText(context, zh: '转换', en: 'Convert')),
          ),
          const SizedBox(height: 8),
          SelectableText(_output),
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
      title: _lifeText(context, zh: '数字转标', en: 'Super or subscript'),
      subtitle: _lifeText(
        context,
        zh: '将文本和数字转换为上标或下标样式。',
        en: 'Convert text and numbers to superscript or subscript style.',
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
            title: Text(_lifeText(context, zh: '使用下标', en: 'Use subscript')),
            onChanged: (value) => setState(() => _subscript = value),
          ),
          FilledButton(
            onPressed: _convert,
            child: Text(_lifeText(context, zh: '转换', en: 'Convert')),
          ),
          const SizedBox(height: 10),
          SelectableText(_output),
        ],
      ),
    );
  }
}
