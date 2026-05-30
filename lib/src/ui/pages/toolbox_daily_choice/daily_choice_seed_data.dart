import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import 'daily_choice_eat_support.dart';
import 'daily_choice_models.dart';

part 'daily_choice_food_seed.dart';
part 'daily_choice_place_seed.dart';

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
    titleKey: 'inline.plan295.daily_choice.eat.d63f09b7b74f',
    subtitleKey: 'inline.plan295.daily_choice.pick_a_dish_by_meal_moment.dc6743f32eac'),
      DailyChoiceModuleConfig(
        id: 'wear',
        icon: Icons.checkroom_rounded,
        accent: Color(0xFF5F8F73),
    titleKey: 'inline.plan295.daily_choice.wear.ff9423ba7740',
    subtitleKey: 'inline.plan295.daily_choice.match_temperature_and_scene_to_choos.e8e972383462'),
      DailyChoiceModuleConfig(
        id: 'go',
        icon: Icons.explore_rounded,
        accent: Color(0xFF4A8DA8),
    titleKey: 'inline.plan295.daily_choice.go.f0266169957c',
    subtitleKey: 'inline.plan295.daily_choice.choose_a_nearby_errand_local_trip_or.0c19561bbff5'),
      DailyChoiceModuleConfig(
        id: 'activity',
        icon: Icons.auto_awesome_motion_rounded,
        accent: Color(0xFF8A70B5),
    titleKey: 'inline.plan295.daily_choice.do.dc2ba8bc3572',
    subtitleKey: 'inline.plan295.daily_choice.pick_a_direction_or_randomize_the_di.b725c483ba75'),
      DailyChoiceModuleConfig(
        id: 'custom_random',
        icon: Icons.shuffle_rounded,
        accent: Color(0xFF607C8F),
    titleKey: 'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.random_assistant_a5a3a1',
    subtitleKey: 'inline.plan295.daily_choice.enter_your_own_options_and_draw_by_w.1e1e02b49eac'),
      DailyChoiceModuleConfig(
        id: 'assistant',
        icon: Icons.functions_rounded,
        accent: Color(0xFFB8793C),
    titleKey: 'inline.plan295.daily_choice.decision.7067fb1a0cb9',
    subtitleKey: 'inline.plan295.daily_choice.use_probability_expected_value_and_f.48e823c1aef0'),
    ];
const DailyChoiceCategory allMealCategory = DailyChoiceCategory(
  id: 'all',
  icon: Icons.grid_view_rounded,
    titleKey: 'inline.plan295.daily_choice.all_meals.26a4b15988dd',
    subtitleKey: 'inline.plan295.daily_choice.choose_freely_across_meals.18390de685aa');
const List<DailyChoiceCategory> mealCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'breakfast',
    icon: Icons.wb_sunny_rounded,
    titleKey: 'inline.plan295.daily_choice.breakfast.177e9b91b63c',
    subtitleKey: 'inline.plan295.daily_choice.light_warm_fast.6ee056be5549'),
  DailyChoiceCategory(
    id: 'lunch',
    icon: Icons.rice_bowl_rounded,
    titleKey: 'inline.plan295.daily_choice.lunch.387f9531b13a',
    subtitleKey: 'inline.plan295.daily_choice.filling_and_steady.cf76e1936554'),
  DailyChoiceCategory(
    id: 'dinner',
    icon: Icons.dinner_dining_rounded,
    titleKey: 'inline.plan295.daily_choice.dinner.72700bcfd0b3',
    subtitleKey: 'inline.plan295.daily_choice.warm_dishes_and_soups.ce67858a9d47'),
  DailyChoiceCategory(
    id: 'tea',
    icon: Icons.local_cafe_rounded,
    titleKey: 'inline.plan295.daily_choice.tea.07e46701e17e',
    subtitleKey: 'inline.plan295.daily_choice.snacks_and_sweets.a279894e2e25'),
  DailyChoiceCategory(
    id: 'night',
    icon: Icons.nightlight_round,
    titleKey: 'inline.plan295.daily_choice.late_snack.c89a28c49b75',
    subtitleKey: 'inline.plan295.daily_choice.low_effort_not_too_heavy.b08caa8863bf'),
];
const List<DailyChoiceCategory> eatMealFilterCategories = <DailyChoiceCategory>[
  allMealCategory,
  ...mealCategories,
];
const List<DailyChoiceCategory> cookToolCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'all',
    icon: Icons.grid_view_rounded,
    titleKey: 'inline.plan295.daily_choice.all_tools.ef0a23dbad13',
    subtitleKey: 'inline.plan295.daily_choice.no_tool_limit.05fe9c591df4'),
  DailyChoiceCategory(
    id: 'pot',
    icon: Icons.soup_kitchen_rounded,
    titleKey: 'inline.plan295.daily_choice.pot.9ad74bdea9f9',
    subtitleKey: 'inline.plan295.daily_choice.pan_and_pot_recipes.fdf573ed589a'),
  DailyChoiceCategory(
    id: 'rice_cooker',
    icon: Icons.rice_bowl_rounded,
    titleKey: 'inline.plan295.daily_choice.rice_cooker.e4f8c556db64',
    subtitleKey: 'inline.plan295.daily_choice.one_pot_cooker_dishes.b4de51be0220'),
  DailyChoiceCategory(
    id: 'microwave',
    icon: Icons.microwave_rounded,
    titleKey: 'inline.plan295.daily_choice.microwave.bc3fc4975427',
    subtitleKey: 'inline.plan295.daily_choice.fast_and_low_effort.48439cd8906f'),
  DailyChoiceCategory(
    id: 'air_fryer',
    icon: Icons.air_rounded,
    titleKey: 'inline.plan295.daily_choice.air_fryer.ed741cb9a527',
    subtitleKey: 'inline.plan295.daily_choice.crisp_with_less_tending.e6b875a40b65'),
  DailyChoiceCategory(
    id: 'oven',
    icon: Icons.local_fire_department_rounded,
    titleKey: 'inline.plan295.daily_choice.oven.d510d1c0c583',
    subtitleKey: 'inline.plan295.daily_choice.bake_and_roast_batches.743261c8ac5b'),
];
const List<DailyChoiceTraitGroup> eatTraitGroups = <DailyChoiceTraitGroup>[
  DailyChoiceTraitGroup(
    id: eatAttributeType,
    icon: Icons.ramen_dining_rounded,
    titleKey: 'inline.plan295.daily_choice.dish_type.ba29b4e821d1',
    subtitleKey: 'inline.plan295.daily_choice.filter_by_soup_stir_fry_cold_dish_ri.50142f3d6de3',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'cold_dish',
        titleKey: 'inline.plan295.daily_choice.cold_dish.72cd921c080e',
        icon: Icons.eco_rounded),
      DailyChoiceTraitOption(
        id: 'soup',
        titleKey: 'inline.plan295.daily_choice.soup.fd2d40a89049',
        icon: Icons.soup_kitchen_rounded),
      DailyChoiceTraitOption(
        id: 'stir_fry',
        titleKey: 'inline.plan295.daily_choice.stir_fry.e80e69d81469',
        icon: Icons.local_fire_department_rounded),
      DailyChoiceTraitOption(
        id: 'braise',
        titleKey: 'inline.plan295.daily_choice.braise.fe57288c517a',
        icon: Icons.whatshot_rounded),
      DailyChoiceTraitOption(
        id: 'stew',
        titleKey: 'inline.plan295.daily_choice.stew.0378ddd2562b',
        icon: Icons.coffee_rounded),
      DailyChoiceTraitOption(
        id: 'steam',
        titleKey: 'inline.plan295.daily_choice.steam.4296a0253411',
        icon: Icons.water_drop_rounded),
      DailyChoiceTraitOption(
        id: 'pan_fry',
        titleKey: 'inline.plan295.daily_choice.pan_fry.b5934084242b',
        icon: Icons.egg_alt_rounded),
      DailyChoiceTraitOption(
        id: 'deep_fry',
        titleKey: 'inline.plan295.daily_choice.deep_fry.b6f4fc3ef7d9',
        icon: Icons.bakery_dining_rounded),
      DailyChoiceTraitOption(
        id: 'bake',
        titleKey: 'inline.plan295.daily_choice.bake.1210318bbd4d',
        icon: Icons.outdoor_grill_rounded),
      DailyChoiceTraitOption(
        id: 'rice',
        titleKey: 'inline.plan295.daily_choice.rice.3d2236734f4c',
        icon: Icons.rice_bowl_rounded),
      DailyChoiceTraitOption(
        id: 'noodle',
        titleKey: 'inline.plan295.daily_choice.noodles.ffd7e2007eb1',
        icon: Icons.ramen_dining_rounded),
      DailyChoiceTraitOption(
        id: 'dessert',
        titleKey: 'inline.plan295.daily_choice.dessert.0e418d70d3fd',
        icon: Icons.cake_rounded),
    ]),
  DailyChoiceTraitGroup(
    id: eatAttributeProfile,
    icon: Icons.set_meal_rounded,
    titleKey: 'inline.plan295.daily_choice.profile.393b1af98513',
    subtitleKey: 'inline.plan295.daily_choice.filter_by_vegetarian_meat_based_mixe.37ec39564b42',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: eatProfileVegetarian,
        titleKey: 'inline.plan295.daily_choice.vegetarian.4998bc32bbae',
        icon: Icons.spa_rounded),
      DailyChoiceTraitOption(
        id: eatProfileMeatBased,
        titleKey: 'inline.plan295.daily_choice.meat_based.d7affba2fb8b',
        icon: Icons.set_meal_rounded),
      DailyChoiceTraitOption(
        id: eatProfileMixed,
        titleKey: 'inline.plan295.daily_choice.mixed.2c9888bab620',
        icon: Icons.dinner_dining_rounded),
      DailyChoiceTraitOption(
        id: eatProfileStaple,
        titleKey: 'inline.plan295.daily_choice.staple.446c3b19df2c',
        icon: Icons.lunch_dining_rounded),
      DailyChoiceTraitOption(
        id: eatProfileDessert,
        titleKey: 'inline.plan295.daily_choice.dessert.2097b585433c',
        icon: Icons.icecream_rounded),
    ]),
];
const DailyChoiceTraitGroup eatContainsTraitGroup = DailyChoiceTraitGroup(
  id: eatAttributeContains,
  icon: Icons.report_gmailerrorred_rounded,
    titleKey: 'inline.plan295.daily_choice.avoid_allergens.7c04cb659c45',
    subtitleKey: 'inline.plan295.daily_choice.keep_the_common_quick_avoids_and_add.23e4d5064965',
  options: <DailyChoiceTraitOption>[
    DailyChoiceTraitOption(
      id: 'cilantro',
        titleKey: 'inline.plan295.daily_choice.cilantro.f6d01666284b',
      icon: Icons.local_florist_rounded),
    DailyChoiceTraitOption(
      id: 'seafood',
        titleKey: 'inline.plan295.daily_choice.seafood.b01af20690cc',
      icon: Icons.phishing_rounded),
    DailyChoiceTraitOption(
      id: eatContainsPeanutNut,
        titleKey: 'inline.plan295.daily_choice.peanut_nut.0386a838c040',
      icon: Icons.spa_rounded),
    DailyChoiceTraitOption(
      id: 'alcohol',
        titleKey: 'inline.plan295.daily_choice.alcohol.f81e7794290b',
      icon: Icons.no_drinks_rounded),
    DailyChoiceTraitOption(
      id: 'spicy',
        titleKey: 'inline.plan295.daily_choice.chili.0dd8c76bd276',
      icon: Icons.local_fire_department_rounded),
  ]);
