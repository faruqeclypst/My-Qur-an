// Daftar 114 surah + pencarian.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/theme.dart';
import 'quran_api.dart';
import 'reader_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  List<Surah>? _surah;
  String? _error;
  String _cari = '';
  final _cariCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat({bool refresh = false}) async {
    setState(() {
      _error = null;
      if (refresh) _surah = null;
    });
    try {
      final list = await QuranApi.daftarSurah(paksaRefresh: refresh);
      if (mounted) setState(() => _surah = list);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Tidak bisa memuat daftar surah. Periksa koneksi internet, lalu coba lagi.');
      }
    }
  }

  @override
  void dispose() {
    _cariCtrl.dispose();
    super.dispose();
  }

  List<Surah> get _tersaring {
    final list = _surah ?? [];
    final q = _cari.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((s) {
      return s.namaLatin.toLowerCase().contains(q) ||
          s.arti.toLowerCase().contains(q) ||
          '${s.nomor}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final anak = context.watch<AppStore>().mode == AppMode.anak;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Al-Quran'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _cariCtrl,
              decoration: InputDecoration(
                hintText: anak ? 'Cari surah...' : 'Cari nama atau arti surah...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _cari.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _cariCtrl.clear();
                          setState(() => _cari = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintStyle:
                    const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _cari = v),
            ),
          ),
        ),
      ),
      body: _badan(anak),
    );
  }

  Widget _badan(bool anak) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 52),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _muat(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_surah == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat daftar surah...'),
          ],
        ),
      );
    }
    final list = _tersaring;
    if (list.isEmpty) {
      return Center(
        child: Text(
          anak ? 'Tidak ketemu. Coba kata lain!' : 'Tidak ada surah yang cocok.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _muat(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final s = list[i];
          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: _NomorSurah(nomor: s.nomor),
              title: Text(
                s.namaLatin,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                  '${s.arti} \u2022 ${s.jumlahAyat} ayat \u2022 ${s.tempatTurun}'),
              trailing: Text(
                s.namaArab,
                style: QBTheme.arab(size: 24, color: QBColors.zamrudTua),
                textDirection: TextDirection.rtl,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReaderScreen(surah: s),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NomorSurah extends StatelessWidget {
  final int nomor;
  const _NomorSurah({required this.nomor});

  @override
  Widget build(BuildContext context) {
    final primer = Theme.of(context).colorScheme.primary;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(color: primer, width: 1.6),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        '$nomor',
        style: TextStyle(
          color: primer,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
