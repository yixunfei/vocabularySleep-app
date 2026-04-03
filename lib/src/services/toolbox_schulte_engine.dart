import 'dart:math' as math;

const List<int> schulteBoardSizes = <int>[4, 5, 6, 8];
const List<int> schulteCountdownOptions = <int>[20, 30, 45, 60, 90, 120];
const List<int> schulteJumpOptions = <int>[30, 45, 60, 90, 120];

const String _schultePunctuationChars =
    '!"#\$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'
    '\uFF0C\u3002\uFF01\uFF1F\uFF1B\uFF1A'
    '\u3001\uFF08\uFF09\u300A\u300B\u3010\u3011'
    '\u300C\u300D\u300E\u300F\u201C\u201D\u2018\u2019'
    '\u00B7\u2014\u2026';

enum SchulteBoardShape {
  square('square'),
  triangle('triangle'),
  cross('cross'),
  diamond('diamond'),
  ring('ring');

  const SchulteBoardShape(this.id);

  final String id;

  static SchulteBoardShape fromId(String id) {
    return switch (id.trim()) {
      'triangle' => SchulteBoardShape.triangle,
      'cross' => SchulteBoardShape.cross,
      'diamond' => SchulteBoardShape.diamond,
      'ring' => SchulteBoardShape.ring,
      'classic' ||
      'rounded' ||
      'circle' ||
      'hexagon' => SchulteBoardShape.square,
      _ => SchulteBoardShape.square,
    };
  }
}

enum SchultePlayMode {
  timer('timer'),
  countdown('countdown'),
  jump('jump');

  const SchultePlayMode(this.id);

  final String id;

  bool get isTimed => this != SchultePlayMode.timer;

  static SchultePlayMode fromId(String id) {
    return switch (id.trim()) {
      'countdown' => SchultePlayMode.countdown,
      'jump' || 'time_attack' => SchultePlayMode.jump,
      'classic' || 'timer' => SchultePlayMode.timer,
      _ => SchultePlayMode.timer,
    };
  }
}

enum SchulteSourceMode {
  numbers('numbers'),
  custom('custom');

  const SchulteSourceMode(this.id);

  final String id;

  static SchulteSourceMode fromId(String id) {
    return switch (id.trim()) {
      'content' || 'custom' => SchulteSourceMode.custom,
      _ => SchulteSourceMode.numbers,
    };
  }
}

enum SchulteContentSplitMode {
  character('character'),
  word('word');

  const SchulteContentSplitMode(this.id);

  final String id;

  static SchulteContentSplitMode fromId(String id) {
    return switch (id.trim()) {
      'word' || 'line' => SchulteContentSplitMode.word,
      _ => SchulteContentSplitMode.character,
    };
  }
}

class SchulteBoardCell {
  const SchulteBoardCell({
    required this.slotIndex,
    required this.row,
    required this.column,
    required this.token,
  });

  final int slotIndex;
  final int row;
  final int column;
  final String token;
}

class SchulteBoardData {
  const SchulteBoardData({
    required this.size,
    required this.shape,
    required this.activeSlots,
    required this.sequence,
    required this.slotTokens,
    required this.cells,
  });

  final int size;
  final SchulteBoardShape shape;
  final List<int> activeSlots;
  final List<String> sequence;
  final List<String?> slotTokens;
  final List<SchulteBoardCell> cells;

  int get activeCount => activeSlots.length;
}

int sanitizeSchulteBoardSize(int value) {
  if (schulteBoardSizes.contains(value)) {
    return value;
  }
  if (value <= schulteBoardSizes.first) {
    return schulteBoardSizes.first;
  }
  if (value >= schulteBoardSizes.last) {
    return schulteBoardSizes.last;
  }
  var candidate = schulteBoardSizes.first;
  var distance = (candidate - value).abs();
  for (final size in schulteBoardSizes.skip(1)) {
    final nextDistance = (size - value).abs();
    if (nextDistance < distance) {
      candidate = size;
      distance = nextDistance;
    }
  }
  return candidate;
}

