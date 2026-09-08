const MAX_ADVANCED_MATRIX_SIDE = 8;

function assertAdvancedMatrix(matrix, options = {}) {
  const { square = false, tall = false } = options;
  if (
    matrix.length > MAX_ADVANCED_MATRIX_SIDE ||
    matrix[0].length > MAX_ADVANCED_MATRIX_SIDE
  ) {
    fail('resourceLimit', 'Advanced matrix operations are limited to 8 by 8');
  }
  if (square && matrix.length !== matrix[0].length) {
    fail('invalidInput', 'This operation requires a square matrix');
  }
  if (tall && matrix.length < matrix[0].length) {
    fail('invalidInput', 'This operation requires rows to be at least columns');
  }
}

function assertConstantMatrix(matrix) {
  if (
    matrix.some((row) =>
      row.some((cell) => nerdamer(cell).variables().length !== 0),
    )
  ) {
    fail(
      'unsupported',
      'This decomposition requires numeric or constant matrix entries',
    );
  }
}

function zeroMatrix(rows, columns) {
  return Array.from({ length: rows }, () => Array(columns).fill('0'));
}

function identityMatrix(size) {
  return Array.from({ length: size }, (_, row) =>
    Array.from({ length: size }, (_, column) => row === column ? '1' : '0'),
  );
}

function conjugateExact(value) {
  return nSimplify(`conjugate(${value})`);
}

function conjugateTransposeExact(matrix) {
  return Array.from({ length: matrix[0].length }, (_, column) =>
    matrix.map((row) => conjugateExact(row[column])),
  );
}

function dotExact(left, right) {
  let result = '0';
  for (let index = 0; index < left.length; index += 1) {
    result = nBinary(result, '+', nBinary(left[index], '*', right[index]));
  }
  return result;
}

function innerProductExact(left, right) {
  let result = '0';
  for (let index = 0; index < left.length; index += 1) {
    result = nBinary(
      result,
      '+',
      nBinary(conjugateExact(left[index]), '*', right[index]),
    );
  }
  return result;
}

function scaleVectorExact(vector, scalar) {
  return vector.map((value) => nBinary(value, '*', scalar));
}

function subtractVectorExact(left, right) {
  return left.map((value, index) => nBinary(value, '-', right[index]));
}

function matrixColumns(matrix) {
  return Array.from({ length: matrix[0].length }, (_, column) =>
    matrix.map((row) => row[column]),
  );
}

function matrixFromColumns(columns) {
  return Array.from({ length: columns[0].length }, (_, row) =>
    columns.map((column) => column[row]),
  );
}

function multiplyMatricesExact(left, right) {
  if (left[0].length !== right.length) {
    fail('invalidInput', 'Matrix dimensions do not allow multiplication');
  }
  const rightColumns = matrixColumns(right);
  return left.map((row) => rightColumns.map((column) => dotExact(row, column)));
}

function multiplyMatrixVectorExact(matrix, vector) {
  if (matrix[0].length !== vector.length) {
    fail('invalidInput', 'Matrix and vector dimensions differ');
  }
  return matrix.map((row) => dotExact(row, vector));
}

function matrixResultPart(id, matrix) {
  const exact = matrixSource(matrix);
  return {
    id,
    type: 'matrix',
    exact,
    latex: matrixLatex(exact),
    approximate: null,
  };
}

function expressionResultPart(id, source, type = 'expression') {
  const expression = nerdamer(source);
  return {
    id,
    type,
    exact: expression.toString(),
    latex: expression.toTeX(),
    approximate: decimalForNerdamer(expression),
  };
}

function structuredMatrixResult(parts) {
  const exact = parts.map((part) => `${part.id}=${part.exact}`).join('; ');
  const latex = parts.map((part) => `${part.id}=${part.latex}`).join('\\quad ');
  return boundedResult({
    ok: true,
    backend: 'nerdamer-prime',
    type: 'unknown',
    exact,
    latex,
    approximate: null,
    unevaluated: false,
    warnings: [],
    parts,
  });
}

function zeroSubspaceResult() {
  return nerdamerExactResult('{0}', 'equationSet', '\\{\\mathbf{0}\\}');
}

