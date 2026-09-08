import 'dart:async';
import 'dart:convert';

import 'package:fjs/fjs.dart';
import 'package:flutter/services.dart';

import 'toolbox_calculator_engine.dart';
import 'toolbox_calculator_models.dart';

const _nerdamerAsset =
    'assets/toolbox/calculator_cas/nerdamer-prime-1.5.0.min.js';
const _algebriteAsset =
    'assets/toolbox/calculator_cas/algebrite-1.4.0.browser.js';
const _coreAsset = 'assets/toolbox/calculator_cas/calculator_cas_core.js';
const _advancedAsset =
    'assets/toolbox/calculator_cas/calculator_cas_advanced.js';
const _bridgeAsset = 'assets/toolbox/calculator_cas/calculator_cas_bridge.js';
const _bridgeModuleName = 'toolbox/calculator-cas-bridge';

ToolboxCalculatorEngine createPlatformCalculatorEngine({
  AssetBundle? assetBundle,
  required Duration calculationTimeout,
}) {
  return ToolboxCalculatorCasEngine(
    assetBundle: assetBundle,
    calculationTimeout: calculationTimeout,
  );
}

class ToolboxCalculatorCasEngine implements ToolboxCalculatorEngine {
  ToolboxCalculatorCasEngine({
    AssetBundle? assetBundle,
    this.calculationTimeout = const Duration(seconds: 4),
  }) : _assetBundle = assetBundle ?? rootBundle;

  static Future<void>? _runtimeInitialization;

  final AssetBundle _assetBundle;
  final Duration calculationTimeout;
  Future<JsEngine>? _engineInitialization;
  JsEngine? _engine;
  Future<void> _operationTail = Future<void>.value();
  bool _disposed = false;

  @override
  Future<ToolboxCalculatorResult> calculate(ToolboxCalculatorRequest request) {
    final completer = Completer<ToolboxCalculatorResult>();
    _operationTail = _operationTail.then((_) async {
      if (completer.isCompleted) return;
      try {
        completer.complete(await _calculateNow(request));
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<ToolboxCalculatorResult> _calculateNow(
    ToolboxCalculatorRequest request,
  ) async {
    if (_disposed) {
      throw const ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.engineUnavailable,
        technicalMessage: 'The calculator engine has been disposed.',
      );
    }
    _validateRequestSize(request);
    final engine = await _ensureEngine();
    _throwIfDisposed();
    final payload = jsonEncode(request.toJson());
    try {
      final value = await engine
          .call(
            module: _bridgeModuleName,
            method: 'calculate',
            params: <JsValue>[JsValue.string(payload)],
          )
          .timeout(calculationTimeout);
      return _decodeResponse(value, request.operation);
    } on TimeoutException catch (_) {
      await _invalidateEngine(engine);
      throw const ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.timeout,
      );
    } on ToolboxCalculatorEngineException {
      rethrow;
    } on JsError catch (error) {
      if (error.code() == 'MEMORY_LIMIT_ERROR' ||
          error.code() == 'STACK_OVERFLOW_ERROR') {
        await _invalidateEngine(engine);
        throw ToolboxCalculatorEngineException(
          ToolboxCalculatorFailureCode.resourceLimit,
          technicalMessage: error.toString(),
        );
      }
      throw ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.computation,
        technicalMessage: error.toString(),
      );
    } on Object catch (error) {
      throw ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.computation,
        technicalMessage: error.toString(),
      );
    }
  }

  Future<JsEngine> _ensureEngine() {
    if (_disposed) {
      return Future<JsEngine>.error(_disposedException);
    }
    final current = _engine;
    if (current != null && !current.closed) {
      return Future<JsEngine>.value(current);
    }
    return _engineInitialization ??= _createEngine();
  }

