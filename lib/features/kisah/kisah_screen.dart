// Kisah Nabi: serial 25 nabi, tiap nabi beberapa episode pendek.
// Ilustrasi memakai emoji sesuai permintaan eksplisit user (override R-04 untuk fitur ini).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';

class KisahNabi {
  final String nama;
  final String gelar;
  final List<KisahEpisode> episode;
  KisahNabi({required this.nama, required this.gelar, required this.episode});
}

class KisahEpisode {
  final String judul;
  final String isi;
  KisahEpisode({required this.judul, required this.isi});
}

Future<List<KisahNabi>> muatKisah() async {
  final raw = await rootBundle.loadString('assets/data/kisah_nabi.json');
  final data = jsonDecode(raw) as List;
  return [
    for (final n in data)
      KisahNabi(
        nama: n['nama'] as String,
        gelar: (n['gelar'] as String?) ?? '',
        episode: [
          for (final e in (n['episode'] as List))
            KisahEpisode(judul: e['judul'] as String, isi: e['isi'] as String),
        ],
      ),
  ];
}

// Satu emoji per nabi sebagai "sampul" serial (tanpa gambar eksternal).
const _emojiNabi = [
  '\u{1F468}', '\u2728', '\u{1F6A2}', '\u{1F32A}', '\u{1F42A}',
  '\u{1F525}', '\u{1F3D5}\uFE0F', '\u{1F411}', '\u2B50', '\u{1F31F}',
  '\u{1F319}', '\u{1F49A}', '\u{1F4CF}', '\u{1F30A}', '\u{1F54C}',
  '\u{1F4D6}', '\u{1F3B6}', '\u{1F451}', '\u26C8', '\u{1F33F}',
  '\u{1F41F}', '\u{1F54B}', '\u{1F476}', '\u{1F54A}', '\u{1F311}',
];

class KisahScreen extends StatelessWidget {
  const KisahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kisah 25 Nabi')),
      body: FutureBuilder<List<KisahNabi>>(
        future: muatKisah(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(
              child: Text('Kisah tidak bisa dimuat.'),
            );
          }
          final list = snap.data!;
          return Consumer<AppStore>(
            builder: (context, store, _) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final nabi = list[i];
                final sudah =
                    (store.kisahProgress['n$i'] as num?)?.toInt() ?? -1;
                final mulaiDari = (sudah + 1).clamp(0, nabi.episode.length - 1);
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.65),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _emojiNabi[i % _emojiNabi.length],
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    title: Text(
                      'Nabi ${nabi.nama}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      sudah >= nabi.episode.length - 1
                          ? 'Selesai dibaca. MasyaAllah!'
                          : sudah >= 0
                              ? 'Lanjut: ${nabi.episode[mulaiDari].judul}'
                              : '${nabi.episode.length} episode. ${nabi.gelar}',
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            _KisahDetailScreen(list: list, index: i),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _KisahDetailScreen extends StatefulWidget {
  final List<KisahNabi> list;
  final int index;
  const _KisahDetailScreen({required this.list, required this.index});

  @override
  State<_KisahDetailScreen> createState() => _KisahDetailScreenState();
}

class _KisahDetailScreenState extends State<_KisahDetailScreen> {
  late int _episode;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppStore>();
    final sudah =
        (store.kisahProgress['n${widget.index}'] as num?)?.toInt() ?? -1;
    _episode = (sudah + 1)
        .clamp(0, widget.list[widget.index].episode.length - 1);
  }

  void _gantiEpisode(int e) {
    final nabi = widget.list[widget.index];
    setState(() => _episode = e.clamp(0, nabi.episode.length - 1));
    context.read<AppStore>().saveKisahProgress(widget.index, _episode);
  }

  @override
  Widget build(BuildContext context) {
    final nabi = widget.list[widget.index];
    final ep = nabi.episode[_episode];
    final primer = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text('Nabi ${nabi.nama}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Sampul episode
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primer, primer.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  _emojiNabi[widget.index % _emojiNabi.length],
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 12),
                Text(
                  ep.judul,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Episode ${_episode + 1} dari ${nabi.episode.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final paragraf in ep.isi.split('\n\n'))
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                paragraf.trim(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                    ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: _episode > 0 ? () => _gantiEpisode(_episode - 1) : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Sebelumnya'),
              ),
              if (_episode < nabi.episode.length - 1)
                FilledButton.icon(
                  onPressed: () => _gantiEpisode(_episode + 1),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Episode berikut'),
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    if (widget.index < widget.list.length - 1) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => _KisahDetailScreen(
                            list: widget.list,
                            index: widget.index + 1,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: Text(widget.index < widget.list.length - 1
                      ? 'Nabi berikut'
                      : 'Selesai'),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
