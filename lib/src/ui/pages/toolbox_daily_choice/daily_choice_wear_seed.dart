part of 'daily_choice_seed_data.dart';

const String wearReferenceSourceLabel =
    '本地穿搭资料整理：基本穿搭 / 上班穿什么 / 职场穿衣的终极搭配 / 风格的练习 / 穿衣的基本 / 搭配其实很好玩 2 / 我的风格小黑皮书 / 用优衣库的价格穿出爱马仕的气质 / 绅士时尚';

final List<DailyChoiceOption> _wearOptions = <DailyChoiceOption>[
  _wear(
    id: 'wear_freezing_commute_long_down',
    temp: 'freezing',
    scene: 'commute',
    titleZh: '长款羽绒 + 羊毛针织 + 加绒直筒裤',
    subtitleZh: '严寒通勤先保暖，再把线条收利落。',
    materialsZh: <String>['发热内层或保暖背心', '长款羽绒与羊毛针织', '防滑短靴 + 围巾'],
    tagsZh: <String>['保暖', '基础款'],
  ),
  _wear(
    id: 'wear_freezing_commute_wool_coat',
    temp: 'freezing',
    scene: 'commute',
    titleZh: '羊毛大衣 + 高领针织 + 厚呢长裤',
    subtitleZh: '适合办公室与地铁之间切换的冷天通勤。',
    materialsZh: <String>['贴身打底', '高领针织与羊毛大衣', '抓地鞋底皮鞋或短靴'],
    tagsZh: <String>['通勤', '克制'],
  ),
  _wear(
    id: 'wear_freezing_casual_parka',
    temp: 'freezing',
    scene: 'casual',
    titleZh: '连帽派克大衣 + 抓绒卫衣 + 灯芯绒裤',
    subtitleZh: '周末出门舒服、耐坐，也能挡风。',
    materialsZh: <String>['保暖内层', '抓绒卫衣与派克大衣', '厚袜 + 休闲靴'],
    tagsZh: <String>['松弛', '挡风'],
  ),
  _wear(
    id: 'wear_freezing_casual_short_down',
    temp: 'freezing',
    scene: 'casual',
    titleZh: '短羽绒 + 厚卫衣 + 直筒牛仔裤',
    subtitleZh: '外出走动多时，比长外套更轻快。',
    materialsZh: <String>['保暖打底', '短羽绒与厚卫衣', '直筒牛仔 + 运动鞋'],
    tagsZh: <String>['轻快', '日常'],
  ),
  _wear(
    id: 'wear_freezing_business_dark_tailoring',
    temp: 'freezing',
    scene: 'business',
    titleZh: '双面呢大衣 + 细针高领 + 深色西裤',
    subtitleZh: '正式场景尽量少层次、少花色，把质感放前面。',
    materialsZh: <String>['贴身保暖内搭', '细针高领与呢大衣', '深色西裤 + 皮鞋'],
    tagsZh: <String>['正式', '质感'],
  ),
  _wear(
    id: 'wear_freezing_date_soft_texture',
    temp: 'freezing',
    scene: 'date',
    titleZh: '软糯毛衣 + 长外套 + 半裙或阔腿裤',
    subtitleZh: '一处柔软材质就足够让冷天约会更有记忆点。',
    materialsZh: <String>['柔软针织主上装', '长外套', '短靴 + 小型配饰'],
    tagsZh: <String>['柔和', '记忆点'],
  ),
  _wear(
    id: 'wear_freezing_exercise_thermal_run',
    temp: 'freezing',
    scene: 'exercise',
    titleZh: '保暖打底 + 抓绒运动外套 + 训练长裤',
    subtitleZh: '出门前别贪轻，热起来再按需脱外层。',
    materialsZh: <String>['排汗保暖打底', '抓绒外套', '训练长裤 + 抓地跑鞋'],
    tagsZh: <String>['运动', '排汗'],
  ),
  _wear(
    id: 'wear_freezing_rain_shell_down',
    temp: 'freezing',
    scene: 'rain',
    titleZh: '防水壳层 + 轻羽绒内胆 + 防水抓地鞋',
    subtitleZh: '冷雨天先保脚和外层，里面反而不要堆太厚。',
    materialsZh: <String>['速干内层', '防水壳层 + 轻羽绒内胆', '防水鞋 + 雨伞'],
    tagsZh: <String>['雨天', '防滑'],
  ),
  _wear(
    id: 'wear_cold_commute_vest_trench',
    temp: 'cold',
    scene: 'commute',
    titleZh: '薄羽绒背心 + 风衣 + 细针织',
    subtitleZh: '0 到 10°C 的通勤，最稳妥的是可穿脱叠层。',
    materialsZh: <String>['衬衫或长袖打底', '薄羽绒背心 + 风衣', '直筒裤 + 乐福鞋'],
    tagsZh: <String>['分层', '通勤'],
  ),
  _wear(
    id: 'wear_cold_commute_short_coat',
    temp: 'cold',
    scene: 'commute',
    titleZh: '短呢外套 + 衬衫针织叠穿 + 九分裤',
    subtitleZh: '室内外切换频繁时，比一味加厚更实用。',
    materialsZh: <String>['衬衫与细针织', '短呢外套', '九分裤 + 短靴'],
    tagsZh: <String>['叠穿', '利落'],
  ),
  _wear(
    id: 'wear_cold_casual_duffle',
    temp: 'cold',
    scene: 'casual',
    titleZh: '牛角扣大衣 + 连帽卫衣 + 工装裤',
    subtitleZh: '休闲场景保留一点量感，舒服又有层次。',
    materialsZh: <String>['柔软内搭', '牛角扣大衣 + 卫衣', '工装裤 + 休闲靴'],
    tagsZh: <String>['层次', '休闲'],
  ),
  _wear(
    id: 'wear_cold_casual_cardigan_denim',
    temp: 'cold',
    scene: 'casual',
    titleZh: '厚开衫 + 白T + 深色牛仔裤',
    subtitleZh: '在室内停留较久时，比厚外套更轻松。',
    materialsZh: <String>['白T 或薄打底', '厚开衫', '深色牛仔 + 运动鞋'],
    tagsZh: <String>['轻松', '室内友好'],
  ),
  _wear(
    id: 'wear_cold_business_blazer_wool',
    temp: 'cold',
    scene: 'business',
    titleZh: '西装外套 + 细羊毛衫 + 深色西裤',
    subtitleZh: '正式场景保持干净轮廓，减少臃肿感。',
    materialsZh: <String>['贴身打底', '细羊毛衫 + 西装外套', '深色西裤 + 皮鞋'],
    tagsZh: <String>['正式', '克制'],
  ),
  _wear(
    id: 'wear_cold_business_long_cardigan',
    temp: 'cold',
    scene: 'business',
    titleZh: '长开衫外套 + 领口干净的上装 + 锥形裤',
    subtitleZh: '气场不必太硬，但版型和整洁度要守住。',
    materialsZh: <String>['衬衫或针织上装', '长开衫外套', '锥形裤 + 乐福鞋'],
    tagsZh: <String>['稳妥', '整洁'],
  ),
  _wear(
    id: 'wear_cold_date_cardigan_satin',
    temp: 'cold',
    scene: 'date',
    titleZh: '开衫 + 缎面或垂感上装 + 高腰下装',
    subtitleZh: '用柔和材质提气质，不靠复杂花样。',
    materialsZh: <String>['柔软针织或缎面上装', '轻外套', '高腰裤或长裙 + 短靴'],
    tagsZh: <String>['柔和', '比例'],
  ),
  _wear(
    id: 'wear_cold_exercise_vest_training',
    temp: 'cold',
    scene: 'exercise',
    titleZh: '速干长袖 + 轻保暖马甲 + 跑步长裤',
    subtitleZh: '冷天运动要留一点热身空间，不要一出门就过热。',
    materialsZh: <String>['速干长袖', '轻保暖马甲', '跑步长裤 + 跑鞋'],
    tagsZh: <String>['运动', '热身'],
  ),
  _wear(
    id: 'wear_cold_rain_trench_quickdry',
    temp: 'cold',
    scene: 'rain',
    titleZh: '防水风衣 + 薄抓绒 + 防滑鞋',
    subtitleZh: '寒冷雨天的重点是外层防水、下装不拖地。',
    materialsZh: <String>['快干内层', '防水风衣 + 薄抓绒', '九分裤 + 防滑鞋'],
    tagsZh: <String>['快干', '雨天'],
  ),
  _wear(
    id: 'wear_cool_commute_blazer_tee',
    temp: 'cool',
    scene: 'commute',
    titleZh: '西装外套 + 长袖T + 牛仔直筒裤',
    subtitleZh: '10 到 15°C 最适合用轻外套稳住通勤气质。',
    materialsZh: <String>['长袖T', '西装外套', '牛仔直筒裤 + 乐福鞋'],
    tagsZh: <String>['轻外套', '通勤'],
  ),
  _wear(
    id: 'wear_cool_commute_trench_stripe',
    temp: 'cool',
    scene: 'commute',
    titleZh: '短风衣 + 条纹衫 + 锥形裤',
    subtitleZh: '温度不低但有风时，这套很稳。',
    materialsZh: <String>['条纹长袖或衬衫', '短风衣', '锥形裤 + 皮鞋'],
    tagsZh: <String>['有风', '利落'],
  ),
  _wear(
    id: 'wear_cool_casual_denim_hoodie',
    temp: 'cool',
    scene: 'casual',
    titleZh: '牛仔外套 + 连帽卫衣 + 休闲裤',
    subtitleZh: '休闲感足够，但结构仍然清楚。',
    materialsZh: <String>['轻卫衣', '牛仔外套', '休闲裤 + 运动鞋'],
    tagsZh: <String>['层次', '日常'],
  ),
  _wear(
    id: 'wear_cool_casual_cardigan_khaki',
    temp: 'cool',
    scene: 'casual',
    titleZh: '轻针织开衫 + 白T + 卡其裤',
    subtitleZh: '适合在办公室、咖啡店和散步之间切换。',
    materialsZh: <String>['白T', '轻针织开衫', '卡其裤 + 板鞋'],
    tagsZh: <String>['基础款', '轻松'],
  ),
  _wear(
    id: 'wear_cool_business_vest_shirt',
    temp: 'cool',
    scene: 'business',
    titleZh: '衬衫 + 轻针织马甲 + 西装裤',
    subtitleZh: '比单穿衬衫更完整，也比厚外套更轻盈。',
    materialsZh: <String>['干净衬衫', '针织马甲', '西装裤 + 皮鞋'],
    tagsZh: <String>['正式', '轻盈'],
  ),
  _wear(
    id: 'wear_cool_date_soft_blazer',
    temp: 'cool',
    scene: 'date',
    titleZh: '软西装 + 针织上衣 + 垂感下装',
    subtitleZh: '冷一点的约会穿搭，重点是柔和而不是堆砌。',
    materialsZh: <String>['针织主上装', '软西装外套', '垂感下装 + 小配饰'],
    tagsZh: <String>['柔和', '垂感'],
  ),
  _wear(
    id: 'wear_cool_date_knit_dress',
    temp: 'cool',
    scene: 'date',
    titleZh: '针织开衫 + 连衣裙或高腰裤',
    subtitleZh: '把重点留给比例和材质，而不是夸张配色。',
    materialsZh: <String>['轻薄内搭', '针织开衫', '连衣裙或高腰裤 + 短靴'],
    tagsZh: <String>['比例', '柔软'],
  ),
  _wear(
    id: 'wear_cool_exercise_light_shell',
    temp: 'cool',
    scene: 'exercise',
    titleZh: '速干上衣 + 轻防风外套 + 训练裤',
    subtitleZh: '出门凉、运动热，这一档最需要能脱能穿。',
    materialsZh: <String>['速干上衣', '轻防风外套', '训练裤 + 跑鞋'],
    tagsZh: <String>['防风', '灵活'],
  ),
  _wear(
    id: 'wear_cool_rain_light_shell',
    temp: 'cool',
    scene: 'rain',
    titleZh: '轻防水外套 + 九分裤 + 防滑运动鞋',
    subtitleZh: '不要让裤脚和鞋面吸满水，整体就会轻很多。',
    materialsZh: <String>['快干打底', '轻防水外套', '九分裤 + 防滑鞋'],
    tagsZh: <String>['防水', '轻便'],
  ),
  _wear(
    id: 'wear_mild_commute_shirt_vest',
    temp: 'mild',
    scene: 'commute',
    titleZh: '衬衫 + 薄针织背心 + 九分西装裤',
    subtitleZh: '温和天气最适合用小层次增加完成度。',
    materialsZh: <String>['衬衫', '薄针织背心', '九分西装裤 + 乐福鞋'],
    tagsZh: <String>['通勤', '小层次'],
  ),
  _wear(
    id: 'wear_mild_commute_polo_trousers',
    temp: 'mild',
    scene: 'commute',
    titleZh: 'Polo 针织 + 宽松西裤 + 腰带',
    subtitleZh: '不想叠层时，用领口和裤型把精气神拉起来。',
    materialsZh: <String>['Polo 针织', '宽松西裤', '腰带 + 乐福鞋'],
    tagsZh: <String>['轻正式', '省力'],
  ),
  _wear(
    id: 'wear_mild_casual_cardigan_jeans',
    temp: 'mild',
    scene: 'casual',
    titleZh: '轻开衫 + 白T + 直筒牛仔裤',
    subtitleZh: '温和天的万能公式，出错率很低。',
    materialsZh: <String>['白T', '轻开衫', '直筒牛仔 + 运动鞋'],
    tagsZh: <String>['万能', '基础款'],
  ),
  _wear(
    id: 'wear_mild_casual_shirt_khaki',
    temp: 'mild',
    scene: 'casual',
    titleZh: '短袖衬衫 + 卡其裤或工装半裙',
    subtitleZh: '比纯 T 恤更有完成度，又不会太正式。',
    materialsZh: <String>['短袖衬衫', '卡其裤或工装半裙', '帆布鞋'],
    tagsZh: <String>['轻松', '有型'],
  ),
  _wear(
    id: 'wear_mild_business_drapey_shirt',
    temp: 'mild',
    scene: 'business',
    titleZh: '垂感衬衫 + 西装裤 + 干净皮鞋',
    subtitleZh: '用垂感和整洁度营造专业感，不必把层数堆上去。',
    materialsZh: <String>['垂感衬衫', '西装裤', '皮鞋 + 腰带或腕表'],
    tagsZh: <String>['专业', '整洁'],
  ),
  _wear(
    id: 'wear_mild_business_light_blazer',
    temp: 'mild',
    scene: 'business',
    titleZh: '无里西装 + 干净内搭 + 锥形裤',
    subtitleZh: '会议和见人较多时，这套会比纯衬衫更稳。',
    materialsZh: <String>['干净内搭', '无里西装', '锥形裤 + 皮鞋'],
    tagsZh: <String>['会议', '稳妥'],
  ),
  _wear(
    id: 'wear_mild_date_knit_wide',
    temp: 'mild',
    scene: 'date',
    titleZh: '修身针织 + 高腰阔腿裤 + 小耳饰',
    subtitleZh: '用比例和一个小亮点提升气质最稳妥。',
    materialsZh: <String>['修身针织', '高腰阔腿裤', '小耳饰或细项链'],
    tagsZh: <String>['比例', '亮点'],
  ),
  _wear(
    id: 'wear_mild_date_shirtdress',
    temp: 'mild',
    scene: 'date',
    titleZh: '轻薄衬衫裙或衬衫 + 小外套',
    subtitleZh: '早晚有温差时，一件轻外层刚好让整体更完整。',
    materialsZh: <String>['衬衫裙或衬衫', '轻外套', '低跟鞋或乐福鞋'],
    tagsZh: <String>['温差', '柔和'],
  ),
  _wear(
    id: 'wear_mild_exercise_easy_run',
    temp: 'mild',
    scene: 'exercise',
    titleZh: '速干T + 弹力下装 + 轻跑鞋',
    subtitleZh: '最适合动起来的温度，重点是排汗和自由度。',
    materialsZh: <String>['速干T', '弹力长裤或短裤', '轻跑鞋 + 发带'],
    tagsZh: <String>['排汗', '自由度'],
  ),
  _wear(
    id: 'wear_mild_rain_lightcoat',
    temp: 'mild',
    scene: 'rain',
    titleZh: '轻薄防雨衫 + 速干下装 + 折叠伞',
    subtitleZh: '别穿吸水变重的单品，整天会轻松很多。',
    materialsZh: <String>['速干上装', '轻薄防雨衫', '九分下装 + 防滑鞋'],
    tagsZh: <String>['雨天', '快干'],
  ),
  _wear(
    id: 'wear_warm_commute_linen',
    temp: 'warm',
    scene: 'commute',
    titleZh: '亚麻衬衫 + 轻薄长裤',
    subtitleZh: '25 到 30°C 的通勤，专业感和透气感要同时在场。',
    materialsZh: <String>['亚麻或薄棉衬衫', '轻薄长裤', '透气鞋履'],
    tagsZh: <String>['透气', '通勤'],
  ),
  _wear(
    id: 'wear_warm_commute_cooling_polo',
    temp: 'warm',
    scene: 'commute',
    titleZh: '冷感 Polo + 九分西装裤',
    subtitleZh: '比普通 T 恤更稳，又比长袖衬衫轻松。',
    materialsZh: <String>['冷感 Polo', '九分西装裤', '乐福鞋 + 简洁包'],
    tagsZh: <String>['省力', '专业'],
  ),
  _wear(
    id: 'wear_warm_casual_cotton_linen',
    temp: 'warm',
    scene: 'casual',
    titleZh: '棉麻短袖 + 宽松长裤',
    subtitleZh: '遮阳和通风可以同时做到，不必一味穿短。',
    materialsZh: <String>['棉麻短袖', '宽松长裤', '凉感鞋履'],
    tagsZh: <String>['透气', '松弛'],
  ),
  _wear(
    id: 'wear_warm_casual_loose_tee',
    temp: 'warm',
    scene: 'casual',
    titleZh: '宽松 T 恤 + 轻薄工装短裤或长裙',
    subtitleZh: '走动和久坐都舒服，适合普通周末。',
    materialsZh: <String>['宽松 T 恤', '工装短裤或长裙', '运动凉鞋或板鞋'],
    tagsZh: <String>['周末', '舒展'],
  ),
  _wear(
    id: 'wear_warm_casual_knit_short_sleeve',
    temp: 'warm',
    scene: 'casual',
    titleZh: '短袖针织 + 阔腿裤 + 简洁凉鞋',
    subtitleZh: '想比普通短袖更精致一点时，这套很合适。',
    materialsZh: <String>['短袖针织', '阔腿裤', '简洁凉鞋 + 小包'],
    tagsZh: <String>['精致', '轻松'],
  ),
  _wear(
    id: 'wear_warm_business_short_sleeve',
    temp: 'warm',
    scene: 'business',
    titleZh: '短袖衬衫 + 垂感西裤',
    subtitleZh: '天气热时减少层数，用线条和面料维持正式感。',
    materialsZh: <String>['短袖衬衫', '垂感西裤', '皮鞋或闭口乐福'],
    tagsZh: <String>['正式', '少层数'],
  ),
  _wear(
    id: 'wear_warm_date_satin_light',
    temp: 'warm',
    scene: 'date',
    titleZh: '缎面背心或薄衬衫 + 高腰下装',
    subtitleZh: '轻一点的光泽和垂感，比复杂印花更稳。',
    materialsZh: <String>['缎面或轻薄上装', '高腰下装', '小配饰 + 低跟鞋'],
    tagsZh: <String>['垂感', '约会'],
  ),
  _wear(
    id: 'wear_warm_exercise_quickdry',
    temp: 'warm',
    scene: 'exercise',
    titleZh: '速干短袖 + 透气短裤 + 运动帽',
    subtitleZh: '这个温度动起来会很快发热，越轻越舒服。',
    materialsZh: <String>['速干短袖', '透气短裤', '跑鞋 + 运动帽'],
    tagsZh: <String>['轻量', '透气'],
  ),
  _wear(
    id: 'wear_warm_rain_quickdry',
    temp: 'warm',
    scene: 'rain',
    titleZh: '轻防泼外套 + 速干T + 九分裤',
    subtitleZh: '暖雨天气最怕湿闷，所以快干比厚更重要。',
    materialsZh: <String>['速干T', '轻防泼外套', '九分裤 + 防滑鞋'],
    tagsZh: <String>['快干', '轻外层'],
  ),
  _wear(
    id: 'wear_hot_commute_polo',
    temp: 'hot',
    scene: 'commute',
    titleZh: '冷感 Polo + 轻薄锥形裤',
    subtitleZh: '炎热通勤要兼顾体面和散热，领口会很有用。',
    materialsZh: <String>['冷感 Polo', '轻薄锥形裤', '透气鞋 + 防晒伞'],
    tagsZh: <String>['散热', '通勤'],
  ),
  _wear(
    id: 'wear_hot_commute_shirt',
    temp: 'hot',
    scene: 'commute',
    titleZh: '短袖衬衫 + 超薄西装裤',
    subtitleZh: '必须见人时，比普通短袖更显精神。',
    materialsZh: <String>['短袖衬衫', '超薄西装裤', '透气鞋履'],
    tagsZh: <String>['见人', '清爽'],
  ),
  _wear(
    id: 'wear_hot_commute_functional',
    temp: 'hot',
    scene: 'commute',
    titleZh: '功能衬衫 + 九分裤 + 防晒配件',
    subtitleZh: '长时间在路上时，功能面料会比纯造型更重要。',
    materialsZh: <String>['功能衬衫', '九分裤', '防晒伞或防晒袖'],
    tagsZh: <String>['功能面料', '防晒'],
  ),
  _wear(
    id: 'wear_hot_casual_cotton_linen',
    temp: 'hot',
    scene: 'casual',
    titleZh: '浅色棉麻上衣 + 宽松短裤',
    subtitleZh: '把透气和浅色放前面，体感会差很多。',
    materialsZh: <String>['浅色棉麻上衣', '宽松短裤', '透气凉鞋'],
    tagsZh: <String>['浅色', '透气'],
  ),
  _wear(
    id: 'wear_hot_casual_uv_shirt',
    temp: 'hot',
    scene: 'casual',
    titleZh: '宽松背心或短袖 + 防晒衬衫',
    subtitleZh: '在空调和烈日之间切换时，这套比单穿更稳。',
    materialsZh: <String>['背心或短袖', '防晒衬衫', '凉感下装 + 凉鞋'],
    tagsZh: <String>['防晒', '可穿脱'],
  ),
  _wear(
    id: 'wear_hot_business_clean_shirt',
    temp: 'hot',
    scene: 'business',
    titleZh: '清爽衬衫 + 轻薄直筒裤',
    subtitleZh: '正式感由干净和挺括来撑，不靠厚重层次。',
    materialsZh: <String>['清爽衬衫', '轻薄直筒裤', '闭口鞋履'],
    tagsZh: <String>['挺括', '正式'],
  ),
  _wear(
    id: 'wear_hot_date_drapey',
    temp: 'hot',
    scene: 'date',
    titleZh: '垂感无袖或短袖上装 + 轻盈下装',
    subtitleZh: '热天气约会越要靠面料和轮廓，不要贪复杂。',
    materialsZh: <String>['垂感上装', '轻盈下装', '小型配饰 + 凉鞋'],
    tagsZh: <String>['轻盈', '垂感'],
  ),
  _wear(
    id: 'wear_hot_exercise_run',
    temp: 'hot',
    scene: 'exercise',
    titleZh: '速干背心或短袖 + 跑步短裤 + 遮阳帽',
    subtitleZh: '30°C 以上运动尽量缩短时长，把补水放前面。',
    materialsZh: <String>['速干背心或短袖', '跑步短裤', '跑鞋 + 遮阳帽'],
    tagsZh: <String>['补水', '高温'],
  ),
  _wear(
    id: 'wear_hot_rain_quickdry',
    temp: 'hot',
    scene: 'rain',
    titleZh: '快干T + 防滑凉鞋 + 折叠伞',
    subtitleZh: '闷热雨天的关键不是厚，是尽快干。',
    materialsZh: <String>['快干T', '轻薄短裤或九分裤', '防滑凉鞋 + 折叠伞'],
    tagsZh: <String>['闷热', '快干'],
  ),
  _wear(
    id: 'wear_extreme_hot_commute_uv',
    temp: 'extreme_hot',
    scene: 'commute',
    titleZh: '防晒衬衫 + 冰感内搭 + 透气长裤',
    subtitleZh: '酷暑通勤要把防晒、通风和能脱下来同时考虑。',
    materialsZh: <String>['冰感内搭', '防晒衬衫', '透气长裤 + 透气鞋'],
    tagsZh: <String>['酷暑', '防晒'],
  ),
  _wear(
    id: 'wear_extreme_hot_casual_uv_layer',
    temp: 'extreme_hot',
    scene: 'casual',
    titleZh: '宽松防晒外搭 + 背心 + 凉感短裤',
    subtitleZh: '比纯背心更稳，进室内也不会反差太大。',
    materialsZh: <String>['背心或冰感T', '宽松防晒外搭', '凉感短裤 + 凉鞋'],
    tagsZh: <String>['外搭', '通风'],
  ),
  _wear(
    id: 'wear_extreme_hot_casual_ultralight',
    temp: 'extreme_hot',
    scene: 'casual',
    titleZh: '超轻短袖 + 透气长裙或宽腿裤',
    subtitleZh: '酷暑时适当遮挡反而比暴露更多更舒服。',
    materialsZh: <String>['超轻短袖', '透气长裙或宽腿裤', '凉鞋 + 遮阳帽'],
    tagsZh: <String>['遮阳', '透气'],
  ),
  _wear(
    id: 'wear_extreme_hot_casual_ice_tee',
    temp: 'extreme_hot',
    scene: 'casual',
    titleZh: '冰感T + 防晒伞 + 透气凉鞋',
    subtitleZh: '出门只想简单一点时，先把散热和防晒守住。',
    materialsZh: <String>['冰感T', '透气下装', '防晒伞 + 透气凉鞋'],
    tagsZh: <String>['极简', '散热'],
  ),
  _wear(
    id: 'wear_extreme_hot_business_ultrathin',
    temp: 'extreme_hot',
    scene: 'business',
    titleZh: '超薄短袖衬衫 + 轻量西裤',
    subtitleZh: '酷暑正式穿搭不能硬扛厚度，只能更讲究材质和整洁。',
    materialsZh: <String>['超薄短袖衬衫', '轻量西裤', '透气闭口鞋'],
    tagsZh: <String>['材质', '正式'],
  ),
  _wear(
    id: 'wear_extreme_hot_date_light_drapey',
    temp: 'extreme_hot',
    scene: 'date',
    titleZh: '轻薄垂感上装 + 透气下装 + 小配饰',
    subtitleZh: '热到极致时，干净、轻盈、整洁就是最好的气质。',
    materialsZh: <String>['轻薄垂感上装', '透气下装', '小配饰 + 凉鞋'],
    tagsZh: <String>['轻盈', '整洁'],
  ),
  _wear(
    id: 'wear_extreme_hot_exercise_ultralight',
    temp: 'extreme_hot',
    scene: 'exercise',
    titleZh: '速干背心 + 超轻短裤 + 冰巾',
    subtitleZh: '酷暑运动越轻越好，强度和时长都要主动下调。',
    materialsZh: <String>['速干背心', '超轻短裤', '跑鞋 + 冰巾'],
    tagsZh: <String>['降强度', '补水'],
  ),
  _wear(
    id: 'wear_extreme_hot_rain_towel',
    temp: 'extreme_hot',
    scene: 'rain',
    titleZh: '快干短袖 + 防滑凉鞋 + 备用干毛巾',
    subtitleZh: '热雨天容易又闷又黏，备一块干毛巾很值。',
    materialsZh: <String>['快干短袖', '快干下装', '防滑凉鞋 + 备用干毛巾'],
    tagsZh: <String>['热雨', '备用'],
  ),
  _wear(
    id: 'wear_freezing_business_pinstripe',
    temp: 'freezing',
    scene: 'business',
    titleZh: '深色大衣 + 条纹衬衫 + 保暖西裤',
    subtitleZh: '严寒正式穿搭靠深色轮廓和面料挺括感撑住专业度。',
    materialsZh: <String>['保暖打底', '深色大衣 + 条纹衬衫', '保暖西裤 + 皮鞋'],
    tagsZh: <String>['深色系', '专业'],
  ),
  _wear(
    id: 'wear_freezing_date_cashmere_skirt',
    temp: 'freezing',
    scene: 'date',
    titleZh: '羊绒针织 + 长裙或高腰裤 + 长靴',
    subtitleZh: '冷天约会与其硬拗，不如用柔软材质和清晰比例取胜。',
    materialsZh: <String>['羊绒或细针织上装', '长裙或高腰裤', '长靴 + 小包'],
    tagsZh: <String>['软糯', '比例'],
  ),
  _wear(
    id: 'wear_freezing_exercise_shell_layers',
    temp: 'freezing',
    scene: 'exercise',
    titleZh: '速干打底 + 轻壳层 + 收口训练裤',
    subtitleZh: '大风和低温并存时，轻壳层比堆厚外套更灵活。',
    materialsZh: <String>['速干保暖打底', '轻壳层', '收口训练裤 + 保暖帽'],
    tagsZh: <String>['防风', '灵活'],
  ),
  _wear(
    id: 'wear_freezing_rain_wool_cap',
    temp: 'freezing',
    scene: 'rain',
    titleZh: '防泼长外层 + 羊毛中层 + 抓地短靴',
    subtitleZh: '严寒雨雪里先把脚下和外层保护好，再谈造型细节。',
    materialsZh: <String>['速干贴身层', '防泼长外层 + 羊毛中层', '抓地短靴 + 帽子'],
    tagsZh: <String>['雨雪', '抓地'],
  ),
  _wear(
    id: 'wear_cold_date_turtleneck_skirt',
    temp: 'cold',
    scene: 'date',
    titleZh: '高领针织 + 及踝长裙或锥形裤 + 小耳饰',
    subtitleZh: '把重点留给领口、腰线和一件小配饰，冷天也能显得轻盈。',
    materialsZh: <String>['高领针织', '及踝长裙或锥形裤', '短靴 + 小耳饰'],
    tagsZh: <String>['领口', '轻盈'],
  ),
  _wear(
    id: 'wear_cold_exercise_softshell_run',
    temp: 'cold',
    scene: 'exercise',
    titleZh: '长袖速干 + 软壳马甲 + 收口跑步裤',
    subtitleZh: '寒冷天运动要防风但别闷，躯干保温比全身加厚更实用。',
    materialsZh: <String>['长袖速干', '软壳马甲', '收口跑步裤 + 跑鞋'],
    tagsZh: <String>['软壳', '热身'],
  ),
  _wear(
    id: 'wear_cold_rain_duckboots',
    temp: 'cold',
    scene: 'rain',
    titleZh: '连帽短外套 + 针织层 + 防滑短靴',
    subtitleZh: '寒冷下雨时，裤脚清爽和鞋底稳定往往比多一层更重要。',
    materialsZh: <String>['速干内搭', '连帽短外套 + 针织层', '九分裤 + 防滑短靴'],
    tagsZh: <String>['九分裤', '防滑'],
  ),
  _wear(
    id: 'wear_cool_business_soft_suit',
    temp: 'cool',
    scene: 'business',
    titleZh: '轻西装套组 + 纯色内搭 + 乐福鞋',
    subtitleZh: '凉爽正式场景最适合用轻量套组解决专业感和行动感。',
    materialsZh: <String>['纯色内搭', '轻西装外套 + 西裤', '乐福鞋 + 简洁包'],
    tagsZh: <String>['套组', '轻正式'],
  ),
  _wear(
    id: 'wear_cool_exercise_zip_jacket',
    temp: 'cool',
    scene: 'exercise',
    titleZh: '长袖速干 + 拉链外套 + 弹力长裤',
    subtitleZh: '清晨或晚间运动时，一件能随时解开的外套最省心。',
    materialsZh: <String>['长袖速干', '拉链外套', '弹力长裤 + 跑鞋'],
    tagsZh: <String>['清晨', '可穿脱'],
  ),
  _wear(
    id: 'wear_cool_rain_trench_cap',
    temp: 'cool',
    scene: 'rain',
    titleZh: '短风衣 + 快干长袖 + 防泼帽款鞋',
    subtitleZh: '小雨凉风天，保持上半身清爽比堆厚层更舒服。',
    materialsZh: <String>['快干长袖', '短风衣', '九分裤 + 防泼鞋'],
    tagsZh: <String>['凉雨', '清爽'],
  ),
  _wear(
    id: 'wear_mild_exercise_light_set',
    temp: 'mild',
    scene: 'exercise',
    titleZh: '短袖速干 + 轻薄拉链衫 + 训练短裤',
    subtitleZh: '温和天气最适合轻量分层，热起来就把外层系在腰上。',
    materialsZh: <String>['短袖速干', '轻薄拉链衫', '训练短裤 + 跑鞋'],
    tagsZh: <String>['轻量', '分层'],
  ),
  _wear(
    id: 'wear_mild_rain_packable_shell',
    temp: 'mild',
    scene: 'rain',
    titleZh: '可收纳雨壳 + 长袖T + 锥形裤',
    subtitleZh: '这种天气最适合带一件轻壳层，进室内后也不会累赘。',
    materialsZh: <String>['长袖T', '可收纳雨壳', '锥形裤 + 防滑鞋'],
    tagsZh: <String>['便携', '锥形裤'],
  ),
  _wear(
    id: 'wear_warm_business_vest_skirt',
    temp: 'warm',
    scene: 'business',
    titleZh: '无袖背心上衣 + 垂感半裙或西裤',
    subtitleZh: '微热正式穿搭要尽量减少层数，但仍保留线条和整洁度。',
    materialsZh: <String>['无袖背心上衣', '垂感半裙或西裤', '闭口鞋履 + 轻配饰'],
    tagsZh: <String>['少层数', '垂感'],
  ),
  _wear(
    id: 'wear_warm_date_linen_dress',
    temp: 'warm',
    scene: 'date',
    titleZh: '亚麻衬衫裙或轻衬衫 + 细带凉鞋',
    subtitleZh: '微热约会更适合轻透材质和放松线条，不需要太多装饰。',
    materialsZh: <String>['亚麻衬衫裙或轻衬衫', '轻薄下装', '细带凉鞋 + 小包'],
    tagsZh: <String>['轻透', '自然'],
  ),
  _wear(
    id: 'wear_warm_exercise_uv_run',
    temp: 'warm',
    scene: 'exercise',
    titleZh: '防晒外搭 + 速干短袖 + 训练短裤',
    subtitleZh: '白天室外运动时，防晒层和补水一样重要。',
    materialsZh: <String>['速干短袖', '防晒外搭', '训练短裤 + 帽子'],
    tagsZh: <String>['户外', '防晒'],
  ),
  _wear(
    id: 'wear_warm_rain_shorts_shell',
    temp: 'warm',
    scene: 'rain',
    titleZh: '轻防泼衬衫 + 快干短裤 + 防滑凉鞋',
    subtitleZh: '暖雨天最怕湿闷，所以宁可轻一点，也不要一直捂着。',
    materialsZh: <String>['轻防泼衬衫', '快干短裤', '防滑凉鞋 + 折叠伞'],
    tagsZh: <String>['短裤', '轻快'],
  ),
  _wear(
    id: 'wear_hot_business_knit_set',
    temp: 'hot',
    scene: 'business',
    titleZh: '短袖针织上衣 + 轻薄直筒裤',
    subtitleZh: '炎热正式场合不一定非得穿衬衫，关键是干净、挺括、不过分贴身。',
    materialsZh: <String>['短袖针织上衣', '轻薄直筒裤', '闭口鞋 + 腕表'],
    tagsZh: <String>['针织', '挺括'],
  ),
  _wear(
    id: 'wear_hot_date_sheer_shirt',
    temp: 'hot',
    scene: 'date',
    titleZh: '轻薄衬衫 + 高腰半裙或阔腿裤',
    subtitleZh: '热天约会让面料和比例发力，会比复杂花样更显气质。',
    materialsZh: <String>['轻薄衬衫', '高腰半裙或阔腿裤', '凉鞋 + 细项链'],
    tagsZh: <String>['高腰', '轻薄'],
  ),
  _wear(
    id: 'wear_hot_exercise_cooling_set',
    temp: 'hot',
    scene: 'exercise',
    titleZh: '冷感短袖 + 弹力短裤 + 吸汗头带',
    subtitleZh: '炎热运动先追求散热和补水，再追求配色或层次。',
    materialsZh: <String>['冷感短袖', '弹力短裤', '跑鞋 + 吸汗头带'],
    tagsZh: <String>['散热', '吸汗'],
  ),
  _wear(
    id: 'wear_hot_rain_shell_sandals',
    temp: 'hot',
    scene: 'rain',
    titleZh: '轻薄防泼衫 + 快干短裤 + 防滑凉鞋',
    subtitleZh: '炎热雨天的正确思路不是厚，而是快干和不积水。',
    materialsZh: <String>['轻薄防泼衫', '快干短裤', '防滑凉鞋 + 小毛巾'],
    tagsZh: <String>['不积水', '快干'],
  ),
  _wear(
    id: 'wear_extreme_hot_commute_cooling_shirt',
    temp: 'extreme_hot',
    scene: 'commute',
    titleZh: '凉感衬衫 + 透气锥形裤 + 防晒伞',
    subtitleZh: '酷暑通勤既要体面，也要给空调房和烈日各留一点余地。',
    materialsZh: <String>['凉感衬衫', '透气锥形裤', '防晒伞 + 透气鞋'],
    tagsZh: <String>['锥形裤', '空调房'],
  ),
  _wear(
    id: 'wear_extreme_hot_business_linen_set',
    temp: 'extreme_hot',
    scene: 'business',
    titleZh: '亚麻混纺上衣 + 轻量西裤 + 简洁皮鞋',
    subtitleZh: '高温正式穿搭的核心是材质透气和轮廓整洁，不是硬撑厚度。',
    materialsZh: <String>['亚麻混纺上衣', '轻量西裤', '简洁皮鞋 + 薄腰带'],
    tagsZh: <String>['透气', '轮廓'],
  ),
  _wear(
    id: 'wear_extreme_hot_date_sleeveless_dress',
    temp: 'extreme_hot',
    scene: 'date',
    titleZh: '无袖垂感上装 + 长裙或宽腿裤 + 小包',
    subtitleZh: '酷暑约会别靠堆配饰，轻薄、干净和小范围亮点就够了。',
    materialsZh: <String>['无袖垂感上装', '长裙或宽腿裤', '小包 + 轻凉鞋'],
    tagsZh: <String>['小亮点', '轻薄'],
  ),
  _wear(
    id: 'wear_extreme_hot_exercise_uv_hood',
    temp: 'extreme_hot',
    scene: 'exercise',
    titleZh: '防晒帽衫 + 速干背心 + 超轻短裤',
    subtitleZh: '酷暑户外运动要主动下调强度，把遮阳和补水安排在前面。',
    materialsZh: <String>['速干背心', '防晒帽衫', '超轻短裤 + 水壶'],
    tagsZh: <String>['遮阳', '主动降强度'],
  ),
  _wear(
    id: 'wear_extreme_hot_rain_quick_shirt',
    temp: 'extreme_hot',
    scene: 'rain',
    titleZh: '轻薄快干衬衫 + 九分裤 + 防滑凉鞋',
    subtitleZh: '又热又湿时，保持表面快干和脚下通风会舒服很多。',
    materialsZh: <String>['轻薄快干衬衫', '九分裤', '防滑凉鞋 + 备用纸巾'],
    tagsZh: <String>['通风', '九分裤'],
  ),
];

