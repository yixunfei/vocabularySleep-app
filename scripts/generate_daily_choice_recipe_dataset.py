from __future__ import annotations

import argparse
import csv
import hashlib
import html
import json
import re
import sqlite3
import unicodedata
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


BLOCK_END_RE = re.compile(
    r"</(p|div|h\d|li|tr|td|section|article|dd|dt|blockquote)\s*>",
    re.IGNORECASE,
)
BR_RE = re.compile(r"<br\s*/?>", re.IGNORECASE)
TAG_RE = re.compile(r"<[^>]+>")
SPACE_RE = re.compile(r"[ \t\xa0]+")
MULTI_NL_RE = re.compile(r"\n+")
QUANTITY_RE = re.compile(
    r"[0-9０-９]+(?:/[0-9０-９]+)?(?:\.[0-9]+)?\s*"
    r"(克|千克|公斤|斤|两|毫升|ml|mL|g|kg|个|只|棵|根|片|条|块|勺|匙|杯|瓣|朵|包|把|颗|枚|张|盒|碗|匙)?"
)

BOOK_REFERENCE_TITLES = (
    "YunYouJun/cook（recipe.csv / 做菜之前）",
    "一学就会做家常菜1688例",
    "凉拌美食菜谱",
    "家常小炒139例",
    "小菜谱一定要学会的家常简易刀工",
    "意大利菜谱",
    "最牛的菜谱：6744道菜谱大全",
    "汤煲美食菜谱",
    "百变营养米饭139例",
    "Nourishing Recipes for Elderly",
    "The Italian Pantry",
    "食趣：欧文的无国界创意厨房",
    "专业烘焙 第3版",
    "正確洗菜，擺脫農藥陰影",
    "超完美地中海飲食指南",
    "博古斯学院法式西餐烹饪宝典",
    "請用，西班牙海鮮飯",
    "我的獨享宵夜",
)

MATERIAL_HEADERS = ("材料", "原料", "食材", "料理", "材料及调味料", "主料")
SEASONING_HEADERS = ("调料", "辅料", "配料", "佐料")
STEP_HEADERS = ("做法", "操作", "制作方法", "制作过程", "制作", "制法")
NOTE_HEADERS = (
    "特点",
    "功效",
    "营养功效",
    "贴心小提示",
    "温馨小提示",
    "营养看台",
    "小炒门道",
    "营养快线",
    "营／养／快／线",
    "关键",
    "所属菜系",
    "TIPS",
    "小叮咛",
)
LIBRARY_ID = "toolbox_daily_choice_recipe_library"
SCHEMA_ID = "vocabulary_sleep.daily_choice.recipe_library"
SCHEMA_VERSION = 1
DEFAULT_COOK_CSV_URL = (
    "https://raw.githubusercontent.com/YunYouJun/cook/main/app/data/recipe.csv"
)

CUISINE_MARKERS = (
    "浙江菜",
    "川菜",
    "粤菜",
    "鲁菜",
    "湘菜",
    "闽菜",
    "苏菜",
    "徽菜",
    "东北菜",
    "西餐",
    "法式",
    "意大利",
    "西班牙",
    "其它菜系",
    "其他菜系",
)
MEAT_OR_SEAFOOD_CONTAINS = {
    "pork",
    "beef",
    "mutton",
    "chicken",
    "duck",
    "seafood",
}
MEAT_OR_SEAFOOD_RISK_TERMS = (
    "猪肉",
    "猪油",
    "猪肝",
    "猪肚",
    "猪蹄",
    "猪耳",
    "猪腰",
    "排骨",
    "里脊",
    "五花肉",
    "腊肉",
    "腊肠",
    "火腿",
    "午餐肉",
    "培根",
    "牛肉",
    "牛腩",
    "牛柳",
    "肥牛",
    "牛排",
    "羊肉",
    "羊排",
    "鸡肉",
    "鸡翅",
    "鸡腿",
    "鸡胸",
    "鸡丁",
    "鸡丝",
    "乌鸡",
    "鸭肉",
    "鸭胗",
    "鸭腿",
    "烤鸭",
    "兔肉",
    "兔丁",
    "龟肉",
    "甲鱼",
    "鳖",
    "鸽",
    "鹌鹑",
    "鹿肉",
    "驴肉",
    "鹅肉",
    "肥肠",
    "牛蛙",
    "田鸡",
    "鱼",
    "虾",
    "蟹",
    "鱿鱼",
    "章鱼",
    "海参",
    "牡蛎",
    "鲜贝",
    "干贝",
    "海米",
    "蛤",
    "蚌",
)

SECTION_ALIASES = {}


def normalize_header(text: str) -> str:
    return (
        text.strip()
        .lower()
        .replace("【", "")
        .replace("】", "")
        .replace("〔", "")
        .replace("〕", "")
        .replace("✔", "")
        .replace("●", "")
        .replace("•", "")
        .replace("■", "")
        .replace("□", "")
        .replace("◆", "")
        .replace("◇", "")
        .replace("：", "")
        .replace(":", "")
        .replace(" ", "")
    )


for header in MATERIAL_HEADERS:
    SECTION_ALIASES[normalize_header(header)] = "materials"
for header in SEASONING_HEADERS:
    SECTION_ALIASES[normalize_header(header)] = "seasonings"
for header in STEP_HEADERS:
    SECTION_ALIASES[normalize_header(header)] = "steps"
for header in NOTE_HEADERS:
    SECTION_ALIASES[normalize_header(header)] = "notes"

JUNK_EXACT = {
    "目录",
    "目 录",
    "目　录",
    "内容目录",
    "书名页",
    "版权页",
    "Title",
    "COOKING",
    "RECIPE",
    "BookDNA",
    "Copyright",
}
JUNK_EXACT_NORMALIZED = {normalize_header(value) for value in JUNK_EXACT}
JUNK_CONTAINS = (
    "图书在版编目",
    "责任编辑",
    "版权所有",
    "Babelcube",
    "BookDNA",
    "Enrich Your Reading Experience",
    "你的评论和你的建议就是差异",
    "你正在寻找下一本书",
    "目录 contents",
    "扉页",
    "版权页面",
)
IGNORE_TITLE_PATTERNS = (
    "Chapter ",
    "Chapter1",
    "Chapter2",
    "Chapter3",
    "Chapter4",
    "Chapter5",
    "Chapter6",
    "Chapter7",
    "Chapter8",
    "Chapter9",
)
ENGLISH_INGREDIENT_HEADERS = ("ingredients",)
ENGLISH_STEP_HEADERS = ("procedure", "method", "directions", "instructions")
ENGLISH_NOTE_HEADERS = ("tips", "notes", "note")
ENGLISH_META_PREFIXES = (
    "serves ",
    "serving size:",
    "cooking time:",
    "prep time:",
    "preparation time:",
)
ENGLISH_SECTION_PREFIXES = ("for the ",)
ENGLISH_STEP_OPENERS = (
    "first",
    "meanwhile",
    "bring",
    "heat",
    "place",
    "mix",
    "add",
    "preheat",
    "drain",
    "return",
    "serve",
    "combine",
    "stir",
    "whisk",
    "bake",
    "cook",
    "fold",
    "pour",
    "to make",
    "in a ",
    "using a ",
)
INLINE_HEADER_PREFIXES = (
    *MATERIAL_HEADERS,
    *SEASONING_HEADERS,
    *STEP_HEADERS,
    *NOTE_HEADERS,
)

TYPE_KEYWORDS = {
    "cold_dish": ("凉拌", "拌", "沙拉", "冷盘", "泡菜"),
    "soup": ("汤", "羹"),
    "stir_fry": ("炒", "煸", "爆", "熘"),
    "braise": ("红烧", "烧", "卤", "酱"),
    "stew": ("炖", "煲", "焖"),
    "steam": ("蒸",),
    "pan_fry": ("煎", "锅贴"),
    "deep_fry": ("炸", "酥"),
    "bake": ("烤", "焗", "蛋糕", "吐司"),
    "rice": ("炒饭", "焖饭", "米饭", "粥", "拌饭", "抓饭", "饭团", "盖饭", "蛋包饭", "煲仔饭"),
    "noodle": ("面条", "意面", "意粉", "通心粉", "扁面", "空心面", "拉面", "刀削面", "挂面", "米粉", "河粉"),
    "dessert": ("蛋糕", "布丁", "甜品", "点心", "八宝饭", "慕斯", "奶冻", "冰淇淋", "甜点"),
}