  Future<JsEngine> _createEngine() async {
    JsEngine? engine;
    try {
      await _ensureRuntimeInitialized();
      _throwIfDisposed();
      final scripts = await Future.wait(<Future<String>>[
        _assetBundle.loadString(_nerdamerAsset),
        _assetBundle.loadString(_algebriteAsset),
        _assetBundle.loadString(_coreAsset),
        _assetBundle.loadString(_advancedAsset),
        _assetBundle.loadString(_bridgeAsset),
      ]);
      _throwIfDisposed();
      engine = await JsEngine.create(
        builtins: JsBuiltinOptions.none(),
        runtimeOptions: JsEngineRuntimeOptions(
          memoryLimit: BigInt.from(96 * 1024 * 1024),
          gcThreshold: BigInt.from(16 * 1024 * 1024),
          maxStackSize: BigInt.from(1024 * 1024),
          info: 'toolbox-calculator-cas',
        ),
      );
      await engine.initWithoutBridge();
      await engine.eval(
        source: const JsCode.code(
          'globalThis.window = globalThis; globalThis.self = globalThis; null;',
        ),
      );
      await engine.eval(source: JsCode.code(scripts[0]));
      await engine.eval(source: JsCode.code(scripts[1]));
      await engine.declareNewModule(
        module: JsModule.code(
          module: _bridgeModuleName,
          code: '${scripts[2]}\n${scripts[3]}\n${scripts[4]}',
        ),
      );
      if (_disposed) {
        await engine.close();
        engine = null;
        throw _disposedException;
      }
      _engine = engine;
      return engine;
    } on ToolboxCalculatorEngineException {
      if (engine != null && !engine.closed) {
        await engine.close();
      }
      rethrow;
    } on Object catch (error) {
      if (engine != null && !engine.closed) {
        await engine.close();
      }
      throw ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.engineUnavailable,
        technicalMessage: error.toString(),
      );
    } finally {
      _engineInitialization = null;
    }
  }

  Future<void> _ensureRuntimeInitialized() async {
    final initialization = _runtimeInitialization ??= LibFjs.init();
    try {
      await initialization;
    } on Object {
      if (identical(_runtimeInitialization, initialization)) {
        _runtimeInitialization = null;
      }
      rethrow;
    }
  }

  ToolboxCalculatorResult _decodeResponse(
    JsValue value,
    ToolboxCalculatorOperation operation,
  ) {
    final raw = value.asString;
    if (raw == null) {
      throw const ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.computation,
        technicalMessage: 'The symbolic bridge returned a non-string value.',
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw const ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.computation,
        technicalMessage: 'The symbolic bridge returned malformed JSON.',
      );
    }
    if (decoded['ok'] == true) {
      return ToolboxCalculatorResult.fromJson(decoded, operation);
    }
    final error = decoded['error'];
    final errorMap = error is Map<String, Object?>
        ? error
        : const <String, Object?>{};
    throw ToolboxCalculatorEngineException(
      ToolboxCalculatorFailureCode.fromWireName(errorMap['code']),
      technicalMessage: errorMap['message']?.toString(),
    );
  }

  void _validateRequestSize(ToolboxCalculatorRequest request) {
    final encoded = jsonEncode(request.toJson());
    if (utf8.encode(encoded).length > 64000) {
      throw const ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.resourceLimit,
        technicalMessage: 'The calculator request exceeds 64 KB.',
      );
    }
  }

  void _throwIfDisposed() {
    if (_disposed) throw _disposedException;
  }

  ToolboxCalculatorEngineException get _disposedException =>
      const ToolboxCalculatorEngineException(
        ToolboxCalculatorFailureCode.engineUnavailable,
        technicalMessage: 'The calculator engine has been disposed.',
      );

  Future<void> _invalidateEngine(JsEngine engine) async {
    if (identical(_engine, engine)) _engine = null;
    if (!engine.closed) {
      try {
        await engine.close().timeout(const Duration(seconds: 1));
      } on Object {
        // The handle is discarded even if immediate cancellation reports late.
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final initialization = _engineInitialization;
    if (initialization != null) {
      try {
        await initialization;
      } on Object {
        // Initialization observes _disposed and closes any partial engine.
      }
    }
    final engine = _engine;
    _engine = null;
    if (engine != null && !engine.closed) await engine.close();
  }
}