DailyChoiceOption _wear({
  required String id,
  required String temp,
  required String scene,
  required String titleZh,
  required String subtitleZh,
  String? titleEn,
  String? subtitleEn,
  String? detailsZh,
  String? detailsEn,
  List<String> materialsZh = const <String>[],
  List<String> materialsEn = const <String>[],
  List<String> stepsZh = const <String>[],
  List<String> stepsEn = const <String>[],
  List<String> tagsZh = const <String>[],
  List<String> tagsEn = const <String>[],
  Map<String, List<String>> attributes = const <String, List<String>>{},
}) {
  final tempCategory = _wearCategoryById(temperatureCategories, temp);
  final sceneCategory = _wearCategoryById(wearSceneCategories, scene);
  final resolvedMaterialsZh = materialsZh.isEmpty
      ? _wearDefaultMaterialsZh(temp)
      : materialsZh;
  final resolvedStepsZh = stepsZh.isEmpty
      ? _wearDefaultStepsZh(temp, scene)
      : stepsZh;
  final resolvedAttributes = _wearResolvedAttributes(
    titleZh: titleZh,
    subtitleZh: subtitleZh,
    materialsZh: resolvedMaterialsZh,
    tagsZh: tagsZh,
    attributes: attributes,
  );
  return _choice(
    id: id,
    moduleId: 'wear',
    categoryId: temp,
    contextId: scene,
    titleZh: titleZh,
    titleEn: titleEn ?? titleZh,
    subtitleZh: subtitleZh,
    subtitleEn: subtitleEn ?? subtitleZh,
    detailsZh:
        detailsZh ??
        '这套搭配面向${tempCategory.titleZh}的${sceneCategory.titleZh}场景，优先保证体感、行动方便和场合得体。先把基础层次穿对，再用一件主单品把整体收住。',
    detailsEn:
        detailsEn ??
        'This outfit is designed for ${tempCategory.titleEn.toLowerCase()} ${sceneCategory.titleEn.toLowerCase()} situations, prioritizing comfort, mobility, and social fit. Get the base layers right first, then let one main piece hold the look together.',
    materialsZh: resolvedMaterialsZh,
    materialsEn: materialsEn.isEmpty ? resolvedMaterialsZh : materialsEn,
    stepsZh: resolvedStepsZh,
    stepsEn: stepsEn.isEmpty ? resolvedStepsZh : stepsEn,
    tagsZh: _wearDistinctTags(<String>[
      '穿搭',
      tempCategory.titleZh,
      sceneCategory.titleZh,
      ...wearTraitLabelsZh(resolvedAttributes, limit: 8),
      ...tagsZh,
    ]),
    tagsEn: _wearDistinctTags(<String>[
      'Outfit',
      tempCategory.titleEn,
      sceneCategory.titleEn,
      ...wearTraitLabelsEn(resolvedAttributes, limit: 8),
      ...tagsEn,
    ]),
    attributes: resolvedAttributes,
    sourceLabel: wearReferenceSourceLabel,
  );
}

