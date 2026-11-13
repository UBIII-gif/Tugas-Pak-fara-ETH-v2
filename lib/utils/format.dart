/// Memotong teks panjang: "a1b2c3d4…e5f6a7b8".
String potongHash(String teks, {int awal = 8, int akhir = 8}) {
  if (teks.length <= awal + akhir + 1) return teks;
  return '${teks.substring(0, awal)}…${teks.substring(teks.length - akhir)}';
}

String potongAlamat(String alamat) => potongHash(alamat, awal: 6, akhir: 4);

String formatWaktu(DateTime waktu) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final t = waktu.toLocal();
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${t.day} ${bulan[t.month - 1]} ${t.year}, ${dua(t.hour)}.${dua(t.minute)}';
}

String formatUkuran(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
