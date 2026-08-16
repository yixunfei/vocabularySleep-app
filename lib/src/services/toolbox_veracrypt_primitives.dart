import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

void _checkDigestInputRange(Uint8List input, int offset, int length) {
  if (offset < 0 || length < 0 || offset + length > input.length) {
    throw ArgumentError.value(<String, int>{
      'offset': offset,
      'length': length,
      'inputLength': input.length,
    }, 'input range');
  }
}

void _checkDigestOutputRange(Uint8List output, int offset, int digestSize) {
  if (offset < 0 || offset + digestSize > output.length) {
    throw ArgumentError.value(<String, int>{
      'offset': offset,
      'digestSize': digestSize,
      'outputLength': output.length,
    }, 'output range');
  }
}

class ToolboxVeraCryptSerpentEngine implements pc.BlockCipher {
  ToolboxVeraCryptSerpentEngine();

  static const int _blockSize = 16;
  static const int _keySize = 32;
  static const int _mask32 = 0xffffffff;
  static const int _phi = 0x9e3779b9;

  static const List<List<int>> _sBoxes = <List<int>>[
    <int>[3, 8, 15, 1, 10, 6, 5, 11, 14, 13, 4, 2, 7, 0, 9, 12],
    <int>[15, 12, 2, 7, 9, 0, 5, 10, 1, 11, 14, 8, 6, 13, 3, 4],
    <int>[8, 6, 7, 9, 3, 12, 10, 15, 13, 1, 14, 4, 0, 11, 5, 2],
    <int>[0, 15, 11, 8, 12, 9, 6, 3, 13, 1, 2, 4, 10, 7, 5, 14],
    <int>[1, 15, 8, 3, 12, 0, 11, 6, 2, 5, 4, 10, 9, 14, 7, 13],
    <int>[15, 5, 2, 11, 4, 10, 9, 12, 0, 3, 14, 8, 13, 6, 7, 1],
    <int>[7, 2, 12, 5, 8, 4, 6, 11, 14, 9, 1, 15, 13, 3, 10, 0],
    <int>[1, 13, 15, 0, 14, 8, 2, 11, 7, 4, 12, 10, 9, 3, 5, 6],
  ];

  static final List<List<int>> _inverseSBoxes = _buildInverseSBoxes();

  bool _forEncryption = true;
  List<List<int>> _roundKeys = List<List<int>>.empty();

  @override
  String get algorithmName => 'Serpent';

  @override
  int get blockSize => _blockSize;

  @override
  void init(bool forEncryption, pc.CipherParameters? params) {
    if (params is! pc.KeyParameter) {
      throw ArgumentError.value(params, 'params');
    }
    final key = params.key;
    if (key.length != _keySize) {
      throw ArgumentError.value(key.length, 'key.length');
    }
    _forEncryption = forEncryption;
    _roundKeys = _makeRoundKeys(key);
  }

  @override
  Uint8List process(Uint8List data) {
    final out = Uint8List(blockSize);
    processBlock(data, 0, out, 0);
    return out;
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if (_roundKeys.isEmpty) {
      throw StateError('Serpent engine is not initialized.');
    }
    if (inpOff < 0 || inpOff + _blockSize > inp.length) {
      throw ArgumentError.value(inpOff, 'inpOff');
    }
    if (outOff < 0 || outOff + _blockSize > out.length) {
      throw ArgumentError.value(outOff, 'outOff');
    }
    final transformed = _forEncryption
        ? _encryptBlock(Uint8List.sublistView(inp, inpOff, inpOff + _blockSize))
        : _decryptBlock(
            Uint8List.sublistView(inp, inpOff, inpOff + _blockSize),
          );
    out.setRange(outOff, outOff + _blockSize, transformed);
    return _blockSize;
  }

  @override
  void reset() {}

  Uint8List _encryptBlock(Uint8List block) {
    var state = <int>[
      _readLe32(block, 0),
      _readLe32(block, 4),
      _readLe32(block, 8),
      _readLe32(block, 12),
    ];
    for (var round = 0; round < 32; round += 1) {
      state = _xorWords(state, _roundKeys[round]);
      state = _applySBox(state, _sBoxes[round & 7]);
      if (round < 31) {
        state = _linearTransform(state);
      } else {
        state = _xorWords(state, _roundKeys[32]);
      }
    }
    return _wordsToBlock(state);
  }

