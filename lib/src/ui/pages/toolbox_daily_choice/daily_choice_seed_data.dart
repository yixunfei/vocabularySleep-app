import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import '../../ui_copy.dart';
import 'daily_choice_eat_support.dart';
import 'daily_choice_models.dart';

part 'daily_choice_food_seed.dart';
part 'daily_choice_wear_seed.dart';
part 'daily_choice_place_seed.dart';
part 'daily_choice_activity_place_seed.dart';

const String cookRecipeSourceLabel = 'YunYouJun/cook recipe.csv';
const String cookRecipeSourceUrl =
    'https://github.com/YunYouJun/cook/blob/main/app/data/recipe.csv';
const String cookRecipeRawUrl =
    'https://raw.githubusercontent.com/YunYouJun/cook/main/app/data/recipe.csv';
const String cookSkillReadmeUrl =
    'https://github.com/YunYouJun/cook/blob/main/skills/cook/README.md';
const String cookSkillSpecUrl =
    'https://github.com/YunYouJun/cook/blob/main/skills/cook/SKILL.md';
const List<DailyChoiceModuleConfig> dailyChoiceModuleConfigs =
    <DailyChoiceModuleConfig>[
      DailyChoiceModuleConfig(
        id: 'eat',
        icon: Icons.restaurant_menu_rounded,
        accent: Color(0xFFE08B58),
        titleZh: '吃什么',
        titleEn: 'Eat',
        subtitleZh: '按餐段摇出今天想吃的菜。',
        subtitleEn: 'Pick a dish by meal moment.',
      ),
      DailyChoiceModuleConfig(
        id: 'wear',
        icon: Icons.checkroom_rounded,
        accent: Color(0xFF5F8F73),
        titleZh: '穿什么',
        titleEn: 'Wear',
        subtitleZh: '按温度和场景挑一套不出错的搭配。',
        subtitleEn: 'Match temperature and scene to choose an outfit.',
      ),
      DailyChoiceModuleConfig(
        id: 'go',
        icon: Icons.explore_rounded,
        accent: Color(0xFF4A8DA8),
        titleZh: '去哪儿',
        titleEn: 'Go',
        subtitleZh: '从出门、周边到远行，给自己一个方向。',
        subtitleEn: 'Choose a nearby errand, local trip, or longer escape.',
      ),
      DailyChoiceModuleConfig(
        id: 'activity',
        icon: Icons.auto_awesome_motion_rounded,
        accent: Color(0xFF8A70B5),
        titleZh: '干什么',
        titleEn: 'Do',
        subtitleZh: '先选方向，也可以让方向一起随机。',
        subtitleEn: 'Pick a direction, or randomize the direction too.',
      ),
      DailyChoiceModuleConfig(
        id: 'assistant',
        icon: Icons.functions_rounded,
        accent: Color(0xFFB8793C),
        titleZh: '决策助手',
        titleEn: 'Decision',
        subtitleZh: '用概率、期望和因子权重把纠结摊开。',
        subtitleEn: 'Use probability, expected value, and factor weights.',
      ),
    ];
const DailyChoiceCategory allMealCategory = DailyChoiceCategory(
  id: 'all',
  icon: Icons.grid_view_rounded,
  titleZh: '全部餐段',
  titleEn: 'All meals',
  subtitleZh: '不按时间收口，直接从完整候选池随机',
  subtitleEn: 'Use the full recipe pool without time-of-day narrowing',
);
const List<DailyChoiceCategory> mealCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'breakfast',
    icon: Icons.wb_sunny_rounded,
    titleZh: '早饭',
    titleEn: 'Breakfast',
    subtitleZh: '轻量、暖胃、快手',
    subtitleEn: 'Light, warm, fast',
  ),
  DailyChoiceCategory(
    id: 'lunch',
    icon: Icons.rice_bowl_rounded,
    titleZh: '午餐',
    titleEn: 'Lunch',
    subtitleZh: '主食明确，能量够',
    subtitleEn: 'Filling and steady',
  ),
  DailyChoiceCategory(
    id: 'dinner',
    icon: Icons.dinner_dining_rounded,
    titleZh: '晚餐',
    titleEn: 'Dinner',
    subtitleZh: '热菜、汤和下饭菜',
    subtitleEn: 'Warm dishes and soups',
  ),
  DailyChoiceCategory(
    id: 'tea',
    icon: Icons.local_cafe_rounded,
    titleZh: '下午茶',
    titleEn: 'Tea',
    subtitleZh: '点心、小食、甜口',
    subtitleEn: 'Snacks and sweets',
  ),
  DailyChoiceCategory(
    id: 'night',
    icon: Icons.nightlight_round,
    titleZh: '宵夜',
    titleEn: 'Late snack',
    subtitleZh: '少油、少折腾',
    subtitleEn: 'Low effort, not too heavy',
  ),
];
const List<DailyChoiceCategory> eatMealFilterCategories = <DailyChoiceCategory>[
  allMealCategory,
  ...mealCategories,
];
const List<DailyChoiceCategory> cookToolCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'all',
    icon: Icons.grid_view_rounded,
    titleZh: '全部厨具',
    titleEn: 'All tools',
    subtitleZh: '不限制厨具',
    subtitleEn: 'No tool limit',
  ),
  DailyChoiceCategory(
    id: 'pot',
    icon: Icons.soup_kitchen_rounded,
    titleZh: '一口大锅',
    titleEn: 'Pot',
    subtitleZh: '炒、煮、炖都能做',
    subtitleEn: 'Pan and pot recipes',
  ),
  DailyChoiceCategory(
    id: 'rice_cooker',
    icon: Icons.rice_bowl_rounded,
    titleZh: '电饭煲',
    titleEn: 'Rice cooker',
    subtitleZh: '一锅出，省心稳',
    subtitleEn: 'One-pot cooker dishes',
  ),
  DailyChoiceCategory(
    id: 'microwave',
    icon: Icons.microwave_rounded,
    titleZh: '微波炉',
    titleEn: 'Microwave',
    subtitleZh: '快手低门槛',
    subtitleEn: 'Fast and low effort',
  ),
  DailyChoiceCategory(
    id: 'air_fryer',
    icon: Icons.air_rounded,
    titleZh: '空气炸锅',
    titleEn: 'Air fryer',
    subtitleZh: '省翻炒，易上手',
    subtitleEn: 'Crisp with less tending',
  ),
  DailyChoiceCategory(
    id: 'oven',
    icon: Icons.local_fire_department_rounded,
    titleZh: '烤箱',
    titleEn: 'Oven',
    subtitleZh: '适合烘烤和批量做',
    subtitleEn: 'Bake and roast batches',
  ),
];
const List<DailyChoiceTraitGroup> eatTraitGroups = <DailyChoiceTraitGroup>[
  DailyChoiceTraitGroup(
    id: eatAttributeType,
    icon: Icons.ramen_dining_rounded,
    titleZh: '做法与菜型',
    titleEn: 'Dish type',
    subtitleZh: '按汤、炒、拌、烧、饭面、甜品等收口',
    subtitleEn: 'Filter by soup, stir-fry, cold dish, rice, noodles, and more',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'cold_dish',
        titleZh: '凉拌',
        titleEn: 'Cold dish',
        icon: Icons.eco_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'soup',
        titleZh: '汤羹',
        titleEn: 'Soup',
        icon: Icons.soup_kitchen_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'stir_fry',
        titleZh: '炒菜',
        titleEn: 'Stir-fry',
        icon: Icons.local_fire_department_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'braise',
        titleZh: '烧焖',
        titleEn: 'Braise',
        icon: Icons.whatshot_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'stew',
        titleZh: '炖煲',
        titleEn: 'Stew',
        icon: Icons.coffee_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'steam',
        titleZh: '蒸制',
        titleEn: 'Steam',
        icon: Icons.water_drop_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'pan_fry',
        titleZh: '煎制',
        titleEn: 'Pan-fry',
        icon: Icons.egg_alt_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'deep_fry',
        titleZh: '炸物',
        titleEn: 'Deep-fry',
        icon: Icons.bakery_dining_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'bake',
        titleZh: '烘烤',
        titleEn: 'Bake',
        icon: Icons.outdoor_grill_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'rice',
        titleZh: '饭粥类',
        titleEn: 'Rice',
        icon: Icons.rice_bowl_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'noodle',
        titleZh: '面食类',
        titleEn: 'Noodles',
        icon: Icons.ramen_dining_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'dessert',
        titleZh: '甜品点心',
        titleEn: 'Dessert',
        icon: Icons.cake_rounded,
      ),
    ],
  ),
  DailyChoiceTraitGroup(
    id: eatAttributeProfile,
    icon: Icons.set_meal_rounded,
    titleZh: '荤素结构',
    titleEn: 'Profile',
    subtitleZh: '按素菜、荤菜、荤素搭配、主食型收口',
    subtitleEn: 'Filter by vegetarian, meat-based, mixed, or staple',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: eatProfileVegetarian,
        titleZh: '偏素',
        titleEn: 'Vegetarian',
        icon: Icons.spa_rounded,
      ),
      DailyChoiceTraitOption(
        id: eatProfileMeatBased,
        titleZh: '偏荤',
        titleEn: 'Meat-based',
        icon: Icons.set_meal_rounded,
      ),
      DailyChoiceTraitOption(
        id: eatProfileMixed,
        titleZh: '荤素搭配',
        titleEn: 'Mixed',
        icon: Icons.dinner_dining_rounded,
      ),
      DailyChoiceTraitOption(
        id: eatProfileStaple,
        titleZh: '主食型',
        titleEn: 'Staple',
        icon: Icons.lunch_dining_rounded,
      ),
      DailyChoiceTraitOption(
        id: eatProfileDessert,
        titleZh: '甜口',
        titleEn: 'Dessert',
        icon: Icons.icecream_rounded,
      ),
    ],
  ),
];
const DailyChoiceTraitGroup eatContainsTraitGroup = DailyChoiceTraitGroup(
  id: eatAttributeContains,
  icon: Icons.report_gmailerrorred_rounded,
  titleZh: '常见忌口与过敏原',
  titleEn: 'Avoid / allergens',
  subtitleZh: '保留最高频的快速排除项，其余口味放到自定义忌口里添加',
  subtitleEn: 'Keep the common quick avoids and add personal ones below',
  options: <DailyChoiceTraitOption>[
    DailyChoiceTraitOption(
      id: 'cilantro',
      titleZh: '香菜',
      titleEn: 'Cilantro',
      icon: Icons.local_florist_rounded,
    ),
    DailyChoiceTraitOption(
      id: 'seafood',
      titleZh: '海鲜',
      titleEn: 'Seafood',
      icon: Icons.phishing_rounded,
    ),
    DailyChoiceTraitOption(
      id: eatContainsPeanutNut,
      titleZh: '花生坚果',
      titleEn: 'Peanut / nut',
      icon: Icons.spa_rounded,
    ),
    DailyChoiceTraitOption(
      id: 'alcohol',
      titleZh: '酒精',
      titleEn: 'Alcohol',
      icon: Icons.no_drinks_rounded,
    ),
    DailyChoiceTraitOption(
      id: 'spicy',
      titleZh: '辣椒',
      titleEn: 'Chili',
      icon: Icons.local_fire_department_rounded,
    ),
  ],
);
final List<DailyChoiceTraitGroup> eatManagerTraitGroups =
    <String>{eatAttributeType, eatAttributeProfile}
        .map((id) => eatTraitGroupById(id))
        .whereType<DailyChoiceTraitGroup>()
        .toList(growable: false);
