// Halaman baca per surah: teks Arab + latin + terjemahan,
// audio per ayat & full surah, slider font, toggle tajwid, auto-simpan terakhir dibaca.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/theme.dart';
import 'quran_api.dart';
import 'tajwid.dart';

class ReaderScreen extends StatefulWidget {
  final Surah surah;
  final int ayatAwal; // untuk "lanjutkan" dari terakhir dibaca
  const ReaderScreen({super.key, required this.surah, this.ayatAwal = 1});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  SurahDetail? _detail;
  String? _error;
  final _player = AudioPlayer();
  int? _ayatDiputar;
  bool _putarSemua = false;
  bool _memutar = false;
  final _scrollCtrl = ScrollController();
  final _kunciAyat = <int, GlobalKey>{};
  double _fontAyat = 30;
  StreamSubscription<int?>? _indexSub;

  @override
  void initState() {
    super.initState();
    _fontAyat = 26 + context.read<AppStore>().fontScale * 4;
    _muat();
    _player.playerStateStream.listen((st) {
      if (!mounted) return;
      setState(() => _memutar = st.playing);
      if (st.processingState == ProcessingState.completed) {
        setState(() {
          _putarSemua = false;
          _ayatDiputar = null;
        });
      }
    });
    // Ikuti perpindahan ayat saat memutar seluruh surah
    _indexSub = _player.currentIndexStream.listen((idx) {
      if (!mounted || !_putarSemua || _detail == null || idx == null) return;
      final denganAudio = [
        for (final a in _detail!.ayat)
          if (a.audioUrl.isNotEmpty) a
      ];
      if (idx < denganAudio.length) {
        final ayat = denganAudio[idx];
        setState(() => _ayatDiputar = ayat.nomor);
        _keAyat(ayat.nomor);
        _simpanTerakhir(ayat.nomor);
      }
    });
  }

