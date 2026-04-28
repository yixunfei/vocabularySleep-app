#!/usr/bin/env python3
"""Generate the Daily Choice wear library JSON and SQLite database."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sqlite3
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


DEFAULT_SOURCE_DIR = Path(r"D:\vocabularySleep-resources\穿什么")
DEFAULT_OUTPUT_DIR = Path(r"D:\vocabularySleep-resources\穿什么-数据")

LIBRARY_ID = "toolbox_daily_choice_wear_library"
SCHEMA_ID = "vocabulary_sleep.daily_choice.wear_library"
SCHEMA_VERSION = 1


TEMPERATURES = [
    ("freezing", "严寒", "Freezing", "0°C 以下", "Below 0°C"),
    ("cold", "寒冷", "Cold", "-5°C 到 10°C", "-5°C to 10°C"),
    ("cool", "凉爽", "Cool", "10°C 到 15°C", "10°C to 15°C"),
    ("mild", "温和", "Mild", "15°C 到 25°C", "15°C to 25°C"),
    ("warm", "微热", "Warm", "25°C 到 30°C", "25°C to 30°C"),
    ("hot", "炎热", "Hot", "30°C 到 35°C", "30°C to 35°C"),
    ("extreme_hot", "酷暑", "Extreme heat", "35°C 以上", "Above 35°C"),
]

SCENES = [
    ("commute", "通勤", "Commute", "得体、耐坐、易打理", "Polished and practical"),
    ("casual", "日常", "Casual", "舒服、松弛、不费力", "Comfortable and easy"),
    ("business", "正式", "Business", "轮廓清楚，颜色克制", "Structured and restrained"),
    ("date", "约会", "Date", "柔和、有记忆点", "Soft with one highlight"),
    ("exercise", "运动", "Exercise", "透气、可活动", "Breathable and mobile"),
    ("rain", "雨天", "Rain", "防滑、快干、轻外层", "Grippy, quick-dry, layered"),
]

TRAIT_GROUPS = [
    (
        "gender",
        "性别参考",
        "Gender reference",
        "只作为版型和单品方向参考，可按自己的穿着习惯自由选择",
        "A fit and styling reference only; choose by your own wardrobe habits",
        [
            ("gender_neutral", "不限定", "Open"),
            ("womenswear", "女装方向", "Womenswear"),
            ("menswear", "男装方向", "Menswear"),
        ],
    ),
    (
        "age",
        "年龄阶段",
        "Age stage",
        "按生活阶段和穿着语气筛选，不把年龄当成硬限制",
        "Filter by life stage and styling tone, not a hard age rule",
        [
            ("all_age", "通用不挑龄", "Age-flexible"),
            ("youth", "学生 / 青春", "Youth"),
            ("young_adult", "年轻通勤", "Young adult"),
            ("adult", "成熟日常", "Adult"),
            ("mature", "稳重质感", "Mature"),
        ],
    ),
    (
        "style",
        "风格",
        "Style",
        "这个搭配整体给人的气质方向",
        "How the outfit reads at a glance",
        [
            ("minimal", "极简基础", "Minimal"),
            ("polished", "利落通勤", "Polished"),
            ("soft", "温柔轻熟", "Soft"),
            ("relaxed", "松弛休闲", "Relaxed"),
            ("sporty", "运动机能", "Sporty"),
            ("retro", "复古文艺", "Retro"),
            ("street", "街头潮感", "Street"),
            ("outdoor", "户外防护", "Outdoor"),
        ],
    ),
    (
        "silhouette",
        "版型",
        "Silhouette",
        "记录这套更偏修身、直筒、宽松还是层次",
        "Capture the shape and proportion",
        [
            ("clean", "干净利落", "Clean"),
            ("waist_defined", "强调腰线", "Waist-defined"),
            ("straight", "直筒修长", "Straight"),
            ("relaxed", "宽松舒展", "Relaxed fit"),
            ("drapey", "垂感流动", "Drapey"),
            ("layered", "叠穿层次", "Layered"),
        ],
    ),
    (
        "key_piece",
        "样式类型",
        "Key pieces",
        "用来描述这套搭配最重要的核心单品",
        "The main clothing types carrying the look",
        [
            ("shirt", "衬衫 / Polo", "Shirt / Polo"),
            ("knit", "针织 / 毛衣", "Knit"),
            ("tailoring", "西装 / 西裤", "Tailoring"),
            ("coat", "外套 / 大衣", "Outerwear"),
            ("dress_skirt", "裙装 / 连衣裙", "Dress / Skirt"),
            ("trousers", "裤装主导", "Trousers"),
            ("shorts", "短裤 / 清凉下装", "Shorts"),
            ("athleisure", "运动套组", "Athleisure"),
        ],
    ),
    (
        "material",
        "面料与触感",
        "Fabric",
        "帮助你记住这套依赖的材质关键词",
        "Track the fabric and touch that define the outfit",
        [
            ("wool", "羊毛 / 呢料", "Wool"),
            ("knit", "针织感", "Knit texture"),
            ("cotton_linen", "棉麻透气", "Cotton-linen"),
            ("tailoring_fabric", "挺括西装料", "Tailoring fabric"),
            ("quick_dry", "速干凉感", "Quick-dry"),
            ("waterproof", "防水防泼", "Waterproof"),
            ("denim", "牛仔 / 灯芯绒", "Denim / corduroy"),
            ("soft_sheen", "柔软 / 光泽", "Soft / sheen"),
        ],
    ),
    (
        "highlight",
        "亮点",
        "Highlight",
        "这套最值得被记住的点",
        "The finishing note worth remembering",
        [
            ("clean_color", "配色克制", "Clean palette"),
            ("color_accent", "颜色提气", "Color accent"),
            ("texture", "材质层次", "Texture contrast"),
            ("proportion", "比例优化", "Proportion"),
            ("accessory", "配饰收口", "Accessory finish"),
            ("weather_protection", "天气防护", "Weather protection"),
            ("sun_protection", "防晒降温", "Sun protection"),
            ("shoe_anchor", "鞋履定调", "Shoe anchor"),
        ],
    ),
]

TEMP_TITLE = {item[0]: item[1] for item in TEMPERATURES}
SCENE_TITLE = {item[0]: item[1] for item in SCENES}
TRAIT_TITLE = {
    group_id: {option_id: title_zh for option_id, title_zh, _ in options}
    for group_id, *_rest, options in TRAIT_GROUPS
}


GUIDE_MODULES = [
    {
        "id": "wardrobe_first",
        "titleZh": "先从自己的衣柜开始",
        "titleEn": "Start from your own wardrobe",
        "subtitleZh": "内置数据是参考，真正稳定的是你拥有并愿意反复穿的组合",
        "subtitleEn": "Built-ins are references; your repeatable outfits matter most",
        "entries": [
            {
                "titleZh": "把常穿组合录入，而不是追求一次性惊艳",
                "titleEn": "Save repeatable outfits, not one-off drama",
                "bodyZh": "先记录你真实拥有、穿着舒服、已经验证过的搭配。能被重复使用的组合，才会让随机结果越来越贴近你的生活。",
                "bodyEn": "Record outfits you own, feel good in, and have already tested. Repeatable combinations make random picks useful.",
            },
            {
                "titleZh": "没有同款时，用颜色、版型和面料替代",
                "titleEn": "Substitute by color, shape, and fabric",
                "bodyZh": "内置搭配不要求照抄。找不到同款时，用相近颜色、相近松紧和相近厚薄替代，比追求完全一致更现实。",
                "bodyEn": "Built-ins are not scripts. Substitute by color, fit, and fabric weight instead of chasing exact pieces.",
            },
        ],
    },
    {
        "id": "fit_weather_scene",
        "titleZh": "先解决体感和场景",
        "titleEn": "Weather and scene first",
        "subtitleZh": "好看的前提是能走、能坐、能应对当天温差",
        "subtitleEn": "A good outfit still needs to move, sit, and handle the day",
        "entries": [
            {
                "titleZh": "温度看体感，不只看数字",
                "titleEn": "Read feels-like temperature",
                "bodyZh": "冷天看风、雨和昼夜温差，热天看防晒、透气和空调房。穿搭记录里把这些条件写清楚，之后筛选会更准。",
                "bodyEn": "For cold days, read wind, rain, and daily swing. For hot days, read sun, ventilation, and air conditioning.",
            },
            {
                "titleZh": "场景先定正式度，再定亮点",
                "titleEn": "Set formality before accents",
                "bodyZh": "通勤、正式、约会、运动和雨天各有第一优先级。先把正式度和行动便利定住，再用颜色、配饰或材质做一点记忆点。",
                "bodyEn": "Commute, business, date, exercise, and rain each have a first priority. Solve formality and mobility before accents.",
            },
        ],
    },
    {
        "id": "gender_age_reference",
        "titleZh": "性别和年龄只是参考维度",
        "titleEn": "Gender and age are reference dimensions",
        "subtitleZh": "它们帮助筛选版型和语气，不替你规定能穿什么",
        "subtitleEn": "They help filter shape and tone; they do not decide what you may wear",
        "entries": [
            {
                "titleZh": "按自己的穿着习惯选择",
                "titleEn": "Choose by your own habits",
                "bodyZh": "性别参考更像单品和剪裁方向，年龄阶段更像生活语气。它们都不是规则；如果一套适合你，就可以保存到自己的衣柜。",
                "bodyEn": "Gender reference describes pieces and cuts; age stage describes tone. Neither is a rule.",
            }
        ],
    },
]


def slugify(text: str) -> str:
    mapping = {
        "女士": "women",
        "男士": "men",
        "春季": "spring",
        "夏季": "summer",
        "秋季": "autumn",
        "冬季": "winter",
        "职场": "work",
        "休闲": "casual",
        "正式": "formal",
        "极简": "minimal",
        "甜美": "sweet",
        "优雅": "elegant",
        "经典商务": "classic_business",
        "休闲绅士": "smart_casual",
        "约会": "date",
    }
    for key, value in mapping.items():
        if key in text:
            return value
    return re.sub(r"\W+", "_", text.lower()).strip("_") or "section"


def split_table_row(line: str) -> list[str] | None:
    if not re.match(r"^\|\s*\d+\s*\|", line):
        return None
    cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
    if len(cells) < 5:
        return None
    return cells


def parse_temperature_range(raw: str) -> tuple[int, int] | None:
    normalized = raw.replace("—", "-").replace("–", "-")
    matches = re.findall(r"(?<!\d)-?\d+", normalized)
    if len(matches) >= 2:
        first, second = int(matches[0]), int(matches[1])
        return (min(first, second), max(first, second))
    if len(matches) == 1:
        value = int(matches[0])
        return (value, value)
    return None


def temperature_id(raw: str) -> str:
    temp_range = parse_temperature_range(raw)
    if temp_range is None:
        return "mild"
    low, high = temp_range
    avg = (low + high) / 2
    if high <= 0 or avg < 0:
        return "freezing"
    if avg < 8:
        return "cold"
    if avg < 15:
        return "cool"
    if avg < 25:
        return "mild"
    if avg < 30:
        return "warm"
    if avg < 35:
        return "hot"
    return "extreme_hot"


def infer_gender(section: str, outfit: str) -> str:
    if "【女】" in outfit or "女士" in section:
        return "womenswear"
    if "【男】" in outfit or "男士" in section:
        return "menswear"
    return "gender_neutral"


def infer_scene(section: str, outfit: str, style: str) -> str:
    text = f"{section} {outfit} {style}"
    if any(word in text for word in ["雨", "防水", "防泼", "壳层", "雨靴"]):
        return "rain"
    if any(word in text for word in ["运动", "跑", "训练", "瑜伽", "健身", "速干", "Athleisure"]):
        return "exercise"
    if "正式" in section or any(word in text for word in ["礼服", "晚宴", "Black Tie", "西装套装", "商务正式", "会议"]):
        return "business"
    if "职场" in section or any(word in text for word in ["通勤", "办公", "客户", "职场", "商务休闲"]):
        return "commute"
    if "约会" in section or any(word in text for word in ["约会", "浪漫", "甜美", "晚间"]):
        return "date"
    return "casual"


def infer_age(outfit: str, style: str, scene_id: str) -> str:
    text = f"{outfit} {style}"
    if any(word in text for word in ["学生", "学院", "少女", "青春", "校园"]):
        return "youth"
    if any(word in text for word in ["轻熟", "甜酷", "潮流", "街头", "活力", "约会"]):
        return "young_adult"
    if scene_id in {"commute", "business"} or any(word in text for word in ["职场", "商务", "通勤", "优雅", "知性"]):
        return "adult"
    if any(word in text for word in ["成熟", "稳重", "高级", "经典", "绅士", "大气", "质感"]):
        return "mature"
    return "all_age"


KEYWORDS = {
    "style": [
        ("minimal", ["基础", "极简", "简约", "克制", "干净", "同色"]),
        ("polished", ["通勤", "职场", "商务", "正式", "西装", "会议", "利落", "知性"]),
        ("soft", ["温柔", "甜美", "柔和", "真丝", "缎面", "浪漫", "约会"]),
        ("relaxed", ["休闲", "周末", "松弛", "舒适", "日常", "慵懒", "度假"]),
        ("sporty", ["运动", "跑", "训练", "速干", "弹力", "Athleisure"]),
        ("retro", ["复古", "格纹", "条纹", "灯芯绒", "牛角扣", "学院"]),
        ("street", ["街头", "工装", "卫衣", "潮", "板鞋", "机车", "马丁"]),
        ("outdoor", ["户外", "防水", "防泼", "防风", "派克", "壳层", "防晒"]),
    ],
    "silhouette": [
        ("clean", ["利落", "修身", "烟管", "尖头", "干练"]),
        ("waist_defined", ["腰带", "高腰", "收腰", "腰线", "裹身"]),
        ("straight", ["直筒", "锥形", "修长", "九分", "西裤"]),
        ("relaxed", ["宽松", "阔腿", "舒展", "量感", "oversize"]),
        ("drapey", ["垂感", "流动", "缎面", "真丝", "阔腿"]),
        ("layered", ["叠穿", "层次", "开衫", "外套", "马甲", "风衣", "大衣"]),
    ],
    "key_piece": [
        ("shirt", ["衬衫", "Polo", "牛津"]),
        ("knit", ["针织", "毛衣", "开衫", "高领", "羊绒"]),
        ("tailoring", ["西装", "西裤", "套装", "Blazer", "礼服"]),
        ("coat", ["外套", "大衣", "风衣", "羽绒", "派克", "夹克", "马甲"]),
        ("dress_skirt", ["裙", "连衣裙", "半裙", "小黑裙"]),
        ("trousers", ["裤", "牛仔", "阔腿", "Chino", "工装裤"]),
        ("shorts", ["短裤", "热裤"]),
        ("athleisure", ["运动", "跑鞋", "卫衣", "训练", "leggings", "背心"]),
    ],
    "material": [
        ("wool", ["羊毛", "羊绒", "呢", "羽绒", "法兰绒"]),
        ("knit", ["针织", "毛衣", "开衫", "高领"]),
        ("cotton_linen", ["棉", "亚麻", "棉麻", "泡泡纱"]),
        ("tailoring_fabric", ["西装", "挺括", "羊毛西装", "烟管"]),
        ("quick_dry", ["速干", "凉感", "透气", "莫代尔", "天丝"]),
        ("waterproof", ["防水", "防泼", "雨", "壳层"]),
        ("denim", ["牛仔", "灯芯绒"]),
        ("soft_sheen", ["柔软", "真丝", "缎面", "光泽", "垂感", "蕾丝"]),
    ],
    "highlight": [
        ("clean_color", ["克制", "同色", "极简", "干净", "黑白", "大地色"]),
        ("color_accent", ["亮色", "提气", "红色", "黄色", "粉色", "紫色", "绿色"]),
        ("texture", ["叠穿", "层次", "材质", "针织", "格纹", "灯芯绒"]),
        ("proportion", ["腰带", "高腰", "腰线", "短款", "九分"]),
        ("accessory", ["围巾", "耳环", "项链", "腕表", "小包", "帽", "丝巾", "腰带"]),
        ("weather_protection", ["防水", "防泼", "防风", "雨", "壳层", "户外"]),
        ("sun_protection", ["防晒", "遮阳", "草帽", "太阳镜"]),
        ("shoe_anchor", ["乐福", "短靴", "皮鞋", "凉鞋", "跑鞋", "牛津鞋", "德比鞋", "帆布鞋"]),
    ],
}


def infer_traits(outfit: str, style: str, scene_id: str, gender_id: str, age_id: str) -> dict[str, list[str]]:
    text = f"{outfit} {style}"
    traits: dict[str, list[str]] = {
        "gender": [gender_id],
        "age": [age_id],
    }
    for group_id, rules in KEYWORDS.items():
        values: list[str] = []
        for option_id, words in rules:
            if any(word.lower() in text.lower() for word in words):
                values.append(option_id)
        if not values:
            if group_id == "style":
                values = ["polished"] if scene_id in {"commute", "business"} else ["relaxed"]
            elif group_id == "silhouette":
                values = ["clean"] if scene_id in {"commute", "business"} else ["relaxed"]
            elif group_id == "key_piece":
                values = ["trousers"]
            elif group_id == "material":
                values = ["cotton_linen"] if scene_id != "business" else ["tailoring_fabric"]
            elif group_id == "highlight":
                values = ["clean_color"]
        traits[group_id] = sorted(set(values))[:4]
    return traits


def clean_outfit(outfit: str) -> str:
    return re.sub(r"^【[男女]】", "", outfit).strip()


def option_id(section_slug: str, row_no: str, used: set[str]) -> str:
    base = f"wear_{section_slug}_{int(row_no):03d}"
    candidate = base
    suffix = 2
    while candidate in used:
        candidate = f"{base}_{suffix}"
        suffix += 1
    used.add(candidate)
    return candidate


def zh_tags(option: dict[str, Any]) -> list[str]:
    tags = ["穿搭", TEMP_TITLE[option["categoryId"]], SCENE_TITLE[option["contextId"]]]
    for group_id, values in option["attributes"].items():
        for value in values:
            label = TRAIT_TITLE.get(group_id, {}).get(value)
            if label:
                tags.append(label)
    return list(dict.fromkeys(tags))


def build_option(
    *,
    option_id_value: str,
    outfit: str,
    temp_raw: str,
    style_raw: str,
    section: str,
    scene_id: str | None = None,
    supplement_note: str | None = None,
) -> dict[str, Any]:
    cleaned = clean_outfit(outfit)
    category_id = temperature_id(temp_raw)
    resolved_scene = scene_id or infer_scene(section, cleaned, style_raw)
    gender_id = infer_gender(section, outfit)
    age_id = infer_age(cleaned, style_raw, resolved_scene)
    attributes = infer_traits(cleaned, style_raw, resolved_scene, gender_id, age_id)
    pieces = [part.strip() for part in re.split(r"\s*\+\s*", cleaned) if part.strip()]
    if len(pieces) < 2:
        pieces = [cleaned]
    subtitle = f"{TEMP_TITLE[category_id]} · {SCENE_TITLE[resolved_scene]} · {style_raw}，可按自己的衣柜替换同类单品。"
    details = (
        f"这是一套面向{TEMP_TITLE[category_id]}和{SCENE_TITLE[resolved_scene]}场景的参考搭配。"
        "录入到个人衣柜时，优先保留你真实拥有、穿着舒服、适合当天日程的单品；"
        "没有同款时，用相近颜色、版型和厚薄的衣物替代即可。"
    )
    if supplement_note:
        details += supplement_note
    steps = [
        "先确认核心单品是否都在自己的衣柜里；没有同款时，用相近颜色、版型或面料替代。",
        "按当天体感温度调整内层厚度，保证能走、能坐、能在室内外切换。",
        "出门前检查鞋履、包袋、裤脚或裙摆长度，让整体利落且行动方便。",
    ]
    notes = [
        "内置搭配是参考模板，建议另存后改成你真实拥有的单品。",
        "性别和年龄标签只作为筛选参考，不限制个人穿着选择。",
    ]
    option = {
        "id": option_id_value,
        "moduleId": "wear",
        "categoryId": category_id,
        "contextId": resolved_scene,
        "contextIds": [resolved_scene],
        "titleZh": cleaned,
        "titleEn": cleaned,
        "subtitleZh": subtitle,
        "subtitleEn": subtitle,
        "detailsZh": details,
        "detailsEn": details,
        "materialsZh": pieces,
        "materialsEn": pieces,
        "stepsZh": steps,
        "stepsEn": steps,
        "notesZh": notes,
        "notesEn": notes,
        "tagsZh": [],
        "tagsEn": [],
        "sourceLabel": None,
        "sourceUrl": None,
        "references": [],
        "attributes": attributes,
        "custom": False,
    }
    option["tagsZh"] = zh_tags(option)
    option["tagsEn"] = option["tagsZh"]
    return option


def parse_outfit_library(path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    section = ""
    section_slug = ""
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        if raw_line.startswith("## "):
            section = raw_line.strip("# ").strip()
            section_slug = slugify(section)
            continue
        cells = split_table_row(raw_line)
        if cells is None:
            continue
        rows.append(
            {
                "section": section,
                "sectionSlug": section_slug,
                "rowNo": cells[0],
                "outfit": cells[1],
                "temperature": cells[2],
                "style": cells[3],
            }
        )
    return rows


SUPPLEMENTS = {
    "commute": [
        ("基础衬衫 + 直筒裤 + 轻外套 + 舒适通勤鞋", "通勤基础"),
        ("针织上装 + 烟管裤 + 简洁外套 + 乐福鞋", "利落通勤"),
        ("纯色内搭 + 可穿脱外层 + 深色裤装 + 稳妥鞋履", "温差通勤"),
    ],
    "casual": [
        ("干净T恤 + 休闲裤 + 轻便外套 + 小白鞋", "日常基础"),
        ("柔软针织 + 牛仔裤 + 帆布鞋 + 托特包", "松弛日常"),
        ("宽松上装 + 直筒下装 + 舒适鞋履", "周末休闲"),
    ],
    "business": [
        ("挺括外套 + 衬衫或针织内搭 + 西裤 + 皮鞋", "正式基础"),
        ("深色套装感外层 + 浅色内搭 + 利落下装 + 低调鞋履", "正式会议"),
        ("结构感上装 + 克制配色 + 直线条下装 + 整洁鞋面", "商务场景"),
    ],
    "date": [
        ("柔和上装 + 有垂感下装 + 干净鞋履 + 小面积配饰", "约会基础"),
        ("针织或衬衫 + 修饰比例下装 + 轻亮点配饰", "温柔约会"),
        ("简洁主色 + 柔软材质 + 记忆点鞋包", "社交约会"),
    ],
    "rain": [
        ("防泼水轻外套 + 快干上装 + 九分直筒裤 + 防滑鞋", "雨天通勤"),
        ("短风衣 + 棉质内搭 + 深色裤装 + 防滑乐福鞋", "雨天日常"),
        ("壳层夹克 + 速干T恤 + 轻量长裤 + 抓地运动鞋", "雨天运动"),
    ],
    "exercise": [
        ("速干T恤 + 弹力长裤 + 轻量外套 + 训练鞋", "运动通勤"),
        ("透气背心 + 运动短裤 + 防晒薄外套 + 跑鞋", "户外活动"),
        ("连帽卫衣 + 运动裤 + 支撑型运动鞋", "低强度运动"),
    ],
}


def supplement_coverage(options: list[dict[str, Any]], used_ids: set[str], minimum: int = 8) -> None:
    counts = Counter((option["categoryId"], option["contextId"]) for option in options)
    for temp_id, *_ in TEMPERATURES:
        for scene_id, *_ in SCENES:
            current = counts[(temp_id, scene_id)]
            if current >= minimum:
                continue
            templates = SUPPLEMENTS.get(scene_id)
            if not templates:
                continue
            needed = minimum - current
            for index in range(needed):
                outfit, style = templates[index % len(templates)]
                temp_label = TEMP_TITLE[temp_id]
                unique_id = f"wear_supplement_{temp_id}_{scene_id}_{index + 1:02d}"
                while unique_id in used_ids:
                    unique_id = f"{unique_id}_x"
                used_ids.add(unique_id)
                option = build_option(
                    option_id_value=unique_id,
                    outfit=outfit,
                    temp_raw=temp_label,
                    style_raw=style,
                    section="通用补充",
                    scene_id=scene_id,
                    supplement_note="这条用于补足天气或运动场景覆盖，仍建议按自己的真实衣柜替换。",
                )
                option["categoryId"] = temp_id
                option["attributes"]["gender"] = ["gender_neutral"]
                option["attributes"]["age"] = ["all_age"]
                option["tagsZh"] = zh_tags(option)
                option["tagsEn"] = option["tagsZh"]
                options.append(option)
                counts[(temp_id, scene_id)] += 1


def trait_groups_json() -> list[dict[str, Any]]:
    return [
        {
            "id": group_id,
            "titleZh": title_zh,
            "titleEn": title_en,
            "subtitleZh": subtitle_zh,
            "subtitleEn": subtitle_en,
            "multiSelect": True,
            "options": [
                {"id": option_id, "titleZh": option_zh, "titleEn": option_en}
                for option_id, option_zh, option_en in options
            ],
        }
        for group_id, title_zh, title_en, subtitle_zh, subtitle_en, options in TRAIT_GROUPS
    ]


def category_json(items: list[tuple[str, str, str, str, str]]) -> list[dict[str, str]]:
    return [
        {
            "id": item_id,
            "titleZh": title_zh,
            "titleEn": title_en,
            "subtitleZh": subtitle_zh,
            "subtitleEn": subtitle_en,
        }
        for item_id, title_zh, title_en, subtitle_zh, subtitle_en in items
    ]


def build_library(source_dir: Path) -> dict[str, Any]:
    rows = parse_outfit_library(source_dir / "衣着搭配库.md")
    options: list[dict[str, Any]] = []
    used_ids: set[str] = set()
    for row in rows:
        item_id = option_id(row["sectionSlug"], row["rowNo"], used_ids)
        options.append(
            build_option(
                option_id_value=item_id,
                outfit=row["outfit"],
                temp_raw=row["temperature"],
                style_raw=row["style"],
                section=row["section"],
            )
        )
    supplement_coverage(options, used_ids)
    per_temp_scene = Counter((option["categoryId"], option["contextId"]) for option in options)
    per_gender = Counter(option["attributes"]["gender"][0] for option in options)
    per_age = Counter(option["attributes"]["age"][0] for option in options)
    generated_at = dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")
    return {
        "libraryId": LIBRARY_ID,
        "libraryVersion": dt.date.today().isoformat(),
        "schemaId": SCHEMA_ID,
        "schemaVersion": SCHEMA_VERSION,
        "generatedAt": generated_at,
        "referenceTitles": [],
        "stats": {
            "totalOutfits": len(options),
            "parsedRows": len(rows),
            "perTempScene": {
                f"{temp}/{scene}": per_temp_scene[(temp, scene)]
                for temp, *_ in TEMPERATURES
                for scene, *_ in SCENES
            },
            "perGender": dict(sorted(per_gender.items())),
            "perAge": dict(sorted(per_age.items())),
        },
        "categories": {
            "temperature": category_json(TEMPERATURES),
            "scene": category_json(SCENES),
        },
        "traitGroups": trait_groups_json(),
        "guideModules": GUIDE_MODULES,
        "options": options,
    }


CREATE_OPTIONS_SQL = """
CREATE TABLE daily_choice_wear_options (
  option_id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL,
  context_id TEXT,
  context_ids_json TEXT NOT NULL DEFAULT '[]',
  title_zh TEXT NOT NULL,
  title_en TEXT NOT NULL,
  subtitle_zh TEXT NOT NULL,
  subtitle_en TEXT NOT NULL,
  details_zh TEXT NOT NULL,
  details_en TEXT NOT NULL,
  materials_zh_json TEXT NOT NULL DEFAULT '[]',
  materials_en_json TEXT NOT NULL DEFAULT '[]',
  steps_zh_json TEXT NOT NULL DEFAULT '[]',
  steps_en_json TEXT NOT NULL DEFAULT '[]',
  notes_zh_json TEXT NOT NULL DEFAULT '[]',
  notes_en_json TEXT NOT NULL DEFAULT '[]',
  tags_zh_json TEXT NOT NULL DEFAULT '[]',
  tags_en_json TEXT NOT NULL DEFAULT '[]',
  source_label TEXT,
  source_url TEXT,
  references_json TEXT NOT NULL DEFAULT '[]',
  attributes_json TEXT NOT NULL DEFAULT '{}',
  custom INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active',
  is_available INTEGER NOT NULL DEFAULT 1,
  sort_key INTEGER NOT NULL DEFAULT 0
)
"""


def write_database(library: dict[str, Any], db_path: Path) -> None:
    if db_path.exists():
        db_path.unlink()
    for suffix in ("-wal", "-shm", "-journal"):
        artifact = Path(f"{db_path}{suffix}")
        if artifact.exists():
            artifact.unlink()
    db = sqlite3.connect(db_path)
    try:
        db.execute("PRAGMA foreign_keys = ON")
        db.execute(CREATE_OPTIONS_SQL)
        db.execute(
            "CREATE TABLE daily_choice_wear_meta (meta_key TEXT PRIMARY KEY, meta_value TEXT NOT NULL)"
        )
        db.execute(
            "CREATE INDEX idx_wear_cat_ctx ON daily_choice_wear_options(category_id, context_id, status, is_available)"
        )
        meta = {
            "library_id": library["libraryId"],
            "library_version": library["libraryVersion"],
            "schema_id": library["schemaId"],
            "schema_version": str(library["schemaVersion"]),
            "reference_titles_json": json.dumps([], ensure_ascii=False),
            "installed_at": "",
            "updated_at": library["generatedAt"],
            "error_message": "",
        }
        db.executemany(
            "INSERT INTO daily_choice_wear_meta(meta_key, meta_value) VALUES (?, ?)",
            sorted(meta.items()),
        )
        rows = []
        for sort_key, option in enumerate(library["options"]):
            rows.append(
                (
                    option["id"],
                    option["categoryId"],
                    option.get("contextId"),
                    json.dumps(option.get("contextIds", []), ensure_ascii=False),
                    option["titleZh"],
                    option["titleEn"],
                    option["subtitleZh"],
                    option["subtitleEn"],
                    option["detailsZh"],
                    option["detailsEn"],
                    json.dumps(option.get("materialsZh", []), ensure_ascii=False),
                    json.dumps(option.get("materialsEn", []), ensure_ascii=False),
                    json.dumps(option.get("stepsZh", []), ensure_ascii=False),
                    json.dumps(option.get("stepsEn", []), ensure_ascii=False),
                    json.dumps(option.get("notesZh", []), ensure_ascii=False),
                    json.dumps(option.get("notesEn", []), ensure_ascii=False),
                    json.dumps(option.get("tagsZh", []), ensure_ascii=False),
                    json.dumps(option.get("tagsEn", []), ensure_ascii=False),
                    option.get("sourceLabel"),
                    option.get("sourceUrl"),
                    json.dumps(option.get("references", []), ensure_ascii=False),
                    json.dumps(option.get("attributes", {}), ensure_ascii=False),
                    1 if option.get("custom") else 0,
                    "active",
                    1,
                    sort_key,
                )
            )
        db.executemany(
            """
            INSERT INTO daily_choice_wear_options (
              option_id, category_id, context_id, context_ids_json,
              title_zh, title_en, subtitle_zh, subtitle_en,
              details_zh, details_en,
              materials_zh_json, materials_en_json,
              steps_zh_json, steps_en_json,
              notes_zh_json, notes_en_json,
              tags_zh_json, tags_en_json,
              source_label, source_url, references_json,
              attributes_json,
              custom, status, is_available, sort_key
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            rows,
        )
        db.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
        db.commit()
    finally:
        db.close()


