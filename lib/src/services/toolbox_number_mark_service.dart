import 'package:flutter/foundation.dart';

enum ToolboxNumberMarkMode {
  superscript,
  subscript,
  circled,
  parenthesized,
  fullwidth,
}

@immutable
class ToolboxNumberMarkTransformResult {
  const ToolboxNumberMarkTransformResult({
    required this.output,
    required this.changedCount,
    required this.unsupportedCount,
  });

  final String output;
  final int changedCount;
  final int unsupportedCount;
}

class ToolboxNumberMarkService {
  const ToolboxNumberMarkService._();

  static ToolboxNumberMarkTransformResult transform(
    String input, {
    required ToolboxNumberMarkMode mode,
    bool reverse = false,
  }) {
    final mapping = reverse ? _reverseMap(mode) : _forwardMap(mode);
    final tokens = mapping.keys.toList(growable: false)
      ..sort((left, right) => right.length.compareTo(left.length));

    final buffer = StringBuffer();
    var cursor = 0;
    var changedCount = 0;
    var unsupportedCount = 0;

    while (cursor < input.length) {
      String? matchedSource;
      String? matchedTarget;
      for (final token in tokens) {
        if (token.isEmpty) {
          continue;
        }
        if (input.startsWith(token, cursor)) {
          matchedSource = token;
          matchedTarget = mapping[token];
          break;
        }
      }

      if (matchedSource != null && matchedTarget != null) {
        buffer.write(matchedTarget);
        if (matchedSource != matchedTarget) {
          changedCount += 1;
        }
        cursor += matchedSource.length;
        continue;
      }

      final char = input[cursor];
      buffer.write(char);
      if (!reverse && _isLikelyConvertible(char)) {
        unsupportedCount += 1;
      }
      cursor += 1;
    }

    return ToolboxNumberMarkTransformResult(
      output: buffer.toString(),
      changedCount: changedCount,
      unsupportedCount: unsupportedCount,
    );
  }

  static Map<String, String> _forwardMap(ToolboxNumberMarkMode mode) {
    return switch (mode) {
      ToolboxNumberMarkMode.superscript => _superscriptMap,
      ToolboxNumberMarkMode.subscript => _subscriptMap,
      ToolboxNumberMarkMode.circled => _circledMap,
      ToolboxNumberMarkMode.parenthesized => _parenthesizedMap,
      ToolboxNumberMarkMode.fullwidth => _fullwidthMap,
    };
  }

  static Map<String, String> _reverseMap(ToolboxNumberMarkMode mode) {
    final reverse = <String, String>{};
    for (final entry in _forwardMap(mode).entries) {
      reverse[entry.value] = entry.key;
    }
    return reverse;
  }

  static bool _isLikelyConvertible(String char) {
    return RegExp(r'[0-9A-Za-z+\-=()]').hasMatch(char);
  }

  static const Map<String, String> _superscriptMap = <String, String>{
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '+': '⁺',
    '-': '⁻',
    '=': '⁼',
    '(': '⁽',
    ')': '⁾',
    'a': 'ᵃ',
    'b': 'ᵇ',
    'c': 'ᶜ',
    'd': 'ᵈ',
    'e': 'ᵉ',
    'f': 'ᶠ',
    'g': 'ᵍ',
    'h': 'ʰ',
    'i': 'ⁱ',
    'j': 'ʲ',
    'k': 'ᵏ',
    'l': 'ˡ',
    'm': 'ᵐ',
    'n': 'ⁿ',
    'o': 'ᵒ',
    'p': 'ᵖ',
    'r': 'ʳ',
    's': 'ˢ',
    't': 'ᵗ',
    'u': 'ᵘ',
    'v': 'ᵛ',
    'w': 'ʷ',
    'x': 'ˣ',
    'y': 'ʸ',
    'z': 'ᶻ',
  };

  static const Map<String, String> _subscriptMap = <String, String>{
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
    '+': '₊',
    '-': '₋',
    '=': '₌',
    '(': '₍',
    ')': '₎',
    'a': 'ₐ',
    'e': 'ₑ',
    'h': 'ₕ',
    'i': 'ᵢ',
    'j': 'ⱼ',
    'k': 'ₖ',
    'l': 'ₗ',
    'm': 'ₘ',
    'n': 'ₙ',
    'o': 'ₒ',
    'p': 'ₚ',
    'r': 'ᵣ',
    's': 'ₛ',
    't': 'ₜ',
    'u': 'ᵤ',
    'v': 'ᵥ',
    'x': 'ₓ',
  };

