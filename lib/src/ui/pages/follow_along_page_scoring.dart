part of 'follow_along_page.dart';

extension _FollowAlongScoringHelpers on _FollowAlongPageState {
  double _similarityPassThreshold() {
    final length = widget.word.word.trim().runes.length;
    if (length <= 4) return 0.76;
    if (length <= 8) return 0.73;
    return 0.7;
  }

  bool _hasHardTextMismatch({
    required String expected,
    required String recognized,
    required PronunciationComparison? textComparison,
  }) {
    final exp = expected.trim();
    final rec = recognized.trim();
    if (exp.isEmpty || rec.isEmpty) return false;
    final comparison = textComparison;
    if (comparison == null) return false;
    if (comparison.isCorrect) return false;
    if (comparison.similarity >= 0.56) return false;

    final normalizedExpected = _normalizeForHardMatch(exp);
    final normalizedRecognized = _normalizeForHardMatch(rec);
    if (normalizedExpected == normalizedRecognized) return false;

    final expectedTokens = _splitHardMatchTokens(normalizedExpected);
    final recognizedTokens = _splitHardMatchTokens(normalizedRecognized);
    if (expectedTokens.length == 1 && recognizedTokens.length == 1) {
      return true;
    }
    return comparison.differences.any(
      (item) =>
          item.startsWith('replace::') ||
          item.startsWith('missing::') ||
          item.startsWith('extra::'),
    );
  }

  String _normalizeForHardMatch(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\u4e00-\u9fff]+', unicode: true), ' ')
        .trim();
  }

  List<String> _splitHardMatchTokens(String value) {
    if (value.isEmpty) return const <String>[];
    return value
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  String _formatDifference(AppI18n i18n, String item) {
    if (item.startsWith('missing::')) {
      return i18n.t(
        'pronunciationDiffMissing',
        params: <String, Object?>{'value': item.substring('missing::'.length)},
      );
    }
    if (item.startsWith('extra::')) {
      return i18n.t(
        'pronunciationDiffExtra',
        params: <String, Object?>{'value': item.substring('extra::'.length)},
      );
    }
    if (item.startsWith('replace::')) {
      final payload = item.substring('replace::'.length).split('::');
      if (payload.length == 2) {
        return i18n.t(
          'pronunciationDiffReplace',
          params: <String, Object?>{'from': payload[0], 'to': payload[1]},
        );
      }
    }
    return item;
  }

  String _formatScoringMethod(AppI18n i18n, String raw) {
    PronScoringMethod? method;
    for (final candidate in PronScoringMethod.values) {
      if (candidate.name == raw) {
        method = candidate;
        break;
      }
    }
    if (method == null) return raw;
    return switch (method) {
      PronScoringMethod.sslEmbedding => i18n.t('scorerSslEmbedding'),
      PronScoringMethod.gop => i18n.t('scorerGop'),
      PronScoringMethod.forcedAlignmentPer => i18n.t(
        'scorerForcedAlignmentPer',
      ),
      PronScoringMethod.ppgPosterior => i18n.t('scorerPpgPosterior'),
    };
  }
}