INGREDIENT_CANONICALS = (
    ("鸡蛋", ("鸡蛋", "鸭蛋", "鹅蛋", "皮蛋", "松花蛋", "咸蛋", "蛋黄", "蛋清", "蛋液")),
    ("番茄", ("番茄", "西红柿")),
    ("土豆", ("土豆", "马铃薯")),
    ("胡萝卜", ("胡萝卜",)),
    ("洋葱", ("洋葱",)),
    ("大蒜", ("蒜", "蒜蓉", "蒜末", "蒜片")),
    ("生姜", ("姜", "姜片", "姜末", "泡姜")),
    ("葱", ("葱", "葱段", "葱花", "香葱", "青葱")),
    ("青椒", ("青椒", "红椒", "彩椒", "尖椒", "辣椒", "泡辣椒")),
    ("黄瓜", ("黄瓜",)),
    ("白菜", ("白菜", "圆白菜", "包心菜", "卷心菜")),
    ("西蓝花", ("西蓝花", "西兰花")),
    ("香菇", ("香菇", "口蘑", "蘑菇", "平菇", "金针菇", "鸡腿菇")),
    ("豆腐", ("豆腐", "豆腐干", "豆腐皮", "千叶豆腐", "腐竹")),
    ("米饭", ("米", "米饭", "糙米", "紫米")),
    ("面粉", ("面粉", "面包屑")),
    ("牛奶", ("牛奶", "奶油", "奶酪", "乳酪", "酸奶")),
    ("排骨", ("排骨", "猪排骨")),
    ("猪里脊", ("猪里脊", "猪里脊肉", "里脊肉")),
    ("猪油", ("猪油",)),
    ("猪肝", ("猪肝",)),
    ("猪肚", ("猪肚",)),
    ("猪蹄", ("猪蹄",)),
    ("猪耳", ("猪耳",)),
    ("猪腰", ("猪腰",)),
    ("火腿", ("火腿",)),
    ("培根", ("培根",)),
    ("腊肉", ("腊肉",)),
    ("腊肠", ("腊肠",)),
    ("猪肉", ("猪肉", "五花肉", "肉末", "肉馅")),
    ("牛肉", ("牛肉", "牛腩", "牛柳", "牛百叶", "肥牛", "牛排")),
    ("羊肉", ("羊肉", "羊排",)),
    ("鸡肉", ("鸡肉", "鸡翅", "鸡腿", "鸡脯", "鸡丁", "鸡丝", "鸡心", "鸡胗", "鸡肝", "鸡杂", "乌鸡")),
    ("鸭肉", ("鸭肉", "鸭胗", "鸭",)),
    ("鱼", ("鱼", "草鱼", "鲤鱼", "鲈鱼", "黄鱼", "鲫鱼", "平鱼", "带鱼", "鳜鱼", "鳕鱼", "咸鱼", "金枪鱼", "章鱼", "鱿鱼")),
    ("虾", ("虾", "虾仁", "大虾", "明虾", "基围虾")),
    ("蟹", ("蟹", "螃蟹")),
    ("贝类", ("鲜贝", "干贝", "海参", "海米")),
    ("花生", ("花生", "花生仁")),
    ("坚果", ("松仁", "腰果", "板栗", "栗子", "核桃", "杏仁")),
    ("芝麻", ("芝麻", "麻酱")),
    ("面包", ("面包", "吐司")),
)

FILTER_CONTAINS_PATTERNS = {
    "pork": ("猪肉", "排骨", "猪蹄", "肘", "里脊", "腊肉", "腊肠", "火腿", "午餐肉", "培根", "猪油", "猪肝", "猪肚", "猪耳", "猪腰"),
    "beef": ("牛肉", "牛腩", "牛柳", "牛排", "肥牛", "牛百叶"),
    "mutton": ("羊肉", "羊排"),
    "chicken": ("鸡肉", "鸡翅", "鸡腿", "鸡胸", "鸡丁", "鸡丝", "鸡心", "鸡胗", "鸡肝", "鸡杂", "乌鸡"),
    "duck": ("鸭肉", "鸭胗", "鸭腿", "烤鸭"),
    "seafood": ("鱼", "虾", "蟹", "鱿鱼", "海参", "牡蛎", "鲜贝", "干贝", "海米", "章鱼", "金枪鱼", "蛤", "蚌"),
    "egg": ("鸡蛋", "鸭蛋", "鹅蛋", "皮蛋", "松花蛋", "咸蛋", "蛋黄", "蛋清", "蛋液"),
    "dairy": ("牛奶", "奶油", "奶酪", "乳酪", "黄油", "酸奶"),
    "gluten": ("面粉", "面包", "面条", "吐司", "面包屑", "意面", "挂面", "饺子皮"),
    "soy": ("豆腐", "豆腐干", "豆腐皮", "腐竹", "黄豆", "酱油", "豆瓣"),
    "nut": ("花生", "松仁", "腰果", "核桃", "板栗", "栗子", "杏仁"),
    "sesame": ("芝麻", "麻酱", "香油"),
    "spicy": ("辣椒", "泡椒", "辣", "花椒", "辣酱", "辣油"),
    "alcohol": ("料酒", "黄酒", "啤酒", "白酒", "米酒", "绍酒", "葡萄酒", "红酒"),
}

TOOL_HINTS = {
    "microwave": ("微波", "微波炉"),
    "air_fryer": ("空气炸锅",),
    "oven": ("烤箱", "烤"),
    "rice_cooker": ("电饭煲", "焖饭", "煲仔饭", "蒸饭", "抓饭"),
}

STOP_WORDS = (
    "适量",
    "少许",
    "各适量",
    "各少许",
    "备用",
    "洗净",
    "切块",
    "切片",
    "切丝",
    "切丁",
    "切段",
    "剁末",
    "拍碎",
    "沥干",
    "焯水",
    "焯熟",
    "去皮",
    "去蒂",
    "去壳",
    "去核",
    "熟",
    "鲜",
    "嫩",
    "水发",
    "干",
)


@dataclass
class ExtractedRecipe:
    name: str
    materials: list[str]
    seasonings: list[str]
    steps: list[str]
    notes: list[str]
    book_title: str


def html_to_lines(raw_html: str) -> list[str]:
    text = BR_RE.sub("\n", raw_html)
    text = BLOCK_END_RE.sub("\n", text)
    text = TAG_RE.sub(" ", text)
    text = html.unescape(text)
    text = SPACE_RE.sub(" ", text)
    text = MULTI_NL_RE.sub("\n", text)
    lines: list[str] = []
    for line in text.splitlines():
        normalized = line.strip().strip("\ufeff").strip()
        if normalized:
            lines.append(normalized.strip("\"'"))
    return lines


def expand_inline_headers(lines: list[str]) -> list[str]:
    expanded: list[str] = []
    for line in lines:
        handled = False
        for prefix in INLINE_HEADER_PREFIXES:
            candidates = (
                f"{prefix}：",
                f"{prefix}:",
                f"【{prefix}】",
                f"〔{prefix}〕",
            )
            for candidate in candidates:
                if line.startswith(candidate):
                    expanded.append(prefix)
                    remainder = line[len(candidate) :].strip()
                    if remainder:
                        expanded.append(remainder)
                    handled = True
                    break
            if handled:
                break
        if not handled:
            expanded.append(line)
    return expanded


def is_junk_line(line: str) -> bool:
    normalized = normalize_header(line)
    if not normalized:
        return True
    if normalized in JUNK_EXACT_NORMALIZED:
        return True
    if all(character in "—-–_·.•*~ " for character in line):
        return True
    if len(line) > 60 and ("出版社" in line or "有限公司" in line):
        return True
    line_lower = line.lower()
    return any(keyword.lower() in line_lower for keyword in JUNK_CONTAINS)


def looks_like_recipe_title(line: str) -> bool:
    if is_junk_line(line):
        return False
    if len(line) < 2 or len(line) > 20:
        return False
    if normalize_header(line) in SECTION_ALIASES:
        return False
    if any(pattern in line for pattern in IGNORE_TITLE_PATTERNS):
        return False
    if re.search(r"[0-9０-９]", line):
        return False
    if re.match(r"^[Pp]\d+", line):
        return False
    if re.match(r"^[➊➋➌➍➎➏➐➑➒➓]", line):
        return False
    if re.search(r"^[0-9一二三四五六七八九十]+[、.．]", line):
        return False
    if any(symbol in line for symbol in "，,。；;：:"):
        return False
    return True


def next_non_junk(lines: list[str], start: int) -> int:
    index = start
    while index < len(lines) and is_junk_line(lines[index]):
        index += 1
    return index


def has_material_header_ahead(lines: list[str], index: int) -> bool:
    probe = next_non_junk(lines, index + 1)
    limit = min(len(lines), index + 7)
    while probe < limit:
        if SECTION_ALIASES.get(normalize_header(lines[probe])) == "materials":
            return True
        probe = next_non_junk(lines, probe + 1)
    return False


def looks_like_section_heading(lines: list[str], index: int) -> bool:
    probe = next_non_junk(lines, index + 1)
    limit = min(len(lines), index + 5)
    while probe < limit:
        if SECTION_ALIASES.get(normalize_header(lines[probe])) == "materials":
            return False
        if looks_like_recipe_title(lines[probe]):
            return True
        probe = next_non_junk(lines, probe + 1)
    return False


def split_materials(lines: list[str]) -> list[str]:
    items: list[str] = []
    for line in lines:
        parts = re.split(r"[；;。]|[，,、]", line)
        for part in parts:
            cleaned = part.strip(" 　,，。；;")
            if cleaned:
                items.append(cleaned)
    return dedupe_strings(items)


def split_steps(lines: list[str]) -> list[str]:
    steps: list[str] = []
    for line in lines:
        parts = re.split(r"(?=(?:[0-9]+[.．、]))", line)
        for part in parts:
            cleaned = re.sub(r"^[➊➋➌➍➎➏➐➑➒➓❶❷❸❹❺❻❼❽❾❿]\s*", "", part).strip()
            cleaned = re.sub(r"^[0-9]+[.．、]\s*", "", cleaned)
            cleaned = cleaned.replace("??", "").replace("�", "").replace("□", "").strip()
            if not cleaned:
                continue
            steps.append(cleaned)
    return steps


def clean_output_text(value: str) -> str:
    text = unicodedata.normalize("NFKC", value)
    text = text.replace("??", "").replace("�", "").replace("□", "")
    return text.strip()


def dedupe_strings(values: list[str], limit: int | None = None) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        normalized = clean_output_text(value)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        result.append(normalized)
        if limit is not None and len(result) >= limit:
            break
    return result


def looks_like_english_recipe_title(line: str) -> bool:
    stripped = line.strip()
    if len(stripped) < 3 or len(stripped) > 80:
        return False
    normalized = normalize_header(stripped)
    if not normalized:
        return False
    if normalized in JUNK_EXACT_NORMALIZED:
        return False
    if normalized in ENGLISH_INGREDIENT_HEADERS:
        return False
    if normalized in ENGLISH_STEP_HEADERS:
        return False
    if normalized in ENGLISH_NOTE_HEADERS:
        return False
    if stripped.endswith(":"):
        return False
    if any(stripped.startswith(prefix) for prefix in ("PART", "Chapter", "Foreword")):
        return False
    if any(stripped.lower().startswith(prefix) for prefix in ENGLISH_META_PREFIXES):
        return False
    if stripped.lower().startswith(ENGLISH_SECTION_PREFIXES):
        return False
    if not any(character.isalpha() for character in stripped):
        return False
    if len(stripped.split()) > 12:
        return False
    if len(stripped) > 42 and any(symbol in stripped for symbol in ".!?"):
        return False
    return True


