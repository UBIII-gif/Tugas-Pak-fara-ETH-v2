import 'package:flutter/material.dart';

import '../config/blockchain_config.dart';
import '../services/blockchain_service.dart';
import '../utils/salin.dart';

/// Menjalankan satu transaksi dengan UI lengkap:
/// loading -> menunggu konfirmasi blok -> dialog sukses (hash bisa disalin)
/// atau dialog gagal dengan pesan yang jelas.
/// Mengembalikan true bila transaksi sukses terkonfirmasi.
Future<bool> jalankanTransaksi(
  BuildContext context, {
  required BlockchainService service,
  required String judul,
  required Future<String> Function() kirim,
}) async {
  final status = ValueNotifier<String>('Menyiapkan transaksi…');

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(judul),
        content: ValueListenableBuilder<String>(
          valueListenable: status,
          builder: (_, pesan, __) => Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(pesan)),
            ],
          ),
        ),
      ),
    ),
  );

  String? txHash;
  try {
    txHash = await kirim();
    status.value = 'Transaksi terkirim. Menunggu konfirmasi blok…';
    await service.tungguKonfirmasi(txHash);
    if (!context.mounted) return true;
    Navigator.of(context, rootNavigator: true).pop();
    await _dialogSukses(context, judul, txHash);
    return true;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      await _dialogGagal(context, BlockchainService.pesanError(e), txHash);
    }
    return false;
  }
}

Future<void> _dialogSukses(BuildContext context, String judul, String txHash) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.check_circle, color: Color(0xFF1E8E4E), size: 36),
      title: const Text('Transaksi berhasil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$judul selesai dan sudah tercatat di blockchain.'),
          const SizedBox(height: 16),
          Text('Transaction Hash', style: Theme.of(ctx).textTheme.labelLarge),
          const SizedBox(height: 6),
          _KotakHash(txHash),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => salinKeClipboard(
            ctx,
            BlockchainConfig.urlTransaksi(txHash),
            label: 'Link Etherscan',
          ),
          child: const Text('Salin link Etherscan'),
        ),
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
      ],
    ),
  );
}

Future<void> _dialogGagal(BuildContext context, String pesan, String? txHash) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.error_outline, color: Theme.of(ctx).colorScheme.error, size: 36),
      title: const Text('Transaksi gagal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pesan),
            if (txHash != null) ...[
              const SizedBox(height: 16),
              Text('Transaction Hash', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 6),
              _KotakHash(txHash),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
      ],
    ),
  );
}

class _KotakHash extends StatelessWidget {
  const _KotakHash(this.hash);

  final String hash;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: skema.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              hash,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Salin hash',
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => salinKeClipboard(context, hash, label: 'Transaction hash'),
          ),
        ],
      ),
    );
  }
}
