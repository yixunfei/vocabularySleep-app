import 'dart:math' as math;

const List<int> schulteBoardSizes = <int>[4, 5, 6, 8];
const List<int> schulteCountdownOptions = <int>[20, 30, 45, 60, 90, 120];
const List<int> schulteJumpOptions = <int>[30, 45, 60, 90, 120];

const int schulteMinDynamicBoardSize = 2;
const int schulteMaxDynamicBoardSize = 12;

final RegExp _schulteWordSplitPattern = RegExp(r'[\s,，、;；:：/\\|。.!！？?]+');

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
    return switch (id.trim().toLowerCase()) {
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
    return switch (id.trim().toLowerCase()) {
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
    return switch (id.trim().toLowerCase()) {
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
    return switch (id.trim().toLowerCase()) {
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
  for (final option in schulteBoardSizes.skip(1)) {
    final nextDistance = (option - value).abs();
    if (nextDistance < distance) {
      candidate = option;
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

int schulteVisibleCustomTokenLimit({required SchulteBoardShape shape}) {
  return buildSchulteActiveSlots(
    size: schulteMaxDynamicBoardSize,
    shape: shape,
    allowDynamicSize: true,
  ).length;
}

List<int> buildSchulteActiveSlots({
  required int size,
  required SchulteBoardShape shape,
  bool allowDynamicSize = false,
}) {
  final resolvedSize = allowDynamicSize
      ? size.clamp(schulteMinDynamicBoardSize, schulteMaxDynamicBoardSize)
      : sanitizeSchulteBoardSize(size);

  if (shape == SchulteBoardShape.square) {
    return List<int>.generate(
      resolvedSize * resolvedSize,
      (index) => index,
      growable: false,
    );
  }

  final result = <int>[];
  for (var row = 0; row < resolvedSize; row += 1) {
    for (var column = 0; column < resolvedSize; column += 1) {
      if (_isShapeSlotActive(
        size: resolvedSize,
        row: row,
        column: column,
        shape: shape,
      )) {
        result.add(row * resolvedSize + column);
      }
    }
  }

  if (result.isEmpty) {
    return List<int>.generate(
      resolvedSize * resolvedSize,
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
  int? maxCustomTokenCount,
}) {
  final customTokens = sourceMode == SchulteSourceMode.custom
      ? buildSchulteContentTokens(
          customText,
          splitMode: splitMode,
          stripWhitespace: stripWhitespace,
          ignorePunctuation: ignorePunctuation,
          maxTokens: maxCustomTokenCount,
        )
      : const <String>[];

  final resolvedSize = sourceMode == SchulteSourceMode.custom
      ? resolveSchulteCustomBoardSize(
          tokenCount: customTokens.length,
          shape: shape,
        )
      : sanitizeSchulteBoardSize(size);

  final shapeSlots = buildSchulteActiveSlots(
    size: resolvedSize,
    shape: shape,
    allowDynamicSize: sourceMode == SchulteSourceMode.custom,
  );

  final sequence = sourceMode == SchulteSourceMode.custom
      ? customTokens
      : buildSchulteSequence(
          cellCount: shapeSlots.length,
          sourceMode: sourceMode,
          customText: customText,
          splitMode: splitMode,
          stripWhitespace: stripWhitespace,
          ignorePunctuation: ignorePunctuation,
          maxCustomTokenCount: maxCustomTokenCount,
        );

  final activeSlots =
      sourceMode == SchulteSourceMode.custom &&
          sequence.isNotEmpty &&
          sequence.length < shapeSlots.length
      ? _selectCustomSlots(shapeSlots, sequence.length, random)
      : shapeSlots.take(sequence.length).toList(growable: false);

  final shuffled = List<String>.from(sequence)..shuffle(random);
  final slotTokens = List<String?>.filled(
    resolvedSize * resolvedSize,
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
        row: slotIndex ~/ resolvedSize,
        column: slotIndex % resolvedSize,
        token: token,
      ),
    );
  }

  return SchulteBoardData(
    size: resolvedSize,
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
  int? maxCustomTokenCount,
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

  final tokens = buildSchulteContentTokens(
    customText,
    splitMode: splitMode,
    stripWhitespace: stripWhitespace,
    ignorePunctuation: ignorePunctuation,
    maxTokens: maxCustomTokenCount,
  );
  if (tokens.isEmpty) {
    return const <String>[];
  }

  return tokens
      .take(math.min(cellCount, tokens.length))
      .toList(growable: false);
}

List<String> buildSchulteContentTokens(
  String rawText, {
  required SchulteContentSplitMode splitMode,
  required bool stripWhitespace,
  required bool ignorePunctuation,
  int? maxTokens,
}) {
  if (rawText.trim().isEmpty) {
    return const <String>[];
  }

  final rawTokens = switch (splitMode) {
    SchulteContentSplitMode.character =>
      rawText.runes
          .map((codePoint) => String.fromCharCode(codePoint))
          .toList(growable: false),
    SchulteContentSplitMode.word => rawText.split(_schulteWordSplitPattern),
  };

  final normalized = rawTokens
      .map(
        (token) => normalizeSchulteToken(
          token,
          stripWhitespace: stripWhitespace,
          ignorePunctuation: ignorePunctuation,
        ),
      )
      .where((token) => token.isNotEmpty)
      .toList(growable: false);

  if (maxTokens == null || maxTokens <= 0 || normalized.length <= maxTokens) {
    return normalized;
  }
  return normalized.take(maxTokens).toList(growable: false);
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
  int? maxTokens,
}) {
  if (sourceMode == SchulteSourceMode.numbers) {
    return 'numbers';
  }

  final normalizedTokens = buildSchulteContentTokens(
    customText,
    splitMode: splitMode,
    stripWhitespace: stripWhitespace,
    ignorePunctuation: ignorePunctuation,
    maxTokens: maxTokens,
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
  final normalizedSize = size.clamp(
    schulteMinDynamicBoardSize,
    schulteMaxDynamicBoardSize,
  );
  return '${mode.id}|${shape.id}|$normalizedSize|'
      '$durationSeconds|${sourceMode.id}|$contentSignature';
}

int resolveSchulteCustomBoardSize({
  required int tokenCount,
  required SchulteBoardShape shape,
}) {
  if (tokenCount <= 0) {
    return schulteMinDynamicBoardSize;
  }

  for (
    var size = schulteMinDynamicBoardSize;
    size <= schulteMaxDynamicBoardSize;
    size += 1
  ) {
    final activeCount = buildSchulteActiveSlots(
      size: size,
      shape: shape,
      allowDynamicSize: true,
    ).length;
    if (activeCount >= tokenCount) {
      return size;
    }
  }

  return schulteMaxDynamicBoardSize;
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

List<int> _selectCustomSlots(
  List<int> source,
  int targetCount,
  math.Random random,
) {
  if (targetCount >= source.length) {
    return List<int>.from(source, growable: false);
  }

  final shuffled = List<int>.from(source)..shuffle(random);
  final result = shuffled.take(targetCount).toList(growable: false)..sort();
  return result;
}
