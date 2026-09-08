const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const csvPath = path.join(root, 'lib/l10n/catalog/app_texts.csv');
const registryPath = path.join(
  root,
  'lib/l10n/catalog/app_text_registry.json',
);

const rows = [
  ['toolbox.life.advanced_calculator.angle_semantics', '直接三角：DEG/RAD；微积分与符号：RAD', 'Direct trig: DEG/RAD; calculus and symbols: RAD', '数値三角: DEG/RAD、微積分・記号: RAD', 'Direkte Trigonometrie: DEG/RAD; Analysis und Symbole: RAD', 'Trigonométrie directe : DEG/RAD ; calcul et symboles : RAD', 'Trigonometría directa: DEG/RAD; cálculo y símbolos: RAD', 'Прямая тригонометрия: DEG/RAD; анализ и символы: RAD'],
  ['toolbox.life.advanced_calculator.expression_toolbar', '输入编辑', 'Input editing', '入力編集', 'Eingabe bearbeiten', 'Modification de la saisie', 'Edición de entrada', 'Редактирование ввода'],
  ['toolbox.life.advanced_calculator.undo', '撤销', 'Undo', '元に戻す', 'Rückgängig', 'Annuler', 'Deshacer', 'Отменить'],
  ['toolbox.life.advanced_calculator.redo', '重做', 'Redo', 'やり直す', 'Wiederholen', 'Rétablir', 'Rehacer', 'Повторить'],
  ['toolbox.life.advanced_calculator.definition.manage', '变量与函数', 'Variables and functions', '変数と関数', 'Variablen und Funktionen', 'Variables et fonctions', 'Variables y funciones', 'Переменные и функции'],
  ['toolbox.life.advanced_calculator.definition.title', '命名变量与函数', 'Named variables and functions', '名前付き変数と関数', 'Benannte Variablen und Funktionen', 'Variables et fonctions nommées', 'Variables y funciones con nombre', 'Именованные переменные и функции'],
  ['toolbox.life.advanced_calculator.definition.subtitle', '定义仅在当前计算器会话中有效。', 'Definitions are scoped to this calculator session.', '定義はこの計算機セッション内でのみ有効です。', 'Definitionen gelten nur in dieser Rechnersitzung.', 'Les définitions sont limitées à cette session de calcul.', 'Las definiciones se limitan a esta sesión de cálculo.', 'Определения действуют только в этом сеансе калькулятора.'],
  ['toolbox.life.advanced_calculator.definition.add', '新增定义', 'Add definition', '定義を追加', 'Definition hinzufügen', 'Ajouter une définition', 'Añadir definición', 'Добавить определение'],
  ['toolbox.life.advanced_calculator.definition.edit', '编辑定义', 'Edit definition', '定義を編集', 'Definition bearbeiten', 'Modifier la définition', 'Editar definición', 'Изменить определение'],
  ['toolbox.life.advanced_calculator.definition.delete', '删除定义', 'Delete definition', '定義を削除', 'Definition löschen', 'Supprimer la définition', 'Eliminar definición', 'Удалить определение'],
  ['toolbox.life.advanced_calculator.definition.empty', '尚未定义变量或函数。', 'No variables or functions are defined yet.', '変数または関数はまだ定義されていません。', 'Noch sind keine Variablen oder Funktionen definiert.', 'Aucune variable ni fonction n’est encore définie.', 'Aún no se han definido variables ni funciones.', 'Переменные и функции пока не определены.'],
  ['toolbox.life.advanced_calculator.definition.add_title', '新建定义', 'New definition', '新しい定義', 'Neue Definition', 'Nouvelle définition', 'Nueva definición', 'Новое определение'],
  ['toolbox.life.advanced_calculator.definition.edit_title', '编辑定义', 'Edit definition', '定義を編集', 'Definition bearbeiten', 'Modifier la définition', 'Editar definición', 'Изменить определение'],
  ['toolbox.life.advanced_calculator.definition.variable', '变量', 'Variable', '変数', 'Variable', 'Variable', 'Variable', 'Переменная'],
  ['toolbox.life.advanced_calculator.definition.function', '函数', 'Function', '関数', 'Funktion', 'Fonction', 'Función', 'Функция'],
  ['toolbox.life.advanced_calculator.definition.name', '名称', 'Name', '名前', 'Name', 'Nom', 'Nombre', 'Имя'],
  ['toolbox.life.advanced_calculator.definition.parameters', '参数', 'Parameters', '引数', 'Parameter', 'Paramètres', 'Parámetros', 'Параметры'],
  ['toolbox.life.advanced_calculator.definition.parameters_help', '使用逗号分隔，最多 4 个参数。', 'Separate with commas; up to 4 parameters.', 'カンマで区切り、最大 4 個まで指定できます。', 'Mit Kommas trennen; maximal 4 Parameter.', 'Séparez-les par des virgules ; 4 paramètres maximum.', 'Sepáralos con comas; máximo 4 parámetros.', 'Разделяйте запятыми; не более 4 параметров.'],
  ['toolbox.life.advanced_calculator.definition.expression', '定义表达式', 'Definition expression', '定義式', 'Definitionsausdruck', 'Expression de définition', 'Expresión de definición', 'Выражение определения'],
  ['toolbox.life.advanced_calculator.definition.save', '保存定义', 'Save definition', '定義を保存', 'Definition speichern', 'Enregistrer la définition', 'Guardar definición', 'Сохранить определение'],
  ['toolbox.life.advanced_calculator.definition.error.limit', '最多可保存 32 个定义。', 'Up to 32 definitions can be saved.', '保存できる定義は最大 32 個です。', 'Es können höchstens 32 Definitionen gespeichert werden.', 'Vous pouvez enregistrer jusqu’à 32 définitions.', 'Se pueden guardar hasta 32 definiciones.', 'Можно сохранить не более 32 определений.'],
  ['toolbox.life.advanced_calculator.definition.error.invalidName', '名称必须是有效的数学标识符。', 'The name must be a valid mathematical identifier.', '名前は有効な数式識別子である必要があります。', 'Der Name muss ein gültiger mathematischer Bezeichner sein.', 'Le nom doit être un identifiant mathématique valide.', 'El nombre debe ser un identificador matemático válido.', 'Имя должно быть допустимым математическим идентификатором.'],
  ['toolbox.life.advanced_calculator.definition.error.reservedName', '该名称已被计算器保留。', 'This name is reserved by the calculator.', 'この名前は計算機で予約されています。', 'Dieser Name ist für den Rechner reserviert.', 'Ce nom est réservé par la calculatrice.', 'Este nombre está reservado por la calculadora.', 'Это имя зарезервировано калькулятором.'],
  ['toolbox.life.advanced_calculator.definition.error.duplicateName', '已存在同名定义。', 'A definition with this name already exists.', '同じ名前の定義がすでに存在します。', 'Eine Definition mit diesem Namen ist bereits vorhanden.', 'Une définition portant ce nom existe déjà.', 'Ya existe una definición con este nombre.', 'Определение с таким именем уже существует.'],
  ['toolbox.life.advanced_calculator.definition.error.invalidParameters', '参数必须唯一且为有效名称，最多 4 个。', 'Parameters must be unique valid names, with a maximum of 4.', '引数は重複しない有効な名前で、最大 4 個までです。', 'Parameter müssen eindeutige gültige Namen sein; maximal 4.', 'Les paramètres doivent être des noms valides et uniques, au maximum 4.', 'Los parámetros deben ser nombres válidos y únicos, con un máximo de 4.', 'Параметры должны иметь уникальные допустимые имена; не более 4.'],
  ['toolbox.life.advanced_calculator.definition.error.invalidExpression', '定义表达式为空、过长或包含不支持的赋值。', 'The definition expression is empty, too long, or contains an unsupported assignment.', '定義式が空、長すぎる、または未対応の代入を含んでいます。', 'Der Definitionsausdruck ist leer, zu lang oder enthält eine nicht unterstützte Zuweisung.', 'L’expression de définition est vide, trop longue ou contient une affectation non prise en charge.', 'La expresión de definición está vacía, es demasiado larga o contiene una asignación no compatible.', 'Выражение определения пусто, слишком длинное или содержит неподдерживаемое присваивание.'],
  ['toolbox.life.advanced_calculator.definition.error.cyclicDependency', '定义之间存在循环依赖。', 'The definitions contain a cyclic dependency.', '定義に循環依存があります。', 'Die Definitionen enthalten eine zyklische Abhängigkeit.', 'Les définitions contiennent une dépendance cyclique.', 'Las definiciones contienen una dependencia cíclica.', 'Определения содержат циклическую зависимость.'],
  ['toolbox.life.advanced_calculator.result_route.title', '继续计算到', 'Continue result to', '結果の使用先', 'Ergebnis weiterverwenden in', 'Continuer le résultat vers', 'Continuar el resultado en', 'Продолжить результат в'],
  ['toolbox.life.advanced_calculator.result_route.expression', '主表达式', 'Main expression', 'メイン式', 'Hauptausdruck', 'Expression principale', 'Expresión principal', 'Основное выражение'],
  ['toolbox.life.advanced_calculator.result_route.matrix_a', '矩阵 A', 'Matrix A', '行列 A', 'Matrix A', 'Matrice A', 'Matriz A', 'Матрица A'],
  ['toolbox.life.advanced_calculator.result_route.matrix_b', '矩阵 B', 'Matrix B', '行列 B', 'Matrix B', 'Matrice B', 'Matriz B', 'Матрица B'],
  ['toolbox.life.advanced_calculator.result_route.vector_a', '向量 A', 'Vector A', 'ベクトル A', 'Vektor A', 'Vecteur A', 'Vector A', 'Вектор A'],
  ['toolbox.life.advanced_calculator.result_route.vector_b', '向量 B', 'Vector B', 'ベクトル B', 'Vektor B', 'Vecteur B', 'Vector B', 'Вектор B'],
  ['toolbox.life.advanced_calculator.result_route.invalid', '该结果无法写入所选输入。', 'This result cannot be written to the selected input.', 'この結果は選択した入力に書き込めません。', 'Dieses Ergebnis kann nicht in die ausgewählte Eingabe übernommen werden.', 'Ce résultat ne peut pas être écrit dans l’entrée sélectionnée.', 'Este resultado no se puede escribir en la entrada seleccionada.', 'Этот результат нельзя записать в выбранное поле.'],
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

function updateRegistry() {
  const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));
  const knownKeys = new Set(
    registry.entries.map((entry) => entry.id || entry.key).filter(Boolean),
  );
  for (const row of rows) {
    const [id, ...translations] = row;
    const texts = Object.fromEntries(
      locales.map((locale, index) => [locale, translations[index]]),
    );
    if (knownKeys.has(id)) {
      const existing = registry.entries.find((entry) => entry.id === id);
      if (existing !== undefined) existing.texts = texts;
      continue;
    }
    const sourceFile = id.includes('.result_route.')
      ? 'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_calculator_result_routing.dart'
      : id.includes('.definition.')
        ? 'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_calculator_definitions.dart'
        : 'lib/src/ui/pages/toolbox_life_tools/toolbox_life_tools_calculator_workspace.dart';
    registry.entries.push({
      id,
      kind: 'i18n_runtime_reference',
      status: 'runtime_wired',
      sourceSystem: 'AppI18n.t',
      texts,
      sources: [{ file: sourceFile, context: 'PLAN_426 calculator continuous workspace' }],
      sourceCount: 1,
      placeholders: [],
    });
  }
  registry.lastPlan426CalculatorWorkspace = {
    date: '2026-08-30',
    addedCatalogKeys: rows.length,
    retiredCatalogKeys: 0,
    source: 'PLAN_426 calculator semantic consistency and continuous workspace',
  };
  fs.writeFileSync(registryPath, `${JSON.stringify(registry, null, 2)}\n`, 'utf8');
}

updateCsv();
updateRegistry();
console.log(`PLAN_426 calculator i18n keys synchronized: ${rows.length}`);
