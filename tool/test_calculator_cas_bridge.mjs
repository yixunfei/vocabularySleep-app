import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const assetRoot = new URL('../assets/toolbox/calculator_cas/', import.meta.url);

globalThis.window = globalThis;
globalThis.self = globalThis;
vm.runInThisContext(
  fs.readFileSync(new URL('nerdamer-prime-1.5.0.min.js', assetRoot), 'utf8'),
);
vm.runInThisContext(
  fs.readFileSync(new URL('algebrite-1.4.0.browser.js', assetRoot), 'utf8'),
);

const bridgeSource = [
  'calculator_cas_core.js',
  'calculator_cas_advanced.js',
  'calculator_cas_bridge.js',
].map((name) => fs.readFileSync(new URL(name, assetRoot), 'utf8')).join('\n');
const bridge = await import(
  `data:text/javascript;base64,${Buffer.from(bridgeSource).toString('base64')}`
);

function calculate(request) {
  return JSON.parse(
    bridge.calculate(JSON.stringify({ version: 1, ...request })),
  );
}

function expectSuccess(request) {
  const result = calculate(request);
  assert.equal(result.ok, true, JSON.stringify(result));
  return result;
}

function expectFailure(request, code = 'invalidInput') {
  const result = calculate(request);
  assert.equal(result.ok, false, JSON.stringify(result));
  assert.equal(result.error.code, code, JSON.stringify(result));
  return result;
}

const exact = expectSuccess({
  operation: 'evaluate',
  expression: '1/3+sqrt(2)',
});
assert.match(exact.exact, /1\/3/);
assert.match(exact.exact, /sqrt\(2\)/);
assert.match(exact.approximate, /^1\.7475/);

assert.equal(
  expectSuccess({
    operation: 'simplify',
    expression: 'sin(x)^2+cos(x)^2',
  }).exact,
  '1',
);
assert.match(
  expectSuccess({ operation: 'factor', expression: 'x^2-1' }).exact,
  /\(-1\+x\)/,
);
assert.equal(
  expectSuccess({
    operation: 'solveSystem',
    equations: ['x+y=3', 'x-y=1'],
    variables: ['x', 'y'],
  }).exact,
  'x=2, y=1',
);
const emptyEquationSet = expectSuccess({
  operation: 'solveEquation',
  expression: 'exp(x)=0',
  variable: 'x',
});
assert.equal(emptyEquationSet.exact, '∅');
assert.equal(emptyEquationSet.latex, '\\varnothing');
assert.equal(
  expectSuccess({
    operation: 'solveEquation',
    expression: 'x=x',
    variable: 'x',
  }).exact,
  'x∈ℂ',
);
assert.equal(
  expectSuccess({
    operation: 'solveEquation',
    expression: 'x=x+1',
    variable: 'x',
  }).exact,
  '∅',
);
assert.equal(
  expectSuccess({
    operation: 'solveSystem',
    equations: ['x+y=2'],
    variables: ['x', 'y'],
  }).exact,
  'x=-y+2, y∈ℂ',
);
assert.equal(
  expectSuccess({
    operation: 'solveSystem',
    equations: ['x+y=1', 'x+y=2'],
    variables: ['x', 'y'],
  }).exact,
  '∅',
);

assert.equal(
  expectSuccess({
    operation: 'integrate',
    expression: '2*x*cos(x^2)',
    variable: 'x',
  }).exact,
  'sin(x^2)',
);
assert.equal(
  expectSuccess({
    operation: 'definiteIntegral',
    expression: 'sin(x)',
    variable: 'x',
    lowerBound: '0',
    upperBound: 'pi',
  }).exact,
  '2',
);
assert.equal(
  expectSuccess({
    operation: 'limit',
    expression: 'sin(x)/x',
    variable: 'x',
    point: '0',
  }).exact,
  '1',
);
assert.match(
  expectSuccess({
    operation: 'taylor',
    expression: 'exp(x)',
    variable: 'x',
    point: '0',
    order: 5,
  }).exact,
  /\(?1\/120\)?\*x\^5/,
);
assert.match(
  expectSuccess({
    operation: 'laplace',
    expression: 'sin(t)',
    variable: 't',
    targetVariable: 's',
  }).exact,
  /\(1\+s\^2\)\^\(-1\)/,
);

