part of '../toolbox_crypto_security.dart';

enum _ContentMediaMode { encode, decode }

enum _ContentMediaInputKind { text, file }

enum _ContentMediaImageMinimum { auto, square512, square1024 }

class _ContentMediaToolPage extends StatefulWidget {
  const _ContentMediaToolPage();

  @override
  State<_ContentMediaToolPage> createState() => _ContentMediaToolPageState();
}

class _ContentMediaToolPageState extends State<_ContentMediaToolPage> {
  final ToolboxContentMediaCodecService _mediaService =
      ToolboxContentMediaCodecService();
  final ToolboxCryptoService _cryptoService = ToolboxCryptoService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _passphraseController = TextEditingController();
  final TextEditingController _keyFileLengthController = TextEditingController(
    text: '4096',
  );
  final TextEditingController _mediaUrlController = TextEditingController();
  final TextEditingController _maxErrorsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _maxDecryptsController = TextEditingController(
    text: '0',
  );

  _ContentMediaMode _mode = _ContentMediaMode.encode;
  _ContentMediaInputKind _inputKind = _ContentMediaInputKind.text;
  ToolboxContentMediaFormat _format = ToolboxContentMediaFormat.imagePng;
  ToolboxCryptoAlgorithm _algorithm = ToolboxCryptoAlgorithm.aesGcm;
  ToolboxCryptoStrength _strength = ToolboxCryptoStrength.standard;
  ToolboxCryptoKeyBits _keyBits = ToolboxCryptoKeyBits.bits256;
  ToolboxCryptoMacAlgorithm _macAlgorithm = ToolboxCryptoMacAlgorithm.sha256;
  ToolboxCryptoSignatureMode _signatureMode =
      ToolboxCryptoSignatureMode.ecdsaSha256;
  _ContentMediaImageMinimum _imageMinimum = _ContentMediaImageMinimum.square512;
  ToolboxContentMediaImageFillMode _imageFillMode =
      ToolboxContentMediaImageFillMode.softGradient;
  List<ToolboxCryptoCascadeCipher> _cascade =
      const <ToolboxCryptoCascadeCipher>[
        ToolboxCryptoCascadeCipher.aes,
        ToolboxCryptoCascadeCipher.twofish,
        ToolboxCryptoCascadeCipher.serpent,
      ];

  _CryptoPickedFile? _sourceFile;
  _CryptoPickedFile? _mediaFile;
  ToolboxCryptoCombinedKeyFileResult? _combinedKeyFile;
  ToolboxContentMediaEncodeResult? _encodeResult;
  ToolboxContentMediaDecodeResult? _decodeResult;
  ToolboxImageToWebUploadResult? _shareResult;
  Uint8List? _outputBytes;
  String? _outputName;
  String? _restoredText;
  String? _savedPath;
  String? _statusMessage;
  String? _error;
  bool _busy = false;
  bool _uploading = false;
  bool _configExpanded = false;
  bool _overwriteMediaOnThreshold = false;
  late final AudioPlayer _previewPlayer;
  StreamSubscription<void>? _previewCompleteSubscription;
  bool _previewPlaying = false;
  int _failedAttempts = 0;
  int _successfulDecrypts = 0;

  bool get _isEncode => _mode == _ContentMediaMode.encode;

  void applyState(VoidCallback fn) => setState(fn);

