import 'package:flutter/material.dart';

Future<String?> showTextPromptDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  String initialValue = '',
  String? hintText,
  String? confirmText,
}) async {
  final controller = TextEditingController(text: initialValue);
  var closed = false;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      void close([String? value]) {
        if (closed) return;
        closed = true;
        Navigator.of(dialogContext).pop(value);
      }

      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if ((subtitle ?? '').trim().isNotEmpty) ...[
              Text(subtitle!),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: hintText),
              onSubmitted: (_) => close(controller.text.trim()),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => close(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => close(controller.text.trim()),
            child: Text(
              confirmText ??
                  MaterialLocalizations.of(dialogContext).okButtonLabel,
            ),
          ),
        ],
      );
    },
  );
}

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  bool danger = false,
}) async {
  var resolved = false;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      void close(bool value) {
        if (resolved) return;
        resolved = true;
        Navigator.of(dialogContext).pop(value);
      }

      final actionButton = danger
          ? FilledButton.tonal(
              onPressed: () => close(true),
              child: Text(
                confirmText ??
                    MaterialLocalizations.of(dialogContext).okButtonLabel,
              ),
            )
          : FilledButton(
              onPressed: () => close(true),
              child: Text(
                confirmText ??
                    MaterialLocalizations.of(dialogContext).okButtonLabel,
              ),
            );
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => close(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          actionButton,
        ],
      );
    },
  );
  return result ?? false;
}
