import argparse
import hashlib
import html
import json
import os
import re
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOG_DIR = ROOT / "lib" / "l10n" / "catalog"
REGISTRY_PATH = CATALOG_DIR / "app_text_registry.json"
BUILD_DIR = ROOT / "build" / "i18n_locale_completion_redo"
CACHE_PATH = BUILD_DIR / "bing_cache.json"
REPORT_PATH = BUILD_DIR / "completion_report.json"

LOCALES = ["zh", "en", "ja", "de", "fr", "es", "ru"]
TARGET_LOCALES = ["zh", "ja", "de", "fr", "es", "ru"]
REMOTE_LOCALES = ["zh", "ja", "de", "fr", "es", "ru"]
TRANSLATABLE_KINDS = {
    "existing_app_i18n_key",
    "existing_arb_key",
    "inline_pick_ui_text",
    "i18n_runtime_reference",
}

MARKER_RE = re.compile(r"\[\[I(\d{4})\]\]\s*(.*?)(?=\n\[\[I\d{4}\]\]|\Z)", re.S)
PLACEHOLDER_RE = re.compile(
    r"""
    \$\{[^}]+\}
    |\$[A-Za-z_][A-Za-z0-9_]*
    |\{[A-Za-z_][A-Za-z0-9_]*\}
    """,
    re.X,
)
ASCII_LETTER_RE = re.compile(r"[A-Za-z]")
NON_ASCII_RE = re.compile(r"[^\x00-\x7F]")
CJK_RE = re.compile(r"[\u3400-\u9fff]")
DART_EXPRESSION_RE = re.compile(
    r"toStringAsFixed|\?\?|=>|[A-Za-z_][A-Za-z0-9_]*\[\]\?|"
    r"\$\{[^}]*[?.][^}]*\}"
)

SAME_AS_EN_OK = {
    "SiliconFlow API",
    "Binaural",
    "Lo-fi",
    "BPM",
    "BOLT",
    "ASR",
    "TTS",
    "API",
    "GPS",
    "OSM",
    "HTTP",
    "HTTPS",
    "JSON",
    "SQL",
    "dBFS",
    "Add9",
    "Maj7",
    "Min7",
    "Sus2",
    "Sus4",
    "m7",
    "Sudoku",
    "Gomoku",
    "Sokoban",
    "Tetris",
    "Minesweeper",
    "Wordle",
    "2048",
    "2048 / 4096",
}

SAME_AS_EN_OK_BY_LOCALE = {
    ("fr", "Nature"),
    ("de", "Wind"),
    ("de", "Cafe"),
}


