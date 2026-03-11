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
  return showDialog<String>(
    context: context,
    builder: (context) {
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
              onSubmitted: (_) =>
                  Navigator.of(context).pop(controller.text.trim()),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(
              confirmText ?? MaterialLocalizations.of(context).okButtonLabel,
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
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final actionButton = danger
          ? FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText ?? MaterialLocalizations.of(context).okButtonLabel,
              ),
            )
          : FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText ?? MaterialLocalizations.of(context).okButtonLabel,
              ),
            );
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          actionButton,
        ],
      );
    },
  );
  return result ?? false;
}
