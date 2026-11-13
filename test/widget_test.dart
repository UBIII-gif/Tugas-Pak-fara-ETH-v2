import 'package:flutter_test/flutter_test.dart';
import 'package:sertifikat_dapp/main.dart';

void main() {
  testWidgets('Render halaman error konfigurasi saat .env belum dimuat',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const KonfigurasiErrorApp(pesan: 'Contoh pesan error konfigurasi'),
    );

    expect(find.text('Konfigurasi belum lengkap'), findsOneWidget);
  });
}