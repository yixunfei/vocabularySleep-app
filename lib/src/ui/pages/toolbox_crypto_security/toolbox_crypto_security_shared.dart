part of '../toolbox_crypto_security.dart';

class _LifeOption<T> {
  const _LifeOption({required this.value, required this.labelKey});

  final T value;
  final String labelKey;

  String label(BuildContext context) {
    return _lifeI18nText(context, labelKey);
  }
}

class _LifeSettingsPanel extends StatelessWidget {
  const _LifeSettingsPanel({
    required this.title,
    this.subtitle,
    required this.children,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.shadowOpacity = 0.05,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Color? color;
  final Color? borderColor;
  final Color? shadowColor;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outlineVariant,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (shadowColor ?? Colors.black).withValues(
              alpha: shadowOpacity,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _LifeSegmentedField<T> extends StatelessWidget {
  const _LifeSegmentedField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<_LifeOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map((option) {
                return ChoiceChip(
                  selected: option.value == value,
                  label: Text(option.label(context)),
                  onSelected: (_) => onChanged(option.value),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _LifePreviewFrame extends StatelessWidget {
  const _LifePreviewFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _CryptoPickedFile {
  const _CryptoPickedFile({
    required this.name,
    required this.bytes,
    this.path,
    this.extension,
  });

  final String name;
  final Uint8List bytes;
  final String? path;
  final String? extension;
}

Future<_CryptoPickedFile?> _pickCryptoFile({
  required int maxBytes,
  List<String>? allowedExtensions,
}) async {
  final picked = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: false,
    withReadStream: true,
  );
  final file = (picked != null && picked.files.isNotEmpty)
      ? picked.files.first
      : null;
  if (file == null) {
    return null;
  }
  final bytes = await _readCryptoPlatformFile(file, maxBytes: maxBytes);
  return _CryptoPickedFile(
    name: file.name,
    bytes: bytes,
    path: file.path,
    extension: file.extension,
  );
}

Future<List<ToolboxCryptoKeyFileInput>> _pickCryptoKeyFileInputs() async {
  final picked = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: FileType.any,
    withData: false,
    withReadStream: true,
  );
  final files = picked?.files ?? const <PlatformFile>[];
  if (files.isEmpty) {
    return const <ToolboxCryptoKeyFileInput>[];
  }
  final entries = <ToolboxCryptoKeyFileInput>[];
  var totalSize = 0;
  for (final file in files) {
    _validateCryptoPickedFileSize(
      file.size,
      ToolboxCryptoService.maxKeyFileBytes,
    );
    totalSize += file.size;
    if (totalSize > ToolboxCryptoService.maxCombinedKeyFileBytes) {
      throw const ToolboxCryptoException('Combined key files are too large.');
    }
    final bytes = await _readCryptoPlatformFile(
      file,
      maxBytes: ToolboxCryptoService.maxKeyFileBytes,
    );
    entries.add(ToolboxCryptoKeyFileInput(name: file.name, bytes: bytes));
  }
  return entries;
}

Future<Uint8List> _readCryptoPlatformFile(
  PlatformFile file, {
  required int maxBytes,
}) async {
  _validateCryptoPickedFileSize(file.size, maxBytes);
  final readStream = file.readStream;
  if (readStream != null) {
    return _readCryptoStreamBytesBounded(readStream, maxBytes: maxBytes);
  }
  final filePath = file.path;
  if (!kIsWeb && filePath != null && filePath.trim().isNotEmpty) {
    final source = File(filePath);
    final diskLength = await source.length();
    _validateCryptoPickedFileSize(diskLength, maxBytes);
    return _readCryptoStreamBytesBounded(source.openRead(), maxBytes: maxBytes);
  }
  final bytes = file.bytes;
  if (bytes != null) {
    _validateCryptoPickedFileSize(bytes.length, maxBytes);
    return Uint8List.fromList(bytes);
  }
  throw const ToolboxCryptoException('Selected file cannot be read.');
}

void _validateCryptoPickedFileSize(int size, int maxBytes) {
  if (size <= 0) {
    throw const ToolboxCryptoException('Selected file is empty.');
  }
  if (size > maxBytes) {
    throw ToolboxCryptoException(
      'Selected file is too large. Limit: ${_formatCryptoBytes(maxBytes)}.',
    );
  }
}

Future<Uint8List> _readCryptoStreamBytesBounded(
  Stream<List<int>> stream, {
  required int maxBytes,
}) async {
  final builder = BytesBuilder(copy: false);
  var total = 0;
  await for (final chunk in stream) {
    total += chunk.length;
    if (total > maxBytes) {
      throw ToolboxCryptoException(
        'Selected file is too large. Limit: ${_formatCryptoBytes(maxBytes)}.',
      );
    }
    builder.add(chunk);
  }
  if (total <= 0) {
    throw const ToolboxCryptoException('Selected file is empty.');
  }
  return builder.takeBytes();
}

const int _cryptoFallbackFileNameMaxLength = 180;
const int _cryptoFallbackExtensionMaxLength = 32;
const String _cryptoFallbackDefaultFileName = 'vocabulary_sleep_export.bin';

const Set<String> _cryptoWindowsReservedBaseNames = <String>{
  'CON',
  'PRN',
  'AUX',
  'NUL',
  'COM1',
  'COM2',
  'COM3',
  'COM4',
  'COM5',
  'COM6',
  'COM7',
  'COM8',
  'COM9',
  'LPT1',
  'LPT2',
  'LPT3',
  'LPT4',
  'LPT5',
  'LPT6',
  'LPT7',
  'LPT8',
  'LPT9',
  'CONIN\$',
  'CONOUT\$',
};

final RegExp _cryptoPathSeparatorPattern = RegExp(r'[\\/]+');
final RegExp _cryptoWindowsInvalidFileNameCharsPattern = RegExp(r'[<>:"|?*]');
final RegExp _cryptoTrailingWindowsDotsAndSpacesPattern = RegExp(r'[. ]+$');

Future<String?> _pickCryptoSavePath({
  required String dialogTitle,
  required String fileName,
  required String extension,
  required Uint8List bytes,
}) async {
  try {
    final safeFileName = _sanitizeCryptoFallbackFileName(fileName);
    final safeExtension = _sanitizeCryptoExtension(extension);
    return await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: safeFileName,
      type: FileType.custom,
      allowedExtensions: <String>[safeExtension],
      bytes: kIsWeb ? bytes : null,
    );
  } on UnimplementedError {
    return null;
  }
}

Future<String?> _saveCryptoBytesWithFallback({
  required String? pickedPath,
  required Uint8List bytes,
  required List<String> fallbackSegments,
  required String fallbackFileName,
}) async {
  final normalizedPath = pickedPath?.trim();
  if (normalizedPath != null && normalizedPath.isNotEmpty) {
    if (!kIsWeb) {
      await File(normalizedPath).writeAsBytes(bytes, flush: true);
    }
    return normalizedPath;
  }
  if (kIsWeb) {
    return null;
  }
  final appDir = await getApplicationDocumentsDirectory();
  final exportDir = Directory(
    path.joinAll(<String>[appDir.path, ...fallbackSegments]),
  );
  if (!await exportDir.exists()) {
    await exportDir.create(recursive: true);
  }
  final safeFallbackFileName = _sanitizeCryptoFallbackFileName(
    fallbackFileName,
  );
  final fallback = File(path.join(exportDir.path, safeFallbackFileName));
  await fallback.writeAsBytes(bytes, flush: true);
  return fallback.path;
}

String _sanitizeCryptoFallbackFileName(String fallbackFileName) {
  var fileName = _cryptoUntrustedBasename(fallbackFileName);
  fileName = _stripCryptoControlCharacters(fileName);
  fileName = fileName.replaceAll(_cryptoPathSeparatorPattern, '');
  fileName = fileName.replaceAll(_cryptoWindowsInvalidFileNameCharsPattern, '');
  fileName = fileName.trim().replaceAll(
    _cryptoTrailingWindowsDotsAndSpacesPattern,
    '',
  );
  if (_isCryptoEmptyFileName(fileName)) {
    return _cryptoFallbackDefaultFileName;
  }
  fileName = _avoidCryptoWindowsReservedFileName(fileName);
  fileName = _limitCryptoFileNameLength(fileName);
  if (_isCryptoEmptyFileName(fileName)) {
    return _cryptoFallbackDefaultFileName;
  }
  return fileName;
}

String _cryptoExtensionForUntrustedFileName(String fileName) {
  final safeFileName = _sanitizeCryptoFallbackFileName(fileName);
  return _sanitizeCryptoExtension(path.extension(safeFileName));
}

String _cryptoUntrustedBasename(String fileName) {
  final normalized = fileName.trim().replaceAll('\\', '/');
  if (normalized.isEmpty) {
    return '';
  }
  final segments = normalized
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  if (segments.isEmpty) {
    return '';
  }
  return segments.last;
}

String _stripCryptoControlCharacters(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (!_isCryptoControlRune(rune)) {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

bool _isCryptoControlRune(int rune) {
  return rune <= 0x1F || (rune >= 0x7F && rune <= 0x9F);
}

bool _isCryptoEmptyFileName(String fileName) {
  return fileName.isEmpty || fileName == '.' || fileName == '..';
}

String _avoidCryptoWindowsReservedFileName(String fileName) {
  final extension = path.extension(fileName);
  final baseName = extension.isEmpty
      ? fileName
      : fileName.substring(0, fileName.length - extension.length);
  final windowsBaseName = baseName
      .replaceAll(_cryptoTrailingWindowsDotsAndSpacesPattern, '')
      .toUpperCase();
  if (!_cryptoWindowsReservedBaseNames.contains(windowsBaseName)) {
    return fileName;
  }
  return '_$fileName';
}

String _limitCryptoFileNameLength(String fileName) {
  if (fileName.length <= _cryptoFallbackFileNameMaxLength) {
    return fileName;
  }
  var extension = path.extension(fileName);
  if (extension.length > _cryptoFallbackExtensionMaxLength) {
    extension = '';
  }
  final baseName = extension.isEmpty
      ? fileName
      : fileName.substring(0, fileName.length - extension.length);
  final maxBaseNameLength = _cryptoFallbackFileNameMaxLength - extension.length;
  if (maxBaseNameLength <= 0) {
    return _cryptoFallbackDefaultFileName;
  }
  final truncatedBaseName = _truncateCryptoString(
    baseName,
    maxBaseNameLength,
  ).trim().replaceAll(_cryptoTrailingWindowsDotsAndSpacesPattern, '');
  if (_isCryptoEmptyFileName(truncatedBaseName)) {
    return _cryptoFallbackDefaultFileName;
  }
  return '$truncatedBaseName$extension';
}

String _sanitizeCryptoExtension(String extension) {
  var safeExtension = _cryptoUntrustedBasename(extension);
  safeExtension = _stripCryptoControlCharacters(safeExtension);
  safeExtension = safeExtension.replaceAll(_cryptoPathSeparatorPattern, '');
  safeExtension = safeExtension.replaceAll(
    _cryptoWindowsInvalidFileNameCharsPattern,
    '',
  );
  safeExtension = safeExtension.trim();
  while (safeExtension.startsWith('.')) {
    safeExtension = safeExtension.substring(1);
  }
  final lastDotIndex = safeExtension.lastIndexOf('.');
  if (lastDotIndex >= 0) {
    safeExtension = safeExtension.substring(lastDotIndex + 1);
  }
  safeExtension = _truncateCryptoString(
    safeExtension,
    _cryptoFallbackExtensionMaxLength,
  ).trim();
  if (safeExtension.isEmpty) {
    return 'bin';
  }
  return safeExtension;
}

String _truncateCryptoString(String value, int maxLength) {
  if (value.length <= maxLength) {
    return value;
  }
  final buffer = StringBuffer();
  var length = 0;
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    if (length + character.length > maxLength) {
      break;
    }
    buffer.write(character);
    length += character.length;
  }
  return buffer.toString();
}

Future<bool> _bestEffortOverwriteAndDeleteFile(String? filePath) async {
  final normalized = filePath?.trim();
  if (kIsWeb || normalized == null || normalized.isEmpty) {
    return false;
  }
  final file = File(normalized);
  if (!await file.exists()) {
    return false;
  }
  final length = await file.length();
  if (length <= 0) {
    await file.delete();
    return true;
  }
  final random = math.Random.secure();
  final chunk = Uint8List(64 * 1024);
  final raf = await file.open(mode: FileMode.write);
  try {
    var remaining = length;
    while (remaining > 0) {
      final count = math.min(chunk.length, remaining);
      for (var index = 0; index < count; index += 1) {
        chunk[index] = random.nextInt(256);
      }
      await raf.writeFrom(chunk, 0, count);
      remaining -= count;
    }
    await raf.flush();
  } finally {
    await raf.close();
  }
  await file.delete();
  return true;
}

String _formatCryptoBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final units = <String>['KB', 'MB', 'GB'];
  var value = bytes / 1024.0;
  var unit = units.first;
  for (var index = 1; index < units.length && value >= 1024; index += 1) {
    value /= 1024.0;
    unit = units[index];
  }
  return '${value.toStringAsFixed(value >= 10 ? 1 : 2)} $unit';
}

String _cryptoSha256Short(Uint8List bytes) {
  final digest = sha256.convert(bytes).toString();
  return digest.substring(0, 16);
}

String _cryptoAlgorithmKey(ToolboxCryptoAlgorithm algorithm) {
  return switch (algorithm) {
    ToolboxCryptoAlgorithm.aesGcm => 'toolbox.crypto.algorithm.aes_gcm',
    ToolboxCryptoAlgorithm.chacha20Poly1305 =>
      'toolbox.crypto.algorithm.chacha20_poly1305',
    ToolboxCryptoAlgorithm.twofishGcm => 'toolbox.crypto.algorithm.twofish_gcm',
    ToolboxCryptoAlgorithm.camelliaGcm =>
      'toolbox.crypto.algorithm.camellia_gcm',
    ToolboxCryptoAlgorithm.serpentGcm => 'toolbox.crypto.algorithm.serpent_gcm',
    ToolboxCryptoAlgorithm.kuznyechikGcm =>
      'toolbox.crypto.algorithm.kuznyechik_gcm',
    ToolboxCryptoAlgorithm.aesSerpentKuznyechikGcm =>
      'toolbox.crypto.algorithm.aes_serpent_kuznyechik',
    ToolboxCryptoAlgorithm.aesTwofishCamelliaSerpentKuznyechikGcm =>
      'toolbox.crypto.algorithm.full_five_cascade',
    ToolboxCryptoAlgorithm.customCascade =>
      'toolbox.crypto.algorithm.custom_cascade',
    _ => 'toolbox.crypto.algorithm.aes_gcm',
  };
}

String _cryptoStrengthKey(ToolboxCryptoStrength strength) {
  return switch (strength) {
    ToolboxCryptoStrength.standard => 'toolbox.crypto.strength.standard',
    ToolboxCryptoStrength.strong => 'toolbox.crypto.strength.strong',
    ToolboxCryptoStrength.extreme => 'toolbox.crypto.strength.extreme',
  };
}

String _cryptoKeyBitsKey(ToolboxCryptoKeyBits keyBits) {
  return switch (keyBits) {
    ToolboxCryptoKeyBits.bits256 => 'toolbox.crypto.key_bits.256',
    ToolboxCryptoKeyBits.bits512 => 'toolbox.crypto.key_bits.512',
    ToolboxCryptoKeyBits.bits1024 => 'toolbox.crypto.key_bits.1024',
    ToolboxCryptoKeyBits.bits2048 => 'toolbox.crypto.key_bits.2048',
    ToolboxCryptoKeyBits.bits4096 => 'toolbox.crypto.key_bits.4096',
  };
}

String _cryptoCascadeKey(ToolboxCryptoCascadeCipher cipher) {
  return switch (cipher) {
    ToolboxCryptoCascadeCipher.aes => 'toolbox.crypto.algorithm.aes_gcm',
    ToolboxCryptoCascadeCipher.chacha20 =>
      'toolbox.crypto.algorithm.chacha20_poly1305',
    ToolboxCryptoCascadeCipher.twofish =>
      'toolbox.crypto.algorithm.twofish_gcm',
    ToolboxCryptoCascadeCipher.camellia =>
      'toolbox.crypto.algorithm.camellia_gcm',
    ToolboxCryptoCascadeCipher.serpent =>
      'toolbox.crypto.algorithm.serpent_gcm',
    ToolboxCryptoCascadeCipher.kuznyechik =>
      'toolbox.crypto.algorithm.kuznyechik_gcm',
    ToolboxCryptoCascadeCipher.sha256Stream =>
      'toolbox.crypto.algorithm.sha256_stream',
  };
}

String _cryptoHashAlgorithmKey(ToolboxCryptoHashAlgorithm algorithm) {
  return switch (algorithm) {
    ToolboxCryptoHashAlgorithm.md5 => 'toolbox.crypto.hash.algorithm.md5',
    ToolboxCryptoHashAlgorithm.sha1 => 'toolbox.crypto.hash.algorithm.sha1',
    ToolboxCryptoHashAlgorithm.sha256 => 'toolbox.crypto.hash.algorithm.sha256',
    ToolboxCryptoHashAlgorithm.sha512 => 'toolbox.crypto.hash.algorithm.sha512',
    ToolboxCryptoHashAlgorithm.sha3_256 =>
      'toolbox.crypto.hash.algorithm.sha3_256',
    ToolboxCryptoHashAlgorithm.sha3_512 =>
      'toolbox.crypto.hash.algorithm.sha3_512',
    ToolboxCryptoHashAlgorithm.blake2b256 =>
      'toolbox.crypto.hash.algorithm.blake2b_256',
    ToolboxCryptoHashAlgorithm.blake2b512 =>
      'toolbox.crypto.hash.algorithm.blake2b_512',
    ToolboxCryptoHashAlgorithm.whirlpool =>
      'toolbox.crypto.hash.algorithm.whirlpool',
  };
}

String _cryptoAsymmetricAlgorithmKey(
  ToolboxCryptoAsymmetricAlgorithm algorithm,
) {
  return switch (algorithm) {
    ToolboxCryptoAsymmetricAlgorithm.rsa2048 =>
      'toolbox.crypto.asymmetric.algorithm.rsa_2048',
    ToolboxCryptoAsymmetricAlgorithm.ecP256 =>
      'toolbox.crypto.asymmetric.algorithm.ec_p256',
  };
}

String _cryptoHmacAlgorithmKey(ToolboxCryptoHmacAlgorithm algorithm) {
  return switch (algorithm) {
    ToolboxCryptoHmacAlgorithm.sha1 => 'toolbox.crypto.hash.algorithm.sha1',
    ToolboxCryptoHmacAlgorithm.sha256 => 'toolbox.crypto.hash.algorithm.sha256',
    ToolboxCryptoHmacAlgorithm.sha512 => 'toolbox.crypto.hash.algorithm.sha512',
  };
}

String _cryptoOtpAlgorithmKey(ToolboxCryptoOtpAlgorithm algorithm) {
  return switch (algorithm) {
    ToolboxCryptoOtpAlgorithm.sha1 => 'toolbox.crypto.hash.algorithm.sha1',
    ToolboxCryptoOtpAlgorithm.sha256 => 'toolbox.crypto.hash.algorithm.sha256',
    ToolboxCryptoOtpAlgorithm.sha512 => 'toolbox.crypto.hash.algorithm.sha512',
  };
}

String _friendlyCryptoExtraError(Object error) {
  final text = error is ToolboxCryptoExtraException
      ? error.message
      : error.toString();
  return text.replaceFirst('Exception: ', '');
}

class _CryptoStatusBlock extends StatelessWidget {
  const _CryptoStatusBlock({
    required this.message,
    required this.accent,
    this.isError = false,
  });

  final String message;
  final Color accent;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isError
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
          height: 1.35,
        ),
      ),
    );
  }
}