DailyChoiceCategory _wearCategoryById(
  List<DailyChoiceCategory> categories,
  String id,
) {
  return categories.firstWhere(
    (item) => item.id == id,
    orElse: () => categories.first,
  );
}

List<String> _wearDefaultMaterialsZh(String temp) {
  return switch (temp) {
    'freezing' => <String>['保暖内层', '厚针织或抓绒中层', '防风外层或抓地鞋履'],
    'cold' => <String>['舒适打底', '针织或轻保暖层', '稳妥鞋履与围巾'],
    'cool' => <String>['长袖内搭', '轻外套或开衫', '适中下装和鞋履'],
    'mild' => <String>['透气主上装', '可加减薄外层', '轻便鞋履或小配件'],
    'warm' => <String>['透气上装', '轻薄下装', '防晒或凉感配件'],
    'hot' => <String>['快干或薄面料上装', '轻薄下装', '防晒与补水装备'],
    _ => <String>['最轻薄主上装', '通风下装', '防晒与透气鞋履'],
  };
}

List<String> _wearDefaultStepsZh(String temp, String scene) {
  final steps = switch (scene) {
    'commute' => <String>[
      '先确认领口、肩线和裤长是否干净利落。',
      '再按室内外温差决定是否加一层可脱外套。',
      '最后检查鞋履和包是否适合通勤久走久坐。',
    ],
    'business' => <String>[
      '先把主色控制在一到两个稳定颜色里。',
      '再检查版型是否合身、是否会起皱或显松垮。',
      '最后统一鞋、腰带、包的整洁度。',
    ],
    'date' => <String>[
      '先选一件最能体现气质的主单品。',
      '再用版型或小配饰做一个记忆点。',
      '最后确认整体舒服、能走路、能久坐。',
    ],
    'exercise' => <String>[
      '先把贴身层换成排汗或速干材质。',
      '再按风感和热身情况决定是否加外层。',
      '结束后尽快更换汗湿衣物，别一直捂着。',
    ],
    'rain' => <String>[
      '先把快干和防滑放在造型前面。',
      '再把裤脚和鞋面长度控制好，避免吸水。',
      '最后确认雨具和备用纸巾是否带齐。',
    ],
    _ => <String>[
      '先确保主单品合身、舒服、可行动。',
      '再用一层外搭或一件配件把整体收住。',
      '最后看天气补齐鞋履、防晒或保暖细节。',
    ],
  };
  if (temp == 'freezing' || temp == 'cold') {
    return <String>[steps.first, '低温别只顾上半身，颈部、手部和脚踝也要一起保暖。', steps.last];
  }
  if (temp == 'warm' || temp == 'hot' || temp == 'extreme_hot') {
    return <String>[steps.first, steps[1], '出门前补一层防晒或备水，热时优先能脱能散热。'];
  }
  return steps;
}