int sanitizeSchulteCountdownSeconds(int value) {
  if (schulteCountdownOptions.contains(value)) {
    return value;
  }
  return _nearestOption(value, schulteCountdownOptions);
}

int sanitizeSchulteJumpSeconds(int value) {
  if (schulteJumpOptions.contains(value)) {
    return value;
  }
  return _nearestOption(value, schulteJumpOptions);
}

List<int> buildSchulteActiveSlots({
  required int size,
  required SchulteBoardShape shape,
}) {
  final sanitizedSize = sanitizeSchulteBoardSize(size);
  if (shape == SchulteBoardShape.square) {
    return List<int>.generate(
      sanitizedSize * sanitizedSize,
      (index) => index,
      growable: false,
    );
  }

  final result = <int>[];
  for (var row = 0; row < sanitizedSize; row += 1) {
    for (var column = 0; column < sanitizedSize; column += 1) {
      if (_isShapeSlotActive(
        size: sanitizedSize,
        row: row,
        column: column,
        shape: shape,
      )) {
        result.add(row * sanitizedSize + column);
      }
    }
  }
  if (result.isEmpty) {
    return List<int>.generate(
      sanitizedSize * sanitizedSize,
      (index) => index,
      growable: false,
    );
  }
  return result;
}

SchulteBoardData buildSchulteBoard({
  required int size,
  required SchulteBoardShape shape,
  required SchulteSourceMode sourceMode,
  required String customText,
  required SchulteContentSplitMode splitMode,
  required bool stripWhitespace,
  required bool ignorePunctuation,
  required math.Random random,
}) {
  final sanitizedSize = sanitizeSchulteBoardSize(size);
  final activeSlots = buildSchulteActiveSlots(
    size: sanitizedSize,
    shape: shape,
  );
  final sequence = buildSchulteSequence(
    cellCount: activeSlots.length,
    sourceMode: sourceMode,
    customText: customText,
    splitMode: splitMode,
    stripWhitespace: stripWhitespace,
    ignorePunctuation: ignorePunctuation,
  );

  final shuffled = List<String>.from(sequence)..shuffle(random);
  final slotTokens = List<String?>.filled(
    sanitizedSize * sanitizedSize,
    null,
    growable: false,
  );
  final cells = <SchulteBoardCell>[];
  for (var index = 0; index < shuffled.length; index += 1) {
    final slotIndex = activeSlots[index];
    final token = shuffled[index];
    slotTokens[slotIndex] = token;
    cells.add(
      SchulteBoardCell(
        slotIndex: slotIndex,
        row: slotIndex ~/ sanitizedSize,
        column: slotIndex % sanitizedSize,
        token: token,
      ),
    );
  }

  return SchulteBoardData(
    size: sanitizedSize,
    shape: shape,
    activeSlots: activeSlots,
    sequence: sequence,
    slotTokens: slotTokens,
    cells: cells,
  );
}

List<String> buildSchulteSequence({
  required int cellCount,
  required SchulteSourceMode sourceMode,
  required String customText,
  required SchulteContentSplitMode splitMode,
  required bool stripWhitespace,
  required bool ignorePunctuation,
}) {
  if (cellCount <= 0) {
    return const <String>[];
  }
  if (sourceMode == SchulteSourceMode.numbers) {
    return List<String>.generate(
      cellCount,
      (index) => '${index + 1}',
      growable: false,
    );
  }

  final sourceTokens = buildSchulteContentTokens(
    customText,
    splitMode: splitMode,
    stripWhitespace: stripWhitespace,
    ignorePunctuation: ignorePunctuation,
  );
  if (sourceTokens.isEmpty) {
    return const <String>[];
  }

  return List<String>.generate(
    cellCount,
    (index) => sourceTokens[index % sourceTokens.length],
    growable: false,
  );
}