final List<DailyChoiceTraitGroup> eatManagerTraitGroups =
    <String>{eatAttributeType, eatAttributeProfile}
        .map((id) => eatTraitGroupById(id))
        .whereType<DailyChoiceTraitGroup>()
        .toList(growable: false);
const List<DailyChoiceCategory> temperatureCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'freezing',
    icon: Icons.ac_unit_rounded,
    titleKey: 'inline.plan295.daily_choice.freezing.112ca90b1cba',
    subtitleKey: 'inline.plan295.daily_choice.below_0_c.5595ec4d998b'),
  DailyChoiceCategory(
    id: 'cold',
    icon: Icons.severe_cold_rounded,
    titleKey: 'inline.plan295.daily_choice.cold.5f5a5d94ebb0',
    subtitleKey: 'inline.plan295.daily_choice.5_c_to_10_c.48ec3aa86bd4'),
  DailyChoiceCategory(
    id: 'cool',
    icon: Icons.cloud_queue_rounded,
    titleKey: 'inline.plan295.daily_choice.cool.97b323d9a1f6',
    subtitleKey: 'inline.plan295.daily_choice.10_c_to_15_c.47019b39de50'),
  DailyChoiceCategory(
    id: 'mild',
    icon: Icons.filter_vintage_rounded,
    titleKey: 'inline.plan295.daily_choice.mild.55233cb9e60a',
    subtitleKey: 'inline.plan295.daily_choice.15_c_to_25_c.11df045af05c'),
  DailyChoiceCategory(
    id: 'warm',
    icon: Icons.wb_sunny_outlined,
    titleKey: 'inline.plan295.daily_choice.warm.7e5d01fcd40e',
    subtitleKey: 'inline.plan295.daily_choice.25_c_to_30_c.829f81da743a'),
  DailyChoiceCategory(
    id: 'hot',
    icon: Icons.wb_sunny_rounded,
    titleKey: 'inline.plan295.daily_choice.hot.5b5815af79df',
    subtitleKey: 'inline.plan295.daily_choice.30_c_to_35_c.42550ae59815'),
  DailyChoiceCategory(
    id: 'extreme_hot',
    icon: Icons.local_fire_department_rounded,
    titleKey: 'inline.plan295.daily_choice.extreme_heat.5c6fc7f42b77',
    subtitleKey: 'inline.plan295.daily_choice.above_35_c.f58470be03af'),
];
const DailyChoiceCategory allTemperatureCategory = DailyChoiceCategory(
  id: 'all',
  icon: Icons.grid_view_rounded,
    titleKey: 'inline.plan295.daily_choice.all_temperatures.c1f346a28465',
    subtitleKey: 'inline.plan295.daily_choice.all_temperatures_full_wardrobe.dc043ccba6f5');
const List<DailyChoiceCategory> wearTemperatureFilterCategories =
    <DailyChoiceCategory>[allTemperatureCategory, ...temperatureCategories];
const List<DailyChoiceCategory> wearSceneCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'commute',
    icon: Icons.work_rounded,
    titleKey: 'inline.plan295.daily_choice.commute.4799a6b90d47',
    subtitleKey: 'inline.plan295.daily_choice.polished_and_practical.c9e392673587'),
  DailyChoiceCategory(
    id: 'casual',
    icon: Icons.weekend_rounded,
    titleKey: 'inline.plan295.daily_choice.casual.04c0350270ab',
    subtitleKey: 'inline.plan295.daily_choice.comfortable_and_easy.418716dc2ece'),
  DailyChoiceCategory(
    id: 'business',
    icon: Icons.business_center_rounded,
    titleKey: 'inline.plan295.daily_choice.business.31da658066a7',
    subtitleKey: 'inline.plan295.daily_choice.structured_and_restrained.4b4a35739092'),
  DailyChoiceCategory(
    id: 'date',
    icon: Icons.favorite_rounded,
    titleKey: 'inline.plan295.daily_choice.date.8b68ec92c089',
    subtitleKey: 'inline.plan295.daily_choice.soft_with_one_highlight.307967f73ed1'),
  DailyChoiceCategory(
    id: 'exercise',
    icon: Icons.directions_run_rounded,
    titleKey: 'inline.plan295.daily_choice.exercise.c95fb246e2c7',
    subtitleKey: 'inline.plan295.daily_choice.breathable_and_mobile.79aeee148da8'),
  DailyChoiceCategory(
    id: 'rain',
    icon: Icons.umbrella_rounded,
    titleKey: 'inline.plan295.daily_choice.rain.653c02cd93ca',
    subtitleKey: 'inline.plan295.daily_choice.grippy_quick_dry_layered.64d55a69b643'),
];
const DailyChoiceCategory allWearSceneCategory = DailyChoiceCategory(
  id: 'all',
  icon: Icons.grid_view_rounded,
    titleKey: 'inline.plan295.daily_choice.all_scenes.07f7ddffe20c',
    subtitleKey: 'inline.plan295.daily_choice.all_scenes.bb6705527faa');
const List<DailyChoiceCategory> wearSceneFilterCategories =
    <DailyChoiceCategory>[allWearSceneCategory, ...wearSceneCategories];