  Future<void> _muat() async {
    try {
      final d = await QuranApi.detailSurah(widget.surah.nomor);
      if (!mounted) return;
      setState(() => _detail = d);
      for (final a in d.ayat) {
        _kunciAyat[a.nomor] = GlobalKey();
      }
      // Lompat ke ayat awal bila diminta
      if (widget.ayatAwal > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _keAyat(widget.ayatAwal));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Tidak bisa memuat surah. Periksa koneksi internet, lalu coba lagi.');
      }
    }
  }

  void _keAyat(int nomor) {
    final key = _kunciAyat[nomor];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        alignment: 0.15,
      );
    }
  }

  Future<void> _putarAyat(int nomorAyat) async {
    final ayat = _detail!.ayat.firstWhere((a) => a.nomor == nomorAyat);
    if (ayat.audioUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio ayat ini tidak tersedia.')),
      );
      return;
    }
    try {
      setState(() {
        _ayatDiputar = nomorAyat;
        _putarSemua = false;
      });
      await _player.setUrl(ayat.audioUrl);
      await _player.play();
      _simpanTerakhir(nomorAyat);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio gagal diputar.')),
      );
    }
  }

  Future<void> _putarSeluruhSurah() async {
    final sources = [
      for (final a in _detail!.ayat)
        if (a.audioUrl.isNotEmpty) AudioSource.uri(Uri.parse(a.audioUrl)),
    ];
    if (sources.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio surah ini tidak tersedia.')),
      );
      return;
    }
    try {
      final pertama = _detail!.ayat.firstWhere((a) => a.audioUrl.isNotEmpty);
      setState(() {
        _putarSemua = true;
        _ayatDiputar = pertama.nomor;
      });
      await _player.setAudioSources(sources);
      await _player.play();
      _keAyat(pertama.nomor);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio gagal diputar.')),
      );
    }
  }

  Future<void> _berhenti() async {
    await _player.stop();
    if (mounted) {
      setState(() {
        _ayatDiputar = null;
        _putarSemua = false;
      });
    }
  }

  void _simpanTerakhir(int ayat) {
    context.read<AppStore>().saveLastRead(
          widget.surah.nomor,
          widget.surah.namaLatin,
          ayat,
        );
  }

  @override
  void dispose() {
    _indexSub?.cancel();
    _player.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final primer = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.surah.namaLatin),
            Text(
              '${widget.surah.arti} \u2022 ${widget.surah.jumlahAyat} ayat',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Putar full surah
          IconButton(
            tooltip: _putarSemua && _memutar ? 'Berhenti' : 'Putar semua ayat',
            icon: Icon(_putarSemua && _memutar
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline),
            onPressed: _detail == null
                ? null
                : (_putarSemua && _memutar ? _berhenti : _putarSeluruhSurah),
          ),
          // Ukuran font
          IconButton(
            tooltip: 'Ukuran huruf',
            icon: const Icon(Icons.text_fields),
            onPressed: () => _dialogFont(),
          ),
        ],
      ),
      body: _badan(store, primer),
      bottomNavigationBar: _detail == null
          ? null
          : SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: primer.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _putarSemua && _memutar
                            ? 'Memutar seluruh surah...'
                            : _ayatDiputar != null && _memutar
                                ? 'Memutar ayat $_ayatDiputar...'
                                : 'Ketuk ikon suara pada ayat untuk mendengar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: QBColors.tintaLembut,
                            ),
                      ),
                    ),
                    if (_memutar)
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: _berhenti,
                        tooltip: 'Berhenti',
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _badan(AppStore store, Color primer) {
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
                onPressed: () {
                  setState(() {
                    _error = null;
                    _detail = null;
                  });
                  _muat();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_detail == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat surah...'),
          ],
        ),
      );
    }

    final gayaArab = QBTheme.arab(
      size: _fontAyat,
      height: 2.1,
    );

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _detail!.ayat.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _kepalaSurah(store, primer);
        final ayat = _detail!.ayat[i - 1];
        final sedangDiputar = _ayatDiputar == ayat.nomor && _memutar;
        return Card(
          key: _kunciAyat[ayat.nomor],
          color: sedangDiputar ? primer.withValues(alpha: 0.08) : null,
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nomor ayat + tombol audio
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ayat.nomor}',
                        style: TextStyle(
                          color: primer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: sedangDiputar
                          ? 'Berhenti'
                          : 'Dengarkan ayat ${ayat.nomor}',
                      icon: Icon(
                        sedangDiputar
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                        color: primer,
                      ),
                      onPressed: sedangDiputar
                          ? _berhenti
                          : () => _putarAyat(ayat.nomor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Teks Arab (dengan/s tanpa tajwid)
                RichText(
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  text: bangunTeksTajwid(
                    ayat.teksArab,
                    gayaDasar: gayaArab,
                    aktif: store.showTajwid,
                  ),
                ),
                if (store.showLatin) ...[
                  const SizedBox(height: 10),
                  Text(
                    ayat.teksLatin,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: QBColors.tintaLembut,
                        ),
                  ),
                ],
                if (store.showTerjemahan) ...[
                  const SizedBox(height: 8),
                  Text(
                    ayat.teksIndonesia,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kepalaSurah(AppStore store, Color primer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Text(
            widget.surah.namaArab,
            style: QBTheme.arab(size: 40, color: primer, height: 1.8),
            textDirection: TextDirection.rtl,
          ),
          // Kecuali At-Taubah (9), surah diawali basmalah
          if (widget.surah.nomor != 9)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u064e\u0651\u0647\u0650 \u0627\u0644\u0631\u064e\u0651\u062d\u0652\u0645\u064e\u0670\u0646\u0650 \u0627\u0644\u0631\u064e\u0651\u062d\u0650\u064a\u0645\u0650',
                style: QBTheme.arab(size: _fontAyat * 0.95, height: 2.0),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          if (store.showTajwid)
            Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final l in legendaTajwid)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: l.warna,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  void _dialogFont() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ukuran huruf Arab'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\u0628\u0650\u0633\u0652\u0645\u0650 \u0627\u0644\u0644\u064e\u0651\u0647\u0650',
                style: QBTheme.arab(size: _fontAyat),
                textDirection: TextDirection.rtl,
              ),
              Slider(
                value: _fontAyat,
                min: 20,
                max: 48,
                divisions: 14,
                label: _fontAyat.round().toString(),
                onChanged: (v) {
                  setState(() => _fontAyat = v);
                  this.setState(() {});
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
