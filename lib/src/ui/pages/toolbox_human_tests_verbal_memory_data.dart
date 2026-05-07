part of 'toolbox_human_tests.dart';

const List<_VerbalMemoryDomain> _verbalMemoryDomainOrder =
    <_VerbalMemoryDomain>[
      _VerbalMemoryDomain.fruits,
      _VerbalMemoryDomain.environment,
      _VerbalMemoryDomain.nature,
      _VerbalMemoryDomain.food,
      _VerbalMemoryDomain.travel,
      _VerbalMemoryDomain.technology,
      _VerbalMemoryDomain.home,
      _VerbalMemoryDomain.office,
      _VerbalMemoryDomain.weather,
      _VerbalMemoryDomain.animals,
    ];

const Map<_VerbalMemoryDomain, _VerbalMemoryDomainSpec>
_verbalMemoryDomainSpecs = <_VerbalMemoryDomain, _VerbalMemoryDomainSpec>{
  _VerbalMemoryDomain.fruits: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '水果',
    en: 'Fruits',
    accent: Color(0xFFD38A35),
  ),
  _VerbalMemoryDomain.environment: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '环境',
    en: 'Environment',
    accent: Color(0xFF4D8C7B),
  ),
  _VerbalMemoryDomain.nature: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '自然',
    en: 'Nature',
    accent: Color(0xFF6C8D42),
  ),
  _VerbalMemoryDomain.food: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.food,
    zh: '食物',
    en: 'Food',
    accent: Color(0xFFC56C45),
  ),
  _VerbalMemoryDomain.travel: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '旅行',
    en: 'Travel',
    accent: Color(0xFF4C83B8),
  ),
  _VerbalMemoryDomain.technology: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '科技',
    en: 'Technology',
    accent: Color(0xFF5C68B8),
  ),
  _VerbalMemoryDomain.home: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '居家',
    en: 'Home',
    accent: Color(0xFF8A6849),
  ),
  _VerbalMemoryDomain.office: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '办公',
    en: 'Office',
    accent: Color(0xFF697282),
  ),
  _VerbalMemoryDomain.weather: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '天气',
    en: 'Weather',
    accent: Color(0xFF4A9CB4),
  ),
  _VerbalMemoryDomain.animals: _VerbalMemoryDomainSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '动物',
    en: 'Animals',
    accent: Color(0xFFC05B74),
  ),
};