const List<DailyChoiceTraitGroup> wearTraitGroups = <DailyChoiceTraitGroup>[
  DailyChoiceTraitGroup(
    id: 'gender',
    icon: Icons.wc_rounded,
    titleKey: 'inline.plan295.daily_choice.gender_reference.227689787637',
    subtitleKey: 'inline.plan295.daily_choice.a_fit_and_styling_reference_only_cho.f2f507e5a46a',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'gender_neutral',
        titleKey: 'inline.plan295.daily_choice.open.ee9fc2bd9171',
        icon: Icons.all_inclusive_rounded),
      DailyChoiceTraitOption(
        id: 'womenswear',
        titleKey: 'inline.plan295.daily_choice.womenswear.facc6d4b9dc1',
        icon: Icons.face_retouching_natural_rounded),
      DailyChoiceTraitOption(
        id: 'menswear',
        titleKey: 'inline.plan295.daily_choice.menswear.4ed5ba5cb43e',
        icon: Icons.man_rounded),
    ]),
  DailyChoiceTraitGroup(
    id: 'age',
    icon: Icons.diversity_3_rounded,
    titleKey: 'inline.plan295.daily_choice.age_stage.5c243e27d79b',
    subtitleKey: 'inline.plan295.daily_choice.filter_by_life_stage_and_styling_ton.455d2d6c514f',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'all_age',
        titleKey: 'inline.plan295.daily_choice.age_flexible.9d7266f462ad',
        icon: Icons.all_inclusive_rounded),
      DailyChoiceTraitOption(
        id: 'youth',
        titleKey: 'inline.plan295.daily_choice.youth.e7674ca6c131',
        icon: Icons.school_rounded),
      DailyChoiceTraitOption(
        id: 'young_adult',
        titleKey: 'inline.plan295.daily_choice.young_adult.88be2b9b7b2f',
        icon: Icons.badge_rounded),
      DailyChoiceTraitOption(
        id: 'adult',
        titleKey: 'inline.plan295.daily_choice.adult.1ed5be66d036',
        icon: Icons.work_outline_rounded),
      DailyChoiceTraitOption(
        id: 'mature',
        titleKey: 'inline.plan295.daily_choice.mature.6524bac656aa',
        icon: Icons.workspace_premium_rounded),
    ]),
  DailyChoiceTraitGroup(
    id: 'style',
    icon: Icons.style_rounded,
    titleKey: 'ref.toolbox.sound.piano.style',
    subtitleKey: 'inline.plan295.daily_choice.how_the_outfit_reads_at_a_glance.f4067a9f698f',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'minimal',
        titleKey: 'inline.plan295.daily_choice.minimal.1c786f1ba396',
        icon: Icons.checkroom_rounded),
      DailyChoiceTraitOption(
        id: 'polished',
        titleKey: 'inline.plan295.daily_choice.polished.47b263e6660d',
        icon: Icons.work_outline_rounded),
      DailyChoiceTraitOption(
        id: 'soft',
        titleKey: 'inline.plan295.daily_choice.soft.22bf270f622a',
        icon: Icons.favorite_border_rounded),
      DailyChoiceTraitOption(
        id: 'relaxed',
        titleKey: 'inline.plan295.daily_choice.relaxed.556d216b95e0',
        icon: Icons.weekend_rounded),
      DailyChoiceTraitOption(
        id: 'sporty',
        titleKey: 'inline.plan295.daily_choice.sporty.5c48952c2dcb',
        icon: Icons.fitness_center_rounded),
      DailyChoiceTraitOption(
        id: 'retro',
        titleKey: 'inline.plan295.daily_choice.retro.5f7fcf5d1f85',
        icon: Icons.history_edu_rounded),
      DailyChoiceTraitOption(
        id: 'street',
        titleKey: 'inline.plan295.daily_choice.street.09be80d3b5c2',
        icon: Icons.flash_on_rounded),
      DailyChoiceTraitOption(
        id: 'outdoor',
        titleKey: 'inline.plan295.daily_choice.outdoor.52b51ce427df',
        icon: Icons.terrain_rounded),
    ]),
  DailyChoiceTraitGroup(
    id: 'silhouette',
    icon: Icons.straighten_rounded,
    titleKey: 'inline.plan295.daily_choice.silhouette.4611e18bada9',
    subtitleKey: 'inline.plan295.daily_choice.capture_the_shape_and_proportion.822356182b01',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'clean',
        titleKey: 'inline.plan295.daily_choice.clean.79d9bc98707d',
        icon: Icons.crop_3_2_rounded),
      DailyChoiceTraitOption(
        id: 'waist_defined',
        titleKey: 'inline.plan295.daily_choice.waist_defined.66ee5293c64f',
        icon: Icons.face_retouching_natural_rounded),
      DailyChoiceTraitOption(
        id: 'straight',
        titleKey: 'inline.plan295.daily_choice.straight.b18107af4dbb',
        icon: Icons.view_column_rounded),
      DailyChoiceTraitOption(
        id: 'relaxed',
        titleKey: 'inline.plan295.daily_choice.relaxed_fit.abfae1c26ef4',
        icon: Icons.open_in_full_rounded),
      DailyChoiceTraitOption(
        id: 'drapey',
        titleKey: 'inline.plan295.daily_choice.drapey.045d3e784e68',
        icon: Icons.waterfall_chart_rounded),
      DailyChoiceTraitOption(
        id: 'layered',
        titleKey: 'inline.plan295.daily_choice.layered.6ffd4abe235e',
        icon: Icons.layers_rounded),
    ]),
  DailyChoiceTraitGroup(
    id: 'key_piece',
    icon: Icons.category_rounded,
    titleKey: 'inline.plan295.daily_choice.key_pieces.f3609209ea4d',
    subtitleKey: 'inline.plan295.daily_choice.the_main_clothing_types_carrying_the.e3903218b720',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'shirt',
        titleKey: 'inline.plan295.daily_choice.shirt_polo.a01dff7830fe',
        icon: Icons.badge_rounded),
      DailyChoiceTraitOption(
        id: 'knit',
        titleKey: 'inline.plan295.daily_choice.knit.b79a15a8b9d2',
        icon: Icons.texture_rounded),
      DailyChoiceTraitOption(
        id: 'tailoring',
        titleKey: 'inline.plan295.daily_choice.tailoring.56d71335e98e',
        icon: Icons.business_center_rounded),
      DailyChoiceTraitOption(
        id: 'coat',
        titleKey: 'inline.plan295.daily_choice.outerwear.3ad5c2da8a8f',
        icon: Icons.checkroom_rounded),
      DailyChoiceTraitOption(
        id: 'dress_skirt',
        titleKey: 'inline.plan295.daily_choice.dress_skirt.3e41e756b1b9',
        icon: Icons.dry_cleaning_rounded),
      DailyChoiceTraitOption(
        id: 'trousers',
        titleKey: 'inline.plan295.daily_choice.trousers.36c7596cc20b',
        icon: Icons.accessibility_new_rounded),
      DailyChoiceTraitOption(
        id: 'shorts',
        titleKey: 'inline.plan295.daily_choice.shorts.68530c8397fc',
        icon: Icons.wb_sunny_outlined),
      DailyChoiceTraitOption(
        id: 'athleisure',
        titleKey: 'inline.plan295.daily_choice.athleisure.e1f12cd7bf95',
        icon: Icons.sports_gymnastics_rounded),
    ]),
  DailyChoiceTraitGroup(
    id: 'material',
    icon: Icons.grid_view_rounded,
    titleKey: 'inline.plan295.daily_choice.fabric.eeb696b9b80d',
    subtitleKey: 'inline.plan295.daily_choice.track_the_fabric_and_touch_that_defi.102d8cc8295d',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'wool',
        titleKey: 'inline.plan295.daily_choice.wool.a47ca572a940',
        icon: Icons.ac_unit_rounded),
      DailyChoiceTraitOption(
        id: 'knit',
        titleKey: 'inline.plan295.daily_choice.knit_texture.e54ab24cd0cc',
        icon: Icons.texture_rounded),
      DailyChoiceTraitOption(
        id: 'cotton_linen',
        titleKey: 'inline.plan295.daily_choice.cotton_linen.a34c1b41c94c',
        icon: Icons.air_rounded),
      DailyChoiceTraitOption(
        id: 'tailoring_fabric',
        titleKey: 'inline.plan295.daily_choice.tailoring_fabric.339e9fa8b11c',
        icon: Icons.iron_rounded),
      DailyChoiceTraitOption(
        id: 'quick_dry',
        titleKey: 'inline.plan295.daily_choice.quick_dry.dfb916d9f28a',
        icon: Icons.bolt_rounded),
      DailyChoiceTraitOption(
        id: 'waterproof',
        titleKey: 'inline.plan295.daily_choice.waterproof.b58ae4d6b661',
        icon: Icons.umbrella_rounded),
      DailyChoiceTraitOption(
        id: 'denim',
        titleKey: 'inline.plan295.daily_choice.denim_corduroy.ed2f19500045',
        icon: Icons.texture_outlined),
      DailyChoiceTraitOption(
        id: 'soft_sheen',
        titleKey: 'inline.plan295.daily_choice.soft_sheen.58990b1a0c0c',
        icon: Icons.auto_awesome_rounded),
    ]),
  DailyChoiceTraitGroup(
    id: 'highlight',
    icon: Icons.auto_awesome_rounded,
    titleKey: 'inline.plan295.daily_choice.highlight.b718d030b28c',
    subtitleKey: 'inline.plan295.daily_choice.the_finishing_note_worth_remembering.952b6193c264',
    options: <DailyChoiceTraitOption>[
      DailyChoiceTraitOption(
        id: 'clean_color',
        titleKey: 'inline.plan295.daily_choice.clean_palette.2e3ef7f003b6',
        icon: Icons.palette_outlined),
      DailyChoiceTraitOption(
        id: 'color_accent',
        titleKey: 'inline.plan295.daily_choice.color_accent.daba9dafb903',
        icon: Icons.color_lens_outlined),
      DailyChoiceTraitOption(
        id: 'texture',
        titleKey: 'inline.plan295.daily_choice.texture_contrast.14fbcc764930',
        icon: Icons.blur_on_rounded),
      DailyChoiceTraitOption(
        id: 'proportion',
        titleKey: 'inline.plan295.daily_choice.proportion.637085fc0c9b',
        icon: Icons.height_rounded),
      DailyChoiceTraitOption(
        id: 'accessory',
        titleKey: 'inline.plan295.daily_choice.accessory_finish.fd34225380d1',
        icon: Icons.watch_rounded),
      DailyChoiceTraitOption(
        id: 'weather_protection',
        titleKey: 'inline.plan295.daily_choice.weather_protection.3120ee5c7d49',
        icon: Icons.shield_rounded),
      DailyChoiceTraitOption(
        id: 'sun_protection',
        titleKey: 'inline.plan295.daily_choice.sun_protection.b48c2de4f401',
        icon: Icons.beach_access_rounded),
      DailyChoiceTraitOption(
        id: 'shoe_anchor',
        titleKey: 'inline.plan295.daily_choice.shoe_anchor.187e64e15801',
        icon: Icons.shopping_bag_outlined),
    ]),
];
final List<DailyChoiceTraitGroup> wearManagerTraitGroups =
    <String>{'gender', 'age', 'style', 'silhouette', 'key_piece'}
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
    i18n: i18n,
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
    i18n: AppI18n('zh'),
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
    i18n: AppI18n('en'),
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
      '${group.title(i18n)}${i18n.t('inline.plan295.daily_choice.text.6e6eaf6a1043')}${labels.join(i18n.t('inline.plan295.daily_choice.text.2dce0380cd64'))}',
    );
  }
  return lines;
}