def write_format(library: dict[str, Any], output_dir: Path) -> None:
    stats = library["stats"]
    content = f"""# 穿什么数据格式规范

## 文件

- `daily_choice_wear_library.json`: 内置穿搭参考库 JSON。
- `daily_choice_wear_library.db`: 与 Flutter 运行时 `DailyChoiceWearLibraryStore` schema 对齐的 SQLite 数据库。
- `GENERATION_SUMMARY.md`: 本次生成摘要和校验信息。

## 本次数据

- 生成日期: {library["generatedAt"]}
- 总搭配数: {stats["totalOutfits"]}
- 从 Markdown 解析: {stats["parsedRows"]}
- 来源展示: 已移除。数据只保留可操作搭配、标签和说明，不在 App 内展示书名或信息源。
- 新增筛选: `gender` 性别参考、`age` 年龄阶段。

## 关键字段

每个 `options[]` 项兼容 `DailyChoiceOption`:

- `categoryId`: 气温档位。
- `contextId` / `contextIds`: 场景。
- `attributes.gender`: `gender_neutral` / `womenswear` / `menswear`。
- `attributes.age`: `all_age` / `youth` / `young_adult` / `adult` / `mature`。
- `attributes.style`, `silhouette`, `key_piece`, `material`, `highlight`: 穿搭筛选标签。
- `sourceLabel`, `sourceUrl`, `references`: 固定为空，避免信息源争议。

## 使用建议

内置库是参考模板。用户应在 App 管理页中把适合自己的组合另存、改成真实拥有的单品，并整理到自己的衣柜集合。
"""
    (output_dir / "FORMAT.md").write_text(content, encoding="utf-8", newline="\n")