const symbolicMatrix = [
  ['a', 'b'],
  ['c', 'd'],
];
assert.equal(
  expectSuccess({ operation: 'determinant', matrix: symbolicMatrix }).exact,
  'a*d-b*c',
);
assert.match(
  expectSuccess({ operation: 'inverse', matrix: symbolicMatrix }).exact,
  /d\/\(a\*d-b\*c\)/,
);
assert.equal(
  expectSuccess({
    operation: 'rref',
    matrix: [
      ['1', '2'],
      ['2', '4'],
    ],
  }).exact,
  '[[1,2],[0,0]]',
);
expectFailure({
  operation: 'rref',
  matrix: [['x']],
}, 'unsupported');
assert.equal(
  expectSuccess({
    operation: 'rref',
    matrix: [['x', '1'], ['1', '0']],
  }).exact,
  '[[1,0],[0,1]]',
);
assert.match(
  expectSuccess({
    operation: 'characteristicPolynomial',
    matrix: symbolicMatrix,
    targetVariable: 'lambda',
  }).exact,
  /lambda\^2/,
);
assert.equal(
  expectSuccess({
    operation: 'eigenvalues',
    matrix: [
      ['2', '0'],
      ['0', '3'],
    ],
    targetVariable: 'lambda',
  }).exact,
  'lambda=2, lambda=3',
);

assert.equal(
  expectSuccess({
    operation: 'gradient',
    expression: 'x^2+y^2',
    variables: ['x', 'y'],
  }).exact,
  '[2*x,2*y]',
);
assert.equal(
  expectSuccess({
    operation: 'hessian',
    expression: 'x^2+x*y+y^2',
    variables: ['x', 'y'],
  }).exact,
  '[[2,1],[1,2]]',
);
assert.match(
  expectSuccess({
    operation: 'crossProduct',
    vector: ['a', 'b', 'c'],
    secondaryVector: ['x', 'y', 'z'],
  }).exact,
  /-c\*y\+b\*z/,
);

assert.equal(
  expectSuccess({
    operation: 'evaluate',
    expression: 'sin(30)',
    angleUnit: 'degree',
  }).exact,
  '1/2',
);
assert.equal(
  expectSuccess({
    operation: 'approximate',
    expression: 'asin(1/2)',
    angleUnit: 'degree',
  }).approximate,
  '30',
);
assert.equal(
  expectSuccess({
    operation: 'differentiate',
    expression: 'sin(x)',
    variable: 'x',
    angleUnit: 'degree',
  }).exact,
  'cos(x)',
);

