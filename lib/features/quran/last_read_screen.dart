// Halaman "Terakhir Dibaca": akses cepat ke posisi terakhir + riwayat singkat.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import 'quran_api.dart';
import 'reader_screen.dart';
import 'surah_list_screen.dart';

class LastReadScreen extends StatelessWidget {
  const LastReadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final lr = store.lastRead;

    return Scaffold(
      appBar: AppBar(title: const Text('Terakhir Dibaca')),
      body: lr == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_add_outlined,
                      size: 56,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada bacaan tersimpan.\nMulai ngaji dan posisimu akan tersimpan otomatis di sini.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SurahListScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Mulai Ngaji'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lr.namaSurah,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ayat ${lr.ayat} \u2022 ${_formatWaktu(lr.waktu)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _lanjutkan(context, lr),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Lanjutkan ngaji'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatWaktu(DateTime w) {
    final now = DateTime.now();
    final selisih = now.difference(w);
    if (selisih.inMinutes < 1) return 'baru saja';
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
    if (selisih.inDays == 1) return 'kemarin';
    if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
    return '${w.day}/${w.month}/${w.year}';
  }

  Future<void> _lanjutkan(BuildContext context, LastRead lr) async {
    // Muat info surah dari cache/daftar agar Reader punya metadata lengkap
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator()),
    );
    try {
      final list = await QuranApi.daftarSurah();
      final surah = list.firstWhere(
        (s) => s.nomor == lr.surah,
        orElse: () => Surah(
          nomor: lr.surah,
          namaArab: '',
          namaLatin: lr.namaSurah,
          jumlahAyat: 0,
          tempatTurun: '',
          arti: '',
        ),
      );
      if (!context.mounted) return;
      Navigator.of(context).pop(); // tutup loading
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReaderScreen(surah: surah, ayatAwal: lr.ayat),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal membuka. Periksa koneksi internet.')),
      );
    }
  }
}
