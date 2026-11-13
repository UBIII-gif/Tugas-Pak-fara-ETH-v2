import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> salinKeClipboard(
  BuildContext context,
  String teks, {
  String label = 'Teks',
}) async {
  await Clipboard.setData(ClipboardData(text: teks));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$label disalin')));
}
