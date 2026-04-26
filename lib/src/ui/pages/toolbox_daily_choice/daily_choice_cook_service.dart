import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'daily_choice_eat_support.dart';
import 'daily_choice_models.dart';
import 'daily_choice_recipe_library.dart';
import 'daily_choice_seed_data.dart';

enum DailyChoiceCookDataSource { bundle, remote, cache, fallback }

class DailyChoiceCookLoadResult {
  const DailyChoiceCookLoadResult({
    required this.options,
    required this.source,
    this.cookRecipeCount = 0,
    this.localLibraryCount = 0,
    this.referenceTitles = const <String>[],
    this.updatedAt,
    this.errorMessage,
  });

  final List<DailyChoiceOption> options;
  final DailyChoiceCookDataSource source;
  final int cookRecipeCount;
  final int localLibraryCount;
  final List<String> referenceTitles;
  final DateTime? updatedAt;
  final String? errorMessage;
}

class _DailyChoiceCookLibraryBundle {
  const _DailyChoiceCookLibraryBundle({
    required this.options,
    required this.referenceTitles,
    this.generatedAt,
  });

  final List<DailyChoiceOption> options;
  final List<String> referenceTitles;
  final DateTime? generatedAt;
}

class _DailyChoiceCookParsedLibrary {
  const _DailyChoiceCookParsedLibrary({
    required this.bundle,
    required this.document,
  });

  final _DailyChoiceCookLibraryBundle bundle;
  final DailyChoiceRecipeLibraryDocument document;
}

class DailyChoiceCookService {
  DailyChoiceCookService({http.Client? client, AssetBundle? bundle})
    : _client = client,
      _bundle = bundle ?? rootBundle;

  final http.Client? _client;
  final AssetBundle _bundle;
  static Future<_DailyChoiceCookParsedLibrary?>? _sharedParsedLibraryFuture;
  Future<_DailyChoiceCookParsedLibrary?>? _parsedLibraryFuture;

  static const String _cacheFileName = 'toolbox_daily_choice_cook_recipe.csv';
  static const String _libraryAssetPath =
      'assets/toolbox/daily_choice/recipe_library.json';
  static const Duration _requestTimeout = Duration(seconds: 8);
  static const Duration _refreshTtl = Duration(hours: 12);
  static const List<String> _defaultReferenceTitles = <String>[
    'YunYouJun/cook（recipe.csv / 做菜之前）',
  ];

  Future<DailyChoiceCookLoadResult?> loadBundled() async {
    final bundle = await _loadLibraryBundle();
    if (bundle == null || bundle.options.isEmpty) {
      return null;
    }
    return _buildBundleResult(bundle);
  }

  Future<DailyChoiceRecipeLibraryDocument?>
  exportBundledLibraryDocument() async {
    final parsed = await _loadParsedLibrary();
    return parsed?.document;
  }