  Uint8List _decryptBlock(Uint8List block) {
    var state = <int>[
      _readLe32(block, 0),
      _readLe32(block, 4),
      _readLe32(block, 8),
      _readLe32(block, 12),
    ];
    for (var round = 31; round >= 0; round -= 1) {
      if (round == 31) {
        state = _xorWords(state, _roundKeys[32]);
      } else {
        state = _inverseLinearTransform(state);
      }
      state = _applySBox(state, _inverseSBoxes[round & 7]);
      state = _xorWords(state, _roundKeys[round]);
    }
    return _wordsToBlock(state);
  }

  static List<List<int>> _makeRoundKeys(Uint8List key) {
    final prekeys = List<int>.filled(140, 0);
    for (var index = 0; index < 8; index += 1) {
      prekeys[index] = _readLe32(key, index * 4);
    }
    for (var index = 8; index < 140; index += 1) {
      prekeys[index] = _rotl32(
        prekeys[index - 8] ^
            prekeys[index - 5] ^
            prekeys[index - 3] ^
            prekeys[index - 1] ^
            _phi ^
            (index - 8),
        11,
      );
    }
    return List<List<int>>.generate(33, (round) {
      final words = <int>[
        prekeys[8 + round * 4],
        prekeys[8 + round * 4 + 1],
        prekeys[8 + round * 4 + 2],
        prekeys[8 + round * 4 + 3],
      ];
      return _applySBox(words, _sBoxes[(3 - round) & 7]);
    });
  }

  static List<int> _applySBox(List<int> words, List<int> box) {
    var y0 = 0;
    var y1 = 0;
    var y2 = 0;
    var y3 = 0;
    for (var bit = 0; bit < 32; bit += 1) {
      final nibble =
          ((words[0] >> bit) & 1) |
          (((words[1] >> bit) & 1) << 1) |
          (((words[2] >> bit) & 1) << 2) |
          (((words[3] >> bit) & 1) << 3);
      final value = box[nibble];
      y0 |= (value & 1) << bit;
      y1 |= ((value >> 1) & 1) << bit;
      y2 |= ((value >> 2) & 1) << bit;
      y3 |= ((value >> 3) & 1) << bit;
    }
    return <int>[y0 & _mask32, y1 & _mask32, y2 & _mask32, y3 & _mask32];
  }

  static List<int> _linearTransform(List<int> words) {
    var a = _rotl32(words[0], 13);
    var b = words[1];
    var c = _rotl32(words[2], 3);
    var d = words[3];
    b = _rotl32(b ^ a ^ c, 1);
    d = _rotl32(d ^ c ^ ((a << 3) & _mask32), 7);
    a = _rotl32(a ^ b ^ d, 5);
    c = _rotl32(c ^ d ^ ((b << 7) & _mask32), 22);
    return <int>[a, b, c, d];
  }

  static List<int> _inverseLinearTransform(List<int> words) {
    var a = words[0];
    var b = words[1];
    var c = words[2];
    var d = words[3];
    c = _rotr32(c, 22);
    a = _rotr32(a, 5);
    c = (c ^ d ^ ((b << 7) & _mask32)) & _mask32;
    a = (a ^ b ^ d) & _mask32;
    b = _rotr32(b, 1);
    d = (_rotr32(d, 7) ^ c ^ ((a << 3) & _mask32)) & _mask32;
    b = (b ^ a ^ c) & _mask32;
    c = _rotr32(c, 3);
    a = _rotr32(a, 13);
    return <int>[a, b, c, d];
  }

  static List<int> _xorWords(List<int> a, List<int> b) {
    return <int>[
      (a[0] ^ b[0]) & _mask32,
      (a[1] ^ b[1]) & _mask32,
      (a[2] ^ b[2]) & _mask32,
      (a[3] ^ b[3]) & _mask32,
    ];
  }

  static Uint8List _wordsToBlock(List<int> words) {
    final out = Uint8List(_blockSize);
    for (var index = 0; index < 4; index += 1) {
      _writeLe32(out, index * 4, words[index]);
    }
    return out;
  }

  static List<List<int>> _buildInverseSBoxes() {
    return _sBoxes
        .map((box) {
          final inverse = List<int>.filled(16, 0);
          for (var index = 0; index < 16; index += 1) {
            inverse[box[index]] = index;
          }
          return inverse;
        })
        .toList(growable: false);
  }

  static int _readLe32(Uint8List bytes, int offset) {
    return (bytes[offset] |
            (bytes[offset + 1] << 8) |
            (bytes[offset + 2] << 16) |
            (bytes[offset + 3] << 24)) &
        _mask32;
  }

  static void _writeLe32(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xff;
    bytes[offset + 1] = (value >> 8) & 0xff;
    bytes[offset + 2] = (value >> 16) & 0xff;
    bytes[offset + 3] = (value >> 24) & 0xff;
  }