List<String> buildSchulteContentTokens(
  String rawText, {
  required SchulteContentSplitMode splitMode,
  required bool stripWhitespace,
  required bool ignorePunctuation,
}) {
  if (rawText.trim().isEmpty) {
    return const <String>[];
  }

  final rawTokens = switch (splitMode) {
    SchulteContentSplitMode.character =>
      rawText.runes
          .map((codePoint) => String.fromCharCode(codePoint))
          .toList(growable: false),
    SchulteContentSplitMode.word => rawText.split(RegExp(r'\s+')),
  };

  return rawTokens
      .map(
        (token) => normalizeSchulteToken(
          token,
          stripWhitespace: stripWhitespace,
          ignorePunctuation: ignorePunctuation,
        ),
      )
      .where((token) => token.isNotEmpty)
      .toList(growable: false);
}

String normalizeSchulteToken(
  String raw, {
  required bool stripWhitespace,
  required bool ignorePunctuation,
}) {
  var value = raw;
  if (ignorePunctuation) {
    final buffer = StringBuffer();
    for (final codePoint in value.runes) {
      final char = String.fromCharCode(codePoint);
      if (!_schultePunctuationChars.contains(char)) {
        buffer.write(char);
      }
    }
    value = buffer.toString();
  }
  if (stripWhitespace) {
    value = value.trim();
  }
  return value;
}

String buildSchulteContentSignature({
  required SchulteSourceMode sourceMode,
  required String customText,
  required SchulteContentSplitMode splitMode,
  required bool stripWhitespace,
  required bool ignorePunctuation,
}) {
  if (sourceMode == SchulteSourceMode.numbers) {
    return 'numbers';
  }

  final normalizedTokens = buildSchulteContentTokens(
    customText,
    splitMode: splitMode,
    stripWhitespace: stripWhitespace,
    ignorePunctuation: ignorePunctuation,
  );
  final payload = normalizedTokens.isEmpty
      ? 'empty'
      : normalizedTokens.join('\u0001');
  final signatureSource =
      '${splitMode.id}|${stripWhitespace ? 1 : 0}|'
      '${ignorePunctuation ? 1 : 0}|$payload';
  var hash = 2166136261;
  for (final unit in signatureSource.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash.toRadixString(16);
}

String buildSchulteRecordKey({
  required SchultePlayMode mode,
  required SchulteBoardShape shape,
  required int size,
  required int durationSeconds,
  required SchulteSourceMode sourceMode,
  required String contentSignature,
}) {
  return '${mode.id}|${shape.id}|${sanitizeSchulteBoardSize(size)}|'
      '$durationSeconds|${sourceMode.id}|$contentSignature';
}

bool _isShapeSlotActive({
  required int size,
  required int row,
  required int column,
  required SchulteBoardShape shape,
}) {
  final x = ((column + 0.5) / size) * 2 - 1;
  final y = ((row + 0.5) / size) * 2 - 1;
  switch (shape) {
    case SchulteBoardShape.square:
      return true;
    case SchulteBoardShape.triangle:
      return y >= (2 * x.abs()) - 1.3;
    case SchulteBoardShape.cross:
      final arm = size <= 4 ? 0.33 : 0.28;
      return x.abs() <= arm || y.abs() <= arm;
    case SchulteBoardShape.diamond:
      return x.abs() + y.abs() <= 1.05;
    case SchulteBoardShape.ring:
      final distance = math.sqrt((x * x) + (y * y));
      return distance <= 1.05 && distance >= 0.38;
  }
}

int _nearestOption(int value, List<int> options) {
  var candidate = options.first;
  var distance = (candidate - value).abs();
  for (final option in options.skip(1)) {
    final nextDistance = (option - value).abs();
    if (nextDistance < distance) {
      candidate = option;
      distance = nextDistance;
    }
  }
  return candidate;
}