function nullSpaceResult(matrix) {
  assertAdvancedMatrix(matrix);
  const reduced = rrefMatrix(matrix);
  const pivotSet = new Set(reduced.pivotColumns);
  const freeColumns = Array.from(
    { length: matrix[0].length },
    (_, index) => index,
  ).filter((column) => !pivotSet.has(column));
  if (freeColumns.length === 0) return zeroSubspaceResult();
  const basis = freeColumns.map((freeColumn) => {
    const vector = Array(matrix[0].length).fill('0');
    vector[freeColumn] = '1';
    reduced.pivotColumns.forEach((pivotColumn, row) => {
      vector[pivotColumn] = nBinary('0', '-', reduced.matrix[row][freeColumn]);
    });
    return vector;
  });
  return matrixNerdamerResult(basis);
}

function columnSpaceResult(matrix) {
  assertAdvancedMatrix(matrix);
  const reduced = rrefMatrix(matrix);
  if (reduced.pivotColumns.length === 0) return zeroSubspaceResult();
  const basis = matrix.map((row) =>
    reduced.pivotColumns.map((column) => row[column]),
  );
  return matrixNerdamerResult(basis);
}

function rowSpaceResult(matrix) {
  assertAdvancedMatrix(matrix);
  const reduced = rrefMatrix(matrix);
  const basis = reduced.matrix.filter((row) => row.some((cell) => !nZero(cell)));
  return basis.length === 0 ? zeroSubspaceResult() : matrixNerdamerResult(basis);
}

function luDecompositionResult(matrix) {
  assertAdvancedMatrix(matrix, { square: true });
  assertConstantMatrix(matrix);
  const size = matrix.length;
  const upper = matrix.map((row) => row.map((cell) => nSimplify(cell)));
  const lower = identityMatrix(size);
  const permutation = identityMatrix(size);
  for (let column = 0; column < size; column += 1) {
    let pivotRow = column;
    while (pivotRow < size && nZero(upper[pivotRow][column])) pivotRow += 1;
    if (pivotRow === size) fail('unsupported', 'LU decomposition requires a nonsingular matrix');
    if (pivotRow !== column) {
      [upper[column], upper[pivotRow]] = [upper[pivotRow], upper[column]];
      [permutation[column], permutation[pivotRow]] = [
        permutation[pivotRow],
        permutation[column],
      ];
      for (let previous = 0; previous < column; previous += 1) {
        [lower[column][previous], lower[pivotRow][previous]] = [
          lower[pivotRow][previous],
          lower[column][previous],
        ];
      }
    }
    for (let row = column + 1; row < size; row += 1) {
      const factor = nBinary(upper[row][column], '/', upper[column][column]);
      lower[row][column] = factor;
      for (let index = column; index < size; index += 1) {
        upper[row][index] = nBinary(
          upper[row][index],
          '-',
          nBinary(factor, '*', upper[column][index]),
        );
      }
      upper[row][column] = '0';
    }
  }
  return structuredMatrixResult([
    matrixResultPart('P', permutation),
    matrixResultPart('L', lower),
    matrixResultPart('U', upper),
  ]);
}

function qrDecompose(matrix) {
  assertAdvancedMatrix(matrix, { tall: true });
  assertConstantMatrix(matrix);
  const sourceColumns = matrixColumns(matrix);
  const orthonormalColumns = [];
  const upper = zeroMatrix(sourceColumns.length, sourceColumns.length);
  for (let column = 0; column < sourceColumns.length; column += 1) {
    let residual = [...sourceColumns[column]];
    for (let previous = 0; previous < column; previous += 1) {
      const coefficient = innerProductExact(
        orthonormalColumns[previous],
        sourceColumns[column],
      );
      upper[previous][column] = coefficient;
      residual = subtractVectorExact(
        residual,
        scaleVectorExact(orthonormalColumns[previous], coefficient),
      );
    }
    const normSquared = innerProductExact(residual, residual);
    if (nZero(normSquared)) {
      fail('unsupported', 'QR decomposition requires independent columns');
    }
    const norm = nSimplify(`sqrt(${normSquared})`);
    upper[column][column] = norm;
    orthonormalColumns.push(residual.map((value) => nBinary(value, '/', norm)));
  }
  return { q: matrixFromColumns(orthonormalColumns), r: upper };
}

