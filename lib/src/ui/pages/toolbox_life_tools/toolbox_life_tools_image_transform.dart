part of '../toolbox_life_tools.dart';

enum _ImageTransformTab { compress, upscale }

class _ImageTransformPage extends StatefulWidget {
  const _ImageTransformPage();

  @override
  State<_ImageTransformPage> createState() => _ImageTransformPageState();
}

class _ImageTransformPageState extends State<_ImageTransformPage> {
  _ImageTransformTab _activeTab = _ImageTransformTab.compress;

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.image_compression_upscale.6a89f70da7a2',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.switch_quickly_between_compression_a.3a839a4a3c45',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.tool_tabs.04c8cbf8182c',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.the_two_workspaces_stay_independent.1e184dc0fe00',
            ),
            children: <Widget>[
              KeyedSubtree(
                key: const ValueKey<String>('life_image_transform_tab_field'),
                child: _LifeSegmentedField<_ImageTransformTab>(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.current_action.53c9cbce00f8',
                  ),
                  value: _activeTab,
                  options: const <_LifeOption<_ImageTransformTab>>[
                    _LifeOption<_ImageTransformTab>(
                      value: _ImageTransformTab.compress,
                      labelKey: 'inline.plan295.life.compress.32907d88de52',
                    ),
                    _LifeOption<_ImageTransformTab>(
                      value: _ImageTransformTab.upscale,
                      labelKey: 'inline.plan295.life.upscale.51e9b469f111',
                    ),
                  ],
                  onChanged: (value) => setState(() => _activeTab = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _activeTab == _ImageTransformTab.compress
                ? const KeyedSubtree(
                    key: ValueKey<String>('life_image_transform_compress_tab'),
                    child: _ImageCompressPage(embedded: true),
                  )
                : const KeyedSubtree(
                    key: ValueKey<String>('life_image_transform_upscale_tab'),
                    child: _ImageUpscalePage(embedded: true),
                  ),
          ),
        ],
      ),
    );
  }
}