List<String> _wearDistinctTags(List<String> values) {
  return <String>{...values}.toList(growable: false);
}

Map<String, List<String>> _wearResolvedAttributes({
  required String titleZh,
  required String subtitleZh,
  required List<String> materialsZh,
  required List<String> tagsZh,
  required Map<String, List<String>> attributes,
}) {
  final inferred = _wearInferAttributes(
    titleZh: titleZh,
    subtitleZh: subtitleZh,
    materialsZh: materialsZh,
    tagsZh: tagsZh,
  );
  final merged = <String, Set<String>>{};
  void mergeInto(Map<String, List<String>> source) {
    for (final entry in source.entries) {
      final bucket = merged.putIfAbsent(entry.key, () => <String>{});
      bucket.addAll(entry.value);
    }
  }

  mergeInto(inferred);
  mergeInto(attributes);
  return merged.map(
    (key, value) => MapEntry(key, value.toList(growable: false)..sort()),
  );
}

Map<String, List<String>> _wearInferAttributes({
  required String titleZh,
  required String subtitleZh,
  required List<String> materialsZh,
  required List<String> tagsZh,
}) {
  final text =
      '$titleZh $subtitleZh ${materialsZh.join(' ')} ${tagsZh.join(' ')}';
  final style = <String>{};
  final silhouette = <String>{};
  final keyPiece = <String>{};
  final material = <String>{};
  final highlight = <String>{};

  if (_containsAny(text, <String>['基础', '简洁', '克制', '省力', '万能', '干净'])) {
    style.add('minimal');
    highlight.add('clean_color');
  }
  if (_containsAny(text, <String>['通勤', '正式', '西装', '会议', '专业', '利落'])) {
    style.add('polished');
  }
  if (_containsAny(text, <String>['柔和', '软糯', '缎面', '约会', '轻盈', '温柔'])) {
    style.add('soft');
  }
  if (_containsAny(text, <String>['松弛', '周末', '轻松', '日常', '舒服', '休闲'])) {
    style.add('relaxed');
  }
  if (_containsAny(text, <String>['运动', '跑', '训练', '速干', '弹力'])) {
    style.add('sporty');
  }
  if (_containsAny(text, <String>['复古', '灯芯绒', '牛角扣', '条纹', '格纹'])) {
    style.add('retro');
  }
  if (_containsAny(text, <String>['工装', '潮', '街头', '卫衣', '板鞋'])) {
    style.add('street');
  }
  if (_containsAny(text, <String>['防水', '防泼', '防风', '防晒', '壳层', '户外'])) {
    style.add('outdoor');
    highlight.add('weather_protection');
  }
  if (style.isEmpty) {
    if (_containsAny(text, <String>['约会', '轻盈', '柔和'])) {
      style.add('soft');
    } else if (_containsAny(text, <String>['运动', '速干', '训练', '跑'])) {
      style.add('sporty');
    } else if (_containsAny(text, <String>['雨', '快干', '防滑'])) {
      style.add('outdoor');
    } else if (_containsAny(text, <String>['通勤', '正式', '会议', '专业'])) {
      style.add('polished');
    } else {
      style.add('relaxed');
    }
  }

  if (_containsAny(text, <String>['腰带', '高腰', '腰线'])) {
    silhouette.add('waist_defined');
    highlight.add('proportion');
  }
  if (_containsAny(text, <String>['直筒', '锥形', '修长'])) {
    silhouette.add('straight');
  }
  if (_containsAny(text, <String>['宽松', '阔腿', '舒展', '量感'])) {
    silhouette.add('relaxed');
  }
  if (_containsAny(text, <String>['垂感', '流动', '缎面'])) {
    silhouette.add('drapey');
  }
  if (_containsAny(text, <String>['叠穿', '分层', '外套', '层次'])) {
    silhouette.add('layered');
    highlight.add('texture');
  }
  if (silhouette.isEmpty) {
    silhouette.add('clean');
  }

  if (_containsAny(text, <String>['衬衫', 'Polo', 'polo'])) {
    keyPiece.add('shirt');
  }
  if (_containsAny(text, <String>['针织', '毛衣', '开衫', '高领'])) {
    keyPiece.add('knit');
    material.add('knit');
  }
  if (_containsAny(text, <String>['西装', '西裤', '套组'])) {
    keyPiece.add('tailoring');
    material.add('tailoring_fabric');
  }
  if (_containsAny(text, <String>['外套', '大衣', '风衣', '羽绒', '派克', '壳层'])) {
    keyPiece.add('coat');
  }
  if (_containsAny(text, <String>['裙', '连衣裙'])) {
    keyPiece.add('dress_skirt');
  }
  if (_containsAny(text, <String>['裤', '牛仔', '阔腿', '锥形'])) {
    keyPiece.add('trousers');
  }
  if (_containsAny(text, <String>['短裤'])) {
    keyPiece.add('shorts');
  }
  if (_containsAny(text, <String>['跑', '训练', '运动', '背心'])) {
    keyPiece.add('athleisure');
  }
  if (keyPiece.isEmpty) {
    keyPiece.add('trousers');
  }

  if (_containsAny(text, <String>['羊毛', '羊绒', '呢', '羽绒'])) {
    material.add('wool');
  }
  if (_containsAny(text, <String>['棉麻', '亚麻'])) {
    material.add('cotton_linen');
  }
  if (_containsAny(text, <String>['速干', '凉感', '冰感', '冷感'])) {
    material.add('quick_dry');
  }
  if (_containsAny(text, <String>['防水', '防泼', '壳层'])) {
    material.add('waterproof');
  }
  if (_containsAny(text, <String>['牛仔', '灯芯绒'])) {
    material.add('denim');
  }
  if (_containsAny(text, <String>['软糯', '柔软', '缎面', '光泽', '垂感'])) {
    material.add('soft_sheen');
  }

  if (_containsAny(text, <String>['亮点', '提气', '亮色'])) {
    highlight.add('color_accent');
  }
  if (_containsAny(text, <String>['围巾', '耳饰', '项链', '腕表', '小包', '配饰'])) {
    highlight.add('accessory');
  }
  if (_containsAny(text, <String>['防晒', '遮阳', '太阳伞'])) {
    highlight.add('sun_protection');
  }
  if (_containsAny(text, <String>['乐福鞋', '短靴', '皮鞋', '凉鞋', '跑鞋'])) {
    highlight.add('shoe_anchor');
  }

  return <String, List<String>>{
    if (style.isNotEmpty) 'style': style.toList(growable: false),
    if (silhouette.isNotEmpty) 'silhouette': silhouette.toList(growable: false),
    if (keyPiece.isNotEmpty) 'key_piece': keyPiece.toList(growable: false),
    if (material.isNotEmpty) 'material': material.toList(growable: false),
    if (highlight.isNotEmpty) 'highlight': highlight.toList(growable: false),
  };
}

bool _containsAny(String text, List<String> needles) {
  for (final needle in needles) {
    if (text.contains(needle)) {
      return true;
    }
  }
  return false;
}
