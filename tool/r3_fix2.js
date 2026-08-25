// PLAN_417 第三轮（第二批）：标题类 key 的 ja/de/fr/es/ru 英文回退补译
// 范围：wear.advisor 审计/颜色/分层/场景标题、crypto 工具标题、life 工具标题、
//       life.hub 分类 label、sound.focus 预设标题（共 40 key，只填 5 个语言列）
// 跳过：地图源品牌名 6 key 与 veracrypt.title（品牌写法七语言一致为有意设计）
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const CSV = path.join(ROOT, 'lib/l10n/catalog/app_texts.csv');

const s = fs.readFileSync(CSV, 'utf8');

function parseWithOffsets(src) {
  const records = [];
  let cur = [], field = '', q = false, start = 0;
  for (let i = 0; i < src.length; i++) {
    const c = src[i];
    if (q) {
      if (c === '"') { if (src[i + 1] === '"') { field += '"'; i++; } else q = false; }
      else field += c;
    } else {
      if (c === '"') q = true;
      else if (c === ',') { cur.push(field); field = ''; }
      else if (c === '\n') {
        cur.push(field);
        records.push({ f: cur, start, end: i + 1 });
        cur = []; field = ''; start = i + 1;
      } else if (c !== '\r') field += c;
    }
  }
  if (field !== '' || cur.length) records.push({ f: cur, start, end: src.length });
  return records;
}