def looks_like_english_meta(line: str) -> bool:
    lowered = line.lower()
    return any(lowered.startswith(prefix) for prefix in ENGLISH_META_PREFIXES)


def looks_like_english_step(line: str) -> bool:
    lowered = line.lower().strip()
    if any(lowered.startswith(prefix) for prefix in ENGLISH_STEP_OPENERS):
        return True
    if lowered.endswith(".") and len(lowered.split()) >= 10:
        return True
    return False


def looks_like_english_ingredient(line: str) -> bool:
    lowered = line.lower().strip()
    if not lowered:
        return False
    if lowered.startswith(ENGLISH_SECTION_PREFIXES):
        return True
    if looks_like_english_meta(line):
        return False
    if normalized_english_header(line) in ENGLISH_INGREDIENT_HEADERS:
        return False
    if normalized_english_header(line) in ENGLISH_STEP_HEADERS:
        return False
    if looks_like_english_step(line):
        return False
    if re.match(r"^(?:\d+|½|¼|¾|\d+/\d+)", lowered):
        return True
    return len(lowered.split()) <= 10 and any(
        token in lowered
        for token in (
            "cup",
            "cups",
            "tbsp",
            "tsp",
            "g ",
            "kg",
            "ml",
            "oz",
            "lb",
            "egg",
            "salt",
            "pepper",
            "oil",
            "clove",
            "sprig",
        )
    )


def normalized_english_header(line: str) -> str:
    return normalize_header(line).rstrip(":")


def has_english_recipe_markers_ahead(lines: list[str], index: int) -> bool:
    limit = min(len(lines), index + 10)
    for probe in range(index + 1, limit):
        normalized = normalized_english_header(lines[probe])
        if normalized in ENGLISH_INGREDIENT_HEADERS:
            return True
        if looks_like_english_meta(lines[probe]):
            return True
    return False


def parse_english_recipe_blocks(lines: list[str], book_title: str) -> list[ExtractedRecipe]:
    recipes: list[ExtractedRecipe] = []
    book_key = normalize_name(Path(book_title).stem)
    index = 0
    while index < len(lines):
        line = lines[index]
        if not looks_like_english_recipe_title(line):
            index += 1
            continue
        line_key = normalize_name(line)
        if line_key and line_key in book_key:
            index += 1
            continue
        if not has_english_recipe_markers_ahead(lines, index):
            index += 1
            continue

        name = line.strip()
        notes: list[str] = []
        materials: list[str] = []
        steps: list[str] = []
        index += 1

        while index < len(lines):
            current = lines[index]
            normalized = normalized_english_header(current)
            if looks_like_english_meta(current):
                notes.append(current)
                index += 1
                continue
            if normalized in ENGLISH_INGREDIENT_HEADERS:
                index += 1
                break
            if looks_like_english_ingredient(current):
                break
            if looks_like_english_recipe_title(current) and has_english_recipe_markers_ahead(lines, index):
                break
            notes.append(current)
            index += 1

        while index < len(lines):
            current = lines[index]
            normalized = normalized_english_header(current)
            if normalized in ENGLISH_STEP_HEADERS:
                index += 1
                break
            if normalized in ENGLISH_NOTE_HEADERS:
                index += 1
                break
            if materials and looks_like_english_step(current):
                break
            if materials and looks_like_english_recipe_title(current) and has_english_recipe_markers_ahead(lines, index):
                break
            if not materials and not looks_like_english_ingredient(current):
                break
            materials.append(current)
            index += 1

        while index < len(lines):
            current = lines[index]
            normalized = normalized_english_header(current)
            if normalized in ENGLISH_NOTE_HEADERS:
                index += 1
                break
            if looks_like_english_recipe_title(current) and has_english_recipe_markers_ahead(lines, index):
                break
            steps.append(current)
            index += 1

        while index < len(lines):
            current = lines[index]
            if looks_like_english_recipe_title(current) and has_english_recipe_markers_ahead(lines, index):
                break
            notes.append(current)
            index += 1

        normalized_materials = dedupe_strings(materials, limit=50)
        normalized_steps = dedupe_strings(steps, limit=20)
        normalized_notes = dedupe_strings(notes, limit=12)
        if normalized_materials and normalized_steps:
            recipes.append(
                ExtractedRecipe(
                    name=name,
                    materials=normalized_materials,
                    seasonings=[],
                    steps=normalized_steps,
                    notes=normalized_notes,
                    book_title=book_title,
                )
            )
    return recipes


def parse_recipe_blocks(lines: list[str], book_title: str) -> list[ExtractedRecipe]:
    recipes: list[ExtractedRecipe] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        if (
            not looks_like_recipe_title(line)
            or not has_material_header_ahead(lines, index)
            or looks_like_section_heading(lines, index)
        ):
            index += 1
            continue

        name = line.replace("COOKING", "").replace("RECIPE", "").strip()
        sections = {
            "materials": [],
            "seasonings": [],
            "steps": [],
            "notes": [],
        }
        current_section: str | None = None
        index += 1
        while index < len(lines):
            line = lines[index]
            if (
                looks_like_recipe_title(line)
                and has_material_header_ahead(lines, index)
                and not looks_like_section_heading(lines, index)
                and sections["materials"]
                and sections["steps"]
            ):
                break

            section_key = SECTION_ALIASES.get(normalize_header(line))
            if section_key is not None:
                current_section = section_key
                index += 1
                continue

            if current_section is not None:
                sections[current_section].append(line)
            index += 1

        materials = split_materials(sections["materials"])
        seasonings = split_materials(sections["seasonings"])
        steps = split_steps(sections["steps"])
        notes = dedupe_strings(sections["notes"], limit=12)
        if materials and steps:
            recipes.append(
                ExtractedRecipe(
                    name=name,
                    materials=materials[:50],
                    seasonings=seasonings[:25],
                    steps=steps[:20],
                    notes=notes,
                    book_title=book_title,
                )
            )
    return recipes


def get_epub_text_paths(zf: zipfile.ZipFile) -> list[str]:
    try:
        container_root = ET.fromstring(zf.read("META-INF/container.xml"))
        rootfile = container_root.find(".//{*}rootfile")
        if rootfile is None:
            raise ValueError("missing rootfile")
        opf_path = rootfile.attrib["full-path"]
        opf_root = ET.fromstring(zf.read(opf_path))
        opf_dir = str(Path(opf_path).parent).replace("\\", "/")
        manifest: dict[str, str] = {}
        for item in opf_root.findall(".//{*}manifest/{*}item"):
            item_id = item.attrib.get("id")
            href = item.attrib.get("href")
            if not item_id or not href:
                continue
            full_path = f"{opf_dir}/{href}" if opf_dir not in ("", ".") else href
            manifest[item_id] = full_path.replace("\\", "/")
        ordered_paths: list[str] = []
        for itemref in opf_root.findall(".//{*}spine/{*}itemref"):
            item_id = itemref.attrib.get("idref")
            full_path = manifest.get(item_id or "")
            if full_path and full_path in zf.namelist():
                ordered_paths.append(full_path)
        if ordered_paths:
            return ordered_paths
    except Exception:
        pass
    return [
        name
        for name in zf.namelist()
        if name.lower().endswith((".html", ".xhtml", ".htm"))
    ]


def normalize_name(name: str) -> str:
    cleaned = unicodedata.normalize("NFKC", name).strip()
    cleaned = re.sub(r"^[〔【(（].*?[)）】〕]\s*", "", cleaned)
    cleaned = re.sub(r"[\s　·•:：()（）【】〔〕/\\,，.。!！?？\-—]+", "", cleaned)
    return cleaned.lower()


def recipe_quality_score(recipe: ExtractedRecipe) -> int:
    return (
        len(recipe.materials) * 3
        + len(recipe.seasonings) * 2
        + len(recipe.steps) * 4
        + len(recipe.notes)
    )


def choose_primary_type(types: list[str]) -> str:
    priority = (
        "rice",
        "noodle",
        "soup",
        "stir_fry",
        "braise",
        "stew",
        "steam",
        "pan_fry",
        "deep_fry",
        "bake",
        "cold_dish",
        "dessert",
    )
    for item in priority:
        if item in types:
            return item
    return "home_style"


def annotate_dish_types(recipe: ExtractedRecipe) -> list[str]:
    haystack = " ".join([recipe.name, recipe.book_title])
    dish_types: list[str] = []
    for dish_type, keywords in TYPE_KEYWORDS.items():
        if any(keyword in haystack for keyword in keywords):
            dish_types.append(dish_type)
    if "意大利" in recipe.book_title or "意面" in haystack:
        dish_types.append("noodle")
    if "凉拌" in recipe.book_title:
        dish_types.append("cold_dish")
    if "汤煲" in recipe.book_title:
        dish_types.extend(["soup", "stew"])
    if "小炒" in recipe.book_title:
        dish_types.append("stir_fry")
    if "百变营养米饭" in recipe.book_title:
        dish_types.append("rice")
    return dedupe_strings(dish_types)


def cleaned_ingredient_text(raw: str) -> str:
    text = unicodedata.normalize("NFKC", raw)
    text = re.sub(r"[（(][^)）]*[）)]", "", text)
    text = QUANTITY_RE.sub("", text)
    for stop_word in STOP_WORDS:
        text = text.replace(stop_word, "")
    text = re.sub(r"[A-Za-z]+", "", text)
    text = re.sub(r"[0-9０-９/]+", "", text)
    text = re.sub(r"[，,。；;：:、\s]+", "", text)
    return text.strip()