const List<DailyChoiceCategory> temperatureCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'freezing',
    icon: Icons.ac_unit_rounded,
    titleZh: '严寒',
    titleEn: 'Freezing',
    subtitleZh: '0°C 以下',
    subtitleEn: 'Below 0°C',
  ),
  DailyChoiceCategory(
    id: 'cold',
    icon: Icons.severe_cold_rounded,
    titleZh: '寒冷',
    titleEn: 'Cold',
    subtitleZh: '-5°C 到 10°C',
    subtitleEn: '-5°C to 10°C',
  ),
  DailyChoiceCategory(
    id: 'cool',
    icon: Icons.cloud_queue_rounded,
    titleZh: '凉爽',
    titleEn: 'Cool',
    subtitleZh: '10°C 到 15°C',
    subtitleEn: '10°C to 15°C',
  ),
  DailyChoiceCategory(
    id: 'mild',
    icon: Icons.filter_vintage_rounded,
    titleZh: '温和',
    titleEn: 'Mild',
    subtitleZh: '15°C 到 25°C',
    subtitleEn: '15°C to 25°C',
  ),
  DailyChoiceCategory(
    id: 'warm',
    icon: Icons.wb_sunny_outlined,
    titleZh: '微热',
    titleEn: 'Warm',
    subtitleZh: '25°C 到 30°C',
    subtitleEn: '25°C to 30°C',
  ),
  DailyChoiceCategory(
    id: 'hot',
    icon: Icons.wb_sunny_rounded,
    titleZh: '炎热',
    titleEn: 'Hot',
    subtitleZh: '30°C 到 35°C',
    subtitleEn: '30°C to 35°C',
  ),
  DailyChoiceCategory(
    id: 'extreme_hot',
    icon: Icons.local_fire_department_rounded,
    titleZh: '酷暑',
    titleEn: 'Extreme heat',
    subtitleZh: '35°C 以上',
    subtitleEn: 'Above 35°C',
  ),
];
const List<DailyChoiceCategory> wearSceneCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'commute',
    icon: Icons.work_rounded,
    titleZh: '通勤',
    titleEn: 'Commute',
    subtitleZh: '得体、耐坐、易打理',
    subtitleEn: 'Polished and practical',
  ),
  DailyChoiceCategory(
    id: 'casual',
    icon: Icons.weekend_rounded,
    titleZh: '日常',
    titleEn: 'Casual',
    subtitleZh: '舒服、松弛、不费力',
    subtitleEn: 'Comfortable and easy',
  ),
  DailyChoiceCategory(
    id: 'business',
    icon: Icons.business_center_rounded,
    titleZh: '正式',
    titleEn: 'Business',
    subtitleZh: '轮廓清楚，颜色克制',
    subtitleEn: 'Structured and restrained',
  ),
  DailyChoiceCategory(
    id: 'date',
    icon: Icons.favorite_rounded,
    titleZh: '约会',
    titleEn: 'Date',
    subtitleZh: '柔和、有记忆点',
    subtitleEn: 'Soft with one highlight',
  ),
  DailyChoiceCategory(
    id: 'exercise',
    icon: Icons.directions_run_rounded,
    titleZh: '运动',
    titleEn: 'Exercise',
    subtitleZh: '透气、可活动',
    subtitleEn: 'Breathable and mobile',
  ),
  DailyChoiceCategory(
    id: 'rain',
    icon: Icons.umbrella_rounded,
    titleZh: '雨天',
    titleEn: 'Rain',
    subtitleZh: '防滑、快干、轻外层',
    subtitleEn: 'Grippy, quick-dry, layered',
  ),
];
const List<DailyChoiceTraitGroup> wearTraitGroups = <DailyChoiceTraitGroup>[
  DailyChoiceTraitGroup(
    id: 'style',
    icon: Icons.style_rounded,
    titleZh: '风格',
    titleEn: 'Style',
    subtitleZh: '这个搭配整体给人的气质方向',
    subtitleEn: 'How the outfit reads at a glance',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'minimal',
        titleZh: '极简基础',
        titleEn: 'Minimal',
        icon: Icons.checkroom_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'polished',
        titleZh: '利落通勤',
        titleEn: 'Polished',
        icon: Icons.work_outline_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'soft',
        titleZh: '温柔轻熟',
        titleEn: 'Soft',
        icon: Icons.favorite_border_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'relaxed',
        titleZh: '松弛休闲',
        titleEn: 'Relaxed',
        icon: Icons.weekend_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'sporty',
        titleZh: '运动机能',
        titleEn: 'Sporty',
        icon: Icons.fitness_center_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'retro',
        titleZh: '复古文艺',
        titleEn: 'Retro',
        icon: Icons.history_edu_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'street',
        titleZh: '街头潮感',
        titleEn: 'Street',
        icon: Icons.flash_on_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'outdoor',
        titleZh: '户外防护',
        titleEn: 'Outdoor',
        icon: Icons.terrain_rounded,
      ),
    ],
  ),
  DailyChoiceTraitGroup(
    id: 'silhouette',
    icon: Icons.straighten_rounded,
    titleZh: '版型',
    titleEn: 'Silhouette',
    subtitleZh: '记录这套更偏修身、直筒、宽松还是层次',
    subtitleEn: 'Capture the shape and proportion',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'clean',
        titleZh: '干净利落',
        titleEn: 'Clean',
        icon: Icons.crop_3_2_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'waist_defined',
        titleZh: '强调腰线',
        titleEn: 'Waist-defined',
        icon: Icons.face_retouching_natural_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'straight',
        titleZh: '直筒修长',
        titleEn: 'Straight',
        icon: Icons.view_column_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'relaxed',
        titleZh: '宽松舒展',
        titleEn: 'Relaxed fit',
        icon: Icons.open_in_full_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'drapey',
        titleZh: '垂感流动',
        titleEn: 'Drapey',
        icon: Icons.waterfall_chart_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'layered',
        titleZh: '叠穿层次',
        titleEn: 'Layered',
        icon: Icons.layers_rounded,
      ),
    ],
  ),
  DailyChoiceTraitGroup(
    id: 'key_piece',
    icon: Icons.category_rounded,
    titleZh: '样式类型',
    titleEn: 'Key pieces',
    subtitleZh: '用来描述这套搭配最重要的核心单品',
    subtitleEn: 'The main clothing types carrying the look',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'shirt',
        titleZh: '衬衫 / Polo',
        titleEn: 'Shirt / Polo',
        icon: Icons.badge_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'knit',
        titleZh: '针织 / 毛衣',
        titleEn: 'Knit',
        icon: Icons.texture_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'tailoring',
        titleZh: '西装 / 西裤',
        titleEn: 'Tailoring',
        icon: Icons.business_center_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'coat',
        titleZh: '外套 / 大衣',
        titleEn: 'Outerwear',
        icon: Icons.checkroom_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'dress_skirt',
        titleZh: '裙装 / 连衣裙',
        titleEn: 'Dress / Skirt',
        icon: Icons.dry_cleaning_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'trousers',
        titleZh: '裤装主导',
        titleEn: 'Trousers',
        icon: Icons.accessibility_new_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'shorts',
        titleZh: '短裤 / 清凉下装',
        titleEn: 'Shorts',
        icon: Icons.wb_sunny_outlined,
      ),
      DailyChoiceTraitOption(
        id: 'athleisure',
        titleZh: '运动套组',
        titleEn: 'Athleisure',
        icon: Icons.sports_gymnastics_rounded,
      ),
    ],
  ),
  DailyChoiceTraitGroup(
    id: 'material',
    icon: Icons.grid_view_rounded,
    titleZh: '面料与触感',
    titleEn: 'Fabric',
    subtitleZh: '帮助你记住这套依赖的材质关键词',
    subtitleEn: 'Track the fabric and touch that define the outfit',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'wool',
        titleZh: '羊毛 / 呢料',
        titleEn: 'Wool',
        icon: Icons.ac_unit_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'knit',
        titleZh: '针织感',
        titleEn: 'Knit texture',
        icon: Icons.texture_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'cotton_linen',
        titleZh: '棉麻透气',
        titleEn: 'Cotton-linen',
        icon: Icons.air_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'tailoring_fabric',
        titleZh: '挺括西装料',
        titleEn: 'Tailoring fabric',
        icon: Icons.iron_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'quick_dry',
        titleZh: '速干凉感',
        titleEn: 'Quick-dry',
        icon: Icons.bolt_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'waterproof',
        titleZh: '防水防泼',
        titleEn: 'Waterproof',
        icon: Icons.umbrella_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'denim',
        titleZh: '牛仔 / 灯芯绒',
        titleEn: 'Denim / corduroy',
        icon: Icons.texture_outlined,
      ),
      DailyChoiceTraitOption(
        id: 'soft_sheen',
        titleZh: '柔软 / 光泽',
        titleEn: 'Soft / sheen',
        icon: Icons.auto_awesome_rounded,
      ),
    ],
  ),
  DailyChoiceTraitGroup(
    id: 'highlight',
    icon: Icons.auto_awesome_rounded,
    titleZh: '亮点',
    titleEn: 'Highlight',
    subtitleZh: '这套最值得被记住的点',
    subtitleEn: 'The finishing note worth remembering',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'clean_color',
        titleZh: '配色克制',
        titleEn: 'Clean palette',
        icon: Icons.palette_outlined,
      ),
      DailyChoiceTraitOption(
        id: 'color_accent',
        titleZh: '颜色提气',
        titleEn: 'Color accent',
        icon: Icons.color_lens_outlined,
      ),
      DailyChoiceTraitOption(
        id: 'texture',
        titleZh: '材质层次',
        titleEn: 'Texture contrast',
        icon: Icons.blur_on_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'proportion',
        titleZh: '比例优化',
        titleEn: 'Proportion',
        icon: Icons.height_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'accessory',
        titleZh: '配饰收口',
        titleEn: 'Accessory finish',
        icon: Icons.watch_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'weather_protection',
        titleZh: '天气防护',
        titleEn: 'Weather protection',
        icon: Icons.shield_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'sun_protection',
        titleZh: '防晒降温',
        titleEn: 'Sun protection',
        icon: Icons.beach_access_rounded,
      ),
      DailyChoiceTraitOption(
        id: 'shoe_anchor',
        titleZh: '鞋履定调',
        titleEn: 'Shoe anchor',
        icon: Icons.shopping_bag_outlined,
      ),
    ],
  ),
];
final List<DailyChoiceTraitGroup> wearManagerTraitGroups =
    <String>{'style', 'silhouette', 'key_piece'}
        .map((id) => wearTraitGroupById(id))
        .whereType<DailyChoiceTraitGroup>()
        .toList(growable: false);