  Future<DailyChoiceCookLoadResult?> loadCached() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) {
        return null;
      }
      final bundle = await _loadLibraryBundle();
      return _loadCachedFromFile(file, bundle);
    } catch (_) {
      return null;
    }
  }

  Future<DailyChoiceCookLoadResult?> _loadCachedWithBundle(
    _DailyChoiceCookLibraryBundle? libraryBundle,
  ) async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) {
        return null;
      }
      return _loadCachedFromFile(file, libraryBundle);
    } catch (_) {
      return null;
    }
  }

  Future<DailyChoiceCookLoadResult?> _loadCachedFromFile(
    File file,
    _DailyChoiceCookLibraryBundle? libraryBundle,
  ) async {
    final csvData = await file.readAsString();
    final cookOptions = parseDailyChoiceCookOptions(csvData);
    if (cookOptions.isEmpty) {
      return null;
    }
    final bundle = libraryBundle ?? await _loadLibraryBundle();
    final mergedOptions = mergeEatOptionCollections(<DailyChoiceOption>[
      ...?bundle?.options,
      ...cookOptions,
    ]);
    return DailyChoiceCookLoadResult(
      options: mergedOptions,
      source: DailyChoiceCookDataSource.cache,
      cookRecipeCount: cookOptions.length,
      localLibraryCount: bundle?.options.length ?? 0,
      referenceTitles: _resolveReferenceTitles(bundle),
      updatedAt: await file.lastModified(),
    );
  }

  Future<bool> shouldRefreshRemote() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) {
        return true;
      }
      final lastModified = await file.lastModified();
      return DateTime.now().difference(lastModified) >= _refreshTtl;
    } catch (_) {
      return true;
    }
  }

  Future<DailyChoiceCookLoadResult> refresh() async {
    final bundle = await _loadLibraryBundle();
    return _refreshWithBundle(bundle);
  }

  Future<DailyChoiceCookLoadResult> _refreshWithBundle(
    _DailyChoiceCookLibraryBundle? libraryBundle,
  ) async {
    final bundle = libraryBundle ?? await _loadLibraryBundle();
    try {
      final client = _client ?? http.Client();
      final response = await client
          .get(Uri.parse(cookRecipeRawUrl))
          .timeout(_requestTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'cook recipe request failed: ${response.statusCode}',
          uri: Uri.parse(cookRecipeRawUrl),
        );
      }
      final csvData = utf8.decode(response.bodyBytes);
      final cookOptions = parseDailyChoiceCookOptions(csvData);
      if (cookOptions.isEmpty) {
        throw const FormatException('cook recipe csv parsed to empty data');
      }
      final file = await _cacheFile();
      await file.parent.create(recursive: true);
      await file.writeAsString(csvData, flush: true);
      return DailyChoiceCookLoadResult(
        options: mergeEatOptionCollections(<DailyChoiceOption>[
          ...?bundle?.options,
          ...cookOptions,
        ]),
        source: DailyChoiceCookDataSource.remote,
        cookRecipeCount: cookOptions.length,
        localLibraryCount: bundle?.options.length ?? 0,
        referenceTitles: _resolveReferenceTitles(bundle),
        updatedAt: DateTime.now(),
      );
    } catch (error) {
      final cached = await _loadCachedWithBundle(bundle);
      if (cached != null) {
        return DailyChoiceCookLoadResult(
          options: cached.options,
          source: cached.source,
          cookRecipeCount: cached.cookRecipeCount,
          localLibraryCount: cached.localLibraryCount,
          referenceTitles: cached.referenceTitles,
          updatedAt: cached.updatedAt,
          errorMessage: '$error',
        );
      }
      if (bundle != null && bundle.options.isNotEmpty) {
        return DailyChoiceCookLoadResult(
          options: bundle.options,
          source: DailyChoiceCookDataSource.bundle,
          localLibraryCount: bundle.options.length,
          referenceTitles: _resolveReferenceTitles(bundle),
          updatedAt: bundle.generatedAt,
          errorMessage: '$error',
        );
      }
      return fallback(errorMessage: '$error');
    }
  }

  DailyChoiceCookLoadResult fallback({String? errorMessage}) {
    final options = buildDailyChoiceFallbackEatOptions()
        .map(ensureEatOptionAttributes)
        .toList(growable: false);
    return DailyChoiceCookLoadResult(
      options: List<DailyChoiceOption>.unmodifiable(options),
      source: DailyChoiceCookDataSource.fallback,
      referenceTitles: _defaultReferenceTitles,
      errorMessage: errorMessage,
    );
  }

  Future<_DailyChoiceCookLibraryBundle?> _loadLibraryBundle() async {
    final parsed = await _loadParsedLibrary();
    return parsed?.bundle;
  }

  Future<_DailyChoiceCookParsedLibrary?> _loadParsedLibrary() {
    if (identical(_bundle, rootBundle)) {
      return _sharedParsedLibraryFuture ??= _parseBundledLibrary();
    }
    return _parsedLibraryFuture ??= _parseBundledLibrary();
  }

  Future<_DailyChoiceCookParsedLibrary?> _parseBundledLibrary() async {
    try {
      final rawJson = await _bundle.loadString(_libraryAssetPath);
      final decoded = await compute(_decodeDailyChoiceLibraryJson, rawJson);
      if (decoded.isEmpty) {
        return null;
      }
      final document = DailyChoiceRecipeLibraryDocument.fromJson(decoded);
      if (document.recipes.isEmpty) {
        return null;
      }
      final referenceTitles = <String>[
        ..._defaultReferenceTitles,
        ...document.referenceTitles,
      ];
      final catalogOptions = mergeEatOptionCollections(document.recipes);
      return _DailyChoiceCookParsedLibrary(
        bundle: _DailyChoiceCookLibraryBundle(
          options: catalogOptions,
          referenceTitles: _dedupeStrings(referenceTitles),
          generatedAt: document.generatedAt,
        ),
        document: document,
      );
    } catch (_) {
      return null;
    }
  }

  DailyChoiceCookLoadResult _buildBundleResult(
    _DailyChoiceCookLibraryBundle bundle,
  ) {
    return DailyChoiceCookLoadResult(
      options: bundle.options,
      source: DailyChoiceCookDataSource.bundle,
      localLibraryCount: bundle.options.length,
      referenceTitles: _resolveReferenceTitles(bundle),
      updatedAt: bundle.generatedAt,
    );
  }

  List<String> _resolveReferenceTitles(_DailyChoiceCookLibraryBundle? bundle) {
    return _dedupeStrings(<String>[
      ..._defaultReferenceTitles,
      ...?bundle?.referenceTitles,
    ]);
  }

  Future<File> _cacheFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_cacheFileName');
  }
}

