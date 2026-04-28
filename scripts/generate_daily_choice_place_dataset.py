#!/usr/bin/env python3
"""Generate the Daily Choice place library JSON and SQLite database."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import sqlite3
from collections import Counter
from pathlib import Path
from typing import Any


DEFAULT_OUTPUT_DIR = Path(r"D:\vocabularySleep-resources\去哪儿-数据")

LIBRARY_ID = "toolbox_daily_choice_place_library"
SCHEMA_ID = "vocabulary_sleep.daily_choice.place_library"
SCHEMA_VERSION = 1


DISTANCES = [
    {
        "id": "outside",
        "titleZh": "出门",
        "titleEn": "Step out",
        "prefixZh": "附近",
        "prefixEn": "Nearby ",
        "durationZh": "30 分钟到 1 小时",
        "durationEn": "30 to 60 minutes",
        "rhythmZh": "低摩擦、说走就走",
        "rhythmEn": "low-friction and easy to start",
        "budgetZh": "0-80 元为主",
        "budgetEn": "usually 0-80 CNY",
        "checklistZh": "天气、电量、钥匙、步行或短途通勤",
        "checklistEn": "weather, battery, keys, and a short route",
    },
    {
        "id": "nearby",
        "titleZh": "周边",
        "titleEn": "Nearby",
        "prefixZh": "同城",
        "prefixEn": "In-town ",
        "durationZh": "半天左右",
        "durationEn": "around half a day",
        "rhythmZh": "适合留出一段完整同城时间",
        "rhythmEn": "good for a local half-day block",
        "budgetZh": "50-220 元为主",
        "budgetEn": "usually 50-220 CNY",
        "checklistZh": "营业时间、交通方式、餐饮衔接和返程窗口",
        "checklistEn": "opening hours, transport, food, and return timing",
    },
    {
        "id": "travel",
        "titleZh": "远行",
        "titleEn": "Travel",
        "prefixZh": "远一点的",
        "prefixEn": "Further-out ",
        "durationZh": "半天到一天",
        "durationEn": "half a day to a full day",
        "rhythmZh": "需要提前确认预约、票务和返程",
        "rhythmEn": "needs booking, tickets, and return checks",
        "budgetZh": "100-500 元起，视交通和门票浮动",
        "budgetEn": "100-500 CNY and up, depending on transport and tickets",
        "checklistZh": "预约、票务、证件、补给、返程和备用方案",
        "checklistEn": "booking, tickets, ID, supplies, return route, and backup",
    },
]


ANGLES = [
    {
        "id": "steady",
        "titleZh": "稳妥线",
        "titleEn": "steady route",
        "subtitleZh": "优先低风险、好收尾、临时改计划成本低",
        "subtitleEn": "prioritizes low risk, easy closure, and flexible pivots",
        "tagZh": "稳妥",
        "tagEn": "Steady",
        "noteZh": "稳妥线优先选择评价稳定、动线简单、可以随时结束的候选。",
        "noteEn": "The steady route favors reliable places with simple routes and easy closure.",
    },
    {
        "id": "fresh",
        "titleZh": "新鲜线",
        "titleEn": "fresh route",
        "subtitleZh": "优先一点新鲜感，但仍保留同区替代点",
        "subtitleEn": "adds novelty while keeping a same-area backup",
        "tagZh": "新鲜感",
        "tagEn": "Novelty",
        "noteZh": "新鲜线可以多看新开、临展、限定活动或没去过的同类型地点。",
        "noteEn": "The fresh route can include newly opened places, temporary events, or untried options.",
    },
]


SCENES: list[dict[str, Any]] = [
    {
        "id": "food",
        "titleZh": "饮食",
        "titleEn": "Food",
        "intentZh": "补一顿饭、换口味，或找个能坐下来的地方",
        "intentEn": "land a meal, switch flavors, or find somewhere to sit",
        "companionZh": "一个人也自然，小组同行更容易顺手延长",
        "companionEn": "solo-friendly, with small groups easy to extend",
        "checkpointZh": "营业时间、排队、是否容易收尾",
        "checkpointEn": "opening hours, queue length, and ease of closing out",
        "places": [
            ("breakfast_shop", "早餐铺", "breakfast shop", "早餐 铺", "breakfast shop", True, ["热食", "快决策"], ["Hot food", "Fast choice"], ["study"]),
            ("noodle_house", "面馆", "noodle house", "面馆", "noodle house", True, ["正餐", "独自可去"], ["Main meal", "Solo-friendly"], ["social"]),
            ("local_restaurant", "本地餐馆", "local restaurant", "本地 餐馆", "local restaurant", True, ["本地口味", "正餐"], ["Local flavor", "Main meal"], ["specialty"]),
            ("cafe_dessert", "咖啡甜品店", "cafe and dessert shop", "咖啡 甜品", "cafe dessert", True, ["可久坐", "轻甜"], ["Sit-down", "Dessert"], ["study", "social"]),
            ("food_hall", "美食广场", "food hall", "美食 广场", "food hall", True, ["多人友好", "选择多"], ["Group-friendly", "Many choices"], ["shopping"]),
            ("snack_street", "小吃街", "snack street", "小吃街", "snack street", False, ["边走边吃", "烟火气"], ["Walking food", "Street vibe"], ["photo"]),
            ("late_night_food", "夜宵街区", "late-night food strip", "夜宵 街区", "late night food street", False, ["夜间", "续摊"], ["Late-night", "After-hours"], ["nightlife"]),
            ("view_restaurant", "景观餐厅", "scenic restaurant", "景观 餐厅", "scenic restaurant", True, ["景观", "约会"], ["View", "Date-friendly"], ["photo", "social"]),
        ],
    },
    {
        "id": "entertainment",
        "titleZh": "娱乐",
        "titleEn": "Entertainment",
        "intentZh": "找一点新鲜感、玩一会儿，或给社交找载体",
        "intentEn": "get novelty, play for a while, or give social time an activity",
        "companionZh": "一个人优先低沟通成本，多人适合互动场地",
        "companionEn": "solo works with low-friction fun; groups suit interactive venues",
        "checkpointZh": "营业时间、预约规则和临时改计划成本",
        "checkpointEn": "opening time, booking rules, and pivot cost",
        "places": [
            ("cinema", "影院", "cinema", "影院", "cinema", True, ["低沟通", "室内"], ["Low-talk", "Indoor"], ["relax"]),
            ("arcade", "电玩城", "arcade", "电玩城", "arcade", True, ["互动", "上手快"], ["Interactive", "Easy start"], ["nightlife"]),
            ("board_game_cafe", "桌游店", "board game cafe", "桌游 店", "board game cafe", True, ["慢社交", "多人"], ["Slow social", "Group"], ["social"]),
            ("escape_room", "密室", "escape room", "密室", "escape room", True, ["团队", "沉浸"], ["Team", "Immersive"], ["social"]),
            ("ktv", "KTV", "KTV", "KTV", "KTV", True, ["合唱", "聚会"], ["Sing-along", "Party"], ["nightlife", "social"]),
            ("livehouse", "Livehouse", "livehouse", "Livehouse", "livehouse", True, ["现场", "氛围"], ["Live", "Atmosphere"], ["nightlife"]),
            ("comedy_club", "脱口秀小剧场", "comedy club", "脱口秀 小剧场", "comedy club", True, ["轻演出", "晚间"], ["Light show", "Evening"], ["culture"]),
            ("theme_experience", "主题体验馆", "themed experience venue", "主题 体验馆", "themed experience venue", True, ["新鲜", "打卡"], ["Novel", "Check-in"], ["photo"]),
        ],
    },
    {
        "id": "sports",
        "titleZh": "运动",
        "titleEn": "Sports",
        "intentZh": "让身体动起来，用低门槛活动切换状态",
        "intentEn": "wake up the body and shift state through movement",
        "companionZh": "一个人适合自助式，多人适合对抗或协作项目",
        "companionEn": "solo suits self-serve places; groups suit matches or teamwork",
        "checkpointZh": "装备、预约、淋浴和强度是否合适",
        "checkpointEn": "gear, booking, showers, and suitable intensity",
        "places": [
            ("community_gym", "社区健身房", "community gym", "健身房", "gym", True, ["低门槛", "常规"], ["Low-friction", "Routine"], ["relax"]),
            ("badminton_court", "羽毛球馆", "badminton court", "羽毛球馆", "badminton court", True, ["轻对抗", "多人"], ["Light match", "Group"], ["social"]),
            ("basketball_court", "篮球场", "basketball court", "篮球场", "basketball court", False, ["户外", "团队"], ["Outdoor", "Team"], ["social"]),
            ("swimming_pool", "游泳馆", "swimming pool", "游泳馆", "swimming pool", True, ["低冲击", "恢复"], ["Low-impact", "Recovery"], ["relax"]),
            ("climbing_gym", "攀岩馆", "climbing gym", "攀岩馆", "climbing gym", True, ["挑战", "新鲜"], ["Challenge", "Novel"], ["entertainment"]),
            ("skate_park", "滑板公园", "skate park", "滑板 公园", "skate park", False, ["街头", "观看也可"], ["Street", "Watchable"], ["photo"]),
            ("yoga_studio", "瑜伽普拉提馆", "yoga or pilates studio", "瑜伽 普拉提", "yoga pilates studio", True, ["舒展", "恢复"], ["Stretch", "Restore"], ["relax"]),
            ("greenway_run", "绿道慢跑线", "greenway running route", "绿道 慢跑", "greenway running route", False, ["有氧", "自然"], ["Cardio", "Nature"], ["nature"]),
        ],
    },
    {
        "id": "culture",
        "titleZh": "文化",
        "titleEn": "Culture",
        "intentZh": "看展、看演出，或给自己一点输入",
        "intentEn": "see exhibitions, performances, or take in new input",
        "companionZh": "独自看也好，同行时适合低声交流",
        "companionEn": "solo works well; companions should allow quiet exchange",
        "checkpointZh": "开放时间、预约、闭馆日和展期",
        "checkpointEn": "opening hours, booking, closing days, and exhibition dates",
        "places": [
            ("museum", "博物馆", "museum", "博物馆", "museum", True, ["常设展", "信息量"], ["Permanent", "Informative"], ["history"]),
            ("art_gallery", "美术馆", "art gallery", "美术馆", "art gallery", True, ["视觉", "慢看"], ["Visual", "Slow look"], ["photo"]),
            ("theater", "剧场", "theater", "剧场 演出", "theater performance", True, ["演出", "沉浸"], ["Performance", "Immersive"], ["entertainment"]),
            ("bookstore_event", "书店活动", "bookstore event", "书店 活动", "bookstore event", True, ["讲座", "书店"], ["Talk", "Bookstore"], ["study"]),
            ("public_lecture", "公共讲座", "public lecture", "公共 讲座", "public lecture", True, ["输入", "低成本"], ["Input", "Low-cost"], ["study"]),
            ("film_archive", "资料馆放映", "film archive screening", "资料馆 放映", "film archive screening", True, ["电影", "专题"], ["Film", "Program"], ["entertainment"]),
            ("craft_workshop", "手作体验课", "craft workshop", "手作 体验", "craft workshop", True, ["动手", "体验"], ["Hands-on", "Experience"], ["specialty"]),
            ("cultural_center", "文化中心", "cultural center", "文化 中心", "cultural center", True, ["综合", "公共空间"], ["Mixed", "Public space"], ["social"]),
        ],
    },
    {
        "id": "history",
        "titleZh": "历史",
        "titleEn": "History",
        "intentZh": "看城市如何留下时间痕迹",
        "intentEn": "see how a city keeps traces of time",
        "companionZh": "适合慢走、低声交流，也适合独自去",
        "companionEn": "best for slow walking, low-voice exchange, or solo time",
        "checkpointZh": "开放规则、讲解安排和路线连贯性",
        "checkpointEn": "access rules, guided interpretation, and route continuity",
        "places": [
            ("old_street", "老街区", "old street", "老街区", "old street", False, ["街区", "慢走"], ["Street", "Slow walk"], ["photo", "specialty"]),
            ("historic_building", "历史建筑群", "historic buildings", "历史 建筑", "historic buildings", False, ["建筑", "时间感"], ["Architecture", "Time traces"], ["photo"]),
            ("heritage_site", "文保遗址", "heritage site", "文保 遗址", "heritage site", False, ["遗址", "公共记忆"], ["Relic", "Memory"], ["memorial"]),
            ("ancient_town", "古镇古村", "ancient town or village", "古镇 古村", "ancient town village", False, ["古镇", "半日"], ["Old town", "Half-day"], ["specialty"]),
            ("city_wall", "城墙或城门", "city wall or gate", "城墙 城门", "city wall gate", False, ["地标", "步行"], ["Landmark", "Walk"], ["photo"]),
            ("old_factory", "老厂区改造", "converted factory", "老厂区 改造", "converted factory", False, ["工业", "改造"], ["Industrial", "Converted"], ["specialty"]),
            ("former_residence", "名人故居", "former residence", "名人 故居", "former residence", True, ["人物", "室内"], ["Figure-led", "Indoor"], ["culture"]),
            ("archive_exhibition", "城市档案展", "city archive exhibition", "城市 档案 展", "city archive exhibition", True, ["档案", "叙事"], ["Archive", "Narrative"], ["culture"]),
        ],
    },
    {
        "id": "nature",
        "titleZh": "自然",
        "titleEn": "Nature",
        "intentZh": "用绿地、水边或山野恢复注意力",
        "intentEn": "restore attention through greenery, water, or trails",
        "companionZh": "独自散步、两人聊天或家庭同行都适合",
        "companionEn": "good for solo walks, pairs, or family outings",
        "checkpointZh": "天气、路况、厕所、补水和返程",
        "checkpointEn": "weather, path condition, restrooms, water, and return route",
        "places": [
            ("city_park", "城市公园", "city park", "城市 公园", "city park", False, ["绿地", "低成本"], ["Green", "Low-cost"], ["family"]),
            ("riverside", "滨水步道", "riverside walk", "滨水 步道", "riverside walk", False, ["水边", "散步"], ["Waterfront", "Walk"], ["photo"]),
            ("botanical_garden", "植物园", "botanical garden", "植物园", "botanical garden", False, ["植物", "季节"], ["Plants", "Seasonal"], ["photo", "family"]),
            ("wetland", "湿地公园", "wetland park", "湿地 公园", "wetland park", False, ["观鸟", "自然"], ["Birding", "Nature"], ["family"]),
            ("hill_trail", "近郊登高线", "hill trail", "近郊 登高", "hill trail", False, ["登高", "体力"], ["Climb", "Effort"], ["sports"]),
            ("forest_path", "林荫步道", "shaded forest path", "林荫 步道", "shaded forest path", False, ["阴凉", "慢走"], ["Shade", "Slow walk"], ["relax"]),
            ("lake_loop", "湖边环线", "lake loop", "湖边 环线", "lake loop", False, ["环线", "景观"], ["Loop", "View"], ["sports"]),
            ("flower_field", "季节花田", "seasonal flower field", "花田 花园", "seasonal flower field", False, ["花期", "出片"], ["Bloom", "Photo"], ["photo"]),
        ],
    },
    {
        "id": "study",
        "titleZh": "学习",
        "titleEn": "Study",
        "intentZh": "换个环境专注一小段时间",
        "intentEn": "change environment and focus for a while",
        "companionZh": "更适合独自或安静同行",
        "companionEn": "best solo or with quiet companions",
        "checkpointZh": "座位、电源、安静程度和营业时间",
        "checkpointEn": "seats, power, quietness, and opening hours",
        "places": [
            ("public_library", "公共图书馆", "public library", "公共 图书馆", "public library", True, ["安静", "免费"], ["Quiet", "Free"], ["culture"]),
            ("study_room", "自习室", "study room", "自习室", "study room", True, ["专注", "付费"], ["Focus", "Paid"], ["relax"]),
            ("bookstore", "书店", "bookstore", "书店", "bookstore", True, ["浏览", "输入"], ["Browse", "Input"], ["culture"]),
            ("quiet_cafe", "安静咖啡馆", "quiet cafe", "安静 咖啡馆", "quiet cafe", True, ["轻办公", "咖啡"], ["Light work", "Coffee"], ["food"]),
            ("campus_area", "大学校园周边", "campus area", "大学 校园 周边", "campus area", False, ["校园", "散步"], ["Campus", "Walk"], ["history"]),
            ("coworking_daypass", "共享办公日票", "coworking day pass", "共享 办公 日票", "coworking day pass", True, ["办公", "电源"], ["Work", "Power"], ["social"]),
            ("museum_reading_area", "博物馆阅读区", "museum reading area", "博物馆 阅读区", "museum reading area", True, ["阅读", "文化"], ["Read", "Culture"], ["culture"]),
            ("community_classroom", "社区课堂", "community classroom", "社区 课堂", "community classroom", True, ["课程", "公共"], ["Class", "Public"], ["family"]),
        ],
    },
    {
        "id": "shopping",
        "titleZh": "购物",
        "titleEn": "Shopping",
        "intentZh": "补物品、逛市集，或给自己一点实体浏览",
        "intentEn": "buy essentials, browse markets, or do physical browsing",
        "companionZh": "一个人效率高，多人适合边逛边聊",
        "companionEn": "solo is efficient; groups can browse and talk",
        "checkpointZh": "预算、营业时间、寄存和人流",
        "checkpointEn": "budget, hours, storage, and crowds",
        "places": [
            ("mall", "综合商场", "shopping mall", "综合 商场", "shopping mall", True, ["一站式", "雨天"], ["One-stop", "Rain-safe"], ["food"]),
            ("market", "生活市集", "local market", "生活 市集", "local market", False, ["生活感", "采购"], ["Everyday", "Errand"], ["specialty"]),
            ("night_market", "夜市", "night market", "夜市", "night market", False, ["夜间", "小吃"], ["Night", "Snacks"], ["food", "nightlife"]),
            ("outlet", "奥莱或折扣店", "outlet mall", "奥莱 折扣店", "outlet mall", True, ["折扣", "半日"], ["Discount", "Half-day"], ["specialty"]),
            ("design_store", "买手店", "design select shop", "买手店", "select shop", True, ["设计", "小众"], ["Design", "Niche"], ["photo"]),
            ("flower_market", "花鸟花卉市场", "flower market", "花卉 市场", "flower market", False, ["花卉", "生活"], ["Flowers", "Life"], ["nature"]),
            ("secondhand_market", "二手旧物市场", "secondhand market", "二手 旧物 市场", "secondhand market", False, ["旧物", "淘货"], ["Vintage", "Treasure hunt"], ["specialty"]),
            ("book_fair", "书展或文创市集", "book or cultural fair", "书展 文创 市集", "book fair cultural market", False, ["文创", "限时"], ["Cultural goods", "Limited-time"], ["culture"]),
        ],
    },
    {
        "id": "social",
        "titleZh": "社交",
        "titleEn": "Social",
        "intentZh": "见人、聊天，或降低见面时的尴尬成本",
        "intentEn": "meet people, talk, or reduce awkwardness through activity",
        "companionZh": "两三人最灵活，多人要优先座位和动线",
        "companionEn": "pairs and trios are flexible; larger groups need seats and routes",
        "checkpointZh": "噪音、座位、预约和是否方便续摊",
        "checkpointEn": "noise, seating, booking, and whether it can extend",
        "places": [
            ("tea_house", "茶室", "tea house", "茶室", "tea house", True, ["慢聊", "安静"], ["Slow talk", "Quiet"], ["relax"]),
            ("brunch_place", "早午餐店", "brunch spot", "早午餐", "brunch spot", True, ["轻聚", "白天"], ["Light meetup", "Daytime"], ["food"]),
            ("board_game_place", "桌游聚会点", "board game meetup spot", "桌游 聚会", "board game cafe", True, ["互动", "多人"], ["Interactive", "Group"], ["entertainment"]),
            ("walk_and_talk", "边走边聊路线", "walk-and-talk route", "散步 路线", "walk and talk route", False, ["低压力", "散步"], ["Low-pressure", "Walk"], ["nature"]),
            ("private_room_dining", "包间餐厅", "private-room restaurant", "包间 餐厅", "private room restaurant", True, ["多人", "私密"], ["Group", "Private"], ["food"]),
            ("community_event", "社区活动", "community event", "社区 活动", "community event", True, ["活动", "轻连接"], ["Event", "Light contact"], ["family"]),
            ("pet_friendly_cafe", "宠物友好咖啡馆", "pet-friendly cafe", "宠物友好 咖啡", "pet friendly cafe", True, ["宠物", "轻松"], ["Pet-friendly", "Easy"], ["food"]),
            ("picnic_lawn", "野餐草坪", "picnic lawn", "野餐 草坪", "picnic lawn", False, ["户外", "多人"], ["Outdoor", "Group"], ["nature", "family"]),
        ],
    },
    {
        "id": "family",
        "titleZh": "亲子",
        "titleEn": "Family",
        "intentZh": "照顾长辈、小孩和多人同行的舒适度",
        "intentEn": "support elders, children, and multi-age groups",
        "companionZh": "带小孩和长辈时优先厕所、座位和撤退路线",
        "companionEn": "with kids or elders, prioritize restrooms, seats, and exits",
        "checkpointZh": "无障碍、厕所、休息位、餐饮和人流",
        "checkpointEn": "accessibility, restrooms, seating, food, and crowds",
        "places": [
            ("children_museum", "儿童博物馆", "children's museum", "儿童 博物馆", "children museum", True, ["亲子", "互动"], ["Kids", "Interactive"], ["culture"]),
            ("science_center", "科技馆", "science center", "科技馆", "science center", True, ["科普", "互动"], ["Science", "Interactive"], ["study"]),
            ("zoo_aquarium", "动物园或水族馆", "zoo or aquarium", "动物园 水族馆", "zoo aquarium", False, ["动物", "半日"], ["Animals", "Half-day"], ["nature"]),
            ("indoor_playground", "室内儿童乐园", "indoor playground", "室内 儿童 乐园", "indoor playground", True, ["雨天", "放电"], ["Rain-safe", "Active"], ["sports"]),
            ("family_park", "亲子友好公园", "family-friendly park", "亲子 公园", "family friendly park", False, ["免费", "跑跳"], ["Free", "Run"], ["nature"]),
            ("hands_on_class", "亲子手作课", "family craft class", "亲子 手作", "family craft class", True, ["手作", "课程"], ["Craft", "Class"], ["culture"]),
            ("accessible_mall", "无障碍商场", "accessible mall", "无障碍 商场", "accessible mall", True, ["长辈友好", "室内"], ["Elder-friendly", "Indoor"], ["shopping"]),
            ("farm_experience", "农场体验", "farm experience", "农场 体验", "farm experience", False, ["户外", "体验"], ["Outdoor", "Experience"], ["nature"]),
        ],
    },
    {
        "id": "nightlife",
        "titleZh": "夜生活",
        "titleEn": "Nightlife",
        "intentZh": "让晚上有一个明确去处，而不是无目的消耗",
        "intentEn": "give the evening a destination instead of drifting",
        "companionZh": "更适合同伴同行，独自去优先安全和返程",
        "companionEn": "better with companions; solo needs safety and return checks",
        "checkpointZh": "返程、营业到几点、噪音和安全",
        "checkpointEn": "return route, closing time, noise, and safety",
        "places": [
            ("cocktail_bar", "鸡尾酒吧", "cocktail bar", "鸡尾酒吧", "cocktail bar", True, ["夜间", "小酌"], ["Night", "Drink"], ["social"]),
            ("jazz_bar", "爵士酒吧", "jazz bar", "爵士 酒吧", "jazz bar", True, ["音乐", "氛围"], ["Music", "Atmosphere"], ["culture"]),
            ("night_view", "夜景观景点", "night view spot", "夜景 观景", "night view spot", False, ["夜景", "拍照"], ["Night view", "Photo"], ["photo"]),
            ("late_movie", "深夜电影", "late movie", "深夜 电影", "late movie", True, ["低沟通", "夜间"], ["Low-talk", "Night"], ["entertainment"]),
            ("night_food", "夜宵小店", "late-night diner", "夜宵 小店", "late night diner", True, ["热食", "收尾"], ["Hot food", "Close-out"], ["food"]),
            ("night_market_walk", "夜市散步线", "night market walk", "夜市 散步", "night market walk", False, ["边逛边吃", "人气"], ["Browse and eat", "Lively"], ["shopping"]),
            ("rooftop", "露台空间", "rooftop venue", "露台 空间", "rooftop venue", False, ["露台", "风景"], ["Rooftop", "View"], ["social"]),
            ("night_show", "夜间演出", "night show", "夜间 演出", "night show", True, ["演出", "预约"], ["Show", "Booking"], ["culture"]),
        ],
    },
    {
        "id": "relax",
        "titleZh": "放松",
        "titleEn": "Relax",
        "intentZh": "降低刺激、恢复体感，给自己一段慢时间",
        "intentEn": "lower stimulation, restore the body, and take slow time",
        "companionZh": "独自或很熟的人更合适",
        "companionEn": "best solo or with someone very familiar",
        "checkpointZh": "预约、安静程度、卫生和结束后交通",
        "checkpointEn": "booking, quietness, hygiene, and transport afterward",
        "places": [
            ("spa", "按摩理疗店", "massage or spa", "按摩 理疗", "massage spa", True, ["恢复", "预约"], ["Recovery", "Booking"], ["sports"]),
            ("hot_spring", "温泉或汤池", "hot spring", "温泉 汤池", "hot spring", True, ["泡汤", "半日"], ["Bathing", "Half-day"], ["nature"]),
            ("tea_room", "安静茶室", "quiet tea room", "安静 茶室", "quiet tea room", True, ["慢", "安静"], ["Slow", "Quiet"], ["social"]),
            ("meditation_space", "冥想空间", "meditation space", "冥想 空间", "meditation space", True, ["低刺激", "静心"], ["Low-stim", "Calm"], ["study"]),
            ("slow_walk_park", "慢走公园", "slow-walk park", "慢走 公园", "slow walk park", False, ["免费", "舒缓"], ["Free", "Gentle"], ["nature"]),
            ("bathhouse", "公共浴室或汗蒸", "bathhouse or sauna", "汗蒸 公共浴室", "bathhouse sauna", True, ["暖身", "恢复"], ["Warmth", "Restore"], ["sports"]),
            ("quiet_hotel_lobby", "安静酒店大堂吧", "quiet hotel lounge", "酒店 大堂吧", "hotel lounge", True, ["安静", "坐下"], ["Quiet", "Sit-down"], ["food"]),
            ("healing_workshop", "疗愈体验课", "restorative workshop", "疗愈 体验课", "restorative workshop", True, ["体验", "恢复"], ["Experience", "Restore"], ["culture"]),
        ],
    },
    {
        "id": "photo",
        "titleZh": "出片",
        "titleEn": "Photo",
        "intentZh": "找一个画面目标，让外出更有观察感",
        "intentEn": "give the outing a visual target and a reason to observe",
        "companionZh": "适合愿意慢走和停留的人",
        "companionEn": "best with people willing to walk slowly and stop often",
        "checkpointZh": "光线、天气、人流和是否允许拍摄",
        "checkpointEn": "light, weather, crowds, and photo permission",
        "places": [
            ("viewpoint", "城市观景台", "city viewpoint", "观景台", "city viewpoint", False, ["视野", "地标"], ["View", "Landmark"], ["nightlife"]),
            ("street_corner", "有层次的街角", "layered street corner", "街角 街景", "street corner photo spot", False, ["街景", "前景"], ["Street", "Foreground"], ["history"]),
            ("bridge", "桥梁机位", "bridge photo spot", "桥梁 机位", "bridge photo spot", False, ["线条", "水边"], ["Lines", "Water"], ["nature"]),
            ("architecture_cluster", "建筑群", "architecture cluster", "建筑群", "architecture cluster", False, ["建筑", "线条"], ["Architecture", "Lines"], ["culture"]),
            ("installation_square", "装置广场", "installation square", "装置 广场", "installation square", False, ["装置", "互动"], ["Installation", "Interactive"], ["specialty"]),
            ("sunset_riverside", "江边日落点", "riverside sunset spot", "江边 日落", "riverside sunset spot", False, ["日落", "柔光"], ["Sunset", "Soft light"], ["nature"]),
            ("flower_garden", "花园或花田", "garden or flower field", "花园 花田", "garden flower field", False, ["花期", "色彩"], ["Bloom", "Color"], ["family"]),
            ("old_alley", "老巷子", "old alley", "老巷子", "old alley", False, ["故事感", "时间痕迹"], ["Story", "Time traces"], ["history"]),
        ],
    },
    {
        "id": "specialty",
        "titleZh": "特色区域",
        "titleEn": "Special area",
        "intentZh": "找有地方性气质的区域，而不是单点打卡",
        "intentEn": "find areas with local character, not only isolated spots",
        "companionZh": "适合愿意边走边看、临时拐弯的人",
        "companionEn": "best with people willing to browse and improvise",
        "checkpointZh": "区域密度、步行串联性和营业时间",
        "checkpointEn": "area density, walkability, and opening time",
        "places": [
            ("creative_park", "创意园区", "creative park", "创意园区", "creative park", False, ["复合业态", "能逛"], ["Mixed-use", "Browse"], ["shopping", "photo"]),
            ("craft_street", "手作街区", "craft street", "手作 街区", "craft street", False, ["手作", "慢逛"], ["Handmade", "Slow browse"], ["culture"]),
            ("specialty_food_zone", "特色风味区", "specialty food zone", "特色 风味区", "specialty food zone", False, ["地方味道", "集中"], ["Local flavor", "Concentrated"], ["food"]),
            ("antique_market", "古玩旧物区", "antique market", "古玩 旧物 市场", "antique market", True, ["旧物", "能淘"], ["Vintage", "Treasure hunt"], ["shopping"]),
            ("cultural_market", "文创市集", "cultural market", "文创 市集", "cultural market", False, ["文创", "展售"], ["Cultural goods", "Show and shop"], ["shopping"]),
            ("converted_factory", "改造厂区", "converted factory district", "改造 厂区", "converted factory district", False, ["工业", "层次"], ["Industrial", "Layered"], ["history", "photo"]),
            ("folk_neighborhood", "民俗风情区", "folk-custom neighborhood", "民俗 风情区", "folk custom neighborhood", False, ["地域风情", "体验"], ["Regional style", "Experience"], ["history", "food"]),
            ("themed_fair", "主题市集", "themed fair", "主题 市集", "themed fair", False, ["限时", "新鲜"], ["Limited-time", "Novel"], ["entertainment", "shopping"]),
        ],
    },
    {
        "id": "memorial",
        "titleZh": "纪念",
        "titleEn": "Memorial",
        "intentZh": "纪念、缅怀，或认真看城市如何保存记忆",
        "intentEn": "remember, commemorate, or see how a city preserves memory",
        "companionZh": "适合慢行和低声交流，也很适合独自去",
        "companionEn": "best for slow walking, quiet exchange, or solo time",
        "checkpointZh": "开放规则、礼仪要求和讲解安排",
        "checkpointEn": "access rules, etiquette, and guided interpretation",
        "places": [
            ("memorial_hall", "纪念馆", "memorial hall", "纪念馆", "memorial hall", True, ["主题明确", "信息完整"], ["Focused", "Informative"], ["history"]),
            ("martyrs_park", "烈士纪念园", "martyrs memorial park", "烈士 纪念园", "martyrs memorial park", False, ["肃穆", "短暂停留"], ["Solemn", "Short stop"], ["history"]),
            ("disaster_memorial", "灾害纪念公园", "disaster memorial park", "灾害 纪念 公园", "disaster memorial park", False, ["公共记忆", "认真看"], ["Public memory", "Reflective"], ["history"]),
            ("city_memory_museum", "城市记忆馆", "city memory museum", "城市 记忆馆", "city memory museum", True, ["城市叙事", "记忆"], ["City narrative", "Memory"], ["culture"]),
            ("school_history", "校史馆", "school history museum", "校史馆", "school history museum", True, ["教育史", "校友友好"], ["Education", "Alumni-friendly"], ["study"]),
            ("figure_residence", "人物故居纪念馆", "figure memorial residence", "人物 故居 纪念馆", "figure memorial residence", True, ["人物线索", "生活切面"], ["Figure-led", "Life slice"], ["history"]),
            ("war_site", "战场遗址纪念地", "war-site memorial", "战场 遗址 纪念", "war site memorial", False, ["遗址感", "完整看"], ["Site feeling", "Full look"], ["history"]),
            ("remembrance_square", "公共纪念广场", "remembrance square", "纪念 广场", "remembrance square", False, ["仪式", "驻足"], ["Ritual", "Pause"], ["photo"]),
        ],
    },
]


CREATE_OPTIONS_SQL = """
CREATE TABLE daily_choice_place_options (
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


def option_id(distance_id: str, scene_id: str, slug: str, angle_id: str) -> str:
    return f"go_{distance_id}_{scene_id}_{slug}_{angle_id}"


def as_place(
    raw: tuple[
        str,
        str,
        str,
        str,
        str,
        bool,
        list[str],
        list[str],
        list[str],
    ]
) -> dict[str, Any]:
    slug, title_zh, title_en, query_zh, query_en, indoor, tags_zh, tags_en, secondary = raw
    return {
        "slug": slug,
        "titleZh": title_zh,
        "titleEn": title_en,
        "queryZh": query_zh,
        "queryEn": query_en,
        "indoor": indoor,
        "tagsZh": tags_zh,
        "tagsEn": tags_en,
        "secondarySceneIds": secondary,
    }


def build_option(
    distance: dict[str, str],
    scene: dict[str, Any],
    place: dict[str, Any],
    angle: dict[str, str],
    sort_key: int,
) -> dict[str, Any]:
    distance_id = distance["id"]
    scene_id = scene["id"]
    title_zh = f'{distance["prefixZh"]}{place["titleZh"]}（{angle["titleZh"]}）'
    title_en = f'{distance["prefixEn"]}{place["titleEn"]} ({angle["titleEn"]})'
    context_ids = [scene_id, *place["secondarySceneIds"]]
    indoor_label_zh = "室内" if place["indoor"] else "户外"
    indoor_label_en = "Indoor" if place["indoor"] else "Outdoor"
    details_zh = (
        f"当你想{scene['intentZh']}时，{title_zh}可以作为一个可执行方向。"
        f"{angle['subtitleZh']}；出发前先确认{scene['checkpointZh']}，再用地图搜索词"
        f"“{place['queryZh']}”筛一组同区域候选。这个条目不是固定 POI，适合按你所在城市落地。"
    )
    details_en = (
        f"When you want to {scene['intentEn']}, {title_en} is an actionable direction. "
        f"It {angle['subtitleEn']}. Confirm {scene['checkpointEn']} before leaving, "
        f"then search \"{place['queryEn']}\" on a map and pick a nearby candidate. "
        "This is a destination type, not a fixed POI."
    )
    return {
        "id": option_id(distance_id, scene_id, place["slug"], angle["id"]),
        "moduleId": "go",
        "categoryId": distance_id,
        "contextId": scene_id,
        "contextIds": context_ids,
        "titleZh": title_zh,
        "titleEn": title_en,
        "subtitleZh": f'{scene["titleZh"]} · {distance["rhythmZh"]} · {angle["subtitleZh"]}',
        "subtitleEn": f'{scene["titleEn"]} · {distance["rhythmEn"]} · {angle["subtitleEn"]}',
        "detailsZh": details_zh,
        "detailsEn": details_en,
        "materialsZh": [
            f'建议时长：{distance["durationZh"]}',
            f'预算预期：{distance["budgetZh"]}',
            f'同行建议：{scene["companionZh"]}',
            f'室内外：{indoor_label_zh}',
            f'地图搜索词：{place["queryZh"]}',
        ],
        "materialsEn": [
            f'Suggested duration: {distance["durationEn"]}',
            f'Budget: {distance["budgetEn"]}',
            f'Good with: {scene["companionEn"]}',
            f'Indoor/outdoor: {indoor_label_en}',
            f'Map query: {place["queryEn"]}',
        ],
        "stepsZh": [
            f"先确认这次外出愿意投入{distance['durationZh']}，不要把随机方向拖成负担。",
            f"用“{place['queryZh']}”在地图中筛 3 个候选，比较营业时间、路线、人流和评分。",
            f"出发前确认{distance['checklistZh']}，并准备一个同区域替代点。",
        ],
        "stepsEn": [
            f"Decide whether you want to spend {distance['durationEn']} on this outing.",
            f"Search \"{place['queryEn']}\" and compare three candidates by hours, route, crowd, and rating.",
            f"Before leaving, confirm {distance['checklistEn']} and keep a backup in the same area.",
        ],
        "notesZh": [
            f"适合状态：{scene['intentZh']}。",
            "天气提醒：户外点优先确认气温、降雨和风；室内点也要看营业、排队和闭馆信息。",
            angle["noteZh"],
            "地图提醒：先按关键词找区域候选，再按当前体力、预算和返程窗口缩小范围。",
        ],
        "notesEn": [
            f"Best for: {scene['intentEn']}.",
            "Weather note: outdoor places need temperature, rain, and wind checks; indoor places still need hours and queue checks.",
            angle["noteEn"],
            "Map note: search by keyword first, then narrow by energy, budget, and return timing.",
        ],
        "tagsZh": [
            distance["titleZh"],
            scene["titleZh"],
            indoor_label_zh,
            angle["tagZh"],
            *place["tagsZh"],
        ],
        "tagsEn": [
            distance["titleEn"],
            scene["titleEn"],
            indoor_label_en,
            angle["tagEn"],
            *place["tagsEn"],
        ],
        "sourceLabel": None,
        "sourceUrl": None,
        "references": [],
        "attributes": {
            "distance": [distance_id],
            "scene": context_ids,
            "indoor": ["yes" if place["indoor"] else "no"],
            "angle": [angle["id"]],
            "map_query_zh": [place["queryZh"]],
            "map_query_en": [place["queryEn"]],
        },
        "custom": False,
        "sortKey": sort_key,
    }


def build_library() -> dict[str, Any]:
    options: list[dict[str, Any]] = []
    sort_key = 0
    for distance in DISTANCES:
        for scene in SCENES:
            for raw_place in scene["places"]:
                place = as_place(raw_place)
                for angle in ANGLES:
                    options.append(build_option(distance, scene, place, angle, sort_key))
                    sort_key += 1
    generated_at = dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")
    per_distance = Counter(option["categoryId"] for option in options)
    per_scene = Counter(option["contextId"] for option in options)
    per_distance_scene = Counter(
        (option["categoryId"], option["contextId"]) for option in options
    )
    return {
        "libraryId": LIBRARY_ID,
        "libraryVersion": dt.date.today().isoformat(),
        "schemaId": SCHEMA_ID,
        "schemaVersion": SCHEMA_VERSION,
        "generatedAt": generated_at,
        "referenceTitles": [],
        "categories": {
            "distance": [
                {key: distance[key] for key in ("id", "titleZh", "titleEn", "durationZh", "durationEn")}
                for distance in DISTANCES
            ],
            "scene": [
                {
                    "id": scene["id"],
                    "titleZh": scene["titleZh"],
                    "titleEn": scene["titleEn"],
                    "intentZh": scene["intentZh"],
                    "intentEn": scene["intentEn"],
                }
                for scene in SCENES
            ],
        },
        "stats": {
            "totalPlaces": len(options),
            "perDistance": dict(sorted(per_distance.items())),
            "perScene": dict(sorted(per_scene.items())),
            "perDistanceScene": {
                f"{distance['id']}/{scene['id']}": per_distance_scene[(distance["id"], scene["id"])]
                for distance in DISTANCES
                for scene in SCENES
            },
        },
        "options": options,
    }


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
            "CREATE TABLE daily_choice_place_meta (meta_key TEXT PRIMARY KEY, meta_value TEXT NOT NULL)"
        )
        db.execute(
            "CREATE INDEX idx_place_cat_ctx ON daily_choice_place_options(category_id, context_id, status, is_available)"
        )
        db.execute(
            "CREATE INDEX idx_place_sort ON daily_choice_place_options(sort_key, option_id)"
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
            "INSERT INTO daily_choice_place_meta(meta_key, meta_value) VALUES (?, ?)",
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
            INSERT INTO daily_choice_place_options (
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
    content = f"""# 去哪儿数据格式规范

## 文件

- `daily_choice_place_library.json`: 内置目的地方向库 JSON，运行时下载后导入本地 SQLite。
- `daily_choice_place_library.db`: 与 Flutter 运行时 `DailyChoicePlaceLibraryStore` schema 对齐的 SQLite 校验包。
- `FORMAT.md`: 本说明。
- `GENERATION_SUMMARY.md`: 本次生成摘要。

## 本次数据

- 生成时间: {library["generatedAt"]}
- 总目的地方向: {library["stats"]["totalPlaces"]}
- 距离层级: 出门 / 周边 / 远行
- 场景数: {len(SCENES)}
- 每个距离与场景组合: {len(SCENES[0]["places"]) * len(ANGLES)} 条

## 字段说明

每个 `options[]` 项兼容 `DailyChoiceOption`:

- `categoryId`: 距离层级，`outside` / `nearby` / `travel`。
- `contextId` / `contextIds`: 主场景与辅助场景。
- `materialsZh`: 时长、预算、同行建议、室内外和地图搜索词。
- `stepsZh`: 出门前的三步检查。
- `notesZh`: 天气、地图和替代点提醒。
- `attributes.indoor`: `yes` / `no`。
- `attributes.map_query_zh`: 可复制到地图 App 的搜索词。
- `sourceLabel`, `sourceUrl`, `references`: 固定为空，避免在 App 内展示来源背书。

## 使用边界

本库提供的是“目的地类型”和“地图搜索方向”，不是某个城市的固定 POI。用户应结合当前城市、天气、营业时间、预约和返程窗口落地。
"""
    (output_dir / "FORMAT.md").write_text(content, encoding="utf-8", newline="\n")


def write_summary(library: dict[str, Any], output_dir: Path) -> None:
    lines = [
        "# 每日决策去哪儿数据生成摘要",
        "",
        f"- 生成时间: {library['generatedAt']}",
        f"- 总目的地方向: {library['stats']['totalPlaces']}",
        f"- JSON: `{output_dir / 'daily_choice_place_library.json'}`",
        f"- SQLite: `{output_dir / 'daily_choice_place_library.db'}`",
        "",
        "## 距离分布",
        "",
    ]
    for key, count in library["stats"]["perDistance"].items():
        lines.append(f"- {key}: {count}")
    lines.extend(["", "## 场景分布", ""])
    for key, count in library["stats"]["perScene"].items():
        lines.append(f"- {key}: {count}")
    lines.extend(["", "## 距离 / 场景覆盖", ""])
    for key, count in library["stats"]["perDistanceScene"].items():
        lines.append(f"- {key}: {count}")
    lines.extend(
        [
            "",
            "## 备注",
            "",
            "- 数据只提供目的地方向、搜索词和检查清单，不在 App 内展示任何外部来源。",
            "- 每个距离 / 场景组合均有稳妥线与新鲜线，便于随机结果兼顾稳定和新鲜感。",
        ]
    )
    (output_dir / "GENERATION_SUMMARY.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8", newline="\n"
    )


def validate(library: dict[str, Any], db_path: Path) -> None:
    options = library["options"]
    ids = [item["id"] for item in options]
    if len(ids) != len(set(ids)):
        raise RuntimeError("Duplicate option ids in place dataset.")
    allowed_scene_ids = {scene["id"] for scene in SCENES}
    invalid_scene_ids = sorted(
        {
            scene_id
            for item in options
            for scene_id in item.get("contextIds", [])
            if scene_id not in allowed_scene_ids
        }
    )
    if invalid_scene_ids:
        raise RuntimeError(f"Unknown place scene ids: {invalid_scene_ids}")
    if len(options) < 600:
        raise RuntimeError(f"Place dataset is too small: {len(options)}")
    with_sources = [
        item["id"]
        for item in options
        if item.get("sourceLabel") or item.get("sourceUrl") or item.get("references")
    ]
    if with_sources:
        raise RuntimeError(f"Place dataset should not expose sources: {with_sources[:5]}")
    expected_per_combo = len(SCENES[0]["places"]) * len(ANGLES)
    for key, count in library["stats"]["perDistanceScene"].items():
        if count != expected_per_combo:
            raise RuntimeError(f"Unexpected coverage for {key}: {count}")
    db = sqlite3.connect(db_path)
    try:
        count = db.execute(
            "SELECT COUNT(*) FROM daily_choice_place_options WHERE status='active' AND is_available=1"
        ).fetchone()[0]
        integrity = db.execute("PRAGMA integrity_check").fetchone()[0]
    finally:
        db.close()
    if count != len(options):
        raise RuntimeError(f"SQLite row count mismatch: {count} != {len(options)}")
    if integrity != "ok":
        raise RuntimeError(f"SQLite integrity check failed: {integrity}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    library = build_library()
    json_path = args.output_dir / "daily_choice_place_library.json"
    db_path = args.output_dir / "daily_choice_place_library.db"
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
                "totalPlaces": library["stats"]["totalPlaces"],
                "sceneCount": len(SCENES),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