List<String> _wearTraitLabelsForLanguage(
  Map<String, List<String>> attributes, {
  required AppI18n i18n,
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
      labels.add(option.title(i18n));
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
    i18n: i18n,
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
    i18n: AppI18n('zh'),
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
    i18n: AppI18n('en'),
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
      '${i18n.t('inline.plan295.daily_choice.meals.cf474b56409b')}${mealLabels.join(i18n.t('inline.plan295.daily_choice.text.2dce0380cd64'))}',
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
      '${group.title(i18n)}${i18n.t('inline.plan295.daily_choice.text.6e6eaf6a1043')}${labels.join(i18n.t('inline.plan295.daily_choice.text.2dce0380cd64'))}',
    );
  }
  return lines;
}

List<String> _eatTraitLabelsForLanguage(
  Map<String, List<String>> attributes, {
  required AppI18n i18n,
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
      labels.add(option.title(i18n));
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
    titleKey: 'inline.plan295.daily_choice.step_out.baf18d364c05',
    subtitleKey: 'inline.plan295.daily_choice.under_30_minutes.689b9df746cc'),
  DailyChoiceCategory(
    id: 'nearby',
    icon: Icons.location_city_rounded,
    titleKey: 'inline.plan295.daily_choice.nearby.8d7779a99a74',
    subtitleKey: 'inline.plan295.daily_choice.a_local_half_day.b01b923ee490'),
  DailyChoiceCategory(
    id: 'travel',
    icon: Icons.train_rounded,
    titleKey: 'inline.plan295.daily_choice.travel.66ca8f22e0c9',
    subtitleKey: 'inline.plan295.daily_choice.needs_planning.9c9283e14b3a'),
];
const DailyChoiceCategory allPlaceSceneCategory = DailyChoiceCategory(
  id: 'all',
  icon: Icons.grid_view_rounded,
    titleKey: 'inline.plan295.daily_choice.all_scenes.07f7ddffe20c',
    subtitleKey: 'inline.plan295.daily_choice.start_from_distance_then_randomize_a.6f0a551e29bf');
const List<DailyChoiceCategory> placeSceneCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'food',
    icon: Icons.restaurant_rounded,
    titleKey: 'inline.plan295.daily_choice.food.180d201ea8ce',
    subtitleKey: 'inline.plan295.daily_choice.meals_snacks_cafes_and_late_bites.b4bf3c969258'),
  DailyChoiceCategory(
    id: 'entertainment',
    icon: Icons.local_activity_rounded,
    titleKey: 'inline.plan295.daily_choice.entertainment.9fd0c0e75bb9',
    subtitleKey: 'inline.plan295.daily_choice.movies_games_and_live_fun.30a895e44d5d'),
  DailyChoiceCategory(
    id: 'sports',
    icon: Icons.sports_basketball_rounded,
    titleKey: 'inline.plan295.daily_choice.sports.4ccfe61b17e6',
    subtitleKey: 'inline.plan295.daily_choice.gyms_courts_pools_and_active_venues.506aeb125159'),
  DailyChoiceCategory(
    id: 'culture',
    icon: Icons.palette_rounded,
    titleKey: 'inline.ui.pages.playback_advanced_page.culture_faa85e',
    subtitleKey: 'inline.plan295.daily_choice.museums_galleries_theaters_and_exhib.cb4f084eb9cc'),
  DailyChoiceCategory(
    id: 'history',
    icon: Icons.account_balance_rounded,
    titleKey: 'inline.plan295.daily_choice.history.d46792db5fca',
    subtitleKey: 'inline.plan295.daily_choice.historic_streets_relics_and_old_arch.f25999a1d064'),
  DailyChoiceCategory(
    id: 'nature',
    icon: Icons.park_rounded,
    titleKey: 'ambientCategoryNature',
    subtitleKey: 'inline.plan295.daily_choice.parks_greenways_wetlands_and_trails.95f22bb85b73'),
  DailyChoiceCategory(
    id: 'study',
    icon: Icons.local_library_rounded,
    titleKey: 'inline.ui.module.module_access.study_594a75',
    subtitleKey: 'inline.plan295.daily_choice.libraries_study_rooms_bookstores_and.cd2123a37c23'),
  DailyChoiceCategory(
    id: 'shopping',
    icon: Icons.shopping_bag_rounded,
    titleKey: 'inline.plan295.daily_choice.shopping.ba38e028ab31',
    subtitleKey: 'inline.plan295.daily_choice.malls_markets_and_shopping_districts.14432d85df00'),
  DailyChoiceCategory(
    id: 'social',
    icon: Icons.groups_rounded,
    titleKey: 'inline.plan295.daily_choice.social.8b1bc96611f4',
    subtitleKey: 'inline.plan295.daily_choice.meetups_board_games_and_easy_social.6fc57166325a'),
  DailyChoiceCategory(
    id: 'family',
    icon: Icons.family_restroom_rounded,
    titleKey: 'inline.plan295.daily_choice.family.8cd1e0a00fc0',
    subtitleKey: 'inline.plan295.daily_choice.family_outings_and_multi_age_friendl.aae9a888248f'),
  DailyChoiceCategory(
    id: 'nightlife',
    icon: Icons.nightlife_rounded,
    titleKey: 'inline.plan295.daily_choice.nightlife.c52c0931be25',
    subtitleKey: 'inline.plan295.daily_choice.bars_night_shows_views_and_late_acti.6519f2633335'),
  DailyChoiceCategory(
    id: 'relax',
    icon: Icons.spa_rounded,
    titleKey: 'breakPhase',
    subtitleKey: 'inline.plan295.daily_choice.hot_springs_tea_houses_and_restorati.61fa0f7d77bd'),
  DailyChoiceCategory(
    id: 'photo',
    icon: Icons.photo_camera_back_rounded,
    titleKey: 'inline.plan295.daily_choice.photo.73846acf7437',
    subtitleKey: 'inline.plan295.daily_choice.street_scenes_viewpoints_and_photo_s.998087b2480c'),
  DailyChoiceCategory(
    id: 'specialty',
    icon: Icons.explore_off_rounded,
    titleKey: 'inline.plan295.daily_choice.special_area.77bf0527aa07',
    subtitleKey: 'inline.plan295.daily_choice.creative_parks_and_locally_distincti.4286e68200a3'),
  DailyChoiceCategory(
    id: 'memorial',
    icon: Icons.flag_circle_rounded,
    titleKey: 'inline.plan295.daily_choice.memorial.09900fc31d20',
    subtitleKey: 'inline.plan295.daily_choice.memorial_halls_remembrance_parks_and.e127f0e11cce'),
];
const DailyChoiceCategory randomActivityCategory = DailyChoiceCategory(
  id: 'any',
  icon: Icons.shuffle_rounded,
    titleKey: 'inline.plan295.daily_choice.random.43e7c57cce0c',
    subtitleKey: 'inline.plan295.daily_choice.randomize_the_direction_too.1423422f5015');