List<DailyChoiceOption> parseDailyChoiceCookOptions(String csvData) {
  final rows = Csv(
    lineDelimiter: '\n',
    dynamicTyping: false,
    skipEmptyLines: true,
  ).decode(csvData);
  if (rows.length <= 1) {
    return const <DailyChoiceOption>[];
  }

  final options = <DailyChoiceOption>[];
  final seenKeys = <String>{};
  for (var index = 1; index < rows.length; index += 1) {
    final row = rows[index];
    final name = _cell(row, 0);
    if (name.isEmpty) {
      continue;
    }
    final ingredients = _splitCookItems(_cell(row, 1));
    final bv = _cleanBv(_cell(row, 2));
    final difficulty = _cell(row, 3);
    final tags = _splitCookItems(_cell(row, 4));
    final methods = _splitCookItems(_cell(row, 5));
    final tools = _splitCookItems(_cell(row, 6));
    final toolIds = tools
        .map(_cookToolId)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final primaryToolId = toolIds.isEmpty ? null : toolIds.first;
    final mealId = _classifyMeal(name, ingredients, tags, methods, tools);
    final attributes = buildEatAttributes(
      title: name,
      materials: ingredients,
      notes: <String>[difficulty, ...tags],
      tags: tags,
      methods: methods,
      tools: toolIds,
      primaryMealId: mealId,
    );
    final dedupeKey = '${_normalizedKey(name)}|${toolIds.join(",")}';
    if (!seenKeys.add(dedupeKey)) {
      continue;
    }

    final labels = _buildCookLabels(
      name: name,
      mealId: mealId,
      ingredients: ingredients,
      difficulty: difficulty,
      tags: tags,
      methods: methods,
      tools: tools,
    );

    options.add(
      ensureEatOptionAttributes(
        DailyChoiceOption(
          id: 'cook_${_normalizedKey(name)}_${primaryToolId ?? 'generic'}',
          moduleId: DailyChoiceModuleId.eat.storageValue,
          categoryId: mealId,
          contextId: primaryToolId,
          contextIds: toolIds,
          titleZh: name,
          titleEn: name,
          subtitleZh: labels.subtitle,
          subtitleEn: labels.subtitle,
          detailsZh: labels.details,
          detailsEn: labels.details,
          materialsZh: _buildCookMaterials(
            ingredients: ingredients,
            methods: methods,
            tools: tools,
          ),
          materialsEn: _buildCookMaterials(
            ingredients: ingredients,
            methods: methods,
            tools: tools,
          ),
          stepsZh: _buildCookSteps(
            name: name,
            mealId: mealId,
            ingredients: ingredients,
            methods: methods,
            tools: tools,
          ),
          stepsEn: _buildCookSteps(
            name: name,
            mealId: mealId,
            ingredients: ingredients,
            methods: methods,
            tools: tools,
          ),
          notesZh: _buildCookNotes(
            difficulty: difficulty,
            ingredients: ingredients,
            tools: tools,
          ),
          notesEn: _buildCookNotes(
            difficulty: difficulty,
            ingredients: ingredients,
            tools: tools,
          ),
          tagsZh: _buildCookTags(
            difficulty: difficulty,
            tags: tags,
            methods: methods,
            tools: tools,
          ),
          tagsEn: _buildCookTags(
            difficulty: difficulty,
            tags: tags,
            methods: methods,
            tools: tools,
          ),
          sourceLabel: cookRecipeSourceLabel,
          sourceUrl: cookRecipeSourceUrl,
          references: _buildCookReferences(bv),
          attributes: attributes,
        ),
      ),
    );
  }

  return mergeEatOptionCollections(options);
}

