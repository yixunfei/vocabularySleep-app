part of '../toolbox_life_tools.dart';

const List<Color> _teamColorPresets = <Color>[
  Color(0xFFE53935),
  Color(0xFF1E88E5),
  Color(0xFF43A047),
  Color(0xFFFB8C00),
  Color(0xFF8E24AA),
  Color(0xFF00ACC1),
  Color(0xFFEC407A),
  Color(0xFF3949AB),
  Color(0xFF00897B),
  Color(0xFFFFB300),
  Color(0xFF5E35B1),
  Color(0xFF546E7A),
];

String _formatTime(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _ScoreboardToolPage extends StatefulWidget {
  const _ScoreboardToolPage();

  @override
  State<_ScoreboardToolPage> createState() => _ScoreboardToolPageState();
}

class _ScoreboardToolPageState extends State<_ScoreboardToolPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.scoreboard.331767dc94ac',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.two_team_and_mixed_points_mode.c7377211c4e2',
      ),
      child: Column(
        children: <Widget>[
          TabBar(
            controller: _tabController,
            tabs: <Tab>[
              Tab(
                text: _lifeI18nText(
                  context,
                  'inline.plan295.life.two_team.e80a640e21e9',
                ),
              ),
              Tab(
                text: _lifeI18nText(
                  context,
                  'inline.plan295.life.mixed.fc8f0031fe1b',
                ),
              ),
            ],
          ),
          SizedBox(
            height: math.max(420, MediaQuery.sizeOf(context).height - 280),
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _DualTeamMode(vsync: this),
                _MixedScoreMode(vsync: this),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepValueSetting extends StatelessWidget {
  const _StepValueSetting({
    required this.enabled,
    required this.value,
    required this.onToggle,
    required this.onValueChanged,
  });

  final bool enabled;
  final int value;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onValueChanged;

  static const List<int> _steps = <int>[1, 2, 3, 5, 10];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.step_value.b99d33bc33e9',
            ),
          ),
          subtitle: Text(
            enabled
                ? _lifeI18nText(
                    context,
                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.scoreboard.per_tap.7260235428',
                    params: <String, Object?>{'value': value},
                  )
                : _lifeI18nText(
                    context,
                    'inline.plan295.life.default_1.3685180e053b',
                  ),
          ),
          value: enabled,
          onChanged: onToggle,
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Wrap(
              spacing: 6,
              children: _steps
                  .map(
                    (s) => ChoiceChip(
                      selected: value == s,
                      label: Text('+$s'),
                      onSelected: (_) => onValueChanged(s),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }
}
