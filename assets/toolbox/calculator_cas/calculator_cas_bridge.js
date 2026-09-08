function requiredExpression(expression) {
  if (expression === null) fail('invalidInput', 'expression is required');
  return expression;
}

function calculateAlgebraOperation(operation, state) {
  const { request, context, substitutions, expression, variable } = state;
  switch (operation) {
    case 'evaluate': {
      const source = requiredExpression(expression);
      if (source.startsWith('[[')) return nerdamerResult(nerdamer(source), 'matrix');
      return nerdamerResult(nExpression(source, substitutions));
    }
    case 'approximate': {
      const value = nExpression(requiredExpression(expression), substitutions);
      return nerdamerExactResult(
        value.toString(),
        'expression',
        value.toTeX(),
        value.evaluate().text('decimals', 16),
      );
    }
    case 'simplify': {
      try {
        return algebriteResult(`simplify(${assertPureAlgebriteExpression(expression)})`);
      } catch (error) {
        if (error instanceof CalculatorBridgeError && error.code === 'invalidInput') throw error;
        return nerdamerResult(nExpression(requiredExpression(expression), substitutions).simplify());
      }
    }
    case 'expand':
      return nerdamerResult(nExpression(requiredExpression(expression), substitutions).expand());
    case 'factor':
      return nerdamerResult(nerdamer(`factor(${requiredExpression(expression)})`, substitutions));
    case 'partialFraction':
      return nerdamerResult(nerdamer(`partfrac(${requiredExpression(expression)},${variable})`, substitutions));
    case 'substitute':
      return nerdamerResult(nExpression(requiredExpression(expression), substitutions));
    case 'solveEquation':
      return solveEquationSourceResult(
        requiredExpression(expression),
        variable,
      );
    case 'solveSystem':
      return solveSystemResult(
        normalizeStringList(request.equations, 'equations', context),
        normalizeIdentifiers(request.variables, [variable], 'variables'),
      );
    default:
      return null;
  }
}

function calculateSingleVariableOperation(operation, state) {
  const { request, context, substitutions, expression, variable, targetVariable } = state;
  switch (operation) {
    case 'differentiate': {
      const order = Number.isInteger(request.order) ? request.order : 1;
      if (order < 1 || order > 20) fail('invalidInput', 'Derivative order is invalid');
      return nerdamerResult(nerdamer(`diff(${requiredExpression(expression)},${variable},${order})`, substitutions));
    }
    case 'integrate': {
      const result = nerdamer(`integrate(${requiredExpression(expression)},${variable})`, substitutions);
      return nerdamerResult(result, 'expression', result.toString().includes('integrate('));
    }
    case 'definiteIntegral': {
      const lower = contextExpression(context, request.lowerBound, 'lowerBound');
      const upper = contextExpression(context, request.upperBound, 'upperBound');
      const source = requiredExpression(expression);
      const antiderivative = nerdamer(`integrate(${source},${variable})`, substitutions);
      if (!antiderivative.toString().includes('integrate(')) {
        const upperValue = antiderivative.sub(variable, upper).toString();
        const lowerValue = antiderivative.sub(variable, lower).toString();
        return nerdamerResult(nerdamer(`(${upperValue})-(${lowerValue})`).simplify());
      }
      return nerdamerResult(
        nerdamer(`defint(${source},${lower},${upper},${variable})`, substitutions),
        'expression',
        true,
      );
    }
    case 'limit': {
      const point = contextExpression(context, request.point, 'point');
      const result = nerdamer(`limit(${requiredExpression(expression)},${variable},${point})`, substitutions);
      return nerdamerResult(result, 'expression', result.toString().includes('limit('));
    }
    case 'taylor': {
      const order = Number.isInteger(request.order) ? request.order : 6;
      if (order < 0 || order > 30) fail('invalidInput', 'Taylor order is invalid');
      const point = contextExpression(context, request.point || '0', 'point');
      return nerdamerResult(taylorSeries(requiredExpression(expression), variable, order, point));
    }
    case 'summation':
    case 'product': {
      const lower = contextExpression(context, request.lowerBound, 'lowerBound');
      const upper = contextExpression(context, request.upperBound, 'upperBound');
      const command = operation === 'summation' ? 'sum' : 'product';
      const result = nerdamer(
        `${command}(${requiredExpression(expression)},${variable},${lower},${upper})`,
        substitutions,
      );
      return nerdamerResult(result, 'expression', result.toString().includes(`${command}(`));
    }
    case 'laplace':
    case 'inverseLaplace': {
      const command = operation === 'laplace' ? 'laplace' : 'ilt';
      const result = nerdamer(
        `${command}(${requiredExpression(expression)},${variable},${targetVariable})`,
        substitutions,
      );
      return nerdamerResult(result, 'expression', result.toString().includes(`${command}(`));
    }
    default:
      return null;
  }
}