DailyChoiceTraitGroup? wearTraitGroupById(String id) {
  for (final group in wearTraitGroups) {
    if (group.id == id) {
      return group;
    }
  }
  return null;
}

DailyChoiceTraitOption? wearTraitOptionById(String groupId, String optionId) {
  final group = wearTraitGroupById(groupId);
  if (group == null) {
    return null;
  }
  for (final option in group.options) {
    if (option.id == optionId) {
      return option;
    }
  }
  return null;
}

List<String> wearTraitLabels(
  AppI18n i18n,
  Map<String, List<String>> attributes, {
  List<String>? groupIds,
  int? limit,
}) {
  return _wearTraitLabelsForLanguage(
    attributes,
    useZh: AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh',
    groupIds: groupIds,
    limit: limit,
  );
}

List<String> wearTraitLabelsZh(
  Map<String, List<String>> attributes, {
  List<String>? groupIds,
  int? limit,
}) {
  return _wearTraitLabelsForLanguage(
    attributes,
    useZh: true,
    groupIds: groupIds,
    limit: limit,
  );
}

List<String> wearTraitLabelsEn(
  Map<String, List<String>> attributes, {
  List<String>? groupIds,
  int? limit,
}) {
  return _wearTraitLabelsForLanguage(
    attributes,
    useZh: false,
    groupIds: groupIds,
    limit: limit,
  );
}

List<String> wearTraitLines(AppI18n i18n, DailyChoiceOption option) {
  final lines = <String>[];
  for (final group in wearTraitGroups) {
    final labels = wearTraitLabels(
      i18n,
      option.attributes,
      groupIds: <String>[group.id],
    );
    if (labels.isEmpty) {
      continue;
    }
    lines.add(
      '${group.title(i18n)}${pickUiText(i18n, zh: '：', en: ': ')}${labels.join(pickUiText(i18n, zh: '、', en: ', '))}',
    );
  }
  return lines;
}

List<String> _wearTraitLabelsForLanguage(
  Map<String, List<String>> attributes, {
  required bool useZh,
  List<String>? groupIds,
  int? limit,
}) {
  final resolvedGroupIds = groupIds ?? wearTraitGroups.map((item) => item.id);
  final labels = <String>[];
  for (final groupId in resolvedGroupIds) {
    final values = attributes[groupId] ?? const <String>[];
    for (final value in values) {
      final option = wearTraitOptionById(groupId, value);
      if (option == null) {
        continue;
      }
      labels.add(useZh ? option.titleZh : option.titleEn);
      if (limit != null && labels.length >= limit) {
        return labels;
      }
    }
  }
  return labels;
}

DailyChoiceTraitGroup? eatTraitGroupById(String id) {
  if (eatContainsTraitGroup.id == id) {
    return eatContainsTraitGroup;
  }
  for (final group in eatTraitGroups) {
    if (group.id == id) {
      return group;
    }
  }
  return null;
}

DailyChoiceTraitOption? eatTraitOptionById(String groupId, String optionId) {
  final group = eatTraitGroupById(groupId);
  if (group == null) {
    return null;
  }
  for (final option in group.options) {
    if (option.id == optionId) {
      return option;
    }
  }
  return null;
}

List<String> eatTraitLabels(
  AppI18n i18n,
  Map<String, List<String>> attributes, {
  List<String>? groupIds,
  int? limit,
}) {
  return _eatTraitLabelsForLanguage(
    attributes,
    useZh: AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh',
    groupIds: groupIds,
    limit: limit,
  );
}

List<String> eatTraitLabelsZh(
  Map<String, List<String>> attributes, {
  List<String>? groupIds,
  int? limit,
}) {
  return _eatTraitLabelsForLanguage(
    attributes,
    useZh: true,
    groupIds: groupIds,
    limit: limit,
  );
}

List<String> eatTraitLabelsEn(
  Map<String, List<String>> attributes, {
  List<String>? groupIds,
  int? limit,
}) {
  return _eatTraitLabelsForLanguage(
    attributes,
    useZh: false,
    groupIds: groupIds,
    limit: limit,
  );
}

List<String> eatMealLabels(AppI18n i18n, DailyChoiceOption option) {
  final labels = <String>[];
  for (final mealId in eatMealIds(option)) {
    for (final category in mealCategories) {
      if (category.id == mealId) {
        labels.add(category.title(i18n));
        break;
      }
    }
  }
  return labels;
}

List<String> eatTraitLines(AppI18n i18n, DailyChoiceOption option) {
  final lines = <String>[];
  final mealLabels = eatMealLabels(i18n, option);
  if (mealLabels.isNotEmpty) {
    lines.add(
      '${pickUiText(i18n, zh: '适合餐段：', en: 'Meals: ')}${mealLabels.join(pickUiText(i18n, zh: '、', en: ', '))}',
    );
  }
  for (final group in <DailyChoiceTraitGroup>[
    ...eatTraitGroups,
    eatContainsTraitGroup,
  ]) {
    final labels = eatTraitLabels(
      i18n,
      option.attributes,
      groupIds: <String>[group.id],
    );
    if (labels.isEmpty) {
      continue;
    }
    lines.add(
      '${group.title(i18n)}${pickUiText(i18n, zh: '：', en: ': ')}${labels.join(pickUiText(i18n, zh: '、', en: ', '))}',
    );
  }
  return lines;
}

List<String> _eatTraitLabelsForLanguage(
  Map<String, List<String>> attributes, {
  required bool useZh,
  List<String>? groupIds,
  int? limit,
}) {
  final resolvedGroupIds =
      groupIds ??
      <String>[
        ...eatTraitGroups.map((item) => item.id),
        eatContainsTraitGroup.id,
      ];
  final labels = <String>[];
  for (final groupId in resolvedGroupIds) {
    final values = attributes[groupId] ?? const <String>[];
    for (final value in values) {
      final option = eatTraitOptionById(groupId, value);
      if (option == null) {
        continue;
      }
      labels.add(useZh ? option.titleZh : option.titleEn);
      if (limit != null && labels.length >= limit) {
        return labels;
      }
    }
  }
  return labels;
}