  static const Map<String, String> _circledMap = <String, String>{
    '0': '⓪',
    '1': '①',
    '2': '②',
    '3': '③',
    '4': '④',
    '5': '⑤',
    '6': '⑥',
    '7': '⑦',
    '8': '⑧',
    '9': '⑨',
    '10': '⑩',
    '11': '⑪',
    '12': '⑫',
    '13': '⑬',
    '14': '⑭',
    '15': '⑮',
    '16': '⑯',
    '17': '⑰',
    '18': '⑱',
    '19': '⑲',
    '20': '⑳',
    'A': 'Ⓐ',
    'B': 'Ⓑ',
    'C': 'Ⓒ',
    'D': 'Ⓓ',
    'E': 'Ⓔ',
    'F': 'Ⓕ',
    'G': 'Ⓖ',
    'H': 'Ⓗ',
    'I': 'Ⓘ',
    'J': 'Ⓙ',
    'K': 'Ⓚ',
    'L': 'Ⓛ',
    'M': 'Ⓜ',
    'N': 'Ⓝ',
    'O': 'Ⓞ',
    'P': 'Ⓟ',
    'Q': 'Ⓠ',
    'R': 'Ⓡ',
    'S': 'Ⓢ',
    'T': 'Ⓣ',
    'U': 'Ⓤ',
    'V': 'Ⓥ',
    'W': 'Ⓦ',
    'X': 'Ⓧ',
    'Y': 'Ⓨ',
    'Z': 'Ⓩ',
    'a': 'ⓐ',
    'b': 'ⓑ',
    'c': 'ⓒ',
    'd': 'ⓓ',
    'e': 'ⓔ',
    'f': 'ⓕ',
    'g': 'ⓖ',
    'h': 'ⓗ',
    'i': 'ⓘ',
    'j': 'ⓙ',
    'k': 'ⓚ',
    'l': 'ⓛ',
    'm': 'ⓜ',
    'n': 'ⓝ',
    'o': 'ⓞ',
    'p': 'ⓟ',
    'q': 'ⓠ',
    'r': 'ⓡ',
    's': 'ⓢ',
    't': 'ⓣ',
    'u': 'ⓤ',
    'v': 'ⓥ',
    'w': 'ⓦ',
    'x': 'ⓧ',
    'y': 'ⓨ',
    'z': 'ⓩ',
  };

  static const Map<String, String> _parenthesizedMap = <String, String>{
    '1': '⑴',
    '2': '⑵',
    '3': '⑶',
    '4': '⑷',
    '5': '⑸',
    '6': '⑹',
    '7': '⑺',
    '8': '⑻',
    '9': '⑼',
    '10': '⑽',
    '11': '⑾',
    '12': '⑿',
    '13': '⒀',
    '14': '⒁',
    '15': '⒂',
    '16': '⒃',
    '17': '⒄',
    '18': '⒅',
    '19': '⒆',
    '20': '⒇',
  };

  static const Map<String, String> _fullwidthMap = <String, String>{
    '0': '０',
    '1': '１',
    '2': '２',
    '3': '３',
    '4': '４',
    '5': '５',
    '6': '６',
    '7': '７',
    '8': '８',
    '9': '９',
    'A': 'Ａ',
    'B': 'Ｂ',
    'C': 'Ｃ',
    'D': 'Ｄ',
    'E': 'Ｅ',
    'F': 'Ｆ',
    'G': 'Ｇ',
    'H': 'Ｈ',
    'I': 'Ｉ',
    'J': 'Ｊ',
    'K': 'Ｋ',
    'L': 'Ｌ',
    'M': 'Ｍ',
    'N': 'Ｎ',
    'O': 'Ｏ',
    'P': 'Ｐ',
    'Q': 'Ｑ',
    'R': 'Ｒ',
    'S': 'Ｓ',
    'T': 'Ｔ',
    'U': 'Ｕ',
    'V': 'Ｖ',
    'W': 'Ｗ',
    'X': 'Ｘ',
    'Y': 'Ｙ',
    'Z': 'Ｚ',
    'a': 'ａ',
    'b': 'ｂ',
    'c': 'ｃ',
    'd': 'ｄ',
    'e': 'ｅ',
    'f': 'ｆ',
    'g': 'ｇ',
    'h': 'ｈ',
    'i': 'ｉ',
    'j': 'ｊ',
    'k': 'ｋ',
    'l': 'ｌ',
    'm': 'ｍ',
    'n': 'ｎ',
    'o': 'ｏ',
    'p': 'ｐ',
    'q': 'ｑ',
    'r': 'ｒ',
    's': 'ｓ',
    't': 'ｔ',
    'u': 'ｕ',
    'v': 'ｖ',
    'w': 'ｗ',
    'x': 'ｘ',
    'y': 'ｙ',
    'z': 'ｚ',
    '+': '＋',
    '-': '－',
    '=': '＝',
    '(': '（',
    ')': '）',
    ' ': '　',
  };
}