function esc(v) {
  if (/[",\n\r]/.test(v)) return '"' + v.replace(/"/g, '""') + '"';
  return v;
}

const recs = parseWithOffsets(s);
console.log('records:', recs.length);
const keyIndex = new Map();
for (let i = 1; i < recs.length; i++) keyIndex.set(recs[i].f[0], i);

// ---- key -> [zh, en, ja, de, fr, es, ru]（zh/en 均为 null，只补五语言）----
const FIX = {
  // ===== wear.advisor 审计维度 =====
  'daily_choice.wear.advisor.audit.care.title': [null, null,
    'お手入れと細部', 'Pflege & Details', 'Entretien et détails', 'Cuidado y detalles', 'Уход и детали'],
  'daily_choice.wear.advisor.audit.movement.title': [null, null,
    '動きやすさ', 'Bewegungsfreiheit', 'Liberté de mouvement', 'Libertad de movimiento', 'Свобода движений'],
  'daily_choice.wear.advisor.audit.proportion.title': [null, null,
    'バランス調整', 'Proportionen', 'Proportions', 'Proporción', 'Пропорции'],
  'daily_choice.wear.advisor.audit.scene.title': [null, null,
    'シーン適合', 'Anlass-Tauglichkeit', 'Adapté à l’occasion', 'Adecuado a la ocasión', 'Соответствие ситуации'],
  'daily_choice.wear.advisor.audit.shoes_bag.title': [null, null,
    '靴とバッグの統一', 'Schuhe und Tasche', 'Chaussures et sac', 'Zapatos y bolso', 'Обувь и сумка'],
  'daily_choice.wear.advisor.audit.temperature.title': [null, null,
    '気温と体感', 'Temperatur', 'Température', 'Temperatura', 'Температура'],
  // ===== wear.advisor 颜色 =====
  'daily_choice.wear.advisor.color.accent.title': [null, null,
    '差し色', 'Akzentfarbe', 'Touche de couleur', 'Color de acento', 'Яркий акцент'],
  'daily_choice.wear.advisor.color.black.title': [null, null,
    'ブラック', 'Schwarz', 'Noir', 'Negro', 'Чёрный'],
  'daily_choice.wear.advisor.color.khaki.title': [null, null,
    'カーキベージュ', 'Khaki', 'Kaki', 'Caqui', 'Хаки'],
  'daily_choice.wear.advisor.color.navy.title': [null, null,
    'ネイビー', 'Marineblau', 'Bleu marine', 'Azul marino', 'Тёмно-синий'],
  'daily_choice.wear.advisor.color.white.title': [null, null,
    'ホワイト', 'Weiß', 'Blanc', 'Blanco', 'Белый'],
  // ===== wear.advisor 分层（天气）=====
  'daily_choice.wear.advisor.layer.cold.title': [null, null,
    '寒い日', 'Kalt', 'Froid', 'Frío', 'Холодно'],
  'daily_choice.wear.advisor.layer.hot.title': [null, null,
    '暑い日', 'Heiß', 'Chaud', 'Calor', 'Жарко'],
  'daily_choice.wear.advisor.layer.mild.title': [null, null,
    '穏やか', 'Mild', 'Doux', 'Templado', 'Умеренно'],
  'daily_choice.wear.advisor.layer.rain.title': [null, null,
    '雨の日', 'Regen', 'Pluie', 'Lluvia', 'Дождь'],
  // ===== wear.advisor 场景 =====
  'daily_choice.wear.advisor.scene.business.title': [null, null,
    'フォーマル', 'Business', 'Professionnel', 'Negocios', 'Деловой'],
  'daily_choice.wear.advisor.scene.commute.title': [null, null,
    '通勤', 'Pendeln', 'Trajet quotidien', 'Trayecto diario', 'Поездка на работу'],
  'daily_choice.wear.advisor.scene.date.title': [null, null,
    'デート', 'Date', 'Rendez-vous', 'Cita', 'Свидание'],
  'daily_choice.wear.advisor.scene.exercise.title': [null, null,
    'スポーツ', 'Sport', 'Sport', 'Deporte', 'Спорт'],
  'daily_choice.wear.advisor.scene.rain.title': [null, null,
    '雨の日', 'Regen', 'Pluie', 'Lluvia', 'Дождь'],
  // ===== crypto 工具标题 =====
  'toolbox.crypto.file.title': [null, null,
    'ファイル暗号化', 'Dateiverschlüsselung', 'Chiffrement de fichiers', 'Cifrado de archivos', 'Шифрование файлов'],
  'toolbox.crypto.hash.title': [null, null,
    'ハッシュ検証', 'Hash-Prüfung', 'Vérification de hachage', 'Comprobación de hash', 'Проверка хеша'],
  'toolbox.crypto.hmac.title': [null, null,
    'HMAC / MAC', 'HMAC / MAC', 'HMAC / MAC', 'HMAC / MAC', 'HMAC / MAC'],
  'toolbox.crypto.otp.title': [null, null,
    'TOTP/HOTP コード', 'TOTP/HOTP-Codes', 'Codes TOTP/HOTP', 'Códigos TOTP/HOTP', 'Коды TOTP/HOTP'],
  'toolbox.crypto.password_vault.title': [null, null,
    'マイパスワード', 'Meine Passwörter', 'Mes mots de passe', 'Mis contraseñas', 'Мои пароли'],
  'toolbox.crypto.text.title': [null, null,
    'テキスト暗号化', 'Textverschlüsselung', 'Chiffrement de texte', 'Cifrado de texto', 'Шифрование текста'],
  // ===== life 工具标题 =====
  'toolbox.life.distance_meter.title': [null, null,
    '距離メーター', 'Entfernungsmesser', 'Télémètre', 'Medidor de distancia', 'Дальномер'],
  'toolbox.life.light_meter.title': [null, null,
    '照度計', 'Belichtungsmesser', 'Luxmètre', 'Luxómetro', 'Люксметр'],
  'toolbox.life.magnifier.title': [null, null,
    'ルーペ', 'Lupe', 'Loupe', 'Lupa', 'Лупа'],
  'toolbox.life.menstrual_cycle.title': [null, null,
    '生理サイクル', 'Menstruationszyklus', 'Cycle menstruel', 'Ciclo menstrual', 'Менструальный цикл'],
  'toolbox.life.speedometer.title': [null, null,
    '速度計', 'Tachometer', 'Compteur de vitesse', 'Velocímetro', 'Спидометр'],
  // ===== life.hub 分类 label =====
  'toolbox.life.hub.category.calc.label': [null, null,
    '計算ツール', 'Rechner', 'Calculateurs', 'Calculadoras', 'Калькуляторы'],
  'toolbox.life.hub.category.display.label': [null, null,
    '画面表示', 'Anzeige-Tools', 'Affichage', 'Pantalla', 'Экранный показ'],
  'toolbox.life.hub.category.image.label': [null, null,
    '画像とメディア', 'Bild & Medien', 'Image et médias', 'Imagen y medios', 'Изображения и медиа'],
  'toolbox.life.hub.category.system.label': [null, null,
    'システムツール', 'System-Tools', 'Outils système', 'Herramientas del sistema', 'Системные инструменты'],
  'toolbox.life.hub.category.text.label': [null, null,
    'テキストツール', 'Text-Tools', 'Outils de texte', 'Herramientas de texto', 'Текстовые инструменты'],
  'toolbox.life.hub.category.web.label': [null, null,
    '検索とウェブ', 'Suche & Web', 'Recherche et web', 'Consulta y web', 'Запросы и веб'],
  // ===== sound.focus 预设标题 =====
  'toolbox.sound.focus.quick_presets.deep.title': [null, null,
    'ディープ', 'Tief und ruhig', 'Profond et stable', 'Profundo y constante', 'Глубокий ровный'],
  'toolbox.sound.focus.quick_presets.sprint.title': [null, null,
    'スプリント', 'Sprint', 'Sprint', 'Esprint', 'Спринт'],
  'toolbox.sound.focus.quick_presets.steady.title': [null, null,
    'ステーディ', 'Ruhig', 'Stable', 'Estable', 'Ровный'],
};

// ---- 应用替换（含 ref.* 镜像自动同步）----
let changed = 0;
const edits = [];
for (const [key, vals] of Object.entries(FIX)) {
  const targets = [key];
  if (keyIndex.has('ref.' + key)) targets.push('ref.' + key);
  for (const t of targets) {
    const rec = recs[keyIndex.get(t)];
    if (!rec) { console.log('MISSING:', t); continue; }
    const orig = rec.f;
    if (orig.length !== 8) { console.log('BAD COLS, skip:', t, orig.length); continue; }
    const row = orig.slice();
    for (let c = 0; c < 7; c++) {
      if (vals[c] !== null) row[c + 1] = vals[c];
    }
    const line = row.map(esc).join(',');
    const endsWithNL = s[rec.end - 1] === '\n';
    edits.push({ start: rec.start, end: rec.end, text: line + (endsWithNL ? '\n' : '') });
    changed++;
  }
}

edits.sort((a, b) => b.start - a.start);
let out = s;
for (const e of edits) out = out.slice(0, e.start) + e.text + out.slice(e.end);
fs.writeFileSync(CSV, out, 'utf8');
console.log('rows changed:', changed);

const recs2 = parseWithOffsets(fs.readFileSync(CSV, 'utf8'));
console.log('records after:', recs2.length);
let bad = 0;
for (let i = 1; i < recs2.length; i++) if (recs2[i].f.length !== 8) bad++;
console.log('bad column rows after:', bad);
