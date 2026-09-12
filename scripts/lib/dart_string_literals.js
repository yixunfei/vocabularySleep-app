'use strict';

// [风险] 原实现用单个正则匹配 Dart 字符串字面量，遇到
// `'${expr ?? 'fallback'}'` 这类插值内嵌套引号时会错位，
// 导致后续整段文件的字面量漏扫（key 被误判为未引用）。
// 这里改为逐字符状态机：支持原始字符串、三引号、转义、
// `${...}` 插值（含嵌套字符串与嵌套花括号）、行/块注释。
// 插值表达式内部的字符串字面量同样单独收集。

function isQuoteStart(source, i) {
  const ch = source[i];
  return ch === "'" || ch === '"';
}

// 扫描一个字符串字面量，返回结束索引（越过闭引号）。
// 字面量内容（含插值原文）推入 out；插值内部的字符串由递归处理。
function scanDartString(source, start, out) {
  const n = source.length;
  let i = start;
  let raw = false;
  if (source[i] === 'r' && (source[i + 1] === "'" || source[i + 1] === '"')) {
    raw = true;
    i += 1;
  }
  const quote = source[i];
  const triple = source[i + 1] === quote && source[i + 2] === quote;
  const quoteRun = triple ? 3 : 1;
  i += quoteRun;
  const contentStart = i;
  let interpolationDepth = 0;

  while (i < n) {
    const ch = source[i];

    if (interpolationDepth === 0) {
      if (!raw && ch === '\\') {
        i += 2;
        continue;
      }
      if (!triple && ch === '\n') {
        // 单引号字符串不允许裸换行：按提前结束处理，避免继续错位。
        out.push({ value: source.slice(contentStart, i), index: contentStart });
        return i + 1;
      }
      if (!raw && ch === '$' && source[i + 1] === '{') {
        interpolationDepth = 1;
        i += 2;
        continue;
      }
      if (!raw && ch === '$') {
        // $identifier 简单插值：标识符不含引号，直接跳过。
        i += 1;
        while (i < n && /[A-Za-z0-9_$]/.test(source[i])) {
          i += 1;
        }
        continue;
      }
      if (ch === quote) {
        if (!triple) {
          out.push({ value: source.slice(contentStart, i), index: contentStart });
          return i + 1;
        }
        if (source[i + 1] === quote && source[i + 2] === quote) {
          out.push({ value: source.slice(contentStart, i), index: contentStart });
          return i + 3;
        }
      }
      i += 1;
      continue;
    }

    // 插值表达式内部：跟踪花括号深度，其中的字符串按规则递归处理。
    if (ch === '{') {
      interpolationDepth += 1;
      i += 1;
      continue;
    }
    if (ch === '}') {
      interpolationDepth -= 1;
      i += 1;
      continue;
    }
    if (!raw && ch === '\\') {
      i += 2;
      continue;
    }
    if (isQuoteStart(source, i)) {
      i = scanDartString(source, i, out);
      continue;
    }
    i += 1;
  }
  out.push({ value: source.slice(contentStart, i), index: contentStart });
  return i;
}

function extractDartStringLiterals(source) {
  const out = [];
  const n = source.length;
  let i = 0;
  let inLineComment = false;
  let blockCommentDepth = 0;

  while (i < n) {
    const ch = source[i];

    if (inLineComment) {
      if (ch === '\n') {
        inLineComment = false;
      }
      i += 1;
      continue;
    }
    if (blockCommentDepth > 0) {
      if (ch === '/' && source[i + 1] === '*') {
        blockCommentDepth += 1;
        i += 2;
        continue;
      }
      if (ch === '*' && source[i + 1] === '/') {
        blockCommentDepth -= 1;
        i += 2;
        continue;
      }
      i += 1;
      continue;
    }

    if (ch === '/' && source[i + 1] === '/') {
      inLineComment = true;
      i += 2;
      continue;
    }
    if (ch === '/' && source[i + 1] === '*') {
      blockCommentDepth = 1;
      i += 2;
      continue;
    }
    if (
      isQuoteStart(source, i) ||
      (ch === 'r' && (source[i + 1] === "'" || source[i + 1] === '"'))
    ) {
      i = scanDartString(source, i, out);
      continue;
    }
    i += 1;
  }
  return out;
}

module.exports = { extractDartStringLiterals };