const List<DailyChoiceCategory> activityCategories = <DailyChoiceCategory>[
  DailyChoiceCategory(
    id: 'focus',
    icon: Icons.center_focus_strong_rounded,
    titleKey: 'ambientCategoryFocus',
    subtitleKey: 'inline.plan295.daily_choice.return_attention_to_the_current_goal.9a6144b68939'),
  DailyChoiceCategory(
    id: 'move',
    icon: Icons.fitness_center_rounded,
    titleKey: 'inline.plan295.daily_choice.move.334053354298',
    subtitleKey: 'inline.plan295.daily_choice.wake_up_the_body.12b3c52cb708'),
  DailyChoiceCategory(
    id: 'learn',
    icon: Icons.menu_book_rounded,
    titleKey: 'inline.plan295.daily_choice.learn.04d5b02dec2f',
    subtitleKey: 'inline.plan295.daily_choice.one_small_loop.ce4f2befd42a'),
  DailyChoiceCategory(
    id: 'outdoor',
    icon: Icons.hiking_rounded,
    titleKey: 'inline.plan295.daily_choice.out.86591a8b5975',
    subtitleKey: 'inline.plan295.daily_choice.change_environment.67cba1665e44'),
  DailyChoiceCategory(
    id: 'home',
    icon: Icons.home_repair_service_rounded,
    titleKey: 'inline.plan295.daily_choice.tidy.b342e0532757',
    subtitleKey: 'inline.plan295.daily_choice.lighten_the_space.c45af387f8b8'),
  DailyChoiceCategory(
    id: 'relax',
    icon: Icons.self_improvement_rounded,
    titleKey: 'breakPhase',
    subtitleKey: 'inline.plan295.daily_choice.lower_stimulation.7e41b44e3b27'),
  DailyChoiceCategory(
    id: 'create',
    icon: Icons.brush_rounded,
    titleKey: 'inline.plan295.daily_choice.create.8d833bf46a54',
    subtitleKey: 'inline.plan295.daily_choice.leave_a_small_artifact.85414368f4b5'),
  DailyChoiceCategory(
    id: 'social',
    icon: Icons.groups_rounded,
    titleKey: 'inline.plan295.daily_choice.social.8b1bc96611f4',
    subtitleKey: 'inline.plan295.daily_choice.connect_lightly.5c243ae32d10'),
];
const List<DailyChoiceGuideModule>
cookingGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'kitchen_readiness',
    icon: Icons.countertops_rounded,
    titleKey: 'inline.plan295.daily_choice.kitchen_baseline.22f0ef0eb160',
    subtitleKey: 'inline.plan295.daily_choice.confirm_time_tools_people_and_risks.7b2fe2923902',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.timer_rounded,
        titleKey: 'inline.plan295.daily_choice.ask_time_servings_and_cleanup_first.efd11de01b1b',
        bodyKey: 'inline.plan295.daily_choice.a_suitable_dish_depends_on_time_serv.6d25f6597fe9'),
      DailyChoiceGuideEntry(
        icon: Icons.inventory_2_rounded,
        titleKey: 'inline.plan295.daily_choice.group_ingredients_by_role.6b78bf52ec02',
        bodyKey: 'inline.plan295.daily_choice.separate_main_ingredients_supporting.17edcda42dc0'),
      DailyChoiceGuideEntry(
        icon: Icons.warning_amber_rounded,
        titleKey: 'inline.plan295.daily_choice.remove_unsafe_options_before_optimiz.4e45ee806a5c',
        bodyKey: 'inline.plan295.daily_choice.allergies_pregnancy_infants_swallowi.05f5c59b4a99'),
    ]),
  DailyChoiceGuideModule(
    id: 'shopping_check',
    icon: Icons.shopping_basket_rounded,
    titleKey: 'inline.plan295.daily_choice.shopping_and_inspection.aa31b4629f58',
    subtitleKey: 'inline.plan295.daily_choice.good_ingredients_reduce_the_need_for.735b54baa0a2',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.eco_rounded,
        titleKey: 'inline.plan295.daily_choice.judge_produce_by_freshness_and_cooki.0c3662c9e19f',
        bodyKey: 'inline.plan295.daily_choice.for_produce_check_firmness_cut_surfa.19f667b1f7c3'),
      DailyChoiceGuideEntry(
        icon: Icons.set_meal_rounded,
        titleKey: 'inline.plan295.daily_choice.check_smell_texture_and_cold_chain.a70a0d01b46d',
        bodyKey: 'inline.plan295.daily_choice.meat_should_smell_clean_and_feel_ela.9ffd84e98f24'),
      DailyChoiceGuideEntry(
        icon: Icons.grain_rounded,
        titleKey: 'inline.plan295.daily_choice.inspect_dry_goods_and_seasoning_stor.e7ca21c73a50',
        bodyKey: 'inline.plan295.daily_choice.dry_grains_beans_nuts_spices_and_oil.ce02cce7373c'),
    ]),
  DailyChoiceGuideModule(
    id: 'washing',
    icon: Icons.water_drop_rounded,
    titleKey: 'inline.plan295.daily_choice.washing_and_cleaning.83891e6ab8c5',
    subtitleKey: 'inline.plan295.daily_choice.choose_rinsing_soaking_brushing_peel.82fbd8860ec8',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.spa_rounded,
        titleKey: 'inline.plan295.daily_choice.rinse_leafy_vegetables_layer_by_laye.e9a0984fa5b4',
        bodyKey: 'inline.plan295.daily_choice.remove_damaged_outer_leaves_separate.64162ebebc02'),
      DailyChoiceGuideEntry(
        icon: Icons.brush_rounded,
        titleKey: 'inline.plan295.daily_choice.brush_firm_skins_before_peeling_deci.ba49f2622f08',
        bodyKey: 'inline.plan295.daily_choice.brush_root_vegetables_and_firm_skinn.8e86b70162ae'),
      DailyChoiceGuideEntry(
        icon: Icons.science_rounded,
        titleKey: 'inline.plan295.daily_choice.salt_vinegar_baking_soda_and_produce.bed279483cd1',
        bodyKey: 'inline.plan295.daily_choice.the_baseline_remains_running_water_s.031e7ae9c455'),
    ]),
  DailyChoiceGuideModule(
    id: 'knife_work',
    icon: Icons.content_cut_rounded,
    titleKey: 'inline.plan295.daily_choice.knife_work_and_prep_cuts.7ff75abc55fd',
    subtitleKey: 'inline.plan295.daily_choice.knife_work_is_about_even_cooking_not.85dd8d188e33',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.grid_on_rounded,
        titleKey: 'inline.plan295.daily_choice.shape_should_serve_the_cooking_metho.00881b7c6c43',
        bodyKey: 'inline.plan295.daily_choice.julienne_slices_dice_chunks_segments.c0421e16cf1d'),
      DailyChoiceGuideEntry(
        icon: Icons.restaurant_rounded,
        titleKey: 'inline.plan295.daily_choice.read_meat_grain_and_purpose_first.e3e3b424fa12',
        bodyKey: 'inline.plan295.daily_choice.for_stir_fry_cut_across_the_grain_fo.48d39c753efa'),
      DailyChoiceGuideEntry(
        icon: Icons.health_and_safety_rounded,
        titleKey: 'inline.plan295.daily_choice.cutting_board_order_controls_food_sa.b5bf0ce4d45e',
        bodyKey: 'inline.plan295.daily_choice.prepare_ready_to_eat_items_produce_c.dbeb87165f2a'),
    ]),
  DailyChoiceGuideModule(
    id: 'mise_en_place',
    icon: Icons.fact_check_rounded,
    titleKey: 'inline.plan295.daily_choice.mise_en_place.7f9381b78c2d',
    subtitleKey: 'inline.plan295.daily_choice.arrange_irreversible_and_waiting_ste.55dee2a53a88',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.schedule_rounded,
        titleKey: 'inline.plan295.daily_choice.start_long_waits_first.a6119d31c81c',
        bodyKey: 'inline.plan295.daily_choice.soaking_marinating_preheating_rice_c.105bb2ad15e2'),
      DailyChoiceGuideEntry(
        icon: Icons.bento_rounded,
        titleKey: 'inline.plan295.daily_choice.place_seasoning_and_containers_withi.e0c437598fa0',
        bodyKey: 'inline.plan295.daily_choice.stir_frying_pan_frying_frying_thicke.f3bbdf5d9b10'),
      DailyChoiceGuideEntry(
        icon: Icons.layers_rounded,
        titleKey: 'inline.plan295.daily_choice.group_prep_by_cooking_order.3c8e28e7db8d',
        bodyKey: 'inline.plan295.daily_choice.group_ingredients_by_when_they_enter.85c904ccde27'),
    ]),
  DailyChoiceGuideModule(
    id: 'seasoning',
    icon: Icons.soup_kitchen_rounded,
    titleKey: 'inline.plan295.daily_choice.seasoning_baseline.67b57bf7ed20',
    subtitleKey: 'inline.plan295.daily_choice.build_salt_acid_sweetness_umami_arom.0e18f596b1d6',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.tune_rounded,
        titleKey: 'inline.plan295.daily_choice.build_base_seasoning_then_finish.4781f73731d2',
        bodyKey: 'inline.plan295.daily_choice.salt_soy_sauce_pastes_and_stock_form.6e7ddc205dbd'),
      DailyChoiceGuideEntry(
        icon: Icons.balance_rounded,
        titleKey: 'inline.plan295.daily_choice.fix_salt_with_volume_and_blandness_w.2f69856ec4e6',
        bodyKey: 'inline.plan295.daily_choice.for_over_salting_add_unsalted_volume.b9a5f262b8bc'),
      DailyChoiceGuideEntry(
        icon: Icons.local_florist_rounded,
        titleKey: 'inline.plan295.daily_choice.aromatics_have_timing.6c5b7d486ef7',
        bodyKey: 'inline.plan295.daily_choice.scallion_ginger_garlic_onion_and_spi.f51b7311ce68'),
    ]),
  DailyChoiceGuideModule(
    id: 'heat_pan',
    icon: Icons.local_fire_department_rounded,
    titleKey: 'inline.plan295.daily_choice.heat_and_cookware.b40ac59d9ac9',
    subtitleKey: 'inline.plan295.daily_choice.read_the_food_state_instead_of_trust.b16c5ffb4525',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.thermostat_rounded,
        titleKey: 'inline.plan295.daily_choice.preheating_does_not_mean_smoking_hot.8a27ac8aa812',
        bodyKey: 'inline.plan295.daily_choice.preheating_means_the_pan_is_ready_no.7beef427c05d'),
      DailyChoiceGuideEntry(
        icon: Icons.air_rounded,
        titleKey: 'inline.plan295.daily_choice.wok_aroma_needs_heat_small_batches_d.8918d2a66f2b',
        bodyKey: 'inline.plan295.daily_choice.good_stir_fry_aroma_needs_dry_ingred.f937e52103e8'),
      DailyChoiceGuideEntry(
        icon: Icons.visibility_rounded,
        titleKey: 'inline.plan295.daily_choice.state_signals_beat_fixed_timing.c84dced6056c',
        bodyKey: 'inline.plan295.daily_choice.watch_color_moisture_release_shrinka.930c5336c479'),
    ]),
  DailyChoiceGuideModule(
    id: 'foundation_techniques',
    icon: Icons.science_rounded,
    titleKey: 'inline.plan295.daily_choice.foundation_techniques.b88db9e6dfd2',
    subtitleKey: 'inline.plan295.daily_choice.know_why_you_blanch_marinate_velvet.a67343b78df7',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.water_rounded,
        titleKey: 'inline.plan295.daily_choice.blanching_removes_odor_sets_color_an.49668ee51584',
        bodyKey: 'inline.plan295.daily_choice.blanch_leafy_greens_briefly_for_colo.70534470b81c'),
      DailyChoiceGuideEntry(
        icon: Icons.spa_rounded,
        titleKey: 'inline.plan295.daily_choice.marinating_and_velveting_control_wat.621ace78c6f3',
        bodyKey: 'inline.plan295.daily_choice.use_a_little_salt_or_soy_sauce_first.1612ffb98524'),
      DailyChoiceGuideEntry(
        icon: Icons.opacity_rounded,
        titleKey: 'inline.plan295.daily_choice.thickening_and_reducing_are_water_ma.7d2e3367cf62',
        bodyKey: 'inline.plan295.daily_choice.stir_starch_slurry_before_adding_it.dc9ae371a08c'),
    ]),
  DailyChoiceGuideModule(
    id: 'cooking_methods',
    icon: Icons.restaurant_menu_rounded,
    titleKey: 'inline.plan295.daily_choice.core_cooking_methods.8c8fe1f57162',
    subtitleKey: 'inline.plan295.daily_choice.each_method_has_a_few_controlling_va.45f7684eed07',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.whatshot_rounded,
        titleKey: 'inline.plan295.daily_choice.stir_fry_and_pan_fry_control_moistur.5689f419309c',
        bodyKey: 'inline.plan295.daily_choice.for_stir_fry_keep_ingredients_dry_or.2ac4a6671e27'),
      DailyChoiceGuideEntry(
        icon: Icons.soup_kitchen_rounded,
        titleKey: 'inline.plan295.daily_choice.boil_stew_braise_and_simmer_depend_o.5ef64d657ab1',
        bodyKey: 'inline.plan295.daily_choice.clear_soups_need_gentle_heat_and_lit.f7f48df5a8ae'),
      DailyChoiceGuideEntry(
        icon: Icons.cloud_rounded,
        titleKey: 'inline.plan295.daily_choice.steam_fry_and_cold_dishes_each_have.48539bfaaa7e',
        bodyKey: 'inline.plan295.daily_choice.for_steaming_count_after_strong_stea.1703a6fe34d0'),
    ]),
  DailyChoiceGuideModule(
    id: 'grains_baking',
    icon: Icons.bakery_dining_rounded,
    titleKey: 'inline.plan295.daily_choice.grains_noodles_and_baking.f9816067ba46',
    subtitleKey: 'inline.plan295.daily_choice.staples_and_baking_depend_heavily_on.ef967f6f6803',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.rice_bowl_rounded,
        titleKey: 'inline.plan295.daily_choice.rice_congee_and_rice_cooker_meals_st.4773b408ecdc',
        bodyKey: 'inline.plan295.daily_choice.fresh_rice_aged_rice_brown_rice_and.61012b10c449'),
      DailyChoiceGuideEntry(
        icon: Icons.ramen_dining_rounded,
        titleKey: 'inline.plan295.daily_choice.noodles_and_starches_depend_on_timin.26c9c6c005a2',
        bodyKey: 'inline.plan295.daily_choice.noodles_keep_absorbing_water_after_d.9e1e4f14fbf7'),
      DailyChoiceGuideEntry(
        icon: Icons.scale_rounded,
        titleKey: 'inline.plan295.daily_choice.for_baking_measure_before_relying_on.9431d223c151',
        bodyKey: 'inline.plan295.daily_choice.bread_cake_tart_cookies_and_desserts.96fb6217a611'),
    ]),
  DailyChoiceGuideModule(
    id: 'storage_reheat',
    icon: Icons.kitchen_rounded,
    titleKey: 'inline.plan295.daily_choice.storage_and_reheating.31d6859bf52c',
    subtitleKey: 'inline.plan295.daily_choice.post_cooking_handling_determines_how.354b78281c75',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.ac_unit_rounded,
        titleKey: 'inline.plan295.daily_choice.cool_cooked_food_quickly_and_portion.315d5101def2',
        bodyKey: 'inline.plan295.daily_choice.do_not_leave_a_large_hot_pot_at_room.7306ab80f831'),
      DailyChoiceGuideEntry(
        icon: Icons.microwave_rounded,
        titleKey: 'inline.plan295.daily_choice.reheat_by_restoring_moisture_or_cris.ca431b698fc7',
        bodyKey: 'inline.plan295.daily_choice.rice_noodles_and_stews_often_need_a.596f73c16b9b'),
      DailyChoiceGuideEntry(
        icon: Icons.recycling_rounded,
        titleKey: 'inline.plan295.daily_choice.reuse_leftovers_by_changing_form.04ce5d4f0a87',
        bodyKey: 'inline.plan295.daily_choice.leftover_rice_can_become_fried_rice.8d5d62279d7b'),
    ]),
  DailyChoiceGuideModule(
    id: 'troubleshooting',
    icon: Icons.build_circle_rounded,
    titleKey: 'inline.plan295.daily_choice.troubleshooting.767b202d7cd6',
    subtitleKey: 'inline.plan295.daily_choice.find_the_variable_before_choosing_th.ab7592f5ed00',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.water_damage_rounded,
        titleKey: 'inline.plan295.daily_choice.too_watery_usually_means_early_salt.72599e813291',
        bodyKey: 'inline.plan295.daily_choice.if_a_dish_gets_watery_remove_excess.a0e37bca9d0c'),
      DailyChoiceGuideEntry(
        icon: Icons.flash_on_rounded,
        titleKey: 'inline.plan295.daily_choice.burnt_outside_and_raw_inside_means_h.07605583a1e8',
        bodyKey: 'inline.plan295.daily_choice.lower_heat_cover_add_a_little_liquid.a65005141457'),
      DailyChoiceGuideEntry(
        icon: Icons.sentiment_dissatisfied_rounded,
        titleKey: 'inline.plan295.daily_choice.tough_meat_limp_vegetables_and_dull.0ac51f69c708',
        bodyKey: 'inline.plan295.daily_choice.lean_meat_dries_out_seafood_shrinks.877042365456'),
    ]),
];
List<DailyChoiceGuideModule> buildCookingGuideModules(List<String> _) {
  return cookingGuideModules;
}