def load_json(path):
    with path.open("r", encoding="utf-8-sig") as f:
        return json.load(f)


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def sha_text(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def strip_ref_prefix(entry_id):
    return entry_id[4:] if entry_id.startswith("ref.") else entry_id


def runtime_key_for_entry(entry):
    if entry.get("kind") == "i18n_runtime_reference":
        return entry.get("referencedKey") or strip_ref_prefix(entry["id"])
    return entry["id"]


def write_keys_for_entry(entry):
    keys = [runtime_key_for_entry(entry)]
    if entry["id"] not in keys:
        keys.append(entry["id"])
    return keys


def humanize_runtime_key(key):
    tail = key.split(".")[-1]
    tail = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", tail)
    tail = tail.replace("_", " ").replace("-", " ").strip()
    if not tail:
        tail = key.replace(".", " ").replace("_", " ")
    return " ".join(part.capitalize() if part.islower() else part for part in tail.split())


def is_brand_or_code(text):
    stripped = text.strip()
    if not stripped:
        return True
    if stripped in SAME_AS_EN_OK:
        return True
    placeholderless = PLACEHOLDER_RE.sub("", stripped).strip()
    if not placeholderless or re.fullmatch(r"[\s\d./:;,+\-·×%()~>|]+", placeholderless):
        return True
    if DART_EXPRESSION_RE.search(stripped):
        return True
    if re.fullmatch(r"[A-Za-z]*\d+[A-Za-z0-9]*", stripped):
        return True
    if stripped in {"BPM", "BOLT", "ASR", "TTS", "API", "GPS", "OSM"}:
        return True
    if re.fullmatch(r"[A-Z0-9][A-Z0-9 _./:+-]*", stripped):
        return True
    if re.fullmatch(r"[A-Za-z0-9_.:/\\-]+", stripped) and any(
        token in stripped.lower()
        for token in [".dart", ".json", ".mp3", ".wav", "http", "assets/", "lib/"]
    ):
        return True
    return False


def looks_localized(locale, value, english):
    if value is None:
        return False
    value = str(value).strip()
    english = (english or "").strip()
    if not value:
        return False
    if locale == "en":
        return True
    if locale == "zh" and CJK_RE.search(value):
        return True
    locale_static = STATIC_TERMS.get(locale, {})
    if english in locale_static and value == locale_static[english]:
        return True
    if value == english and (
        english in SAME_AS_EN_OK or (locale, english) in SAME_AS_EN_OK_BY_LOCALE
    ):
        return True
    if locale == "zh":
        if value == english and ASCII_LETTER_RE.search(value) and not is_brand_or_code(value):
            return False
        return bool(NON_ASCII_RE.search(value)) or not ASCII_LETTER_RE.search(value) or is_brand_or_code(value)
    if is_brand_or_code(english):
        return True
    if value == english and ASCII_LETTER_RE.search(value):
        return False
    if locale in {"ja", "ru"}:
        return bool(NON_ASCII_RE.search(value))
    if locale in {"de", "fr", "es"}:
        # Latin-script languages can legitimately contain ASCII only. Treat equal
        # English fallback as missing, but accept translated Latin text.
        return value != english
    return value != english


def protect_placeholders(text):
    mapping = []

    def repl(match):
        token = f"PHX{len(mapping)}PH"
        mapping.append((token, match.group(0)))
        return token

    return PLACEHOLDER_RE.sub(repl, text), mapping


def restore_placeholders(text, mapping):
    restored = text
    for token, original in mapping:
        restored = restored.replace(token, original)
        restored = restored.replace(token.lower(), original)
    return restored


def placeholder_set(text):
    return sorted(PLACEHOLDER_RE.findall(text or ""))


def placeholders_compatible(locale, value, english):
    source_tokens = placeholder_set(english)
    value_tokens = placeholder_set(value)
    if source_tokens == value_tokens:
        return True
    if locale != "zh" or len(source_tokens) != len(value_tokens):
        return False
    localized_tokens = [
        token.replace("titleEn", "titleZh")
        .replace("subtitleEn", "subtitleZh")
        .replace("labelEn", "labelZh")
        .replace("nameEn", "nameZh")
        for token in source_tokens
    ]
    return sorted(localized_tokens) == value_tokens


def clean_translation(text):
    value = html.unescape(text or "").strip()
    value = value.replace("\u00a0", " ")
    value = re.sub(r"[ \t]+", " ", value)
    value = re.sub(r"\s+([?.!,;:])", r"\1", value)
    value = value.replace("PHX ", "PHX").replace(" PH", " PH")
    return value.strip()


STATIC_TERMS = {
    "zh": {
        "Add": "新增",
        "Add Field": "新增字段",
        "Add Word": "新增单词",
        "Add word": "新增单词",
        "All": "全部",
        "Back": "返回",
        "Cancel": "取消",
        "Close": "知道了",
        "Delete": "删除",
        "Done": "完成",
        "Edit": "编辑",
        "Focus": "专注",
        "More": "更多",
        "Play": "播放",
        "Save": "保存",
        "Settings": "设置",
        "Today": "今天",
        "Tomorrow": "明天",
        "Weather": "天气",
    },
    "ja": {
        "Add": "追加",
        "All": "すべて",
        "Back": "戻る",
        "Cancel": "キャンセル",
        "Close": "閉じる",
        "Delete": "削除",
        "Done": "完了",
        "Edit": "編集",
        "Focus": "集中",
        "More": "その他",
        "Play": "再生",
        "Save": "保存",
        "Settings": "設定",
        "Today": "今日",
        "Tomorrow": "明日",
        "Weather": "天気",
        "s": "秒",
    },
    "de": {
        "Add": "Hinzufügen",
        "All": "Alle",
        "Back": "Zurück",
        "Cancel": "Abbrechen",
        "Close": "Schließen",
        "Delete": "Löschen",
        "Done": "Fertig",
        "Edit": "Bearbeiten",
        "Focus": "Fokus",
        "More": "Mehr",
        "Play": "Wiedergabe",
        "Save": "Speichern",
        "Settings": "Einstellungen",
        "Today": "Heute",
        "Tomorrow": "Morgen",
        "Weather": "Wetter",
        "s": "s",
    },
    "fr": {
        "Add": "Ajouter",
        "All": "Tous",
        "Back": "Retour",
        "Cancel": "Annuler",
        "Close": "Fermer",
        "Delete": "Supprimer",
        "Done": "Terminé",
        "Edit": "Modifier",
        "Focus": "Concentration",
        "More": "Plus",
        "Play": "Lire",
        "Save": "Enregistrer",
        "Settings": "Paramètres",
        "Today": "Aujourd’hui",
        "Tomorrow": "Demain",
        "Weather": "Météo",
        "s": "s",
    },
    "es": {
        "Add": "Añadir",
        "All": "Todo",
        "Back": "Atrás",
        "Cancel": "Cancelar",
        "Close": "Cerrar",
        "Delete": "Eliminar",
        "Done": "Listo",
        "Edit": "Editar",
        "Focus": "Enfoque",
        "More": "Más",
        "Play": "Reproducir",
        "Save": "Guardar",
        "Settings": "Configuración",
        "Today": "Hoy",
        "Tomorrow": "Mañana",
        "Weather": "Tiempo",
        "s": "s",
    },
    "ru": {
        "Add": "Добавить",
        "All": "Все",
        "Back": "Назад",
        "Cancel": "Отмена",
        "Close": "Закрыть",
        "Delete": "Удалить",
        "Done": "Готово",
        "Edit": "Изменить",
        "Focus": "Фокус",
        "More": "Еще",
        "Play": "Воспроизвести",
        "Save": "Сохранить",
        "Settings": "Настройки",
        "Today": "Сегодня",
        "Tomorrow": "Завтра",
        "Weather": "Погода",
        "s": "с",
    },
}


STATIC_TERM_EXTENSIONS = {
    "zh": {
        "s": "秒",
        "min": "分钟",
        "Start": "开始",
        "Pause": "暂停",
        "Continue": "继续",
        "Previous": "上一个",
        "Next": "下一个",
        "Jump": "跳转",
        "Jump by letter": "按字母跳转",
        "Language": "语言",
        "Definition": "释义",
        "Word": "单词",
        "Wordbook": "词本",
        "Search word or content": "搜索单词或内容",
        "Save and apply": "保存并应用",
        "Test mode": "测试模式",
        "Fuzzy": "模糊",
        "Prefix jump (e.g., ab)": "前缀跳转（如 ab）",
        'Extra "{value}"': "多出“{value}”",
        'Missing "{value}"': "缺少“{value}”",
        'Read "{from}" as "{to}"': "将“{from}”读成了“{to}”",
        "ASR API request failed: {code}": "ASR API 请求失败（状态码：{code}）",
        "ASR disabled": "ASR 已禁用",
        "SiliconFlow API": "SiliconFlow API",
        "TTS language (auto / en-US / zh-CN)": "TTS 语言（auto / en-US / zh-CN）",
    },
    "ja": {
        "Start": "開始",
        "Pause": "一時停止",
        "Decoding speech": "音声を解析中",
        "ASR API request failed: {code}": "ASR API リクエストに失敗しました: {code}",
        "s": "秒",
        "min": "分",
        "$_loopCycleSeconds s": "$_loopCycleSeconds 秒",
        "Low BOLT": "低BOLT",
        "SiliconFlow API": "SiliconFlow API",
        "Unlimited": "無制限",
    },
    "de": {
        "Start": "Starten",
        "Pause": "Pause",
        "Continue": "Fortsetzen",
        "Previous": "Zurück",
        "Next": "Weiter",
        "Jump": "Springen",
        "Jump by letter": "Nach Buchstaben springen",
        "Language": "Sprache",
        "Definition": "Definition",
        "Word": "Wort",
        "Wordbook": "Wortbuch",
        "Search word or content": "Wort oder Inhalt suchen",
        "Save and apply": "Speichern und anwenden",
        "Test mode": "Testmodus",
        "Fuzzy": "Unscharf",
        'Extra "{value}"': "Zusätzlich „{value}“",
        '"{from}" -> "{to}"': "„{from}“ -> „{to}“",
        "Monospace": "Monospace",
        "Serif": "Serif",
        "System": "System",
        "Layout": "Layout",
        "Medium": "Mittel",
        "Default": "Standard",
        "Fade": "Ausblenden",
        "Band": "Band",
        "Linear": "Linear",
        "Bounce": "Springen",
        "Tickets": "Tickets",
        "Ticket": "Ticket",
        "Status": "Status",
        "Details": "Details",
        "Option": "Option",
        "Option A": "Option A",
        "Option B": "Option B",
        "Option C": "Option C",
        "Option D": "Option D",
        "Option $label": "Option $label",
        "Option $nextIndex": "Option $nextIndex",
        "Pool": "Pool",
        "Pool $candidateCount": "Pool $candidateCount",
        "Premortem": "Premortem",
        "Premortem: ${_briefValue(draft.premortem)}": "Premortem: ${_briefValue(draft.premortem)}",
        "$_loopCycleSeconds s": "$_loopCycleSeconds s",
        "$_targetMinutes min": "$_targetMinutes min",
        "$minutes min": "$minutes min",
        "{minutes} min": "{minutes} min",
        "Alpha": "Alpha",
        "Array optional": "Optionales Array",
        "Aurora": "Aurora",
        "Avg": "Durchschn.",
        "Box": "Box",
        "Bt": "Bt",
        "Code": "Code",
        "Countdown": "Countdown",
        "Cyan": "Cyan",
        "Diagonal": "Diagonal",
        "Dorian": "Dorisch",
        "Drop": "Drop",
        "Drum Pad Sub": "Drum-Pad-Sub",
        "Dual": "Dual",
        "Extra": "Extra",
        "Extra: {value}": "Zusätzlich: {value}",
        "Hirajoshi": "Hirajoshi",
        "Horizontal": "Horizontal",
        "Hybrid": "Hybrid",
        "Hyper": "Hyper",
        "Jade": "Jade",
        "Joystick": "Joystick",
        "Kick": "Kick",
        "Kit": "Kit",
        "Lead": "Lead",
        "Material": "Material",
        "Metro": "Metro",
        "Mismatch": "Abweichung",
        "Mixer": "Mixer",
        "Mono": "Mono",
        "Nylon": "Nylon",
        "Orange": "Orange",
        "Pack $packId": "Paket $packId",
        "Palette": "Palette",
        "Phrase {label}": "Phrase {label}",
        "Position": "Position",
        "Position {value}": "Position {value}",
        "Reflux": "Reflux",
        "Segment": "Segment",
        "SiliconFlow API": "SiliconFlow API",
        "Snare": "Snare",
        "Solo": "Solo",
        "Space {value}%": "Abstand {value}%",
        "Sprint": "Sprint",
        "Stroop": "Stroop",
        "Tail {value}%": "Ende {value}%",
        "Tags": "Tags",
        "Tempo": "Tempo",
        "Tempo $_bpm BPM": "Tempo $_bpm BPM",
        "Ticket $ticketId": "Ticket $ticketId",
        "Tom": "Tom",
        "Standard": "Standard",
        "Training": "Training",
        "Timer": "Timer",
        "Warm": "Warm",
        "Cool": "Kühl",
        "Blind": "Blind",
        "Still": "Still",
        "Online": "Online",
        "Arpeggio": "Arpeggio",
        "Master": "Master",
        "s": "s",
        "min": "min",
        "Brown Noise": "Braunes Rauschen",
        "Pink Noise": "Rosa Rauschen",
        "Low BOLT": "Niedriger BOLT",
    },
    "fr": {
        "Start": "Démarrer",
        "Pause": "Pause",
        "Continue": "Continuer",
        "Previous": "Précédent",
        "Next": "Suivant",
        "Jump": "Aller",
        "Jump by letter": "Aller par lettre",
        "Language": "Langue",
        "Definition": "Définition",
        "Word": "Mot",
        "Wordbook": "Carnet de mots",
        "Search word or content": "Rechercher un mot ou un contenu",
        "Save and apply": "Enregistrer et appliquer",
        "Test mode": "Mode test",
        "Fuzzy": "Flou",
        'Extra "{value}"': "En trop : « {value} »",
        "Monospace": "Monospace",
        "Serif": "Serif",
        "Transport": "Transport",
        "Mode": "Mode",
        "Modes": "Modes",
        "Score": "Score",
        "Guide": "Guide",
        "Option": "Option",
        "Options": "Options",
        "Option $label": "Option $label",
        "Option $nextIndex": "Option $nextIndex",
        "Option A": "Option A",
        "Option B": "Option B",
        "Option C": "Option C",
        "Option D": "Option D",
        "Premortem": "Pré-mortem",
        "Premortem: ${_briefValue(draft.premortem)}": "Pré-mortem : ${_briefValue(draft.premortem)}",
        "Expert": "Expert",
        "Stable": "Stable",
        "Sessions": "Sessions",
        "Usage": "Usage",
        "Minutes": "Minutes",
        "Action": "Action",
        "Affixes": "Affixes",
        "Alpha": "Alpha",
        "Condition": "Condition",
        "Correct.": "Correct.",
        "Correct/rounds": "Correct/tours",
        "Correct/total": "Correct/total",
        "$_loopCycleSeconds s": "$_loopCycleSeconds s",
        "$_targetMinutes min": "$_targetMinutes min",
        "$minutes min": "$minutes min",
        "~$formatted cycles/min": "≈ $formatted cycles/min",
        "{count} min": "{count} min",
        "{minutes} min": "{minutes} min",
        "10 min": "10 min",
        "10-20 min": "10-20 min",
        "15 min": "15 min",
        "3 min": "3 min",
        "4 directions": "4 directions",
        "5 min": "5 min",
        "8 directions": "8 directions",
        "Accent": "Accent",
        "Alto": "Alto",
        "Arrangement": "Arrangement",
        "Arrangement · {name}": "Arrangement · {name}",
        "Bt": "Bt",
        "Cascade": "Cascade",
        "Code": "Code",
        "Collocations": "Collocations",
        "Concert": "Concert",
        "Condition P": "Condition P",
        "Conf": "Conf.",
        "Confusions": "Confusions",
        "Consensus: $consensus": "Consensus : $consensus",
        "Culture": "Culture",
        "Cyan": "Cyan",
        "Cycle": "Cycle",
        "Cycle {label}": "Cycle {label}",
        "Diagonal": "Diagonale",
        "Disjoint": "Disjoint",
        "Direction": "Direction",
        "Distance": "Distance",
        "Effort": "Effort",
        "Excellent": "Excellent",
        "Flashcard": "Carte mémoire",
        "Hi-hat": "Charleston",
        "Hirajoshi": "Hirajoshi",
        "Horizontal": "Horizontal",
        "Hyper": "Hyper",
        "Jade": "Jade",
        "Joystick": "Joystick",
        "Kit": "Kit",
        "Local": "Local",
        "Mode: ${experienceModeTitle(i18n, mode)}": "Mode : ${experienceModeTitle(i18n, mode)}",
        "Mono": "Mono",
        "Nylon": "Nylon",
        "Observation": "Observation",
        "Orange": "Orange",
        "Palette": "Palette",
        "Phrase {label}": "Phrase {label}",
        "Phrases": "Phrases",
        "Piano": "Piano",
        "Piano Sub": "Sub piano",
        "Position": "Position",
        "Position {value}": "Position {value}",
        "Rare": "Rare",
        "Rectangle": "Rectangle",
        "Reflux": "Reflux",
        "Regret": "Regret",
        "Saturation": "Saturation",
        "Science": "Science",
        "Segment": "Segment",
        "SiliconFlow API": "SiliconFlow API",
        "Six modules": "6 modules",
        "Solo": "Solo",
        "Source": "Source",
        "Source {deg} deg {side}": "Source {deg}° {side}",
        "Sprint": "Sprint",
        "Stimuli": "Stimuli",
        "Style": "Style",
        "Subdivision": "Subdivision",
        "Tempo": "Tempo",
        "Tempo $_bpm BPM": "Tempo $_bpm BPM",
        "Timbre": "Timbre",
        "Tom": "Tom",
        "Triangle": "Triangle",
        "Triangle Sub": "Sub triangle",
        "Validation": "Validation",
        "Variable": "Variable",
        "Verbal": "Verbal",
        "Vertical": "Vertical",
        "Visible": "Visible",
        "Volume {pct}%": "Volume {pct} %",
        "Zigzag": "Zigzag",
        "pts": "pts",
        "s": "s",
        "min": "min",
    },
    "es": {
        "Start": "Iniciar",
        "Pause": "Pausar",
        "Continue": "Continuar",
        "Previous": "Anterior",
        "Next": "Siguiente",
        "Jump": "Saltar",
        "Jump by letter": "Saltar por letra",
        "Language": "Idioma",
        "Definition": "Definición",
        "Word": "Palabra",
        "Wordbook": "Vocabulario",
        "Search word or content": "Buscar palabra o contenido",
        "Save and apply": "Guardar y aplicar",
        "Test mode": "Modo de prueba",
        "Fuzzy": "Difuso",
        'Extra "{value}"': "Extra «{value}»",
        '"{from}" -> "{to}"': "«{from}» -> «{to}»",
        "Serif": "Serif",
        "Regular": "Regular",
        "Combo": "Combo",
        "Net": "Neto",
        "Color": "Color",
        "Manual": "Manual",
        "Visual": "Visual",
        "Verbal": "Verbal",
        "Material": "Material",
        "Metal": "Metal",
        "Diagonal": "Diagonal",
        "Horizontal": "Horizontal",
        "Sprint": "Sprint",
        "Kit": "Kit",
        "Tempo": "Tempo",
        "Timbre": "Timbre",
        "Sub": "Sub",
        "Premortem": "Premortem",
        "Premortem: ${_briefValue(draft.premortem)}": "Premortem: ${_briefValue(draft.premortem)}",
        "Conf": "Conf.",
        "$_loopCycleSeconds s": "$_loopCycleSeconds s",
        "$_targetMinutes min": "$_targetMinutes min",
        "$minutes min": "$minutes min",
        "{minutes} min": "{minutes} min",
        " · Auto {interval}s": " · Auto {interval}s",
        "· Auto {interval}s": " · Automático {interval}s",
        "10 min": "10 min",
        "10-20 min": "10-20 min",
        "3 min": "3 min",
        "Alto": "Alto",
        "Aurora": "Aurora",
        "Bimanual": "Bimanual",
        "Bt": "Bt",
        "Confusable": "Confundible",
        "Distractor": "Distractor",
        "Electro": "Electro",
        "Error": "Error",
        "Extra": "Extra",
        "Extra: {value}": "Extra: {value}",
        "Factorial": "Factorial",
        "Hi-hat": "Hi-hat",
        "Hirajoshi": "Hirajoshi",
        "Jade": "Jade",
        "Joystick": "Joystick",
        "Local": "Local",
        "Metro": "Metro",
        "Mono": "Mono",
        "Nylon": "Nylon",
        "Oddball": "Oddball",
        "Piano": "Piano",
        "SiliconFlow API": "SiliconFlow API",
        "Solo": "Solo",
        "Stroop": "Stroop",
        "Sub ×{div}": "Sub ×{div}",
        "Tempo $_bpm BPM": "Tempo $_bpm BPM",
        "Tom": "Tom",
        "Variable": "Variable",
        "Vertical": "Vertical",
        "Visible": "Visible",
        "Zigzag": "Zigzag",
        "pts": "pts",
        "s": "s",
        "min": "min",
    },
    "ru": {
        "Start": "Начать",
        "Pause": "Пауза",
        '"{from}" -> "{to}"': "«{from}» → «{to}»",
        "Low BOLT": "Низкий BOLT",
        "SiliconFlow API": "SiliconFlow API",
        "Strike {value}%": "Удар {value}%",
        "Sub ×{div}": "Деление ×{div}",
        "Unlimited": "Без ограничений",
        "Add/Sub": "Сложение/вычитание",
        "pts": "очк.",
        "s": "с",
        "min": "мин",
    },
}

for _locale, _terms in STATIC_TERM_EXTENSIONS.items():
    STATIC_TERMS.setdefault(_locale, {}).update(_terms)


def static_translation(locale, source):
    source = (source or "").strip()
    if locale == "zh" and CJK_RE.search(source):
        return source
    if source in STATIC_TERMS.get(locale, {}):
        return STATIC_TERMS[locale][source]
    if is_brand_or_code(source):
        return source
    if re.fullmatch(r"\d+\s*/\s*\d+", source):
        return source
    if re.fullmatch(r"[\W_]+", source):
        return source
    return None


def source_text_for_entry(entry, tables):
    texts = entry.get("texts") or {}
    runtime_key = runtime_key_for_entry(entry)
    english = (
        texts.get("en")
        or tables["en"].get(entry["id"])
        or tables["en"].get(runtime_key)
        or ""
    )
    if english:
        return english
    zh = texts.get("zh") or tables["zh"].get(entry["id"]) or ""
    # Some extractor rows accidentally concatenated zh and en branches. Recover
    # the English suffix when it is plainly present in the current source text.
    match = re.search(r"([A-Z][A-Za-z0-9 ,.;:!?/'\"()$${}\[\]_\-\u00b7>=%*/&|]+)$", zh)
    if match:
        return match.group(1).strip()
    if entry.get("kind") == "i18n_runtime_reference":
        return humanize_runtime_key(runtime_key)
    return ""


def source_language_for_text(text):
    if CJK_RE.search(text or "") and not re.search(r"\b[A-Za-z]{3,}\b", text or ""):
        return "zh"
    return "en"


def needs_locale(entry, locale, tables):
    if entry.get("kind") not in TRANSLATABLE_KINDS:
        return False
    entry_id = entry["id"]
    runtime_key = runtime_key_for_entry(entry)
    english = (
        tables["en"].get(entry_id)
        or tables["en"].get(runtime_key)
        or (entry.get("texts") or {}).get("en", "")
        or source_text_for_entry(entry, tables)
    )
    value = tables[locale].get(runtime_key) or tables[locale].get(entry_id)
    if value and english and not placeholders_compatible(locale, value, english):
        return True
    if looks_localized(locale, value, english):
        return False
    if locale in (entry.get("missingLocales") or []):
        return True
    if value is None or value == "":
        return True
    if locale != "en" and english and value == english and not is_brand_or_code(english):
        return True
    return False


def collect_jobs(registry, tables, include_zh=False, force_runtime=False):
    jobs = []
    seen = set()
    for entry in registry["entries"]:
        if entry.get("kind") not in TRANSLATABLE_KINDS:
            continue
        source = source_text_for_entry(entry, tables)
        if not source.strip():
            continue
        for locale in TARGET_LOCALES:
            if locale == "zh" and not include_zh:
                continue
            if not force_runtime and not needs_locale(entry, locale, tables):
                continue
            static = static_translation(locale, source)
            write_keys = write_keys_for_entry(entry)
            key = (write_keys[0], locale)
            if key in seen:
                continue
            seen.add(key)
            jobs.append(
                {
                    "id": write_keys[0],
                    "writeIds": write_keys,
                    "locale": locale,
                    "source": source,
                    "sourceLang": source_language_for_text(source),
                    "static": static,
                    "kind": entry.get("kind"),
                    "file": ((entry.get("sources") or [{}])[0]).get("file", ""),
                    "line": ((entry.get("sources") or [{}])[0]).get("line", 0),
                }
            )
    return jobs


def translate_chunk_resilient(translator, jobs, source_lang, locale, timeout, attempts):
    last_reason = "translation failed"
    for attempt in range(max(1, attempts)):
        try:
            translated = translate_batch(translator, jobs, source_lang, locale, timeout)
            if len(translated) == len(jobs):
                return translated, {}
            if len(jobs) == 1 and translated:
                return translated, {}
            last_reason = f"missing batch marker ({len(translated)}/{len(jobs)})"
        except Exception as exc:
            last_reason = f"{type(exc).__name__}: {str(exc)[:240]}"
        time.sleep(0.8 + attempt * 0.6)

    if len(jobs) > 1:
        mid = max(1, len(jobs) // 2)
        left_values, left_errors = translate_chunk_resilient(
            translator, jobs[:mid], source_lang, locale, timeout, attempts
        )
        right_values, right_errors = translate_chunk_resilient(
            translator, jobs[mid:], source_lang, locale, timeout, attempts
        )
        values = dict(left_values)
        errors = dict(left_errors)
        for index, value in right_values.items():
            values[index + mid] = value
        for index, reason in right_errors.items():
            errors[index + mid] = reason
        return values, errors

    return {}, {0: last_reason}


def path_with_locale(prefix, locale, suffix):
    if locale:
        return BUILD_DIR / f"{prefix}_{locale}.{suffix}"
    return BUILD_DIR / f"{prefix}.{suffix}"


def load_cache(path):
    if path.exists():
        return load_json(path)
    return {}


def save_cache(cache, path):
    write_json(path, cache)


def localized_counts(registry, tables):
    counts = {locale: 0 for locale in TARGET_LOCALES}
    for entry in registry["entries"]:
        if entry.get("kind") not in TRANSLATABLE_KINDS:
            continue
        entry_id = entry["id"]
        runtime_key = runtime_key_for_entry(entry)
        english = (
            tables["en"].get(entry_id)
            or tables["en"].get(runtime_key)
            or (entry.get("texts") or {}).get("en", "")
            or source_text_for_entry(entry, tables)
        )
        for locale in TARGET_LOCALES:
            value = tables[locale].get(runtime_key) or tables[locale].get(entry_id)
            if looks_localized(locale, value, english):
                counts[locale] += 1
    return counts


def parse_batch_output(output, count):
    found = {}
    for match in MARKER_RE.finditer(output.strip()):
        index = int(match.group(1))
        if 0 <= index < count:
            found[index] = clean_translation(match.group(2))
    return found


def translate_batch(translator, jobs, source_lang, locale, timeout):
    import translators as ts

    protected = []
    mappings = []
    for i, job in enumerate(jobs):
        text, mapping = protect_placeholders(job["source"])
        protected.append(f"[[I{i:04d}]] {text}")
        mappings.append(mapping)
    payload = "\n".join(protected)
    output = ts.translate_text(
        payload,
        translator=translator,
        from_language=source_lang,
        to_language=locale,
        timeout=timeout,
    )
    parsed = parse_batch_output(output, len(jobs))
    results = {}
    for i, raw in parsed.items():
        results[i] = restore_placeholders(raw, mappings[i])
    return results


def apply_jobs(
    registry,
    tables,
    jobs,
    cache,
    cache_path,
    translator,
    batch_size,
    timeout,
    attempts,
    dry_run=False,
):
    completed = []
    failed = []
    static_count = 0
    remote_count = 0

    for job in jobs:
        if job["static"] is None:
            continue
        if not dry_run:
            for write_id in job.get("writeIds", [job["id"]]):
                tables[job["locale"]][write_id] = job["static"]
        completed.append({**job, "value": job["static"], "method": "static_term"})
        static_count += 1

    remote_jobs = [
        job
        for job in jobs
        if job["locale"] in REMOTE_LOCALES and job["static"] is None
    ]

    grouped = {}
    pending_by_cache_key = {}
    for job in remote_jobs:
        cache_key = f"{translator}|en|{job['locale']}|{sha_text(job['source'])}|{job['source']}"
        cached = cache.get(cache_key)
        if cached:
            value = cached["value"]
            if placeholder_set(value) == placeholder_set(job["source"]):
                if not dry_run:
                    for write_id in job.get("writeIds", [job["id"]]):
                        tables[job["locale"]][write_id] = value
                completed.append({**job, "value": value, "method": "cache"})
                continue
        pending_by_cache_key.setdefault(cache_key, []).append(job)

    for cache_key, pending_jobs in pending_by_cache_key.items():
        representative = pending_jobs[0]
        grouped.setdefault((representative.get("sourceLang", "en"), representative["locale"]), []).append(
            (representative, cache_key, pending_jobs)
        )

    for (source_lang, locale), items in grouped.items():
        index = 0
        print(
            f"[{locale}] remote unique batches: {len(items)} items, batch_size={batch_size}",
            flush=True,
        )
        while index < len(items):
            chunk = items[index : index + batch_size]
            chunk_jobs = [item[0] for item in chunk]
            print(
                f"[{locale}] translating {index + 1}-{index + len(chunk)} / {len(items)}",
                flush=True,
            )
            translated, translate_errors = translate_chunk_resilient(
                translator, chunk_jobs, source_lang, locale, timeout, attempts
            )
            if translate_errors:
                failed.extend(
                    {
                        **job,
                        "reason": translate_errors.get(offset, "translation failed"),
                    }
                    for offset, (_job, _cache_key, pending_jobs) in enumerate(chunk)
                    if offset in translate_errors
                    for job in pending_jobs
                )

            for offset, (job, cache_key, pending_jobs) in enumerate(chunk):
                if offset in translate_errors:
                    continue
                value = translated.get(offset, "").strip()
                if not value:
                    failed.extend(
                        {**pending_job, "reason": "missing batch marker"}
                        for pending_job in pending_jobs
                    )
                    continue
                if "???" in value:
                    failed.extend(
                        {
                            **pending_job,
                            "value": value,
                            "reason": "question-mark mojibake",
                        }
                        for pending_job in pending_jobs
                    )
                    continue
                if placeholder_set(value) != placeholder_set(job["source"]):
                    failed.extend(
                        {
                            **pending_job,
                            "value": value,
                            "reason": "placeholder mismatch",
                            "sourcePlaceholders": placeholder_set(job["source"]),
                            "valuePlaceholders": placeholder_set(value),
                        }
                        for pending_job in pending_jobs
                    )
                    continue
                if not looks_localized(job["locale"], value, job["source"]):
                    failed.extend(
                        {
                            **pending_job,
                            "value": value,
                            "reason": "still looks like fallback",
                        }
                        for pending_job in pending_jobs
                    )
                    continue
                if not dry_run:
                    for pending_job in pending_jobs:
                        for write_id in pending_job.get("writeIds", [pending_job["id"]]):
                            tables[pending_job["locale"]][write_id] = value
                    cache[cache_key] = {
                        "value": value,
                        "locale": job["locale"],
                        "source": job["source"],
                        "translator": translator,
                    }
                completed.extend(
                    {**pending_job, "value": value, "method": translator}
                    for pending_job in pending_jobs
                )
                remote_count += len(pending_jobs)
            save_cache(cache, cache_path)
            index += batch_size
            print(
                f"[{locale}] done {min(index, len(items))} / {len(items)}",
                flush=True,
            )
            time.sleep(0.4)

    return {
        "completed": completed,
        "failed": failed,
        "staticCount": static_count,
        "remoteCount": remote_count,
    }


def sync_registry(registry, tables, report_summary):
    changed_entries = 0
    unresolved_by_kind = {}
    for entry in registry["entries"]:
        if entry.get("kind") not in TRANSLATABLE_KINDS:
            continue
        entry_id = entry["id"]
        runtime_key = runtime_key_for_entry(entry)
        texts = entry.setdefault("texts", {})
        english = tables["en"].get(entry_id) or tables["en"].get(runtime_key) or texts.get("en", "")
        if not english:
            english = source_text_for_entry(entry, tables)
            if english:
                tables["en"][runtime_key] = english
                tables["en"][entry_id] = english
        if not english.strip():
            entry.pop("missingLocales", None)
            continue
        missing = []
        for locale in LOCALES:
            value = tables[locale].get(runtime_key) or tables[locale].get(entry_id)
            if (
                value
                and looks_localized(locale, value, english)
                and placeholders_compatible(locale, value, english)
            ):
                if texts.get(locale) != value:
                    texts[locale] = value
                    changed_entries += 1
                tables[locale][runtime_key] = value
                tables[locale][entry_id] = value
            elif locale != "en":
                missing.append(locale)
        if missing:
            entry["missingLocales"] = missing
            unresolved_by_kind[entry.get("kind", "unknown")] = (
                unresolved_by_kind.get(entry.get("kind", "unknown"), 0) + 1
            )
        else:
            entry.pop("missingLocales", None)

    summary = registry.setdefault("summary", {})
    completion = (
        {
            "date": "2026-05-29",
            "sourceCommit": "current-catalog-only",
            "strategy": (
                "Redo without historical translation reuse. Regenerated runtime and explicit UI "
                "catalog entries from current English sources using verified Bing batches, "
                "static UI terms, placeholder protection, cache, and validation. Non-runtime "
                "literal candidates remain audit-only."
            ),
            "translator": report_summary["translator"],
            "completedByLocale": report_summary["completedByLocale"],
            "failedCount": report_summary["failedCount"],
            "staticCount": report_summary["staticCount"],
            "remoteCount": report_summary["remoteCount"],
            "registryEntriesSynced": changed_entries,
            "unresolvedByKind": unresolved_by_kind,
        }
    )
    if report_summary.get("replaceCompletionSummary"):
        summary["localeCompletion"] = [completion]
    else:
        completions = summary.setdefault("localeCompletion", [])
        completions.append(completion)
    return changed_entries


def audit(registry, tables):
    unresolved = []
    same_as_en = {locale: 0 for locale in TARGET_LOCALES}
    by_kind = {}
    for entry in registry["entries"]:
        if entry.get("kind") not in TRANSLATABLE_KINDS:
            continue
        entry_id = entry["id"]
        runtime_key = runtime_key_for_entry(entry)
        english = (
            tables["en"].get(entry_id)
            or tables["en"].get(runtime_key)
            or (entry.get("texts") or {}).get("en", "")
            or source_text_for_entry(entry, tables)
        )
        if not english.strip():
            continue
        for locale in TARGET_LOCALES:
            value = tables[locale].get(runtime_key) or tables[locale].get(entry_id)
            if locale != "en" and value and english and value == english and not is_brand_or_code(english):
                same_as_en[locale] += 1
            placeholder_mismatch = bool(value and not placeholders_compatible(locale, value, english))
            if placeholder_mismatch or not looks_localized(locale, value, english):
                item = {
                    "id": entry_id,
                    "locale": locale,
                    "kind": entry.get("kind"),
                    "source": english,
                    "value": value,
                    "reason": "placeholder mismatch"
                    if placeholder_mismatch
                    else "missing or fallback",
                    "file": ((entry.get("sources") or [{}])[0]).get("file", ""),
                    "line": ((entry.get("sources") or [{}])[0]).get("line", 0),
                }
                unresolved.append(item)
                by_kind[entry.get("kind", "unknown")] = by_kind.get(entry.get("kind", "unknown"), 0) + 1
    return {
        "unresolvedCount": len(unresolved),
        "unresolvedByKind": by_kind,
        "sameAsEn": same_as_en,
        "unresolvedSamples": unresolved[:200],
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--translator", default="bing")
    parser.add_argument("--batch-size", type=int, default=25)
    parser.add_argument("--timeout", type=int, default=30)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--include-zh", action="store_true")
    parser.add_argument("--fail-on-untranslated", action="store_true")
    parser.add_argument("--locale", choices=TARGET_LOCALES)
    parser.add_argument("--force-runtime", action="store_true")
    parser.add_argument("--attempts", type=int, default=2)
    parser.add_argument("--defer-registry-sync", action="store_true")
    parser.add_argument("--sync-only", action="store_true")
    parser.add_argument("--replace-completion-summary", action="store_true")
    parser.add_argument("--cache-prefix", default="bing_cache")
    parser.add_argument("--report-prefix", default="completion_report")
    args = parser.parse_args()

    os.environ.setdefault("PYTHONIOENCODING", "utf-8")
    cache_path = path_with_locale(args.cache_prefix, args.locale, "json")
    report_path = path_with_locale(args.report_prefix, args.locale, "json")
    registry = load_json(REGISTRY_PATH)
    tables = {
        locale: load_json(CATALOG_DIR / f"app_texts_{locale}.json")
        for locale in LOCALES
    }
    cache = load_cache(cache_path)
    if args.sync_only:
        before_audit = audit(registry, tables)
        report_summary = {
            "translator": "sync-only",
            "completedByLocale": localized_counts(registry, tables),
            "failedCount": 0,
            "staticCount": 0,
            "remoteCount": 0,
            "forceRuntime": True,
            "replaceCompletionSummary": args.replace_completion_summary,
        }
        sync_registry(registry, tables, report_summary)
        for locale in LOCALES:
            write_json(CATALOG_DIR / f"app_texts_{locale}.json", tables[locale])
        write_json(REGISTRY_PATH, registry)
        after_audit = audit(registry, tables)
        report = {
            "createdAt": "2026-05-29",
            "inputJobCount": 0,
            "summary": report_summary,
            "syncOnly": True,
            "beforeAudit": before_audit,
            "afterAudit": after_audit,
            "failed": [],
        }
        write_json(report_path, report)
        print(json.dumps(report["summary"], ensure_ascii=False, indent=2))
        print(json.dumps(report["afterAudit"], ensure_ascii=False, indent=2))
        return 1 if args.fail_on_untranslated and after_audit["unresolvedCount"] else 0

    jobs = collect_jobs(
        registry,
        tables,
        include_zh=args.include_zh,
        force_runtime=args.force_runtime,
    )
    if args.locale:
        jobs = [job for job in jobs if job["locale"] == args.locale]
    if args.limit:
        jobs = jobs[: args.limit]

    before_audit = audit(registry, tables)
    result = apply_jobs(
        registry,
        tables,
        jobs,
        cache,
        cache_path,
        translator=args.translator,
        batch_size=args.batch_size,
        timeout=args.timeout,
        attempts=args.attempts,
        dry_run=args.dry_run,
    )
    completed_by_locale = {}
    for item in result["completed"]:
        completed_by_locale[item["locale"]] = completed_by_locale.get(item["locale"], 0) + 1

    report_summary = {
        "translator": args.translator,
        "completedByLocale": completed_by_locale,
        "failedCount": len(result["failed"]),
        "staticCount": result["staticCount"],
        "remoteCount": result["remoteCount"],
    }

    if not args.dry_run:
        if not args.defer_registry_sync:
            sync_registry(registry, tables, report_summary)
            locales_to_write = LOCALES
        elif args.locale:
            locales_to_write = [args.locale]
        else:
            locales_to_write = sorted({job["locale"] for job in jobs})
        for locale in locales_to_write:
            write_json(CATALOG_DIR / f"app_texts_{locale}.json", tables[locale])
        if not args.defer_registry_sync:
            write_json(REGISTRY_PATH, registry)

    after_audit = audit(registry, tables)
    report = {
        "createdAt": "2026-05-29",
        "inputJobCount": len(jobs),
        "summary": report_summary,
        "forceRuntime": args.force_runtime,
        "beforeAudit": before_audit,
        "afterAudit": after_audit,
        "failed": result["failed"][:1000],
    }
    write_json(report_path, report)
    save_cache(cache, cache_path)
    print(json.dumps(report["summary"], ensure_ascii=False, indent=2))
    print(json.dumps(report["afterAudit"], ensure_ascii=False, indent=2))
    return 1 if args.fail_on_untranslated and result["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())
