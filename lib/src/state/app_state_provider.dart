import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/cstcloud_resource_cache_service.dart';
import 'app_state.dart';

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  throw StateError('appStateProvider must be overridden at app bootstrap.');
});

final cstCloudResourceCacheProvider = Provider<CstCloudResourceCacheService>((
  ref,
) {
  throw StateError(
    'cstCloudResourceCacheProvider must be overridden at app bootstrap.',
  );
});
