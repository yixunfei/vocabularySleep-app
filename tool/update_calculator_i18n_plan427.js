const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const csvPath = path.join(root, 'lib/l10n/catalog/app_texts.csv');
const registryPath = path.join(
  root,
  'lib/l10n/catalog/app_text_registry.json',
);

const rows = [
  ['toolbox.life.advanced_calculator.summary', '离线高级科学计算器，支持连续输入、符号代数、高等数学、复数、矩阵分解、向量与概率计算。', 'Offline advanced calculator for continuous input, symbolic algebra, higher mathematics, complex numbers, matrix decompositions, vectors, and probability.', '連続入力、記号代数、高等数学、複素数、行列分解、ベクトル、確率計算に対応するオフライン高機能電卓。', 'Offline-Rechner für fortlaufende Eingaben, symbolische Algebra, höhere Mathematik, komplexe Zahlen, Matrixzerlegungen, Vektoren und Wahrscheinlichkeit.', 'Calculatrice avancée hors ligne pour la saisie continue, l’algèbre symbolique, les mathématiques supérieures, les nombres complexes, les décompositions matricielles, les vecteurs et les probabilités.', 'Calculadora avanzada sin conexión para entrada continua, álgebra simbólica, matemáticas superiores, números complejos, descomposiciones matriciales, vectores y probabilidad.', 'Продвинутый офлайн-калькулятор для непрерывного ввода, символьной алгебры, высшей математики, комплексных чисел, разложений матриц, векторов и вероятностей.'],
  ['toolbox.life.advanced_calculator.subtitle', '连续输入并复用精确结果；专业工具覆盖代数、微积分、高级线性代数、复数与概率。', 'Enter continuously and reuse exact results, with tools for algebra, calculus, advanced linear algebra, complex numbers, and probability.', '連続入力して厳密結果を再利用できます。代数、微積分、高度な線形代数、複素数、確率の専門ツールを備えています。', 'Fortlaufend eingeben und exakte Ergebnisse weiterverwenden, mit Werkzeugen für Algebra, Analysis, fortgeschrittene lineare Algebra, komplexe Zahlen und Wahrscheinlichkeit.', 'Saisissez en continu et réutilisez les résultats exacts, avec des outils d’algèbre, d’analyse, d’algèbre linéaire avancée, de nombres complexes et de probabilités.', 'Introduce datos de forma continua y reutiliza resultados exactos, con herramientas de álgebra, cálculo, álgebra lineal avanzada, números complejos y probabilidad.', 'Вводите выражения непрерывно и повторно используйте точные результаты с инструментами алгебры, анализа, продвинутой линейной алгебры, комплексных чисел и вероятностей.'],
  ['toolbox.life.advanced_calculator.category.complex', '复数', 'Complex', '複素数', 'Komplex', 'Complexes', 'Complejos', 'Комплексные'],
  ['toolbox.life.advanced_calculator.section.linear_advanced', '子空间与矩阵分解', 'Subspaces and decompositions', '部分空間と行列分解', 'Unterräume und Zerlegungen', 'Sous-espaces et décompositions', 'Subespacios y descomposiciones', 'Подпространства и разложения'],
  ['toolbox.life.advanced_calculator.section.linear_advanced_hint', '零空间、列空间、行空间、PLU、QR、最小二乘与正交归一；最小二乘使用矩阵 A 和向量 A。', 'Null, column, and row spaces; PLU, QR, least squares, and orthonormalization. Least squares uses matrix A and vector A.', '零空間・列空間・行空間、PLU、QR、最小二乗、正規直交化。最小二乗では行列 A とベクトル A を使用します。', 'Null-, Spalten- und Zeilenraum; PLU, QR, kleinste Quadrate und Orthonormalisierung. Kleinste Quadrate verwendet Matrix A und Vektor A.', 'Espaces nul, colonne et ligne ; PLU, QR, moindres carrés et orthonormalisation. Les moindres carrés utilisent la matrice A et le vecteur A.', 'Espacios nulo, columna y fila; PLU, QR, mínimos cuadrados y ortonormalización. Mínimos cuadrados usa la matriz A y el vector A.', 'Нулевое пространство, пространства столбцов и строк; PLU, QR, МНК и ортонормирование. МНК использует матрицу A и вектор A.'],
  ['toolbox.life.advanced_calculator.section.complex', '复数分析', 'Complex analysis', '複素数演算', 'Komplexe Rechnung', 'Calcul complexe', 'Cálculo complejo', 'Комплексные вычисления'],
  ['toolbox.life.advanced_calculator.section.complex_hint', '对当前表达式计算实部、虚部、共轭、模、辐角及极式；辐角遵循当前 DEG/RAD。', 'Compute real and imaginary parts, conjugate, magnitude, argument, and polar form for the current expression. Arguments follow DEG/RAD.', '現在の式の実部、虚部、共役、絶対値、偏角、極形式を計算します。偏角は DEG/RAD に従います。', 'Real- und Imaginärteil, Konjugation, Betrag, Argument und Polarform des aktuellen Ausdrucks berechnen. Argumente folgen DEG/RAD.', 'Calculez les parties réelle et imaginaire, le conjugué, le module, l’argument et la forme polaire de l’expression. Les arguments suivent DEG/RAD.', 'Calcula las partes real e imaginaria, conjugado, módulo, argumento y forma polar de la expresión. Los argumentos siguen DEG/RAD.', 'Вычисляет действительную и мнимую части, сопряжение, модуль, аргумент и полярную форму выражения. Аргумент учитывает DEG/RAD.'],
  ['toolbox.life.advanced_calculator.section.polar_input', '从极坐标构造', 'Build from polar coordinates', '極座標から構成', 'Aus Polarkoordinaten bilden', 'Construire depuis les coordonnées polaires', 'Construir desde coordenadas polares', 'Построить из полярных координат'],
  ['toolbox.life.advanced_calculator.section.polar_input_hint', '半径可使用精确表达式；角度按当前 DEG/RAD 解释。', 'The radius can be an exact expression; the angle uses the current DEG/RAD setting.', '半径には厳密な式を使用でき、角度は現在の DEG/RAD で解釈されます。', 'Der Radius kann ein exakter Ausdruck sein; der Winkel verwendet die aktuelle DEG/RAD-Einstellung.', 'Le rayon peut être une expression exacte ; l’angle utilise le réglage DEG/RAD actuel.', 'El radio puede ser una expresión exacta; el ángulo usa el ajuste DEG/RAD actual.', 'Радиус может быть точным выражением; угол интерпретируется в текущем режиме DEG/RAD.'],
  ['toolbox.life.advanced_calculator.complex_radius', '半径 r', 'Radius r', '半径 r', 'Radius r', 'Rayon r', 'Radio r', 'Радиус r'],
  ['toolbox.life.advanced_calculator.complex_angle', '角度 θ', 'Angle θ', '角度 θ', 'Winkel θ', 'Angle θ', 'Ángulo θ', 'Угол θ'],
  ['toolbox.life.advanced_calculator.operation.null_space', '零空间', 'Null space', '零空間', 'Nullraum', 'Noyau', 'Espacio nulo', 'Нулевое пространство'],
  ['toolbox.life.advanced_calculator.operation.column_space', '列空间', 'Column space', '列空間', 'Spaltenraum', 'Espace colonne', 'Espacio columna', 'Пространство столбцов'],
  ['toolbox.life.advanced_calculator.operation.row_space', '行空间', 'Row space', '行空間', 'Zeilenraum', 'Espace ligne', 'Espacio fila', 'Пространство строк'],
  ['toolbox.life.advanced_calculator.operation.lu_decomposition', 'PLU 分解', 'PLU decomposition', 'PLU 分解', 'PLU-Zerlegung', 'Décomposition PLU', 'Descomposición PLU', 'PLU-разложение'],
  ['toolbox.life.advanced_calculator.operation.qr_decomposition', 'QR 分解', 'QR decomposition', 'QR 分解', 'QR-Zerlegung', 'Décomposition QR', 'Descomposición QR', 'QR-разложение'],
  ['toolbox.life.advanced_calculator.operation.least_squares', '最小二乘', 'Least squares', '最小二乗', 'Kleinste Quadrate', 'Moindres carrés', 'Mínimos cuadrados', 'Метод наименьших квадратов'],
  ['toolbox.life.advanced_calculator.operation.gram_schmidt', 'Gram-Schmidt 正交化', 'Gram-Schmidt', 'グラム・シュミット法', 'Gram-Schmidt', 'Gram-Schmidt', 'Gram-Schmidt', 'Процесс Грама-Шмидта'],
  ['toolbox.life.advanced_calculator.operation.vector_projection', '向量投影', 'Vector projection', 'ベクトル射影', 'Vektorprojektion', 'Projection vectorielle', 'Proyección vectorial', 'Проекция вектора'],
  ['toolbox.life.advanced_calculator.operation.complex_real_part', '实部', 'Real part', '実部', 'Realteil', 'Partie réelle', 'Parte real', 'Действительная часть'],
  ['toolbox.life.advanced_calculator.operation.complex_imaginary_part', '虚部', 'Imaginary part', '虚部', 'Imaginärteil', 'Partie imaginaire', 'Parte imaginaria', 'Мнимая часть'],
  ['toolbox.life.advanced_calculator.operation.complex_conjugate', '复共轭', 'Complex conjugate', '複素共役', 'Komplex konjugiert', 'Conjugué complexe', 'Conjugado complejo', 'Комплексное сопряжение'],
  ['toolbox.life.advanced_calculator.operation.complex_magnitude', '复数模', 'Magnitude', '絶対値', 'Betrag', 'Module', 'Módulo', 'Модуль'],
  ['toolbox.life.advanced_calculator.operation.complex_argument', '辐角', 'Argument', '偏角', 'Argument', 'Argument', 'Argumento', 'Аргумент'],
  ['toolbox.life.advanced_calculator.operation.complex_polar_form', '极形式', 'Polar form', '極形式', 'Polarform', 'Forme polaire', 'Forma polar', 'Полярная форма'],
  ['toolbox.life.advanced_calculator.operation.complex_rectangular_form', '直角坐标形式', 'Rectangular form', '直交形式', 'Kartesische Form', 'Forme cartésienne', 'Forma rectangular', 'Алгебраическая форма'],
  ['toolbox.life.advanced_calculator.operation.complex_from_polar', '转换为直角坐标', 'Convert to rectangular', '直交形式へ変換', 'In kartesische Form umwandeln', 'Convertir en forme cartésienne', 'Convertir a forma rectangular', 'Преобразовать в алгебраическую форму'],
  ['toolbox.life.advanced_calculator.structured_result', '结构化结果', 'Structured result', '構造化された結果', 'Strukturiertes Ergebnis', 'Résultat structuré', 'Resultado estructurado', 'Структурированный результат'],
  ['toolbox.life.advanced_calculator.result_parts', '结果部件', 'Result parts', '結果の各要素', 'Ergebnisteile', 'Parties du résultat', 'Partes del resultado', 'Части результата'],
  ['toolbox.life.advanced_calculator.result_parts_count', '{count} 个结果部件', '{count} result parts', '結果の要素: {count} 件', '{count} Ergebnisteile', '{count} parties du résultat', '{count} partes del resultado', 'Частей результата: {count}'],
  ['toolbox.life.advanced_calculator.catalog.title', '函数与符号目录', 'Function and symbol catalog', '関数・記号カタログ', 'Funktions- und Symbolkatalog', 'Catalogue des fonctions et symboles', 'Catálogo de funciones y símbolos', 'Каталог функций и символов'],
  ['toolbox.life.advanced_calculator.catalog.search_hint', '搜索函数、符号或公式', 'Search functions, symbols, or formulas', '関数・記号・数式を検索', 'Funktionen, Symbole oder Formeln suchen', 'Rechercher des fonctions, symboles ou formules', 'Buscar funciones, símbolos o fórmulas', 'Поиск функций, символов или формул'],
  ['toolbox.life.advanced_calculator.catalog.filter', '分类', 'Category', 'カテゴリ', 'Kategorie', 'Catégorie', 'Categoría', 'Категория'],
  ['toolbox.life.advanced_calculator.catalog.empty', '没有匹配的函数或符号。', 'No matching functions or symbols.', '一致する関数や記号はありません。', 'Keine passenden Funktionen oder Symbole.', 'Aucune fonction ni aucun symbole correspondant.', 'No hay funciones ni símbolos coincidentes.', 'Подходящие функции или символы не найдены.'],
  ['toolbox.life.advanced_calculator.catalog.insert', '插入输入框', 'Insert into input', '入力欄に挿入', 'In Eingabe einfügen', 'Insérer dans la saisie', 'Insertar en la entrada', 'Вставить в поле ввода'],
  ['toolbox.life.advanced_calculator.catalog.open_tool', '打开专业工具', 'Open specialist tool', '専門ツールを開く', 'Spezialwerkzeug öffnen', 'Ouvrir l’outil spécialisé', 'Abrir herramienta especializada', 'Открыть специальный инструмент'],
  ['toolbox.life.advanced_calculator.catalog.category.all', '全部分类', 'All categories', 'すべてのカテゴリ', 'Alle Kategorien', 'Toutes les catégories', 'Todas las categorías', 'Все категории'],
  ['toolbox.life.advanced_calculator.catalog.category.symbols', '常量与符号', 'Constants and symbols', '定数と記号', 'Konstanten und Symbole', 'Constantes et symboles', 'Constantes y símbolos', 'Константы и символы'],
  ['toolbox.life.advanced_calculator.catalog.category.algebra', '代数', 'Algebra', '代数', 'Algebra', 'Algèbre', 'Álgebra', 'Алгебра'],
  ['toolbox.life.advanced_calculator.catalog.category.trigonometry', '三角函数', 'Trigonometry', '三角関数', 'Trigonometrie', 'Trigonométrie', 'Trigonometría', 'Тригонометрия'],
  ['toolbox.life.advanced_calculator.catalog.category.hyperbolic', '双曲函数', 'Hyperbolic functions', '双曲線関数', 'Hyperbelfunktionen', 'Fonctions hyperboliques', 'Funciones hiperbólicas', 'Гиперболические функции'],
  ['toolbox.life.advanced_calculator.catalog.category.complex', '复数', 'Complex numbers', '複素数', 'Komplexe Zahlen', 'Nombres complexes', 'Números complejos', 'Комплексные числа'],
  ['toolbox.life.advanced_calculator.catalog.category.numberTheory', '数论与组合', 'Number theory and combinatorics', '数論と組合せ', 'Zahlentheorie und Kombinatorik', 'Théorie des nombres et combinatoire', 'Teoría de números y combinatoria', 'Теория чисел и комбинаторика'],
  ['toolbox.life.advanced_calculator.catalog.category.calculus', '微积分', 'Calculus', '微積分', 'Analysis', 'Analyse', 'Cálculo', 'Математический анализ'],
  ['toolbox.life.advanced_calculator.catalog.category.linearAlgebra', '线性代数', 'Linear algebra', '線形代数', 'Lineare Algebra', 'Algèbre linéaire', 'Álgebra lineal', 'Линейная алгебра'],
  ['toolbox.life.advanced_calculator.catalog.category.probability', '概率', 'Probability', '確率', 'Wahrscheinlichkeit', 'Probabilités', 'Probabilidad', 'Вероятность'],
];

