const MAX_EXPRESSION_LENGTH = 8000;
const MAX_RESULT_LENGTH = 48000;
const MAX_REQUEST_BYTES = 64000;
const MAX_LIST_LENGTH = 32;
const MAX_MATRIX_SIDE = 12;
const MAX_MATRIX_CELLS = 144;
const MAX_DEFINITIONS = 32;
const MAX_DEFINITION_PARAMETERS = 4;
const MAX_DEFINITION_NAME_LENGTH = 32;
const MAX_DEFINITION_EXPRESSION_LENGTH = 2000;
const IDENTIFIER_PATTERN = /^[A-Za-z_\u0370-\u03ff][A-Za-z0-9_\u0370-\u03ff]*$/u;
const IDENTIFIER_TOKEN_PATTERN = /[A-Za-z_\u0370-\u03ff][A-Za-z0-9_\u0370-\u03ff]*/gu;
const RESERVED_DEFINITION_NAMES = new Set([
  'ans', 'mem', 'pi', 'tau', 'phi', 'e', 'i', 'infinity',
  'sin', 'cos', 'tan', 'sec', 'csc', 'cot',
  'asin', 'acos', 'atan', 'atan2', 'asec', 'acsc', 'acot',
  'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh',
  'log', 'ln', 'exp', 'sqrt', 'cbrt', 'root', 'abs',
  'floor', 'ceil', 'round', 'min', 'max', 'mod', 'gcd', 'lcm',
  'ncr', 'npr', 'factor', 'diff', 'integrate', 'limit', 'sum',
  'product', 'matrix', 'vector', 'det', 'transpose',
  'realpart', 'imagpart', 'conjugate', 'arg',
]);
const DEGREE_FUNCTION_ALIASES = new Map([
  ['sin', '__calc_sin'], ['cos', '__calc_cos'], ['tan', '__calc_tan'],
  ['sec', '__calc_sec'], ['csc', '__calc_csc'], ['cot', '__calc_cot'],
  ['asin', '__calc_asin'], ['arcsin', '__calc_asin'],
  ['acos', '__calc_acos'], ['arccos', '__calc_acos'],
  ['atan', '__calc_atan'], ['arctan', '__calc_atan'],
  ['asec', '__calc_asec'], ['arcsec', '__calc_asec'],
  ['acsc', '__calc_acsc'], ['arccsc', '__calc_acsc'],
  ['acot', '__calc_acot'], ['arccot', '__calc_acot'],
  ['atan2', '__calc_atan2'],
]);

class CalculatorBridgeError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function fail(code, message) {
  throw new CalculatorBridgeError(code, message);
}

function utf8ByteLength(value) {
  let length = 0;
  for (const character of value) {
    const codePoint = character.codePointAt(0);
    if (codePoint <= 0x7f) length += 1;
    else if (codePoint <= 0x7ff) length += 2;
    else if (codePoint <= 0xffff) length += 3;
    else length += 4;
  }
  return length;
}

function requiredString(value, field) {
  if (typeof value !== 'string' || value.trim() === '') {
    fail('invalidInput', `${field} is required`);
  }
  if (value.length > MAX_EXPRESSION_LENGTH) {
    fail('resourceLimit', `${field} is too long`);
  }
  if (/\0|\r|\n/u.test(value)) {
    fail('invalidInput', `${field} contains an unsupported control character`);
  }
  if (value.includes(':=')) {
    fail('invalidInput', 'Persistent function assignments are not allowed');
  }
  return value.trim();
}

function optionalString(value, fallback, field) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }
  return requiredString(value, field);
}

function identifier(value, fallback, field) {
  const candidate = optionalString(value, fallback, field);
  if (!IDENTIFIER_PATTERN.test(candidate)) {
    fail('invalidInput', `${field} is not a valid symbol`);
  }
  return candidate;
}