def ingredient_alias_matches(cleaned: str, canonical: str, alias: str) -> bool:
    if canonical == "葱":
        cleaned = cleaned.replace("洋葱", "").replace("葱头", "")
    return alias in cleaned


def extract_ingredient_keywords(recipe: ExtractedRecipe) -> list[str]:
    keywords: list[str] = []
    for raw_material in [*recipe.materials, *recipe.seasonings]:
        cleaned = cleaned_ingredient_text(raw_material)
        if not cleaned:
            continue
        matched = False
        for canonical, aliases in INGREDIENT_CANONICALS:
            if any(
                ingredient_alias_matches(cleaned, canonical, alias)
                for alias in aliases
            ):
                keywords.append(canonical)
                matched = True
        if not matched and 1 < len(cleaned) <= 8:
            keywords.append(cleaned)
    return dedupe_strings(keywords, limit=18)


def normalized_recipe_haystack(recipe: ExtractedRecipe) -> str:
    haystack = " ".join(
        [
            recipe.name,
            *recipe.materials,
            *recipe.seasonings,
            *recipe.steps,
            *recipe.notes,
        ]
    )
    return (
        unicodedata.normalize("NFKC", haystack)
        .replace("鱼腥草", "")
        .replace("鱼香", "")
        .replace("蛋白质", "")
    )


def contains_filter_pattern(haystack: str, pattern: str) -> bool:
    if pattern == "鱼":
        return bool(
            re.search(
                r"(?:草鱼|鲤鱼|鲈鱼|黄鱼|鲫鱼|平鱼|带鱼|鳜鱼|鳕鱼|咸鱼|"
                r"金枪鱼|桂鱼|鱼肉|鱼片|鱼块|鱼头|鱼尾|鱼丸|鱼排|"
                r"(?:^|[\s、，,])鱼(?:$|[\s、，,]))",
                haystack,
            )
        )
    if pattern == "虾":
        return bool(re.search(r"(?:虾|虾仁|大虾|明虾|基围虾)", haystack))
    if pattern == "蟹":
        return bool(re.search(r"(?:蟹|螃蟹)", haystack))
    return pattern in haystack


def recipe_has_meat_or_seafood_risk(
    recipe: ExtractedRecipe,
    filters: list[str],
) -> bool:
    contains = {
        item.split(":", 1)[1]
        for item in filters
        if item.startswith("contains:")
    }
    if contains & MEAT_OR_SEAFOOD_CONTAINS:
        return True
    haystack = normalized_recipe_haystack(recipe)
    return any(
        contains_filter_pattern(haystack, term)
        for term in MEAT_OR_SEAFOOD_RISK_TERMS
    )


def annotate_filter_ids(
    ingredient_keywords: list[str],
    dish_types: list[str],
    recipe: ExtractedRecipe,
) -> list[str]:
    haystack = normalized_recipe_haystack(recipe)
    filters: list[str] = []

    for filter_id, patterns in FILTER_CONTAINS_PATTERNS.items():
        if any(contains_filter_pattern(haystack, pattern) for pattern in patterns):
            filters.append(f"contains:{filter_id}")

    has_meat_or_seafood_risk = recipe_has_meat_or_seafood_risk(recipe, filters)
    has_meat = any(
        item
        in (
            "猪肉",
            "猪里脊",
            "排骨",
            "猪油",
            "猪肝",
            "猪肚",
            "猪蹄",
            "猪耳",
            "猪腰",
            "火腿",
            "培根",
            "腊肉",
            "腊肠",
            "牛肉",
            "羊肉",
            "鸡肉",
            "鸭肉",
        )
        for item in ingredient_keywords
    )
    has_seafood = any(item in ingredient_keywords for item in ("鱼", "虾", "蟹", "贝类"))

    if not has_meat_or_seafood_risk and not has_meat and not has_seafood:
        filters.append("profile:vegetarian")
    else:
        filters.append("profile:meat_based")

    animal_ingredient_labels = {
        "猪肉",
        "猪里脊",
        "排骨",
        "猪油",
        "猪肝",
        "猪肚",
        "猪蹄",
        "猪耳",
        "猪腰",
        "火腿",
        "培根",
        "腊肉",
        "腊肠",
        "牛肉",
        "羊肉",
        "鸡肉",
        "鸭肉",
        "鱼",
        "虾",
        "蟹",
        "贝类",
    }
    if (has_meat_or_seafood_risk or has_meat or has_seafood) and any(
        item
        for item in ingredient_keywords
        if item not in animal_ingredient_labels
    ):
        filters.append("profile:mixed")

    if "rice" in dish_types or "noodle" in dish_types:
        filters.append("profile:staple")
    if "dessert" in dish_types:
        filters.append("profile:dessert")

    for dish_type in dish_types:
        filters.append(f"type:{dish_type}")

    return dedupe_strings(filters)


def infer_tools(recipe: ExtractedRecipe, dish_types: list[str]) -> list[str]:
    haystack = " ".join([recipe.name, *recipe.steps, recipe.book_title])
    tools: list[str] = []
    for tool_id, keywords in TOOL_HINTS.items():
        if any(keyword in haystack for keyword in keywords):
            tools.append(tool_id)
    if "rice" in dish_types and "炒饭" not in recipe.name and "pot" not in tools:
        tools.append("rice_cooker")
    if not tools or "stir_fry" in dish_types or "soup" in dish_types or "braise" in dish_types or "stew" in dish_types:
        tools.append("pot")
    if "bake" in dish_types and "oven" not in tools and "air_fryer" not in tools:
        tools.append("oven")
    return dedupe_strings(tools)


def infer_meals(recipe: ExtractedRecipe, dish_types: list[str], filters: list[str]) -> list[str]:
    meals: list[str] = []
    haystack = " ".join([recipe.name, *recipe.notes])
    if any(keyword in haystack for keyword in ("早餐", "早饭", "吐司", "燕麦", "蛋包饭", "粥")):
        meals.append("breakfast")
    if "profile:dessert" in filters or any(
        keyword in haystack for keyword in ("甜品", "下午茶", "茶点", "蛋糕", "饼", "布丁", "奶冻")
    ):
        meals.append("tea")
    if any(item in dish_types for item in ("rice", "noodle", "soup", "stir_fry", "braise", "stew", "steam")):
        meals.extend(("lunch", "dinner"))
    if any(keyword in haystack for keyword in ("宵夜", "夜宵")) or any(
        item in dish_types for item in ("soup", "noodle")
    ):
        meals.append("night")
    if not meals:
        meals.extend(("lunch", "dinner"))
    return dedupe_strings(meals)


def build_subtitle(recipe: ExtractedRecipe, dish_types: list[str], tools: list[str]) -> str:
    parts: list[str] = []
    type_label_map = {
        "cold_dish": "凉拌",
        "soup": "汤羹",
        "stir_fry": "小炒",
        "braise": "烧卤",
        "stew": "炖煲",
        "steam": "清蒸",
        "pan_fry": "煎制",
        "deep_fry": "炸物",
        "bake": "烘烤",
        "rice": "饭食",
        "noodle": "面点",
        "dessert": "甜品",
        "home_style": "家常",
    }
    for dish_type in dish_types[:2]:
        label = type_label_map.get(dish_type)
        if label:
            parts.append(label)
    tool_label_map = {
        "pot": "一锅可做",
        "rice_cooker": "电饭煲友好",
        "microwave": "微波炉友好",
        "air_fryer": "空气炸锅友好",
        "oven": "烤箱友好",
    }
    if tools:
        parts.append(tool_label_map.get(tools[0], tools[0]))
    parts.extend(recipe.materials[:2])
    return " · ".join(dedupe_strings(parts, limit=4))


def build_details(recipe: ExtractedRecipe, dish_types: list[str], filters: list[str]) -> str:
    style_labels = {
        "cold_dish": "偏清爽凉拌",
        "soup": "适合作为热汤或汤羹",
        "stir_fry": "主打快火现炒",
        "braise": "更强调酱香和收汁",
        "stew": "适合慢炖焖煮",
        "steam": "更适合保留食材本味",
        "pan_fry": "适合平底锅煎制",
        "deep_fry": "口感更偏香酥",
        "bake": "适合烘烤定型",
        "rice": "属于主食向的饭食",
        "noodle": "属于面食或面条类",
        "dessert": "更偏甜品或点心",
    }
    style = style_labels.get(choose_primary_type(dish_types), "偏家常做法")
    ingredients = "、".join(recipe.materials[:4])
    audience = "更适合作为午晚餐主菜或搭配主食" if "profile:dessert" not in filters else "适合作为加餐、点心或下午茶"
    return f"{recipe.name}以{ingredients}为主要材料，{style}，步骤完整，{audience}。"


def clean_recipe_notes(raw_notes: list[str]) -> list[str]:
    notes: list[str] = []
    for raw_note in raw_notes:
        note = unicodedata.normalize("NFKC", raw_note).strip()
        if not note:
            continue
        if "清真友好" in note:
            continue
        for marker in CUISINE_MARKERS:
            note = note.replace(marker, "")
        note = re.sub(r"所属菜系[:：]?", "", note).strip(" ,，。；;、")
        if note:
            notes.append(note)
    return dedupe_strings(notes, limit=8)


def build_notes(recipe: ExtractedRecipe, filters: list[str], dish_types: list[str]) -> list[str]:
    notes = clean_recipe_notes(recipe.notes)
    if "contains:seafood" in filters:
        notes.append("海鲜类食材需要以完全熟透为准，处理后尽量尽快烹调。")
    if "contains:egg" in filters and "soup" in dish_types:
        notes.append("蛋液下锅前可先调匀，沿汤面缓慢划圈，更容易形成均匀口感。")
    if "contains:pork" in filters or "contains:beef" in filters or "contains:mutton" in filters:
        notes.append("肉类建议按厚薄尽量切匀，先确认熟透再调最终口味。")
    return dedupe_strings(notes, limit=8)


