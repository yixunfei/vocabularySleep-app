# 记录 070: 每日决策吃什么菜谱数据源审计

## 基本信息
- **生成时间**: 2026-04-27T00:39:40.415866+00:00
- **菜谱总数**: 7179
- **摘要总数**: 7179
- **cook recipe.csv 行数**: 599
- **SQLite 摘要行数**: 7179

## 关键结论
1. `YunYouJun/cook` 当前没有作为独立默认菜谱集导入：recipe.csv 共 599 行，当前库标题精确命中 30 行，未命中 569 行。
2. 素食/纯素字段存在高风险冲突：`vegetarian` 与肉类/海鲜冲突 530 条，`vegan_friendly` 与动物性食材冲突 496 条。
3. 菜系信息当前混在 notes 中且缺少可信度边界：含菜系标签 notes 共 2221 条，其中西式/非中式标记却带中式菜系 notes 的高疑似错配 30 条。
4. `清真友好` 说明被写入菜谱 notes 3416 条，属于 UI/规则说明污染菜谱正文。
5. 食材别名存在过宽匹配：`洋葱` 额外索引为 `葱` 143 条；排骨/猪油等具体猪肉项折叠到粗粒度猪肉/contains:pork 1529 条。

## 数据源覆盖
- cook CSV 缺失样例: 电饭煲版广式腊肠煲饭, 电饭煲版烧鸡, 电饭煲焖面, 电饭煲版番茄牛腩焖饭, 电饭煲版蜜汁鸡翅, 电饭煲版南瓜鸡腿焖饭, 电饭煲版土豆排骨焖饭, 电饭煲版香菇腊肠焖饭
- 0 提取书籍数: 7
- 摘要行 sourceLabel/sourceUrl: 0
- 摘要行 references: 0

## 问题桶

### vegetarian_profile_conflicts_with_meat_or_seafood
- **优先级**: P0
- **数量**: 530
- **说明**: profile contains vegetarian while contains includes meat or seafood.
- `library_八宝锅蒸` 八宝锅蒸 (conflict=['pork']; materials=大米粉 面粉各45克 蜜瓜片 蜜枣 核桃仁各10克 莲子 扁豆各15克 蜜樱桃15个 橘红6克 熟猪油 白糖各120克)
- `library_兔肉粥` 兔肉粥 (conflict=['pork']; materials=兔肉 粳米 马蹄各100克 水发香菇50克 精盐 味精 胡椒 猪油 葱姜末各少许)
- `library_八卦粥` 八卦粥 (conflict=['pork']; materials=活龟肉100克 粳米200克 核桃仁50克 猪油 香油 葱白 花椒 姜 盐 味精各少许)
- `library_牡蛎粥` 牡蛎粥 (conflict=['pork']; materials=鲜牡蛎肉60克 糯米60克 猪瘦肉30克 料酒 盐 猪油 大蒜末 葱头末 味精 胡椒粉各适量)
- `library_胡萝卜粥` 胡萝卜粥 (conflict=['pork']; materials=胡萝卜二两 糯米二两 香菜二钱 猪油三钱 精盐一钱 味精二分 清水二斤)

### vegan_friendly_conflicts_with_animal_contains
- **优先级**: P0
- **数量**: 496
- **说明**: diet contains vegan_friendly while contains includes animal ingredients.
- `library_八宝锅蒸` 八宝锅蒸 (conflict=['pork']; materials=大米粉 面粉各45克 蜜瓜片 蜜枣 核桃仁各10克 莲子 扁豆各15克 蜜樱桃15个 橘红6克 熟猪油 白糖各120克)
- `library_五谷豆糙米粥` 五谷豆糙米粥 (conflict=['egg']; materials=黑豆 红豆 黄豆 绿豆 米豆 糙米各1/2杯 调味料:糖1--2大匙)
- `library_什锦甜粥` 什锦甜粥 (conflict=['egg']; materials=小米100克 大米50克 绿豆30克 花生米25克 红枣50克 核桃仁25克 葡萄干50克 辅料:红糖或白糖适量)
- `library_兔肉粥` 兔肉粥 (conflict=['pork']; materials=兔肉 粳米 马蹄各100克 水发香菇50克 精盐 味精 胡椒 猪油 葱姜末各少许)
- `library_八卦粥` 八卦粥 (conflict=['pork']; materials=活龟肉100克 粳米200克 核桃仁50克 猪油 香油 葱白 花椒 姜 盐 味精各少许)

