import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/web3dart.dart';

import '../config/blockchain_config.dart';
import '../models/sertifikat.dart';

/// Error yang pesannya sudah siap ditampilkan ke user.
class TransaksiException implements Exception {
  TransaksiException(this.pesan);
  final String pesan;

  @override
  String toString() => pesan;
}

/// Satu-satunya pintu komunikasi aplikasi dengan smart contract di Sepolia.
class BlockchainService {
  BlockchainService._(
    Web3Client client,
    DeployedContract contract,
    EthPrivateKey credentials,
  )   : _client = client,
        _contract = contract,
        _credentials = credentials,
        _fnJumlah = contract.function('jumlahSertifikat'),
        _fnAmbil = contract.function('ambilSertifikat'),
        _fnTerbitkan = contract.function('terbitkanSertifikat'),
        _fnCabut = contract.function('cabutSertifikat'),
        _fnVerifikasi = _cariFungsi(contract, 'verifikasiHash'),
        _evTerbit = contract.event('SertifikatDiterbitkan'),
        _evCabut = contract.event('SertifikatDicabut');

  final Web3Client _client;
  final DeployedContract _contract;
  final EthPrivateKey _credentials;

  final ContractFunction _fnJumlah;
  final ContractFunction _fnAmbil;
  final ContractFunction _fnTerbitkan;
  final ContractFunction _fnCabut;
  final ContractFunction? _fnVerifikasi; // null bila ABI tidak memuat verifikasiHash
  final ContractEvent _evTerbit;
  final ContractEvent _evCabut;

  static const int _ukuranBatch = 5;

  /// Membuat service: memuat ABI dari asset, menyiapkan client & credentials.
  /// Tidak melakukan request jaringan.
  static Future<BlockchainService> buat() async {
    final abiJson = await rootBundle.loadString('assets/abi/SertifikatKegiatan.json');
    final contract = DeployedContract(
      ContractAbi.fromJson(abiJson, 'SertifikatKegiatan'),
      EthereumAddress.fromHex(BlockchainConfig.contractAddress),
    );
    final client = Web3Client(BlockchainConfig.rpcUrl, http.Client());
    final credentials = EthPrivateKey.fromHex(BlockchainConfig.privateKey);
    return BlockchainService._(client, contract, credentials);
  }

  static ContractFunction? _cariFungsi(DeployedContract c, String nama) {
    for (final f in c.abi.functions) {
      if (f.name == nama) return f;
    }
    return null;
  }

  /// Alamat wallet penandatangan (diturunkan dari private key).
  EthereumAddress get alamatWallet => _credentials.address;

  void dispose() => _client.dispose();

  // ---------------------------------------------------------------------
  // BACA (gratis, tanpa transaksi)
  // ---------------------------------------------------------------------

  Future<int> jumlahSertifikat() async {
    final r = await _client.call(contract: _contract, function: _fnJumlah, params: []);
    return (r.first as BigInt).toInt();
  }

  Future<Sertifikat> ambilSertifikat(int id) async {
    final r = await _client.call(
      contract: _contract,
      function: _fnAmbil,
      params: [BigInt.from(id)],
    );
    return Sertifikat(
      id: id,
      hashBerkas: r[0] as String,
      namaKegiatan: r[1] as String,
      namaPenerbit: r[2] as String,
      waktuTerbit: DateTime.fromMillisecondsSinceEpoch((r[3] as BigInt).toInt() * 1000),
      alamatPenerbit: r[4] as EthereumAddress,
      valid: r[5] as bool,
    );
  }

  /// Seluruh sertifikat, terbaru di atas. Dibaca per batch agar tidak
  /// membebani rate limit RPC.
  Future<List<Sertifikat>> ambilSemua() async {
    final total = await jumlahSertifikat();
    final hasil = <Sertifikat>[];
    for (var awal = total; awal >= 1; awal -= _ukuranBatch) {
      final akhir = max(1, awal - _ukuranBatch + 1);
      hasil.addAll(await Future.wait([
        for (var id = awal; id >= akhir; id--) ambilSertifikat(id),
      ]));
    }
    return hasil;
  }

  /// Mengecek apakah hash file terdaftar.
  /// - Bila kontrak punya fungsi `verifikasiHash`, fungsi itu yang dipanggil.
  /// - Bila tidak (ABI tidak memuatnya), hash dicocokkan dengan membaca
  ///   sertifikat dari yang terbaru. Hasilnya sama, hanya lebih banyak request.
  Future<HasilVerifikasi> verifikasiHash(String hashBerkas) async {
    final hash = hashBerkas.trim();
    final fn = _fnVerifikasi;

    if (fn != null) {
      final r = await _client.call(contract: _contract, function: fn, params: [hash]);
      return HasilVerifikasi(
        ditemukan: r[0] as bool,
        id: (r[1] as BigInt).toInt(),
        masihValid: r[2] as bool,
      );
    }

    final total = await jumlahSertifikat();
    for (var awal = total; awal >= 1; awal -= _ukuranBatch) {
      final akhir = max(1, awal - _ukuranBatch + 1);
      final batch = await Future.wait([
        for (var id = awal; id >= akhir; id--) ambilSertifikat(id),
      ]);
      for (final s in batch) {
        if (s.hashBerkas.toLowerCase() == hash.toLowerCase()) {
          return HasilVerifikasi(ditemukan: true, id: s.id, masihValid: s.valid);
        }
      }
    }
    return const HasilVerifikasi(ditemukan: false, id: 0, masihValid: false);
  }