def build_tags(meals: list[str], dish_types: list[str], filters: list[str]) -> list[str]:
    meal_labels = {
        "breakfast": "早餐",
        "lunch": "午餐",
        "dinner": "晚餐",
        "tea": "下午茶",
        "night": "宵夜",
    }
    type_labels = {
        "cold_dish": "凉拌",
        "soup": "汤",
        "stir_fry": "炒",
        "braise": "烧",
        "stew": "炖煲",
        "steam": "蒸",
        "pan_fry": "煎",
        "deep_fry": "炸",
        "bake": "烤",
        "rice": "饭食",
        "noodle": "面食",
        "dessert": "甜品",
    }
    tags = [meal_labels[item] for item in meals if item in meal_labels]
    tags.extend(type_labels[item] for item in dish_types if item in type_labels)
    if "profile:vegetarian" in filters:
        tags.append("素")
    if "profile:meat_based" in filters:
        tags.append("荤")
    return dedupe_strings(tags, limit=8)


def merge_duplicate_recipes(recipes: list[ExtractedRecipe]) -> list[ExtractedRecipe]:
    merged: dict[str, ExtractedRecipe] = {}
    for recipe in recipes:
        key = normalize_name(recipe.name)
        existing = merged.get(key)
        if existing is None or recipe_quality_score(recipe) > recipe_quality_score(existing):
            merged[key] = recipe
    return list(merged.values())


def extract_from_epub(epub_path: Path) -> list[ExtractedRecipe]:
    extracted: list[ExtractedRecipe] = []
    with zipfile.ZipFile(epub_path) as zf:
        for content_path in get_epub_text_paths(zf):
            if not content_path.lower().endswith((".html", ".xhtml", ".htm")):
                continue
            lines = expand_inline_headers(
                html_to_lines(zf.read(content_path).decode("utf-8", "ignore"))
            )
            extracted.extend(parse_recipe_blocks(lines, epub_path.name))
            extracted.extend(parse_english_recipe_blocks(lines, epub_path.name))
    return merge_duplicate_recipes(extracted)


def split_cook_items(raw: str) -> list[str]:
    if not raw.strip():
        return []
    return dedupe_strings(
        [item.strip() for item in re.split(r"[、，,；;]", raw) if item.strip()]
    )


def cook_tool_id(raw: str) -> str | None:
    if "电饭煲" in raw:
        return "rice_cooker"
    if "微波炉" in raw:
        return "microwave"
    if "空气炸锅" in raw:
        return "air_fryer"
    if "烤箱" in raw:
        return "oven"
    if "大锅" in raw or "炒锅" in raw:
        return "pot"
    return None


def clean_cook_bv(raw: str) -> str:
    return raw.strip().replace("https://www.bilibili.com/video/", "")


def cook_specific_ingredients_from_title(name: str) -> list[str]:
    specific_terms = (
        "排骨",
        "猪蹄",
        "猪肝",
        "猪肚",
        "猪耳",
        "猪腰",
        "猪油",
        "火腿",
        "培根",
        "腊肉",
        "腊肠",
    )
    return [term for term in specific_terms if term in name]


def cook_dish_types(
    recipe: ExtractedRecipe,
    tags: list[str],
    methods: list[str],
) -> list[str]:
    dish_types = annotate_dish_types(recipe)
    method_map = {
        "炒": "stir_fry",
        "爆": "stir_fry",
        "煎": "pan_fry",
        "炸": "deep_fry",
        "烤": "bake",
        "焗": "bake",
        "蒸": "steam",
        "煮": "soup",
        "炖": "stew",
        "煲": "stew",
        "拌": "cold_dish",
        "烧": "braise",
        "焖": "braise",
    }
    for method in methods:
        mapped = method_map.get(method.strip())
        if mapped:
            dish_types.append(mapped)
    haystack = " ".join([recipe.name, *tags, *methods])
    if any(keyword in haystack for keyword in ("饭", "米", "煲饭", "焖饭")):
        dish_types.append("rice")
    if any(keyword in haystack for keyword in ("面", "粉", "意面", "方便面")):
        dish_types.append("noodle")
    return dedupe_strings(dish_types)


def build_cook_steps(
    name: str,
    ingredients: list[str],
    methods: list[str],
    tools: list[str],
) -> list[str]:
    ingredient_label = "、".join(ingredients[:6]) if ingredients else "主要食材"
    method_label = "、".join(methods) if methods else "家常方式"
    tool_label = "、".join(tools) if tools else "常用锅具"
    return [
        f"准备 {ingredient_label}，先按易熟程度和入口大小完成清洗、切配与沥水。",
        f"使用 {tool_label}，按 {method_label} 的思路先处理需要出香或更耐煮的食材。",
        f"主料接近成熟后再合并易熟配菜，边加热边观察水分、颜色和熟度。",
        f"{name} 出锅前确认中心熟透、咸淡合适，再按口味补少量调味。",
    ]


def build_cook_notes(difficulty: str, ingredients: list[str]) -> list[str]:
    notes: list[str] = []
    if difficulty:
        notes.append(f"难度：{difficulty}")
    if any(item in " ".join(ingredients) for item in ("猪", "牛肉", "羊肉", "鸡肉", "鸭肉", "鱼", "虾", "蟹")):
        notes.append("肉类、禽类和水产类食材需要确认中心完全熟透。")
    return notes


def cook_csv_row_to_option_payload(row: dict[str, str], row_index: int) -> dict[str, object] | None:
    name = row.get("name", "").strip()
    if not name:
        return None
    ingredients = split_cook_items(row.get("stuff", ""))
    difficulty = row.get("difficulty", "").strip()
    tags_raw = split_cook_items(row.get("tags", ""))
    methods = split_cook_items(row.get("methods", ""))
    tools_raw = split_cook_items(row.get("tools", ""))
    bv = clean_cook_bv(row.get("bv", ""))
    recipe = ExtractedRecipe(
        name=name,
        materials=ingredients,
        seasonings=[],
        steps=methods,
        notes=[difficulty, *tags_raw],
        book_title="YunYouJun/cook recipe.csv",
    )
    dish_types = cook_dish_types(recipe, tags_raw, methods)
    ingredient_keywords = extract_ingredient_keywords(recipe)
    specific_ingredients = cook_specific_ingredients_from_title(name)
    if specific_ingredients and "猪肉" in ingredient_keywords:
        ingredient_keywords = dedupe_strings(
            [
                *[item for item in ingredient_keywords if item != "猪肉"],
                *specific_ingredients,
            ],
            limit=18,
        )
    filter_ids = annotate_filter_ids(ingredient_keywords, dish_types, recipe)
    meals = infer_meals(recipe, dish_types, filter_ids)
    tool_ids = dedupe_strings(
        [item for item in (cook_tool_id(tool) for tool in tools_raw) if item]
    )
    if not tool_ids:
        tool_ids = infer_tools(recipe, dish_types)
    primary_tool = tool_ids[0] if tool_ids else "pot"
    subtitle_parts = [
        tools_raw[0] if tools_raw else "家常厨具",
        difficulty or "家常难度",
        *(tags_raw[:2] or ingredients[:2]),
    ]
    method_label = "、".join(methods) if methods else "家常做法"
    ingredient_label = "、".join(ingredients[:4]) if ingredients else "常见食材"
    tags = dedupe_strings(
        [
            *build_tags(meals, dish_types, filter_ids),
            difficulty,
            *tags_raw[:3],
            *methods[:2],
            *tools_raw[:2],
        ],
        limit=10,
    )
    attributes = {
        "meal": meals,
        "type": [item.split(":", 1)[1] for item in filter_ids if item.startswith("type:")],
        "profile": [item.split(":", 1)[1] for item in filter_ids if item.startswith("profile:")],
        "diet": [],
        "contains": [item.split(":", 1)[1] for item in filter_ids if item.startswith("contains:")],
        "ingredient": ingredient_keywords,
        "tool": tool_ids,
        "recipeSet": ["cook_csv"],
        "cookDifficulty": [difficulty] if difficulty else [],
        "cookTag": tags_raw,
        "cookMethod": methods,
        "cookTool": tools_raw,
        "cookBv": [bv] if bv else [],
        "cookStuff": ingredients,
    }
    normalized_name = normalize_name(name) or f"row_{row_index}"
    return {
        "id": f"cook_csv_{normalized_name}_{primary_tool}",
        "moduleId": "eat",
        "categoryId": meals[0] if meals else "lunch",
        "contextId": primary_tool,
        "contextIds": tool_ids,
        "titleZh": name,
        "titleEn": name,
        "subtitleZh": " · ".join(dedupe_strings(subtitle_parts, limit=4)),
        "subtitleEn": " · ".join(dedupe_strings(subtitle_parts, limit=4)),
        "detailsZh": f"{name} 以 {ingredient_label} 为主，适合用 {tools_raw[0] if tools_raw else '常用锅具'} 按 {method_label} 完成。",
        "detailsEn": f"{name} 以 {ingredient_label} 为主，适合用 {tools_raw[0] if tools_raw else '常用锅具'} 按 {method_label} 完成。",
        "materialsZh": ingredients,
        "materialsEn": ingredients,
        "stepsZh": build_cook_steps(name, ingredients, methods, tools_raw),
        "stepsEn": build_cook_steps(name, ingredients, methods, tools_raw),
        "notesZh": build_cook_notes(difficulty, ingredients),
        "notesEn": build_cook_notes(difficulty, ingredients),
        "tagsZh": tags,
        "tagsEn": tags,
        "attributes": attributes,
        "custom": False,
    }


