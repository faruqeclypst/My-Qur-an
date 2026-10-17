// Belajar Hijaiyah: 28 huruf + harakat. Ketuk untuk mendengar bunyi via TTS.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/theme.dart';

class HurufHijaiyah {
  final String huruf;
  final String nama;
  const HurufHijaiyah(this.huruf, this.nama);
}

const hijaiyah = [
  HurufHijaiyah('\u0627', 'Alif'),
  HurufHijaiyah('\u0628', 'Ba'),
  HurufHijaiyah('\u062a', 'Ta'),
  HurufHijaiyah('\u062b', 'Tsa'),
  HurufHijaiyah('\u062c', 'Jim'),
  HurufHijaiyah('\u062d', 'Ha'),
  HurufHijaiyah('\u062e', 'Kha'),
  HurufHijaiyah('\u062f', 'Dal'),
  HurufHijaiyah('\u0630', 'Dzal'),
  HurufHijaiyah('\u0631', 'Ra'),
  HurufHijaiyah('\u0632', 'Za'),
  HurufHijaiyah('\u0633', 'Sin'),
  HurufHijaiyah('\u0634', 'Syin'),
  HurufHijaiyah('\u0635', 'Shad'),
  HurufHijaiyah('\u0636', 'Dhad'),
  HurufHijaiyah('\u0637', 'Tha'),
  HurufHijaiyah('\u0638', 'Zha'),
  HurufHijaiyah('\u0639', '\u2019Ain'),
  HurufHijaiyah('\u063a', 'Ghain'),
  HurufHijaiyah('\u0641', 'Fa'),
  HurufHijaiyah('\u0642', 'Qaf'),
  HurufHijaiyah('\u0643', 'Kaf'),
  HurufHijaiyah('\u0644', 'Lam'),
  HurufHijaiyah('\u0645', 'Mim'),
  HurufHijaiyah('\u0646', 'Nun'),
  HurufHijaiyah('\u0648', 'Wau'),
  HurufHijaiyah('\u0647', 'Ha'),
  HurufHijaiyah('\u0621', 'Hamzah'),
  HurufHijaiyah('\u064a', 'Ya'),
];

const harakatList = [
  _Harakat('\u064e', 'Fathah', 'a'),
  _Harakat('\u0650', 'Kasrah', 'i'),
  _Harakat('\u064f', 'Dhammah', 'u'),
  _Harakat('\u0652', 'Sukun', ''),
  _Harakat('\u064b', 'Fathatain', 'an'),
  _Harakat('\u064d', 'Kasratain', 'in'),
  _Harakat('\u064c', 'Dhammatain', 'un'),
];

class _Harakat {
  final String tanda;
  final String nama;
  final String bunyi;
  const _Harakat(this.tanda, this.nama, this.bunyi);
}

class HijaiyahScreen extends StatefulWidget {
  const HijaiyahScreen({super.key});

  @override
  State<HijaiyahScreen> createState() => _HijaiyahScreenState();
}

class _HijaiyahScreenState extends State<HijaiyahScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _ttsSiap = false;
  int _harakatIndex = 0;
  String? _terakhirDibunyikan;

  @override
  void initState() {
    super.initState();
    _siapkanTts();
  }

  Future<void> _siapkanTts() async {
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      if (mounted) setState(() => _ttsSiap = true);
    } catch (_) {
      // TTS tidak tersedia: fallback hanya tampil, tanpa suara
      if (mounted) setState(() => _ttsSiap = false);
    }
  }

  Future<void> _bunyikan(String teksArab) async {
    setState(() => _terakhirDibunyikan = teksArab);
    context.read<AppStore>().tandaiHijaiyah(teksArab);
    if (!_ttsSiap) return;
    try {
      await _tts.stop();
      await _tts.speak(teksArab);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final anak = store.mode == AppMode.anak;
    final harakat = harakatList[_harakatIndex];
    final primer = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Huruf Hijaiyah')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            anak
                ? 'Ketuk hurufnya, dengarkan bunyinya!'
                : 'Pilih harakat, lalu ketuk huruf untuk mendengar bunyinya.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: QBColors.tintaLembut,
                ),
          ),
          const SizedBox(height: 12),
          // Kemajuan belajar: angka nyata dari data lokal (R-17)
          _KartuProgres(
            dipelajari: store.hijaiyahDipelajari.length,
            total: hijaiyah.length * harakatList.length,
          ),
          const SizedBox(height: 12),
          Text(
            'Harakat',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Pemilih harakat
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: harakatList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final h = harakatList[i];
                final aktif = i == _harakatIndex;
                return ChoiceChip(
                  label: Text(
                    '\u0628${h.tanda}  ${h.nama}',
                    style: QBTheme.arab(size: 20, height: 1.6),
                  ),
                  selected: aktif,
                  onSelected: (_) => setState(() => _harakatIndex = i),
                  selectedColor: primer.withValues(alpha: 0.22),
                  side: BorderSide(
                    color: aktif
                        ? primer
                        : primer.withValues(alpha: 0.3),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
          if (!_ttsSiap && !kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Suara tidak tersedia di perangkat ini, huruf tetap bisa dilihat.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: QBColors.tintaLembut,
                    ),
              ),
            ),
          const SizedBox(height: 12),
          // Grid huruf
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: hijaiyah.length,
            itemBuilder: (context, i) {
              final h = hijaiyah[i];
              final denganHarakat = '${h.huruf}${harakat.tanda}';
              final dipelajari =
                  store.hijaiyahDipelajari.contains(denganHarakat);
              final berbunyi =
                  _terakhirDibunyikan == denganHarakat;
              return Card(
                color: berbunyi
                    ? primer.withValues(alpha: 0.15)
                    : dipelajari
                        ? QBColors.emasMuda.withValues(alpha: 0.45)
                        : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _bunyikan(denganHarakat),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              denganHarakat,
                              style: QBTheme.arab(
                                size: anak ? 40 : 34,
                                color: QBColors.tinta,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                        Text(
                          h.nama,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        if (dipelajari)
                          Icon(Icons.check_circle,
                              size: 14, color: QBColors.emas),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Sudah dipelajari: ${store.hijaiyahDipelajari.length} bunyi',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QBColors.tintaLembut,
                ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kemajuan belajar hijaiyah dengan bilah progres nyata.
class _KartuProgres extends StatelessWidget {
  final int dipelajari;
  final int total;
  const _KartuProgres({required this.dipelajari, required this.total});

  @override
  Widget build(BuildContext context) {
    final primer = Theme.of(context).colorScheme.primary;
    final persen = total == 0 ? 0.0 : dipelajari / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: QBColors.emasMuda,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.track_changes, color: QBColors.emas),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dipelajari dari $total bunyi dipelajari',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: persen,
                      minHeight: 7,
                      backgroundColor: primer.withValues(alpha: 0.12),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(QBColors.emas),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