  // ---------------------------------------------------------------------
  // TULIS (butuh tanda tangan & gas). Mengembalikan Transaction Hash.
  // ---------------------------------------------------------------------

  Future<String> terbitkanSertifikat({
    required String hashBerkas,
    required String namaKegiatan,
    required String namaPenerbit,
  }) =>
      _kirim(_fnTerbitkan, [hashBerkas, namaKegiatan, namaPenerbit]);

  Future<String> cabutSertifikat(int id) => _kirim(_fnCabut, [BigInt.from(id)]);

  Future<String> _kirim(ContractFunction fn, List<dynamic> parameter) {
    return _client.sendTransaction(
      _credentials,
      Transaction.callContract(contract: _contract, function: fn, parameters: parameter),
      chainId: BlockchainConfig.chainId,
    );
  }

  /// Menunggu transaksi masuk blok. Melempar error bila di-revert atau timeout.
  Future<TransactionReceipt> tungguKonfirmasi(
    String txHash, {
    Duration batasWaktu = const Duration(minutes: 3),
  }) async {
    final batas = DateTime.now().add(batasWaktu);
    while (DateTime.now().isBefore(batas)) {
      final receipt = await _client.getTransactionReceipt(txHash);
      if (receipt != null) {
        if (receipt.status == false) {
          throw TransaksiException('Transaksi masuk blok tetapi ditolak oleh smart contract.');
        }
        return receipt;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    throw TransaksiException(
      'Transaksi belum terkonfirmasi dalam ${batasWaktu.inMinutes} menit. '
      'Cek statusnya di Etherscan dengan hash:\n$txHash',
    );
  }

  // ---------------------------------------------------------------------
  // [BONUS] Listener event agar daftar ter-update otomatis
  // ---------------------------------------------------------------------

  /// Stream yang memancarkan 'terbit' / 'cabut' setiap ada event baru.
  /// Bergantung pada dukungan `eth_newFilter` di RPC; bila tidak didukung,
  /// error stream diabaikan dan user tetap bisa refresh manual.
  Stream<String> pantauPerubahan() {
    final controller = StreamController<String>();
    final langganan = <StreamSubscription<FilterEvent>>[];

    controller.onListen = () {
      langganan.add(_client
          .events(FilterOptions.events(
            contract: _contract,
            event: _evTerbit,
            fromBlock: const BlockNum.current(),
          ))
          .listen((_) => controller.add('terbit'), onError: (_) {}));
      langganan.add(_client
          .events(FilterOptions.events(
            contract: _contract,
            event: _evCabut,
            fromBlock: const BlockNum.current(),
          ))
          .listen((_) => controller.add('cabut'), onError: (_) {}));
    };
    controller.onCancel = () async {
      for (final s in langganan) {
        await s.cancel();
      }
    };
    return controller.stream;
  }

  // ---------------------------------------------------------------------
  // Pesan error yang ramah untuk user
  // ---------------------------------------------------------------------

  static String pesanError(Object e) {
    if (e is TransaksiException) return e.pesan;
    if (e is SocketException) {
      return 'Tidak ada koneksi internet atau RPC tidak bisa dijangkau.';
    }
    if (e is TimeoutException) return 'Permintaan ke jaringan melebihi batas waktu. Coba lagi.';
    if (e is RPCError) {
      final alasan = _alasanRevert(e.data);
      if (alasan != null) return 'Ditolak smart contract: $alasan';
      final pesan = e.message.toLowerCase();
      if (pesan.contains('insufficient funds')) {
        return 'Saldo ETH Sepolia di wallet tidak cukup untuk membayar gas. Isi saldo lewat faucet.';
      }
      if (pesan.contains('execution reverted')) {
        return 'Ditolak smart contract: ${e.message.replaceFirst('execution reverted:', '').trim()}';
      }
      return 'Error RPC (${e.errorCode}): ${e.message}';
    }
    if (e is StateError) return e.message;
    return e.toString();
  }

  /// Membaca alasan revert `Error(string)` dari data RPC.
  static String? _alasanRevert(dynamic data) {
    if (data is! String || !data.startsWith('0x08c379a0')) return null;
    try {
      final bytes = hexToBytes(data);
      final panjang = bytesToUnsignedInt(bytes.sublist(36, 68)).toInt();
      return utf8.decode(bytes.sublist(68, 68 + panjang));
    } catch (_) {
      return null;
    }
  }
}
