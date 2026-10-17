// Challenge harian: kuis untuk mode Normal dan mode Anak.
// Skor + streak + badge tersimpan lokal.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/theme.dart';

class Soal {
  final String tipe;
  final String pertanyaan;
  final List<String> pilihan;
  final int jawaban;
  final String penjelasan;
  Soal({
    required this.tipe,
    required this.pertanyaan,
    required this.pilihan,
    required this.jawaban,
    required this.penjelasan,
  });
}

Future<List<Soal>> muatSoal(AppMode mode) async {
  final raw = await rootBundle.loadString('assets/data/challenge.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final key = mode == AppMode.anak ? 'anak' : 'normal';
  final list = (data[key] as List)
      .map((s) => Soal(
            tipe: s['tipe'] as String,
            pertanyaan: s['pertanyaan'] as String,
            pilihan: [for (final p in (s['pilihan'] as List)) p as String],
            jawaban: (s['jawaban'] as num).toInt(),
            penjelasan: (s['penjelasan'] as String?) ?? '',
          ))
      .toList();
  list.shuffle(Random());
  return list.take(10).toList(); // 10 soal per sesi
}

const _namaBadge = {
  'konsisten_3': 'Konsisten 3 Hari',
  'seminggu_penuh': 'Seminggu Penuh',
  'sebulan_rajin': 'Sebulan Rajin',
  'skor_100': 'Skor 100',
  'skor_500': 'Skor 500',
};

class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final anak = store.mode == AppMode.anak;

    return Scaffold(
      appBar: AppBar(
          title: Text(anak ? 'Kuis Seru' : 'Challenge Harian')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 52, color: QBColors.emas),
                  const SizedBox(height: 8),
                  Text(
                    anak ? 'Ayo main kuis!' : 'Challenge hari ini',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '10 soal. Setiap jawaban benar = 10 poin.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: QBColors.tintaLembut,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat('Streak', '${store.challengeStreak} hari'),
                      _Stat('Total skor', '${store.challengeScore}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _QuizScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(anak ? 'Mulai Main' : 'Mulai Challenge'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Badge',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (store.badges.isEmpty)
            Text(
              anak
                  ? 'Belum ada badge. Mainkan kuis untuk mendapatkan badge!'
                  : 'Belum ada badge. Selesaikan challenge untuk membukanya.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: QBColors.tintaLembut,
                  ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in store.badges)
                  Chip(
                    avatar: const Icon(Icons.military_tech_outlined,
                        size: 18, color: QBColors.emas),
                    label: Text(_namaBadge[b] ?? b),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String nilai;
  const _Stat(this.label, this.nilai);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          nilai,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QBColors.tintaLembut,
              ),
        ),
      ],
    );
  }
}

class _QuizScreen extends StatefulWidget {
  const _QuizScreen();

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
  List<Soal>? _soal;
  int _index = 0;
  int? _dipilih;
  int _benar = 0;
  bool _selesai = false;

  @override
  void initState() {
    super.initState();
    final mode = context.read<AppStore>().mode;
    muatSoal(mode == AppMode.anak ? AppMode.anak : AppMode.normal).then((s) {
      if (mounted) setState(() => _soal = s);
    });
  }

  void _jawab(int i) {
    if (_dipilih != null) return;
    setState(() {
      _dipilih = i;
      if (i == _soal![_index].jawaban) _benar++;
    });
  }

  Future<void> _lanjut() async {
    if (_index < _soal!.length - 1) {
      setState(() {
        _index++;
        _dipilih = null;
      });
    } else {
      final store = context.read<AppStore>();
      final naik = await store.recordChallengeDay(_benar * 10);
      if (!mounted) return;
      setState(() => _selesai = true);
      if (naik) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Streak bertambah! Sekarang ${store.challengeStreak} hari.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primer = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Kuis')),
      body: _soal == null
          ? const Center(child: CircularProgressIndicator())
          : _selesai
              ? _Hasil(benar: _benar, total: _soal!.length)
              : _soal!.isEmpty
                  ? const Center(child: Text('Soal tidak tersedia.'))
                  : _tampilanSoal(primer),
    );
  }