function calculateVectorCalculusOperation(operation, state) {
  const { request, context, substitutions, expression, variable } = state;
  switch (operation) {
    case 'gradient': {
      const variables = normalizeIdentifiers(request.variables, [variable], 'variables');
      const values = variables.map((name) =>
        nerdamer(`diff(${requiredExpression(expression)},${name})`, substitutions).toString(),
      );
      return vectorNerdamerResult(values);
    }
    case 'divergence': {
      const components = normalizeStringList(request.expressions, 'expressions', context);
      const variables = normalizeIdentifiers(request.variables, ['x', 'y', 'z'], 'variables');
      if (components.length !== variables.length) fail('invalidInput', 'Vector and variable dimensions differ');
      let result = '0';
      for (let index = 0; index < components.length; index += 1) {
        result = nBinary(result, '+', nerdamer(`diff(${components[index]},${variables[index]})`).toString());
      }
      return nerdamerResult(nerdamer(result));
    }
    case 'curl': {
      const components = normalizeStringList(request.expressions, 'expressions', context);
      const variables = normalizeIdentifiers(request.variables, ['x', 'y', 'z'], 'variables');
      if (components.length !== 3 || variables.length !== 3) fail('invalidInput', 'Curl requires three dimensions');
      const derivative = (component, name) => nerdamer(`diff(${component},${name})`).toString();
      return vectorNerdamerResult([
        nBinary(derivative(components[2], variables[1]), '-', derivative(components[1], variables[2])),
        nBinary(derivative(components[0], variables[2]), '-', derivative(components[2], variables[0])),
        nBinary(derivative(components[1], variables[0]), '-', derivative(components[0], variables[1])),
      ]);
    }
    case 'hessian': {
      const variables = normalizeIdentifiers(request.variables, ['x', 'y'], 'variables');
      const matrix = variables.map((rowVariable) =>
        variables.map((columnVariable) =>
          nerdamer(`diff(diff(${requiredExpression(expression)},${rowVariable}),${columnVariable})`).toString(),
        ),
      );
      return matrixNerdamerResult(matrix);
    }
    default:
      return null;
  }
}

function calculateBasicMatrixOperation(operation, state) {
  const { request, context } = state;
  switch (operation) {
    case 'matrixAdd':
    case 'matrixSubtract':
    case 'matrixMultiply': {
      const left = matrixFromRequest(request, context);
      const right = matrixFromRequest(request, context, 'secondaryMatrix', 'secondaryExpression');
      const leftSource = matrixSource(left);
      const rightSource = matrixSource(right);
      const command = operation === 'matrixAdd'
        ? `${leftSource}+${rightSource}`
        : operation === 'matrixSubtract'
          ? `${leftSource}-${rightSource}`
          : `inner(${leftSource},${rightSource})`;
      return algebriteResult(command, 'matrix');
    }
    case 'scalarMultiply': {
      const matrix = matrixFromRequest(request, context);
      const scalar = contextExpression(context, request.scalar, 'scalar');
      return algebriteResult(`(${scalar})*${matrixSource(matrix)}`, 'matrix');
    }
    case 'matrixPower': {
      const matrix = matrixFromRequest(request, context);
      const order = Number.isInteger(request.order) ? request.order : 2;
      if (order < -10 || order > 10) fail('invalidInput', 'Matrix power is invalid');
      return algebriteResult(`${matrixSource(matrix)}^(${order})`, 'matrix');
    }
    case 'determinant':
      return algebriteResult(`det(${matrixSource(matrixFromRequest(request, context))})`);
    case 'inverse':
      return algebriteResult(`inv(${matrixSource(matrixFromRequest(request, context))})`, 'matrix');
    case 'transpose':
      return algebriteResult(`transpose(${matrixSource(matrixFromRequest(request, context))})`, 'matrix');
    case 'trace': {
      const matrix = matrixFromRequest(request, context);
      if (matrix.length !== matrix[0].length) fail('invalidInput', 'Trace requires a square matrix');
      let result = '0';
      for (let index = 0; index < matrix.length; index += 1) {
        result = nBinary(result, '+', matrix[index][index]);
      }
      return nerdamerResult(nerdamer(result));
    }
    case 'rref':
      return matrixNerdamerResult(rrefMatrix(matrixFromRequest(request, context)).matrix);
    case 'rank':
      return nerdamerResult(nerdamer(String(rrefMatrix(matrixFromRequest(request, context)).rank)));
    default:
      return null;
  }
}

