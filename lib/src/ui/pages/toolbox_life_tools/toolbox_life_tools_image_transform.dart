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
      title: _lifeText(
        context,
        zh: '图片压缩/扩大',
        en: 'Image compression / upscale',
      ),
      subtitle: _lifeText(
        context,
        zh: '在同一页面内快速切换压缩和扩大；扩大侧补充更轻量的插值路径与自定义倍率。',
        en: 'Switch quickly between compression and upscale with lighter interpolation paths and a custom scale input.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '工具页签', en: 'Tool tabs'),
            subtitle: _lifeText(
              context,
              zh: '两个工作区相互独立，可快速来回切换。',
              en: 'The two workspaces stay independent and switch quickly.',
            ),
            children: <Widget>[
              KeyedSubtree(
                key: const ValueKey<String>('life_image_transform_tab_field'),
                child: _LifeSegmentedField<_ImageTransformTab>(
                  label: _lifeText(context, zh: '当前操作', en: 'Current action'),
                  value: _activeTab,
                  options: const <_LifeOption<_ImageTransformTab>>[
                    _LifeOption<_ImageTransformTab>(
                      value: _ImageTransformTab.compress,
                      labelZh: '压缩',
                      labelEn: 'Compress',
                    ),
                    _LifeOption<_ImageTransformTab>(
                      value: _ImageTransformTab.upscale,
                      labelZh: '扩大',
                      labelEn: 'Upscale',
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
