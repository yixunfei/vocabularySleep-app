part of 'app_state.dart';

extension AppStateWeatherDomain on AppState {
  void _setWeatherEnabledImpl(bool enabled) {
    _weatherStore.setEnabled(enabled);
  }

  Future<void> _refreshWeatherImpl({bool force = false}) {
    return _weatherStore.refresh(force: force);
  }

  void _refreshWeatherIfStaleImpl() {
    _weatherStore.refreshIfStale();
  }
}