  Widget _tampilanSoal(Color primer) {
    final s = _soal![_index];
    final anak = context.read<AppStore>().mode == AppMode.anak;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_index + 1) / _soal!.length,
            minHeight: 8,
            backgroundColor: primer.withValues(alpha: 0.12),
            valueColor:
                const AlwaysStoppedAnimation<Color>(QBColors.emas),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Soal ${_index + 1} dari ${_soal!.length}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: QBColors.tintaLembut,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              s.pertanyaan,
              style: s.tipe == 'huruf'
                  ? QBTheme.arab(size: 64, height: 1.8)
                  : Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              textDirection:
                  s.tipe == 'huruf' ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < s.pilihan.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Opsi(
              teks: s.pilihan[i],
              state: _dipilih == null
                  ? _OpsiState.netral
                  : i == s.jawaban
                      ? _OpsiState.benar
                      : i == _dipilih
                          ? _OpsiState.salah
                          : _OpsiState.netral,
              onTap: () => _jawab(i),
            ),
          ),
        if (_dipilih != null) ...[
          Card(
            color: _dipilih == s.jawaban
                ? QBColors.zamrudMuda
                : QBColors.emasMuda,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    _dipilih == s.jawaban
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: _dipilih == s.jawaban
                        ? QBColors.zamrud
                        : QBColors.emas,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _dipilih == s.jawaban
                          ? (anak ? 'Hebat! Benar!' : 'Benar! ') +
                              s.penjelasan
                          : (anak
                                  ? 'Belum tepat. '
                                  : 'Kurang tepat. ') +
                              s.penjelasan,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _lanjut,
            child: Text(_index < _soal!.length - 1
                ? 'Soal berikut'
                : 'Lihat hasil'),
          ),
        ],
      ],
    );
  }
}

enum _OpsiState { netral, benar, salah }

class _Opsi extends StatelessWidget {
  final String teks;
  final _OpsiState state;
  final VoidCallback onTap;
  const _Opsi({
    required this.teks,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Color? border;
    if (state == _OpsiState.benar) {
      bg = QBColors.zamrudMuda;
      border = QBColors.zamrud;
    } else if (state == _OpsiState.salah) {
      bg = const Color(0xFFFDE8E8);
      border = const Color(0xFFC0392B);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border ??
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
            width: state == _OpsiState.netral ? 1.2 : 2,
          ),
        ),
        child: Text(
          teks,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _Hasil extends StatelessWidget {
  final int benar;
  final int total;
  const _Hasil({required this.benar, required this.total});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final anak = store.mode == AppMode.anak;
    final persen = total == 0 ? 0 : (benar / total * 100).round();
    final pesan = persen == 100
        ? (anak ? 'Sempurna! Kamu hebat!' : 'Sempurna! MasyaAllah.')
        : persen >= 70
            ? (anak ? 'Bagus sekali!' : 'Bagus! Terus pertahankan.')
            : persen >= 40
                ? 'Lumayan, ayo coba lagi besok.'
                : 'Tidak apa-apa, belajar lagi yuk.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cincin skor: visualisasi hasil sekilas (data nyata, R-17)
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                painter: _CincinSkor(
                  persen: persen / 100,
                  warna: QBColors.emas,
                  latar: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$persen%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$benar dari $total benar',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: QBColors.tintaLembut,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Streak: ${store.challengeStreak} hari. Total skor: ${store.challengeScore}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: QBColors.tintaLembut,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cincin progres skor hasil kuis.
class _CincinSkor extends CustomPainter {
  final double persen;
  final Color warna;
  final Color latar;

  _CincinSkor({
    required this.persen,
    required this.warna,
    required this.latar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    const tebal = 12.0;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = latar
        ..style = PaintingStyle.stroke
        ..strokeWidth = tebal,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      persen * 2 * pi,
      false,
      Paint()
        ..color = warna
        ..style = PaintingStyle.stroke
        ..strokeWidth = tebal
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CincinSkor old) =>
      old.persen != persen;
}