function calculateLinearSystemOperation(operation, state) {
  const { request, context } = state;
  switch (operation) {
    case 'solveLinearSystem': {
      const matrix = matrixFromRequest(request, context);
      const vector = vectorFromRequest(request, context, 'vector', 'secondaryExpression');
      if (matrix.length !== vector.length) fail('invalidInput', 'Matrix and vector dimensions differ');
      const variables = normalizeIdentifiers(
        request.variables,
        matrix[0].map((_, index) => `x${index + 1}`),
        'variables',
      );
      if (variables.length !== matrix[0].length) fail('invalidInput', 'Variable count does not match matrix columns');
      const equations = matrix.map((row, rowIndex) => {
        const left = row.map((cell, index) => `(${cell})*(${variables[index]})`).join('+');
        return `${left}=(${vector[rowIndex]})`;
      });
      return solveSystemResult(equations, variables);
    }
    case 'characteristicPolynomial': {
      const matrix = matrixFromRequest(request, context);
      if (matrix.length !== matrix[0].length) fail('invalidInput', 'Characteristic polynomial requires a square matrix');
      const symbol = identifier(request.targetVariable, 'lambda', 'targetVariable');
      return algebriteResult(`simplify(det(${matrixSource(matrix)}-${symbol}*unit(${matrix.length})))`);
    }
    case 'eigenvalues': {
      const matrix = matrixFromRequest(request, context);
      if (matrix.length !== matrix[0].length) fail('invalidInput', 'Eigenvalues require a square matrix');
      const symbol = identifier(request.targetVariable, 'lambda', 'targetVariable');
      const polynomial = Algebrite.run(`simplify(det(${matrixSource(matrix)}-${symbol}*unit(${matrix.length})))`);
      return solveEquationResult(nerdamer.solveEquations(polynomial, symbol), symbol);
    }
    case 'eigenvectors':
      return algebriteResult(`eigenvec(${matrixSource(matrixFromRequest(request, context))})`, 'matrix');
    default:
      return null;
  }
}

function calculateAdvancedMatrixOperation(operation, state) {
  const { request, context } = state;
  const matrixOperations = new Set([
    'nullSpace',
    'columnSpace',
    'rowSpace',
    'luDecomposition',
    'qrDecomposition',
    'gramSchmidt',
    'leastSquares',
  ]);
  if (!matrixOperations.has(operation)) return null;
  const matrix = matrixFromRequest(request, context);
  switch (operation) {
    case 'nullSpace':
      return nullSpaceResult(matrix);
    case 'columnSpace':
      return columnSpaceResult(matrix);
    case 'rowSpace':
      return rowSpaceResult(matrix);
    case 'luDecomposition':
      return luDecompositionResult(matrix);
    case 'qrDecomposition':
      return qrDecompositionResult(matrix);
    case 'gramSchmidt':
      return gramSchmidtResult(matrix);
    case 'leastSquares':
      return leastSquaresResult(
        matrix,
        vectorFromRequest(request, context, 'vector', 'secondaryExpression'),
      );
    default:
      return null;
  }
}