class _CookLabels {
  const _CookLabels({required this.subtitle, required this.details});

  final String subtitle;
  final String details;
}

_CookLabels _buildCookLabels({
  required String name,
  required String mealId,
  required List<String> ingredients,
  required String difficulty,
  required List<String> tags,
  required List<String> methods,
  required List<String> tools,
}) {
  final primaryTool = tools.isEmpty ? '家常厨具' : tools.first;
  final difficultyLabel = difficulty.isEmpty ? '家常难度' : difficulty;
  final highlight = tags.isNotEmpty
      ? tags.take(2).join(' / ')
      : ingredients.take(2).join(' / ');
  final subtitle = <String>[
    primaryTool,
    difficultyLabel,
    if (highlight.isNotEmpty) highlight,
  ].join(' · ');

  final methodLabel = methods.isEmpty ? '家常做法' : methods.join('、');
  final ingredientLabel = ingredients.isEmpty
      ? '常见家常食材'
      : ingredients.take(4).join('、');
  final tagLabel = tags.isEmpty ? '' : '风味重点是 ${tags.take(2).join('、')}。';
  final details =
      '$name 通常以 $ingredientLabel 为主，适合在 ${_mealHint(mealId)} 用 $primaryTool 通过 $methodLabel 完成。'
      '这类做法更强调先把食材和调味准备齐，再按火候稳稳推进。'
      '$tagLabel';

  return _CookLabels(subtitle: subtitle, details: details);
}

List<String> _buildCookMaterials({
  required List<String> ingredients,
  required List<String> methods,
  required List<String> tools,
}) {
  final materials = <String>[
    ...ingredients,
    ..._baseSeasonings(methods),
    if (_hasAnyIngredient(ingredients, <String>['鸡肉', '猪肉', '牛肉', '虾']))
      '料酒、胡椒或基础去腥调味（按口味可选）',
    if (_hasAnyIngredient(ingredients, <String>['米', '面食', '方便面', '面包']))
      '清水或高汤（按主食和口感调整）',
    if (_hasAnyTool(tools, <String>['烤箱', '空气炸锅'])) '烘焙纸或耐热容器（可选）',
  ];
  return _dedupeStrings(materials);
}

List<String> _buildCookSteps({
  required String name,
  required String mealId,
  required List<String> ingredients,
  required List<String> methods,
  required List<String> tools,
}) {
  return <String>[
    _buildPrepStep(ingredients),
    _buildToolStep(tools),
    _buildCoreStep(name, ingredients, methods, tools),
    _buildCombinationStep(ingredients),
    _buildSeasoningStep(methods),
    _buildFinishStep(mealId, tools),
  ];
}

List<String> _buildCookNotes({
  required String difficulty,
  required List<String> ingredients,
  required List<String> tools,
}) {
  final notes = <String>[
    switch (difficulty) {
      '困难' => '这道菜在 cook 数据里被标为“困难”，第一次做建议先完整读完步骤、预留更多时间，并把食材全部备好再开火。',
      '普通' => '这道菜在 cook 数据里被标为“普通”，关键在于切配整齐、火候别太急，先把流程走稳会更容易成功。',
      '简单' => '这道菜在 cook 数据里被标为“简单”，更适合工作日快速做，但依然建议先把厨具和调味准备齐。',
      _ => '这道菜没有明确难度标注，建议先按保守火候和基础调味来做，边做边看状态调整。',
    },
    if (_hasAnyIngredient(ingredients, <String>['鸡肉', '猪肉', '牛肉', '虾']))
      '肉类和虾类要以“中心完全熟透”为准，不要只看表面上色；担心翻车时，可以先把主料做熟，再和配菜合并。',
    if (_hasAnyIngredient(ingredients, <String>['土豆', '胡萝卜', '白萝卜']))
      '根茎类切得越均匀，熟度越一致；想缩短时间时，可以先焯一下或先微波预熟再进入主锅。',
    if (_hasAnyIngredient(ingredients, <String>['番茄']))
      '番茄类想要更有汤汁和鲜味，先把番茄加热到明显出汁，再和主料结合，味道通常会更稳。',
    if (_hasAnyTool(tools, <String>['微波炉']))
      '微波炉做菜请分段加热，每一轮都检查容器、液体和边缘熟度，防止局部过头或溢出。',
    if (_hasAnyTool(tools, <String>['空气炸锅', '烤箱']))
      '烘烤类菜中途翻面或换位一次，颜色和熟度会更均匀；表面过快变深时，优先降温或缩短尾段时间。',
    if (_hasAnyTool(tools, <String>['电饭煲']))
      '电饭煲类菜出锅前多焖 3 到 5 分钟，米饭和配菜的口感通常会更完整，也更方便收汁定型。',
  ];
  return notes.take(4).toList(growable: false);
}

