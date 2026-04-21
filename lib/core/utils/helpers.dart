import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: errorRed),
  );
}

void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: successGreen),
  );
}

String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (_) {
    return dateStr;
  }
}

String formatHour(double h) {
  final hour = h.floor() % 24;
  final minutes = ((h - h.floor()) * 60).round();
  return '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

/// Returns emoji for known sports; empty string for unknown.
String sportEmoji(String? sport) {
  switch (sport?.toLowerCase()) {
    case 'foot':
    case 'football':
      return '\u26BD'; // ⚽
    case 'padel':
    case 'tennis':
      return '\u{1F3BE}'; // 🎾
    case 'basket':
    case 'basketball':
      return '\u{1F3C0}'; // 🏀
    default:
      return '';
  }
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = 'Confirmer',
  Color confirmColor = errorRed,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final c = WColors.of(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(ctx).size.width * 0.025,
        ),
        child: AlertDialog(
        backgroundColor: c.secondaryBackground,
        title: Text(title, style: TextStyle(color: c.primaryText, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(body, style: TextStyle(color: c.secondaryText)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(confirmLabel),
        ),
      ],
        ),
      );
    },
  );
  return result ?? false;
}
