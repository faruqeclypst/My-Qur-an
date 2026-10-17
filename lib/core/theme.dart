// Identitas visual Quranku: hangat seperti mushaf cetak, tenang, punya karakter.
// Zamrud tua + krem kertas + aksen emas. Lihat DESIGN.md untuk alasan tiap pilihan.
import 'package:flutter/material.dart';

import 'app_store.dart';

class QBColors {
  static const zamrud = Color(0xFF0E5E4A);
  static const zamrudTua = Color(0xFF0B4A3A);
  static const zamrudMuda = Color(0xFFE3F0EA);
  static const krem = Color(0xFFFAF6EE);
  static const kertas = Color(0xFFFFFEFA);
  static const tinta = Color(0xFF1F2937);
  static const tintaLembut = Color(0xFF5B6572);
  static const emas = Color(0xFFC9A227);
  static const emasMuda = Color(0xFFF7EED3);

  // Mode anak: tetap satu keluarga warna, dibuat lebih cerah dan ceria
  static const toskaCeria = Color(0xFF0FA3A3);
  static const madu = Color(0xFFF5B301);
  static const maduMuda = Color(0xFFFFF3D1);
}

class QBTheme {
  static ThemeData forMode(AppMode mode, double fontScale) {
    final bool anak = mode == AppMode.anak;
    final bool lansia = mode == AppMode.lansia;

    final primer = anak ? QBColors.toskaCeria : QBColors.zamrud;
    final primerTua = anak ? const Color(0xFF0B7C7C) : QBColors.zamrudTua;
    final latar = lansia ? Colors.white : QBColors.krem;
    final permukaan = lansia ? Colors.white : QBColors.kertas;

    final scheme = ColorScheme.fromSeed(
      seedColor: primer,
      primary: primer,
      surface: permukaan,
    );

    var theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: primer,
        onPrimary: Colors.white,
        secondary: anak ? QBColors.madu : QBColors.emas,
        surface: permukaan,
      ),
      scaffoldBackgroundColor: latar,
      appBarTheme: AppBarTheme(
        backgroundColor: primerTua,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: permukaan,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(anak ? 20 : 14),
          side: BorderSide(
            color: primer.withValues(alpha: 0.18),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primer,
          foregroundColor: Colors.white,
          minimumSize: Size(64, lansia ? 60 : 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(anak ? 18 : 12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, lansia ? 60 : 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(anak ? 18 : 12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primer,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primer,
        unselectedItemColor: QBColors.tintaLembut,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: DividerThemeData(
        color: primer.withValues(alpha: 0.14),
      ),
    );

    // Skala teks global mengikuti preferensi pengguna (mode lansia default 1.35x)
    return theme.copyWith(
      textTheme: theme.textTheme.apply(fontSizeFactor: fontScale),
    );
  }

  /// Gaya teks Arab: Amiri Quran dari aset lokal (dibundel di aplikasi,
  /// bukan diunduh saat runtime) agar tabel GPOS/GSUB untuk posisi harakat
  /// dan tanda waqaf selalu tersedia — termasuk saat offline atau CDN font
  /// tidak terjangkau browser. Selalu kanan-ke-kiri.
  ///
  /// Dipakai di: mode Per Ayat, mode Mushaf, hijaiyah, iqro.
  static TextStyle arab({
    double size = 28,
    Color color = QBColors.tinta,
    FontWeight weight = FontWeight.w500,
    double height = 2.0,
  }) {
    return TextStyle(
      fontFamily: 'AmiriQuran',
      fontFamilyFallback: const ['Amiri', 'serif'],
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
      // Aktifkan ligatur & kerning OpenType: harakat, tanwin, dan tanda
      // waqaf dirender menempel pas pada huruf induknya.
      fontFeatures: const [FontFeature('liga'), FontFeature('kern')],
    );
  }
}