def load_cook_csv_rows(
    cook_csv: Path | None,
    cook_csv_url: str,
    *,
    skip_cook_csv: bool,
) -> list[dict[str, str]]:
    if skip_cook_csv:
        return []
    if cook_csv is not None:
        text = cook_csv.read_text(encoding="utf-8-sig")
    else:
        request = urllib.request.Request(
            cook_csv_url,
            headers={"User-Agent": "vocabularySleep-recipe-generator/1.0"},
        )
        with urllib.request.urlopen(request, timeout=45) as response:
            text = response.read().decode("utf-8-sig")
    return [
        {str(key): str(value or "") for key, value in row.items() if key is not None}
        for row in csv.DictReader(text.splitlines())
    ]


def cook_csv_payloads(rows: list[dict[str, str]]) -> list[dict[str, object]]:
    payloads: list[dict[str, object]] = []
    seen: set[str] = set()
    for index, row in enumerate(rows, start=1):
        payload = cook_csv_row_to_option_payload(row, index)
        if payload is None:
            continue
        key = f"{payload['titleZh']}|{payload.get('contextId') or ''}"
        if key in seen:
            continue
        seen.add(key)
        payloads.append(payload)
    return payloads


def recipe_to_option_payload(recipe: ExtractedRecipe) -> dict[str, object]:
    dish_types = annotate_dish_types(recipe)
    ingredient_keywords = extract_ingredient_keywords(recipe)
    filter_ids = annotate_filter_ids(ingredient_keywords, dish_types, recipe)
    meals = infer_meals(recipe, dish_types, filter_ids)
    tools = infer_tools(recipe, dish_types)
    tags = build_tags(meals, dish_types, filter_ids)
    notes = build_notes(recipe, filter_ids, dish_types)
    attributes = {
        "meal": meals,
        "type": [item.split(":", 1)[1] for item in filter_ids if item.startswith("type:")],
        "profile": [item.split(":", 1)[1] for item in filter_ids if item.startswith("profile:")],
        "diet": [item.split(":", 1)[1] for item in filter_ids if item.startswith("diet:")],
        "contains": [item.split(":", 1)[1] for item in filter_ids if item.startswith("contains:")],
        "ingredient": ingredient_keywords,
    }
    return {
        "id": f"library_{normalize_name(recipe.name)}",
        "moduleId": "eat",
        "categoryId": meals[0],
        "contextId": tools[0],
        "contextIds": tools,
        "titleZh": recipe.name,
        "titleEn": recipe.name,
        "subtitleZh": build_subtitle(recipe, dish_types, tools),
        "subtitleEn": build_subtitle(recipe, dish_types, tools),
        "detailsZh": build_details(recipe, dish_types, filter_ids),
        "detailsEn": build_details(recipe, dish_types, filter_ids),
        "materialsZh": dedupe_strings([*recipe.materials, *recipe.seasonings], limit=48),
        "materialsEn": dedupe_strings([*recipe.materials, *recipe.seasonings], limit=48),
        "stepsZh": recipe.steps,
        "stepsEn": recipe.steps,
        "notesZh": notes,
        "notesEn": notes,
        "tagsZh": tags,
        "tagsEn": tags,
        "attributes": attributes,
        "custom": False,
    }


def build_dataset(
    source_dir: Path,
    *,
    cook_rows: list[dict[str, str]] | None = None,
) -> dict[str, object]:
    all_recipes: list[ExtractedRecipe] = []
    per_book_counts: Counter[str] = Counter()

    for epub_path in sorted(source_dir.glob("*.epub")):
        extracted = extract_from_epub(epub_path)
        per_book_counts[epub_path.name] = len(extracted)
        all_recipes.extend(extracted)

    deduped_recipes = merge_duplicate_recipes(all_recipes)
    book_payloads = [recipe_to_option_payload(recipe) for recipe in deduped_recipes]
    cook_payload_list = cook_csv_payloads(cook_rows or [])
    payloads = sorted(
        [*cook_payload_list, *book_payloads],
        key=lambda item: (
            item["categoryId"],
            item["contextId"],
            item["titleZh"],
        ),
    )

    return {
        "libraryId": LIBRARY_ID,
        "libraryVersion": "2026-04-25",
        "schemaId": SCHEMA_ID,
        "schemaVersion": SCHEMA_VERSION,
        "version": "2026-04-25",
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "referenceTitles": [],
        "stats": {
            "rawRecipeCount": len(all_recipes),
            "bookRecipeCount": len(book_payloads),
            "cookRecipeCount": len(cook_payload_list),
            "dedupedRecipeCount": len(payloads),
            "perBookCounts": dict(per_book_counts),
        },
        "recipes": payloads,
    }


def build_summary_manifest(dataset: dict[str, object]) -> dict[str, object]:
    recipes = dataset["recipes"]
    assert isinstance(recipes, list)
    return {
        "libraryId": dataset["libraryId"],
        "libraryVersion": dataset["libraryVersion"],
        "schemaId": dataset["schemaId"],
        "schemaVersion": dataset["schemaVersion"],
        "version": dataset["version"],
        "generatedAt": dataset["generatedAt"],
        "referenceTitles": dataset["referenceTitles"],
        "stats": dataset["stats"],
        "recipes": [
            {
                "id": recipe["id"],
                "moduleId": recipe["moduleId"],
                "categoryId": recipe["categoryId"],
                "contextId": recipe["contextId"],
                "contextIds": recipe["contextIds"],
                "titleZh": recipe["titleZh"],
                "titleEn": recipe["titleEn"],
                "subtitleZh": recipe["subtitleZh"],
                "subtitleEn": recipe["subtitleEn"],
                "tagsZh": recipe["tagsZh"],
                "tagsEn": recipe["tagsEn"],
                "attributes": recipe["attributes"],
            }
            for recipe in recipes
        ],
    }


def build_index_terms(recipe: dict[str, object]) -> list[tuple[str, str]]:
    terms: list[tuple[str, str]] = []
    category_id = str(recipe.get("categoryId", "")).strip()
    context_id = str(recipe.get("contextId", "")).strip()
    if category_id:
        terms.append(("meal", category_id))
    if context_id:
        terms.append(("tool", context_id))
    for tool_id in recipe.get("contextIds", []):
        normalized = str(tool_id).strip()
        if normalized:
            terms.append(("tool", normalized))
    attributes = recipe.get("attributes", {})
    if isinstance(attributes, dict):
        for key, values in attributes.items():
            if not isinstance(values, list):
                continue
            for value in values:
                normalized = str(value).strip()
                if normalized:
                    terms.append((str(key).strip(), normalized))
    return sorted(set(terms))


V2_BOOK_SET_ID = "book_library"
V2_COOK_SET_ID = "cook_csv"
V2_SCHEMA_SQL = Path(__file__).with_name("daily_choice_recipe_schema_v2.sql")

PORK_FAMILY_INGREDIENTS = {
    "排骨",
    "猪里脊",
    "猪油",
    "猪肝",
    "猪肚",
    "猪蹄",
    "猪耳",
    "猪腰",
    "火腿",
    "培根",
    "腊肉",
    "腊肠",
    "猪肉",
}
SEAFOOD_FAMILY_INGREDIENTS = {"鱼", "虾", "蟹", "贝类"}
NUT_FAMILY_INGREDIENTS = {"花生", "坚果"}


def stable_random_key(value: str) -> int:
    digest = hashlib.sha256(value.encode("utf-8")).digest()
    return int.from_bytes(digest[:8], "big") & 0x7FFFFFFFFFFFFFFF


def recipe_attribute_values(recipe: dict[str, object], key: str) -> list[str]:
    attributes = recipe.get("attributes", {})
    if not isinstance(attributes, dict):
        return []
    values = attributes.get(key, [])
    if not isinstance(values, list):
        return []
    return dedupe_strings([str(item) for item in values])


def recipe_primary_set_id(recipe: dict[str, object]) -> str:
    recipe_sets = set(recipe_attribute_values(recipe, "recipeSet"))
    recipe_id = str(recipe.get("id", ""))
    if "cook_csv" in recipe_sets or recipe_id.startswith("cook_csv_"):
        return V2_COOK_SET_ID
    return V2_BOOK_SET_ID


def recipe_origin(recipe: dict[str, object]) -> str:
    return "cook_csv" if recipe_primary_set_id(recipe) == V2_COOK_SET_ID else "book"


def recipe_sort_key(recipe: dict[str, object]) -> str:
    return (
        f"{recipe.get('categoryId', '')}|"
        f"{recipe.get('contextId') or ''}|"
        f"{recipe.get('titleZh', '')}"
    )


def recipe_search_text(recipe: dict[str, object], include_detail: bool = True) -> str:
    parts: list[str] = [
        str(recipe.get("id", "")).strip(),
        str(recipe.get("titleZh", "")).strip(),
        str(recipe.get("titleEn", "")).strip(),
        str(recipe.get("subtitleZh", "")).strip(),
        str(recipe.get("subtitleEn", "")).strip(),
        *[str(item).strip() for item in recipe.get("tagsZh", []) if str(item).strip()],
        *[str(item).strip() for item in recipe.get("tagsEn", []) if str(item).strip()],
    ]
    if include_detail:
        parts.extend(
            [
                *[str(item).strip() for item in recipe.get("materialsZh", []) if str(item).strip()],
                *[str(item).strip() for item in recipe.get("stepsZh", []) if str(item).strip()],
                *[str(item).strip() for item in recipe.get("notesZh", []) if str(item).strip()],
            ]
        )
    return " ".join(parts).strip().lower()


def recipe_quality_score_from_payload(recipe: dict[str, object]) -> int:
    return (
        len(recipe.get("materialsZh", [])) * 3
        + len(recipe.get("stepsZh", [])) * 4
        + len(recipe.get("notesZh", []))
        + len(recipe.get("tagsZh", []))
        + len(str(recipe.get("detailsZh", ""))) // 18
    )


def ingredient_family_value(token: str) -> str | None:
    if token in PORK_FAMILY_INGREDIENTS:
        return "猪肉"
    if token in SEAFOOD_FAMILY_INGREDIENTS:
        return "海鲜"
    if token in NUT_FAMILY_INGREDIENTS:
        return "坚果"
    return None


