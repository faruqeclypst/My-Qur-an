// Dekorasi khas Quranku: motif geometris Islami (bintang delapan) dan
// ornamen mushaf, digambar dengan CustomPainter agar ringan tanpa aset gambar.
//
// Alasan tiap elemen (R-31):
// - PolaBintang: motif identitas "geometri masjid", dipakai SAMAR sebagai latar
//   kepala halaman saja (R-07: pola hanya bila mendukung identitas produk).
// - PembatasOrnamen: pemisah visual antar-bagian bacaan, menggantikan Divider
//   polos di area sakral (kepala surah) agar terasa seperti mushaf cetak.
// - BingkaiMushaf: bingkai ganda (garis zamrud + garis emas tipis) untuk mode
//   Mushaf; alasan: memisahkan teks suci dari UI di sekitarnya secara hormat.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Pola bintang delapan (dua bujur sangkar bertumpuk, diputar 45 derajat)
/// yang berulang seperti kisi. Digambar sebagai garis tipis samar.
class PolaBintang extends CustomPainter {
  final Color warna;
  final double jarak;

  PolaBintang({required this.warna, this.jarak = 64});

  @override
  void paint(Canvas canvas, Size size) {
    final cat = Paint()
      ..color = warna
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void bintang(double cx, double cy, double r) {
      for (var putar = 0; putar < 2; putar++) {
        final path = Path();
        final offset = putar * math.pi / 4;
        for (var i = 0; i < 4; i++) {
          final a = offset + i * math.pi / 2;
          final x = cx + r * math.cos(a);
          final y = cy + r * math.sin(a);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, cat);
      }
    }

    for (var y = jarak / 2; y < size.height + jarak; y += jarak) {
      for (var x = jarak / 2; x < size.width + jarak; x += jarak) {
        bintang(x, y, jarak * 0.26);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PolaBintang old) =>
      old.warna != warna || old.jarak != jarak;
}

/// Latar berpola untuk kepala halaman: warna primer + pola bintang samar.
class LatarPola extends StatelessWidget {
  final Widget child;
  final Color warnaDasar;
  final Color warnaPola;
  final double jarak;

  const LatarPola({
    super.key,
    required this.child,
    required this.warnaDasar,
    required this.warnaPola,
    this.jarak = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: warnaDasar,
      child: CustomPaint(
        painter: PolaBintang(warna: warnaPola, jarak: jarak),
        child: child,
      ),
    );
  }
}

/// Kepala halaman beranda: sapaan + tanggal di atas latar berpola.
/// Alasan: satu titik fokus yang hangat di tiap beranda mode (Part 3: satu
/// focal point per layar), sekaligus membawa motif identitas.
class KepalaBeranda extends StatelessWidget {
  final String sapaan;
  final String nama;
  final String tanggal;

  const KepalaBeranda({
    super.key,
    required this.sapaan,
    required this.nama,
    required this.tanggal,
  });

  @override
  Widget build(BuildContext context) {
    final primerTua = Theme.of(context).colorScheme.primary;
    return LatarPola(
      warnaDasar: primerTua,
      warnaPola: Colors.white.withValues(alpha: 0.07),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Emblem mihrab kecil sebagai penanda identitas
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(23),
                        topRight: Radius.circular(23),
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: QBColors.emas.withValues(alpha: 0.8),
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'ٱلْقُرْآن',
                      style: QBTheme.arab(
                        size: 13,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quranku',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                        ),
                        Text(
                          tanggal,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Colors.white.withValues(alpha: 0.75),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$sapaan${nama.isEmpty ? '' : ', $nama'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pembatas ornamen: garis - belah ketupat - garis.
/// Dipakai di kepala surah / halaman mushaf sebagai ganti Divider polos.
class PembatasOrnamen extends StatelessWidget {
  final Color warna;
  final double tebal;

  const PembatasOrnamen({
    super.key,
    required this.warna,
    this.tebal = 1.2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: warna, thickness: tebal)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: QBColors.emas,
                border: Border.all(color: warna, width: 1.2),
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: warna, thickness: tebal)),
      ],
    );
  }
}

/// Bingkai ganda untuk teks mushaf: garis luar zamrud + garis dalam emas tipis.
/// Alasan: memberi "ruang hormat" di sekeliling teks suci, seperti bingkai
/// halaman mushaf cetak; juga memisahkan hierarki bacaan dari kontrol UI.
class BingkaiMushaf extends StatelessWidget {
  final Widget child;
  final Color warnaGaris;

  const BingkaiMushaf({
    super.key,
    required this.child,
    required this.warnaGaris,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: warnaGaris, width: 2),
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: QBColors.emas.withValues(alpha: 0.65),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: child,
      ),
    );
  }
}

/// Medali nomor berbentuk segi delapan (octagon) untuk daftar surah.
/// Alasan: bentuk geometris khas ornamen Islam; menggantikan kotak polos
/// sebagai penanda identitas tanpa menambah warna baru (R-29).
class MedaliNomor extends StatelessWidget {
  final int nomor;
  final double ukuran;

  const MedaliNomor({super.key, required this.nomor, this.ukuran = 48});

  @override
  Widget build(BuildContext context) {
    final primer = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: ukuran,
      height: ukuran,
      child: CustomPaint(
        painter: _SegiDelapan(
          warnaGaris: primer,
          warnaIsi: primer.withValues(alpha: 0.08),
        ),
        child: Center(
          child: Text(
            '$nomor',
            style: TextStyle(
              color: primer,
              fontWeight: FontWeight.bold,
              fontSize: ukuran * 0.32,
            ),
          ),
        ),
      ),
    );
  }
}

class _SegiDelapan extends CustomPainter {
  final Color warnaGaris;
  final Color warnaIsi;

  _SegiDelapan({required this.warnaGaris, required this.warnaIsi});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path();
    // Segi delapan beraturan: titik tiap 45 derajat, offset 22.5 derajat
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4 + math.pi / 8;
      final x = r + (r - 2) * math.cos(a);
      final y = r + (r - 2) * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = warnaIsi
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = warnaGaris
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _SegiDelapan old) => false;
}