const requestDefinitions = [
  { name: 'total', expression: '3' },
  { name: 'delta', expression: '1' },
  { name: 'f', parameters: ['x'], expression: 'x^2+total' },
];
assert.equal(
  expectSuccess({
    operation: 'evaluate',
    expression: 'f(2)',
    definitions: requestDefinitions,
  }).exact,
  '7',
);
assert.equal(
  expectSuccess({
    operation: 'differentiate',
    expression: 'f(x)',
    variable: 'x',
    definitions: requestDefinitions,
  }).exact,
  '2*x',
);
assert.equal(
  expectSuccess({
    operation: 'solveSystem',
    equations: ['x+y=total', 'x-y=delta'],
    variables: ['x', 'y'],
    definitions: requestDefinitions,
  }).exact,
  'x=2, y=1',
);
assert.equal(
  expectSuccess({
    operation: 'definiteIntegral',
    expression: 'sin(x)',
    variable: 'x',
    lowerBound: 'zero',
    upperBound: 'edge',
    definitions: [
      { name: 'zero', expression: '0' },
      { name: 'edge', expression: 'pi' },
    ],
  }).exact,
  '2',
);
assert.match(
  expectSuccess({
    operation: 'taylor',
    expression: 'exp(x)',
    variable: 'x',
    point: 'center',
    order: 3,
    definitions: [{ name: 'center', expression: '0' }],
  }).exact,
  /\(?1\/6\)?\*x\^3/,
);
assert.equal(
  expectSuccess({
    operation: 'determinant',
    matrix: [['scale', '0'], ['0', 'scale']],
    definitions: [{ name: 'scale', expression: '3' }],
  }).exact,
  '9',
);
assert.equal(
  expectSuccess({
    operation: 'dotProduct',
    vector: ['ans', '2'],
    secondaryVector: ['1', 'mem'],
    substitutions: { ans: '3', mem: '4' },
  }).exact,
  '11',
);
assert.equal(
  expectSuccess({
    operation: 'scalarMultiply',
    matrix: [['1', '2']],
    scalar: 'factorValue',
    definitions: [{ name: 'factorValue', expression: '3' }],
  }).exact,
  '[[3,6]]',
);

expectSuccess({
  operation: 'evaluate',
  expression: 'temporaryValue',
  definitions: [{ name: 'temporaryValue', expression: '7' }],
});
assert.equal(
  expectSuccess({ operation: 'evaluate', expression: 'temporaryValue' }).exact,
  'temporaryValue',
);
expectFailure({
  operation: 'evaluate',
  expression: 'a',
  definitions: [
    { name: 'a', expression: 'b+1' },
    { name: 'b', expression: 'a+1' },
  ],
});
expectFailure({
  operation: 'evaluate',
  expression: 'sin',
  definitions: [{ name: 'sin', expression: '1' }],
});

const nullSpace = expectSuccess({
  operation: 'nullSpace',
  matrix: [['1', '2'], ['2', '4']],
});
assert.equal(nullSpace.exact, '[[-2,1]]');
assert.equal(
  expectSuccess({
    operation: 'columnSpace',
    matrix: [['1', '2'], ['2', '4']],
  }).exact,
  '[[1],[2]]',
);
assert.equal(
  expectSuccess({
    operation: 'rowSpace',
    matrix: [['1', '2'], ['2', '4']],
  }).exact,
  '[[1,2]]',
);

const lu = expectSuccess({
  operation: 'luDecomposition',
  matrix: [['0', '2'], ['1', '3']],
});
assert.deepEqual(
  lu.parts.map(({ id, exact }) => [id, exact]),
  [['P', '[[0,1],[1,0]]'], ['L', '[[1,0],[0,1]]'], ['U', '[[1,3],[0,2]]']],
);
const qr = expectSuccess({
  operation: 'qrDecomposition',
  matrix: [['1', '0'], ['0', '1'], ['0', '0']],
});
assert.deepEqual(
  qr.parts.map(({ id, exact }) => [id, exact]),
  [['Q', '[[1,0],[0,1],[0,0]]'], ['R', '[[1,0],[0,1]]']],
);
const nontrivialQr = expectSuccess({
  operation: 'qrDecomposition',
  matrix: [['3', '0'], ['4', '5']],
});
assert.deepEqual(
  nontrivialQr.parts.map(({ id, exact }) => [id, exact]),
  [
    ['Q', '[[3/5,-4/5],[4/5,3/5]]'],
    ['R', '[[5,4],[0,3]]'],
  ],
);
assert.equal(
  expectSuccess({
    operation: 'gramSchmidt',
    matrix: [['1', '0'], ['0', '1'], ['0', '0']],
  }).exact,
  '[[1,0],[0,1],[0,0]]',
);
assert.equal(
  expectSuccess({
    operation: 'leastSquares',
    matrix: [['1', '0'], ['0', '1'], ['1', '1']],
    vector: ['1', '2', '4'],
  }).exact,
  '[4/3,7/3]',
);
assert.equal(
  expectSuccess({
    operation: 'vectorProjection',
    vector: ['2', '2'],
    secondaryVector: ['1', '0'],
  }).exact,
  '[2,0]',
);
assert.equal(
  expectSuccess({
    operation: 'dotProduct',
    vector: ['1', 'i'],
    secondaryVector: ['1', 'i'],
  }).exact,
  '2',
);
assert.equal(
  expectSuccess({
    operation: 'vectorNorm',
    vector: ['1', 'i'],
  }).exact,
  'sqrt(2)',
);
assert.equal(
  expectSuccess({
    operation: 'vectorProjection',
    vector: ['1', 'i'],
    secondaryVector: ['1', 'i'],
  }).exact,
  '[1,i]',
);
assert.deepEqual(
  expectSuccess({
    operation: 'qrDecomposition',
    matrix: [['i', '0'], ['0', '1']],
  }).parts.map(({ id, exact }) => [id, exact]),
  [['Q', '[[i,0],[0,1]]'], ['R', '[[1,0],[0,1]]']],
);
assert.equal(
  expectSuccess({
    operation: 'leastSquares',
    matrix: [['1'], ['i']],
    vector: ['1', 'i'],
  }).exact,
  '[1]',
);

