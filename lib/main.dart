import 'package:flutter/material.dart';

import 'config/blockchain_config.dart';
import 'screens/home_screen.dart';
import 'services/blockchain_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await BlockchainConfig.muat();
    final service = await BlockchainService.buat();
    runApp(SertifikatApp(service: service));
  } catch (e) {
    runApp(KonfigurasiErrorApp(pesan: e.toString()));
  }
}

ThemeData _tema(Brightness brightness) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B5C6B),
        brightness: brightness,
      ),
    );

class SertifikatApp extends StatelessWidget {
  const SertifikatApp({super.key, required this.service});

  final BlockchainService service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sertifikat Kegiatan',
      debugShowCheckedModeBanner: false,
      theme: _tema(Brightness.light),
      darkTheme: _tema(Brightness.dark),
      home: HomeScreen(service: service),
    );
  }
}

/// Ditampilkan bila `.env` hilang atau ada variabel yang belum diisi.
class KonfigurasiErrorApp extends StatelessWidget {
  const KonfigurasiErrorApp({super.key, required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _tema(Brightness.light),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.settings_suggest_outlined, size: 40),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) => Text(
                    'Konfigurasi belum lengkap',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Text(pesan),
                const SizedBox(height: 16),
                const Text(
                  'Salin .env.example menjadi .env, isi semua nilainya, '
                  'lalu jalankan ulang aplikasi.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}