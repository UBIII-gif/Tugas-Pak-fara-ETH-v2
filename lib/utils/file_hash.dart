import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';

/// File yang dipilih user beserta SHA-256 hash-nya (hex huruf kecil, 64 karakter).
class HasilFile {
  const HasilFile({required this.nama, required this.ukuran, required this.hash});

  final String nama;
  final int ukuran;
  final String hash;
}

/// Membuka pemilih file (PDF/JPG/PNG), lalu menghitung SHA-256 secara lokal.
/// Kompatibel untuk Web (Chrome) maupun Android/Desktop.
/// Mengembalikan null jika user membatalkan pemilihan.
Future<HasilFile?> pilihDanHashFile() async {
  final hasil = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    withData: true, // Wajib true agar bytes file terbaca di Chrome/Web & Android
  );
  if (hasil == null || hasil.files.isEmpty) return null;

  final berkas = hasil.files.single;
  final bytes = berkas.bytes;
  if (bytes == null) {
    throw StateError('Data file tidak dapat dibaca. Coba pilih file lain.');
  }

  final digest = sha256.convert(bytes);
  return HasilFile(
    nama: berkas.name,
    ukuran: berkas.size,
    hash: digest.toString(),
  );
}