// Kompas Kiblat: bearing great-circle ke Ka'bah dari lokasi GPS.
// Di web / tanpa sensor: tampilkan sudut + panduan manual (graceful fallback).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme.dart';

const _kakbahLat = 21.4225;
const _kakbahLon = 39.8262;

double hitungBearingKiblat(double lat, double lon) {
  final phi1 = lat * math.pi / 180;
  final phi2 = _kakbahLat * math.pi / 180;
  final dLambda = (_kakbahLon - lon) * math.pi / 180;
  final y = math.sin(dLambda);
  final x = math.cos(phi1) * math.tan(phi2) - math.sin(phi1) * math.cos(dLambda);
  final bearing = math.atan2(y, x) * 180 / math.pi;
  return (bearing + 360) % 360;
}

class KiblatScreen extends StatefulWidget {
  const KiblatScreen({super.key});

  @override
  State<KiblatScreen> createState() => _KiblatScreenState();
}

class _KiblatScreenState extends State<KiblatScreen> {
  Position? _posisi;
  String? _error;
  bool _memuat = true;
  StreamSubscription<CompassEvent>? _compassSub;
  double? _arahHp; // derajat dari sensor kompas
  bool _kompasTersedia = true;

  @override
  void initState() {
    super.initState();
    _mulai();
  }

  Future<void> _mulai() async {
    try {
      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        setState(() {
          _error =
              'Izin lokasi ditolak. Aktifkan izin lokasi agar arah kiblat bisa dihitung.';
          _memuat = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      setState(() {
        _posisi = pos;
        _memuat = false;
      });
      _dengarKompas();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lokasi tidak bisa dibaca: $e';
        _memuat = false;
      });
    }
  }

  void _dengarKompas() {
    if (kIsWeb) {
      setState(() => _kompasTersedia = false);
      return;
    }
    try {
      _compassSub = FlutterCompass.events?.listen(
        (event) {
          if (mounted && event.heading != null) {
            setState(() => _arahHp = event.heading);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _kompasTersedia = false);
        },
      );
      // Jika stream null, sensor tidak ada
      if (FlutterCompass.events == null) {
        setState(() => _kompasTersedia = false);
      }
    } catch (_) {
      setState(() => _kompasTersedia = false);
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primer = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Kompas Kiblat')),
      body: _memuat
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Mencari lokasimu...'),
                ],
              ),
            )
          : _error != null
              ? _PesanError(
                  pesan: _error!,
                  onRetry: () {
                    setState(() {
                      _memuat = true;
                      _error = null;
                    });
                    _mulai();
                  },
                )
              : _tampilanKompas(primer),
    );
  }

  Widget _tampilanKompas(Color primer) {
    final bearing = hitungBearingKiblat(_posisi!.latitude, _posisi!.longitude);
    // Sudut putar jarum: selisih arah kiblat dengan arah HP (jika sensor ada)
    final double? putar = _arahHp == null ? null : (bearing - _arahHp!);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Muka kompas: lingkaran + tick derajat + huruf mata angin
                CustomPaint(
                  size: const Size(280, 280),
                  painter: _DialKompas(primer: primer),
                ),
                // Jarum kiblat
                Transform.rotate(
                  angle: ((putar ?? 0) * math.pi / 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation,
                          size: 76, color: QBColors.emas),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'KIBLAT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tutup poros jarum
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primer,
                    border: Border.all(color: QBColors.emas, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _BarisInfo('Arah kiblat', '${bearing.toStringAsFixed(1)}\u00B0 dari utara'),
                const Divider(),
                _BarisInfo('Lokasimu',
                    '${_posisi!.latitude.toStringAsFixed(4)}, ${_posisi!.longitude.toStringAsFixed(4)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_kompasTersedia && _arahHp != null)
          Text(
            'Putar HP sampai jarum emas menunjuk ke atas, itulah arah kiblat.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QBColors.tintaLembut,
                ),
          )
        else
          Card(
            color: QBColors.emasMuda,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sensor kompas tidak tersedia di perangkat ini. '
                'Gunakan sudut ${bearing.toStringAsFixed(0)}\u00B0 dari arah utara '
                '(pakai kompas biasa atau lihat arah matahari): '
                'utara = 0\u00B0, timur = 90\u00B0, selatan = 180\u00B0, barat = 270\u00B0.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }
}

/// Muka kompas bergaya instrumen: lingkaran ganda, tick tiap 15 derajat,
/// dan huruf mata angin. Alasan (R-31): tick derajat membantu membaca sudut
/// kiblat dengan presisi, bukan sekadar hiasan.
class _DialKompas extends CustomPainter {
  final Color primer;
  _DialKompas({required this.primer});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Muka + cincin ganda
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..color = QBColors.kertas
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..color = primer
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      c,
      r - 10,
      Paint()
        ..color = QBColors.emas.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Tick derajat
    const huruf = {'U': 0, 'T': 90, 'S': 180, 'B': 270};
    for (var d = 0; d < 360; d += 15) {
      final kardinal = d % 90 == 0;
      final rad = (d - 90) * math.pi / 180;
      final r1 = r - (kardinal ? 26 : 18);
      final r2 = r - 12;
      final p1 = c + Offset(math.cos(rad) * r1, math.sin(rad) * r1);
      final p2 = c + Offset(math.cos(rad) * r2, math.sin(rad) * r2);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = kardinal ? primer : primer.withValues(alpha: 0.45)
          ..strokeWidth = kardinal ? 3 : 1.5,
      );
    }

    // Huruf mata angin (U merah mengikuti konvensi kompas)
    for (final e in huruf.entries) {
      final rad = (e.value - 90) * math.pi / 180;
      final pos = c + Offset(math.cos(rad) * (r - 44), math.sin(rad) * (r - 44));
      final tp = TextPainter(
        text: TextSpan(
          text: e.key,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: e.key == 'U' ? const Color(0xFFB3261E) : primer,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DialKompas old) => old.primer != primer;
}

class _BarisInfo extends StatelessWidget {
  final String label;
  final String nilai;
  const _BarisInfo(this.label, this.nilai);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          nilai,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _PesanError extends StatelessWidget {
  final String pesan;
  final VoidCallback onRetry;
  const _PesanError({required this.pesan, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined, size: 56),
            const SizedBox(height: 12),
            Text(pesan, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
