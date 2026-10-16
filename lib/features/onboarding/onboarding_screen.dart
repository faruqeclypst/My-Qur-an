// Onboarding: pilih mode + nama opsional. Sekali saja, bisa diubah di Pengaturan.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  AppMode? _mode;
  final _namaCtrl = TextEditingController();

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _selesai() async {
    if (_mode == null) return;
    final store = context.read<AppStore>();
    await store.completeOnboarding(_mode!, _namaCtrl.text);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Motif mihrab sederhana sebagai identitas
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: QBColors.zamrud,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(48),
                          topRight: Radius.circular(48),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '\u0627\u0644\u0642\u0631\u0622\u0646',
                        style: QBTheme.arab(
                          size: 30,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quranku',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Teman ngaji harian: baca Quran, belajar hijaiyah dan Iqro, kisah nabi, kompas kiblat, dan pengingat ngaji.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: QBColors.tintaLembut,
                        ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Siapa yang memakai aplikasi ini?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    mode: AppMode.lansia,
                    judul: 'Lansia',
                    deskripsi:
                        'Huruf besar, kontras tinggi, tombol besar, tampilan sederhana.',
                    dipilih: _mode == AppMode.lansia,
                    onTap: () => setState(() => _mode = AppMode.lansia),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    mode: AppMode.normal,
                    judul: 'Normal',
                    deskripsi:
                        'Semua fitur lengkap dengan tampilan yang rapi dan profesional.',
                    dipilih: _mode == AppMode.normal,
                    onTap: () => setState(() => _mode = AppMode.normal),
                  ),
                  const SizedBox(height: 12),
                  _ModeCard(
                    mode: AppMode.anak,
                    judul: 'Anak',
                    deskripsi:
                        'Warna ceria, ikon besar, bahasa sederhana, ada kuis seru.',
                    dipilih: _mode == AppMode.anak,
                    onTap: () => setState(() => _mode = AppMode.anak),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _namaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama panggilan (boleh dikosongkan)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _selesai(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _mode == null ? null : _selesai,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Mulai Ngaji', style: TextStyle(fontSize: 17)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tanpa akun, tanpa login. Semua data tersimpan di perangkat ini.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QBColors.tintaLembut,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final AppMode mode;
  final String judul;
  final String deskripsi;
  final bool dipilih;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.judul,
    required this.deskripsi,
    required this.dipilih,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case AppMode.lansia:
        return Icons.visibility_outlined;
      case AppMode.normal:
        return Icons.menu_book_outlined;
      case AppMode.anak:
        return Icons.child_care_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primer = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dipilih ? primer : primer.withValues(alpha: 0.25),
            width: dipilih ? 2.5 : 1.5,
          ),
          color: dipilih ? primer.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: dipilih ? primer : primer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _icon,
                color: dipilih ? Colors.white : primer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    deskripsi,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: QBColors.tintaLembut,
                        ),
                  ),
                ],
              ),
            ),
            if (dipilih) Icon(Icons.check_circle, color: primer),
          ],
        ),
      ),
    );
  }
}