function calculateVectorOperation(operation, state) {
  const { request, context } = state;
  if (!['dotProduct', 'crossProduct', 'vectorNorm', 'vectorProjection'].includes(operation)) {
    return null;
  }
  const left = vectorFromRequest(request, context, 'vector', 'expression');
  if (operation === 'vectorNorm') {
    return vectorNormResult(left);
  }
  const right = vectorFromRequest(
    request,
    context,
    'secondaryVector',
    'secondaryExpression',
  );
  if (left.length !== right.length) fail('invalidInput', 'Vector dimensions differ');
  if (operation === 'dotProduct') {
    return vectorInnerProductResult(left, right);
  }
  if (operation === 'vectorProjection') return vectorProjectionResult(left, right);
  if (left.length !== 3) fail('invalidInput', 'Cross product requires three dimensions');
  return nerdamerResult(
    nerdamer(`cross(vector(${left.join(',')}),vector(${right.join(',')}))`),
    'vector',
  );
}

function calculateComplexOperation(operation, state) {
  const { request, context, expression } = state;
  const degreeMode = request.angleUnit === 'degree';
  if (operation === 'complexFromPolar') {
    const radius = contextExpression(context, request.radius, 'radius');
    const angle = contextExpression(context, request.angle, 'angle');
    return complexFromPolarResult(radius, angle, degreeMode);
  }
  if (!operation.startsWith('complex')) return null;
  const source = requiredExpression(expression);
  switch (operation) {
    case 'complexRealPart':
      return nerdamerResult(nerdamer(complexComponents(source).real));
    case 'complexImaginaryPart':
      return nerdamerResult(nerdamer(complexComponents(source).imaginary));
    case 'complexConjugate':
      return nerdamerResult(nerdamer(`conjugate(${source})`));
    case 'complexMagnitude':
      return nerdamerResult(nerdamer(`abs(${source})`));
    case 'complexArgument':
      return complexArgumentResult(source, degreeMode);
    case 'complexPolarForm':
      return complexPolarResult(source, degreeMode);
    case 'complexRectangularForm':
      return nerdamerResult(nerdamer(`rectform(${source})`));
    default:
      return null;
  }
}

function calculateOperation(request) {
  const operation = requiredString(request.operation, 'operation');
  const context = createRequestContext(request);
  const state = {
    request,
    context,
    substitutions: context.substitutions,
    expression: request.expression === undefined
      ? null
      : contextExpression(context, request.expression),
    variable: identifier(request.variable, 'x', 'variable'),
    targetVariable: identifier(request.targetVariable, 's', 'targetVariable'),
  };
  const handlers = [
    calculateAlgebraOperation,
    calculateSingleVariableOperation,
    calculateVectorCalculusOperation,
    calculateBasicMatrixOperation,
    calculateLinearSystemOperation,
    calculateAdvancedMatrixOperation,
    calculateVectorOperation,
    calculateComplexOperation,
  ];
  for (const handler of handlers) {
    const result = handler(operation, state);
    if (result !== null) return result;
  }
  fail('unsupported', `Unsupported operation: ${operation}`);
}

export function calculate(requestJson) {
  try {
    if (typeof nerdamer !== 'function' || typeof Algebrite !== 'object') {
      fail('engineUnavailable', 'CAS libraries are not initialized');
    }
    if (
      typeof requestJson !== 'string' ||
      utf8ByteLength(requestJson) > MAX_REQUEST_BYTES
    ) {
      fail('resourceLimit', 'Request is too large');
    }
    const request = JSON.parse(requestJson);
    if (request === null || typeof request !== 'object' || Array.isArray(request)) {
      fail('invalidInput', 'Request must be an object');
    }
    if (request.version !== 1) fail('unsupported', 'Unsupported bridge protocol version');
    resetEngines();
    const result = calculateOperation(request);
    result.operation = request.operation;
    return JSON.stringify(result);
  } catch (error) {
    const code = error instanceof CalculatorBridgeError
      ? error.code
      : String(error && error.message ? error.message : error).toLowerCase().includes('timeout')
        ? 'resourceLimit'
        : 'computation';
    const message = error && error.message ? String(error.message) : String(error);
    return JSON.stringify({
      ok: false,
      error: { code, message: message.slice(0, 500) },
    });
  } finally {
    try {
      if (typeof nerdamer === 'function' && typeof Algebrite === 'object') {
        clearNerdamerState();
      }
    } catch (_) {
      // A failed cleanup must not replace the calculation response.
    }
  }
}