const List<DailyChoiceCategory> placeCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'outside',
    icon: Icons.door_front_door_rounded,
    titleZh: '出门',
    titleEn: 'Step out',
    subtitleZh: '半小时内完成',
    subtitleEn: 'Under 30 minutes',
  ),
  DailyChoiceCategory(
    id: 'nearby',
    icon: Icons.location_city_rounded,
    titleZh: '周边',
    titleEn: 'Nearby',
    subtitleZh: '同城半日感',
    subtitleEn: 'A local half-day',
  ),
  DailyChoiceCategory(
    id: 'travel',
    icon: Icons.train_rounded,
    titleZh: '远行',
    titleEn: 'Travel',
    subtitleZh: '需要提前规划',
    subtitleEn: 'Needs planning',
  ),
];
const DailyChoiceCategory allPlaceSceneCategory = DailyChoiceCategory(
  id: 'all',
  icon: Icons.grid_view_rounded,
  titleZh: '全部场景',
  titleEn: 'All scenes',
  subtitleZh: '先看距离，再在整组地点里随机',
  subtitleEn: 'Start from distance, then randomize across all scenes',
);
const List<DailyChoiceCategory> placeSceneCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'food',
    icon: Icons.restaurant_rounded,
    titleZh: '饮食',
    titleEn: 'Food',
    subtitleZh: '餐馆、小吃、咖啡和夜宵',
    subtitleEn: 'Meals, snacks, cafes, and late bites',
  ),
  DailyChoiceCategory(
    id: 'entertainment',
    icon: Icons.local_activity_rounded,
    titleZh: '娱乐',
    titleEn: 'Entertainment',
    subtitleZh: '电影、电玩、桌游和演出',
    subtitleEn: 'Movies, games, and live fun',
  ),
  DailyChoiceCategory(
    id: 'sports',
    icon: Icons.sports_basketball_rounded,
    titleZh: '运动',
    titleEn: 'Sports',
    subtitleZh: '球馆、健身、游泳和运动场地',
    subtitleEn: 'Gyms, courts, pools, and active venues',
  ),
  DailyChoiceCategory(
    id: 'culture',
    icon: Icons.palette_rounded,
    titleZh: '文化',
    titleEn: 'Culture',
    subtitleZh: '博物馆、美术馆、剧场和展览',
    subtitleEn: 'Museums, galleries, theaters, and exhibitions',
  ),
  DailyChoiceCategory(
    id: 'history',
    icon: Icons.account_balance_rounded,
    titleZh: '历史',
    titleEn: 'History',
    subtitleZh: '古迹、老街、遗址和旧建筑',
    subtitleEn: 'Historic streets, relics, and old architecture',
  ),
  DailyChoiceCategory(
    id: 'nature',
    icon: Icons.park_rounded,
    titleZh: '自然',
    titleEn: 'Nature',
    subtitleZh: '公园、绿道、湿地和山野',
    subtitleEn: 'Parks, greenways, wetlands, and trails',
  ),
  DailyChoiceCategory(
    id: 'study',
    icon: Icons.local_library_rounded,
    titleZh: '学习',
    titleEn: 'Study',
    subtitleZh: '图书馆、自习室、书店和安静工作点',
    subtitleEn: 'Libraries, study rooms, bookstores, and quiet work spots',
  ),
  DailyChoiceCategory(
    id: 'shopping',
    icon: Icons.shopping_bag_rounded,
    titleZh: '购物',
    titleEn: 'Shopping',
    subtitleZh: '商圈、市集、夜市和买手店',
    subtitleEn: 'Malls, markets, and shopping districts',
  ),
  DailyChoiceCategory(
    id: 'social',
    icon: Icons.groups_rounded,
    titleZh: '社交',
    titleEn: 'Social',
    subtitleZh: '聊天、聚会、桌游和轻连接',
    subtitleEn: 'Meetups, board games, and easy social time',
  ),
  DailyChoiceCategory(
    id: 'family',
    icon: Icons.family_restroom_rounded,
    titleZh: '亲子',
    titleEn: 'Family',
    subtitleZh: '亲子出游、长辈友好和多人同行',
    subtitleEn: 'Family outings and multi-age friendly places',
  ),
  DailyChoiceCategory(
    id: 'nightlife',
    icon: Icons.nightlife_rounded,
    titleZh: '夜生活',
    titleEn: 'Nightlife',
    subtitleZh: '酒吧、夜场、夜景和夜间活动',
    subtitleEn: 'Bars, night shows, views, and late activities',
  ),
  DailyChoiceCategory(
    id: 'relax',
    icon: Icons.spa_rounded,
    titleZh: '放松',
    titleEn: 'Relax',
    subtitleZh: '温泉、茶室、疗愈和慢节奏空间',
    subtitleEn: 'Hot springs, tea houses, and restorative places',
  ),
  DailyChoiceCategory(
    id: 'photo',
    icon: Icons.photo_camera_back_rounded,
    titleZh: '出片',
    titleEn: 'Photo',
    subtitleZh: '街景、机位、观景台和建筑',
    subtitleEn: 'Street scenes, viewpoints, and photo spots',
  ),
  DailyChoiceCategory(
    id: 'specialty',
    icon: Icons.explore_off_rounded,
    titleZh: '特色区域',
    titleEn: 'Special area',
    subtitleZh: '创意园、非标空间和本地特色区',
    subtitleEn: 'Creative parks and locally distinctive zones',
  ),
  DailyChoiceCategory(
    id: 'memorial',
    icon: Icons.flag_circle_rounded,
    titleZh: '纪念',
    titleEn: 'Memorial',
    subtitleZh: '纪念馆、纪念园和城市记忆空间',
    subtitleEn: 'Memorial halls, remembrance parks, and memory spaces',
  ),
];
const DailyChoiceCategory randomActivityCategory = DailyChoiceCategory(
  id: 'any',
  icon: Icons.shuffle_rounded,
  titleZh: '随机方向',
  titleEn: 'Random',
  subtitleZh: '方向也交给随机',
  subtitleEn: 'Randomize the direction too',
);
const List<DailyChoiceCategory> activityCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'move',
    icon: Icons.fitness_center_rounded,
    titleZh: '运动',
    titleEn: 'Move',
    subtitleZh: '让身体先醒来',
    subtitleEn: 'Wake up the body',
  ),
  DailyChoiceCategory(
    id: 'learn',
    icon: Icons.menu_book_rounded,
    titleZh: '学习',
    titleEn: 'Learn',
    subtitleZh: '一个小闭环',
    subtitleEn: 'One small loop',
  ),
  DailyChoiceCategory(
    id: 'outdoor',
    icon: Icons.hiking_rounded,
    titleZh: '出行',
    titleEn: 'Out',
    subtitleZh: '换一个环境',
    subtitleEn: 'Change environment',
  ),
  DailyChoiceCategory(
    id: 'home',
    icon: Icons.home_repair_service_rounded,
    titleZh: '整理',
    titleEn: 'Tidy',
    subtitleZh: '让空间轻一点',
    subtitleEn: 'Lighten the space',
  ),
  DailyChoiceCategory(
    id: 'relax',
    icon: Icons.self_improvement_rounded,
    titleZh: '放松',
    titleEn: 'Relax',
    subtitleZh: '降低刺激',
    subtitleEn: 'Lower stimulation',
  ),
  DailyChoiceCategory(
    id: 'create',
    icon: Icons.brush_rounded,
    titleZh: '创作',
    titleEn: 'Create',
    subtitleZh: '留下一个作品痕迹',
    subtitleEn: 'Leave a small artifact',
  ),
  DailyChoiceCategory(
    id: 'social',
    icon: Icons.groups_rounded,
    titleZh: '社交',
    titleEn: 'Social',
    subtitleZh: '轻量连接别人',
    subtitleEn: 'Connect lightly',
  ),
];
const List<DailyChoiceGuideModule>
cookingGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'kitchen_readiness',
    icon: Icons.countertops_rounded,
    titleZh: '入厨前基准',
    titleEn: 'Kitchen baseline',
    subtitleZh: '先确定人、时间、厨具和风险，再决定菜式',
    subtitleEn: 'Confirm time, tools, people, and risks before choosing a dish',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.timer_rounded,
        titleZh: '先问三件事：多久、几人、能洗几口锅',
        titleEn: 'Ask time, servings, and cleanup first',
        bodyZh:
            '一道菜是否适合今天，不只看想不想吃，还要看可用时间、份量和收拾成本。工作日优先 30 分钟内、一锅或一盘能收口的菜；多人吃饭先确定主食、主菜、蔬菜和汤水的分工，避免最后全是重口味或全是淀粉。',
        bodyEn:
            'A suitable dish depends on time, servings, and cleanup. For busy days, prefer meals that finish within 30 minutes and use one pan or one tray. For a group meal, balance starch, protein, vegetables, and liquid before cooking.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.inventory_2_rounded,
        titleZh: '盘点材料时先分主料、配料、底味',
        titleEn: 'Group ingredients by role',
        bodyZh:
            '主料决定菜名和饱腹感，配料负责颜色、口感和体积，底味来自葱姜蒜、洋葱、番茄、香菇、骨汤、酱油或香料。缺一味小配料时可以替代；缺主料或底味时，最好改菜，不要硬凑。',
        bodyEn:
            'Separate main ingredients, supporting ingredients, and flavor bases. Small supporting ingredients can often be swapped, but if the main ingredient or core flavor base is missing, choosing another dish is usually safer.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.warning_amber_rounded,
        titleZh: '先排除不能吃，再追求好吃',
        titleEn: 'Remove unsafe options before optimizing flavor',
        bodyZh: '过敏、孕期、婴幼儿、老人吞咽能力、慢病控盐控糖等情况都要先单独判断。上桌前仍要看具体食材、调味、熟度和烹调工具是否混用。',
        bodyEn:
            'Allergies, pregnancy, infants, swallowing ability, and medical diets come first. Always check ingredients, seasoning, doneness, and tool separation before serving.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'shopping_check',
    icon: Icons.shopping_basket_rounded,
    titleZh: '采购与验收',
    titleEn: 'Shopping and inspection',
    subtitleZh: '买得对，比临场补救更可靠',
    subtitleEn: 'Good ingredients reduce the need for rescue work',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.eco_rounded,
        titleZh: '蔬果看新鲜度，也看适合怎么做',
        titleEn: 'Judge produce by freshness and cooking use',
        bodyZh:
            '叶菜看挺度、切口和黄烂；根茎看表皮、重量和发芽霉斑；瓜果看香气、弹性和伤口。水分足、口感脆的适合快炒凉拌，成熟度高、出汁多的更适合炖、烩、酱汁或做汤。',
        bodyEn:
            'For produce, check firmness, cut surfaces, bruising, sprouts, mold, aroma, and weight. Crisp produce suits quick cooking and cold dishes; riper or juicier produce works better in stews, sauces, and soups.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.set_meal_rounded,
        titleZh: '肉鱼海鲜先看气味、弹性和冷链',
        titleEn: 'Check smell, texture, and cold chain',
        bodyZh:
            '鲜肉应有正常肉香和弹性，鱼眼清亮、鱼鳃颜色正常、表面不粘手，贝类和虾蟹要看活力和异味。买回家后尽快冷藏或冷冻，生食级和熟食、凉拌菜必须分开放置。',
        bodyEn:
            'Meat should smell clean and feel elastic. Fish should have clear eyes, normal gills, and non-sticky skin. Shellfish and crustaceans need freshness and no off smell. Refrigerate quickly and keep raw seafood away from ready-to-eat foods.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.grain_rounded,
        titleZh: '干货、米面、调味料看保存状态',
        titleEn: 'Inspect dry goods and seasoning storage',
        bodyZh:
            '米面豆类怕潮、虫和霉味，坚果芝麻怕哈喇味，香料怕受潮失香，油脂怕光照和高温。采购时少量高频比一次囤太久更稳，开封后用密封、避光、标日期来降低翻车率。',
        bodyEn:
            'Dry grains, beans, nuts, spices, and oils are sensitive to moisture, rancidity, light, and heat. Buy in practical quantities, seal after opening, avoid light, and date containers.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'washing',
    icon: Icons.water_drop_rounded,
    titleZh: '清洗与去污',
    titleEn: 'Washing and cleaning',
    subtitleZh: '冲、泡、刷、剥、沥，要按食材结构选择',
    subtitleEn:
        'Choose rinsing, soaking, brushing, peeling, and draining by structure',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.spa_rounded,
        titleZh: '叶菜逐层冲洗，先去泥沙再沥水',
        titleEn: 'Rinse leafy vegetables layer by layer',
        bodyZh:
            '包叶菜先剥外层和损伤叶，再把叶片掰开冲洗；小叶菜和香草先挑掉黄烂，再用流动水分散冲洗。短时浸泡可作为补充，但不要把久泡当成唯一方法，沥干水分才利于快炒、凉拌和保存。',
        bodyEn:
            'Remove damaged outer leaves, separate layers, rinse under running water, and drain well. Short soaking may help, but long soaking alone is not a reliable cleaning method and makes cooking watery.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.brush_rounded,
        titleZh: '根茎瓜果先刷表皮，再决定去不去皮',
        titleEn: 'Brush firm skins before peeling decisions',
        bodyZh:
            '土豆、胡萝卜、莲藕、南瓜、黄瓜等先刷掉泥沙和表面附着物，再按菜式决定去皮、削伤口或保留皮香。表面凹凸多、缝隙多的食材要特别注意沟槽，切开后再冲容易把水和杂质带进切面。',
        bodyEn:
            'Brush root vegetables and firm-skinned produce before cutting. Pay attention to grooves and rough surfaces, then decide whether to peel based on the dish.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.science_rounded,
        titleZh: '盐、醋、小苏打和清洁剂不是万能答案',
        titleEn: 'Salt, vinegar, baking soda, and produce wash are not magic',
        bodyZh:
            '家庭清洗的基本盘仍然是流动水、分层冲洗、必要时刷洗和去除外层。盐水、醋水、小苏打或清洁剂可能改变口感、残留气味或需要额外冲净，不能代替认真冲洗，也不应制造“洗过就绝对安全”的错觉。',
        bodyEn:
            'The baseline remains running water, separation, brushing when needed, and removing outer layers. Salt, vinegar, baking soda, or detergents can affect texture or leave residue and do not replace careful rinsing.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'knife_work',
    icon: Icons.content_cut_rounded,
    titleZh: '刀工与切配',
    titleEn: 'Knife work and prep cuts',
    subtitleZh: '刀工的核心不是炫技，而是受热一致',
    subtitleEn: 'Knife work is about even cooking, not showing off',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.grid_on_rounded,
        titleZh: '形状服务烹调方法',
        titleEn: 'Shape should serve the cooking method',
        bodyZh:
            '丝、片、丁、块、段、滚刀块各有用途：快炒要薄和均匀，炖煮可稍大，煎烤要接触面稳定，凉拌要入口方便。新手先做到厚薄接近，比追求花刀更重要。',
        bodyEn:
            'Julienne, slices, dice, chunks, segments, and roll cuts should match the cooking method. Quick cooking needs thin and even cuts; braising can use larger pieces; pan-frying needs stable contact surfaces.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.restaurant_rounded,
        titleZh: '肉类先判断纹理和用途',
        titleEn: 'Read meat grain and purpose first',
        bodyZh:
            '炒肉丝、肉片通常逆纹切更嫩，炖肉可以保留较大块，鸡胸适合薄片或小丁，带骨肉要沿骨和筋膜下刀。冷冻到半硬状态更容易切薄片，但解冻后不可长时间放在室温等待。',
        bodyEn:
            'For stir-fry, cut across the grain for tenderness. Braises can use larger pieces. Chicken breast works well as thin slices or dice. Semi-frozen meat is easier to slice, but do not leave thawed meat at room temperature for long.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.health_and_safety_rounded,
        titleZh: '案板顺序决定安全边界',
        titleEn: 'Cutting-board order controls food safety',
        bodyZh:
            '推荐顺序是即食食材、蔬果、熟食、生肉、生海鲜；条件允许时生熟案板分开。若只能用一块案板，处理生肉海鲜后要洗手、清洁刀板和台面，再接触熟食或凉拌菜。',
        bodyEn:
            'Prepare ready-to-eat items, produce, cooked foods, raw meat, and raw seafood in a safe order. Separate boards are best; if using one board, clean hands, knife, board, and counter after raw meat or seafood.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'mise_en_place',
    icon: Icons.fact_check_rounded,
    titleZh: '备料顺序',
    titleEn: 'Mise en place',
    subtitleZh: '开火前把不可逆和等待步骤排好',
    subtitleEn: 'Arrange irreversible and waiting steps before heat',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.schedule_rounded,
        titleZh: '先启动长等待：浸泡、腌制、预热、煮饭',
        titleEn: 'Start long waits first',
        bodyZh:
            '豆类、干货、米饭、烤箱预热、空气炸锅预热、肉类腌制、烧水焯菜都可能占用整顿饭的时间轴。先让等待步骤开始，再切配和调酱，整体节奏会轻很多。',
        bodyEn:
            'Soaking, marinating, preheating, rice cooking, and boiling water can dominate the timeline. Start them first, then cut and mix sauces.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.bento_rounded,
        titleZh: '调味和容器提前到手边',
        titleEn: 'Place seasoning and containers within reach',
        bodyZh:
            '炒、煎、炸、勾芡和收汁的窗口很短，开火后再找盐、盘子、漏勺和淀粉水，很容易过火。把常用调味、小碗、盘子、锅盖、厨房纸和夹子提前放好，是稳定出品的基本功。',
        bodyEn:
            'Stir-frying, pan-frying, frying, thickening, and reducing move fast. Put seasoning, bowls, plates, lids, paper towels, and tongs within reach before heat.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.layers_rounded,
        titleZh: '按下锅时间分盘，不按食材类别乱堆',
        titleEn: 'Group prep by cooking order',
        bodyZh:
            '同一类蔬菜也可能下锅时间不同：胡萝卜、土豆、豆角先入，青菜叶、葱花、香菜后放；肉片先滑散，易熟海鲜后下。按时间分盘，能避免一锅里同时出现夹生和过熟。',
        bodyEn:
            'Group ingredients by when they enter the pan, not merely by type. Firm vegetables go early, tender leaves and herbs go late, and seafood often needs less time than meat.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'seasoning',
    icon: Icons.soup_kitchen_rounded,
    titleZh: '调味基准',
    titleEn: 'Seasoning baseline',
    subtitleZh: '咸、酸、甜、鲜、香、辣要分层建立',
    subtitleEn: 'Build salt, acid, sweetness, umami, aroma, and heat in layers',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.tune_rounded,
        titleZh: '先有底味，再做尾调',
        titleEn: 'Build base seasoning, then finish',
        bodyZh:
            '盐、生抽、酱、汤底负责底味，醋、柠檬、糖、胡椒、香油、葱蒜、香草负责收口。汤、炖、焖和酱汁类不要一开始压得太咸，因为水分蒸发后味道会继续变重。',
        bodyEn:
            'Salt, soy sauce, pastes, and stock form the base. Acid, sugar, pepper, sesame oil, aromatics, and herbs finish the dish. Avoid heavy early seasoning in soups, braises, and sauces because reduction concentrates flavor.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.balance_rounded,
        titleZh: '咸了补体积，淡了补层次',
        titleEn: 'Fix salt with volume and blandness with layers',
        bodyZh:
            '过咸优先加无盐主料、水、汤或淀粉类稀释，不要只靠糖遮盖；太淡则先判断是盐不够、香气不足、酸度不足还是油脂不足。少量多次，比一次猛加更容易救。',
        bodyEn:
            'For over-salting, add unsalted volume, water, stock, or starch rather than only sugar. For blandness, identify whether salt, aroma, acid, or fat is missing and adjust gradually.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.local_florist_rounded,
        titleZh: '香气有先后：爆香、同煮、出锅香不同',
        titleEn: 'Aromatics have timing',
        bodyZh:
            '葱姜蒜、洋葱、香料适合低到中火出香；香菜、葱花、柠檬皮、香油、部分辣椒油更适合出锅前后加入。香气材料放错时间，轻则无味，重则焦苦。',
        bodyEn:
            'Scallion, ginger, garlic, onion, and spices usually bloom over low to medium heat. Herbs, scallion greens, citrus zest, sesame oil, and some chili oils work better near the end.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'heat_pan',
    icon: Icons.local_fire_department_rounded,
    titleZh: '火候与锅具',
    titleEn: 'Heat and cookware',
    subtitleZh: '看状态，不迷信固定分钟数',
    subtitleEn: 'Read the food state instead of trusting minutes blindly',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.thermostat_rounded,
        titleZh: '预热不是把锅烧到冒烟',
        titleEn: 'Preheating does not mean smoking hot',
        bodyZh:
            '煎炒需要锅体热起来，但大量白烟通常说明油温过高或锅中残留物在焦化。判断预热可看油纹、听轻微滋声、试少量食材边缘反应；不粘锅尤其避免长时间空烧。',
        bodyEn:
            'Preheating means the pan is ready, not smoking aggressively. Watch oil movement, listen for a gentle sizzle, and test a small piece. Avoid prolonged dry heating, especially with nonstick pans.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.air_rounded,
        titleZh: '锅气来自高温、少量、干爽和快速翻动',
        titleEn: 'Wok aroma needs heat, small batches, dryness, and speed',
        bodyZh: '快炒想香，食材要沥干，锅中不要堆太满，调味汁不要一次倒太多。家庭灶火力有限时，宁可分批炒，也不要一锅挤到变成煮菜。',
        bodyEn:
            'Good stir-fry aroma needs dry ingredients, enough heat, small batches, and fast movement. On a home stove, cook in batches rather than crowding the pan into steaming.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.visibility_rounded,
        titleZh: '状态信号比时间更可靠',
        titleEn: 'State signals beat fixed timing',
        bodyZh:
            '看颜色、出水、回缩、定型、冒泡、油水分离、筷子穿透感和中心温度。不同锅具、分量、火力和食材含水量都会改变分钟数，菜谱时间只能当起点。',
        bodyEn:
            'Watch color, moisture release, shrinkage, structure, bubbling, separation, texture, and center temperature. Pan, batch size, stove power, and water content all change timing.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'foundation_techniques',
    icon: Icons.science_rounded,
    titleZh: '基础处理技法',
    titleEn: 'Foundation techniques',
    subtitleZh: '焯水、腌制、上浆、勾芡、收汁要知道目的',
    subtitleEn: 'Know why you blanch, marinate, velvet, thicken, and reduce',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.water_rounded,
        titleZh: '焯水用于去味、定色、缩短后续时间',
        titleEn: 'Blanching removes odor, sets color, and shortens cooking',
        bodyZh:
            '绿叶菜短焯后过凉可保色，排骨和部分内脏冷水下锅更利于带出血沫，豆角、笋、草酸高或有涩味的食材常需要预处理。焯水后要沥干，否则炒菜会变水。',
        bodyEn:
            'Blanch leafy greens briefly for color, start bones or offal in cold water for scum removal, and pre-treat beans, shoots, or astringent ingredients when needed. Drain well before stir-frying.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.spa_rounded,
        titleZh: '腌制和上浆是控水、入味、保护口感',
        titleEn: 'Marinating and velveting control water, flavor, and texture',
        bodyZh:
            '肉片先少量盐或酱油打底，再按需要加淀粉、蛋清或油形成保护层。腌制不是越久越好，薄片快炒通常十几分钟即可，酸性材料太久会改变肉质。',
        bodyEn:
            'Use a little salt or soy sauce first, then starch, egg white, or oil if needed for a protective layer. Longer is not always better; thin stir-fry slices often need only minutes, and acid can change texture.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.opacity_rounded,
        titleZh: '勾芡和收汁都在管理水分',
        titleEn: 'Thickening and reducing are water management',
        bodyZh:
            '水淀粉要先搅匀，薄芡适合包裹，厚芡适合挂汁；收汁靠蒸发浓缩，火太小会拖时间，火太大容易焦底。先尝味再收汁，因为收浓后咸甜酸都会变明显。',
        bodyEn:
            'Stir starch slurry before adding it. Light thickening coats, heavy thickening clings. Reduction concentrates flavor, so taste before reducing and control heat to avoid scorching.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'cooking_methods',
    icon: Icons.restaurant_menu_rounded,
    titleZh: '常用烹调法',
    titleEn: 'Core cooking methods',
    subtitleZh: '炒、煮、炖、蒸、煎、炸、烤、凉拌各有关键点',
    subtitleEn: 'Each method has a few controlling variables',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.whatshot_rounded,
        titleZh: '炒和煎：控制水分与接触面',
        titleEn: 'Stir-fry and pan-fry control moisture and contact',
        bodyZh:
            '炒菜食材要干爽、下锅顺序清楚、调味汁少量快入；煎东西要给表面定型时间，不要一直翻。粘锅时先判断锅温、油量、水分和是否太早移动。',
        bodyEn:
            'For stir-fry, keep ingredients dry, order clear, and sauce limited. For pan-fry, allow the surface to set before moving. Sticking often comes from temperature, oil, moisture, or moving too early.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.soup_kitchen_rounded,
        titleZh: '煮、炖、焖、煲：液体决定质地',
        titleEn: 'Boil, stew, braise, and simmer depend on liquid',
        bodyZh: '清汤要稳火少搅，浓汤可靠煸炒、乳化或淀粉质食材增加厚度；炖肉要让胶原和纤维慢慢转化，焖菜则要控制液体刚好够熟而不糊底。',
        bodyEn:
            'Clear soups need gentle heat and little agitation. Thick soups rely on browning, emulsification, or starchy ingredients. Braises need time for collagen and fibers; covered simmering needs just enough liquid.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.cloud_rounded,
        titleZh: '蒸、炸、凉拌：一个看蒸汽，一个看油温，一个看沥干',
        titleEn: 'Steam, fry, and cold dishes each have one main variable',
        bodyZh:
            '蒸菜要水开上汽后计时，盘中不要积太多水；炸物要分清低温浸熟、中温定型、高温复炸；凉拌的关键是食材熟度、沥水和最后调味，不要让菜泡在水里。',
        bodyEn:
            'For steaming, count after strong steam appears and avoid excess plate water. Frying uses different oil temperatures for cooking, setting, and crisping. Cold dishes need proper doneness, draining, and final seasoning.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'grains_baking',
    icon: Icons.bakery_dining_rounded,
    titleZh: '米面与烘焙',
    titleEn: 'Grains, noodles, and baking',
    subtitleZh: '主食和烘焙更依赖比例、吸水和温度',
    subtitleEn:
        'Staples and baking depend heavily on ratios, hydration, and temperature',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.rice_bowl_rounded,
        titleZh: '米饭、粥、焖饭先看米水比和吸水',
        titleEn: 'Rice, congee, and rice cooker meals start with water ratio',
        bodyZh:
            '新米、陈米、糙米、糯米吸水不同；焖饭还会从蔬菜、肉和调味汁得到额外水分。做电饭煲饭时，先保证米熟，再追求配料丰富，油脂和酱汁不要多到影响米粒吸水。',
        bodyEn:
            'Fresh rice, aged rice, brown rice, and glutinous rice absorb water differently. Rice cooker meals also get liquid from vegetables, meat, and sauce. Get the rice cooked first, then increase complexity.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.ramen_dining_rounded,
        titleZh: '面条粉类重视出锅时机',
        titleEn: 'Noodles and starches depend on timing',
        bodyZh:
            '面条离火后仍会继续吸水变软，炒面和拌面通常要比直接吃略早捞；粉丝、米粉、年糕、意面都要按粗细和后续烹调留余地，避免先煮到满熟再二次加热。',
        bodyEn:
            'Noodles keep absorbing water after draining. For stir-fry or tossed noodles, drain slightly early. Vermicelli, rice noodles, rice cakes, and pasta all need room for later cooking.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.scale_rounded,
        titleZh: '烘焙先称量，再谈手感',
        titleEn: 'For baking, measure before relying on feel',
        bodyZh:
            '面包、蛋糕、派塔、饼干和许多甜点对克重、温度、搅拌程度和冷却时间敏感。先量好粉、液体、糖、油脂、鸡蛋和膨松剂；烤箱温差大时，用状态和探针温度辅助判断。',
        bodyEn:
            'Bread, cake, tart, cookies, and desserts are sensitive to weight, temperature, mixing, and cooling. Measure dry goods, liquids, sugar, fat, eggs, and leaveners first, then judge by state and temperature.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'storage_reheat',
    icon: Icons.kitchen_rounded,
    titleZh: '保存与复热',
    titleEn: 'Storage and reheating',
    subtitleZh: '做完后的处理决定下一顿是否省心',
    subtitleEn: 'Post-cooking handling determines how easy the next meal is',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.ac_unit_rounded,
        titleZh: '熟食尽快降温分装',
        titleEn: 'Cool cooked food quickly and portion it',
        bodyZh:
            '大量热汤热饭不要整锅长时间放在室温，分浅盒、留缝散热、降温后冷藏更稳。生熟、荤素、汤汁和干爽菜分开装，能减少串味、出水和复热失败。',
        bodyEn:
            'Do not leave a large hot pot at room temperature for long. Portion into shallow containers, let steam escape, then refrigerate. Separate raw and cooked items, strong flavors, liquids, and dry dishes.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.microwave_rounded,
        titleZh: '复热要补水或补脆，不是一律加热到烫',
        titleEn: 'Reheat by restoring moisture or crispness',
        bodyZh: '米饭、面条、炖菜常需要少量水或汤；炸物、烤物更适合烤箱或空气炸锅恢复表面；绿叶菜和海鲜不耐反复加热，最好少量做、尽快吃。',
        bodyEn:
            'Rice, noodles, and stews often need a little water or stock. Fried and baked foods regain texture better in an oven or air fryer. Leafy greens and seafood do not tolerate repeated reheating well.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.recycling_rounded,
        titleZh: '剩菜复用先换形态',
        titleEn: 'Reuse leftovers by changing form',
        bodyZh:
            '剩米饭适合炒饭、粥、饭团；炖肉可变浇头、夹馍、面码；烤蔬菜可进沙拉、浓汤或意面。复用时补新鲜蔬菜和酸香，会比单纯反复加热更好吃。',
        bodyEn:
            'Leftover rice can become fried rice, congee, or rice balls. Braised meat can top noodles or sandwiches. Roasted vegetables can become salad, soup, or pasta. Add freshness and acid when reusing leftovers.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'troubleshooting',
    icon: Icons.build_circle_rounded,
    titleZh: '翻车排查',
    titleEn: 'Troubleshooting',
    subtitleZh: '先找变量，再决定补救方式',
    subtitleEn: 'Find the variable before choosing the rescue',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.water_damage_rounded,
        titleZh: '出水太多：通常是盐早、锅挤、火弱或没沥干',
        titleEn:
            'Too watery usually means early salt, crowding, weak heat, or poor draining',
        bodyZh:
            '蔬菜出水严重时可先盛出多余汤汁再回锅收口，或改成汤、烩、盖饭。下次减少提前撒盐，食材沥干，分批下锅，并把调味汁留到食材断生后再加。',
        bodyEn:
            'If a dish gets watery, remove excess liquid and reduce, or turn it into soup, stew, or rice topping. Next time, salt later, drain better, cook in batches, and add sauce after the food starts cooking through.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.flash_on_rounded,
        titleZh: '外焦内生：火太急或尺寸不匹配',
        titleEn: 'Burnt outside and raw inside means heat or size mismatch',
        bodyZh: '先降火、加盖、少量补水或转烤箱完成内部熟化。下次把食材切小或切薄，厚块先煎定型再低温焖熟，不要全程大火硬冲。',
        bodyEn:
            'Lower heat, cover, add a little liquid, or finish in the oven. Next time, cut smaller or thinner, sear for structure, then finish gently instead of using high heat throughout.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.sentiment_dissatisfied_rounded,
        titleZh: '肉老、菜软、味闷：多半是时间和顺序错了',
        titleEn:
            'Tough meat, limp vegetables, and dull flavor often come from timing',
        bodyZh:
            '瘦肉过久会柴，海鲜过火会缩，绿叶菜久煮会黄软，香草久煮会失香。先把易老、易熟、易失香的材料后置，复杂菜拆成预处理、主烹调、出锅香三段更稳。',
        bodyEn:
            'Lean meat dries out, seafood shrinks, leafy greens turn dull, and herbs lose aroma when overcooked. Put delicate items later and split complex dishes into prep, main cooking, and finishing aroma.',
      ),
    ],
  ),
];
List<DailyChoiceGuideModule> buildCookingGuideModules(
  List<String> referenceTitles,
) {
  final bibliography = referenceTitles.isEmpty
      ? const <String>[
          'YunYouJun/cook',
          '小菜谱一定要学会的家常简易刀工',
          '正確洗菜，擺脫農藥陰影',
          '专业烘焙 第3版',
          '日本料理制作大全',
          '博古斯学院法式西餐烹饪宝典',
          '法国蓝带西餐烹饪宝典',
          'The Italian Pantry',
          'Nourishing Recipes for Elderly',
        ]
      : referenceTitles
            .map(_cleanCookingReferenceTitle)
            .where((title) => title.isNotEmpty)
            .toSet()
            .toList(growable: false);
  return <DailyChoiceGuideModule>[
    ...cookingGuideModules,
    DailyChoiceGuideModule(
      id: 'references',
      icon: Icons.menu_book_rounded,
      titleZh: '参考与延伸阅读',
      titleEn: 'References',
      subtitleZh: '本指南只提炼通用原则，具体菜式仍以可靠菜谱和实际食材为准',
      subtitleEn:
          'This guide distills general principles; use reliable recipes for specific dishes',
      entries: <DailyChoiceGuideEntry>[
        ...bibliography.map(
          (title) => DailyChoiceGuideEntry(
            icon: Icons.book_rounded,
            titleZh: title,
            titleEn: title,
            bodyZh: '可作为继续查阅的烹饪资料来源。本指南只做归纳，不逐字复写原书或原始资料内容。',
            bodyEn:
                'A source for further reading. This guide summarizes cooking principles instead of reproducing the original material.',
          ),
        ),
      ],
    ),
  ];
}

