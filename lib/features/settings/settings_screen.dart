// Pengaturan: mode, font, toggle tampilan, tentang, info sinkronisasi cloud.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _JudulSeksi('Mode Tampilan'),
          Card(
            child: RadioGroup<AppMode>(
              groupValue: store.mode,
              onChanged: (v) {
                if (v != null) {
                  context.read<AppStore>().setMode(v);
                  if (v == AppMode.lansia) {
                    context.read<AppStore>().setFontScale(1.35);
                  }
                }
              },
              child: Column(
                children: [
                  for (final m in AppMode.values)
                    RadioListTile<AppMode>(
                      title: Text('Mode ${m.label}'),
                      subtitle: Text(_deskripsiMode(m)),
                      value: m,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _JudulSeksi('Ukuran Huruf'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Contoh: \u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u064e\u0651\u0647\u0650',
                    style: QBTheme.arab(size: 28 * store.fontScale),
                    textDirection: TextDirection.rtl,
                  ),
                  Slider(
                    value: store.fontScale,
                    min: 0.8,
                    max: 2.2,
                    divisions: 14,
                    label: '${(store.fontScale * 100).round()}%',
                    onChanged: (v) =>
                        context.read<AppStore>().setFontScale(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _JudulSeksi('Tampilan Bacaan'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Tanda warna tajwid'),
                  subtitle: const Text(
                      'Warnai bacaan sesuai hukum tajwid'),
                  value: store.showTajwid,
                  onChanged: (v) =>
                      context.read<AppStore>().setToggles(tajwid: v),
                ),
                SwitchListTile(
                  title: const Text('Teks latin'),
                  subtitle:
                      const Text('Bacaan latin di bawah teks Arab'),
                  value: store.showLatin,
                  onChanged: (v) =>
                      context.read<AppStore>().setToggles(latin: v),
                ),
                SwitchListTile(
                  title: const Text('Terjemahan Indonesia'),
                  subtitle: const Text(
                      'Arti ayat dalam bahasa Indonesia'),
                  value: store.showTerjemahan,
                  onChanged: (v) =>
                      context.read<AppStore>().setToggles(terjemahan: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _JudulSeksi('Sinkronisasi Cloud'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Sinkronisasi antar perangkat'),
              subtitle: const Text('Segera hadir'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () => _tampilInfoCloud(context),
            ),
          ),
          const SizedBox(height: 16),
          _JudulSeksi('Tentang'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quranku versi 1.0',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Teman ngaji harian: baca Al-Quran dengan audio dan tanda '
                    'tajwid, belajar hijaiyah dan Iqro, kisah 25 nabi, kompas '
                    'kiblat, pengingat ngaji, dan challenge harian.\n\n'
                    'Teks, terjemahan, dan tafsir ringkas memakai data dari '
                    'equran.id. Audio bacaan dari qari yang datanya '
                    'disediakan layanan tersebut.\n\n'
                    'Semua progres tersimpan di perangkat ini, tanpa akun.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _deskripsiMode(AppMode m) {
    switch (m) {
      case AppMode.lansia:
        return 'Huruf besar, kontras tinggi, sederhana';
      case AppMode.normal:
        return 'Semua fitur, tampilan profesional';
      case AppMode.anak:
        return 'Ceria, bahasa sederhana, ada kuis';
    }
  }

  void _tampilInfoCloud(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sinkronisasi Cloud (segera hadir)'),
        content: const SingleChildScrollView(
          child: Text(
            'Saat ini semua data (terakhir dibaca, progres Iqro, kisah, '
            'streak challenge) hanya tersimpan di perangkat ini.\n\n'
            'Agar progres ikut saat ganti HP, aplikasi perlu sinkronisasi '
            'cloud dengan login Google. Rencana teknisnya:\n\n'
            '1. Daftarkan proyek di Firebase Console (gratis).\n'
            '2. Aktifkan Authentication dengan metode Google Sign-In.\n'
            '3. Aktifkan Realtime Database untuk menyimpan progres per pengguna.\n'
            '4. Tambahkan paket firebase_auth, google_sign_in, dan '
            'firebase_database ke aplikasi.\n\n'
            'Perkiraan waktu pengerjaan sekitar 30 menit setelah proyek '
            'Firebase siap. Login tetap opsional: tanpa login aplikasi '
            'tetap berfungsi penuh secara lokal.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

class _JudulSeksi extends StatelessWidget {
  final String teks;
  const _JudulSeksi(this.teks);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        teks,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: QBColors.tintaLembut,
            ),
      ),
    );
  }
}
