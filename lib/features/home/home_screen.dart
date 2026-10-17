// Layar utama: tab bawah yang isinya menyesuaikan mode (Lansia/Normal/Anak).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/dekorasi.dart';
import '../../core/theme.dart';
import '../challenge/challenge_screen.dart';
import '../hijaiyah/hijaiyah_screen.dart';
import '../iqro/iqro_screen.dart';
import '../kiblat/kiblat_screen.dart';
import '../kisah/kisah_screen.dart';
import '../quran/last_read_screen.dart';
import '../quran/surah_list_screen.dart';
import '../reminder/reminder_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  List<_Tab> _tabs(AppMode mode) {
    switch (mode) {
      case AppMode.lansia:
        return const [
          _Tab('Beranda', Icons.home_outlined, _BerandaTab()),
          _Tab('Al-Quran', Icons.menu_book_outlined, SurahListScreen()),
          _Tab('Pengaturan', Icons.settings_outlined, SettingsScreen()),
        ];
      case AppMode.anak:
        return const [
          _Tab('Beranda', Icons.home_outlined, _BerandaTab()),
          _Tab('Ngaji', Icons.menu_book_outlined, SurahListScreen()),
          _Tab('Belajar', Icons.school_outlined, _BelajarTab()),
          _Tab('Kisah', Icons.auto_stories_outlined, KisahScreen()),
          _Tab('Main', Icons.emoji_events_outlined, ChallengeScreen()),
        ];
      case AppMode.normal:
        return const [
          _Tab('Beranda', Icons.home_outlined, _BerandaTab()),
          _Tab('Al-Quran', Icons.menu_book_outlined, SurahListScreen()),
          _Tab('Belajar', Icons.school_outlined, _BelajarTab()),
          _Tab('Kisah', Icons.auto_stories_outlined, KisahScreen()),
          _Tab('Pengaturan', Icons.settings_outlined, SettingsScreen()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final tabs = _tabs(store.mode);
    final idx = _index.clamp(0, tabs.length - 1);
    return Scaffold(
      body: IndexedStack(
        index: idx,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final t in tabs)
            BottomNavigationBarItem(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final Widget screen;
  const _Tab(this.label, this.icon, this.screen);
}

// Tab gabungan Hijaiyah + Iqro
class _BelajarTab extends StatelessWidget {
  const _BelajarTab();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Belajar'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hijaiyah', icon: Icon(Icons.abc_outlined)),
              Tab(text: 'Iqro', icon: Icon(Icons.book_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [HijaiyahScreen(), IqroScreen()],
        ),
      ),
    );
  }
}

// Beranda: kepala berpola, terakhir dibaca, challenge, menu cepat
class _BerandaTab extends StatelessWidget {
  const _BerandaTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final teks = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          KepalaBeranda(
            sapaan: store.mode.sapaan,
            nama: store.nama,
            tanggal: _tanggalHariIni(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _LastReadCard(),
                const SizedBox(height: 12),
                const _ChallengeCard(),
                const SizedBox(height: 20),
                Text(
                  'Menu',
                  style: teks.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _MenuGrid(mode: store.mode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tanggalHariIni() {
    final now = DateTime.now();
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} ${now.year}';
  }
}

class _LastReadCard extends StatelessWidget {
  const _LastReadCard();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final lr = store.lastRead;
    final primer = Theme.of(context).colorScheme.primary;
    final teks = Theme.of(context).textTheme;

    // Kartu hero berwarna primer: menandai aksi utama "lanjutkan ngaji"
    // (R-01: warna kuat dipakai di satu momen penting sebagai hierarki).
    return Card(
      color: primer,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                lr == null ? const SurahListScreen() : const LastReadScreen(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: QBColors.emas.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.bookmark_outline,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: lr == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mulai perjalanan ngajimu',
                            style: teks.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Buka Al-Fatihah dan baca ayat pertama.',
                            style: teks.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terakhir dibaca',
                            style: teks.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${lr.namaSurah} ayat ${lr.ayat}',
                            style: teks.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primer,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => lr == null
                        ? const SurahListScreen()
                        : const LastReadScreen(),
                  ),
                ),
                child: Text(lr == null ? 'Mulai' : 'Lanjutkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final primer = Theme.of(context).colorScheme.primary;
    final anak = store.mode == AppMode.anak;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: QBColors.emasMuda,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events_outlined,
                  color: QBColors.emas),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anak ? 'Kuis Seru Hari Ini' : 'Challenge Harian',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    store.challengeStreak > 0
                        ? 'Streak ${store.challengeStreak} hari. Pertahankan!'
                        : (anak
                            ? 'Main kuis dan kumpulkan bintang!'
                            : 'Uji hafalan dan tajwidmu hari ini.'),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: QBColors.tintaLembut),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward, color: primer),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChallengeScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final AppMode mode;
  const _MenuGrid({required this.mode});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem('Kompas Kiblat', Icons.explore_outlined, const KiblatScreen()),
      _MenuItem(
          'Pengingat Ngaji', Icons.alarm_outlined, const ReminderScreen()),
      _MenuItem('Kisah Nabi', Icons.auto_stories_outlined, const KisahScreen()),
      if (mode != AppMode.lansia)
        _MenuItem('Belajar Iqro', Icons.book_outlined, const IqroScreen()),
      if (mode != AppMode.lansia)
        _MenuItem(
            'Huruf Hijaiyah', Icons.abc_outlined, const HijaiyahScreen()),
      _MenuItem('Pengaturan', Icons.settings_outlined, const SettingsScreen()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: mode == AppMode.lansia ? 2 : 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final primer = Theme.of(context).colorScheme.primary;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => item.screen),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon,
                      size: mode == AppMode.lansia ? 40 : 32, color: primer),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const _MenuItem(this.label, this.icon, this.screen);
}