String _cleanCookingReferenceTitle(String rawTitle) {
  final title = rawTitle.trim();
  if (title.isEmpty) {
    return '';
  }
  if (title.startsWith('YunYouJun/cook')) {
    return 'YunYouJun/cook';
  }
  return title;
}

const List<DailyChoiceGuideModule> wearGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'foundation',
    icon: Icons.checkroom_rounded,
    titleZh: '基础与风格',
    titleEn: 'Foundation',
    subtitleZh: '先把常穿公式和自己的风格方向收清楚',
    subtitleEn: 'Start from repeatable basics and your real style direction',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.layers_clear_rounded,
        titleZh: '基础款是衣橱的主语，不是无聊的替身',
        titleEn: 'Basics are the sentence, not a boring placeholder',
        bodyZh:
            '从《基本穿搭》《风格的练习》《搭配其实很好玩 2》整理出来的共同点很明确：真正高频、耐用的穿搭，不是靠一次次追新，而是靠白衬衫、干净针织、直筒裤、轻外套、稳妥鞋履这些能反复重组的主力单品。先把七成衣橱交给稳定基础款，剩下三成再留给个性、颜色和记忆点，随机推荐命中率才会高。',
        bodyEn:
            'The strongest shared lesson is that repeatable outfits come from stable core pieces first, then a smaller layer of personality and accents.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.psychology_alt_rounded,
        titleZh: '风格不是标签堆叠，而是你真实的日常比例',
        titleEn: 'Style is the ratio of your real life',
        bodyZh:
            '《我的风格小黑皮书》《风格的练习》都强调，风格先回答“你常去哪里、想呈现什么、身体想穿什么”。如果你大多数时间在通勤、开会、久坐和短途出行之间切换，那么利落通勤、极简基础通常比强戏剧化更好用；如果你常在校园、咖啡店、散步和周末慢生活之间切换，松弛休闲和温柔轻熟会更自然。先承认生活半径，风格才不会悬空。',
        bodyEn:
            'Style works best when it reflects your actual routines, social settings, and what your body is willing to wear all day.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'fit_ratio',
    icon: Icons.straighten_rounded,
    titleZh: '版型与比例',
    titleEn: 'Fit & Ratio',
    subtitleZh: '合身、长度和腰线，比“流行元素”更先决定体面度',
    subtitleEn: 'Fit, length, and waist definition matter before trend detail',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.crop_portrait_rounded,
        titleZh: '先看肩线、裤长、后背，再看正面',
        titleEn: 'Check shoulders, hem, and back view first',
        bodyZh:
            '《穿衣的基本》与《职场穿衣的终极搭配》都把“合身”放在第一位。肩线掉太多、裤脚堆太厚、后背绷紧或松垮，都会让再贵的衣服也显得没精神。挑衣服时先看能不能走路、坐下、抬手，再看镜子里的正面效果；正面漂亮但活动受限的衣服，实际穿着频率往往会很低。',
        bodyEn:
            'Fit starts with movement, shoulder line, hem length, and how the garment behaves from the back, not only the front mirror angle.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.height_rounded,
        titleZh: '上下量感要分工，不要同时抢戏',
        titleEn: 'Let top and bottom split the visual work',
        bodyZh:
            '常见的稳妥公式是：宽松上装配利落下装，修身上装配有量感下装；想显精神，就让腰线、裤线或鞋面承担收口任务。《搭配其实很好玩 2》里对小个子和比例的提醒也很实用：高腰、短外套、纵向线条、露脚踝或清晰鞋口，都比一味堆层数更有效。',
        bodyEn:
            'Reliable proportion comes from letting either the top or the bottom carry volume while the other side stays clearer and cleaner.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'scene',
    icon: Icons.event_seat_rounded,
    titleZh: '场合与职场',
    titleEn: 'Scene & Work',
    subtitleZh: '先判断时间、地点、角色和今天的日程',
    subtitleEn: 'Judge time, place, role, and today’s agenda first',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.work_history_rounded,
        titleZh: '职场穿衣先看行业、职位、日程三件事',
        titleEn: 'For work, start with industry, role, and agenda',
        bodyZh:
            '《上班穿什么》和《绅士时尚》都强调 TPO 与职业角色。创意行业、技术岗位、行政支持、管理层、对外见客户的穿法不该完全一样。问自己三个问题：今天会不会久坐？会不会频繁见人？会不会在室内外来回切换？答案会决定你该不该加外套、穿不穿明显配饰、鞋子要不要更正式。',
        bodyEn:
            'Workwear choices should react to industry, seniority, and what the day actually demands, especially meetings, sitting time, and indoor-outdoor switching.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.favorite_outline_rounded,
        titleZh: '约会、周末、运动和雨天各有第一优先级',
        titleEn: 'Every scene has its first priority',
        bodyZh:
            '约会先守“柔和 + 一个记忆点”；周末先守“舒服 + 不邋遢”；运动先守“排汗 + 活动范围”；雨天先守“防滑 + 快干 + 不拖地”。这类场景里，体感和行动便利要先于拍照效果。真正好看的搭配，是你不需要一直分神去照顾它。',
        bodyEn:
            'Dates, weekends, exercise, and rain all have different first priorities. Comfort and mobility should be solved before aesthetics start competing.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'color_material',
    icon: Icons.palette_rounded,
    titleZh: '色彩与材质',
    titleEn: 'Color & Material',
    subtitleZh: '颜色控制节奏，材质决定高级感和季节感',
    subtitleEn: 'Color sets rhythm while fabric sets polish and seasonality',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.color_lens_outlined,
        titleZh: '先用中性色稳住，再决定要不要加亮点',
        titleEn: 'Anchor with neutrals before adding color',
        bodyZh:
            '从《服装色彩搭配》《风格的练习》和阿秋秋的色彩经验里，可以归纳出一条实用线：先用黑、白、灰、海军蓝、卡其、深棕这类中性色打底，再加一个小面积提气色。安全做法是一主色、一中性色、一亮点；想再大胆一些，也先从低饱和配色、同色系深浅变化和“黑色带彩色”开始练习。',
        bodyEn:
            'A practical route into color is to stabilize the outfit with neutrals first, then add a small accent instead of starting with several loud tones.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.blur_on_rounded,
        titleZh: '材质会直接决定“看起来贵不贵、轻不轻松”',
        titleEn: 'Fabric decides whether the look feels polished or cheap',
        bodyZh:
            '《穿衣的基本》《上班穿什么》都反复提醒，挺括面料更容易撑起职业感，柔软材质更容易制造亲和感，垂感面料更适合热天和约会，棉麻更适合微热到炎热，羊毛与针织则更适合冷天层次。配色一样时，材质差异往往比颜色本身更能拉开质感差距。',
        bodyEn:
            'Structure, drape, and texture often change the perceived quality of an outfit more than color alone.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'season_weather',
    icon: Icons.wb_sunny_rounded,
    titleZh: '季节与天气',
    titleEn: 'Season & Weather',
    subtitleZh: '温度、体感、风雨和温差要一起看',
    subtitleEn: 'Read temperature, feels-like, rain, wind, and swing together',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.layers_rounded,
        titleZh: '三层原则比“一件扛到底”更稳',
        titleEn: 'The three-layer rule beats one heavy item',
        bodyZh:
            '低温和换季场景里，最实用的公式还是内层舒适排汗、中层负责保暖、外层负责挡风防雨。体感温度和昼夜温差比气温数字更接近日常真实感受，所以页面默认会按天气体感推荐档位，但你仍可以手动覆盖。要点不是穿得最多，而是让你随时能加、能减、能走动。',
        bodyEn:
            'Layering is mainly about adjustability: stay comfortable now, but keep room to react to wind, rain, and daily temperature swing.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.umbrella_rounded,
        titleZh: '高温、低温、降雨各有收尾检查表',
        titleEn: 'Heat, cold, and rain each need a final checklist',
        bodyZh:
            '高温重点看防晒、补水、面料散热和空调房温差；低温重点看颈部、手部、脚踝和鞋底抓地；雨天重点看裤脚长度、鞋面、防滑和备用干物。出门前只花半分钟做这一步，往往比临时补救更省心。',
        bodyEn:
            'For heat, check ventilation and sun protection. For cold, cover the small exposed zones. For rain, control hem length, traction, and backup dry items.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'accessories',
    icon: Icons.watch_rounded,
    titleZh: '鞋履与配饰',
    titleEn: 'Shoes & Accessories',
    subtitleZh: '鞋和配件是收口，不是抢主题',
    subtitleEn: 'Shoes and accessories finish the look instead of stealing it',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.shopping_bag_outlined,
        titleZh: '鞋子决定完成度，包和腰带负责统一',
        titleEn: 'Shoes finish the outfit, bag and belt unify it',
        bodyZh:
            '《基本穿搭》里把鞋子看作最能暴露穿搭功底的单品，这很值得借用。通勤和正式场景先保证鞋面整洁、线条清楚、适合久走；包、腰带、表和首饰则尽量配合同一语气，不需要每样都出彩，只要整体不散。想省力时，优先把鞋和包选稳。',
        bodyEn:
            'Shoes often reveal the most about whether an outfit feels intentional, while bag and belt keep the whole look speaking in one tone.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.auto_fix_high_rounded,
        titleZh: '配饰要么补气色，要么补比例，不要只是“多一个”',
        titleEn: 'Accessories should fix color or proportion',
        bodyZh:
            '围巾、耳饰、项链、帽子、方巾、腕表最适合承担两种任务：一是给脸部和上半身提气，二是把视线拉向你想强调的位置。若一套搭配已经有明显图案、鲜艳颜色或复杂面料，配饰就减法处理；若整体过于平，可以用一件小配件做记忆点。',
        bodyEn:
            'Accessories work best when they either lift color near the face or guide the eye toward the area you want to emphasize.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'wardrobe',
    icon: Icons.inventory_2_rounded,
    titleZh: '衣橱整理与练习',
    titleEn: 'Wardrobe Practice',
    subtitleZh: '衣橱越清楚，随机推荐越接近你真会穿的答案',
    subtitleEn: 'A clearer wardrobe makes recommendations more realistic',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.cleaning_services_rounded,
        titleZh: '按常穿频率和场景保留，不按愧疚感保留',
        titleEn: 'Keep by frequency and scene, not by guilt',
        bodyZh:
            '《基本穿搭》《职场穿衣的终极搭配》都强调质胜于量。整理衣橱时，先留下最合身、最常穿、最好搭、最能代表你当前生活的核心款；低频、难打理、总需要“等一个合适场合”的衣服，要么转入备用，要么尽快清理。你在管理页里标注的风格、版型和样式类型，本质上就是帮自己建立这套衣橱索引。',
        bodyEn:
            'Edit the closet around what fits, gets worn, and actually supports your current life. The guided traits in management are there to make that inventory visible.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.photo_camera_back_rounded,
        titleZh: '在家练穿搭，比出门前临时拼更有效',
        titleEn: 'Practice at home before needing the outfit',
        bodyZh:
            '《风格的练习》给了一个特别实用的提醒：不要把所有试错都放在出门前五分钟。可以把高频场景的几套组合提前试好、拍照、记录优缺点，再把最常穿的搭配录入管理页。久而久之，页面里的随机结果会越来越接近你的个人衣橱，而不是一组抽象建议。',
        bodyEn:
            'Testing combinations ahead of time builds a personal outfit library, which makes both daily choice and wardrobe management dramatically more useful.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'expansion',
    icon: Icons.auto_awesome_rounded,
    titleZh: '扩展边界',
    titleEn: 'Expansion',
    subtitleZh: '先把人能用的一版做稳，再给 AI 和购物能力留接口',
    subtitleEn:
        'Ship a human-useful core first, then leave space for AI and shopping',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.face_retouching_natural_rounded,
        titleZh: '当前先做可解释的衣橱特征层',
        titleEn: 'Start with an explainable wardrobe trait layer',
        bodyZh:
            '本轮的重点是把风格、版型、样式类型、面料和亮点做成可编辑、可筛选、可展示的结构化层。这样做的价值在于：今天能先服务随机推荐和个人管理，未来如果接入照片识别、真实数字人试穿或衣橱拍照建档，也能直接复用这层结构而不用推倒重来。',
        bodyEn:
            'The structured trait layer is useful now for filtering and editing, and later can become the bridge for photo parsing, avatar try-on, or wardrobe recognition.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.shopping_cart_checkout_rounded,
        titleZh: '购物与 AI 试穿暂不接第三方，但接口方向已明确',
        titleEn: 'AI try-on and shopping stay deferred for now',
        bodyZh:
            '后续如要扩展，可在不改动当前随机逻辑的前提下，补充三条支线：一是基于用户衣橱特征的单品缺口分析，二是真实数字人或照片试穿，三是把相似风格映射到购物网站候选。本轮只保留数据和注释边界，不引入任何外部服务依赖。',
        bodyEn:
            'Future work can branch into wardrobe gap analysis, AI try-on, and shopping suggestions, but this release deliberately stops at the data boundary.',
      ),
    ],
  ),
];
const List<DailyChoiceGuideModule> placeGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'scope',
    icon: Icons.timer_rounded,
    titleZh: '先定范围',
    titleEn: 'Set the scope first',
    subtitleZh: '先把时间和半径收口，再谈目的地',
    subtitleEn: 'Bound the time and radius before choosing the place',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.door_front_door_rounded,
        titleZh: '出门、周边、远行不是强度，而是边界',
        titleEn: 'Step out, nearby, and travel are boundaries',
        bodyZh:
            '“出门”适合 30 分钟到 1 小时的低门槛切换，“周边”适合同城半日，“远行”则意味着你愿意为这次外出留出完整行程。先确定你愿意给这件事多少时间，地点才不会无限膨胀。',
        bodyEn:
            'Step out is for a low-friction 30-to-60-minute change, nearby fits a local half day, and travel means you are willing to turn the outing into a full plan.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.filter_alt_rounded,
        titleZh: '先选距离，再选场景',
        titleEn: 'Distance first, scene second',
        bodyZh:
            '当纠结来自“想出门但不知道去哪儿”，先用距离把范围缩到可执行，再用饮食、娱乐、运动、文化等场景把结果拉向你当前真正需要的体验。',
        bodyEn:
            'When the problem is “I want to go out but do not know where,” reduce the radius first, then use scenes like food, sports, or culture to shape the mood you actually need.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'matching',
    icon: Icons.interests_rounded,
    titleZh: '按场景匹配',
    titleEn: 'Match by scene',
    subtitleZh: '先认清你是想吃、想玩、想动，还是想安静',
    subtitleEn: 'Name the kind of outing you actually want',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.psychology_rounded,
        titleZh: '问题不是去哪儿，而是现在缺什么',
        titleEn: 'The issue is what you lack right now',
        bodyZh:
            '饮食类解决的是“补一顿”与“找个能坐下来的地方”，娱乐类解决新鲜感，运动类解决身体激活，学习类解决专注环境，放松类则解决恢复感。先识别缺口，比盲抽地名更准。',
        bodyEn:
            'Food solves hunger or the need for a place to sit, entertainment gives novelty, sports wake up the body, study gives focus, and relax scenes restore energy.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.group_work_rounded,
        titleZh: '同行对象会改写最优解',
        titleEn: 'Who goes with you changes the best answer',
        bodyZh:
            '一个人适合低沟通成本的点位，两三个人适合能边走边聊或能临时换计划的地点，带长辈和小孩则优先看无障碍、洗手间、休息位和就餐衔接。',
        bodyEn:
            'Solo trips work best with low-communication destinations, small groups need flexible places, and multi-age outings should prioritize accessibility, seating, and restroom support.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'map',
    icon: Icons.map_rounded,
    titleZh: '地图与检索',
    titleEn: 'Maps and search',
    subtitleZh: '先看营业、通勤、预约和替代点',
    subtitleEn: 'Check opening hours, transit, booking, and backups',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.search_rounded,
        titleZh: '先搜关键词，不要先认一家店',
        titleEn: 'Search by keyword before committing to one place',
        bodyZh:
            '这一版详情页会给出地图搜索词。先用关键词搜一组候选，再按评分、步行时间、营业时间和是否容易收尾来选，比一开始就锁死某一家更稳。',
        bodyEn:
            'This version gives you a map query. Search the keyword first, then choose by rating, transit time, opening hours, and how easy the outing is to close out.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.alt_route_rounded,
        titleZh: '永远准备一个替代点',
        titleEn: 'Always keep a backup',
        bodyZh:
            '排队、满场、闭馆、下雨和临时取消都很常见。真正降低决策压力的方法，是在同一片区域预留一个替代点，而不是让整次外出因为一个点失败而中断。',
        bodyEn:
            'Queues, closures, rain, or sold-out tickets happen often. A backup in the same area keeps the outing alive instead of collapsing the whole plan.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'weather_budget',
    icon: Icons.wb_sunny_rounded,
    titleZh: '天气、预算与安全',
    titleEn: 'Weather, budget, and safety',
    subtitleZh: '天气和返程可行性永远比“理想感”更重要',
    subtitleEn: 'Practicality matters more than the idealized destination',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.thunderstorm_rounded,
        titleZh: '户外和夜间点先看天气',
        titleEn: 'Outdoor and night outings start with weather',
        bodyZh: '公园、滨水、街景、夜景和远行类地点对天气很敏感。遇到高温、降雨、大风或夜间温差，优先准备替代的室内点，而不是硬扛。',
        bodyEn:
            'Parks, waterfronts, street scenes, night views, and longer trips are weather-sensitive. In heat, rain, or wind, prepare an indoor fallback instead of forcing it.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.account_balance_wallet_rounded,
        titleZh: '预算要把路费一起算进去',
        titleEn: 'Budget means transit cost too',
        bodyZh: '真正的出门成本不只是门票和餐费，还包括打车、停车、地铁换乘、预约损耗和返程时间。远行类地点尤其要把“回得来”一起算清楚。',
        bodyEn:
            'The real cost includes transit, parking, transfers, booking friction, and the return trip, not only the ticket or meal itself.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'pack',
    icon: Icons.backpack_rounded,
    titleZh: '最小准备包',
    titleEn: 'Minimal prep pack',
    subtitleZh: '少带，但别漏掉关键物件',
    subtitleEn: 'Carry little, but do not forget the essentials',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.battery_charging_full_rounded,
        titleZh: '短出门看电量，远行看补给',
        titleEn: 'Short trips need battery, long trips need backup',
        bodyZh: '出门和周边优先确保手机、电量、钥匙、纸巾和水；远行则再加证件、药品、充电线、雨具和返程所需的轻补给。',
        bodyEn:
            'For step-out and nearby trips, phone, battery, keys, tissue, and water usually cover it. For travel, add ID, meds, a cable, weather gear, and small return-trip supplies.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.history_toggle_off_rounded,
        titleZh: '到点就收，不把随机外出拖成负担',
        titleEn: 'End on time instead of dragging it out',
        bodyZh:
            '随机工具的意义是把你推出去，不是把一天压得更满。达到时间盒、完成主要体验、身体开始疲惫，或者返程窗口快关闭时，就可以安心收口。',
        bodyEn:
            'The tool is meant to get you moving, not overload the day. Once the time box is reached or the main experience is done, it is okay to close the outing cleanly.',
      ),
    ],
  ),
  DailyChoiceGuideModule(
    id: 'expansion',
    icon: Icons.travel_explore_rounded,
    titleZh: '后续扩展边界',
    titleEn: 'Expansion path',
    subtitleZh: '为地图、定位和开放地理数据预留接口',
    subtitleEn: 'Leave room for maps, coarse location, and open geo data',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.copy_rounded,
        titleZh: '当前先做地图搜索词闭环',
        titleEn: 'Start with a map-query loop',
        bodyZh: '本轮先做到“场景筛选 -> 随机地点 -> 详情 -> 复制地图搜索词”。这个链路足够稳定，也最容易在移动端落地。',
        bodyEn:
            'This release focuses on the stable loop of scene filter, random place, details, and copying a map query, which lands well on mobile.',
      ),
      DailyChoiceGuideEntry(
        icon: Icons.public_rounded,
        titleZh: '后续可接入粗略定位与开放地理数据',
        titleEn: 'Later versions can add coarse location and open geo data',
        bodyZh:
            '后续若单独推进，可按权限边界接入粗略定位、开放地图 POI 或系统地图拉起，把“附近 / 同城 / 远行”的候选从静态模板进一步变成动态检索结果。',
        bodyEn:
            'A later dedicated pass can add coarse location, open-map POIs, or system map launch so the same scene taxonomy can drive live search results.',
      ),
    ],
  ),
];
const List<DailyChoiceGuideEntry>
activityGuideEntries = <DailyChoiceGuideEntry>[
  DailyChoiceGuideEntry(
    icon: Icons.flag_rounded,
    titleZh: '动作要小到能开始',
    titleEn: 'Make it startable',
    bodyZh: '如果某件事听起来太大，就把它改成 5 分钟版本。每日抉择的价值是破冰，不是替你安排完整人生。',
    bodyEn:
        'If an activity feels too large, shrink it to a five-minute version. Daily choice breaks the ice; it does not schedule your whole life.',
  ),
  DailyChoiceGuideEntry(
    icon: Icons.repeat_rounded,
    titleZh: '先做一轮，再决定继续',
    titleEn: 'One round first',
    bodyZh: '运动、学习、整理都先做一轮。完成后再选择继续、换方向或停止，避免一开始就被计划压住。',
    bodyEn:
        'Move, study, or tidy for one round first. After that, choose continue, switch, or stop.',
  ),
  DailyChoiceGuideEntry(
    icon: Icons.psychology_rounded,
    titleZh: '方向也可以随机',
    titleEn: 'Randomize direction too',
    bodyZh: '当你连大方向都不想选时，用“随机方向”。先让系统给一个方向，再从该方向里摇出具体动作。',
    bodyEn:
        'When even the direction feels hard, use Random. Let the tool pick the direction and then a concrete action.',
  ),
];
const List<DailyChoiceGuideEntry>
decisionGuideEntries = <DailyChoiceGuideEntry>[
  DailyChoiceGuideEntry(
    icon: Icons.casino_rounded,
    titleZh: '均匀随机',
    titleEn: 'Uniform random',
    bodyZh: '所有选项权重相同，适合低风险、差别不大的选择。它不是科学最优，只是快速结束犹豫。',
    bodyEn:
        'Every option has equal weight. Good for low-risk choices where options are similar.',
  ),
  DailyChoiceGuideEntry(
    icon: Icons.functions_rounded,
    titleZh: '期望加权',
    titleEn: 'Expected value',
    bodyZh: '用“概率 × 收益 - 风险 - 成本”粗略排序。适合把模糊直觉摊开，但输入值仍然来自你的判断。',
    bodyEn:
        'Ranks by probability times value minus risk and cost. Useful for exposing assumptions, not for guaranteed truth.',
  ),
  DailyChoiceGuideEntry(
    icon: Icons.account_tree_rounded,
    titleZh: '联合概率',
    titleEn: 'Joint probability',
    bodyZh: '当一个结果依赖多个条件同时成立时，把概率相乘会更保守。第一版只做透明计算，后续可扩展贝叶斯更新。',
    bodyEn:
        'When an outcome depends on several events, multiplying probabilities gives a more conservative view. Later versions can add Bayesian updates.',
  ),
  DailyChoiceGuideEntry(
    icon: Icons.show_chart_rounded,
    titleZh: '建模扩展',
    titleEn: 'Model expansion',
    bodyZh: '回归、相关因子和多目标优化会放到独立扩展层，避免把复杂数学模型混进基础 UI。',
    bodyEn:
        'Regression, correlation factors, and multi-objective optimization belong in a later extension layer.',
  ),
];
List<DailyChoiceOption> buildDailyChoiceFallbackEatOptions() {
  return List<DailyChoiceOption>.unmodifiable(_eatOptions);
}