### vegetarian_profile_with_unmodeled_animal_terms
- **优先级**: P0
- **数量**: 230
- **说明**: profile vegetarian was inferred even though raw text includes animal terms not modeled in canonical meat detection.
- `library_兔肉粥` 兔肉粥 (matchedTerms=['兔肉']; materials=兔肉 粳米 马蹄各100克 水发香菇50克 精盐 味精 胡椒 猪油 葱姜末各少许)
- `library_八卦粥` 八卦粥 (matchedTerms=['龟肉']; materials=活龟肉100克 粳米200克 核桃仁50克 猪油 香油 葱白 花椒 姜 盐 味精各少许)
- `library_牡蛎粥` 牡蛎粥 (matchedTerms=['牡蛎']; materials=鲜牡蛎肉60克 糯米60克 猪瘦肉30克 料酒 盐 猪油 大蒜末 葱头末 味精 胡椒粉各适量)
- `library_百合田鸡粥` 百合田鸡粥 (matchedTerms=['牛蛙', '田鸡']; materials=田鸡500克 猪瘦肉100克 太子参60克 百合30克 普通大米(或粳米)150克 葱 青豆少许 盐 麻油少许)
- `library_鹌鹑山药粥` 鹌鹑山药粥 (matchedTerms=['鹌鹑']; materials=鹌鹑2只 山药50克 粳米100克 姜 葱 盐各适量)