const List<DailyChoiceGuideModule> wearGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'foundation',
    icon: Icons.checkroom_rounded,
    titleKey: 'inline.plan295.daily_choice.foundation.f56ef3715150',
    subtitleKey: 'inline.plan295.daily_choice.start_from_repeatable_basics_and_you.92136804c0e1',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.layers_clear_rounded,
        titleKey: 'inline.plan295.daily_choice.basics_are_the_sentence_not_a_boring.d76448e8ac2f',
        bodyKey: 'inline.plan295.daily_choice.the_strongest_shared_lesson_is_that.e72dc99fb3b5'),
      DailyChoiceGuideEntry(
        icon: Icons.psychology_alt_rounded,
        titleKey: 'inline.plan295.daily_choice.style_is_the_ratio_of_your_real_life.6644df161272',
        bodyKey: 'inline.plan295.daily_choice.style_works_best_when_it_reflects_yo.c62578cfecb0'),
    ]),
  DailyChoiceGuideModule(
    id: 'fit_ratio',
    icon: Icons.straighten_rounded,
    titleKey: 'inline.plan295.daily_choice.fit_ratio.1fddfc886529',
    subtitleKey: 'inline.plan295.daily_choice.fit_length_and_waist_definition_matt.6b3ef250e707',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.crop_portrait_rounded,
        titleKey: 'inline.plan295.daily_choice.check_shoulders_hem_and_back_view_fi.8d0fb6c4598c',
        bodyKey: 'inline.plan295.daily_choice.fit_starts_with_movement_shoulder_li.6b84e3856152'),
      DailyChoiceGuideEntry(
        icon: Icons.height_rounded,
        titleKey: 'inline.plan295.daily_choice.let_top_and_bottom_split_the_visual.db66e0ec098b',
        bodyKey: 'inline.plan295.daily_choice.reliable_proportion_comes_from_letti.f451398475ff'),
    ]),
  DailyChoiceGuideModule(
    id: 'scene',
    icon: Icons.event_seat_rounded,
    titleKey: 'inline.plan295.daily_choice.scene_work.f52e5d6da920',
    subtitleKey: 'inline.plan295.daily_choice.judge_time_place_role_and_today_s_ag.112fd4a9d015',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.work_history_rounded,
        titleKey: 'inline.plan295.daily_choice.for_work_start_with_industry_role_an.82e6dcf6fd95',
        bodyKey: 'inline.plan295.daily_choice.workwear_choices_should_react_to_ind.45026ed3c177'),
      DailyChoiceGuideEntry(
        icon: Icons.favorite_outline_rounded,
        titleKey: 'inline.plan295.daily_choice.every_scene_has_its_first_priority.1760e798a008',
        bodyKey: 'inline.plan295.daily_choice.dates_weekends_exercise_and_rain_all.43fa8b755119'),
    ]),
  DailyChoiceGuideModule(
    id: 'color_material',
    icon: Icons.palette_rounded,
    titleKey: 'inline.plan295.daily_choice.color_material.30aa2c760b61',
    subtitleKey: 'inline.plan295.daily_choice.color_sets_rhythm_while_fabric_sets.e3e5810efcd6',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.color_lens_outlined,
        titleKey: 'inline.plan295.daily_choice.anchor_with_neutrals_before_adding_c.f16de4627815',
        bodyKey: 'inline.plan295.daily_choice.a_practical_route_into_color_is_to_s.2442460c6891'),
      DailyChoiceGuideEntry(
        icon: Icons.blur_on_rounded,
        titleKey: 'inline.plan295.daily_choice.fabric_decides_whether_the_look_feel.03df6bd8936f',
        bodyKey: 'inline.plan295.daily_choice.structure_drape_and_texture_often_ch.bd73bbdb64a0'),
    ]),
  DailyChoiceGuideModule(
    id: 'season_weather',
    icon: Icons.wb_sunny_rounded,
    titleKey: 'inline.plan295.daily_choice.season_weather.47ad90efcd78',
    subtitleKey: 'inline.plan295.daily_choice.read_temperature_feels_like_rain_win.fa773ae8bbe6',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.layers_rounded,
        titleKey: 'inline.plan295.daily_choice.the_three_layer_rule_beats_one_heavy.7c25d1b672d3',
        bodyKey: 'inline.plan295.daily_choice.layering_is_mainly_about_adjustabili.d3b0a363311d'),
      DailyChoiceGuideEntry(
        icon: Icons.umbrella_rounded,
        titleKey: 'inline.plan295.daily_choice.heat_cold_and_rain_each_need_a_final.3b443d0108d9',
        bodyKey: 'inline.plan295.daily_choice.for_heat_check_ventilation_and_sun_p.772810d35c54'),
    ]),
  DailyChoiceGuideModule(
    id: 'accessories',
    icon: Icons.watch_rounded,
    titleKey: 'inline.plan295.daily_choice.shoes_accessories.b76497b8a962',
    subtitleKey: 'inline.plan295.daily_choice.shoes_and_accessories_finish_the_loo.f2e5d8c8500f',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.shopping_bag_outlined,
        titleKey: 'inline.plan295.daily_choice.shoes_finish_the_outfit_bag_and_belt.499d842f2e35',
        bodyKey: 'inline.plan295.daily_choice.shoes_often_reveal_the_most_about_wh.dcc18615462e'),
      DailyChoiceGuideEntry(
        icon: Icons.auto_fix_high_rounded,
        titleKey: 'inline.plan295.daily_choice.accessories_should_fix_color_or_prop.878642a5bfb6',
        bodyKey: 'inline.plan295.daily_choice.accessories_work_best_when_they_eith.e63feafd1e65'),
    ]),
  DailyChoiceGuideModule(
    id: 'wardrobe',
    icon: Icons.inventory_2_rounded,
    titleKey: 'inline.plan295.daily_choice.wardrobe_practice.c1b063846d4d',
    subtitleKey: 'inline.plan295.daily_choice.a_clearer_wardrobe_makes_recommendat.f3524a30a0fc',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.cleaning_services_rounded,
        titleKey: 'inline.plan295.daily_choice.keep_by_frequency_and_scene_not_by_g.8dba30ac1c5c',
        bodyKey: 'inline.plan295.daily_choice.edit_the_closet_around_what_fits_get.783f7a2a14e1'),
      DailyChoiceGuideEntry(
        icon: Icons.photo_camera_back_rounded,
        titleKey: 'inline.plan295.daily_choice.practice_at_home_before_needing_the.d5e23876c333',
        bodyKey: 'inline.plan295.daily_choice.testing_combinations_ahead_of_time_b.88897aa0220f'),
    ]),
];
const List<DailyChoiceGuideModule> placeGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'scope',
    icon: Icons.timer_rounded,
    titleKey: 'inline.plan295.daily_choice.set_the_scope_first.65e4fbaeab32',
    subtitleKey: 'inline.plan295.daily_choice.bound_the_time_and_radius_before_cho.f112cd3620b6',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.door_front_door_rounded,
        titleKey: 'inline.plan295.daily_choice.step_out_nearby_and_travel_are_bound.0d5f349e807e',
        bodyKey: 'inline.plan295.daily_choice.step_out_is_for_a_low_friction_30_to.d97f5fec1860'),
      DailyChoiceGuideEntry(
        icon: Icons.filter_alt_rounded,
        titleKey: 'inline.plan295.daily_choice.distance_first_scene_second.9a110f0395ce',
        bodyKey: 'inline.plan295.daily_choice.when_the_problem_is_i_want_to_go_out.c7920da8b23f'),
    ]),
  DailyChoiceGuideModule(
    id: 'matching',
    icon: Icons.interests_rounded,
    titleKey: 'inline.plan295.daily_choice.match_by_scene.fe2862d5ceef',
    subtitleKey: 'inline.plan295.daily_choice.name_the_kind_of_outing_you_actually.47cbd14e1691',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.psychology_rounded,
        titleKey: 'inline.plan295.daily_choice.the_issue_is_what_you_lack_right_now.37db3b9a4597',
        bodyKey: 'inline.plan295.daily_choice.food_solves_hunger_or_the_need_for_a.147861712619'),
      DailyChoiceGuideEntry(
        icon: Icons.group_work_rounded,
        titleKey: 'inline.plan295.daily_choice.who_goes_with_you_changes_the_best_a.4590a86292b5',
        bodyKey: 'inline.plan295.daily_choice.solo_trips_work_best_with_low_commun.144c3c2aa8cd'),
    ]),
  DailyChoiceGuideModule(
    id: 'map',
    icon: Icons.map_rounded,
    titleKey: 'inline.plan295.daily_choice.maps_and_search.84e317088235',
    subtitleKey: 'inline.plan295.daily_choice.check_opening_hours_transit_booking.99d9d72d8754',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.search_rounded,
        titleKey: 'inline.plan295.daily_choice.search_by_keyword_before_committing.c15c44e1f02f',
        bodyKey: 'inline.plan295.daily_choice.this_version_gives_you_a_map_query_s.0b8aa747eeb4'),
      DailyChoiceGuideEntry(
        icon: Icons.alt_route_rounded,
        titleKey: 'inline.plan295.daily_choice.always_keep_a_backup.a8c5d8082c94',
        bodyKey: 'inline.plan295.daily_choice.queues_closures_rain_or_sold_out_tic.ef02d79ef396'),
    ]),
  DailyChoiceGuideModule(
    id: 'weather_budget',
    icon: Icons.wb_sunny_rounded,
    titleKey: 'inline.plan295.daily_choice.weather_budget_and_safety.a5d8102a0720',
    subtitleKey: 'inline.plan295.daily_choice.practicality_matters_more_than_the_i.552e326044b5',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.thunderstorm_rounded,
        titleKey: 'inline.plan295.daily_choice.outdoor_and_night_outings_start_with.70ad7697b503',
        bodyKey: 'inline.plan295.daily_choice.parks_waterfronts_street_scenes_nigh.cb8e765fadaa'),
      DailyChoiceGuideEntry(
        icon: Icons.account_balance_wallet_rounded,
        titleKey: 'inline.plan295.daily_choice.budget_means_transit_cost_too.83788bd2efb3',
        bodyKey: 'inline.plan295.daily_choice.the_real_cost_includes_transit_parki.c9f02c6eb411'),
    ]),
  DailyChoiceGuideModule(
    id: 'pack',
    icon: Icons.backpack_rounded,
    titleKey: 'inline.plan295.daily_choice.minimal_prep_pack.185400786510',
    subtitleKey: 'inline.plan295.daily_choice.carry_little_but_do_not_forget_the_e.1c836202d497',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.battery_charging_full_rounded,
        titleKey: 'inline.plan295.daily_choice.short_trips_need_battery_long_trips.8ce4f702586d',
        bodyKey: 'inline.plan295.daily_choice.for_step_out_and_nearby_trips_phone.708e72854b73'),
      DailyChoiceGuideEntry(
        icon: Icons.history_toggle_off_rounded,
        titleKey: 'inline.plan295.daily_choice.end_on_time_instead_of_dragging_it_o.fb33abfd2439',
        bodyKey: 'inline.plan295.daily_choice.the_tool_is_meant_to_get_you_moving.811dff52898d'),
    ]),
];
const List<DailyChoiceGuideEntry>
activityGuideEntries = <DailyChoiceGuideEntry>[
  DailyChoiceGuideEntry(
    icon: Icons.flag_rounded,
    titleKey: 'inline.plan295.daily_choice.make_it_startable.f7bb2ac42fd3',
    bodyKey: 'inline.plan295.daily_choice.if_an_activity_feels_too_large_shrin.050f1ba48602'),
  DailyChoiceGuideEntry(
    icon: Icons.repeat_rounded,
    titleKey: 'inline.plan295.daily_choice.one_round_first.c6245bb840b3',
    bodyKey: 'inline.plan295.daily_choice.move_study_or_tidy_for_one_round_fir.f98a3b42bc92'),
  DailyChoiceGuideEntry(
    icon: Icons.psychology_rounded,
    titleKey: 'inline.plan295.daily_choice.randomize_direction_too.dfb3ed3d2a36',
    bodyKey: 'inline.plan295.daily_choice.when_even_the_direction_feels_hard_u.adfcdade9e8f'),
];
const List<DailyChoiceGuideModule>
activityGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'attention',
    icon: Icons.center_focus_strong_rounded,
    titleKey: 'inline.plan295.daily_choice.attention_drift.ce70d56e3e8e',
    subtitleKey: 'inline.plan295.daily_choice.review_the_drift_then_return_to_the.fe532d277123',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.psychology_alt_rounded,
        titleKey: 'inline.plan295.daily_choice.review_the_drift_without_judgment.da1b3ff34c71',
        bodyKey: 'inline.plan295.daily_choice.pause_for_20_seconds_and_name_the_dr.ff6edf15bb6b'),
      DailyChoiceGuideEntry(
        icon: Icons.flag_rounded,
        titleKey: 'inline.plan295.daily_choice.restate_the_current_goal.3b1b54c58af2',
        bodyKey: 'inline.plan295.daily_choice.write_one_sentence_for_what_you_mean.ebc19f5c438c'),
      DailyChoiceGuideEntry(
        icon: Icons.timer_rounded,
        titleKey: 'inline.plan295.daily_choice.commit_to_one_small_round.cf7b3d2357af',
        bodyKey: 'inline.plan295.daily_choice.do_one_5_to_12_minute_round_first_wh.cbdb35739d66'),
    ]),
  DailyChoiceGuideModule(
    id: 'walk',
    icon: Icons.directions_walk_rounded,
    titleKey: 'inline.plan295.daily_choice.when_to_walk_outside.7a1d17b39400',
    subtitleKey: 'inline.plan295.daily_choice.use_walking_as_a_state_shift_not_pur.9f5de9754cf8',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.cloud_queue_rounded,
        titleKey: 'inline.plan295.daily_choice.choose_a_short_outing_when_condition.1e2e431ca87b',
        bodyKey: 'inline.plan295.daily_choice.if_weather_and_body_are_safe_the_tas.1be6ecf38d2b'),
      DailyChoiceGuideEntry(
        icon: Icons.route_rounded,
        titleKey: 'inline.plan295.daily_choice.use_a_fixed_short_route.82f08c689ab6',
        bodyKey: 'inline.plan295.daily_choice.a_fixed_route_costs_less_decision_en.2af692324bc9'),
      DailyChoiceGuideEntry(
        icon: Icons.assignment_return_rounded,
        titleKey: 'inline.plan295.daily_choice.return_into_one_small_action.f8329546536c',
        bodyKey: 'inline.plan295.daily_choice.after_returning_do_one_two_minute_ac.96bc185b2ea0'),
    ]),
  DailyChoiceGuideModule(
    id: 'low_energy',
    icon: Icons.battery_2_bar_rounded,
    titleKey: 'inline.plan295.daily_choice.low_energy_start.9217cb3e1b6e',
    subtitleKey: 'inline.plan295.daily_choice.shrink_the_action_so_starting_happen.ecfd297c75c7',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.compress_rounded,
        titleKey: 'inline.plan295.daily_choice.shrink_to_a_visible_endpoint.f272eaa6a69d',
        bodyKey: 'inline.plan295.daily_choice.do_not_write_study_english_write_rev.1d85b958fe95'),
      DailyChoiceGuideEntry(
        icon: Icons.hourglass_empty_rounded,
        titleKey: 'inline.plan295.daily_choice.keep_the_time_box_short.a4a8f60902f9',
        bodyKey: 'inline.plan295.daily_choice.at_low_energy_five_minutes_is_a_star.e0d0ae4c6089'),
    ]),
  DailyChoiceGuideModule(
    id: 'boundaries',
    icon: Icons.rule_rounded,
    titleKey: 'inline.plan295.daily_choice.action_boundaries.3fe8e2c32d89',
    subtitleKey: 'inline.plan295.daily_choice.know_when_to_stop_and_when_to_switch.1ebc38a45fcb',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.stop_circle_rounded,
        titleKey: 'inline.plan295.daily_choice.stopping_on_time_counts.e5b503f22715',
        bodyKey: 'inline.plan295.daily_choice.the_randomizer_helps_you_start_and_c.67e500458389'),
      DailyChoiceGuideEntry(
        icon: Icons.swap_horiz_rounded,
        titleKey: 'inline.plan295.daily_choice.keep_the_reason_when_switching.48477b2a4492',
        bodyKey: 'inline.plan295.daily_choice.when_switching_keep_one_reason_too_l.7ac439d0b7ee'),
    ]),
];
const List<DailyChoiceGuideEntry>
decisionGuideEntries = <DailyChoiceGuideEntry>[
  DailyChoiceGuideEntry(
    icon: Icons.casino_rounded,
    titleKey: 'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.uniform_random_851942',
    bodyKey: 'inline.plan295.daily_choice.every_option_has_equal_weight_good_f.8707d5a4b689'),
  DailyChoiceGuideEntry(
    icon: Icons.functions_rounded,
    titleKey: 'inline.plan295.daily_choice.expected_value.9314aecb22d2',
    bodyKey: 'inline.plan295.daily_choice.ranks_by_probability_times_value_min.c7cb50a11b6a'),
  DailyChoiceGuideEntry(
    icon: Icons.account_tree_rounded,
    titleKey: 'toolbox.daily_choice.joint_probability',
    bodyKey: 'inline.plan295.daily_choice.when_an_outcome_depends_on_several_e.a7f022ed1c72'),
  DailyChoiceGuideEntry(
    icon: Icons.show_chart_rounded,
    titleKey: 'inline.plan295.daily_choice.calibrated_forecast.b196f3a7b02e',
    bodyKey: 'inline.plan295.daily_choice.when_a_forecast_feels_extremely_opti.f58b2ad99904'),
];
List<DailyChoiceOption> buildDailyChoiceFallbackEatOptions() {
  return List<DailyChoiceOption>.unmodifiable(_eatOptions);
}

List<DailyChoiceOption> buildDailyChoiceStaticSeedOptions() {
  return <DailyChoiceOption>[..._placeOptions];
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
