import 'toolbox_calculator_definitions.dart';
import 'toolbox_calculator_models.dart';

class ToolboxCalculatorSessionSnapshot {
  const ToolboxCalculatorSessionSnapshot({
    this.history = const <ToolboxCalculatorHistoryEntry>[],
    this.answerExpression,
    this.memoryExpression,
    this.result,
    this.angleUnit = ToolboxCalculatorAngleUnit.radian,
    this.definitions = const <ToolboxCalculatorDefinition>[],
  });

  static const int schemaVersion = 1;
  static const int maxHistoryEntries = 50;
  static const int maxExpressionLength = 48000;

  final List<ToolboxCalculatorHistoryEntry> history;
  final String? answerExpression;
  final String? memoryExpression;
  final ToolboxCalculatorResult? result;
  final ToolboxCalculatorAngleUnit angleUnit;
  final List<ToolboxCalculatorDefinition> definitions;

  factory ToolboxCalculatorSessionSnapshot.fromJsonValue(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid calculator session snapshot');
    }
    final map = value.cast<Object?, Object?>();
    if (map['version'] != schemaVersion) {
      throw const FormatException('Unsupported calculator session version');
    }
    final rawHistory = map['history'];
    final rawDefinitions = map['definitions'];
    if (rawHistory is! List ||
        rawHistory.length > maxHistoryEntries ||
        (rawDefinitions != null && rawDefinitions is! List)) {
      throw const FormatException('Invalid calculator session collections');
    }
    final history = rawHistory
        .map(ToolboxCalculatorHistoryEntry.fromJsonValue)
        .toList(growable: false);
    for (final entry in history) {
      if (entry.id < 0 ||
          entry.expression.length > maxExpressionLength ||
          entry.result.exact.length > maxExpressionLength ||
          entry.result.latex.length > maxExpressionLength ||
          (entry.result.approximate?.length ?? 0) > maxExpressionLength) {
        throw const FormatException('Calculator history entry is too large');
      }
      _validateResultParts(entry.result.parts);
    }
    final definitions = rawDefinitions is List
        ? rawDefinitions
              .map(ToolboxCalculatorDefinition.fromJsonValue)
              .toList(growable: false)
        : const <ToolboxCalculatorDefinition>[];
    const ToolboxCalculatorDefinitionValidator().validate(definitions);
    final rawResult = map['result'];
    ToolboxCalculatorResult? result;
    if (rawResult != null) {
      if (rawResult is! Map) {
        throw const FormatException('Invalid calculator active result');
      }
      final resultMap = rawResult.cast<String, Object?>();
      final operation = ToolboxCalculatorOperation.fromWireName(
        resultMap['operation'],
      );
      result = ToolboxCalculatorResult.fromJson(resultMap, operation);
      if (result.exact.length > maxExpressionLength ||
          result.latex.length > maxExpressionLength ||
          (result.approximate?.length ?? 0) > maxExpressionLength) {
        throw const FormatException('Calculator active result is too large');
      }
      _validateResultParts(result.parts);
    }
    return ToolboxCalculatorSessionSnapshot(
      history: history,
      answerExpression: _optionalExpression(map['answerExpression']),
      memoryExpression: _optionalExpression(map['memoryExpression']),
      result: result,
      angleUnit: ToolboxCalculatorAngleUnit.fromWireName(map['angleUnit']),
      definitions: definitions,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'version': schemaVersion,
      'history': history
          .take(maxHistoryEntries)
          .map((entry) => entry.toJson())
          .toList(growable: false),
      if (answerExpression != null) 'answerExpression': answerExpression,
      if (memoryExpression != null) 'memoryExpression': memoryExpression,
      if (result != null) 'result': result!.toJson(),
      'angleUnit': angleUnit.wireName,
      if (definitions.isNotEmpty)
        'definitions': definitions
            .map((definition) => definition.toJson())
            .toList(growable: false),
    };
  }

  static String? _optionalExpression(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    if (text.isEmpty) return null;
    if (text.length > maxExpressionLength) {
      throw const FormatException('Calculator session expression is too large');
    }
    return text;
  }

  static void _validateResultParts(List<ToolboxCalculatorResultPart> parts) {
    if (parts.length > 8 ||
        parts.any(
          (part) =>
              part.id.length > 32 ||
              part.exact.length > maxExpressionLength ||
              part.latex.length > maxExpressionLength ||
              (part.approximate?.length ?? 0) > maxExpressionLength,
        )) {
      throw const FormatException('Calculator result parts are too large');
    }
  }
}