function qrDecompositionResult(matrix) {
  const result = qrDecompose(matrix);
  return structuredMatrixResult([
    matrixResultPart('Q', result.q),
    matrixResultPart('R', result.r),
  ]);
}

function gramSchmidtResult(matrix) {
  return matrixNerdamerResult(qrDecompose(matrix).q);
}

function solveExactLinearSystem(matrix, vector) {
  const augmented = matrix.map((row, index) => [...row, vector[index]]);
  const reduced = rrefMatrix(augmented);
  const variableCount = matrix[0].length;
  const pivotSet = new Set(reduced.pivotColumns);
  for (let column = 0; column < variableCount; column += 1) {
    if (!pivotSet.has(column)) {
      fail('unsupported', 'The least-squares system is rank deficient');
    }
  }
  if (pivotSet.has(variableCount)) {
    fail('computation', 'The linear system is inconsistent');
  }
  return Array.from(
    { length: variableCount },
    (_, row) => reduced.matrix[row][variableCount],
  );
}

function leastSquaresResult(matrix, vector) {
  assertAdvancedMatrix(matrix, { tall: true });
  assertConstantMatrix(matrix);
  if (matrix.length !== vector.length) {
    fail('invalidInput', 'Matrix rows must match the observation vector');
  }
  const adjoint = conjugateTransposeExact(matrix);
  const normalMatrix = multiplyMatricesExact(adjoint, matrix);
  const normalVector = multiplyMatrixVectorExact(adjoint, vector);
  return vectorNerdamerResult(
    solveExactLinearSystem(normalMatrix, normalVector),
  );
}

function vectorProjectionResult(vector, onto) {
  if (vector.length !== onto.length) {
    fail('invalidInput', 'Vector dimensions differ');
  }
  const denominator = innerProductExact(onto, onto);
  if (nZero(denominator)) fail('invalidInput', 'Projection target cannot be zero');
  const factor = nBinary(innerProductExact(onto, vector), '/', denominator);
  return vectorNerdamerResult(scaleVectorExact(onto, factor));
}

function vectorInnerProductResult(left, right) {
  return nerdamerResult(nerdamer(innerProductExact(left, right)));
}

function vectorNormResult(vector) {
  return nerdamerResult(
    nerdamer(`sqrt(${innerProductExact(vector, vector)})`).simplify(),
  );
}

function complexComponents(expression) {
  return {
    real: nerdamer(`realpart(${expression})`).toString(),
    imaginary: nerdamer(`imagpart(${expression})`).toString(),
  };
}

function complexArgumentExpression(expression, degreeMode) {
  const components = complexComponents(expression);
  if (nZero(components.real) && nZero(components.imaginary)) {
    fail('invalidInput', 'The argument of zero is undefined');
  }
  const radians = `atan2((${components.imaginary}),(${components.real}))`;
  return degreeMode ? `180*(${radians})/pi` : radians;
}

function complexArgumentResult(expression, degreeMode) {
  return nerdamerResult(nerdamer(complexArgumentExpression(expression, degreeMode)));
}

function complexPolarResult(expression, degreeMode) {
  const magnitude = nerdamer(`abs(${expression})`).toString();
  const radians = complexArgumentExpression(expression, false);
  const displayAngle = complexArgumentExpression(expression, degreeMode);
  const exact = `(${magnitude})*e^(i*(${radians}))`;
  const parsed = nerdamer(exact);
  const result = nerdamerExactResult(
    exact,
    'expression',
    parsed.toTeX(),
    nerdamer(expression).evaluate().text('decimals', 16),
  );
  result.parts = [
    expressionResultPart('magnitude', magnitude),
    expressionResultPart('argument', displayAngle),
  ];
  return boundedResult(result);
}

function complexFromPolarResult(radius, angle, degreeMode) {
  const radians = degreeMode ? `((${angle})*pi/180)` : `(${angle})`;
  const source = `(${radius})*(cos(${radians})+i*sin(${radians}))`;
  return nerdamerResult(nerdamer(`rectform(${source})`));
}
