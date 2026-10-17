// Belajar Iqro: Jilid 1-3, halaman per halaman. Ketuk baris untuk mendengar via TTS.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/dekorasi.dart';
import '../../core/theme.dart';

class IqroJilid {
  final int nomor;
  final String judul;
  final List<IqroHalaman> halaman;
  IqroJilid({required this.nomor, required this.judul, required this.halaman});
}

class IqroHalaman {
  final int nomor;
  final List<String> baris;
  IqroHalaman({required this.nomor, required this.baris});
}

Future<List<IqroJilid>> muatIqro() async {
  final raw = await rootBundle.loadString('assets/data/iqro.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  return [
    for (final j in (data['jilid'] as List))
      IqroJilid(
        nomor: (j['nomor'] as num).toInt(),
        judul: j['judul'] as String,
        halaman: [
          for (final h in (j['halaman'] as List))
            IqroHalaman(
              nomor: (h['nomor'] as num).toInt(),
              baris: [for (final b in (h['baris'] as List)) b as String],
            ),
        ],
      ),
  ];
}

class IqroScreen extends StatelessWidget {
  const IqroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Belajar Iqro')),
      body: FutureBuilder<List<IqroJilid>>(
        future: muatIqro(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return _ErrorState(
              onRetry: () => (context as Element).markNeedsBuild(),
            );
          }
          final jilids = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jilids.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final j = jilids[i];
              final progres =
                  (store.iqroProgress['j${j.nomor}'] as num?)?.toInt() ?? 0;
              final selesai = progres >= j.halaman.length;
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${j.nomor}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  title: Text(
                    'Iqro Jilid ${j.nomor}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(j.judul),
                      const SizedBox(height: 6),
                      _StatusProgres(
                          selesai: selesai, progres: progres, jilid: j),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _IqroJilidScreen(jilid: j),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Status progres tiap jilid (dipisah agar tidak memakai if/else di dalam list)
class _StatusProgres extends StatelessWidget {
  final bool selesai;
  final int progres;
  final IqroJilid jilid;
  const _StatusProgres({
    required this.selesai,
    required this.progres,
    required this.jilid,
  });

  @override
  Widget build(BuildContext context) {
    if (selesai) {
      return const Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: QBColors.zamrud),
          SizedBox(width: 4),
          Text('Selesai'),
        ],
      );
    }
    final total = jilid.halaman.length;
    final nilai = total == 0 ? 0.0 : progres / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(progres > 0
            ? 'Lanjut halaman ${progres + 1} dari $total'
            : '$total halaman'),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: nilai,
            minHeight: 6,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(QBColors.emas),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Materi Iqro tidak bisa dimuat.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class _IqroJilidScreen extends StatefulWidget {
  final IqroJilid jilid;
  const _IqroJilidScreen({required this.jilid});

  @override
  State<_IqroJilidScreen> createState() => _IqroJilidScreenState();
}

class _IqroJilidScreenState extends State<_IqroJilidScreen> {
  late final PageController _ctrl;
  int _halaman = 0;
  final FlutterTts _tts = FlutterTts();
  int? _barisAktif;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    final progres =
        (store.iqroProgress['j${widget.jilid.nomor}'] as num?)?.toInt() ?? 0;
    _halaman = progres.clamp(0, widget.jilid.halaman.length - 1);
    _ctrl = PageController(initialPage: _halaman);
    _siapkanTts();
  }

  Future<void> _siapkanTts() async {
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.4);
    } catch (_) {}
  }

  Future<void> _bunyikan(String baris, int index) async {
    setState(() => _barisAktif = index);
    try {
      await _tts.stop();
      await _tts.speak(baris);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jilid = widget.jilid;
    final primer = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text('Iqro Jilid ${jilid.nomor}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_halaman + 1) / jilid.halaman.length,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            color: QBColors.emas,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman ${_halaman + 1} dari ${jilid.halaman.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: QBColors.tintaLembut,
                      ),
                ),
                Text(
                  'Ketuk baris untuk mendengar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: QBColors.tintaLembut,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: jilid.halaman.length,
              onPageChanged: (i) {
                setState(() {
                  _halaman = i;
                  _barisAktif = null;
                });
                context
                    .read<AppStore>()
                    .saveIqroProgress(jilid.nomor, i + 1);
              },
              itemBuilder: (context, i) {
                final hal = jilid.halaman[i];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          // Ornamen kepala halaman seperti buku cetak
                          PembatasOrnamen(
                            warna: primer.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 8),
                          for (var b = 0; b < hal.baris.length; b++) ...[
                            InkWell(
                              onTap: () => _bunyikan(hal.baris[b], b),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: _barisAktif == b
                                      ? primer.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  hal.baris[b],
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: QBTheme.arab(size: 34, height: 2.0),
                                ),
                              ),
                            ),
                            if (b < hal.baris.length - 1)
                              Divider(
                                color:
                                    primer.withValues(alpha: 0.15),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _halaman > 0
                      ? () => _ctrl.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          )
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
                FilledButton.icon(
                  onPressed: _halaman < jilid.halaman.length - 1
                      ? () => _ctrl.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          )
                      : () => Navigator.of(context).pop(),
                  icon: Icon(_halaman < jilid.halaman.length - 1
                      ? Icons.arrow_forward
                      : Icons.check),
                  label: Text(_halaman < jilid.halaman.length - 1
                      ? 'Lanjut'
                      : 'Selesai'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
