part of '../toolbox_life_tools.dart';

enum _CalculatorCatalogCategory {
  symbols,
  algebra,
  trigonometry,
  hyperbolic,
  complex,
  numberTheory,
  calculus,
  linearAlgebra,
  probability,
}

class _CalculatorCatalogEntry {
  const _CalculatorCatalogEntry({
    required this.signature,
    required this.category,
    this.insertion,
    this.cursorBack = 0,
    this.aliases = const <String>[],
    this.toolCategory,
    this.toolOperation,
  }) : assert(insertion != null || toolCategory != null);

  final String signature;
  final String? insertion;
  final int cursorBack;
  final _CalculatorCatalogCategory category;
  final List<String> aliases;
  final _CalculatorToolCategory? toolCategory;
  final ToolboxCalculatorOperation? toolOperation;

  bool matches(String query, String localizedCategory) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String>[
      signature,
      localizedCategory,
      ...aliases,
    ].join(' ').toLowerCase().contains(normalized);
  }
}

const _calculatorCatalogEntries = <_CalculatorCatalogEntry>[
  _CalculatorCatalogEntry(
    signature: 'π  pi',
    insertion: 'pi',
    category: _CalculatorCatalogCategory.symbols,
    aliases: <String>['circle constant'],
  ),
  _CalculatorCatalogEntry(
    signature: 'e',
    insertion: 'e',
    category: _CalculatorCatalogCategory.symbols,
  ),
  _CalculatorCatalogEntry(
    signature: 'τ  tau',
    insertion: 'tau',
    category: _CalculatorCatalogCategory.symbols,
  ),
  _CalculatorCatalogEntry(
    signature: 'φ  phi',
    insertion: 'phi',
    category: _CalculatorCatalogCategory.symbols,
  ),
  _CalculatorCatalogEntry(
    signature: 'i  √−1',
    insertion: 'i',
    category: _CalculatorCatalogCategory.symbols,
    aliases: <String>['imaginary unit'],
  ),
  _CalculatorCatalogEntry(
    signature: '∞  infinity',
    insertion: 'infinity',
    category: _CalculatorCatalogCategory.symbols,
  ),
  _CalculatorCatalogEntry(
    signature: 'Ans',
    insertion: 'ans',
    category: _CalculatorCatalogCategory.symbols,
  ),
  _CalculatorCatalogEntry(
    signature: 'Mem',
    insertion: 'mem',
    category: _CalculatorCatalogCategory.symbols,
  ),
  _CalculatorCatalogEntry(
    signature: 'θ  theta',
    insertion: 'theta',
    category: _CalculatorCatalogCategory.symbols,
  ),
  _CalculatorCatalogEntry(
    signature: 'λ  lambda',
    insertion: 'lambda',
    category: _CalculatorCatalogCategory.symbols,
  ),
  _CalculatorCatalogEntry(
    signature: '√x  sqrt(x)',
    insertion: 'sqrt()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: '∛x  cbrt(x)',
    insertion: 'cbrt()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'ⁿ√x  root(x,n)',
    insertion: 'root(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: '|x|  abs(x)',
    insertion: 'abs()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'x!  factorial',
    insertion: '!',
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'ln(x)  log(x)',
    insertion: 'log()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'logₐ(x)  log(x,a)',
    insertion: 'log(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'eˣ  exp(x)',
    insertion: 'exp()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: '⌊x⌋  floor(x)',
    insertion: 'floor()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: '⌈x⌉  ceil(x)',
    insertion: 'ceil()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'round(x)',
    insertion: 'round()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'min(a,b)',
    insertion: 'min(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'max(a,b)',
    insertion: 'max(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.algebra,
  ),
  _CalculatorCatalogEntry(
    signature: 'sin(x)',
    insertion: 'sin()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'cos(x)',
    insertion: 'cos()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'tan(x)',
    insertion: 'tan()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'sec(x)',
    insertion: 'sec()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'csc(x)',
    insertion: 'csc()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'cot(x)',
    insertion: 'cot()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'sin⁻¹(x)  asin(x)',
    insertion: 'asin()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'cos⁻¹(x)  acos(x)',
    insertion: 'acos()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'tan⁻¹(x)  atan(x)',
    insertion: 'atan()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'atan2(y,x)',
    insertion: 'atan2(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.trigonometry,
  ),
  _CalculatorCatalogEntry(
    signature: 'sinh(x)',
    insertion: 'sinh()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.hyperbolic,
  ),
  _CalculatorCatalogEntry(
    signature: 'cosh(x)',
    insertion: 'cosh()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.hyperbolic,
  ),
  _CalculatorCatalogEntry(
    signature: 'tanh(x)',
    insertion: 'tanh()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.hyperbolic,
  ),
  _CalculatorCatalogEntry(
    signature: 'sinh⁻¹(x)  asinh(x)',
    insertion: 'asinh()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.hyperbolic,
  ),
  _CalculatorCatalogEntry(
    signature: 'cosh⁻¹(x)  acosh(x)',
    insertion: 'acosh()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.hyperbolic,
  ),
  _CalculatorCatalogEntry(
    signature: 'tanh⁻¹(x)  atanh(x)',
    insertion: 'atanh()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.hyperbolic,
  ),
  _CalculatorCatalogEntry(
    signature: 'Re(z)',
    category: _CalculatorCatalogCategory.complex,
    toolCategory: _CalculatorToolCategory.complex,
    toolOperation: ToolboxCalculatorOperation.complexRealPart,
  ),
  _CalculatorCatalogEntry(
    signature: 'Im(z)',
    category: _CalculatorCatalogCategory.complex,
    toolCategory: _CalculatorToolCategory.complex,
    toolOperation: ToolboxCalculatorOperation.complexImaginaryPart,
  ),
  _CalculatorCatalogEntry(
    signature: 'z̄  conjugate(z)',
    insertion: 'conjugate()',
    cursorBack: 1,
    category: _CalculatorCatalogCategory.complex,
  ),
  _CalculatorCatalogEntry(
    signature: '|z|',
    category: _CalculatorCatalogCategory.complex,
    toolCategory: _CalculatorToolCategory.complex,
    toolOperation: ToolboxCalculatorOperation.complexMagnitude,
  ),
  _CalculatorCatalogEntry(
    signature: 'arg(z)',
    category: _CalculatorCatalogCategory.complex,
    toolCategory: _CalculatorToolCategory.complex,
    toolOperation: ToolboxCalculatorOperation.complexArgument,
  ),
  _CalculatorCatalogEntry(
    signature: 'r·eⁱᶿ  polar(z)',
    category: _CalculatorCatalogCategory.complex,
    toolCategory: _CalculatorToolCategory.complex,
    toolOperation: ToolboxCalculatorOperation.complexPolarForm,
  ),
  _CalculatorCatalogEntry(
    signature: 'a+b·i  rect(z)',
    category: _CalculatorCatalogCategory.complex,
    toolCategory: _CalculatorToolCategory.complex,
    toolOperation: ToolboxCalculatorOperation.complexRectangularForm,
  ),
  _CalculatorCatalogEntry(
    signature: 'gcd(a,b)',
    insertion: 'gcd(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.numberTheory,
  ),
  _CalculatorCatalogEntry(
    signature: 'lcm(a,b)',
    insertion: 'lcm(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.numberTheory,
  ),
  _CalculatorCatalogEntry(
    signature: 'a mod b',
    insertion: 'mod(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.numberTheory,
  ),
  _CalculatorCatalogEntry(
    signature: 'nCr(n,r)',
    insertion: 'nCr(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.numberTheory,
  ),
  _CalculatorCatalogEntry(
    signature: 'nPr(n,r)',
    insertion: 'nPr(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.numberTheory,
  ),
  _CalculatorCatalogEntry(
    signature: 'factor(x)',
    category: _CalculatorCatalogCategory.numberTheory,
    toolCategory: _CalculatorToolCategory.algebra,
    toolOperation: ToolboxCalculatorOperation.factor,
  ),
  _CalculatorCatalogEntry(
    signature: 'd/dx  diff(f,x)',
    insertion: 'diff(,x)',
    cursorBack: 3,
    category: _CalculatorCatalogCategory.calculus,
  ),
  _CalculatorCatalogEntry(
    signature: '∫f dx  integrate(f,x)',
    insertion: 'integrate(,x)',
    cursorBack: 3,
    category: _CalculatorCatalogCategory.calculus,
  ),
  _CalculatorCatalogEntry(
    signature: '∫ₐᵇf dx  defint(f,a,b,x)',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.definiteIntegral,
  ),
  _CalculatorCatalogEntry(
    signature: 'limₓ→ₐ f(x)',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.limit,
  ),
  _CalculatorCatalogEntry(
    signature: 'Σ  sum(f,k,a,b)',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.summation,
  ),
  _CalculatorCatalogEntry(
    signature: 'Π  product(f,k,a,b)',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.product,
  ),
  _CalculatorCatalogEntry(
    signature: '∇f  gradient(f)',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.gradient,
  ),
  _CalculatorCatalogEntry(
    signature: '∇·F  divergence(F)',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.divergence,
  ),
  _CalculatorCatalogEntry(
    signature: '∇×F  curl(F)',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.curl,
  ),
  _CalculatorCatalogEntry(
    signature: 'H(f)  Hessian',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.hessian,
  ),
  _CalculatorCatalogEntry(
    signature: 'ℒ{f}  Laplace',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.laplace,
  ),
  _CalculatorCatalogEntry(
    signature: 'ℒ⁻¹{F}',
    category: _CalculatorCatalogCategory.calculus,
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.inverseLaplace,
  ),
  _CalculatorCatalogEntry(
    signature: '[[a,b],[c,d]]',
    insertion: '[[,],[,]]',
    cursorBack: 7,
    category: _CalculatorCatalogCategory.linearAlgebra,
    aliases: <String>['matrix'],
  ),
  _CalculatorCatalogEntry(
    signature: 'det(A)',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.determinant,
  ),
  _CalculatorCatalogEntry(
    signature: 'A⁻¹',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.inverse,
  ),
  _CalculatorCatalogEntry(
    signature: 'Aᵀ',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.transpose,
  ),
  _CalculatorCatalogEntry(
    signature: 'rref(A)',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.rref,
  ),
  _CalculatorCatalogEntry(
    signature: 'ker(A)',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.nullSpace,
  ),
  _CalculatorCatalogEntry(
    signature: 'col(A)',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.columnSpace,
  ),
  _CalculatorCatalogEntry(
    signature: 'row(A)',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.rowSpace,
  ),
  _CalculatorCatalogEntry(
    signature: 'PA = LU',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.luDecomposition,
  ),
  _CalculatorCatalogEntry(
    signature: 'A = QR',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.qrDecomposition,
  ),
  _CalculatorCatalogEntry(
    signature: 'min ‖Ax−b‖₂',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.leastSquares,
  ),
  _CalculatorCatalogEntry(
    signature: 'projᵥ(u)',
    category: _CalculatorCatalogCategory.linearAlgebra,
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.vectorProjection,
  ),
  _CalculatorCatalogEntry(
    signature: 'nCr(n,r)',
    insertion: 'nCr(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.probability,
  ),
  _CalculatorCatalogEntry(
    signature: 'nPr(n,r)',
    insertion: 'nPr(,)',
    cursorBack: 2,
    category: _CalculatorCatalogCategory.probability,
  ),
  _CalculatorCatalogEntry(
    signature: 'P(X=k)  Binomial PMF',
    category: _CalculatorCatalogCategory.probability,
    toolCategory: _CalculatorToolCategory.probability,
  ),
  _CalculatorCatalogEntry(
    signature: 'P(X≤k)  Binomial CDF',
    category: _CalculatorCatalogCategory.probability,
    toolCategory: _CalculatorToolCategory.probability,
  ),
  _CalculatorCatalogEntry(
    signature: 'φ(x; μ,σ)  Normal PDF',
    category: _CalculatorCatalogCategory.probability,
    toolCategory: _CalculatorToolCategory.probability,
  ),
  _CalculatorCatalogEntry(
    signature: 'Φ(x; μ,σ)  Normal CDF',
    category: _CalculatorCatalogCategory.probability,
    toolCategory: _CalculatorToolCategory.probability,
  ),
];

String _calculatorCatalogCategoryKey(_CalculatorCatalogCategory category) {
  return 'toolbox.life.advanced_calculator.catalog.category.${category.name}';
}