def write_sqlite_v2_export(
    cursor: sqlite3.Cursor,
    dataset: dict[str, object],
    *,
    create_schema: bool = True,
) -> None:
    if create_schema:
        cursor.executescript(V2_SCHEMA_SQL.read_text(encoding="utf-8"))
    cursor.execute("PRAGMA user_version = 2;")
    recipes = dataset["recipes"]
    assert isinstance(recipes, list)
    generated_at = str(dataset["generatedAt"])
    set_counts = Counter(
        recipe_primary_set_id(recipe)
        for recipe in recipes
        if isinstance(recipe, dict)
    )
    recipe_sets = (
        (
            V2_BOOK_SET_ID,
            "builtin",
            "内置书籍菜谱",
            "Built-in book recipes",
            "从本地做菜资料抽取的内置菜谱集",
            "Recipes extracted from the bundled cooking references",
            10,
        ),
        (
            V2_COOK_SET_ID,
            "builtin",
            "cook 菜谱",
            "cook recipes",
            "从 YunYouJun/cook recipe.csv 导入的菜谱集",
            "Recipes imported from YunYouJun/cook recipe.csv",
            20,
        ),
    )
    for set_id, set_kind, title_zh, title_en, desc_zh, desc_en, priority in recipe_sets:
        cursor.execute(
            """
            INSERT INTO daily_choice_recipe_sets (
              set_id, set_kind, title_zh, title_en, description_zh,
              description_en, library_version, priority, is_enabled,
              is_readonly, recipe_count, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 1, ?, ?, ?)
            """,
            (
                set_id,
                set_kind,
                title_zh,
                title_en,
                desc_zh,
                desc_en,
                str(dataset["libraryVersion"]),
                priority,
                set_counts.get(set_id, 0),
                generated_at,
                generated_at,
            ),
        )

    meta_entries = {
        "schema_id": "vocabulary_sleep.daily_choice.recipe_library.v2",
        "schema_version": "2",
        "compatible_v1_schema_version": str(dataset["schemaVersion"]),
        "library_id": str(dataset["libraryId"]),
        "library_version": str(dataset["libraryVersion"]),
        "generated_at": generated_at,
    }
    for key, value in meta_entries.items():
        cursor.execute(
            "INSERT INTO daily_choice_recipe_schema_meta (key, value) VALUES (?, ?)",
            (key, value),
        )

    for recipe in recipes:
        assert isinstance(recipe, dict)
        recipe_id = str(recipe["id"])
        set_id = recipe_primary_set_id(recipe)
        attributes = recipe.get("attributes", {})
        if not isinstance(attributes, dict):
            attributes = {}
        tags_zh = recipe.get("tagsZh", [])
        tags_en = recipe.get("tagsEn", [])
        materials_zh = recipe.get("materialsZh", [])
        materials_en = recipe.get("materialsEn", [])
        steps_zh = recipe.get("stepsZh", [])
        steps_en = recipe.get("stepsEn", [])
        notes_zh = recipe.get("notesZh", [])
        notes_en = recipe.get("notesEn", [])
        primary_meal = str(recipe.get("categoryId", "") or "all")
        cursor.execute(
            """
            INSERT INTO daily_choice_recipes (
              recipe_id, primary_set_id, origin, title_zh, title_en,
              normalized_title, primary_meal_id, primary_tool_id, sort_key,
              random_key, quality_score, status, is_available, created_at,
              updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 1, ?, ?)
            """,
            (
                recipe_id,
                set_id,
                recipe_origin(recipe),
                str(recipe["titleZh"]),
                str(recipe["titleEn"]),
                normalize_name(str(recipe["titleZh"])),
                primary_meal,
                recipe.get("contextId"),
                recipe_sort_key(recipe),
                stable_random_key(recipe_id),
                recipe_quality_score_from_payload(recipe),
                generated_at,
                generated_at,
            ),
        )
        cursor.execute(
            """
            INSERT INTO daily_choice_recipe_summaries (
              recipe_id, subtitle_zh, subtitle_en, tags_zh_json,
              tags_en_json, summary_attributes_json, display_badges_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                recipe_id,
                str(recipe["subtitleZh"]),
                str(recipe["subtitleEn"]),
                json.dumps(tags_zh, ensure_ascii=False),
                json.dumps(tags_en, ensure_ascii=False),
                json.dumps(attributes, ensure_ascii=False),
                json.dumps(list(tags_zh)[:4], ensure_ascii=False),
            ),
        )
        cursor.execute(
            """
            INSERT INTO daily_choice_recipe_details (
              recipe_id, details_zh, details_en, materials_zh_json,
              materials_en_json, steps_zh_json, steps_en_json, notes_zh_json,
              notes_en_json, raw_payload_json
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                recipe_id,
                str(recipe["detailsZh"]),
                str(recipe["detailsEn"]),
                json.dumps(materials_zh, ensure_ascii=False),
                json.dumps(materials_en, ensure_ascii=False),
                json.dumps(steps_zh, ensure_ascii=False),
                json.dumps(steps_en, ensure_ascii=False),
                json.dumps(notes_zh, ensure_ascii=False),
                json.dumps(notes_en, ensure_ascii=False),
                json.dumps(recipe, ensure_ascii=False),
            ),
        )

        for index, material in enumerate(materials_zh):
            material_text = str(material).strip()
            if not material_text:
                continue
            normalized = cleaned_ingredient_text(material_text) or clean_output_text(
                material_text
            )
            cursor.execute(
                """
                INSERT OR IGNORE INTO daily_choice_recipe_materials (
                  recipe_id, material_index, material_text, normalized_text,
                  material_role, amount_text
                ) VALUES (?, ?, ?, ?, 'ingredient', '')
                """,
                (recipe_id, index, material_text, normalized),
            )
            if 1 < len(normalized) <= 16:
                cursor.execute(
                    """
                    INSERT OR IGNORE INTO daily_choice_recipe_ingredient_index (
                      recipe_id, set_id, token_kind, token_value, display_text,
                      source_text, match_level, is_primary, source_kind
                    ) VALUES (?, ?, 'raw', ?, ?, ?, 100, 0, 'source')
                    """,
                    (recipe_id, set_id, normalized, normalized, material_text),
                )

        for index, step in enumerate(steps_zh):
            step_text = str(step).strip()
            if not step_text:
                continue
            cursor.execute(
                """
                INSERT OR IGNORE INTO daily_choice_recipe_steps (
                  recipe_id, step_index, step_text, normalized_text
                ) VALUES (?, ?, ?, ?)
                """,
                (recipe_id, index, step_text, clean_output_text(step_text).lower()),
            )

        for term_group, term_value in build_index_terms(recipe):
            cursor.execute(
                """
                INSERT OR IGNORE INTO daily_choice_recipe_filter_index (
                  recipe_id, set_id, term_group, term_value, confidence,
                  source_kind
                ) VALUES (?, ?, ?, ?, 100, 'generated')
                """,
                (recipe_id, set_id, term_group, term_value),
            )

        for index, token in enumerate(recipe_attribute_values(recipe, "ingredient")):
            cursor.execute(
                """
                INSERT OR IGNORE INTO daily_choice_recipe_ingredient_index (
                  recipe_id, set_id, token_kind, token_value, display_text,
                  source_text, match_level, is_primary, source_kind
                ) VALUES (?, ?, 'canonical', ?, ?, '', 90, ?, 'generated')
                """,
                (recipe_id, set_id, token, token, 1 if index == 0 else 0),
            )
            family = ingredient_family_value(token)
            if family is not None:
                cursor.execute(
                    """
                    INSERT OR IGNORE INTO daily_choice_recipe_ingredient_index (
                      recipe_id, set_id, token_kind, token_value, display_text,
                      source_text, match_level, is_primary, source_kind
                    ) VALUES (?, ?, 'family', ?, ?, ?, 45, 0, 'generated')
                    """,
                    (recipe_id, set_id, family, family, token),
                )

        cursor.execute(
            """
            INSERT INTO daily_choice_recipe_search_text (
              recipe_id, search_title, search_materials, search_tags,
              search_all
            ) VALUES (?, ?, ?, ?, ?)
            """,
            (
                recipe_id,
                recipe_search_text(recipe, include_detail=False),
                " ".join(str(item).strip() for item in materials_zh).lower(),
                " ".join(str(item).strip() for item in tags_zh).lower(),
                recipe_search_text(recipe, include_detail=True),
            ),
        )

    for set_id in (V2_BOOK_SET_ID, V2_COOK_SET_ID):
        active_count = cursor.execute(
            """
            SELECT COUNT(*)
            FROM daily_choice_recipes
            WHERE primary_set_id = ? AND status = 'active' AND is_available = 1
            """,
            (set_id,),
        ).fetchone()[0]
        ingredient_count = cursor.execute(
            "SELECT COUNT(*) FROM daily_choice_recipe_ingredient_index WHERE set_id = ?",
            (set_id,),
        ).fetchone()[0]
        filter_count = cursor.execute(
            "SELECT COUNT(*) FROM daily_choice_recipe_filter_index WHERE set_id = ?",
            (set_id,),
        ).fetchone()[0]
        cursor.execute(
            """
            INSERT INTO daily_choice_recipe_set_stats (
              set_id, active_recipe_count, disabled_recipe_count,
              ingredient_term_count, filter_term_count, updated_at
            ) VALUES (?, ?, 0, ?, ?, ?)
            """,
            (set_id, active_count, ingredient_count, filter_count, generated_at),
        )


def write_json(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)


