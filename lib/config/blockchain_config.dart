import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Satu-satunya tempat yang membaca konfigurasi blockchain dari file `.env`.
/// UI tidak boleh membaca `.env` atau private key secara langsung.
class BlockchainConfig {
  BlockchainConfig._();

  /// Dipanggil sekali di `main()` sebelum runApp.
  static Future<void> muat() => dotenv.load(fileName: '.env');

  static String get rpcUrl => _wajib('RPC_URL');
  static String get contractAddress => _wajib('CONTRACT_ADDRESS');

  /// Default 11155111 (Sepolia) bila CHAIN_ID tidak diisi.
  static int get chainId =>
      int.tryParse(dotenv.env['CHAIN_ID']?.trim() ?? '') ?? 11155111;

  /// Hanya boleh dipakai oleh BlockchainService untuk membuat Credentials.
  static String get privateKey => _wajib('PRIVATE_KEY');

  static const String _etherscan = 'https://sepolia.etherscan.io';
  static String urlTransaksi(String txHash) => '$_etherscan/tx/$txHash';

  static String _wajib(String kunci) {
    final nilai = dotenv.env[kunci]?.trim();
    if (nilai == null || nilai.isEmpty) {
      throw StateError('Variabel $kunci belum diisi di file .env');
    }
    return nilai;
  }
}