List<String> _buildCookTags({
  required String difficulty,
  required List<String> tags,
  required List<String> methods,
  required List<String> tools,
}) {
  return _dedupeStrings(<String>[
    if (difficulty.isNotEmpty) difficulty,
    ...tags.take(3),
    ...methods.take(2),
    ...tools.take(2),
  ]);
}

List<DailyChoiceReferenceLink> _buildCookReferences(String? bv) {
  return <DailyChoiceReferenceLink>[
    const DailyChoiceReferenceLink(
      labelZh: 'cook 数据源（recipe.csv）',
      labelEn: 'cook recipe.csv',
      url: cookRecipeSourceUrl,
    ),
    if (bv != null && bv.isNotEmpty)
      DailyChoiceReferenceLink(
        labelZh: 'B 站教程视频',
        labelEn: 'Bilibili tutorial',
        url: 'https://www.bilibili.com/video/$bv',
      ),
    const DailyChoiceReferenceLink(
      labelZh: 'cook 做菜之前参考',
      labelEn: 'cook guide reference',
      url: cookSkillReadmeUrl,
    ),
  ];
}

List<String> _baseSeasonings(List<String> methods) {
  if (_hasAnyItem(methods, <String>['烤', '焗', '煎'])) {
    return const <String>['食用油或喷刷油', '盐', '黑胡椒、辣椒粉或常用干香料（按口味可选）'];
  }
  if (_hasAnyItem(methods, <String>['蒸'])) {
    return const <String>['盐', '少量油或葱花（按口味可选）'];
  }
  if (_hasAnyItem(methods, <String>['煮', '炖', '煲'])) {
    return const <String>['盐', '生抽或基础复合调味', '清水或高汤'];
  }
  return const <String>['食用油', '盐', '生抽或基础调味'];
}

String _buildPrepStep(List<String> ingredients) {
  if (_hasAnyIngredient(ingredients, <String>['鸡肉', '猪肉', '牛肉', '虾'])) {
    return '先把主要食材洗净并尽量切成大小一致；肉类或虾类擦干后可用少量盐、胡椒、料酒简单抓匀静置 10 分钟，蔬菜则尽量沥干水分，避免后面出水太多。';
  }
  return '先把食材洗净、沥水，并按厚薄和熟得快慢切成相近大小；这一步做得越整齐，后面越不容易出现有的熟过头、有的还夹生。';
}

String _buildToolStep(List<String> tools) {
  if (_hasAnyTool(tools, <String>['电饭煲'])) {
    return '如果用电饭煲，先把内胆和水量思路理顺：焖饭类优先处理米和耐煮食材，非饭类则确认是否需要垫水、架蒸盘或留足焖煮时间。';
  }
  if (_hasAnyTool(tools, <String>['微波炉'])) {
    return '如果用微波炉，务必选耐热容器并留出蒸汽出口；采用分段加热，每一轮后取出翻拌或检查中心熟度，稳定性会明显更高。';
  }
  if (_hasAnyTool(tools, <String>['空气炸锅'])) {
    return '如果用空气炸锅，先预热 3 到 5 分钟，食材表面薄薄刷油并尽量单层摆放，中途翻面一次，颜色和口感会更均匀。';
  }
  if (_hasAnyTool(tools, <String>['烤箱'])) {
    return '如果用烤箱，先完成预热、铺纸和分区摆放；厚薄差异较大的食材不要挤成一团，这样中途才方便看颜色、换位和调整时间。';
  }
  return '如果用一口大锅，先决定是热油出香还是先烧水/加汤，再按“耐煮食材先下、易熟食材后下”的原则安排顺序。';
}