  static int _rotl32(int value, int shift) {
    final normalized = value & _mask32;
    return (((normalized << shift) & _mask32) | (normalized >> (32 - shift))) &
        _mask32;
  }

  static int _rotr32(int value, int shift) {
    final normalized = value & _mask32;
    return ((normalized >> shift) | ((normalized << (32 - shift)) & _mask32)) &
        _mask32;
  }
}

class ToolboxVeraCryptKuznyechikEngine implements pc.BlockCipher {
  ToolboxVeraCryptKuznyechikEngine();

  static const int _blockSize = 16;
  static const int _keySize = 32;
  static const List<int> _sBox = <int>[
    252,
    238,
    221,
    17,
    207,
    110,
    49,
    22,
    251,
    196,
    250,
    218,
    35,
    197,
    4,
    77,
    233,
    119,
    240,
    219,
    147,
    46,
    153,
    186,
    23,
    54,
    241,
    187,
    20,
    205,
    95,
    193,
    249,
    24,
    101,
    90,
    226,
    92,
    239,
    33,
    129,
    28,
    60,
    66,
    139,
    1,
    142,
    79,
    5,
    132,
    2,
    174,
    227,
    106,
    143,
    160,
    6,
    11,
    237,
    152,
    127,
    212,
    211,
    31,
    235,
    52,
    44,
    81,
    234,
    200,
    72,
    171,
    242,
    42,
    104,
    162,
    253,
    58,
    206,
    204,
    181,
    112,
    14,
    86,
    8,
    12,
    118,
    18,
    191,
    114,
    19,
    71,
    156,
    183,
    93,
    135,
    21,
    161,
    150,
    41,
    16,
    123,
    154,
    199,
    243,
    145,
    120,
    111,
    157,
    158,
    178,
    177,
    50,
    117,
    25,
    61,
    255,
    53,
    138,
    126,
    109,
    84,
    198,
    128,
    195,
    189,
    13,
    87,
    223,
    245,
    36,
    169,
    62,
    168,
    67,
    201,
    215,
    121,
    214,
    246,
    124,
    34,
    185,
    3,
    224,
    15,
    236,
    222,
    122,
    148,
    176,
    188,
    220,
    232,
    40,
    80,
    78,
    51,
    10,
    74,
    167,
    151,
    96,
    115,
    30,
    0,
    98,
    68,
    26,
    184,
    56,
    130,
    100,
    159,
    38,
    65,
    173,
    69,
    70,
    146,
    39,
    94,
    85,
    47,
    140,
    163,
    165,
    125,
    105,
    213,
    149,
    59,
    7,
    88,
    179,
    64,
    134,
    172,
    29,
    247,
    48,
    55,
    107,
    228,
    136,
    217,
    231,
    137,
    225,
    27,
    131,
    73,
    76,
    63,
    248,
    254,
    141,
    83,
    170,
    144,
    202,
    216,
    133,
    97,
    32,
    113,
    103,
    164,
    45,
    43,
    9,
    91,
    203,
    155,
    37,
    208,
    190,
    229,
    108,
    82,
    89,
    166,
    116,
    210,
    230,
    244,
    180,
    192,
    209,
    102,
    175,
    194,
    57,
    75,
    99,
    182,
  ];
  static const List<int> _inverseSBox = <int>[
    165,
    45,
    50,
    143,
    14,
    48,
    56,
    192,
    84,
    230,
    158,
    57,
    85,
    126,
    82,
    145,
    100,
    3,
    87,
    90,
    28,
    96,
    7,
    24,
    33,
    114,
    168,
    209,
    41,
    198,
    164,
    63,
    224,
    39,
    141,
    12,
    130,
    234,
    174,
    180,
    154,
    99,
    73,
    229,
    66,
    228,
    21,
    183,
    200,
    6,
    112,
    157,
    65,
    117,
    25,
    201,
    170,
    252,
    77,
    191,
    42,
    115,
    132,
    213,
    195,
    175,
    43,
    134,
    167,
    177,
    178,
    91,
    70,
    211,
    159,
    253,
    212,
    15,
    156,
    47,
    155,
    67,
    239,
    217,
    121,
    182,
    83,
    127,
    193,
    240,
    35,
    231,
    37,
    94,
    181,
    30,
    162,
    223,
    166,
    254,
    172,
    34,
    249,
    226,
    74,
    188,
    53,
    202,
    238,
    120,
    5,
    107,
    81,
    225,
    89,
    163,
    242,
    113,
    86,
    17,
    106,
    137,
    148,
    101,
    140,
    187,
    119,
    60,
    123,
    40,
    171,
    210,
    49,
    222,
    196,
    95,
    204,
    207,
    118,
    44,
    184,
    216,
    46,
    54,
    219,
    105,
    179,
    20,
    149,
    190,
    98,
    161,
    59,
    22,
    102,
    233,
    92,
    108,
    109,
    173,
    55,
    97,
    75,
    185,
    227,
    186,
    241,
    160,
    133,
    131,
    218,
    71,
    197,
    176,
    51,
    250,
    150,
    111,
    110,
    194,
    246,
    80,
    255,
    93,
    169,
    142,
    23,
    27,
    151,
    125,
    236,
    88,
    247,
    31,
    251,
    124,
    9,
    13,
    122,
    103,
    69,
    135,
    220,
    232,
    79,
    29,
    78,
    4,
    235,
    248,
    243,
    62,
    61,
    189,
    138,
    136,
    221,
    205,
    11,
    19,
    152,
    2,
    147,
    128,
    144,
    208,
    36,
    52,
    203,
    237,
    244,
    206,
    153,
    16,
    68,
    64,
    146,
    58,
    1,
    38,
    18,
    26,
    72,
    104,
    245,
    129,
    139,
    199,
    214,
    32,
    10,
    8,
    0,
    76,
    215,
    116,
  ];
  static const List<int> _linearVector = <int>[
    148,
    32,
    133,
    16,
    194,
    192,
    1,
    251,
    1,
    192,
    194,
    16,
    133,
    32,
    148,
    1,
  ];