  @override
  void initState() {
    super.initState();
    _previewPlayer = AudioPlayer();
    _previewCompleteSubscription = _previewPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() => _previewPlaying = false);
    });
  }

  @override
  void dispose() {
    _previewCompleteSubscription?.cancel();
    unawaited(_previewPlayer.dispose());
    _textController.dispose();
    _passphraseController.dispose();
    _keyFileLengthController.dispose();
    _mediaUrlController.dispose();
    _maxErrorsController.dispose();
    _maxDecryptsController.dispose();
    _wipeBytes(_sourceFile?.bytes);
    _wipeBytes(_mediaFile?.bytes);
    _wipeBytes(_outputBytes);
    _wipeCombinedKeyFile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.crypto.content_media.title'),
      subtitle: _lifeI18nText(context, 'toolbox.crypto.content_media.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStageCard(context),
          const SizedBox(height: 10),
          _buildModePanel(context),
          const SizedBox(height: 10),
          if (_isEncode)
            _buildInputPanel(context)
          else
            _buildMediaPickPanel(context),
          if (_isEncode) ...<Widget>[
            const SizedBox(height: 10),
            _buildFormatPanel(context),
            const SizedBox(height: 10),
            _buildEncryptionPanel(context),
          ],
          const SizedBox(height: 10),
          _buildCredentialPanel(context),
          const SizedBox(height: 12),
          _buildActionPanel(context),
          const SizedBox(height: 10),
          _buildResultPanel(context),
        ],
      ),
    );
  }

  Future<void> _pickPlainFile() async {
    try {
      final picked = await _pickCryptoFile(
        maxBytes: ToolboxContentMediaCodecService.maxMediaEnvelopeBytes,
      );
      if (picked == null || !mounted) {
        return;
      }
      setState(() {
        _wipeBytes(_sourceFile?.bytes);
        _sourceFile = picked;
        _clearResultOnly();
        _error = null;
        _failedAttempts = 0;
        _successfulDecrypts = 0;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.source_ready',
          params: <String, Object?>{'name': picked.name},
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.file.pick_failed', error);
    }
  }

  Future<void> _pickEncodedMedia() async {
    try {
      final picked = await _pickCryptoFile(
        maxBytes: ToolboxCryptoService.maxEnvelopeBytes,
        allowedExtensions: const <String>['png', 'wav', 'wave'],
      );
      if (picked == null || !mounted) {
        return;
      }
      setState(() {
        _wipeBytes(_mediaFile?.bytes);
        _mediaFile = picked;
        _mediaUrlController.clear();
        _clearResultOnly();
        _error = null;
        _failedAttempts = 0;
        _successfulDecrypts = 0;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.source_ready',
          params: <String, Object?>{'name': picked.name},
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.file.pick_failed', error);
    }
  }

  Future<void> _loadNetworkImage() async {
    final Uri uri;
    try {
      uri = ToolboxContentMediaCodecService.normalizeNetworkImageUri(
        _mediaUrlController.text,
      );
    } catch (error) {
      _setError('toolbox.crypto.content_media.network_image_failed', error);
      return;
    }
    try {
      setState(() {
        _busy = true;
        _error = null;
        _shareResult = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.network_image_loading',
        );
      });
      final bytes = await _downloadNetworkPng(uri);
      if (!mounted) {
        return;
      }
      final picked = _CryptoPickedFile(
        name: ToolboxContentMediaCodecService.networkImageFileName(uri),
        bytes: bytes,
        extension: 'png',
      );
      setState(() {
        _wipeBytes(_mediaFile?.bytes);
        _mediaFile = picked;
        _clearResultOnly();
        _error = null;
        _busy = false;
        _failedAttempts = 0;
        _successfulDecrypts = 0;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.network_image_loaded',
          params: <String, Object?>{
            'name': picked.name,
            'size': _formatCryptoBytes(picked.bytes.length),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.content_media.network_image_failed', error);
    }
  }

  Future<Uint8List> _downloadNetworkPng(Uri initialUri) async {
    var uri = initialUri;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      for (
        var redirect = 0;
        redirect <= ToolboxContentMediaCodecService.networkImageMaxRedirects;
        redirect += 1
      ) {
        uri = ToolboxContentMediaCodecService.normalizeNetworkImageUri(
          uri.toString(),
        );
        await _rejectPrivateNetworkImageAddress(uri.host);
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        request.headers.set(
          HttpHeaders.acceptHeader,
          'image/png,application/octet-stream;q=0.8,*/*;q=0.1',
        );
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
        if (response.isRedirect) {
          if (redirect >=
              ToolboxContentMediaCodecService.networkImageMaxRedirects) {
            await response.drain<void>();
            throw const ToolboxContentMediaException(
              'Network image has too many redirects.',
            );
          }
          final location = response.headers.value(HttpHeaders.locationHeader);
          await response.drain<void>();
          if (location == null || location.trim().isEmpty) {
            throw const ToolboxContentMediaException(
              'Network image redirect is invalid.',
            );
          }
          uri = ToolboxContentMediaCodecService.normalizeNetworkImageUri(
            uri.resolve(location).toString(),
          );
          continue;
        }
        if (response.statusCode != HttpStatus.ok) {
          await response.drain<void>();
          throw const ToolboxContentMediaException(
            'Network image download failed.',
          );
        }
        final mimeType = response.headers.contentType?.mimeType;
        if (!ToolboxContentMediaCodecService.allowsNetworkImageContentType(
          mimeType,
        )) {
          await response.drain<void>();
          throw const ToolboxContentMediaException(
            'Network image response is not a PNG image.',
          );
        }
        if (response.contentLength > ToolboxCryptoService.maxEnvelopeBytes) {
          await response.drain<void>();
          throw const ToolboxContentMediaException(
            'Network image is too large.',
          );
        }
        final bytes = await _readCryptoStreamBytesBounded(
          response,
          maxBytes: ToolboxCryptoService.maxEnvelopeBytes,
        );
        if (!ToolboxContentMediaCodecService.hasPngSignature(bytes)) {
          throw const ToolboxContentMediaException(
            'Network image response is not a PNG image.',
          );
        }
        return bytes;
      }
      throw const ToolboxContentMediaException(
        'Network image has too many redirects.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _rejectPrivateNetworkImageAddress(String host) async {
    if (ToolboxContentMediaCodecService.isBlockedNetworkImageHost(host)) {
      throw const ToolboxContentMediaException(
        'Network image host is local or private.',
      );
    }
    final addresses = await InternetAddress.lookup(
      host,
    ).timeout(const Duration(seconds: 6));
    if (addresses.any(
      (address) => ToolboxContentMediaCodecService.isBlockedNetworkImageHost(
        address.address,
      ),
    )) {
      throw const ToolboxContentMediaException(
        'Network image host is local or private.',
      );
    }
  }

  Future<void> _pickKeyFiles() async {
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.text.key_files_loading',
        );
      });
      final entries = await _pickCryptoKeyFileInputs();
      if (!mounted) {
        return;
      }
      if (entries.isEmpty) {
        setState(() => _busy = false);
        return;
      }
      final combined = _cryptoService.combineKeyFiles(entries);
      setState(() {
        _wipeCombinedKeyFile();
        _combinedKeyFile = combined;
        _busy = false;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.key_files_ready',
          params: <String, Object?>{
            'count': combined.entries.length,
            'hash': combined.sha256.substring(0, 16),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.file.key_files_failed', error);
    }
  }

  Future<void> _encodeContent() async {
    final plain = _plainBytes;
    if (plain.isEmpty) {
      _setPlainError('toolbox.crypto.content_media.error_need_content');
      return;
    }
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.encoding',
        );
      });
      final baseName = _sourceFile == null
          ? 'content_text'
          : path.basenameWithoutExtension(_sourceFile!.name);
      final minimumWidth = _minimumImageWidth;
      final minimumHeight = _minimumImageHeight;
      final result = _format == ToolboxContentMediaFormat.imagePng
          ? _mediaService.encryptToPngImage(
              plainBytes: plain,
              algorithm: _algorithm,
              strength: _strength,
              passphrase: _passphraseController.text,
              keyFileBytes: _combinedKeyFile?.bytes,
              fileName: _inputKind == _ContentMediaInputKind.file
                  ? _sourceFile?.name
                  : 'content_text.txt',
              mediaType: _inputKind == _ContentMediaInputKind.text
                  ? 'text/plain;charset=utf-8'
                  : null,
              cascade: _algorithm == ToolboxCryptoAlgorithm.customCascade
                  ? _cascade
                  : null,
              keyBits: _keyBits,
              macAlgorithm: _macAlgorithm,
              signatureMode: _signatureMode,
              outputFileName: '${baseName}_encrypted_media.png',
              minimumImageWidth: minimumWidth,
              minimumImageHeight: minimumHeight,
              fillMode: _imageFillMode,
            )
          : _mediaService.encryptToWavAudio(
              plainBytes: plain,
              algorithm: _algorithm,
              strength: _strength,
              passphrase: _passphraseController.text,
              keyFileBytes: _combinedKeyFile?.bytes,
              fileName: _inputKind == _ContentMediaInputKind.file
                  ? _sourceFile?.name
                  : 'content_text.txt',
              mediaType: _inputKind == _ContentMediaInputKind.text
                  ? 'text/plain;charset=utf-8'
                  : null,
              cascade: _algorithm == ToolboxCryptoAlgorithm.customCascade
                  ? _cascade
                  : null,
              keyBits: _keyBits,
              macAlgorithm: _macAlgorithm,
              signatureMode: _signatureMode,
              outputFileName: '${baseName}_encrypted_media.wav',
            );
      if (!mounted) {
        return;
      }
      setState(() {
        _stopAudioPreviewSilently();
        _wipeBytes(_outputBytes);
        _previewPlaying = false;
        _busy = false;
        _encodeResult = result;
        _decodeResult = null;
        _shareResult = null;
        _outputBytes = result.bytes;
        _outputName = result.fileName;
        _restoredText = null;
        _savedPath = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.encode_success',
          params: <String, Object?>{
            'size': _formatCryptoBytes(result.bytes.length),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.content_media.encode_failed', error);
    }
  }

  Future<void> _decodeContent() async {
    final media = _mediaFile;
    if (media == null) {
      _setPlainError('toolbox.crypto.content_media.error_need_media');
      return;
    }
    final policy = _attemptPolicy;
    if (policy.blocksBeforeDecrypt) {
      await _triggerThresholdClear(
        'toolbox.crypto.content_media.decrypt_limit_cleared',
      );
      return;
    }
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.decoding',
        );
      });
      final result = _mediaService.decryptFromMediaBytes(
        mediaBytes: media.bytes,
        passphrase: _passphraseController.text,
        keyFileBytes: _combinedKeyFile?.bytes,
        extension: media.extension,
      );
      if (!mounted) {
        return;
      }
      final restoredText = _decodedTextOrNull(result);
      _successfulDecrypts += 1;
      setState(() {
        _stopAudioPreviewSilently();
        _wipeBytes(_outputBytes);
        _previewPlaying = false;
        _busy = false;
        _failedAttempts = 0;
        _decodeResult = result;
        _encodeResult = null;
        _shareResult = null;
        _outputBytes = result.plainBytes;
        _outputName = result.fileName ?? _decryptedOutputName(media.name);
        _restoredText = restoredText;
        _savedPath = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.decode_success',
          params: <String, Object?>{
            'size': _formatCryptoBytes(result.plainBytes.length),
          },
        );
      });
      if (restoredText != null && mounted) {
        await _showRestoredTextDialog(restoredText);
      }
      if (policy.clearsAfterDecryptSuccess) {
        await _triggerThresholdClear(
          'toolbox.crypto.content_media.decrypt_limit_cleared',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _failedAttempts += 1;
      setState(() => _busy = false);
      if (policy.clearsAfterDecryptFailure) {
        await _triggerThresholdClear(
          'toolbox.crypto.content_media.error_limit_cleared',
        );
      } else {
        _setError(
          'toolbox.crypto.content_media.decode_failed_with_count',
          error,
          extraParams: <String, Object?>{'count': _failedAttempts},
        );
      }
    }
  }

  Future<void> _showRestoredTextDialog(String restoredText) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text(
            _lifeI18nText(
              dialogContext,
              'toolbox.crypto.content_media.text_restored_title',
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _lifeI18nText(
                    dialogContext,
                    'toolbox.crypto.content_media.text_restored_subtitle',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        restoredText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_lifeI18nText(dialogContext, 'close')),
            ),
            FilledButton.icon(
              onPressed: () async {
                await _copyRestoredText(restoredText);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: Text(
                _lifeI18nText(
                  dialogContext,
                  'toolbox.crypto.content_media.copy_text',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyRestoredText(String restoredText) async {
    try {
      await Clipboard.setData(ClipboardData(text: restoredText));
      if (!mounted) {
        return;
      }
      setState(() {
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.text_copied',
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.text_copy_failed',
          params: <String, Object?>{'error': _friendlyMediaError(error)},
        );
        _statusMessage = null;
      });
    }
  }

  Future<void> _exportOutput() async {
    final bytes = _outputBytes;
    final fileName = _outputName;
    if (bytes == null || fileName == null) {
      return;
    }
    try {
      final extension = _extensionForFileName(fileName);
      final pickedPath = await _pickCryptoSavePath(
        dialogTitle: _lifeI18nText(context, 'toolbox.crypto.file.save_dialog'),
        fileName: fileName,
        extension: extension,
        bytes: bytes,
      );
      final savedPath = await _saveCryptoBytesWithFallback(
        pickedPath: pickedPath,
        bytes: bytes,
        fallbackSegments: const <String>[
          'toolbox_crypto_security',
          'content_media',
        ],
        fallbackFileName: fileName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _savedPath = savedPath;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.export_success',
          params: <String, Object?>{
            'path':
                savedPath ??
                _lifeI18nText(
                  context,
                  'toolbox.crypto.common.browser_download',
                ),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.file.export_failed', error);
    }
  }

  Future<void> _simulatePngDamage() async {
    final bytes = _outputBytes;
    final fileName = _outputName;
    if (bytes == null ||
        fileName == null ||
        _encodeResult?.format != ToolboxContentMediaFormat.imagePng) {
      _setPlainError('toolbox.crypto.content_media.damage_need_png');
      return;
    }
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.damage_generating',
        );
      });
      final damaged = _mediaService.simulatePngTransferDamage(
        imageBytes: bytes,
        level: ToolboxContentMediaDamageLevel.light,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _wipeBytes(_outputBytes);
        _outputBytes = damaged;
        _outputName = _damagedPngName(fileName);
        _shareResult = null;
        _busy = false;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.damage_success',
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.content_media.damage_failed', error);
    }
  }

  Future<void> _uploadEncryptedPngToUguu() async {
    final bytes = _outputBytes;
    final fileName = _outputName;
    if (bytes == null ||
        fileName == null ||
        _encodeResult?.format != ToolboxContentMediaFormat.imagePng) {
      _setPlainError('toolbox.crypto.content_media.share_need_png');
      return;
    }
    try {
      setState(() {
        _uploading = true;
        _shareResult = null;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.share_uploading',
        );
      });
      final result = await ToolboxImageToWebService.uploadToUguu(
        imageBytes: bytes,
        fileName: fileName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _uploading = false;
        _shareResult = result;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.share_success',
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _uploading = false);
      _setError('toolbox.crypto.content_media.share_failed', error);
    }
  }

  Future<void> _copyShareLink() async {
    final result = _shareResult;
    if (result == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: result.url.toString()));
    if (!mounted) {
      return;
    }
    setState(() {
      _error = null;
      _statusMessage = _lifeI18nText(
        context,
        'toolbox.crypto.content_media.share_link_copied',
      );
    });
  }

  Future<void> _openShareLink() async {
    final result = _shareResult;
    if (result == null) {
      return;
    }
    final ok = await launchUrl(
      result.url,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      _setPlainError('toolbox.crypto.content_media.share_open_failed');
    }
  }

  Future<void> _toggleAudioPreview() async {
    final bytes = _outputBytes;
    if (bytes == null ||
        _encodeResult?.format != ToolboxContentMediaFormat.audioWav) {
      return;
    }
    try {
      if (_previewPlaying) {
        await _stopAudioPreview(updateState: true);
        return;
      }
      await AudioPlayerSourceHelper.play(
        _previewPlayer,
        BytesSource(bytes, mimeType: 'audio/wav'),
        volume: 1,
        tag: 'toolbox_content_media_preview',
        data: <String, Object?>{'bytes': bytes.length},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _previewPlaying = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.content_media.preview_audio_playing',
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _previewPlaying = false);
      _setError('toolbox.crypto.content_media.preview_audio_failed', error);
    }
  }

  Future<void> _stopAudioPreview({required bool updateState}) async {
    await _previewPlayer.stop();
    if (!mounted) {
      return;
    }
    if (updateState) {
      setState(() => _previewPlaying = false);
    } else {
      _previewPlaying = false;
    }
  }

  void _stopAudioPreviewSilently() {
    _previewPlaying = false;
    unawaited(_previewPlayer.stop());
  }

  void _clearPlainFile() {
    setState(() {
      _wipeBytes(_sourceFile?.bytes);
      _sourceFile = null;
      _shareResult = null;
      _clearResultOnly();
      _error = null;
      _statusMessage = null;
      _failedAttempts = 0;
      _successfulDecrypts = 0;
    });
  }

  void _clearEncodedMedia() {
    setState(() {
      _stopAudioPreviewSilently();
      _wipeBytes(_mediaFile?.bytes);
      _mediaFile = null;
      _mediaUrlController.clear();
      _shareResult = null;
      _clearResultOnly();
      _error = null;
      _statusMessage = null;
      _failedAttempts = 0;
      _successfulDecrypts = 0;
    });
  }

  void _clearKeyFiles() {
    setState(() {
      _wipeCombinedKeyFile();
      _combinedKeyFile = null;
      _error = null;
      _statusMessage = null;
    });
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _wipeBytes(_sourceFile?.bytes);
      _wipeBytes(_mediaFile?.bytes);
      _sourceFile = null;
      _mediaFile = null;
      _mediaUrlController.clear();
      _wipeCombinedKeyFile();
      _combinedKeyFile = null;
      _passphraseController.clear();
      _shareResult = null;
      _clearResultOnly();
      _error = null;
      _statusMessage = null;
      _failedAttempts = 0;
      _successfulDecrypts = 0;
    });
  }

  Future<void> _triggerThresholdClear(String messageKey) async {
    final mediaPath = _mediaFile?.path;
    final didOverwrite = _overwriteMediaOnThreshold
        ? await _bestEffortOverwriteAndDeleteFile(mediaPath)
        : false;
    if (!mounted) {
      return;
    }
    setState(() {
      _wipeAndClearSensitiveState();
      _busy = false;
      _uploading = false;
      _error = null;
      _statusMessage = didOverwrite
          ? _lifeI18nText(
              context,
              'toolbox.crypto.content_media.threshold_cleared_deleted',
            )
          : _lifeI18nText(context, messageKey);
    });
  }

  void _wipeAndClearSensitiveState() {
    _stopAudioPreviewSilently();
    _textController.clear();
    _mediaUrlController.clear();
    _wipeBytes(_sourceFile?.bytes);
    _wipeBytes(_mediaFile?.bytes);
    _wipeBytes(_outputBytes);
    _sourceFile = null;
    _mediaFile = null;
    _encodeResult = null;
    _decodeResult = null;
    _shareResult = null;
    _outputBytes = null;
    _outputName = null;
    _restoredText = null;
    _savedPath = null;
    _wipeCombinedKeyFile();
    _combinedKeyFile = null;
    _passphraseController.clear();
    _failedAttempts = 0;
    _successfulDecrypts = 0;
  }

  Future<void> _showGenerateKeyFileDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _lifeI18nText(
              dialogContext,
              'toolbox.crypto.content_media.key_generate_title',
            ),
          ),
          content: TextField(
            controller: _keyFileLengthController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _lifeI18nText(
                dialogContext,
                'toolbox.crypto.keyfile.length_label',
              ),
              helperText: _lifeI18nText(
                dialogContext,
                'toolbox.crypto.keyfile.length_helper',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_lifeI18nText(dialogContext, 'cancel')),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _generateKeyFileForCurrentSelection();
              },
              icon: const Icon(Icons.casino_rounded),
              label: Text(
                _lifeI18nText(
                  dialogContext,
                  'toolbox.crypto.keyfile.generate_random',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateKeyFileForCurrentSelection() async {
    final length = int.tryParse(_keyFileLengthController.text.trim());
    if (length == null ||
        length < 32 ||
        length > ToolboxCryptoService.maxKeyFileBytes) {
      _setPlainError('toolbox.crypto.content_media.key_length_invalid');
      return;
    }
    try {
      setState(() {
        _busy = true;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.generating',
        );
      });
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = _cryptoService.generateKeyFile(
        length: length,
        fileName: 'vocabulary_sleep_content_media_key_$timestamp.bin',
      );
      final combined = _cryptoService.combineKeyFiles(
        <ToolboxCryptoKeyFileInput>[
          ToolboxCryptoKeyFileInput(name: result.fileName, bytes: result.bytes),
        ],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _wipeCombinedKeyFile();
        _combinedKeyFile = combined;
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.file.key_file_generated',
          params: <String, Object?>{
            'size': _formatCryptoBytes(combined.length),
            'hash': combined.sha256.substring(0, 16),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.keyfile.generate_failed', error);
    }
  }

  Future<void> _exportCurrentKeyFile() async {
    final keyFile = _combinedKeyFile;
    if (keyFile == null) {
      return;
    }
    try {
      final pickedPath = await _pickCryptoSavePath(
        dialogTitle: _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.save_dialog',
        ),
        fileName: keyFile.fileName,
        extension: _extensionForFileName(keyFile.fileName),
        bytes: keyFile.bytes,
      );
      final savedPath = await _saveCryptoBytesWithFallback(
        pickedPath: pickedPath,
        bytes: keyFile.bytes,
        fallbackSegments: const <String>[
          'toolbox_crypto_security',
          'content_media',
          'key_files',
        ],
        fallbackFileName: keyFile.fileName,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = null;
        _statusMessage = _lifeI18nText(
          context,
          'toolbox.crypto.keyfile.export_success',
          params: <String, Object?>{
            'path':
                savedPath ??
                _lifeI18nText(
                  context,
                  'toolbox.crypto.common.browser_download',
                ),
          },
        );
      });
    } catch (error) {
      _setError('toolbox.crypto.keyfile.export_failed', error);
    }
  }

  void _clearResultOnly() {
    _stopAudioPreviewSilently();
    _wipeBytes(_outputBytes);
    _encodeResult = null;
    _decodeResult = null;
    _shareResult = null;
    _outputBytes = null;
    _outputName = null;
    _restoredText = null;
    _savedPath = null;
    _previewPlaying = false;
  }

  void _setError(
    String key,
    Object error, {
    Map<String, Object?> extraParams = const <String, Object?>{},
  }) {
    if (!mounted) {
      return;
    }
    final params = <String, Object?>{
      ...extraParams,
      'error': _friendlyMediaError(error),
    };
    setState(() {
      _error = _lifeI18nText(context, key, params: params);
      _statusMessage = null;
      _busy = false;
    });
  }

  void _setPlainError(String key) {
    setState(() {
      _error = _lifeI18nText(context, key);
      _statusMessage = null;
      _busy = false;
    });
  }

  Uint8List get _plainBytes {
    if (_inputKind == _ContentMediaInputKind.file) {
      return _sourceFile?.bytes ?? Uint8List(0);
    }
    return Uint8List.fromList(utf8.encode(_textController.text));
  }

  int get _plainSize {
    if (!_isEncode) {
      return 0;
    }
    return _plainBytes.length;
  }

  void _wipeCombinedKeyFile() {
    _wipeBytes(_combinedKeyFile?.bytes);
  }

  void _wipeBytes(Uint8List? bytes) {
    ToolboxContentMediaSecureWiper.randomOverwrite(bytes, passes: 2);
  }

  String _friendlyMediaError(Object error) {
    if (error case ToolboxContentMediaException(:final message)) {
      final key = _contentMediaErrorKey(message);
      if (key != null) {
        return _lifeI18nText(context, key);
      }
      return message;
    }
    final message = switch (error) {
      ToolboxCryptoException(:final message) => message,
      _ => error.toString(),
    };
    return message.replaceFirst('Exception: ', '');
  }

  String? _contentMediaErrorKey(String message) {
    return switch (message) {
      'Encrypted payload is too large for image media.' =>
        'toolbox.crypto.content_media.error_image_payload_too_large',
      'Image media is invalid or unsupported.' =>
        'toolbox.crypto.content_media.error_image_invalid',
      'Image media dimensions are too large.' =>
        'toolbox.crypto.content_media.error_image_dimensions_too_large',
      'Encrypted envelope is empty.' =>
        'toolbox.crypto.content_media.error_envelope_empty',
      'Encrypted envelope is too large for media encoding.' =>
        'toolbox.crypto.content_media.error_envelope_too_large',
      'Media payload header is incomplete.' =>
        'toolbox.crypto.content_media.error_payload_header_incomplete',
      'No encrypted media payload found.' =>
        'toolbox.crypto.content_media.error_payload_not_found',
      'Unsupported encrypted media payload version.' =>
        'toolbox.crypto.content_media.error_payload_version',
      'Encrypted media payload length is invalid.' =>
        'toolbox.crypto.content_media.error_payload_length_invalid',
      'Encrypted media payload is incomplete.' =>
        'toolbox.crypto.content_media.error_payload_incomplete',
      'Encrypted media payload checksum failed.' =>
        'toolbox.crypto.content_media.error_payload_checksum_failed',
      'Audio media is not a supported WAV file.' =>
        'toolbox.crypto.content_media.error_wav_unsupported',
      'WAV media is damaged.' =>
        'toolbox.crypto.content_media.error_wav_damaged',
      'WAV fmt chunk is invalid.' =>
        'toolbox.crypto.content_media.error_wav_fmt_invalid',
      'Audio media must be PCM WAV.' =>
        'toolbox.crypto.content_media.error_wav_pcm_required',
      'Audio media must be mono PCM16 WAV.' =>
        'toolbox.crypto.content_media.error_wav_mono_pcm16_required',
      'WAV data chunk is missing.' =>
        'toolbox.crypto.content_media.error_wav_data_missing',
      'Encrypted media payload header is invalid.' =>
        'toolbox.crypto.content_media.error_payload_header_invalid',
      'Damage simulation requires naturalized PNG media.' =>
        'toolbox.crypto.content_media.error_damage_requires_naturalized',
      'Network image URL is empty.' =>
        'toolbox.crypto.content_media.error_network_url_empty',
      'Network image URL is invalid.' =>
        'toolbox.crypto.content_media.error_network_url_invalid',
      'Only HTTPS image URLs are supported.' =>
        'toolbox.crypto.content_media.error_network_https_required',
      'Network image host is local or private.' =>
        'toolbox.crypto.content_media.error_network_private_host',
      'Network image redirect is invalid.' =>
        'toolbox.crypto.content_media.error_network_redirect_invalid',
      'Network image has too many redirects.' =>
        'toolbox.crypto.content_media.error_network_too_many_redirects',
      'Network image download failed.' =>
        'toolbox.crypto.content_media.error_network_download_failed',
      'Network image response is not a PNG image.' =>
        'toolbox.crypto.content_media.error_network_not_png',
      'Network image is too large.' =>
        'toolbox.crypto.content_media.error_network_too_large',
      _ => null,
    };
  }

  String _decryptedOutputName(String mediaName) {
    final base = path.basenameWithoutExtension(mediaName).trim();
    return '${base.isEmpty ? 'content_media_decrypted' : base}_restored.bin';
  }

  String? _decodedTextOrNull(ToolboxContentMediaDecodeResult result) {
    if (!_looksLikeTextResult(result)) {
      return null;
    }
    try {
      return utf8.decode(result.plainBytes, allowMalformed: false);
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeTextResult(ToolboxContentMediaDecodeResult result) {
    final mediaType = result.mediaType?.toLowerCase().trim();
    if (mediaType != null && mediaType.startsWith('text/')) {
      return true;
    }
    final extension = path
        .extension(result.fileName ?? '')
        .toLowerCase()
        .replaceFirst('.', '');
    return const <String>{
      'txt',
      'md',
      'csv',
      'json',
      'xml',
      'yaml',
      'yml',
      'log',
    }.contains(extension);
  }

  String _extensionForFileName(String fileName) {
    final extension = path.extension(fileName).replaceFirst('.', '').trim();
    if (extension.isEmpty) {
      return 'bin';
    }
    return extension;
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(2)} s';
  }

  int get _minimumImageWidth {
    return switch (_imageMinimum) {
      _ContentMediaImageMinimum.auto =>
        ToolboxContentMediaCodecService.pngMinimumWidth,
      _ContentMediaImageMinimum.square512 => 512,
      _ContentMediaImageMinimum.square1024 => 1024,
    };
  }

  int get _minimumImageHeight {
    return switch (_imageMinimum) {
      _ContentMediaImageMinimum.auto => 1,
      _ContentMediaImageMinimum.square512 => 512,
      _ContentMediaImageMinimum.square1024 => 1024,
    };
  }

  int get _maxErrorCount {
    final parsed = int.tryParse(_maxErrorsController.text.trim()) ?? 0;
    return parsed.clamp(0, 99).toInt();
  }

  int get _maxDecryptCount {
    final parsed = int.tryParse(_maxDecryptsController.text.trim()) ?? 0;
    return parsed.clamp(0, 999).toInt();
  }

  ToolboxContentMediaAttemptPolicy get _attemptPolicy {
    return ToolboxContentMediaAttemptPolicy(
      maxDecrypts: _maxDecryptCount,
      maxErrors: _maxErrorCount,
      successfulDecrypts: _successfulDecrypts,
      failedAttempts: _failedAttempts,
    );
  }

  String _damagedPngName(String fileName) {
    final base = path.basenameWithoutExtension(fileName).trim();
    final safeBase = base.endsWith('_damaged')
        ? base
        : '${base.isEmpty ? 'encrypted_media' : base}_damaged';
    return '$safeBase.png';
  }
}