String _buildCoreStep(
  String name,
  List<String> ingredients,
  List<String> methods,
  List<String> tools,
) {
  if (_hasAnyTool(tools, <String>['电饭煲']) &&
      _hasAnyIngredient(ingredients, <String>['米'])) {
    return '这类焖饭、煲饭或一锅出菜，通常先把米和耐煮配菜处理好，再把肉类或风味食材铺在上层，让锅内汁水慢慢渗进主食里。';
  }
  if (_hasAnyItem(methods, <String>['炒', '爆'])) {
    return '主锅阶段先让需要上色或出香的主料先下锅，再加入蔬菜和辅料，不要急着频繁加水；保持翻动但留一点锅气，家常味会更明显。';
  }
  if (_hasAnyItem(methods, <String>['煮', '炖', '煲'])) {
    return '如果是汤、炖或煲，先把主料和耐煮食材煮开或煸出香气，再补足液体转中小火，让味道慢慢融合，别一开始就追求重口。';
  }
  if (_hasAnyItem(methods, <String>['蒸'])) {
    return '蒸制类建议水开后再上锅，食材尽量铺平不要堆得太厚，期间少开盖，等中心位置完全熟透再收尾。';
  }
  if (_hasAnyItem(methods, <String>['烤', '焗', '煎'])) {
    return '把调过味的主料送入设备后，先按保守时间执行，中途观察上色和出油情况；表面快焦而内部未熟时，优先降温而不是继续硬烤。';
  }
  return '$name 属于典型家常路线，核心是先把主要食材做熟、把味道收稳，再决定是否补配菜、辅料或收汁。';
}

String _buildCombinationStep(List<String> ingredients) {
  if (_hasAnyIngredient(ingredients, <String>['土豆', '胡萝卜', '白萝卜'])) {
    return '像土豆、胡萝卜、白萝卜这类耐煮食材要更早加入；番茄、叶菜、鸡蛋这类更容易熟或更容易影响口感的材料，建议放在后半段。';
  }
  if (_hasAnyIngredient(ingredients, <String>['鸡蛋'])) {
    return '如果菜里带鸡蛋，通常放在中后段更稳：想吃嫩一点就缩短受热时间，想让它承担黏合或定型作用，就让它在最后阶段充分凝固。';
  }
  return '把食材按熟得快慢分批加入：香味底料先出香，主体食材先定型，容易出水或容易老的部分放到后段，整体节奏会更顺。';
}

String _buildSeasoningStep(List<String> methods) {
  if (_hasAnyItem(methods, <String>['煮', '炖', '煲'])) {
    return '临近收尾时再试味并补盐、生抽或胡椒，汤和炖菜尽量避免开头就下过重的调味，留一点尾段微调空间会更安全。';
  }
  return '接近完成时试一下咸淡和香气，再决定是否补一点盐、生抽、糖、胡椒或辣味；对新手来说，“最后补味”通常比“一开始重口”更稳。';
}

String _buildFinishStep(String mealId, List<String> tools) {
  final finishHint = switch (mealId) {
    'breakfast' => '早餐类注意别过咸过油，保持能轻松吃完。',
    'lunch' => '午餐类优先保证主食和蛋白质都到位，吃完不至于很快饿。',
    'dinner' => '晚餐类更适合把热菜、汤汁和口感收稳，别把调味越收越重。',
    'tea' => '下午茶和小吃类更要控制份量，做成小份通常更舒服。',
    'night' => '夜宵类尽量清淡一点，避免太重口影响后续休息。',
    _ => '出锅前确认熟度、口味和份量都合适。',
  };
  if (_hasAnyTool(tools, <String>['电饭煲'])) {
    return '出锅前先焖几分钟再翻拌，口感会更完整。$finishHint';
  }
  return '出锅前确认中心熟度、口味和表面状态都到位，再静置 1 到 2 分钟装盘。$finishHint';
}

