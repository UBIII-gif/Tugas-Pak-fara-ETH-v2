import 'package:flutter/material.dart';

/// Palet warna status yang kontrasnya aman di mode terang maupun gelap.
({Color teks, Color latar, Color garis}) paletStatus(
  BuildContext context, {
  required bool baik,
}) {
  final gelap = Theme.of(context).brightness == Brightness.dark;
  final dasar = baik ? const Color(0xFF1E8E4E) : const Color(0xFFD32F2F);
  final teks = baik
      ? (gelap ? const Color(0xFF7DDBA3) : const Color(0xFF14683A))
      : (gelap ? const Color(0xFFFF9C94) : const Color(0xFFA61B1B));
  return (teks: teks, latar: dasar.withAlpha(36), garis: dasar.withAlpha(110));
}

/// Badge VALID (hijau) atau DICABUT (merah).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.valid});

  final bool valid;

  @override
  Widget build(BuildContext context) {
    final p = paletStatus(context, baik: valid);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: p.latar,
        border: Border.all(color: p.garis),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(valid ? Icons.check_circle : Icons.cancel, size: 14, color: p.teks),
          const SizedBox(width: 4),
          Text(
            valid ? 'VALID' : 'DICABUT',
            style: TextStyle(
              color: p.teks,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