const List<_VerbalMemoryWordSpec>
_verbalMemoryWordBank = <_VerbalMemoryWordSpec>[
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '苹果',
    en: 'apple',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '香蕉',
    en: 'banana',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '橙子',
    en: 'orange',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '梨子',
    en: 'pear',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '葡萄',
    en: 'grape',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '芒果',
    en: 'mango',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '桃子',
    en: 'peach',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '柠檬',
    en: 'lemon',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '樱桃',
    en: 'cherry',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.fruits,
    zh: '李子',
    en: 'plum',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '森林',
    en: 'forest',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '河流',
    en: 'river',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '山脉',
    en: 'mountain',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '山谷',
    en: 'valley',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '港湾',
    en: 'harbor',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '草甸',
    en: 'meadow',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '峡谷',
    en: 'canyon',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '冰川',
    en: 'glacier',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '湿地',
    en: 'wetland',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.environment,
    zh: '极光',
    en: 'aurora',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '叶片',
    en: 'leaf',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '种子',
    en: 'seed',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '苔藓',
    en: 'moss',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '石块',
    en: 'stone',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '云朵',
    en: 'cloud',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '黎明',
    en: 'dawn',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '黄昏',
    en: 'dusk',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '潮汐',
    en: 'tide',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '贝壳',
    en: 'shell',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.nature,
    zh: '蕨类',
    en: 'fern',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.food,
    zh: '面条',
    en: 'noodle',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.food,
    zh: '饺子',
    en: 'dumpling',
  ),
  _VerbalMemoryWordSpec(domain: _VerbalMemoryDomain.food, zh: '汤品', en: 'soup'),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.food,
    zh: '面包',
    en: 'bread',
  ),
  _VerbalMemoryWordSpec(domain: _VerbalMemoryDomain.food, zh: '米饭', en: 'rice'),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.food,
    zh: '奶酪',
    en: 'cheese',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.food,
    zh: '沙拉',
    en: 'salad',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.food,
    zh: '咖喱',
    en: 'curry',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.food,
    zh: '蜂蜜',
    en: 'honey',
  ),
  _VerbalMemoryWordSpec(domain: _VerbalMemoryDomain.food, zh: '豆腐', en: 'tofu'),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '车站',
    en: 'station',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '桥梁',
    en: 'bridge',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '机场',
    en: 'airport',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '小径',
    en: 'trail',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '行李箱',
    en: 'suitcase',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '路线',
    en: 'route',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '指南针',
    en: 'compass',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '小木屋',
    en: 'cabin',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '灯塔',
    en: 'lighthouse',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.travel,
    zh: '渡轮',
    en: 'ferry',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '传感器',
    en: 'sensor',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '服务器',
    en: 'server',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '电路',
    en: 'circuit',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '像素',
    en: 'pixel',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '路由器',
    en: 'router',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '电池',
    en: 'battery',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '键盘',
    en: 'keyboard',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '无人机',
    en: 'drone',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '信号',
    en: 'signal',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.technology,
    zh: '芯片',
    en: 'chip',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '枕头',
    en: 'pillow',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '窗帘',
    en: 'curtain',
  ),
  _VerbalMemoryWordSpec(domain: _VerbalMemoryDomain.home, zh: '台灯', en: 'lamp'),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '窗户',
    en: 'window',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '抽屉',
    en: 'drawer',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '书架',
    en: 'shelf',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '水壶',
    en: 'kettle',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '毛毯',
    en: 'blanket',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '地毯',
    en: 'carpet',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.home,
    zh: '橱柜',
    en: 'cabinet',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '笔记本',
    en: 'notebook',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '文件夹',
    en: 'folder',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '会议',
    en: 'meeting',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '打印机',
    en: 'printer',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '议程',
    en: 'agenda',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '图表',
    en: 'chart',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '书桌',
    en: 'desk',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '印章',
    en: 'stamp',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '扫描仪',
    en: 'scanner',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.office,
    zh: '报告',
    en: 'report',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '微风',
    en: 'breeze',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '降雨',
    en: 'rainfall',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '阳光',
    en: 'sunshine',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '雷声',
    en: 'thunder',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '细雨',
    en: 'drizzle',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '薄雾',
    en: 'mist',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '风暴',
    en: 'storm',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '霜冻',
    en: 'frost',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '降雪',
    en: 'snow',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.weather,
    zh: '湿度',
    en: 'humidity',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '兔子',
    en: 'rabbit',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '海豚',
    en: 'dolphin',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '老虎',
    en: 'tiger',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '水獭',
    en: 'otter',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '麻雀',
    en: 'sparrow',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '熊猫',
    en: 'panda',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '骆驼',
    en: 'camel',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '鲸鱼',
    en: 'whale',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '狐狸',
    en: 'fox',
  ),
  _VerbalMemoryWordSpec(
    domain: _VerbalMemoryDomain.animals,
    zh: '羊驼',
    en: 'llama',
  ),
];

const List<_VerbalMemoryArrowSpec> _verbalMemoryArrowSpecs =
    <_VerbalMemoryArrowSpec>[
      _VerbalMemoryArrowSpec(
        direction: _VerbalMemoryArrowDirection.upLeft,
        icon: Icons.north_west_rounded,
        zh: '左上',
        en: 'Up left',
        symbol: '↖',
      ),
      _VerbalMemoryArrowSpec(
        direction: _VerbalMemoryArrowDirection.up,
        icon: Icons.arrow_upward_rounded,
        zh: '上',
        en: 'Up',
        symbol: '↑',
      ),
      _VerbalMemoryArrowSpec(
        direction: _VerbalMemoryArrowDirection.upRight,
        icon: Icons.north_east_rounded,
        zh: '右上',
        en: 'Up right',
        symbol: '↗',
      ),
      _VerbalMemoryArrowSpec(
        direction: _VerbalMemoryArrowDirection.left,
        icon: Icons.arrow_back_rounded,
        zh: '左',
        en: 'Left',
        symbol: '←',
      ),
      _VerbalMemoryArrowSpec(
        direction: _VerbalMemoryArrowDirection.right,
        icon: Icons.arrow_forward_rounded,
        zh: '右',
        en: 'Right',
        symbol: '→',
      ),
      _VerbalMemoryArrowSpec(
        direction: _VerbalMemoryArrowDirection.downLeft,
        icon: Icons.south_west_rounded,
        zh: '左下',
        en: 'Down left',
        symbol: '↙',
      ),
      _VerbalMemoryArrowSpec(
        direction: _VerbalMemoryArrowDirection.down,
        icon: Icons.arrow_downward_rounded,
        zh: '下',
        en: 'Down',
        symbol: '↓',
      ),
      _VerbalMemoryArrowSpec(
        direction: _VerbalMemoryArrowDirection.downRight,
        icon: Icons.south_east_rounded,
        zh: '右下',
        en: 'Down right',
        symbol: '↘',
      ),
    ];
