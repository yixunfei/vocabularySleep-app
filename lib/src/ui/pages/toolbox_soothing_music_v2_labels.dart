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

  String _pageTitle(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.page_title');

  String _pageSubtitle(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.page_subtitle');

  String _browseModesTitle(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.browse_modes_title');

  String _browseModesSubtitle(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.browse_modes_subtitle');

  String _modesButtonLabel(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.modes_button_label');

  String _modeFilterLabel(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.all => i18n.t(
        'toolbox.sound.soothing.mode_filter_all',
      ),
      _ModeLibraryFilter.favorites => i18n.t(
        'toolbox.sound.soothing.mode_filter_favorites',
      ),
      _ModeLibraryFilter.recent => i18n.t(
        'toolbox.sound.soothing.mode_filter_recent',
      ),
    };
  }

  String _emptyModeTitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => i18n.t(
        'toolbox.sound.soothing.empty_mode_title_favorites',
      ),
      _ModeLibraryFilter.recent => i18n.t(
        'toolbox.sound.soothing.empty_mode_title_recent',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _emptyModeSubtitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => i18n.t(
        'toolbox.sound.soothing.empty_mode_subtitle_favorites',
      ),
      _ModeLibraryFilter.recent => i18n.t(
        'toolbox.sound.soothing.empty_mode_subtitle_recent',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _showAllModesLabel(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.show_all_modes_label');

  String _sleepTimerButtonLabel(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.sleep_timer_button_label');

  String _sleepTimerOptionLabel(AppI18n i18n, Duration? value) {
    if (value == null) {
      return i18n.t('toolbox.sound.soothing.timer_off');
    }
    return i18n.t(
      'toolbox.sound.soothing.timer_minutes',
      params: <String, Object?>{'count': value.inMinutes},
    );
  }

  String _activeSleepTimerLabel(AppI18n i18n, Duration value) => i18n.t(
    'toolbox.sound.soothing.active_sleep_timer',
    params: <String, Object?>{'duration': _format(value)},
  );

  String _trackCountLabel(AppI18n i18n, int count) => i18n.t(
    'toolbox.sound.soothing.track_count_label',
    params: <String, Object?>{'count': count},
  );

  String _activeModeLabel(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.active_mode_label');

  String _favoriteToggleLabel(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.favorite_toggle_label');
  String _previousTrackLabel(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.previous_track_label');
  String _nextTrackLabel(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.next_track_label');
  String _volumeToggleLabel(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.volume_toggle_label');
}