List<DailyChoiceOption> buildDailyChoiceStaticSeedOptions() {
  return <DailyChoiceOption>[
    ..._wearOptions,
    ..._placeOptions,
    ..._activityOptions,
  ];
}

List<DailyChoiceOption> buildDailyChoiceSeedOptions() {
  return <DailyChoiceOption>[
    ...buildDailyChoiceFallbackEatOptions(),
    ...buildDailyChoiceStaticSeedOptions(),
  ];
}

DailyChoiceOption _choice({
  required String id,
  required String moduleId,
  required String categoryId,
  required String titleZh,
  required String titleEn,
  required String subtitleZh,
  required String subtitleEn,
  required String detailsZh,
  required String detailsEn,
  String? contextId,
  List<String> contextIds = const <String>[],
  List<String> materialsZh = const <String>[],
  List<String> materialsEn = const <String>[],
  List<String> stepsZh = const <String>[],
  List<String> stepsEn = const <String>[],
  List<String> notesZh = const <String>[],
  List<String> notesEn = const <String>[],
  List<String> tagsZh = const <String>[],
  List<String> tagsEn = const <String>[],
  Map<String, List<String>> attributes = const <String, List<String>>{},
  String? sourceLabel,
  String? sourceUrl,
  List<DailyChoiceReferenceLink> references =
      const <DailyChoiceReferenceLink>[],
}) {
  return DailyChoiceOption(
    id: id,
    moduleId: moduleId,
    categoryId: categoryId,
    contextId: contextId,
    contextIds: contextIds,
    titleZh: titleZh,
    titleEn: titleEn,
    subtitleZh: subtitleZh,
    subtitleEn: subtitleEn,
    detailsZh: detailsZh,
    detailsEn: detailsEn,
    materialsZh: materialsZh,
    materialsEn: materialsEn,
    stepsZh: stepsZh,
    stepsEn: stepsEn,
    notesZh: notesZh,
    notesEn: notesEn,
    tagsZh: tagsZh,
    tagsEn: tagsEn,
    attributes: attributes,
    sourceLabel: sourceLabel,
    sourceUrl: sourceUrl,
    references: references,
  );
}
