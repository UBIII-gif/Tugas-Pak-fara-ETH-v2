import 'package:flutter/material.dart';

import '../models/sertifikat.dart';
import '../utils/format.dart';
import '../utils/salin.dart';
import 'status_badge.dart';

/// Kartu satu sertifikat di halaman daftar.
class SertifikatCard extends StatelessWidget {
  const SertifikatCard({
    super.key,
    required this.sertifikat,
    required this.milikSaya,
    required this.onCabut,
  });

  final Sertifikat sertifikat;
  final bool milikSaya;
  final VoidCallback onCabut;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final s = sertifikat;
    final dicabut = !s.valid;

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => tampilkanDetailSertifikat(
          context,
          s,
          milikSaya: milikSaya,
          onCabut: onCabut,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      s.namaKegiatan,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: dicabut ? TextDecoration.lineThrough : null,
                        color: dicabut ? tema.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(valid: s.valid),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                s.namaPenerbit,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _Info(
                ikon: Icons.fingerprint,
                teks: potongHash(s.hashBerkas),
                mono: true,
              ),
              const SizedBox(height: 6),
              _Info(ikon: Icons.schedule, teks: formatWaktu(s.waktuTerbit)),
              const SizedBox(height: 6),
              _Info(ikon: Icons.tag, teks: 'Sertifikat #${s.id}'),
              if (milikSaya) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        size: 16, color: tema.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Diterbitkan wallet Anda',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: tema.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (s.valid)
                      TextButton.icon(
                        onPressed: onCabut,
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Cabut'),
                        style: TextButton.styleFrom(
                          foregroundColor: tema.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.ikon, required this.teks, this.mono = false});

  final IconData ikon;
  final String teks;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final warna = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(ikon, size: 16, color: warna),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teks,
            style: TextStyle(
              fontSize: 13,
              color: warna,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet detail lengkap satu sertifikat.
Future<void> tampilkanDetailSertifikat(
  BuildContext context,
  Sertifikat s, {
  required bool milikSaya,
  required VoidCallback onCabut,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sertifikat #${s.id}',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
                StatusBadge(valid: s.valid),
              ],
            ),
            const SizedBox(height: 16),
            _Baris(label: 'Nama kegiatan', nilai: s.namaKegiatan),
            _Baris(label: 'Penerbit', nilai: s.namaPenerbit),
            _Baris(label: 'Waktu terbit', nilai: formatWaktu(s.waktuTerbit)),
            _Baris(
              label: 'Alamat wallet penerbit',
              nilai: s.alamatPenerbit.hexEip55,
              mono: true,
              bisaSalin: true,
            ),
            _Baris(
              label: 'Hash SHA-256 berkas',
              nilai: s.hashBerkas,
              mono: true,
              bisaSalin: true,
            ),
            if (milikSaya && s.valid) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onCabut();
                  },
                  icon: const Icon(Icons.block),
                  label: const Text('Cabut sertifikat'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Theme.of(ctx).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Baris extends StatelessWidget {
  const _Baris({
    required this.label,
    required this.nilai,
    this.mono = false,
    this.bisaSalin = false,
  });

  final String label;
  final String nilai;
  final bool mono;
  final bool bisaSalin;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  nilai,
                  style: TextStyle(
                    fontSize: mono ? 13 : 15,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
          if (bisaSalin)
            IconButton(
              tooltip: 'Salin',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => salinKeClipboard(context, nilai, label: label),
            ),
        ],
      ),
    );
  }
}