assert.equal(
  expectSuccess({ operation: 'complexRealPart', expression: '3+4*i' }).exact,
  '3',
);
assert.equal(
  expectSuccess({ operation: 'complexImaginaryPart', expression: '3+4*i' }).exact,
  '4',
);
assert.equal(
  expectSuccess({ operation: 'complexConjugate', expression: '3+4*i' }).exact,
  '-4*i+3',
);
assert.equal(
  expectSuccess({ operation: 'complexMagnitude', expression: '3+4*i' }).exact,
  '5',
);
assert.equal(
  expectSuccess({
    operation: 'complexArgument',
    expression: '1+i',
    angleUnit: 'degree',
  }).approximate,
  '45',
);
const polar = expectSuccess({
  operation: 'complexPolarForm',
  expression: '3+4*i',
});
assert.deepEqual(polar.parts.map(({ id }) => id), ['magnitude', 'argument']);
assert.equal(polar.parts[0].exact, '5');
assert.equal(
  expectSuccess({
    operation: 'complexRectangularForm',
    expression: '2*(cos(pi/2)+i*sin(pi/2))',
  }).exact,
  '2*i',
);
assert.equal(
  expectSuccess({
    operation: 'complexFromPolar',
    radius: '2',
    angle: '90',
    angleUnit: 'degree',
  }).exact,
  '2*i',
);

expectFailure({
  operation: 'luDecomposition',
  matrix: [['1', '2'], ['2', '4']],
}, 'unsupported');
expectFailure({
  operation: 'qrDecomposition',
  matrix: [['1', '0', '0'], ['0', '1', '0']],
});
expectFailure({
  operation: 'vectorProjection',
  vector: ['1', '2'],
  secondaryVector: ['0', '0'],
});
expectFailure({
  operation: 'nullSpace',
  matrix: Array.from({ length: 9 }, () => ['1']),
}, 'resourceLimit');
expectFailure({
  operation: 'luDecomposition',
  matrix: [['a', '0'], ['0', '1']],
}, 'unsupported');
expectFailure({ operation: 'complexArgument', expression: '0' });

const multibyteDefinition = `${'α+'.repeat(700)}1`;
expectFailure({
  operation: 'evaluate',
  expression: '1',
  definitions: Array.from({ length: 32 }, (_, index) => ({
    name: `d${index}`,
    expression: multibyteDefinition,
  })),
}, 'resourceLimit');

const assignment = calculate({
  operation: 'evaluate',
  expression: 'f(x):=x^2',
});
assert.equal(assignment.ok, false);
assert.equal(assignment.error.code, 'invalidInput');

console.log('calculator CAS bridge checks passed');
