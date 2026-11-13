import 'package:web3dart/web3dart.dart';

/// Satu sertifikat yang dibaca dari smart contract.
class Sertifikat {
  const Sertifikat({
    required this.id,
    required this.hashBerkas,
    required this.namaKegiatan,
    required this.namaPenerbit,
    required this.waktuTerbit,
    required this.alamatPenerbit,
    required this.valid,
  });

  final int id;
  final String hashBerkas;
  final String namaKegiatan;
  final String namaPenerbit;
  final DateTime waktuTerbit;
  final EthereumAddress alamatPenerbit;
  final bool valid;

  bool diterbitkanOleh(EthereumAddress wallet) =>
      alamatPenerbit.hex.toLowerCase() == wallet.hex.toLowerCase();
}

/// Hasil pencocokan hash file dengan data on-chain.
class HasilVerifikasi {
  const HasilVerifikasi({
    required this.ditemukan,
    required this.id,
    required this.masihValid,
  });

  final bool ditemukan;
  final int id; // 0 bila tidak ditemukan
  final bool masihValid;
}