  bool _forEncryption = true;
  List<Uint8List> _roundKeys = List<Uint8List>.empty();

  @override
  String get algorithmName => 'Kuznyechik';

  @override
  int get blockSize => _blockSize;

  @override
  void init(bool forEncryption, pc.CipherParameters? params) {
    if (params is! pc.KeyParameter) {
      throw ArgumentError.value(params, 'params');
    }
    final key = params.key;
    if (key.length != _keySize) {
      throw ArgumentError.value(key.length, 'key.length');
    }
    _forEncryption = forEncryption;
    _roundKeys = _makeRoundKeys(key);
  }

  @override
  Uint8List process(Uint8List data) {
    final out = Uint8List(blockSize);
    processBlock(data, 0, out, 0);
    return out;
  }

  @override
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if (_roundKeys.isEmpty) {
      throw StateError('Kuznyechik engine is not initialized.');
    }
    if (inpOff < 0 || inpOff + _blockSize > inp.length) {
      throw ArgumentError.value(inpOff, 'inpOff');
    }
    if (outOff < 0 || outOff + _blockSize > out.length) {
      throw ArgumentError.value(outOff, 'outOff');
    }
    final block = Uint8List.sublistView(inp, inpOff, inpOff + _blockSize);
    final transformed = _forEncryption ? _encrypt(block) : _decrypt(block);
    out.setRange(outOff, outOff + _blockSize, transformed);
    return _blockSize;
  }

  @override
  void reset() {}

  Uint8List _encrypt(Uint8List block) {
    var state = Uint8List.fromList(block);
    for (var round = 0; round < 9; round += 1) {
      state = _xorBlock(state, _roundKeys[round]);
      state = _sTransform(state, _sBox);
      state = _lTransform(state);
    }
    return _xorBlock(state, _roundKeys[9]);
  }

  Uint8List _decrypt(Uint8List block) {
    var state = _xorBlock(block, _roundKeys[9]);
    for (var round = 8; round >= 0; round -= 1) {
      state = _inverseLTransform(state);
      state = _sTransform(state, _inverseSBox);
      state = _xorBlock(state, _roundKeys[round]);
    }
    return state;
  }

  static List<Uint8List> _makeRoundKeys(Uint8List key) {
    var left = Uint8List.sublistView(key, 0, 16);
    var right = Uint8List.sublistView(key, 16, 32);
    final keys = <Uint8List>[
      Uint8List.fromList(left),
      Uint8List.fromList(right),
    ];
    for (var group = 0; group < 4; group += 1) {
      for (var step = 1; step <= 8; step += 1) {
        final constant = Uint8List(16)..[15] = group * 8 + step;
        final transformed = _lTransform(
          _sTransform(_xorBlock(left, _lTransform(constant)), _sBox),
        );
        final nextLeft = _xorBlock(transformed, right);
        right = left;
        left = nextLeft;
      }
      keys
        ..add(Uint8List.fromList(left))
        ..add(Uint8List.fromList(right));
    }
    return keys;
  }

  static Uint8List _sTransform(Uint8List block, List<int> box) {
    return Uint8List.fromList(block.map((byte) => box[byte]).toList());
  }

  static Uint8List _lTransform(Uint8List block) {
    var result = Uint8List.fromList(block);
    for (var index = 0; index < 16; index += 1) {
      result = _rTransform(result);
    }
    return result;
  }

  static Uint8List _inverseLTransform(Uint8List block) {
    var result = Uint8List.fromList(block);
    for (var index = 0; index < 16; index += 1) {
      result = _inverseRTransform(result);
    }
    return result;
  }

  static Uint8List _rTransform(Uint8List block) {
    var value = 0;
    for (var index = 0; index < 16; index += 1) {
      value ^= _gfMultiply(block[index], _linearVector[index]);
    }
    final result = Uint8List(16);
    result[0] = value;
    for (var index = 1; index < 16; index += 1) {
      result[index] = block[index - 1];
    }
    return result;
  }

  static Uint8List _inverseRTransform(Uint8List block) {
    final result = Uint8List(16);
    for (var index = 0; index < 15; index += 1) {
      result[index] = block[index + 1];
    }
    var value = block[0];
    for (var index = 0; index < 15; index += 1) {
      value ^= _gfMultiply(result[index], _linearVector[index]);
    }
    result[15] = value;
    return result;
  }

  static Uint8List _xorBlock(Uint8List a, Uint8List b) {
    final result = Uint8List(16);
    for (var index = 0; index < 16; index += 1) {
      result[index] = a[index] ^ b[index];
    }
    return result;
  }

  static int _gfMultiply(int a, int b) {
    var x = a;
    var y = b;
    var result = 0;
    while (y > 0) {
      if ((y & 1) != 0) {
        result ^= x;
      }
      final carry = (x & 0x80) != 0;
      x = (x << 1) & 0xff;
      if (carry) {
        x ^= 0xc3;
      }
      y >>= 1;
    }
    return result & 0xff;
  }
}