const locales = ['zh', 'en', 'ja', 'de', 'fr', 'es', 'ru'];

function csvCell(value) {
  const text = String(value);
  return /[",\r\n]/u.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function updateCsv() {
  let source = fs.readFileSync(csvPath, 'utf8').replace(/\r\n/gu, '\n');
  const byKey = new Map(rows.map((row) => [row[0], row]));
  const found = new Set();
  const lines = source.split('\n').map((line, index) => {
    if (index === 0 || line === '') return line;
    const key = line.split(',', 1)[0];
    const row = byKey.get(key);
    if (row === undefined) return line;
    found.add(key);
    return row.map(csvCell).join(',');
  });
  for (const row of rows) {
    if (!found.has(row[0])) lines.push(row.map(csvCell).join(','));
  }
  source = `${lines.filter((line, index) => line !== '' || index === 0).join('\n')}\n`;
  fs.writeFileSync(csvPath, source, 'utf8');
}

function sourceFileFor(id) {
  if (id.includes('.catalog.')) {
    return 'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_calculator_catalog.dart';
  }
  if (id.includes('.result_') || id.endsWith('.structured_result')) {
    return 'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_calculator_result_parts.dart';
  }
  if (id.includes('.complex') || id.includes('.polar_')) {
    return 'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_calculator_complex_tools.dart';
  }
  return 'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_calculator_linear_tools.dart';
}

function updateRegistry() {
  const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));
  const byId = new Map(registry.entries.map((entry) => [entry.id, entry]));
  for (const row of rows) {
    const [id, ...translations] = row;
    const texts = Object.fromEntries(
      locales.map((locale, index) => [locale, translations[index]]),
    );
    const existing = byId.get(id);
    if (existing !== undefined) {
      existing.texts = texts;
      continue;
    }
    registry.entries.push({
      id,
      kind: 'i18n_runtime_reference',
      status: 'runtime_wired',
      sourceSystem: 'AppI18n.t',
      texts,
      sources: [{
        file: sourceFileFor(id),
        context: 'PLAN_427 calculator linear algebra, complex, and catalog',
      }],
      sourceCount: 1,
      placeholders: id.endsWith('.result_parts_count') ? ['count'] : [],
    });
  }
  registry.lastPlan427CalculatorAdvancedDomains = {
    date: '2026-08-30',
    addedCatalogKeys: rows.length - 2,
    updatedCatalogKeys: 2,
    retiredCatalogKeys: 0,
    source: 'PLAN_427 calculator linear algebra, complex, and catalog',
  };
  fs.writeFileSync(registryPath, `${JSON.stringify(registry, null, 2)}\n`, 'utf8');
}

updateCsv();
updateRegistry();
console.log(`PLAN_427 calculator i18n rows synchronized: ${rows.length}`);
