import 'dart:async';

import 'package:flutter/foundation.dart';

import '../toolbox_scientific_calculator_service.dart';
import 'toolbox_calculator_definitions.dart';
import 'toolbox_calculator_engine.dart';
import 'toolbox_calculator_models.dart';
import 'toolbox_calculator_session_persistence.dart';
import 'toolbox_calculator_session_snapshot.dart';
import 'toolbox_calculator_session_store.dart';

enum ToolboxCalculatorSessionStatus { idle, calculating, success, error }

class ToolboxCalculatorSessionController extends ChangeNotifier {
  ToolboxCalculatorSessionController({
    required this.engine,
    ToolboxScientificCalculatorService? numericCalculator,
    ToolboxCalculatorSessionStore? sessionStore,
  }) : _numericCalculator =
           numericCalculator ?? const ToolboxScientificCalculatorService(),
       _persistence = sessionStore == null
           ? null
           : ToolboxCalculatorSessionPersistence(sessionStore);

  final ToolboxCalculatorEngine engine;
  final ToolboxScientificCalculatorService _numericCalculator;
  final ToolboxCalculatorSessionPersistence? _persistence;
  final ToolboxCalculatorDefinitionValidator _definitionValidator =
      const ToolboxCalculatorDefinitionValidator();
  final List<ToolboxCalculatorHistoryEntry> _history =
      <ToolboxCalculatorHistoryEntry>[];
  final List<ToolboxCalculatorDefinition> _definitions =
      <ToolboxCalculatorDefinition>[];

  ToolboxCalculatorSessionStatus _status = ToolboxCalculatorSessionStatus.idle;
  ToolboxCalculatorResult? _result;
  ToolboxCalculatorEngineException? _error;
  String? _answerExpression;
  String? _memoryExpression;
  ToolboxCalculatorAngleUnit _angleUnit = ToolboxCalculatorAngleUnit.radian;
  bool _restoring = false;
  bool _disposed = false;
  int _generation = 0;
  int _historyId = 0;
  int _mutationRevision = 0;

  ToolboxCalculatorSessionStatus get status => _status;
  ToolboxCalculatorResult? get result => _result;
  ToolboxCalculatorEngineException? get error => _error;
  String? get answerExpression => _answerExpression;
  String? get memoryExpression => _memoryExpression;
  ToolboxCalculatorAngleUnit get angleUnit => _angleUnit;
  bool get degreeMode => _angleUnit == ToolboxCalculatorAngleUnit.degree;
  bool get isRestoring => _restoring;
  bool get isCalculating =>
      _status == ToolboxCalculatorSessionStatus.calculating;
  List<ToolboxCalculatorHistoryEntry> get history =>
      List<ToolboxCalculatorHistoryEntry>.unmodifiable(_history);
  List<ToolboxCalculatorDefinition> get definitions =>
      List<ToolboxCalculatorDefinition>.unmodifiable(_definitions);

  void markUserInteraction() {
    _markMutation();
    if (_cancelActiveCalculation()) _notify();
  }

  Future<void> restore() async {
    final persistence = _persistence;
    if (persistence == null || _disposed || _restoring) return;
    final revision = _mutationRevision;
    _restoring = true;
    _notify();
    try {
      final snapshot = await persistence.restore();
      if (snapshot == null || !_isRestoreCurrent(revision)) return;
      _history
        ..clear()
        ..addAll(snapshot.history.take(50));
      _definitions
        ..clear()
        ..addAll(snapshot.definitions);
      _answerExpression = snapshot.answerExpression;
      _memoryExpression = snapshot.memoryExpression;
      _angleUnit = snapshot.angleUnit;
      _result = snapshot.result;
      _status = _result == null
          ? ToolboxCalculatorSessionStatus.idle
          : ToolboxCalculatorSessionStatus.success;
      _historyId = _history.fold<int>(
        0,
        (maximum, entry) => entry.id > maximum ? entry.id : maximum,
      );
    } on Object {
      // A damaged or unavailable local snapshot must not block calculation.
    } finally {
      if (!_disposed) {
        _restoring = false;
        _notify();
      }
    }
  }