### recipe_notes_contain_halal_explanation
- **优先级**: P1
- **数量**: 3416
- **说明**: Generated halal disclaimer was written into recipe notes instead of staying in UI/help copy.
- `library_茄片吐司` 茄片吐司 (notes=回味微甜色泽宜人, 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_五谷蛋包饭` 五谷蛋包饭 (notes=鲜咸适口,好吃好看不油腻. 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_三仙糕` 三仙糕 (notes=健脾胃,补元气。 用法:可作早餐酌量用。 应用:适用于脾胃虚弱食少便溏者。 俞小平、黄志杰主编 科学技术文献出版社出版 健脾胃,补元气 其它菜系 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_人参薯蓣糕` 人参薯蓣糕 (notes=健脾胃,补元气。 用法:可作早餐随量食用。 应用:适用于脾虚食少乏力之人。 俞小平、黄志杰主编 科学技术文献出版社出版 健脾胃,补元气 其它菜系 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_八仙糕` 八仙糕 (notes=益脾胃,止泄泻。 用法:作早餐酌量食用。 应用:适用于脾胃虚弱之人。 俞小平、黄志杰主编 科学技术文献出版社出版 益脾胃,止泄泻 其它菜系 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)

### recipe_notes_contain_cuisine_labels
- **优先级**: P1
- **数量**: 2221
- **说明**: Cuisine labels appear in free-form notes; they are not structured or source-confidence tracked.
- **分布**: 浙江菜: 840, 粤菜: 421, 川菜: 278, 鲁菜: 229, 苏菜: 210, 闽菜: 91, 湘菜: 59, 东北菜: 39, 西餐: 30, 徽菜: 22, 意大利: 4, 法式: 3, 西班牙: 1
- `library_茄片吐司` 茄片吐司 (cuisines=['浙江菜']; notes=回味微甜色泽宜人, 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_五谷蛋包饭` 五谷蛋包饭 (cuisines=['浙江菜']; notes=鲜咸适口,好吃好看不油腻. 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_海参炖瘦肉` 海参炖瘦肉 (cuisines=['粤菜']; notes=补肾益精,滋润肠燥。精血亏损,症见虚赢瘦弱,津枯便秘;或妇女闭经,或肾虚阳萎;或产后体虚血少之倦怠乏力,大便燥结等。亦可用于高血压、动脉粥样硬化症属阴液不足者。 粤菜 海鲜类食材需要以完全熟透为准,处理后尽量尽快烹调。 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_炒茄丝` 炒茄丝 (cuisines=['浙江菜']; notes=咸香,略带酸味,清素利口,适用于家庭早餐或午餐下酒。 浙江菜)
- `library_决明子粥` 决明子粥 (cuisines=['粤菜']; notes=该粥清肝、明目、通便。对于目赤红肿、畏光多泪、高血压、高血脂、习惯性便秘等症效果明显 粤菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)

### western_marker_with_chinese_cuisine_note
- **优先级**: P1
- **数量**: 30
- **说明**: Recipe title/materials look western or non-Chinese while notes contain a Chinese cuisine label.
- `library_茄片吐司` 茄片吐司 (materials=茄子四只 橄榄油150毫升 蒜瓣一枚 洋葱一或两只 盐 胡椒粉; notes=回味微甜色泽宜人, 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_五谷蛋包饭` 五谷蛋包饭 (materials=五谷饭1碗 鸡蛋3个 冰糖2大勺 苹果醋1大勺 盐少许 沙拉油260—300c.c. 莴苣1片 毛豆200g 面粉1大匙 盐 胡椒少许 番茄(大)2粒 香才适量 红扁豆10g; notes=鲜咸适口,好吃好看不油腻. 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_果酱三明治` 果酱三明治 (materials=主料 咸方包(或土司面包)250克 辅料 什锦果酱100克; notes=香甜、松软。 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_烤奶酪水饺皮` 烤奶酪水饺皮 (materials=水饺皮10张 奶酪酥片3片 葡萄干2大匙; notes=口味独特,香脆爽口。 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_芦笋手卷` 芦笋手卷 (materials=青芦笋 1斤 沙拉 1包 花生粉 少许 炒熟白芝麻 少许美生菜 半粒 烧海苔片1包; notes=补虚,养液,润肺,滑肠。适用于中老年及体弱早衰、产后体虚、头晕目眩、肺燥咳嗽咳血、慢性便秘等症 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)

### onion_alias_also_indexes_scallion
- **优先级**: P2
- **数量**: 143
- **说明**: Ingredient alias matching adds 葱 when only 洋葱 appears.
- `library_茄片吐司` 茄片吐司 (materials=茄子四只 橄榄油150毫升 蒜瓣一枚 洋葱一或两只 盐 胡椒粉)
- `library_咖喱蛋包饭` 咖喱蛋包饭 (materials=米饭100克 牛肉薄片70克 洋葱1/2个 蘑菇4朵 鸡蛋2个 酸奶20克 苹果泥10克 鲜汤 植物油 咖喱粉 咖喱块 奶油各适量)
- `library_泰国辣味烤魚` 泰国辣味烤魚 (materials=鱼肉8两 (1)蒜 辣椒 芫荽茎(切碎)各1/2大匙 洋葱末.4大匙 (2)鱼露.酸子汁各2大匙 糖.1大匙 高汤4大匙)
- `library_番茄芙蓉饭` 番茄芙蓉饭 (materials=米饭150克 豆腐150克 番茄100克 猪里脊肉片50克 洋葱半个 鸡蛋1个 奶酪丝40克 A.奶油 B.酱油 番茄酱 白糖 水淀粉各适量)
- `library_focaccia` Focaccia (materials=高筋面粉400克 低筋面粉100克 盐10克 酵母10克 冰水350克 披萨草叶50克 小番茄 黑橄榄 洋葱适量 海盐 橄榄油适量)

### specific_pork_cut_collapsed_to_generic_pork
- **优先级**: P2
- **数量**: 1529
- **说明**: Specific pork cuts are collapsed into generic 猪肉, which explains broad matches like 排骨 -> 猪肉.
- `library_马蹄松子鸭丁` 马蹄松子鸭丁 (materials=烤鸭500克 马蹄100克 松子(炒)30克 火腿 黑木耳 盐 料酒 鸡汤 味精各适量)
- `library_八宝锅蒸` 八宝锅蒸 (materials=大米粉 面粉各45克 蜜瓜片 蜜枣 核桃仁各10克 莲子 扁豆各15克 蜜樱桃15个 橘红6克 熟猪油 白糖各120克)
- `library_有益补气血的材料` 有益补气血的材料 (materials=白木耳 姜 牛肉 猪肝 牡蛎 蜂蜜 芥菜 昆布 葡萄干 金针 五谷 蛋黄 坚果类 红豆 牛奶 药材:红枣 桂圆 胡桃仁 人参 生地黄 熟地黄 当归 白芍 川芎 肉桂 玫瑰花 菊花)
- `library_兔肉粥` 兔肉粥 (materials=兔肉 粳米 马蹄各100克 水发香菇50克 精盐 味精 胡椒 猪油 葱姜末各少许)
- `library_八卦粥` 八卦粥 (materials=活龟肉100克 粳米200克 核桃仁50克 猪油 香油 葱白 花椒 姜 盐 味精各少许)

### garbled_text_markers
- **优先级**: P1
- **数量**: 8
- **说明**: Materials, steps, or notes contain extraction artifacts such as ?? or replacement glyphs.
- `library_万子酥鸭` 万子酥鸭 (materials=五香蒸鸭1只 白芝麻100克 鸡蛋200克 调料:植物油900克(实耗约80克) 面粉50克; notes=色金黄,外形美,肉酥脆,味浓香 浙江菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_什锦果盅` 什锦果盅 (materials=各种时令鲜果(如苹果 草蓉 菠萝 葡萄 西瓜等) 酸奶; notes=富含多种维生素,果香浓郁,色彩清新柔和,开胃爽,口。既可作为饭后甜食,也可当作冷饮随时享用。 其他 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)
- `library_凤尾虾排` 凤尾虾排 (materials=大青虾750克 精盐2克 料酒25克 葱 姜汁30克 花椒盐5克; notes=安徽名菜。淮河横贯安徽,湖泽众多??产大青虾。安徽名厨善制河虾,凤尾虾排较为著名。此菜造型美观,肉质 徽菜 海鲜类食材需要以完全熟透为准,处理后尽量尽快烹调。)
- `library_松鼠桂鱼` 松鼠桂鱼 (materials=桂鱼1条(约1.2公斤) 玉兰片50克 香菇50克 鲜豌豆25克 鸡蛋清90克 调料: 植物油800克(实耗约200克) 料酒25克 葱 姜 蒜各15克 盐 面??10克 味精4克 白糖120克 米醋50克 酱油25克 干菱粉100克 湿淀粉15克 鸡汤150克; notes=色泽金黄,形似松鼠,外焦里嫩,味浓醇香。 浙江菜 海鲜类食材需要以完全熟透为准,处理后尽量尽快烹调。)
- `library_海南椰子盅` 海南椰子盅 (materials=大椰子1个 水发银耳100克 冰糖100克; notes=粤菜 “清真友好”仅按配方中的猪肉和酒精风险做启发式筛选,不代表宗教或供应链认证。)

## 初步修正建议
1. 数据生成阶段不要再把 `halal_friendly`、`vegan_friendly`、`vegetarian_friendly` 这类高语义字段作为默认展示标签；先降级为可选筛选候选，并在无冲突时才写入索引。
2. 肉类判断不要只依赖 canonical ingredient；`contains` 与 `profile/diet` 应来自同一套原始材料风险词表，并覆盖兔、龟、鸽、牡蛎等当前漏建模动物食材。
3. 菜系不再写入 notes。若源资料明确给出菜系，后续迁移到 `recipe_filter_index(group=cuisine, confidence=source)`；无明确来源则留空。
4. 食材索引拆成 `raw_ingredient`、`canonical_ingredient`、`family_ingredient` 三层，默认匹配 raw/canonical，只有用户显式扩展时才用 family。
5. 将 YunYouJun/cook 的 `recipe.csv` 单独导入为默认 cook 菜谱集，保留 difficulty/methods/tools/tags/stuff 原始字段；本地书籍资料作为另一个可选资料集。
