// PLAN_417 第三轮：标题/描述文案准确性修复（基线重放，整行替换）
// 范围：
//   A. 结构性损坏修复（2 行，含逗号未加引号导致列错位）并补齐七语言
//   B. 准确性修复（分区副标题与代码不符、模糊标题、句号不一致、漏句号、生硬措辞）
//   C. 标题/描述类 key 的 ja/de/fr/es/ru 英文回退补译（60 key）
// 规则：只改文案列，不增删 key；含逗号/引号的字段按 RFC4180 加引号；
//       自动同步对应 ref.* 镜像行。
const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..');
const CSV = path.join(ROOT, 'lib/l10n/catalog/app_texts.csv');

const s = fs.readFileSync(CSV, 'utf8');

// ---- RFC4180 解析（带记录偏移）----
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

// ---- 修复数据：key -> [zh, en, ja, de, fr, es, ru] ----
const FIX = {
  // ===== A. 结构性损坏修复（原行列错位）=====
  'toolbox.sound.focus.quick_presets.subtitle': [
    '一键切换速度、拍号、细分、音色和视觉，先开始再细调。',
    'Switch tempo, meter, subdivision, tone, and visuals in one tap.',
    'テンポ、拍子、细分、音色、ビジュアルをワンタップで切り替え。まず始めてから細調整。',
    'Tempo, Taktart, Unterteilung, Klang und Visuals mit einem Tippen wechseln – erst starten, dann feinjustieren.',
    'Changez tempo, mesure, subdivision, timbre et visuels en un geste ; commencez d’abord, ajustez ensuite.',
    'Cambia tempo, compás, subdivisión, timbre y visuales con un toque; empieza primero y ajusta después.',
    'Переключайте темп, размер, доли, тембр и визуал одним касанием — начните, а потом подстраивайте.',
  ],
  'toolbox.sound.focus.quick_presets.deep.subtitle': [
    '慢速双细分，适合呼吸、阅读和长时间稳定跟拍。',
    'Slow double subdivision for breathing, reading, and longer steady sessions.',
    'ゆっくりした二分割で、呼吸や読書、長時間の安定したテンポ維持に最適。',
    'Langsame Doppelunterteilung für Atmung, Lesen und lange, ruhige Sessions.',
    'Double subdivision lente pour la respiration, la lecture et les longues sessions régulières.',
    'Doble subdivisión lenta para respirar, leer y sesiones largas y constantes.',
    'Медленное двойное деление для дыхания, чтения и долгих ровных сессий.',
  ],
  // ===== B. 准确性修复 =====
  // calm 分区实际只有静心念珠与随心沙盘两个工具，原副标题误称"冥想工具"
  'toolbox.hub.section.calm.subtitle': [
    '静心念珠与随心沙盘，随手可得的平静时刻。',
    'Mindful beads and finger sand art — quick moments of calm.',
    'マインドフルビーズとフィンガーサンドアートで、いつでも穏やかなひとときを。',
    'Achtsamkeitsperlen und Fingersandkunst – ruhige Momente jederzeit.',
    'Perles de pleine conscience et art du sable au doigt : des instants de calme à portée de main.',
    'Cuentas conscientes y arte de arena con los dedos: momentos de calma al instante.',
    'Осознанные бусины и песочное искусство пальцами — спокойствие под рукой.',
  ],
  // 触发条件为平均睡眠 < 360 分钟，原标题"显示出一定的模式"过于模糊
  'toolbox.sleep.library.advice_weekly_sleep_amount.title': [
    '你的总睡眠时间偏短',
    'Your total sleep time is on the short side',
    '総睡眠時間がやや短めです',
    'Ihre Gesamtschlafzeit ist eher kurz',
    'Votre temps de sommeil total est un peu court',
    'Tu tiempo total de sueño es algo corto',
    'Ваше общее время сна коротковато',
  ],
  'toolbox.sleep.library.advice_weekly_sleep_amount.body': [
    '你的平均睡眠时间不足 6 小时。关注固定的起床时间而不是就寝时间——这是调节昼夜节律的更强锚点。',
    'Your average sleep is under six hours. Focus on a consistent wake time rather than bedtime — it is the stronger anchor for your circadian rhythm.',
    '平均睡眠時間が6時間未満です。就寝時刻より固定の起床時刻を意識しましょう。概日リズムを整える、より強力な錨です。',
    'Ihr durchschnittlicher Schlaf liegt unter sechs Stunden. Achten Sie auf eine feste Aufwachzeit statt der Schlafenszeit – sie ist der stärkere Anker für Ihren circadianen Rhythmus.',
    'Votre sommeil moyen est inférieur à six heures. Misez sur une heure de réveil régulière plutôt que l’heure du coucher : c’est l’ancre la plus forte de votre rythme circadien.',
    'Duermes menos de seis horas de media. Céntrate en una hora de despertar constante en vez de la de acostarte: es el ancla más fuerte de tu ritmo circadiano.',
    'Ваш средний сон меньше шести часов. Сосредоточьтесь на постоянном времени подъёма, а не отбоя — это более сильный якорь для циркадного ритма.',
  ],
  // 标题类文案去掉句末句号，与其他建议标题保持一致
  'toolbox.sleep.library.advice_weekly_environment.title': [
    '你的睡眠环境需要关注',
    'Your sleep environment needs attention',
    'あなたの睡眠環境は注意が必要です',
    'Ihr Schlafumfeld benötigt Aufmerksamkeit',
    'Votre environnement de sommeil nécessite une attention',
    'Tu entorno de sueño necesita atención',
    'Вашему спальному окружению требуется внимание',
  ],
  'toolbox.sleep.library.advice_weekly_light.title': [
    '早晨光照是你最强大的节律工具',
    'Morning light is your strongest rhythm tool',
    '朝の光はあなたの最も強力なリズムツールです',
    'Morgenlicht ist dein stärkstes Rhythmus-Werkzeug',
    'La lumière du matin est votre outil de rythme le plus puissant',
    'La luz de la mañana es tu herramienta de ritmo más poderosa',
    'Утренний свет — ваш самый сильный инструмент для регулирования ритма',
  ],
  // "临门修正"措辞生硬，改为更直白的"出门前修正"
  'daily_choice.wear.advisor.quick_fixes.title': [
    '出门前修正',
    'Quick fixes',
    '出かける前のクイック修正',
    'Letzte Korrekturen',
    'Corrections de dernière minute',
    'Ajustes de última hora',
    'Быстрые правки перед выходом',
  ],
  // 补齐句末标点，与其他 summary 一致
  'study.library.wordbook.deferred.summary': [
    '已选中《{wordbook}》。列表可轻量浏览；播放或练习前会完整加载 {count} 个单词。',
    'Selected {wordbook}. Browsing uses a light list. Playback or practice will load {count} words first.',
    null, null, null, null, null,
  ],
  // 品牌名空格一致性（其他语言复用英文品牌写法）
  'toolbox.crypto.veracrypt.title': [
    'VeraCrypt 容器',
    'VeraCrypt container',
    null, null, null, null, null,
  ],
  // ===== C. ja/de/fr/es/ru 英文回退补译（仅填 5 个语言列）=====
  'toolbox.crypto.asymmetric.title': [null, null,
    '公開鍵・秘密鍵ツール', 'Public-/Private-Key-Werkzeuge', 'Outils à clés publique/privée', 'Herramientas de clave pública/privada', 'Инструменты открытого и закрытого ключей'],
  'toolbox.crypto.asymmetric.subtitle': [null, null,
    'ローカルで RSA/ECC 鍵を生成し、署名と検証を行い、RSA-OAEP で短いテキストを暗号化・復号します。',
    'Erzeuge lokale RSA/ECC-Schlüssel, signiere und prüfe Nachrichten und nutze RSA-OAEP für die Verschlüsselung kurzer Texte.',
    'Générez des clés RSA/ECC locales, signez et vérifiez des messages, et chiffrez de courts textes avec RSA-OAEP.',
    'Genera claves RSA/ECC locales, firma y verifica mensajes y usa RSA-OAEP para cifrar textos cortos.',
    'Создавайте локальные ключи RSA/ECC, подписывайте и проверяйте сообщения и шифруйте короткие тексты через RSA-OAEP.'],
  'toolbox.crypto.content_media.title': [null, null,
    'コンテンツを画像/音声へ', 'Inhalt zu Bild/Audio', 'Contenu vers image/audio', 'Contenido a imagen/audio', 'Контент в изображение/аудио'],
  'toolbox.crypto.content_media.subtitle': [null, null,
    'まず v5 暗号化封筒に格納し、それを PNG の色ブロックや PCM WAV サンプルとして可逆配置します。',
    'Zuerst in einen v5-Umschlag verschlüsseln, dann verlustfrei als PNG-Farblöcke oder PCM-WAV-Samples anordnen.',
    'Chiffrez dans une enveloppe v5, puis disposez-la sans perte en blocs de couleurs PNG ou en échantillons PCM WAV.',
    'Cifra en un sobre v5 y luego colócalo sin pérdida como bloques de color PNG o muestras PCM WAV.',
    'Сначала упакуйте в зашифрованный конверт v5, затем без потерь разложите в цвета PNG или сэмплы PCM WAV.'],
  'toolbox.crypto.file.subtitle': [null, null,
    'ローカルでの高速処理に特化したマルチアルゴリズムのファイル暗号化ツール。エクスポート可能な .vsc 暗号化封筒ファイルを出力します。',
    'Ein lokales, leistungsstarkes Multi-Algorithmus-Tool zur Dateiverschlüsselung, das exportierbare .vsc-Umschlagdateien ausgibt.',
    'Un outil local haute performance de chiffrement de fichiers multi-algorithmes, produisant des enveloppes .vsc exportables.',
    'Herramienta local de alto rendimiento para cifrar archivos con varios algoritmos; genera sobres cifrados .vsc exportables.',
    'Локальный высокопроизводительный инструмент шифрования файлов с несколькими алгоритмами; создаёт экспортируемые конверты .vsc.'],
  'toolbox.crypto.hash.subtitle': [null, null,
    'テキストやファイルの MD5、SHA、SHA3、BLAKE2b、Whirlpool ダイジェストを計算し、信頼できるソースの期待値と比較します。',
    'Berechne MD5-, SHA-, SHA3-, BLAKE2b- und Whirlpool-Hashes für Texte oder Dateien und vergleiche sie mit erwarteten Werten aus vertrauenswürdigen Quellen.',
    'Calculez les empreintes MD5, SHA, SHA3, BLAKE2b et Whirlpool de textes ou fichiers et comparez-les aux empreintes attendues d’une source fiable.',
    'Calcula resúmenes MD5, SHA, SHA3, BLAKE2b y Whirlpool de textos o archivos y compáralos con los esperados de una fuente confiable.',
    'Вычисляйте дайджесты MD5, SHA, SHA3, BLAKE2b и Whirlpool для текста или файлов и сравнивайте их с ожидаемыми из надёжного источника.'],
  'toolbox.crypto.hmac.subtitle': [null, null,
    '共有秘密鍵でテキストやファイルのメッセージ認証コードを生成し、ダイジェストを貼り付けて定数時間形式で検証できます。',
    'Erzeuge mit einem gemeinsamen Geheimnis einen MAC für Texte oder Dateien und füge einen Digest zur konstantzeitigen Prüfung ein.',
    'Générez un code d’authentification pour textes ou fichiers avec un secret partagé, puis collez un digest pour une vérification à temps constant.',
    'Genera un código de autenticación para textos o archivos con un secreto compartido y pega un resumen para verificarlo en tiempo constante.',
    'Создавайте код аутентификации для текста или файлов с общим секретом и вставляйте дайджест для проверки за константное время.'],
  'toolbox.crypto.password.title': [null, null,
    'パスワード生成ツール', 'Passwortgenerator', 'Générateur de mots de passe', 'Generador de contraseñas', 'Генератор паролей'],
  'toolbox.crypto.keyfile.title': [null, null,
    '鍵ファイル管理', 'Schlüsseldatei-Verwaltung', 'Gestion des fichiers de clés', 'Gestor de archivos de claves', 'Менеджер ключевых файлов'],
  'toolbox.crypto.shamir.title': [null, null,
    'Shamir 秘密分散', 'Shamir Secret Sharing', 'Partage de secret de Shamir', 'Secreto compartido de Shamir', 'Разделение секрета Шамира'],
  'toolbox.crypto.veracrypt.subtitle': [null,
    'Mobile-first VeraCrypt container tool for decrypting, browsing, exporting, and creating containers.',
    'モバイル優先の VeraCrypt コンテナツール。復号、閲覧、エクスポート、作成に対応します。',
    'Mobile-First-Tool für VeraCrypt-Container: entschlüsseln, durchsuchen, exportieren und erstellen.',
    'Outil VeraCrypt pensé pour mobile : déchiffrer, parcourir, exporter et créer des conteneurs.',
    'Herramienta VeraCrypt para móvil: descifrar, explorar, exportar y crear contenedores.',
    'Инструмент для контейнеров VeraCrypt с упором на мобильные: расшифровка, просмотр, экспорт и создание.'],
  'toolbox.crypto.keyfile.subtitle': [null, null,
    '単独鍵ファイルの生成、パスフレーズからの派生、順序に依存しない結合を行い、ファイル暗号化モジュールと重ねて使えます。',
    'Erzeuge, passewort-deriviere und kombiniere unabhängige Schlüsseldateien (reihenfolgeunabhängig) als Ergänzung zur Dateiverschlüsselung.',
    'Générez, dérivez par mot de passe et combinez sans ordre imposé des fichiers de clés, en complément du chiffrement de fichiers.',
    'Genera, deriva por contraseña y combina sin orden fijo archivos de claves para usarlos junto al cifrado de archivos.',
    'Создавайте, выводите из пароля и комбинируйте без учёта порядка ключевые файлы для совместного использования с шифрованием файлов.'],
  'toolbox.crypto.otp.subtitle': [null, null,
    'Base32 シークレット、TOTP のタイムステップ、HOTP のカウンタに対応し、ワンタイムコードをローカルで計算します。',
    'Berechne Einmalcodes lokal mit Base32-Secrets, TOTP-Zeitschritten und HOTP-Zählern.',
    'Calculez des codes à usage unique en local avec des secrets Base32, des pas de temps TOTP et des compteurs HOTP.',
    'Calcula códigos de un solo uso en local con secretos Base32, pasos de tiempo TOTP y contadores HOTP.',
    'Вычисляйте одноразовые коды локально с секретами Base32, временными шагами TOTP и счётчиками HOTP.'],
  'toolbox.crypto.password.subtitle': [null, null,
    'ランダムパスワードをオフラインで一括生成。パスフレーズ生成とエントロピー推定にも対応し、結果はローカルに保存されません。',
    'Erzeuge offline Passwort-Batches oder Passphrasen mit Entropie-Schätzung; Ergebnisse werden nicht lokal gespeichert.',
    'Générez par lots des mots de passe aléatoires hors ligne ou des phrases de passe avec estimation d’entropie ; rien n’est stocké localement.',
    'Genera lotes de contraseñas aleatorias sin conexión o frases de contraseña con estimación de entropía; no se guardan en local.',
    'Офлайн-генерация паролей партиями или парольных фраз с оценкой энтропии; результаты не записываются в локальное хранилище.'],
  'toolbox.crypto.password_vault.subtitle': [null, null,
    'アカウント情報をローカルの暗号化ボールトに保存。ボールトを選び、対応する認証情報でロック解除します。',
    'Kontodaten lokal verschlüsselt speichern; Tresor auswählen und mit den passenden Zugangsdaten entsperren.',
    'Stockez vos comptes dans un coffre chiffré local ; sélectionnez un coffre et déverrouillez-le avec les bons identifiants.',
    'Guarda cuentas en una bóveda cifrada local; elige una bóveda y desbloquéala con sus credenciales.',
    'Храните записи аккаунтов в локальном зашифрованном хранилище; выберите хранилище и разблокируйте его подходящими данными.'],
  'toolbox.crypto.shamir.subtitle': [null, null,
    'テキストの秘密やソルト付きパスワード定義を閾値付きシェアに分割、または十分な数のシェアから復元します。シェアは分けて保管してください。',
    'Teile ein Textgeheimnis oder eine saltierte Passwortdefinition in Schwellenwert-Shares auf oder stelle es aus genügend Shares wieder her; Shares getrennt aufbewahren.',
    'Divisez un secret texte ou une définition de mot de passe salé en parts à seuil, ou reconstituez-le avec assez de parts ; conservez-les séparément.',
    'Divide un secreto de texto o una definición de contraseña con sal en partes con umbral, o recupéralo con partes suficientes; guárdalas por separado.',
    'Разделяйте текстовый секрет или определение пароля с солью на пороговые доли или восстанавливайте из достаточного числа долей; храните доли отдельно.'],
  'toolbox.crypto.text.subtitle': [null, null,
    'テキストを直接暗号化・復号し、コピー可能な Base64 v5 暗号化封筒を出力します。',
    'Verschlüssle oder entschlüssle Text direkt und kopiere den Base64-v5-Umschlag.',
    'Chiffrez ou déchiffrez directement du texte et copiez l’enveloppe Base64 v5.',
    'Cifra o descifra texto directamente y copia el sobre Base64 v5.',
    'Шифруйте или расшифровывайте текст напрямую и копируйте конверт Base64 v5.'],
  'daily_choice.wear.weather.suggestion.summary': [null, null,
    '現在の体感温度 {temperature}°C に基づき、デフォルトで「{category}」を推奨します。',
    'Basierend auf der gefühlten Temperatur von {temperature}°C wird standardmäßig „{category}“ empfohlen.',
    'D’après une température ressentie de {temperature}°C, la suggestion par défaut est « {category} ».',
    'Con una sensación térmica de {temperature}°C, la sugerencia por defecto es «{category}».',
    'При ощущаемой температуре {temperature}°C по умолчанию рекомендуется уровень «{category}».'],
  'toolbox.life.archive_tool.title': [null, null,
    'モバイル圧縮・解凍ツール', 'Mobiles Archiv-Werkzeug', 'Outil d’archivage mobile', 'Herramienta de archivado móvil', 'Мобильный архиватор'],
  'toolbox.life.archive_tool.subtitle': [null, null,
    'モバイルでの一時的な圧縮・解凍に最適。ZIP、TAR、tar.gz、tar.bz2、tar.xz、gz、bz2、xz を作成でき、RAR/7z の制限も明示します。',
    'Praktisch für mobiles Packen und Entpacken unterwegs. Erstellt ZIP, TAR, tar.gz, tar.bz2, tar.xz, gz, bz2 oder xz und zeigt RAR/7z-Einschränkungen klar an.',
    'Pratique pour compacter et extraire sur mobile : créez ZIP, TAR, tar.gz, tar.bz2, tar.xz, gz, bz2 ou xz, avec les limites RAR/7z clairement indiquées.',
    'Útil para empaquetar y extraer en el móvil: crea ZIP, TAR, tar.gz, tar.bz2, tar.xz, gz, bz2 o xz, con avisos claros sobre las limitaciones de RAR/7z.',
    'Подходит для упаковки и распаковки на телефоне: создаёт ZIP, TAR, tar.gz, tar.bz2, tar.xz, gz, bz2 и xz и ясно показывает ограничения RAR/7z.'],
  'toolbox.life.menstrual_cycle.subtitle': [null, null,
    '直近の生理開始日と周期長からローカルで推算する、生活補助向けの記録ツールです。',
    'Schätzt lokal anhand der letzten Periode und Zykluslänge – als Alltagsbegleiter.',
    'Estime localement à partir des dernières règles et de la durée du cycle, comme aide au quotidien.',
    'Estima localmente a partir de la última menstruación y la duración del ciclo, como ayuda diaria.',
    'Локальная оценка по последней менструации и длине цикла — как бытовой помощник.'],
  'toolbox.life.advanced_calculator.title': [null, null,
    '高度な計算機', 'Erweiterter Rechner', 'Calculatrice avancée', 'Calculadora avanzada', 'Продвинутый калькулятор'],
  'toolbox.life.advanced_calculator.subtitle': [null, null,
    '数式の入力や専門パネルの切り替えで、科学計算、行列演算、確率分布の推定を行えます。',
    'Formeln eingeben oder Profi-Paneele nutzen für wissenschaftliche Berechnungen, Matrixoperationen und Wahrscheinlichkeitsverteilungen.',
    'Saisissez des expressions ou passez aux panneaux experts pour le calcul scientifique, les matrices et les lois de probabilité.',
    'Introduce expresiones o cambia a paneles profesionales para cálculo científico, matrices y estimaciones de probabilidad.',
    'Вводите выражения или переключайте профессиональные панели для научных вычислений, матриц и оценки распределений.'],
  'toolbox.life.distance_meter.subtitle': [null, null,
    '位置情報で2点間の距離を測定するか、対象の高さを入力してスマホの傾きから距離を概算します。',
    'Markiere zwei GPS-Punkte oder gib eine Zielhöhe ein und schätze die Entfernung per Handyneigung.',
    'Marquez deux points GPS ou saisissez une hauteur cible et estimez la distance via l’inclinaison du téléphone.',
    'Marca dos puntos GPS o introduce una altura objetivo y estima la distancia con la inclinación del teléfono.',
    'Отметьте две точки GPS или введите высоту цели и оцените расстояние по наклону телефона.'],
  'toolbox.life.gif_maker.title': [null, null,
    '動画から GIF 作成', 'Video-zu-GIF-Ersteller', 'Créateur de GIF à partir de vidéos', 'Creador de GIF a partir de vídeo', 'Конвертер видео в GIF'],
  'toolbox.life.gif_maker.subtitle': [null, null,
    '動画を選んでトリミング範囲をドラッグし、フレームレート、幅、品質を設定して GIF を生成します。',
    'Video wählen, Trimmbereich ziehen, FPS, Breite und Qualität einstellen und ein GIF erstellen.',
    'Choisissez une vidéo, faites glisser la plage de découpe, réglez FPS, largeur et qualité, puis créez un GIF.',
    'Elige un vídeo, arrastra el rango de recorte, ajusta FPS, ancho y calidad, y crea un GIF.',
    'Выберите видео, перетащите диапазон обрезки, задайте FPS, ширину и качество и создайте GIF.'],
  'toolbox.life.hub.category.display.desc': [null, null,
    '時計、弾幕、補助ライト、スコアボードなど、画面表示に特化したツール。',
    'Uhren, Barragen, Fülllicht und Anzeigetafeln – direkt für die Bildschirmanzeige.',
    'Horloge, barrage, lumière d’appoint et tableau de score : des outils pensés pour l’affichage plein écran.',
    'Reloj, lluvia de mensajes, luz de relleno y marcador: herramientas para mostrar en pantalla.',
    'Часы, «бегущая строка», подсветка и табло — инструменты для показа на экране.'],
  'toolbox.life.hub.category.system.desc': [null, null,
    '端末の状態、振動、圧縮アーカイブ、リマインダー、着信シミュレーションなどのシステム補助ツール。',
    'Systemhelfer für Telefonstatus, Vibration, Archive, Erinnerungen und simulierte Anrufe.',
    'Aides système : état du téléphone, vibrations, archives, rappels et faux appels.',
    'Auxiliares del sistema: estado del teléfono, vibración, archivos, recordatorios y llamadas simuladas.',
    'Системные помощники: состояние телефона, вибрация, архивы, напоминания и имитация звонка.'],
  'toolbox.life.hub.category.measure.label': [null, null,
    '測定ツール', 'Messwerkzeuge', 'Outils de mesure', 'Herramientas de medición', 'Инструменты измерения'],
  'toolbox.life.hub.category.measure.desc': [null, null,
    '定規、コンパス、水準器、速度計、ルーペ、照度計、距離計などのセンサーツール。',
    'Sensorwerkzeuge: Lineal, Kompass, Wasserwaage, Tacho, Lupe, Belichtungsmesser und Entfernungsmesser.',
    'Outils à capteurs : règle, boussole, niveau, vitesse, loupe, luxmètre et télémètre.',
    'Herramientas con sensores: regla, brújula, nivel, velocidad, lupa, luxómetro y medidor de distancia.',
    'Датчики в деле: линейка, компас, уровень, скорость, лупа, люксметр и дальномер.'],
  'toolbox.life.hub.category.image.desc': [null, null,
    'カラーピッカー、画像処理、ミーム、デバイスフレーム、動画から GIF、証明写真、画像のウェブ書き出し。',
    'Farbwahl, Bildbearbeitung, Memes, Gerätrahmen, Video zu GIF, Ausweisfotos und Bild-zu-Web-Export.',
    'Pipette à couleurs, retouche d’images, mèmes, cadres d’appareils, vidéo en GIF, photos d’identité et export web d’images.',
    'Selector de color, procesamiento de imágenes, memes, marcos de dispositivos, vídeo a GIF, fotos de carné y exportación web de imágenes.',
    'Пипетка цвета, обработка изображений, мемы, рамки устройств, видео в GIF, фото на документы и экспорт изображений в веб.'],
  'toolbox.life.hub.category.web.desc': [null, null,
    '壁紙、郵便番号、画像検索、ゴミ分別、短縮リンク、QRコードなど、ネット接続やリンク移動に使うツール。',
    'Hintergrundbilder, Postleitzahlen, Bildrückwärtssuche, Recycling-Lookup, Kurzlinks und QR-Werkzeuge.',
    'Fonds d’écran, codes postaux, recherche d’image inversée, tri des déchets, liens courts et outils QR.',
    'Fondos de pantalla, códigos postales, búsqueda inversa de imágenes, reciclaje, enlaces cortos y herramientas QR.',
    'Обои, почтовые индексы, поиск по картинке, сортировка отходов, короткие ссылки и QR-инструменты.'],
  'toolbox.life.hub.category.text.desc': [null, null,
    '文字数カウント、テキスト変換、上付き・下付き、簡易マインドマップなどのテキスト編集補助。',
    'Text-Helfer: Zählen, Umwandlungen, hoch-/tiefstellen und einfache Mindmaps.',
    'Aides à l’édition : comptage, conversions, exposants/indices et cartes mentales simples.',
    'Auxiliares de texto: conteo, conversiones, superíndices/subíndices y mapas mentales simples.',
    'Помощники для текста: подсчёт, преобразования, верхний/нижний индекс и простые интеллект-карты.'],
  'toolbox.life.hub.category.study.label': [null, null,
    '知識リファレンス', 'Wissensreferenzen', 'Références de connaissances', 'Referencias de conocimiento', 'Справочные знания'],
  'toolbox.life.hub.category.calc.desc': [null, null,
    '単位、科学計算、周期、コスパ計算、都市別給与、住宅ローン、日付、世界時計、BMI、親族呼称、Offer 比較の計算ツール。',
    'Rechner für Einheiten, Wissenschaft, Zyklen, Arbeitswert, Stadtgehälter, Hypotheken, Datum, Weltzeit, BMI, Verwandtschaft und Angebote.',
    'Calculateurs : unités, scientifique, cycles, rapport travail/salaire, salaires par ville, prêt immobilier, dates, horloge mondiale, IMC, parenté et choix d’offres.',
    'Calculadoras de unidades, científica, ciclos, rentabilidad laboral, salarios por ciudad, hipoteca, fechas, reloj mundial, IMC, parentesco y ofertas.',
    'Калькуляторы: единицы, научный, циклы, ценность работы, зарплаты по городам, ипотека, даты, мировое время, ИМТ, родство и выбор оффера.'],
  'toolbox.life.hub.subtitle': [null, null,
    '{length} 個の実用ツールを {categories} 個の分類で整理。検索、クイックアクセス、統一されたソースページに対応します。',
    '{length} praktische Werkzeuge in {categories} fokussierten Kategorien, mit Suche, Schnellzugriff und gemeinsamer Quellenseite.',
    '{length} outils pratiques classés en {categories} catégories ciblées, avec recherche, accès rapide et page de sources unifiée.',
    '{length} herramientas prácticas en {categories} categorías enfocadas, con búsqueda, acceso rápido y página de fuentes unificada.',
    '{length} практичных инструментов в {categories} точных категориях, с поиском, быстрым доступом и единой страницей источников.'],
  'toolbox.life.source_references.title': [null, null,
    '参考ソース', 'Quellenangaben', 'Références des sources', 'Referencias de fuentes', 'Источники'],
  'toolbox.life.source_references.subtitle': [null, null,
    '外部リンクをツール別にまとめて表示します。著作権、可用性、利用規約は各公式サイトに従います。',
    'Externe Links nach Werkzeug anzeigen; Urheberrecht, Verfügbarkeit und Bedingungen richten sich nach den Originalseiten.',
    'Consultez les liens externes par outil ; droits, disponibilité et conditions dépendent des sites d’origine.',
    'Revisa los enlaces externos por herramienta; los derechos, la disponibilidad y los términos corresponden a los sitios originales.',
    'Просмотр внешних ссылок по инструментам; авторские права, доступность и условия — на стороне исходных сайтов.'],
  'toolbox.life.source_references.summary': [null, null,
    'ライフツールが使用するサードパーティページ、公開データ、実装参考をまとめて確認できます。',
    'Gebündelte Übersicht über Drittanbieterseiten, öffentliche Daten und Implementierungsreferenzen der Life-Tools.',
    'Liste unifiée des pages tierces, données publiques et références d’implémentation utilisées par les outils du quotidien.',
    'Lista unificada de páginas de terceros, datos públicos y referencias de implementación usados por las herramientas.',
    'Единый список сторонних страниц, открытых данных и реализационных ссылок, используемых бытовыми инструментами.'],
  'toolbox.life.light_meter.subtitle': [null, null,
    '端末の照度センサーで環境の明るさを推定します。非対応の端末ではフォールバック状態を表示します。',
    'Schätzt die Umgebungsbeleuchtung über den Lichtsensor; nicht unterstützte Geräte zeigen einen Fallback-Status.',
    'Estime l’éclairement ambiant via le capteur de lumière ; les appareils non compatibles affichent un état dégradé.',
    'Estima la iluminancia ambiental con el sensor de luz; los dispositivos sin soporte muestran un estado degradado.',
    'Оценивает освещённость по датчику света; на неподдерживаемых устройствах показывается запасное состояние.'],
  'toolbox.life.magnifier.subtitle': [null, null,
    'カメラで小さな文字や質感、細部を拡大。画面フリーズでじっくり確認できます。',
    'Vergrößere kleine Schrift, Texturen und Details mit der Kamera; Standbild für die genaue Ansicht.',
    'Agrandissez petits textes, textures et détails avec l’appareil photo, avec image figée pour l’inspection.',
    'Amplía textos pequeños, texturas y detalles con la cámara, con imagen congelada para inspeccionar.',
    'Увеличивайте мелкий текст, текстуры и детали камерой; стоп-кадр для удобного осмотра.'],
  'toolbox.life.phone_monitor.title': [null, null,
    '端末情報モニター', 'Telefon-Info-Monitor', 'Moniteur d’informations du téléphone', 'Monitor de información del teléfono', 'Монитор сведений о телефоне'],
  'toolbox.life.phone_monitor.subtitle': [null, null,
    '定期的に端末の状態を更新し、バッテリー、画面、システム情報を確認しやすくします。',
    'Aktualisiert regelmäßig wichtige Gerätedaten, um Akku, Bildschirm und Systeminformationen zu prüfen.',
    'Actualise régulièrement l’état de l’appareil pour inspecter batterie, écran et informations système.',
    'Actualiza periódicamente el estado del dispositivo para revisar batería, pantalla e información del sistema.',
    'Периодически обновляет состояние устройства: удобно проверять батарею, экран и системные сведения.'],
  'toolbox.life.screen_fill_light.title': [null, null,
    '画面補助ライト', 'Bildschirm-Fülllicht', 'Lumière d’appoint par écran', 'Luz de relleno de pantalla', 'Экранная подсветка'],
  'toolbox.life.screen_fill_light.subtitle': [null, null,
    'スマホ画面を調整可能な単色ライトとして使用。撮影、一時的な照明、雰囲気作りに最適です。',
    'Nutze das Display als steuerbares einfarbiges Fülllicht für Fotos, Notbeleuchtung und stimmungsvolles Licht.',
    'Utilisez l’écran comme lumière d’appoint unie et réglable pour les photos, l’éclairage d’appoint et l’ambiance.',
    'Usa la pantalla como luz de relleno sólida y ajustable para fotos, iluminación temporal y ambiente.',
    'Экран как управляемая однотонная подсветка для фото, временного освещения и атмосферы.'],
  'toolbox.life.speedometer.subtitle': [null, null,
    'ウォーキング、サイクリング、車内での簡易な速度計測に。精度は測位信号に依存します。',
    'Für Gehen, Radfahren und kurze Tempokontrollen im Auto; Genauigkeit hängt vom Ortungssignal ab.',
    'Para caminar, ir en bici y comprobaciones puntuales en coche; la precisión depende de la señal de ubicación.',
    'Pour la marche, le vélo et des contrôles ponctuels en voiture ; la précision dépend du signal de localisation.',
    'Для ходьбы, велосипедных поездок и быстрых замеров скорости в машине; точность зависит от сигнала геолокации.'],
  'toolbox.life.screen_fill_light.summary': [null, null,
    '全画面の単色補助ライト。輝度、色温度、カラーパレット、柔らかな呼吸モードに対応します。',
    'Einfarbiges Vollbild-Fülllicht mit Helligkeit, Farbtemperatur, Paletten und sanftem Atemmodus.',
    'Lumière unie plein écran avec luminosité, chaleur, palettes et mode respiration doux.',
    'Luz sólida a pantalla completa con brillo, calidez, paletas y modo de respiración suave.',
    'Полноэкранная однотонная подсветка с яркостью, теплотой, палитрами и мягким режимом дыхания.'],
  'toolbox.life.speedometer.summary': [null, null,
    '位置情報ストリームをもとに、リアルタイム速度、最高速度、走行距離、測位精度を表示します。',
    'Zeigt Live-Geschwindigkeit, Höchstgeschwindigkeit, Distanz und GPS-Genauigkeit aus dem Standortstrom.',
    'Affiche vitesse en direct, vitesse maximale, distance et précision GPS à partir du flux de localisation.',
    'Muestra velocidad en vivo, velocidad máxima, distancia y precisión del GPS desde el flujo de ubicación.',
    'Показывает скорость в реальном времени, максимум, дистанцию и точность GPS по потоку геолокации.'],
  'toolbox.life.magnifier.summary': [null, null,
    'カメラによるリアルタイム拡大。ズーム、ライト、画面フリーズ、カメラ切り替えに対応します。',
    'Live-Kamera-Lupe mit Zoom, Taschenlampe, Standbild und Kamerawechsel.',
    'Loupe caméra en direct avec zoom, torche, image figée et changement de caméra.',
    'Lupa de cámara en vivo con zoom, linterna, imagen congelada y cambio de cámara.',
    'Живая лупа камеры с зумом, фонариком, стоп-кадром и переключением камер.'],
  'toolbox.life.light_meter.summary': [null, null,
    '環境光センサーを読み取り、lux、最小/最大値、光照レベルを表示します。',
    'Liest den Umgebungslichtsensor und zeigt Lux, Min/Max-Werte und Lichtstufen.',
    'Lit le capteur de lumière ambiante et affiche lux, valeurs min/max et niveaux d’éclairage.',
    'Lee el sensor de luz ambiental y muestra lux, valores mín/máx y niveles de luz.',
    'Читает датчик освещённости и показывает люксы, минимум/максимум и уровни света.'],
  'toolbox.life.phone_monitor.summary': [null, null,
    'システム、画面、バッテリー、充電状態、メモリ、温度状態のスナップショットを確認できます。',
    'Zeigt Momentaufnahmen von System, Bildschirm, Akku, Ladestatus, Speicher und Temperatur.',
    'Affiche des instantanés du système, de l’écran, de la batterie, de la charge, de la mémoire et de la température.',
    'Muestra instantáneas del sistema, pantalla, batería, carga, memoria y estado térmico.',
    'Просмотр снимков системы, экрана, батареи, зарядки, памяти и теплового состояния.'],
  'toolbox.life.distance_meter.summary': [null, null,
    'GPS 2点間の距離と、傾きベースの近距離概算に対応します。',
    'Unterstützt GPS-Zweipunkt-Distanz und neigungsbasierte Nahbereichsschätzung.',
    'Prend en charge la distance GPS entre deux points et l’estimation de proximité par inclinaison.',
    'Admite distancia GPS entre dos puntos y estimación de cercanía por inclinación.',
    'Поддерживает расстояние между двумя точками GPS и оценку близкого расстояния по наклону.'],
  'toolbox.life.gif_maker.summary': [null, null,
    '動画を取り込み、指定区間を切り出して圧縮し、GIF としてエクスポートします。',
    'Video importieren, Bereich zuschneiden und als komprimiertes GIF exportieren.',
    'Importez une vidéo, découpez la plage choisie et exportez un GIF compressé.',
    'Importa un vídeo, recorta el rango elegido y exporta un GIF comprimido.',
    'Импортируйте видео, вырежьте нужный фрагмент и экспортируйте сжатый GIF.'],
  'toolbox.life.archive_tool.summary': [null, null,
    'ZIP/TAR/GZip/BZip2/XZ アーカイブをローカルで作成し、一般的なアーカイブのプレビューや解凍ができます。',
    'Erstellt lokal ZIP-, TAR-, GZip-, BZip2- oder XZ-Archive und zeigt gängige Archive an oder entpackt sie.',
    'Créez localement des archives ZIP, TAR, GZip, BZip2 ou XZ, et prévisualisez ou extrayez les archives courantes.',
    'Crea archivos ZIP, TAR, GZip, BZip2 o XZ en local y previsualiza o extrae archivos comunes.',
    'Локальное создание архивов ZIP, TAR, GZip, BZip2 и XZ, а также просмотр и распаковка распространённых форматов.'],
  'toolbox.life.advanced_calculator.summary': [null, null,
    'プロ仕様の科学計算ツール。数式、数値積分、導関数、極限、方程式の求解、線形代数、確率計算に対応します。',
    'Professioneller Wissenschaftsrechner für Ausdrücke, numerische Integrale, Ableitungen, Grenzwerte, Nullstellen, lineare Algebra und Wahrscheinlichkeit.',
    'Calculatrice scientifique experte : expressions, intégrales numériques, dérivées, limites, résolution d’équations, algèbre linéaire et probabilités.',
    'Calculadora científica profesional con expresiones, integrales numéricas, derivadas, límites, resolución de raíces, álgebra lineal y probabilidad.',
    'Профессиональный научный калькулятор: выражения, численные интегралы, производные, пределы, поиск корней, линейная алгебра и вероятность.'],
  'toolbox.life.menstrual_cycle.summary': [null, null,
    '生理日、排卵日、妊娠しやすい期間、次の生理日を推算する、女性向けの周期サポートツールです。',
    'Zyklus-Assistent zur Schätzung von Periodenterminen, Eisprung, fruchtbarem Fenster und nächster Periode.',
    'Assistant de cycle pour estimer les dates de règles, l’ovulation, la fenêtre de fertilité et les prochaines règles.',
    'Asistente del ciclo menstrual para estimar fechas de período, ovulación, ventana fértil y próximo período.',
    'Помощник менструального цикла: оценка дат менструации, овуляции, фертильного окна и следующего цикла.'],
  'toolbox.sound.focus.quick_presets.steady.subtitle': [null, null,
    '1拍に1音の低干渉ビートで、すばやく集中状態に入れます。',
    'Ein Klang pro Schlag, ablenkungsarm – für schnellen Fokus.',
    'Un clic par temps, peu de distraction, pour se concentrer rapidement.',
    'Un clic por pulso, poca distracción, para concentrarte rápido.',
    'Один звук на долю, минимум отвлечения — для быстрого входа в фокус.'],
  'toolbox.sound.focus.quick_presets.sprint.subtitle': [null, null,
    '速めのテンポと短いループで、仕上げのスプリントや片付け作業に最適です。',
    'Schnelleres Tempo mit kurzen Abschnitten für Schlussspurts oder Aufräumarbeiten.',
    'Tempo rapide avec sections courtes pour les sprints finaux ou les tâches de rangement.',
    'Tempo más rápido con secciones cortas para sprints finales o tareas de orden.',
    'Темп побыстрее и короткие циклы — для финального рывка или наведения порядка.'],
  'toolbox.sound.focus.quick_presets.title': [null, null,
    'クイックビートプリセット', 'Schnelle Beat-Voreinstellungen', 'Préréglages de rythmes rapides', 'Presets de ritmo rápido', 'Быстрые пресеты ритма'],
};

// ---- 应用替换（含 ref.* 镜像自动同步）----
let changed = 0;
const edits = []; // {start,end,text}
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

// 从后往前替换，保持偏移有效
edits.sort((a, b) => b.start - a.start);
let out = s;
for (const e of edits) out = out.slice(0, e.start) + e.text + out.slice(e.end);
fs.writeFileSync(CSV, out, 'utf8');
console.log('rows changed:', changed);

// ---- 回读校验 ----
const recs2 = parseWithOffsets(fs.readFileSync(CSV, 'utf8'));
console.log('records after:', recs2.length);
let bad = 0;
for (let i = 1; i < recs2.length; i++) if (recs2[i].f.length !== 8) bad++;
console.log('bad column rows after:', bad);
