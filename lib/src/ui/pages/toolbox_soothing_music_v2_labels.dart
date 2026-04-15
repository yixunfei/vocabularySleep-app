// ignore_for_file: unused_element

part of 'toolbox_soothing_music_v2_page.dart';

extension _SoothingMusicV2LabelHelpers on _SoothingMusicV2PageState {
  String _copyPageTitle(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'page.title');

  String _copyPageSubtitle(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'page.subtitle');

  String _copyBrowseModesTitle(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.browser.title');

  String _copyBrowseModesSubtitle(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.browser.subtitle');

  String _copyModesButtonLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.button');

  String _copyModeFilterLabel(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.all => SoothingMusicCopy.text(i18n, 'mode.filter.all'),
      _ModeLibraryFilter.favorites => SoothingMusicCopy.text(
        i18n,
        'mode.filter.favorites',
      ),
      _ModeLibraryFilter.recent => SoothingMusicCopy.text(
        i18n,
        'mode.filter.recent',
      ),
    };
  }

  String _copyEmptyModeTitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => SoothingMusicCopy.text(
        i18n,
        'mode.empty.favorites.title',
      ),
      _ModeLibraryFilter.recent => SoothingMusicCopy.text(
        i18n,
        'mode.empty.recent.title',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _copyEmptyModeSubtitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => SoothingMusicCopy.text(
        i18n,
        'mode.empty.favorites.subtitle',
      ),
      _ModeLibraryFilter.recent => SoothingMusicCopy.text(
        i18n,
        'mode.empty.recent.subtitle',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _copyShowAllModesLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.show_all');

  String _copySleepTimerButtonLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'timer.button');

  String _copySleepTimerOptionLabel(AppI18n i18n, Duration? value) {
    if (value == null) return SoothingMusicCopy.text(i18n, 'timer.off');
    return SoothingMusicCopy.text(
      i18n,
      'timer.minutes',
      params: <String, Object?>{'count': value.inMinutes},
    );
  }

  String _copyActiveSleepTimerLabel(AppI18n i18n, Duration value) =>
      SoothingMusicCopy.text(
        i18n,
        'timer.active',
        params: <String, Object?>{'duration': _format(value)},
      );

  String _copyTrackCountLabel(AppI18n i18n, int count) =>
      SoothingMusicCopy.text(
        i18n,
        'track.count',
        params: <String, Object?>{'count': count},
      );

  String _copyActiveModeLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.active');

  String _copyFavoriteToggleLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.favorite_toggle');

  String _copyPreviousTrackLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'track.previous');

  String _copyNextTrackLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'track.next');