function normalizeExpression(value, field = 'expression') {
  return requiredString(value, field)
    .replace(/[\u2212\u2013\u2014]/gu, '-')
    .replace(/[\u00d7\u00b7\u22c5]/gu, '*')
    .replace(/\u00f7/gu, '/')
    .replace(/\u03c0/gu, 'pi')
    .replace(/\u03c4/gu, '(2*pi)')
    .replace(/\u221e/gu, 'Infinity')
    .replace(/\u207b\u00b9/gu, '^(-1)')
    .replace(/\u00b2/gu, '^2')
    .replace(/\u00b3/gu, '^3')
    .replace(/\u221a\s*(?=\()/gu, 'sqrt')
    .replace(/\bln\s*\(/giu, 'log(');
}

function normalizeStringList(value, field, context = null) {
  if (!Array.isArray(value) || value.length === 0) {
    fail('invalidInput', `${field} is required`);
  }
  if (value.length > MAX_LIST_LENGTH) {
    fail('resourceLimit', `${field} has too many items`);
  }
  return value.map((item, index) => context === null
    ? normalizeExpression(item, `${field}[${index}]`)
    : contextExpression(context, item, `${field}[${index}]`));
}

function normalizeIdentifiers(value, fallback, field) {
  const source = value === undefined || value === null || value.length === 0
    ? fallback
    : value;
  if (!Array.isArray(source) || source.length === 0 || source.length > MAX_LIST_LENGTH) {
    fail('invalidInput', `${field} is invalid`);
  }
  return source.map((item, index) => identifier(item, '', `${field}[${index}]`));
}

function normalizeSubstitutions(value) {
  if (value === undefined || value === null) {
    return {};
  }
  if (typeof value !== 'object' || Array.isArray(value)) {
    fail('invalidInput', 'substitutions must be an object');
  }
  const entries = Object.entries(value);
  if (entries.length > MAX_LIST_LENGTH) {
    fail('resourceLimit', 'Too many substitutions');
  }
  const normalized = {};
  for (const [key, item] of entries) {
    const name = identifier(key, '', 'substitution key');
    normalized[name] = normalizeExpression(item, `substitutions.${name}`);
  }
  return normalized;
}

function normalizeAngleUnit(value) {
  if (value === undefined || value === null || value === '') return 'radian';
  if (value !== 'degree' && value !== 'radian') {
    fail('invalidInput', 'angleUnit must be degree or radian');
  }
  return value;
}

function normalizeDefinitions(value) {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) {
    fail('invalidInput', 'definitions must be an array');
  }
  if (value.length > MAX_DEFINITIONS) {
    fail('resourceLimit', 'Too many definitions');
  }
  const names = new Set();
  const definitions = value.map((item, index) => {
    if (item === null || typeof item !== 'object' || Array.isArray(item)) {
      fail('invalidInput', `definitions[${index}] must be an object`);
    }
    const name = identifier(item.name, '', `definitions[${index}].name`);
    const normalizedName = name.toLowerCase();
    if (
      name.length > MAX_DEFINITION_NAME_LENGTH ||
      RESERVED_DEFINITION_NAMES.has(normalizedName) ||
      normalizedName.startsWith('__calc_')
    ) {
      fail('invalidInput', `definitions[${index}].name is reserved`);
    }
    if (!names.add(normalizedName)) {
      fail('invalidInput', `definitions[${index}].name is duplicated`);
    }
    const rawParameters = item.parameters === undefined ? [] : item.parameters;
    if (!Array.isArray(rawParameters) || rawParameters.length > MAX_DEFINITION_PARAMETERS) {
      fail('invalidInput', `definitions[${index}].parameters is invalid`);
    }
    const parameterNames = new Set();
    const parameters = rawParameters.map((parameter, parameterIndex) => {
      const normalized = identifier(
        parameter,
        '',
        `definitions[${index}].parameters[${parameterIndex}]`,
      );
      const normalizedParameter = normalized.toLowerCase();
      if (
        normalized.length > MAX_DEFINITION_NAME_LENGTH ||
        normalizedParameter === normalizedName ||
        RESERVED_DEFINITION_NAMES.has(normalizedParameter) ||
        !parameterNames.add(normalizedParameter)
      ) {
        fail('invalidInput', `definitions[${index}].parameters is invalid`);
      }
      return normalized;
    });
    const expression = normalizeExpression(
      item.expression,
      `definitions[${index}].expression`,
    );
    if (expression.length > MAX_DEFINITION_EXPRESSION_LENGTH) {
      fail('resourceLimit', `definitions[${index}].expression is too long`);
    }
    return { name, normalizedName, expression, parameters };
  });
  return sortDefinitionsByDependency(definitions);
}

function sortDefinitionsByDependency(definitions) {
  const byName = new Map(definitions.map((definition) => [definition.normalizedName, definition]));
  const dependencies = new Map(definitions.map((definition) => {
    const parameters = new Set(definition.parameters.map((parameter) => parameter.toLowerCase()));
    const tokens = Array.from(definition.expression.matchAll(IDENTIFIER_TOKEN_PATTERN));
    const referencedNames = new Set(tokens
      .map((match) => match[0].toLowerCase())
      .filter((token) => byName.has(token) && !parameters.has(token)));
    return [definition.normalizedName, referencedNames];
  }));
  const state = new Map();
  const ordered = [];
  const visit = (name) => {
    if (state.get(name) === 1) fail('invalidInput', 'Definitions contain a cycle');
    if (state.get(name) === 2) return;
    state.set(name, 1);
    for (const dependency of dependencies.get(name) || []) visit(dependency);
    state.set(name, 2);
    ordered.push(byName.get(name));
  };
  for (const definition of definitions) visit(definition.normalizedName);
  return ordered;
}

function rewriteDegreeFunctions(source) {
  return source.replace(
    /\b(?:arcsin|arccos|arctan|arcsec|arccsc|arccot|atan2|asin|acos|atan|asec|acsc|acot|sin|cos|tan|sec|csc|cot)\s*(?=\()/giu,
    (match) => DEGREE_FUNCTION_ALIASES.get(match.trim().toLowerCase()) || match,
  );
}

function installDegreeFunctions() {
  const direct = ['sin', 'cos', 'tan', 'sec', 'csc', 'cot'];
  for (const name of direct) {
    nerdamer.setFunction(`__calc_${name}`, ['x'], `${name}(x*pi/180)`);
  }
  const inverse = ['asin', 'acos', 'atan', 'asec', 'acsc', 'acot'];
  for (const name of inverse) {
    nerdamer.setFunction(`__calc_${name}`, ['x'], `${name}(x)*180/pi`);
  }
  nerdamer.setFunction('__calc_atan2', ['y', 'x'], 'atan2(y,x)*180/pi');
}

function transformedSubstitutions(substitutions, degreeMode) {
  if (!degreeMode) return substitutions;
  return Object.fromEntries(
    Object.entries(substitutions).map(([name, expression]) => [
      name,
      rewriteDegreeFunctions(expression),
    ]),
  );
}

function installDefinitions(definitions, substitutions, degreeMode) {
  for (const definition of definitions) {
    const parameterNames = new Set(definition.parameters.map((parameter) => parameter.toLowerCase()));
    const scopedSubstitutions = Object.fromEntries(
      Object.entries(substitutions).filter(([name]) => !parameterNames.has(name.toLowerCase())),
    );
    const prepared = degreeMode
      ? rewriteDegreeFunctions(definition.expression)
      : definition.expression;
    const expanded = nerdamer(prepared, scopedSubstitutions).toString();
    if (definition.parameters.length === 0) {
      nerdamer.setVar(definition.name, expanded);
    } else {
      nerdamer.setFunction(definition.name, definition.parameters, expanded);
    }
  }
}

function expressionIsClosed(source, substitutions) {
  return nerdamer(normalizeExpression(source), substitutions).variables().length === 0;
}

function createRequestContext(request) {
  const definitions = normalizeDefinitions(request.definitions);
  const baseSubstitutions = normalizeSubstitutions(request.substitutions);
  installDefinitions(definitions, baseSubstitutions, false);
  const directNumericOperation = request.operation === 'evaluate' || request.operation === 'approximate';
  const degreeMode = normalizeAngleUnit(request.angleUnit) === 'degree' &&
    directNumericOperation &&
    request.expression !== undefined &&
    expressionIsClosed(request.expression, baseSubstitutions);
  if (degreeMode) {
    clearNerdamerState();
    installDegreeFunctions();
    const substitutions = transformedSubstitutions(baseSubstitutions, true);
    installDefinitions(definitions, substitutions, true);
    return { substitutions, degreeMode: true };
  }
  return { substitutions: baseSubstitutions, degreeMode: false };
}

function contextExpression(context, value, field = 'expression') {
  const normalized = normalizeExpression(value, field);
  const prepared = context.degreeMode ? rewriteDegreeFunctions(normalized) : normalized;
  return nerdamer(prepared, context.substitutions).toString();
}

function splitTopLevel(source, separator) {
  const parts = [];
  let start = 0;
  let roundDepth = 0;
  let squareDepth = 0;
  let braceDepth = 0;
  for (let index = 0; index < source.length; index += 1) {
    const character = source[index];
    if (character === '(') roundDepth += 1;
    if (character === ')') roundDepth -= 1;
    if (character === '[') squareDepth += 1;
    if (character === ']') squareDepth -= 1;
    if (character === '{') braceDepth += 1;
    if (character === '}') braceDepth -= 1;
    if (roundDepth < 0 || squareDepth < 0 || braceDepth < 0) {
      fail('invalidInput', 'Unbalanced delimiters');
    }
    if (
      character === separator &&
      roundDepth === 0 &&
      squareDepth === 0 &&
      braceDepth === 0
    ) {
      parts.push(source.slice(start, index));
      start = index + 1;
    }
  }
  if (roundDepth !== 0 || squareDepth !== 0 || braceDepth !== 0) {
    fail('invalidInput', 'Unbalanced delimiters');
  }
  parts.push(source.slice(start));
  return parts;
}

function parseMatrixText(value, context = null, field = 'matrix') {
  let source = requiredString(value, 'matrix');
  if (/^matrix\s*\(/iu.test(source) && source.endsWith(')')) {
    source = source.replace(/^matrix\s*\(/iu, '').slice(0, -1);
    const rows = splitTopLevel(source, ',').map((row) => {
      const trimmed = row.trim();
      if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
        fail('invalidInput', 'Matrix rows must use brackets');
      }
      return splitTopLevel(trimmed.slice(1, -1), ',');
    });
    return normalizeMatrix(rows, context, field);
  }
  if (source.startsWith('[[') && source.endsWith(']]')) {
    const rows = splitTopLevel(source.slice(1, -1), ',').map((row) => {
      const trimmed = row.trim();
      if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
        fail('invalidInput', 'Matrix rows must use brackets');
      }
      return splitTopLevel(trimmed.slice(1, -1), ',');
    });
    return normalizeMatrix(rows, context, field);
  }
  const rows = splitTopLevel(source, ';').map((row) => splitTopLevel(row, ','));
  return normalizeMatrix(rows, context, field);
}

function normalizeMatrix(value, context = null, field = 'matrix') {
  if (!Array.isArray(value) || value.length === 0 || value.length > MAX_MATRIX_SIDE) {
    fail('invalidInput', 'Matrix row count is invalid');
  }
  const columnCount = Array.isArray(value[0]) ? value[0].length : 0;
  if (columnCount === 0 || columnCount > MAX_MATRIX_SIDE) {
    fail('invalidInput', 'Matrix column count is invalid');
  }
  if (value.length * columnCount > MAX_MATRIX_CELLS) {
    fail('resourceLimit', 'Matrix has too many cells');
  }
  return value.map((row, rowIndex) => {
    if (!Array.isArray(row) || row.length !== columnCount) {
      fail('invalidInput', 'Matrix rows must have equal length');
    }
    return row.map((cell, columnIndex) =>
      context === null
        ? normalizeExpression(cell, `${field}[${rowIndex}][${columnIndex}]`)
        : contextExpression(context, cell, `${field}[${rowIndex}][${columnIndex}]`),
    );
  });
}

function matrixFromRequest(
  request,
  context,
  field = 'matrix',
  expressionField = 'expression',
) {
  if (request[field] !== undefined && request[field] !== null) {
    return normalizeMatrix(request[field], context, field);
  }
  return parseMatrixText(request[expressionField], context, field);
}

function vectorFromRequest(request, context, field, expressionField) {
  const value = request[field];
  if (Array.isArray(value)) {
    if (value.length === 0 || value.length > MAX_LIST_LENGTH) {
      fail('invalidInput', `${field} is invalid`);
    }
    return value.map((cell, index) =>
      contextExpression(context, cell, `${field}[${index}]`),
    );
  }
  let source = requiredString(request[expressionField], expressionField);
  if (source.startsWith('[') && source.endsWith(']')) {
    source = source.slice(1, -1);
  }
  return splitTopLevel(source, ',').map((cell, index) =>
    contextExpression(context, cell, `${field}[${index}]`),
  );
}

function matrixSource(matrix) {
  return `[${matrix.map((row) => `[${row.join(',')}]`).join(',')}]`;
}

function vectorSource(vector) {
  return `[${vector.join(',')}]`;
}

function assertPureAlgebriteExpression(source) {
  if (/(^|[^<>!])=($|[^=])/u.test(source) || source.includes('#')) {
    fail('invalidInput', 'Assignments are not allowed for this operation');
  }
  return source;
}

function clearNerdamerState() {
  nerdamer.clearVars();
  nerdamer.clearFunctions();
  nerdamer.clear('all');
}

function resetEngines() {
  clearNerdamerState();
  Algebrite.run('clearall');
}

function decimalForNerdamer(expression) {
  try {
    if (typeof expression.variables !== 'function' || expression.variables().length !== 0) {
      return null;
    }
    const decimal = expression.evaluate().text('decimals', 16);
    return decimal && decimal !== expression.toString() ? decimal : null;
  } catch (_) {
    return null;
  }
}

function nerdamerResult(expression, type = 'expression', unevaluated = false) {
  const exact = expression.toString();
  const result = {
    ok: true,
    backend: 'nerdamer-prime',
    type,
    exact,
    latex: expression.toTeX(),
    approximate: decimalForNerdamer(expression),
    unevaluated,
    warnings: [],
  };
  return boundedResult(result);
}

function nerdamerExactResult(exact, type, latex, approximate = null, unevaluated = false) {
  return boundedResult({
    ok: true,
    backend: 'nerdamer-prime',
    type,
    exact,
    latex,
    approximate,
    unevaluated,
    warnings: [],
  });
}

function algebriteResult(command, type = 'expression', unevaluatedPrefix = null) {
  const pureCommand = assertPureAlgebriteExpression(command);
  const exact = Algebrite.run(pureCommand);
  if (typeof exact !== 'string' || exact.trim() === '') {
    fail('unsupported', 'The symbolic backend did not return a result');
  }
  let latex = '';
  let approximate = null;
  try {
    latex = Algebrite.run(
      `printlatex(${assertPureAlgebriteExpression(exact)})`,
    );
  } catch (_) {
    latex = '';
  }
  if (!exactHasVariables(exact)) {
    try {
      const decimal = Algebrite.run(`float(${assertPureAlgebriteExpression(exact)})`);
      if (decimal && decimal !== exact) approximate = decimal;
    } catch (_) {
      approximate = null;
    }
  }
  return boundedResult({
    ok: true,
    backend: 'algebrite',
    type,
    exact,
    latex,
    approximate,
    unevaluated: unevaluatedPrefix !== null && exact.includes(unevaluatedPrefix),
    warnings: [],
  });
}

function exactHasVariables(exact) {
  try {
    if (exact.startsWith('[[')) {
      return parseMatrixText(exact).some((row) =>
        row.some((cell) => nerdamer(cell).variables().length !== 0),
      );
    }
    if (exact.startsWith('[') && exact.endsWith(']')) {
      return splitTopLevel(exact.slice(1, -1), ',').some(
        (cell) => nerdamer(cell).variables().length !== 0,
      );
    }
    return nerdamer(exact).variables().length !== 0;
  } catch (_) {
    return true;
  }
}

function boundedResult(result) {
  const encoded = JSON.stringify(result);
  if (utf8ByteLength(encoded) > MAX_RESULT_LENGTH) {
    fail('resourceLimit', 'The symbolic result is too large');
  }
  return result;
}

function nExpression(source, substitutions = {}) {
  return nerdamer(normalizeExpression(source), substitutions);
}

function nSimplify(source) {
  return nerdamer(source).simplify().toString();
}

function nBinary(left, operator, right) {
  return nSimplify(`(${left})${operator}(${right})`);
}

function nZero(source) {
  return nSimplify(source) === '0';
}

function nPivotKind(source) {
  const simplified = nSimplify(source);
  if (simplified === '0') return 'zero';
  try {
    const expression = nerdamer(simplified);
    if (expression.variables().length !== 0) return 'unknown';
    const decimal = expression.evaluate().text('decimals', 16).toLowerCase();
    if (decimal.includes('infinity') || decimal.includes('nan')) return 'unknown';
    return 'nonzero';
  } catch (_) {
    return 'unknown';
  }
}

function taylorSeries(expression, variable, order, point) {
  let derivative = nerdamer(expression);
  let factorial = 1n;
  const terms = [];
  for (let degree = 0; degree <= order; degree += 1) {
    if (degree > 0) {
      factorial *= BigInt(degree);
      derivative = nerdamer(`diff(${derivative.toString()},${variable})`);
    }
    const coefficient = derivative.sub(variable, point).toString();
    if (nZero(coefficient)) continue;
    if (degree === 0) {
      terms.push(`(${coefficient})`);
    } else {
      terms.push(
        `((${coefficient})/(${factorial.toString()}))*` +
        `((${variable})-(${point}))^(${degree})`,
      );
    }
  }
  if (terms.length === 0) return nerdamer('0');
  return nerdamer(terms.join('+')).expand();
}

function rrefMatrix(matrix) {
  const result = matrix.map((row) => row.map((cell) => nSimplify(cell)));
  const rowCount = result.length;
  const columnCount = result[0].length;
  let pivotRow = 0;
  const pivotColumns = [];
  for (let column = 0; column < columnCount && pivotRow < rowCount; column += 1) {
    let selectedRow = -1;
    let hasConditionalCandidate = false;
    for (let row = pivotRow; row < rowCount; row += 1) {
      const pivotKind = nPivotKind(result[row][column]);
      if (pivotKind === 'nonzero') {
        selectedRow = row;
        break;
      }
      if (pivotKind === 'unknown') hasConditionalCandidate = true;
    }
    if (selectedRow < 0 && hasConditionalCandidate) {
      fail(
        'unsupported',
        'Matrix reduction requires assumptions about a symbolic pivot',
      );
    }
    if (selectedRow < 0) continue;
    if (selectedRow !== pivotRow) {
      const temporary = result[pivotRow];
      result[pivotRow] = result[selectedRow];
      result[selectedRow] = temporary;
    }
    const pivot = result[pivotRow][column];
    result[pivotRow] = result[pivotRow].map((cell) => nBinary(cell, '/', pivot));
    for (let row = 0; row < rowCount; row += 1) {
      if (row === pivotRow || nZero(result[row][column])) continue;
      const factor = result[row][column];
      result[row] = result[row].map((cell, index) =>
        nBinary(cell, '-', nBinary(factor, '*', result[pivotRow][index])),
      );
    }
    pivotColumns.push(column);
    pivotRow += 1;
  }
  return { matrix: result, rank: pivotColumns.length, pivotColumns };
}

function matrixLatex(exact) {
  try {
    return Algebrite.run(`printlatex(${assertPureAlgebriteExpression(exact)})`);
  } catch (_) {
    return '';
  }
}

function equationResidual(source) {
  const parts = splitTopLevel(source, '=').map((part) => part.trim());
  if (parts.length === 1) return nSimplify(parts[0]);
  if (parts.length !== 2 || parts.some((part) => part === '')) {
    fail('invalidInput', 'Equation must contain at most one equality');
  }
  return nBinary(parts[0], '-', parts[1]);
}

function universalVariableResult(variable) {
  return nerdamerExactResult(
    `${variable}∈ℂ`,
    'equationSet',
    `${variable}\\in\\mathbb{C}`,
  );
}

function solveEquationSourceResult(source, variable) {
  const residual = equationResidual(source);
  const residualVariables = nerdamer(residual).variables();
  if (!residualVariables.includes(variable)) {
    if (residualVariables.length !== 0) {
      fail(
        'unsupported',
        'The equation depends on unresolved parameters but not the target variable',
      );
    }
    return nZero(residual)
      ? universalVariableResult(variable)
      : emptyEquationSetResult();
  }
  return solveEquationResult(
    nerdamer.solveEquations(residual, variable),
    variable,
  );
}

function linearSystemResult(equations, variables) {
  const augmented = [];
  for (const equation of equations) {
    const residual = equationResidual(equation);
    let constant = nerdamer(residual);
    for (const variable of variables) constant = constant.sub(variable, '0');
    const constantSource = constant.toString();
    const coefficients = variables.map((variable) =>
      nSimplify(`diff(${residual},${variable})`),
    );
    let reconstructed = constantSource;
    coefficients.forEach((coefficient, index) => {
      reconstructed = nBinary(
        reconstructed,
        '+',
        nBinary(coefficient, '*', variables[index]),
      );
    });
    if (!nZero(nBinary(residual, '-', reconstructed))) return null;
    augmented.push([
      ...coefficients,
      nBinary('0', '-', constantSource),
    ]);
  }

  const reduced = rrefMatrix(augmented);
  const variableCount = variables.length;
  if (reduced.pivotColumns.includes(variableCount)) {
    return emptyEquationSetResult();
  }
  const pivotRows = new Map();
  reduced.pivotColumns.forEach((column, row) => {
    if (column < variableCount) pivotRows.set(column, row);
  });
  const freeColumns = Array.from(
    { length: variableCount },
    (_, index) => index,
  ).filter((column) => !pivotRows.has(column));
  const exactParts = [];
  const latexParts = [];
  variables.forEach((variable, column) => {
    const row = pivotRows.get(column);
    if (row === undefined) {
      exactParts.push(`${variable}∈ℂ`);
      latexParts.push(`${variable}\\in\\mathbb{C}`);
      return;
    }
    let value = reduced.matrix[row][variableCount];
    for (const freeColumn of freeColumns) {
      value = nBinary(
        value,
        '-',
        nBinary(reduced.matrix[row][freeColumn], '*', variables[freeColumn]),
      );
    }
    exactParts.push(`${variable}=${value}`);
    latexParts.push(`${variable}=${nerdamer(value).toTeX()}`);
  });
  return nerdamerExactResult(
    exactParts.join(', '),
    'equationSet',
    `\\left\\{${latexParts.join(',\\;')}\\right\\}`,
  );
}

function solveSystemResult(equations, variables) {
  const linearResult = linearSystemResult(equations, variables);
  if (linearResult !== null) return linearResult;
  let solutions;
  try {
    solutions = nerdamer.solveEquations(equations, variables);
  } catch (error) {
    if (String(error && error.message ? error.message : error)
      .includes('distinct solution')) {
      fail('unsupported', 'The nonlinear system has no distinct solution');
    }
    throw error;
  }
  if (!Array.isArray(solutions)) {
    return nerdamerResult(solutions, 'equationSet');
  }
  if (solutions.length === 0) return emptyEquationSetResult();
  const pairs = solutions.map((item) => {
    if (!Array.isArray(item) || item.length !== 2) {
      return [null, String(item)];
    }
    return [String(item[0]), item[1].toString ? item[1].toString() : String(item[1])];
  });
  const exact = pairs.map(([name, value]) => `${name}=${value}`).join(', ');
  const latex = `\\left\\{${pairs
    .map(([name, value]) => `${name}=${nerdamer(value).toTeX()}`)
    .join(',\\;')}\\right\\}`;
  return nerdamerExactResult(exact, 'equationSet', latex);
}

function solveEquationResult(solution, variable) {
  if (!Array.isArray(solution)) {
    return nerdamerResult(solution, 'equationSet');
  }
  const values = solution.map((item) =>
    item && item.toString ? item.toString() : String(item),
  );
  if (values.length === 0) return emptyEquationSetResult();
  const exact = values.map((value) => `${variable}=${value}`).join(', ');
  const latex = `\\left\\{${values
    .map((value) => `${variable}=${nerdamer(value).toTeX()}`)
    .join(',\\;')}\\right\\}`;
  return nerdamerExactResult(exact, 'equationSet', latex);
}

function emptyEquationSetResult() {
  return nerdamerExactResult('∅', 'equationSet', '\\varnothing');
}

function vectorNerdamerResult(values, type = 'vector') {
  const exact = vectorSource(values);
  const expression = nerdamer(`vector(${values.join(',')})`);
  return nerdamerExactResult(exact, type, expression.toTeX());
}

function matrixNerdamerResult(matrix, type = 'matrix') {
  const exact = matrixSource(matrix);
  return nerdamerExactResult(exact, type, matrixLatex(exact));
}
