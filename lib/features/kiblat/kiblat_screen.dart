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
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QBColors.kertas,
                    border: Border.all(color: primer.withValues(alpha: 0.3), width: 3),
                  ),
                ),
                // Tanda mata angin
                for (final m in ['U', 'T', 'S', 'B'])
                  Align(
                    alignment: _alignMataAngin(m),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        m,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: m == 'U' ? Colors.red.shade700 : primer,
                        ),
                      ),
                    ),
                  ),
                // Jarum kiblat
                Transform.rotate(
                  angle: ((putar ?? 0) * math.pi / 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation,
                          size: 72, color: QBColors.emas),
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

  Alignment _alignMataAngin(String m) {
    switch (m) {
      case 'U':
        return Alignment.topCenter;
      case 'S':
        return Alignment.bottomCenter;
      case 'T':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
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