  String _copyVolumeToggleLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'audio.toggle_mute');

  String _pageTitle(AppI18n i18n) => pickUiText(
    i18n,
    zh: '舒缓轻音',
    en: 'Soothing music',
    ja: 'やわらぎミュージック',
    de: 'Sanfte Musik',
    fr: 'Musique apaisante',
    es: 'Música relajante',
    ru: 'Спокойная музыка',
  );

  String _pageSubtitle(AppI18n i18n) => pickUiText(
    i18n,
    zh: '精选疗愈系轻音乐与氛围旋律，配合动态呼吸光效与本地曲库，适合手机端沉浸使用。',
    en: 'Curated calming loops with breathing light effects, local tracks, and a mobile-first immersive layout.',
  );

  String _browseModesTitle(AppI18n i18n) => pickUiText(
    i18n,
    zh: '浏览模式',
    en: 'Browse modes',
    ja: 'モード一覧',
    de: 'Modi durchsuchen',
    fr: 'Parcourir les modes',
    es: 'Explorar modos',
    ru: 'Режимы',
  );

  String _browseModesSubtitle(AppI18n i18n) => pickUiText(
    i18n,
    zh: '切换模式后会自动回到播放页，当前模式会高亮显示。',
    en: 'Selecting a mode closes the menu and keeps the current mode clearly highlighted.',
  );

  String _modesButtonLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '模式',
    en: 'Modes',
    ja: 'モード',
    de: 'Modi',
    fr: 'Modes',
    es: 'Modos',
    ru: 'Режимы',
  );

  String _modeFilterLabel(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.all => pickUiText(
        i18n,
        zh: '全部',
        en: 'All',
        ja: 'すべて',
        de: 'Alle',
        fr: 'Tout',
        es: 'Todo',
        ru: 'Все',
      ),
      _ModeLibraryFilter.favorites => pickUiText(
        i18n,
        zh: '收藏',
        en: 'Favorites',
        ja: 'お気に入り',
        de: 'Favoriten',
        fr: 'Favoris',
        es: 'Favoritos',
        ru: 'Избранное',
      ),
      _ModeLibraryFilter.recent => pickUiText(
        i18n,
        zh: '最近',
        en: 'Recent',
        ja: '最近',
        de: 'Zuletzt',
        fr: 'Récents',
        es: 'Recientes',
        ru: 'Недавние',
      ),
    };
  }

  String _emptyModeTitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => pickUiText(
        i18n,
        zh: '还没有收藏模式',
        en: 'No favorite modes yet',
        ja: 'お気に入りのモードはまだありません',
        de: 'Noch keine Favoriten',
        fr: 'Aucun favori pour le moment',
        es: 'Aún no hay favoritos',
        ru: 'Пока нет избранных режимов',
      ),
      _ModeLibraryFilter.recent => pickUiText(
        i18n,
        zh: '最近还没有播放记录',
        en: 'No recent modes yet',
        ja: '最近使ったモードはまだありません',
        de: 'Noch keine zuletzt verwendeten Modi',
        fr: 'Aucun mode récent pour le moment',
        es: 'Aún no hay modos recientes',
        ru: 'Пока нет недавних режимов',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _emptyModeSubtitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => pickUiText(
        i18n,
        zh: '给常用模式点亮爱心，之后就能在这里快速切换。',
        en: 'Mark modes you use often and they will appear here for quick switching.',
      ),
      _ModeLibraryFilter.recent => pickUiText(
        i18n,
        zh: '切换或播放几个模式后，这里会自动记录最近使用内容。',
        en: 'Once you switch or play a few modes, your recent history will appear here.',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _showAllModesLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '查看全部',
    en: 'Show all',
    ja: 'すべて表示',
    de: 'Alle anzeigen',
    fr: 'Tout afficher',
    es: 'Ver todo',
    ru: 'Показать все',
  );

  String _sleepTimerButtonLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '睡眠定时',
    en: 'Sleep timer',
    ja: 'スリープタイマー',
    de: 'Schlaftimer',
    fr: 'Minuteur de veille',
    es: 'Temporizador de sueño',
    ru: 'Таймер сна',
  );

  String _sleepTimerOptionLabel(AppI18n i18n, Duration? value) {
    if (value == null) {
      return pickUiText(
        i18n,
        zh: '关闭',
        en: 'Off',
        ja: 'オフ',
        de: 'Aus',
        fr: 'Désactivé',
        es: 'Desactivado',
        ru: 'Выкл',
      );
    }
    return pickUiText(
      i18n,
      zh: '${value.inMinutes} 分钟',
      en: '${value.inMinutes} min',
      ja: '${value.inMinutes}分',
      de: '${value.inMinutes} Min',
      fr: '${value.inMinutes} min',
      es: '${value.inMinutes} min',
      ru: '${value.inMinutes} мин',
    );
  }

  String _activeSleepTimerLabel(AppI18n i18n, Duration value) => pickUiText(
    i18n,
    zh: '睡眠定时 ${_format(value)}',
    en: 'Sleep timer ${_format(value)}',
    ja: 'スリープタイマー ${_format(value)}',
    de: 'Schlaftimer ${_format(value)}',
    fr: 'Minuteur ${_format(value)}',
    es: 'Temporizador ${_format(value)}',
    ru: 'Таймер ${_format(value)}',
  );

  String _trackCountLabel(AppI18n i18n, int count) => pickUiText(
    i18n,
    zh: '$count 首曲目',
    en: '$count tracks',
    ja: '$count 曲',
    de: '$count Titel',
    fr: '$count pistes',
    es: '$count pistas',
    ru: '$count треков',
  );

  String _activeModeLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '当前',
    en: 'Active',
    ja: '再生中',
    de: 'Aktiv',
    fr: 'Actif',
    es: 'Activo',
    ru: 'Активен',
  );

  String _favoriteToggleLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '收藏模式',
    en: 'Toggle favorite',
    ja: 'お気に入り',
    de: 'Favorit umschalten',
    fr: 'Mettre en favori',
    es: 'Marcar favorito',
    ru: 'В избранное',
  );

  String _previousTrackLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '上一首',
    en: 'Previous track',
    ja: '前の曲',
    de: 'Vorheriger Titel',
    fr: 'Piste précédente',
    es: 'Pista anterior',
    ru: 'Предыдущий трек',
  );

  String _nextTrackLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '下一首',
    en: 'Next track',
    ja: '次の曲',
    de: 'Nächster Titel',
    fr: 'Piste suivante',
    es: 'Siguiente pista',
    ru: 'Следующий трек',
  );

  String _volumeToggleLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '静音切换',
    en: 'Toggle mute',
    ja: 'ミュート切替',
    de: 'Stumm schalten',
    fr: 'Couper le son',
    es: 'Silenciar',
    ru: 'Вкл/выкл звук',
  );
}