def write_sqlite_export(
    path: Path,
    dataset: dict[str, object],
    *,
    sqlite_mode: str = "v2",
) -> None:
    if sqlite_mode not in {"v2", "v1-v2"}:
        raise ValueError(f"Unsupported sqlite export mode: {sqlite_mode}")
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    connection = sqlite3.connect(path)
    try:
        cursor = connection.cursor()
        if sqlite_mode == "v2":
            cursor.execute("PRAGMA journal_mode = DELETE;")
            cursor.execute("PRAGMA synchronous = OFF;")
            write_sqlite_v2_export(cursor, dataset)
            connection.commit()
            return
        cursor.executescript(
            """
            PRAGMA journal_mode = DELETE;
            PRAGMA synchronous = OFF;
            CREATE TABLE daily_choice_eat_recipe_summaries (
              id TEXT PRIMARY KEY,
              module_id TEXT NOT NULL,
              category_id TEXT NOT NULL,
              context_id TEXT,
              context_ids_json TEXT NOT NULL,
              title_zh TEXT NOT NULL,
              title_en TEXT NOT NULL,
              subtitle_zh TEXT NOT NULL,
              subtitle_en TEXT NOT NULL,
              tags_zh_json TEXT NOT NULL,
              tags_en_json TEXT NOT NULL,
              attributes_json TEXT NOT NULL,
              source_label TEXT,
              source_url TEXT,
              search_title TEXT NOT NULL,
              sort_key TEXT NOT NULL
            );
            CREATE TABLE daily_choice_eat_recipe_details (
              recipe_id TEXT PRIMARY KEY,
              details_zh TEXT NOT NULL,
              details_en TEXT NOT NULL,
              materials_zh_json TEXT NOT NULL,
              materials_en_json TEXT NOT NULL,
              steps_zh_json TEXT NOT NULL,
              steps_en_json TEXT NOT NULL,
              notes_zh_json TEXT NOT NULL,
              notes_en_json TEXT NOT NULL,
              references_json TEXT NOT NULL
            );
            CREATE TABLE daily_choice_eat_recipe_index_terms (
              recipe_id TEXT NOT NULL,
              term_group TEXT NOT NULL,
              term_value TEXT NOT NULL,
              PRIMARY KEY (recipe_id, term_group, term_value)
            );
            CREATE TABLE daily_choice_eat_recipe_meta (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            );
            CREATE INDEX idx_daily_choice_eat_recipe_category
              ON daily_choice_eat_recipe_summaries(category_id, id);
            CREATE INDEX idx_daily_choice_eat_recipe_context
              ON daily_choice_eat_recipe_summaries(context_id, id);
            CREATE INDEX idx_daily_choice_eat_recipe_search_title
              ON daily_choice_eat_recipe_summaries(search_title);
            CREATE INDEX idx_daily_choice_eat_recipe_sort
              ON daily_choice_eat_recipe_summaries(sort_key, id);
            CREATE INDEX idx_daily_choice_eat_recipe_index_terms
              ON daily_choice_eat_recipe_index_terms(term_group, term_value, recipe_id);
            """
        )

        recipes = dataset["recipes"]
        assert isinstance(recipes, list)
        for recipe in recipes:
            assert isinstance(recipe, dict)
            tags_zh = recipe.get("tagsZh", [])
            tags_en = recipe.get("tagsEn", [])
            attributes = recipe.get("attributes", {})
            search_title = " ".join(
                [
                    str(recipe.get("id", "")).strip(),
                    str(recipe.get("titleZh", "")).strip(),
                    str(recipe.get("titleEn", "")).strip(),
                    str(recipe.get("subtitleZh", "")).strip(),
                    str(recipe.get("subtitleEn", "")).strip(),
                    *[str(item).strip() for item in tags_zh if str(item).strip()],
                    *[str(item).strip() for item in tags_en if str(item).strip()],
                ]
            ).strip().lower()
            cursor.execute(
                """
                INSERT INTO daily_choice_eat_recipe_summaries (
                  id, module_id, category_id, context_id, context_ids_json,
                  title_zh, title_en, subtitle_zh, subtitle_en,
                  tags_zh_json, tags_en_json, attributes_json,
                  source_label, source_url, search_title, sort_key
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    recipe["id"],
                    recipe["moduleId"],
                    recipe["categoryId"],
                    recipe.get("contextId"),
                    json.dumps(recipe.get("contextIds", []), ensure_ascii=False),
                    recipe["titleZh"],
                    recipe["titleEn"],
                    recipe["subtitleZh"],
                    recipe["subtitleEn"],
                    json.dumps(tags_zh, ensure_ascii=False),
                    json.dumps(tags_en, ensure_ascii=False),
                    json.dumps(attributes, ensure_ascii=False),
                    recipe.get("sourceLabel"),
                    recipe.get("sourceUrl"),
                    search_title,
                    f"{recipe['categoryId']}|{recipe.get('contextId') or ''}|{recipe['titleZh']}",
                ),
            )
            cursor.execute(
                """
                INSERT INTO daily_choice_eat_recipe_details (
                  recipe_id, details_zh, details_en, materials_zh_json, materials_en_json,
                  steps_zh_json, steps_en_json, notes_zh_json, notes_en_json, references_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    recipe["id"],
                    recipe["detailsZh"],
                    recipe["detailsEn"],
                    json.dumps(recipe.get("materialsZh", []), ensure_ascii=False),
                    json.dumps(recipe.get("materialsEn", []), ensure_ascii=False),
                    json.dumps(recipe.get("stepsZh", []), ensure_ascii=False),
                    json.dumps(recipe.get("stepsEn", []), ensure_ascii=False),
                    json.dumps(recipe.get("notesZh", []), ensure_ascii=False),
                    json.dumps(recipe.get("notesEn", []), ensure_ascii=False),
                    json.dumps(recipe.get("references", []), ensure_ascii=False),
                ),
            )
            for term_group, term_value in build_index_terms(recipe):
                cursor.execute(
                    """
                    INSERT OR IGNORE INTO daily_choice_eat_recipe_index_terms (
                      recipe_id, term_group, term_value
                    ) VALUES (?, ?, ?)
                    """,
                    (recipe["id"], term_group, term_value),
                )

        meta_entries = {
            "library_id": str(dataset["libraryId"]),
            "library_version": str(dataset["libraryVersion"]),
            "schema_id": str(dataset["schemaId"]),
            "schema_version": str(dataset["schemaVersion"]),
            "reference_titles_json": json.dumps(dataset["referenceTitles"], ensure_ascii=False),
            "local_library_count": str(dataset["stats"].get("bookRecipeCount", len(recipes))),
            "cook_recipe_count": str(dataset["stats"].get("cookRecipeCount", 0)),
            "install_source": "bundle",
            "installed_at": str(dataset["generatedAt"]),
            "updated_at": str(dataset["generatedAt"]),
            "error_message": "",
            "stats_json": json.dumps(dataset["stats"], ensure_ascii=False),
        }
        for key, value in meta_entries.items():
            cursor.execute(
                "INSERT INTO daily_choice_eat_recipe_meta (key, value) VALUES (?, ?)",
                (key, value),
            )
        write_sqlite_v2_export(cursor, dataset)
        connection.commit()
    finally:
        connection.close()


def write_export_bundle(
    export_dir: Path,
    dataset: dict[str, object],
    *,
    sqlite_mode: str,
) -> None:
    export_dir.mkdir(parents=True, exist_ok=True)
    write_json(export_dir / "daily_choice_recipe_library.json", dataset)
    write_json(
        export_dir / "daily_choice_recipe_library_summary.json",
        build_summary_manifest(dataset),
    )
    write_sqlite_export(
        export_dir / "daily_choice_recipe_library.db",
        dataset,
        sqlite_mode=sqlite_mode,
    )


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_source = Path(r"D:\vocabularySleep-resources\做菜")
    default_output = (
        script_path.parent.parent
        / "assets"
        / "toolbox"
        / "daily_choice"
        / "recipe_library.json"
    )
    default_export_dir = Path(r"D:\vocabularySleep-resources\cook_data")
    parser = argparse.ArgumentParser(
        description="Extract and normalize the local daily-choice recipe library.",
    )
    parser.add_argument(
        "--source-dir",
        type=Path,
        default=default_source,
        help="Directory that contains local EPUB cooking resources.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=default_output,
        help="JSON output path for the generated recipe library.",
    )
    parser.add_argument(
        "--export-dir",
        type=Path,
        default=default_export_dir,
        help="Directory for externalized JSON summary/full and SQLite exports.",
    )
    parser.add_argument(
        "--cook-csv",
        type=Path,
        help="Optional local YunYouJun/cook recipe.csv path.",
    )
    parser.add_argument(
        "--cook-csv-url",
        default=DEFAULT_COOK_CSV_URL,
        help="YunYouJun/cook recipe.csv URL used when --cook-csv is omitted.",
    )
    parser.add_argument(
        "--skip-cook-csv",
        action="store_true",
        help="Skip importing YunYouJun/cook recipe.csv rows.",
    )
    parser.add_argument(
        "--sqlite-mode",
        choices=("v2", "v1-v2"),
        default="v2",
        help=(
            "SQLite export mode. v2 writes only the PLAN_070 v2 schema; "
            "v1-v2 also writes legacy runtime compatibility tables."
        ),
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    cook_rows = load_cook_csv_rows(
        args.cook_csv,
        args.cook_csv_url,
        skip_cook_csv=args.skip_cook_csv,
    )
    dataset = build_dataset(args.source_dir, cook_rows=cook_rows)
    write_json(args.output, dataset)
    write_export_bundle(args.export_dir, dataset, sqlite_mode=args.sqlite_mode)
    print(
        f"Generated {dataset['stats']['dedupedRecipeCount']} recipes "
        f"from {dataset['stats']['rawRecipeCount']} extracted entries."
    )
    print(
        f"Book recipes: {dataset['stats']['bookRecipeCount']}; "
        f"cook CSV recipes: {dataset['stats']['cookRecipeCount']}."
    )
    print(f"Output: {args.output}")
    print(f"Export directory: {args.export_dir}")


if __name__ == "__main__":
    main()
