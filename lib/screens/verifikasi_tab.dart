import 'package:flutter/material.dart';

import '../models/sertifikat.dart';
import '../services/blockchain_service.dart';
import '../utils/file_hash.dart';
import '../utils/format.dart';
import '../utils/salin.dart';
import '../widgets/status_badge.dart';

class VerifikasiTab extends StatefulWidget {
  const VerifikasiTab({super.key, required this.service});

  final BlockchainService service;

  @override
  State<VerifikasiTab> createState() => _VerifikasiTabState();
}

class _VerifikasiTabState extends State<VerifikasiTab> {
  HasilFile? _file;
  HasilVerifikasi? _hasil;
  Sertifikat? _detail;
  bool _memproses = false;
  String? _error;

  Future<void> _pilihDanVerifikasi() async {
    setState(() => _error = null);
    try {
      final file = await pilihDanHashFile();
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _memproses = true;
        _file = file;
        _hasil = null;
        _detail = null;
      });

      final hasil = await widget.service.verifikasiHash(file.hash);
      Sertifikat? detail;
      if (hasil.ditemukan) detail = await widget.service.ambilSertifikat(hasil.id);

      if (!mounted) return;
      setState(() {
        _hasil = hasil;
        _detail = detail;
      });
    } catch (e) {
      if (mounted) setState(() => _error = BlockchainService.pesanError(e));
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final file = _file;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Pilih file sertifikat yang ingin dicek. Aplikasi menghitung hash-nya '
          'di perangkat, lalu mencocokkannya dengan data di blockchain.',
          style: tema.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _memproses ? null : _pilihDanVerifikasi,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Pilih file untuk diverifikasi'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 20),
        if (_memproses)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Mencocokkan dengan blockchain…'),
                ],
              ),
            ),
          ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tema.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: tema.colorScheme.onErrorContainer),
            ),
          ),
        if (_hasil != null && file != null) _kartuHasil(context, _hasil!, file),
      ],
    );
  }

  Widget _kartuHasil(BuildContext context, HasilVerifikasi h, HasilFile file) {
    final tema = Theme.of(context);

    final bool baik = h.ditemukan && h.masihValid;
    final IconData ikon;
    final String judul;
    final String isi;
    if (!h.ditemukan) {
      ikon = Icons.gpp_bad_outlined;
      judul = 'Tidak ditemukan di blockchain';
      isi = 'File ini belum pernah diterbitkan, atau isinya sudah berubah '
          'dari file aslinya.';
    } else if (h.masihValid) {
      ikon = Icons.verified;
      judul = 'Sertifikat asli dan valid';
      isi = 'Hash file cocok dengan sertifikat #${h.id} yang tercatat di blockchain.';
    } else {
      ikon = Icons.report_gmailerrorred_outlined;
      judul = 'Terdaftar, tetapi sudah dicabut';
      isi = 'File ini cocok dengan sertifikat #${h.id}, namun penerbit '
          'telah mencabutnya.';
    }

    final p = paletStatus(context, baik: baik);
    final detail = _detail;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.latar,
        border: Border.all(color: p.garis),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, color: p.teks, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  judul,
                  style: tema.textTheme.titleMedium?.copyWith(
                    color: p.teks,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(isi),
          if (detail != null) ...[
            const Divider(height: 28),
            Text(detail.namaKegiatan, style: tema.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text('${detail.namaPenerbit} • ${formatWaktu(detail.waktuTerbit)}'),
          ],
          const Divider(height: 28),
          Text(
            '${file.nama} (${formatUkuran(file.ukuran)})',
            style: tema.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  file.hash,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: 'Salin hash',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => salinKeClipboard(context, file.hash, label: 'Hash'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}