String _classifyMeal(
  String name,
  List<String> ingredients,
  List<String> tags,
  List<String> methods,
  List<String> tools,
) {
  final combined = <String>[name, ...tags, ...methods, ...tools].join(' ');
  if (_hasAnyItem(tags, <String>['早餐', '早饭']) ||
      _containsAny(name, <String>[
        '早餐',
        '早饭',
        '粥',
        '花卷',
        '馒头',
        '奶黄包',
        '吐司',
        '蛋饼',
        '蛋卷',
        '蒸蛋',
      ])) {
    return 'breakfast';
  }
  if (_hasAnyItem(tags, <String>['深夜美食', '夜食']) ||
      _containsAny(name, <String>['泡面', '方便面', '夜食', '夜宵'])) {
    return 'night';
  }
  if (_hasAnyItem(tags, <String>['零食', '小吃']) ||
      _containsAny(name, <String>[
        '蛋糕',
        '布丁',
        '薯条',
        '薯片',
        '蛋挞',
        '面包',
        '慕斯',
        '饼干',
        '甜点',
      ])) {
    return 'tea';
  }
  if (_hasAnyItem(tags, <String>['主食', '减脂餐']) ||
      _containsAny(name, <String>[
        '焖饭',
        '炒饭',
        '煲饭',
        '饭团',
        '汉堡',
        '饭',
        '面',
        '便当',
        '粥',
      ])) {
    return 'lunch';
  }
  if (_hasAnyItem(tags, <String>['下饭']) ||
      _containsAny(combined, <String>['汤', '煲', '炖', '火锅', '鸡翅', '排骨', '硬菜'])) {
    return 'dinner';
  }
  if (_hasAnyTool(tools, <String>['微波炉']) &&
      !_hasAnyIngredient(ingredients, <String>['鸡肉', '猪肉', '牛肉', '虾'])) {
    return 'breakfast';
  }
  return _hasAnyIngredient(ingredients, <String>['米', '面食', '方便面'])
      ? 'lunch'
      : 'dinner';
}

String _mealHint(String mealId) {
  return switch (mealId) {
    'breakfast' => '早上想吃点热的、轻一点的时候',
    'lunch' => '午餐需要主食和满足感的时候',
    'dinner' => '晚餐想吃热菜或汤的时候',
    'tea' => '下午嘴馋、想来点小食的时候',
    'night' => '夜里真饿了但又不想太折腾的时候',
    _ => '今天想快点吃上饭的时候',
  };
}

String _cell(List<dynamic> row, int index) {
  if (index >= row.length) {
    return '';
  }
  return '${row[index]}'.trim();
}

List<String> _splitCookItems(String raw) {
  if (raw.trim().isEmpty) {
    return const <String>[];
  }
  return raw
      .split(RegExp(r'[、，]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String? _cleanBv(String raw) {
  final value = raw.trim().replaceAll('https://www.bilibili.com/video/', '');
  if (value.isEmpty) {
    return null;
  }
  return value;
}

String _normalizedKey(String raw) {
  return raw
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String? _cookToolId(String raw) {
  if (raw.contains('电饭煲')) {
    return 'rice_cooker';
  }
  if (raw.contains('微波炉')) {
    return 'microwave';
  }
  if (raw.contains('空气炸锅')) {
    return 'air_fryer';
  }
  if (raw.contains('烤箱')) {
    return 'oven';
  }
  if (raw.contains('大锅')) {
    return 'pot';
  }
  return null;
}

bool _hasAnyIngredient(List<String> ingredients, List<String> candidates) {
  return _hasAnyItem(ingredients, candidates);
}

bool _hasAnyTool(List<String> tools, List<String> candidates) {
  return _hasAnyItem(tools, candidates);
}

bool _hasAnyItem(List<String> items, List<String> candidates) {
  for (final item in items) {
    if (_containsAny(item, candidates)) {
      return true;
    }
  }
  return false;
}

bool _containsAny(String raw, List<String> candidates) {
  for (final candidate in candidates) {
    if (raw.contains(candidate)) {
      return true;
    }
  }
  return false;
}

Map<String, Object?> _decodeDailyChoiceLibraryJson(String rawJson) {
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map) {
    return const <String, Object?>{};
  }
  return decoded.cast<String, Object?>();
}

List<String> _dedupeStrings(List<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    result.add(normalized);
  }
  return result;
}