def write_summary(library: dict[str, Any], output_dir: Path) -> None:
    lines = [
        "# 每日决策穿什么数据生成摘要",
        "",
        f"- 生成时间: {library['generatedAt']}",
        f"- 总搭配数: {library['stats']['totalOutfits']}",
        f"- Markdown 解析行数: {library['stats']['parsedRows']}",
        f"- JSON: `{output_dir / 'daily_choice_wear_library.json'}`",
        f"- SQLite: `{output_dir / 'daily_choice_wear_library.db'}`",
        "",
        "## 性别参考分布",
        "",
    ]
    for key, count in library["stats"]["perGender"].items():
        lines.append(f"- {key}: {count}")
    lines.extend(["", "## 年龄阶段分布", ""])
    for key, count in library["stats"]["perAge"].items():
        lines.append(f"- {key}: {count}")
    lines.extend(["", "## 气温 / 场景覆盖", ""])
    for key, count in library["stats"]["perTempScene"].items():
        lines.append(f"- {key}: {count}")
    lines.extend(
        [
            "",
            "## 备注",
            "",
            "- 已清空 `referenceTitles`，并将所有 option 的 `sourceLabel`、`sourceUrl`、`references` 留空。",
            "- 内置搭配作为参考模板；App 文案引导用户另存并改造成自己的真实衣柜搭配。",
        ]
    )
    (output_dir / "GENERATION_SUMMARY.md").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def validate(library: dict[str, Any], db_path: Path) -> None:
    options = library["options"]
    if not options:
        raise RuntimeError("No generated options.")
    missing_gender = [item["id"] for item in options if not item["attributes"].get("gender")]
    missing_age = [item["id"] for item in options if not item["attributes"].get("age")]
    has_sources = [
        item["id"]
        for item in options
        if item.get("sourceLabel") or item.get("sourceUrl") or item.get("references")
    ]
    if missing_gender or missing_age or has_sources:
        raise RuntimeError(
            f"Invalid generated data: missing_gender={len(missing_gender)}, "
            f"missing_age={len(missing_age)}, has_sources={len(has_sources)}"
        )
    db = sqlite3.connect(db_path)
    try:
        count = db.execute(
            "SELECT COUNT(*) FROM daily_choice_wear_options WHERE status='active' AND is_available=1"
        ).fetchone()[0]
    finally:
        db.close()
    if count != len(options):
        raise RuntimeError(f"SQLite row count mismatch: {count} != {len(options)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    library = build_library(args.source_dir)
    json_path = args.output_dir / "daily_choice_wear_library.json"
    db_path = args.output_dir / "daily_choice_wear_library.db"
    json_path.write_text(
        json.dumps(library, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    write_database(library, db_path)
    write_format(library, args.output_dir)
    write_summary(library, args.output_dir)
    validate(library, db_path)
    print(
        json.dumps(
            {
                "json": str(json_path),
                "db": str(db_path),
                "totalOutfits": library["stats"]["totalOutfits"],
                "parsedRows": library["stats"]["parsedRows"],
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
