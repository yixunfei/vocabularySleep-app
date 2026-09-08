part of '../toolbox_life_tools.dart';

final List<_TimelineFact> _timelineFacts = _sortedTimelineFacts(<_TimelineFact>[
  ..._legacyTimelineFacts01,
  ..._legacyTimelineFacts02,
  ..._legacyTimelineFacts03,
  ..._generalTimelineFacts01,
  ..._generalTimelineFacts02,
  ..._generalTimelineFacts03,
  ..._chinaTimelineFacts01,
  ..._chinaTimelineFacts02,
]);

List<_TimelineFact> _sortedTimelineFacts(List<_TimelineFact> facts) {
  final unique = <String, _TimelineFact>{};
  for (final fact in facts) {
    unique.putIfAbsent('${fact.collection}:${fact.id}', () => fact);
  }
  final sorted = unique.values.toList()
    ..sort((a, b) => b.yearsBeforePresent.compareTo(a.yearsBeforePresent));
  return List<_TimelineFact>.unmodifiable(sorted);
}
