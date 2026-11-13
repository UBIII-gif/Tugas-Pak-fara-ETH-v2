import 'package:flutter/material.dart';

import '../services/blockchain_service.dart';
import '../utils/file_hash.dart';
import '../utils/format.dart';
import '../utils/salin.dart';
import '../widgets/tx_dialog.dart';

class TerbitkanTab extends StatefulWidget {
  const TerbitkanTab({super.key, required this.service, required this.onBerhasil});

  final BlockchainService service;
  final VoidCallback onBerhasil;

  @override
  State<TerbitkanTab> createState() => _TerbitkanTabState();
}

class _TerbitkanTabState extends State<TerbitkanTab> {
  final _formKey = GlobalKey<FormState>();
  final _namaKegiatan = TextEditingController();
  final _namaPenerbit = TextEditingController();

  HasilFile? _file;
  bool _memprosesFile = false;
  String? _errorFile;

  @override
  void dispose() {
    _namaKegiatan.dispose();
    _namaPenerbit.dispose();
    super.dispose();
  }

  Future<void> _pilihFile() async {
    setState(() {
      _memprosesFile = true;
      _errorFile = null;
    });
    try {
      final hasil = await pilihDanHashFile();
      if (!mounted) return;
      if (hasil != null) setState(() => _file = hasil);
    } catch (e) {
      if (mounted) setState(() => _errorFile = 'Gagal membaca file: $e');
    } finally {
      if (mounted) setState(() => _memprosesFile = false);
    }
  }

  Future<void> _terbitkan() async {
    if (!_formKey.currentState!.validate()) return;
    final file = _file;
    if (file == null) {
      setState(() => _errorFile = 'Pilih file sertifikat terlebih dahulu.');
      return;
    }
    FocusScope.of(context).unfocus();

    final kegiatan = _namaKegiatan.text.trim();
    final penerbit = _namaPenerbit.text.trim();

    final sukses = await jalankanTransaksi(
      context,
      service: widget.service,
      judul: 'Menerbitkan sertifikat',
      kirim: () async {
        // Cek duplikat dulu agar user tidak membuang gas untuk transaksi yang pasti ditolak.
        final cek = await widget.service.verifikasiHash(file.hash);
        if (cek.ditemukan) {
          throw TransaksiException(
            'File ini sudah terdaftar sebagai sertifikat #${cek.id}. '
            'Satu file hanya bisa diterbitkan satu kali.',
          );
        }
        return widget.service.terbitkanSertifikat(
          hashBerkas: file.hash,
          namaKegiatan: kegiatan,
          namaPenerbit: penerbit,
        );
      },
    );

    if (sukses && mounted) {
      _formKey.currentState?.reset();
      _namaKegiatan.clear();
      _namaPenerbit.clear();
      setState(() {
        _file = null;
        _errorFile = null;
      });
      widget.onBerhasil();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final file = _file;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tema.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, color: tema.colorScheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hanya hash SHA-256 file yang dikirim ke blockchain. '
                    'File dan data pribadi tetap ada di perangkat Anda.',
                    style: TextStyle(color: tema.colorScheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _namaKegiatan,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama kegiatan',
              hintText: 'Seminar Nasional Teknologi 2026',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama kegiatan wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _namaPenerbit,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama penerbit',
              hintText: 'Himpunan Mahasiswa Informatika',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama penerbit wajib diisi' : null,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _memprosesFile ? null : _pilihFile,
            icon: _memprosesFile
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            label: Text(
              _memprosesFile
                  ? 'Menghitung hash…'
                  : 'Pilih file sertifikat (PDF/JPG/PNG)',
            ),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          if (_errorFile != null) ...[
            const SizedBox(height: 8),
            Text(_errorFile!, style: TextStyle(color: tema.colorScheme.error)),
          ],
          if (file != null) ...[
            const SizedBox(height: 12),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${file.nama} (${formatUkuran(file.ukuran)})',
                            style: tema.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SHA-256',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
                          onPressed: () =>
                              salinKeClipboard(context, file.hash, label: 'Hash'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (file == null || _memprosesFile) ? null : _terbitkan,
            icon: const Icon(Icons.send),
            label: const Text('Terbitkan sertifikat'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 8),
          Text(
            'Biaya gas dibayar dari wallet ${potongAlamat(widget.service.alamatWallet.hexEip55)}.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}