class ToolboxVeraCryptBlake2sDigest implements pc.Digest {
  ToolboxVeraCryptBlake2sDigest();

  final BytesBuilder _buffer = BytesBuilder(copy: false);

  @override
  String get algorithmName => 'BLAKE2s-256';

  @override
  int get byteLength => 64;

  @override
  int get digestSize => 32;

  @override
  Uint8List process(Uint8List data) {
    reset();
    update(data, 0, data.length);
    final out = Uint8List(digestSize);
    doFinal(out, 0);
    return out;
  }

  @override
  void reset() {
    _buffer.clear();
  }

  @override
  void updateByte(int inp) {
    _buffer.addByte(inp & 0xff);
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    _checkDigestInputRange(inp, inpOff, len);
    _buffer.add(Uint8List.sublistView(inp, inpOff, inpOff + len));
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    final digest = _blake2s(_buffer.toBytes());
    _checkDigestOutputRange(out, outOff, digest.length);
    out.setRange(outOff, outOff + digest.length, digest);
    reset();
    return digest.length;
  }

  static Uint8List _blake2s(Uint8List input) {
    const mask32 = 0xffffffff;
    const iv = <int>[
      0x6a09e667,
      0xbb67ae85,
      0x3c6ef372,
      0xa54ff53a,
      0x510e527f,
      0x9b05688c,
      0x1f83d9ab,
      0x5be0cd19,
    ];
    const sigma = <List<int>>[
      <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
      <int>[14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
      <int>[11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
      <int>[7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
      <int>[9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
      <int>[2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
      <int>[12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
      <int>[13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
      <int>[6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
      <int>[10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
    ];
    final h = List<int>.from(iv)..[0] = iv[0] ^ 0x01010020;
    var t0 = 0;
    var t1 = 0;
    var offset = 0;
    while (input.length - offset > 64) {
      t0 = (t0 + 64) & mask32;
      if (t0 < 64) {
        t1 = (t1 + 1) & mask32;
      }
      _compressBlake2s(
        h: h,
        block: Uint8List.sublistView(input, offset, offset + 64),
        t0: t0,
        t1: t1,
        last: false,
        iv: iv,
        sigma: sigma,
      );
      offset += 64;
    }
    final last = Uint8List(64);
    final remaining = input.length - offset;
    last.setRange(0, remaining, Uint8List.sublistView(input, offset));
    t0 = (t0 + remaining) & mask32;
    if (t0 < remaining) {
      t1 = (t1 + 1) & mask32;
    }
    _compressBlake2s(
      h: h,
      block: last,
      t0: t0,
      t1: t1,
      last: true,
      iv: iv,
      sigma: sigma,
    );
    final out = Uint8List(32);
    for (var index = 0; index < 8; index += 1) {
      _writeLe32(out, index * 4, h[index]);
    }
    return out;
  }

  static void _compressBlake2s({
    required List<int> h,
    required Uint8List block,
    required int t0,
    required int t1,
    required bool last,
    required List<int> iv,
    required List<List<int>> sigma,
  }) {
    const mask32 = 0xffffffff;
    final m = List<int>.generate(16, (index) => _readLe32(block, index * 4));
    final v = List<int>.filled(16, 0);
    for (var index = 0; index < 8; index += 1) {
      v[index] = h[index];
      v[index + 8] = iv[index];
    }
    v[12] ^= t0;
    v[13] ^= t1;
    if (last) {
      v[14] ^= mask32;
    }

    void g(int a, int b, int c, int d, int x, int y) {
      v[a] = (v[a] + v[b] + x) & mask32;
      v[d] = _rotr32(v[d] ^ v[a], 16);
      v[c] = (v[c] + v[d]) & mask32;
      v[b] = _rotr32(v[b] ^ v[c], 12);
      v[a] = (v[a] + v[b] + y) & mask32;
      v[d] = _rotr32(v[d] ^ v[a], 8);
      v[c] = (v[c] + v[d]) & mask32;
      v[b] = _rotr32(v[b] ^ v[c], 7);
    }

    for (var round = 0; round < 10; round += 1) {
      final s = sigma[round];
      g(0, 4, 8, 12, m[s[0]], m[s[1]]);
      g(1, 5, 9, 13, m[s[2]], m[s[3]]);
      g(2, 6, 10, 14, m[s[4]], m[s[5]]);
      g(3, 7, 11, 15, m[s[6]], m[s[7]]);
      g(0, 5, 10, 15, m[s[8]], m[s[9]]);
      g(1, 6, 11, 12, m[s[10]], m[s[11]]);
      g(2, 7, 8, 13, m[s[12]], m[s[13]]);
      g(3, 4, 9, 14, m[s[14]], m[s[15]]);
    }
    for (var index = 0; index < 8; index += 1) {
      h[index] = (h[index] ^ v[index] ^ v[index + 8]) & mask32;
    }
  }

  static int _readLe32(Uint8List bytes, int offset) {
    return (bytes[offset] |
            (bytes[offset + 1] << 8) |
            (bytes[offset + 2] << 16) |
            (bytes[offset + 3] << 24)) &
        0xffffffff;
  }

  static void _writeLe32(Uint8List bytes, int offset, int value) {
    bytes[offset] = value & 0xff;
    bytes[offset + 1] = (value >> 8) & 0xff;
    bytes[offset + 2] = (value >> 16) & 0xff;
    bytes[offset + 3] = (value >> 24) & 0xff;
  }

  static int _rotr32(int value, int shift) {
    final normalized = value & 0xffffffff;
    return ((normalized >> shift) |
            ((normalized << (32 - shift)) & 0xffffffff)) &
        0xffffffff;
  }
}

class ToolboxVeraCryptStreebog512Digest implements pc.Digest {
  ToolboxVeraCryptStreebog512Digest();

  static const List<int> _tau = <int>[
    0,
    8,
    16,
    24,
    32,
    40,
    48,
    56,
    1,
    9,
    17,
    25,
    33,
    41,
    49,
    57,
    2,
    10,
    18,
    26,
    34,
    42,
    50,
    58,
    3,
    11,
    19,
    27,
    35,
    43,
    51,
    59,
    4,
    12,
    20,
    28,
    36,
    44,
    52,
    60,
    5,
    13,
    21,
    29,
    37,
    45,
    53,
    61,
    6,
    14,
    22,
    30,
    38,
    46,
    54,
    62,
    7,
    15,
    23,
    31,
    39,
    47,
    55,
    63,
  ];
  static const List<int> _a = <int>[
    0x8e20faa72ba0b470,
    0x47107ddd9b505a38,
    0xad08b0e0c3282d1c,
    0xd8045870ef14980e,
    0x6c022c38f90a4c07,
    0x3601161cf205268d,
    0x1b8e0b0e798c13c8,
    0x83478b07b2468764,
    0xa011d380818e8f40,
    0x5086e740ce47c920,
    0x2843fd2067adea10,
    0x14aff010bdd87508,
    0x0ad97808d06cb404,
    0x05e23c0468365a02,
    0x8c711e02341b2d01,
    0x46b60f011a83988e,
    0x90dab52a387ae76f,
    0x486dd4151c3dfdb9,
    0x24b86a840e90f0d2,
    0x125c354207487869,
    0x092e94218d243cba,
    0x8a174a9ec8121e5d,
    0x4585254f64090fa0,
    0xaccc9ca9328a8950,
    0x9d4df05d5f661451,
    0xc0a878a0a1330aa6,
    0x60543c50de970553,
    0x302a1e286fc58ca7,
    0x18150f14b9ec46dd,
    0x0c84890ad27623e0,
    0x0642ca05693b9f70,
    0x0321658cba93c138,
    0x86275df09ce8aaa8,
    0x439da0784e745554,
    0xafc0503c273aa42a,
    0xd960281e9d1d5215,
    0xe230140fc0802984,
    0x71180a8960409a42,
    0xb60c05ca30204d21,
    0x5b068c651810a89e,
    0x456c34887a3805b9,
    0xac361a443d1c8cd2,
    0x561b0d22900e4669,
    0x2b838811480723ba,
    0x9bcf4486248d9f5d,
    0xc3e9224312c8c1a0,
    0xeffa11af0964ee50,
    0xf97d86d98a327728,
    0xe4fa2054a80b329c,
    0x727d102a548b194e,
    0x39b008152acb8227,
    0x9258048415eb419d,
    0x492c024284fbaec0,
    0xaa16012142f35760,
    0x550b8e9e21f7a530,
    0xa48b474f9ef5dc18,
    0x70a6a56e2440598e,
    0x3853dc371220a247,
    0x1ca76e95091051ad,
    0x0edd37c48a08a6d8,
    0x07e095624504536c,
    0x8d70c431ac02a736,
    0xc83862965601dd1b,
    0x641c314b2b8ee083,
  ];
  static final List<Uint8List> _c = <String>[
    'b1085bda1ecadae9ebcb2f81c0657c1f2f6a76432e45d016714eb88d7585c4fc4b7ce09192676901a2422a08a460d31505767436cc744d23dd806559f2a64507',
    '6fa3b58aa99d2f1a4fe39d460f70b5d7f3feea720a232b9861d55e0f16b501319ab5176b12d699585cb561c2db0aa7ca55dda21bd7cbcd56e679047021b19bb7',
    'f574dcac2bce2fc70a39fc286a3d843506f15e5f529c1f8bf2ea7514b1297b7bd3e20fe490359eb1c1c93a376062db09c2b6f443867adb31991e96f50aba0ab2',
    'ef1fdfb3e81566d2f948e1a05d71e4dd488e857e335c3c7d9d721cad685e353fa9d72c82ed03d675d8b71333935203be3453eaa193e837f1220cbebc84e3d12e',
    '4bea6bacad4747999a3f410c6ca923637f151c1f1686104a359e35d7800fffbdbfcd1747253af5a3dfff00b723271a167a56a27ea9ea63f5601758fd7c6cfe57',
    'ae4faeae1d3ad3d96fa4c33b7a3039c02d66c4f95142a46c187f9ab49af08ec6cffaa6b71c9ab7b40af21f66c2bec6b6bf71c57236904f35fa68407a46647d6e',
    'f4c70e16eeaac5ec51ac86febf240954399ec6c7e6bf87c9d3473e33197a93c90992abc52d822c3706476983284a05043517454ca23c4af38886564d3a14d493',
    '9b1f5b424d93c9a703e7aa020c6e41414eb7f8719c36de1e89b4443b4ddbc49af4892bcb929b069069d18d2bd1a5c42f36acc2355951a8d9a47f0dd4bf02e71e',
    '378f5a541631229b944c9ad8ec165fde3a7d3a1b258942243cd955b7e00d0984800a440bdbb2ceb17b2b8a9aa6079c540e38dc92cb1f2a607261445183235adb',
    'abbedea680056f52382ae548b2e4f3f38941e71cff8a78db1fffe18a1b3361039fe76702af69334b7a1e6c303b7652f43698fad1153bb6c374b4c7fb98459ced',
    '7bcd9ed0efc889fb3002c6cd635afe94d8fa6bbbebab076120018021148466798a1d71efea48b9caefbacd1d7d476e98dea2594ac06fd85d6bcaa4cd81f32d1b',
    '378ee767f11631bad21380b00449b17acda43c32bcdf1d77f82012d430219f9b5d80ef9d1891cc86e71da4aa88e12852faf417d5d9b21b9948bc924af11bd720',
  ].map(_hexToBytes).toList(growable: false);

  final BytesBuilder _buffer = BytesBuilder(copy: false);

  @override
  String get algorithmName => 'Streebog-512';

  @override
  int get byteLength => 64;

  @override
  int get digestSize => 64;

  @override
  Uint8List process(Uint8List data) {
    reset();
    update(data, 0, data.length);
    final out = Uint8List(digestSize);
    doFinal(out, 0);
    return out;
  }

  @override
  void reset() {
    _buffer.clear();
  }

  @override
  void updateByte(int inp) {
    _buffer.addByte(inp & 0xff);
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    _checkDigestInputRange(inp, inpOff, len);
    _buffer.add(Uint8List.sublistView(inp, inpOff, inpOff + len));
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    final digest = _hash(_buffer.toBytes());
    _checkDigestOutputRange(out, outOff, digest.length);
    out.setRange(outOff, outOff + digest.length, digest);
    reset();
    return digest.length;
  }

  static Uint8List _hash(Uint8List input) {
    var h = Uint8List(64);
    var n = Uint8List(64);
    var sigma = Uint8List(64);
    var offset = 0;
    while (input.length - offset >= 64) {
      final block = Uint8List.sublistView(input, offset, offset + 64);
      h = _g(h, n, block);
      n = _add512(n, _bitLengthBlock(512));
      sigma = _add512(sigma, block);
      offset += 64;
    }
    final remaining = input.length - offset;
    final last = Uint8List(64);
    last.setRange(64 - remaining, 64, Uint8List.sublistView(input, offset));
    last[63 - remaining] = 0x01;
    h = _g(h, n, last);
    n = _add512(n, _bitLengthBlock(remaining * 8));
    sigma = _add512(sigma, last);
    h = _g(h, Uint8List(64), n);
    h = _g(h, Uint8List(64), sigma);
    return h;
  }

  static Uint8List _g(Uint8List h, Uint8List n, Uint8List m) {
    final key = _lps(_xor(h, n));
    final encrypted = _e(key, m);
    return _xor(_xor(encrypted, h), m);
  }

  static Uint8List _e(Uint8List key, Uint8List message) {
    var state = Uint8List.fromList(message);
    var roundKey = Uint8List.fromList(key);
    for (var round = 0; round < 12; round += 1) {
      state = _lps(_xor(state, roundKey));
      roundKey = _lps(_xor(roundKey, _c[round]));
    }
    return _xor(state, roundKey);
  }

  static Uint8List _lps(Uint8List block) {
    final substituted = Uint8List.fromList(
      block
          .map((byte) => ToolboxVeraCryptKuznyechikEngine._sBox[byte])
          .toList(),
    );
    final permuted = Uint8List(64);
    for (var index = 0; index < 64; index += 1) {
      permuted[index] = substituted[_tau[index]];
    }
    final result = Uint8List(64);
    for (var chunk = 0; chunk < 8; chunk += 1) {
      var value = 0;
      for (var byteIndex = 0; byteIndex < 8; byteIndex += 1) {
        final byte = permuted[chunk * 8 + byteIndex];
        for (var bit = 0; bit < 8; bit += 1) {
          if ((byte & (1 << (7 - bit))) != 0) {
            value ^= _a[byteIndex * 8 + bit];
          }
        }
      }
      _writeBe64(result, chunk * 8, value);
    }
    return result;
  }

  static Uint8List _xor(Uint8List a, Uint8List b) {
    final result = Uint8List(a.length);
    for (var index = 0; index < a.length; index += 1) {
      result[index] = a[index] ^ b[index];
    }
    return result;
  }

  static Uint8List _add512(Uint8List a, Uint8List b) {
    final result = Uint8List(64);
    var carry = 0;
    for (var index = 63; index >= 0; index -= 1) {
      final sum = a[index] + b[index] + carry;
      result[index] = sum & 0xff;
      carry = sum >> 8;
    }
    return result;
  }

  static Uint8List _bitLengthBlock(int bitLength) {
    final result = Uint8List(64);
    var value = bitLength;
    for (var index = 63; index >= 0; index -= 1) {
      result[index] = value & 0xff;
      value >>= 8;
    }
    return result;
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var index = 0; index < result.length; index += 1) {
      result[index] = int.parse(
        hex.substring(index * 2, index * 2 + 2),
        radix: 16,
      );
    }
    return result;
  }

  static void _writeBe64(Uint8List out, int offset, int value) {
    for (var index = 7; index >= 0; index -= 1) {
      out[offset + index] = value & 0xff;
      value >>= 8;
    }
  }
}