  void setDegreeMode(bool value) {
    if (degreeMode == value) return;
    _cancelActiveCalculation();
    _angleUnit = value
        ? ToolboxCalculatorAngleUnit.degree
        : ToolboxCalculatorAngleUnit.radian;
    _markPersistentMutation();
    _notify();
  }

  Future<void> evaluate(String expression) {
    return submit(
      ToolboxCalculatorRequest(
        operation: ToolboxCalculatorOperation.evaluate,
        expression: expression,
      ),
      expressionLabel: expression,
      allowNumericFallback: true,
    );
  }

  Future<void> submit(
    ToolboxCalculatorRequest request, {
    required String expressionLabel,
    bool allowNumericFallback = false,
  }) async {
    _markMutation();
    final generation = ++_generation;
    _status = ToolboxCalculatorSessionStatus.calculating;
    _error = null;
    _notify();
    try {
      final scopedRequest = request.withSessionContext(
        angleUnit: _angleUnit,
        substitutions: _sessionSubstitutions(),
        definitions: _definitions,
      );
      final nextResult = await engine.calculate(scopedRequest);
      if (!_isCurrent(generation)) return;
      _acceptResult(expressionLabel, nextResult);
    } on ToolboxCalculatorEngineException catch (error) {
      if (!_isCurrent(generation)) return;
      if (allowNumericFallback && _canUseNumericFallback(error, request)) {
        _evaluateNumerically(request.expression!, expressionLabel, generation);
        return;
      }
      _status = ToolboxCalculatorSessionStatus.error;
      _error = error;
      _notify();
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      _status = ToolboxCalculatorSessionStatus.error;
      _error = ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.computation,
        technicalMessage: error.toString(),
      );
      _notify();
    }
  }

  void acceptNumericResult({
    required ToolboxCalculatorOperation operation,
    required String expressionLabel,
    required num value,
  }) {
    if (!value.isFinite) {
      reportError(
        ToolboxCalculatorFailureCode.computation,
        const FormatException('Numeric result is not finite'),
      );
      return;
    }
    _generation += 1;
    final exact = _numericCalculator.formatNumber(value);
    _acceptResult(
      expressionLabel,
      ToolboxCalculatorResult(
        operation: operation,
        exact: exact,
        latex: exact,
        approximate: exact,
        type: ToolboxCalculatorResultType.expression,
        backend: ToolboxCalculatorBackend.numeric,
      ),
    );
  }

  void reportError(ToolboxCalculatorFailureCode code, [Object? error]) {
    _generation += 1;
    _status = ToolboxCalculatorSessionStatus.error;
    _error = ToolboxCalculatorEngineException(
      code,
      technicalMessage: error?.toString(),
    );
    _notify();
  }

  void storeMemory() {
    final current = _result;
    if (current == null ||
        current.type != ToolboxCalculatorResultType.expression) {
      return;
    }
    _cancelActiveCalculation();
    _memoryExpression = current.exact;
    _markPersistentMutation();
    _notify();
  }

  void clearMemory() {
    if (_memoryExpression == null) return;
    _cancelActiveCalculation();
    _memoryExpression = null;
    _markPersistentMutation();
    _notify();
  }

  void upsertDefinition(
    ToolboxCalculatorDefinition definition, {
    String? replacingName,
  }) {
    final replacement = replacingName?.trim().toLowerCase();
    final candidate = <ToolboxCalculatorDefinition>[];
    var replaced = false;
    for (final current in _definitions) {
      if (!replaced && current.name.toLowerCase() == replacement) {
        candidate.add(definition);
        replaced = true;
      } else {
        candidate.add(current);
      }
    }
    if (!replaced) candidate.add(definition);
    _definitionValidator.validate(candidate);
    _cancelActiveCalculation();
    _definitions
      ..clear()
      ..addAll(candidate);
    _markPersistentMutation();
    _notify();
  }

  void removeDefinition(String name) {
    final normalized = name.trim().toLowerCase();
    final previousLength = _definitions.length;
    _definitions.removeWhere(
      (definition) => definition.name.toLowerCase() == normalized,
    );
    if (_definitions.length == previousLength) return;
    _cancelActiveCalculation();
    _markPersistentMutation();
    _notify();
  }

  void clearResult() {
    _markMutation();
    _generation += 1;
    _status = ToolboxCalculatorSessionStatus.idle;
    _result = null;
    _error = null;
    _schedulePersistence();
    _notify();
  }

  void removeHistory(int id) {
    final previousLength = _history.length;
    _history.removeWhere((entry) => entry.id == id);
    if (_history.length == previousLength) return;
    _markPersistentMutation();
    _notify();
  }

  void clearHistory() {
    if (_history.isEmpty) return;
    _history.clear();
    _markPersistentMutation();
    _notify();
  }

  Map<String, String> _sessionSubstitutions() {
    final substitutions = <String, String>{};
    final answer = _answerExpression;
    final memory = _memoryExpression;
    if (answer != null) substitutions['ans'] = answer;
    if (memory != null) substitutions['mem'] = memory;
    return substitutions;
  }

  bool _canUseNumericFallback(
    ToolboxCalculatorEngineException error,
    ToolboxCalculatorRequest request,
  ) {
    return request.operation == ToolboxCalculatorOperation.evaluate &&
        request.expression != null &&
        error.code == ToolboxCalculatorFailureCode.engineUnavailable;
  }

  void _evaluateNumerically(
    String expression,
    String expressionLabel,
    int generation,
  ) {
    try {
      final value = _numericCalculator.evaluate(
        expression,
        angleMode: degreeMode
            ? ScientificAngleMode.degree
            : ScientificAngleMode.radian,
        variables: _numericSessionVariables(),
      );
      if (!_isCurrent(generation)) return;
      acceptNumericResult(
        operation: ToolboxCalculatorOperation.evaluate,
        expressionLabel: expressionLabel,
        value: value,
      );
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      reportError(ToolboxCalculatorFailureCode.computation, error);
    }
  }

  Map<String, double> _numericSessionVariables() {
    final variables = <String, double>{};
    final answer = double.tryParse(_answerExpression ?? '');
    final memory = double.tryParse(_memoryExpression ?? '');
    if (answer != null && answer.isFinite) variables['ans'] = answer;
    if (memory != null && memory.isFinite) variables['mem'] = memory;
    for (final definition in _definitions) {
      if (definition.isFunction) continue;
      final value = double.tryParse(definition.expression);
      if (value != null && value.isFinite) {
        variables[definition.name.toLowerCase()] = value;
      }
    }
    return variables;
  }

  void _acceptResult(
    String expressionLabel,
    ToolboxCalculatorResult nextResult,
  ) {
    _result = nextResult;
    _error = null;
    _status = ToolboxCalculatorSessionStatus.success;
    if (nextResult.type == ToolboxCalculatorResultType.expression) {
      _answerExpression = nextResult.exact;
    }
    _history.insert(
      0,
      ToolboxCalculatorHistoryEntry(
        id: ++_historyId,
        expression: expressionLabel,
        result: nextResult,
        createdAt: DateTime.now(),
      ),
    );
    if (_history.length > 50) {
      _history.removeRange(50, _history.length);
    }
    _markPersistentMutation();
    _notify();
  }

  ToolboxCalculatorSessionSnapshot _snapshot() {
    return ToolboxCalculatorSessionSnapshot(
      history: List<ToolboxCalculatorHistoryEntry>.of(_history),
      answerExpression: _answerExpression,
      memoryExpression: _memoryExpression,
      result: _result,
      angleUnit: _angleUnit,
      definitions: List<ToolboxCalculatorDefinition>.of(_definitions),
    );
  }

  void _markMutation() {
    _mutationRevision += 1;
  }

  void _markPersistentMutation() {
    _markMutation();
    _schedulePersistence();
  }

  bool _cancelActiveCalculation() {
    if (_status != ToolboxCalculatorSessionStatus.calculating) return false;
    _generation += 1;
    _status = ToolboxCalculatorSessionStatus.idle;
    _error = null;
    return true;
  }

  void _schedulePersistence() {
    _persistence?.schedule(_snapshot());
  }

  Future<void> flushPersistence() async {
    await _persistence?.flush(_snapshot());
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  bool _isRestoreCurrent(int revision) {
    return !_disposed && revision == _mutationRevision;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    final persistenceFlush = flushPersistence();
    _disposed = true;
    _generation += 1;
    unawaited(persistenceFlush);
    unawaited(engine.dispose());
    super.dispose();
  }
}
