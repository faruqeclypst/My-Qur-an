// Halaman baca per surah: teks Arab + latin + terjemahan,
// audio per ayat & full surah, slider font, toggle tajwid, auto-simpan terakhir dibaca.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/dekorasi.dart';
import '../../core/theme.dart';
import 'quran_api.dart';
import 'tajwid.dart';

class ReaderScreen extends StatefulWidget {
  final Surah surah;
  final int ayatAwal; // untuk "lanjutkan" dari terakhir dibaca
  final bool autoplay; // putar seluruh surah otomatis (dipakai saat lanjut dari surah sebelumnya)
  const ReaderScreen(
      {super.key, required this.surah, this.ayatAwal = 1, this.autoplay = false});

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
        final modePenuh = _putarSemua;
        setState(() {
          _putarSemua = false;
          _ayatDiputar = null;
        });
        // Selesai memutar seluruh surah -> otomatis lanjut ke surah
        // berikutnya (kecuali An-Nas, surah terakhir: berhenti normal).
        if (modePenuh) _lanjutSurahBerikutnya();
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
        // Auto-scroll hanya di mode per-ayat (di mode mushaf tidak ada
        // GlobalKey per ayat karena teksnya mengalir utuh).
        if (context.read<AppStore>().modeBaca == 'ayat') {
          _keAyat(ayat.nomor);
        }
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
      // Autoplay: dipakai saat otomatis lanjut dari surah sebelumnya.
      if (widget.autoplay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _putarSeluruhSurah();
        });
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

  /// Putar audio ayat sebelumnya (dalam surah yang sama).
  Future<void> _ayatSebelumnya() async {
    if (_detail == null) return;
    final saatIni = _ayatDiputar ?? 1;
    if (saatIni > 1) await _putarAyat(saatIni - 1);
  }

  /// Putar audio ayat berikutnya (dalam surah yang sama).
  Future<void> _ayatBerikutnya() async {
    if (_detail == null) return;
    final saatIni = _ayatDiputar ?? 0;
    if (saatIni < _detail!.ayat.length) await _putarAyat(saatIni + 1);
  }

  /// Otomatis lanjut ke surah berikutnya saat putar-seluruh-surah selesai.
  /// Tampilan reader ikut berpindah dan langsung memutar dari ayat 1.
  /// Di surah terakhir (An-Nas, 114) berhenti normal.
  Future<void> _lanjutSurahBerikutnya() async {
    if (widget.surah.nomor >= 114) return;
    try {
      final daftar = await QuranApi.daftarSurah();
      final berikutnya =
          daftar.firstWhere((s) => s.nomor == widget.surah.nomor + 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lanjut ke ${berikutnya.namaLatin}...'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReaderScreen(surah: berikutnya, autoplay: true),
        ),
      );
    } catch (_) {
      // Gagal memuat daftar surah: berhenti normal, tidak mengganggu user.
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
          // Toggle tanda warna tajwid: berlaku di mode Per Ayat MAUPUN
          // Mushaf; pilihan tersimpan di preferensi lokal (qb_show_tajwid).
          IconButton(
            tooltip: store.showTajwid
                ? 'Tanda warna tajwid: aktif'
                : 'Tanda warna tajwid: nonaktif',
            icon: Icon(
              Icons.format_color_text,
              color: store.showTajwid
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
            ),
            onPressed: () =>
                store.setToggles(tajwid: !store.showTajwid),
          ),
        ],
        // Toggle Per Ayat / Mushaf: di AppBar agar mudah dijangkau ibu jari.
        // Pilihan diingat di preferensi lokal (AppStore.modeBaca).
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor:
                    Colors.white.withValues(alpha: 0.25),
                foregroundColor: Colors.white.withValues(alpha: 0.8),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: 'ayat',
                  icon: Icon(Icons.view_agenda_outlined, size: 18),
                  label: Text('Per Ayat'),
                ),
                ButtonSegment(
                  value: 'mushaf',
                  icon: Icon(Icons.menu_book_outlined, size: 18),
                  label: Text('Mushaf'),
                ),
              ],
              selected: {store.modeBaca},
              onSelectionChanged: (v) =>
                  context.read<AppStore>().setModeBaca(v.first),
            ),
          ),
        ),
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
                                : store.modeBaca == 'mushaf'
                                    ? 'Ketuk ikon putar di atas untuk audio seluruh surah'
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
                    // Navigasi audio per ayat: berlaku di mode Per Ayat
                    // maupun Mushaf. Menekan salah satunya beralih dari
                    // mode putar-seluruh-surah ke putar ayat satuan.
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      tooltip: 'Ayat sebelumnya',
                      onPressed: (_ayatDiputar ?? 1) > 1
                          ? _ayatSebelumnya
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      tooltip: 'Ayat berikutnya',
                      onPressed: (_ayatDiputar ?? 0) < _detail!.ayat.length
                          ? _ayatBerikutnya
                          : null,
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

    // Cabang tampilan: kartu per ayat, atau teks mengalir ala mushaf.
    if (store.modeBaca == 'mushaf') {
      return _tampilanMushaf(store, primer, gayaArab);
    }
    return _tampilanPerAyat(store, gayaArab, primer);
  }

  /// Mode Mushaf: seluruh teks Arab satu surah mengalir utuh seperti mushaf
  /// cetak. Tanpa kartu per ayat, tanpa latin, tanpa terjemahan. Tiap akhir
  /// ayat diberi penanda nomor (angka Arab dalam kurung ornamen ﴿﴾) sebagai
  /// TextSpan murni — tanpa WidgetSpan agar aliran teks RTL tidak rusak.
  /// Pewarnaan tajwid, ukuran font, dan audio full surah tetap didukung.
  Widget _tampilanMushaf(AppStore store, Color primer, TextStyle gayaArab) {
    final gayaMushaf = gayaArab.copyWith(height: 2.35);
    final gayaPenanda = gayaMushaf.copyWith(color: primer);
    final children = <InlineSpan>[];
    for (final ayat in _detail!.ayat) {
      final span = bangunTeksTajwid(
        ayat.teksArab,
        gayaDasar: gayaMushaf,
        aktif: store.showTajwid,
      );
      final isi = span.children;
      if (isi != null && isi.isNotEmpty) {
        children.addAll(isi);
      } else {
        children.add(TextSpan(text: ayat.teksArab, style: gayaMushaf));
      }
      children.add(
        TextSpan(
          text: ' \uFD3F${_angkaArab(ayat.nomor)}\uFD3E ',
          style: gayaPenanda,
        ),
      );
    }

    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        children: [
          _kepalaSurah(store, primer),
          BingkaiMushaf(
            warnaGaris: primer,
            child: RichText(
              // Rata kanan natural (bukan justify): spasi antar kata tetap
              // wajar walau ukuran huruf dibesarkan — seperti mushaf cetak.
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              text: TextSpan(children: children, style: gayaMushaf),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Mode Mushaf: seluruh surah dalam satu bacaan mengalir',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: QBColors.tintaLembut,
                ),
          ),
        ],
      ),
    );
  }

  /// Ubah angka Latin menjadi angka Arab-Indonesia (٠١٢٣٤٥٦٧٨٩)
  /// untuk penanda akhir ayat.
  String _angkaArab(int n) {
    const digit = [
      '\u0660',
      '\u0661',
      '\u0662',
      '\u0663',
      '\u0664',
      '\u0665',
      '\u0666',
      '\u0667',
      '\u0668',
      '\u0669'
    ];
    return n.toString().split('').map((c) => digit[int.parse(c)]).join();
  }

  Widget _tampilanPerAyat(AppStore store, TextStyle gayaArab, Color primer) {
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
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nomor ayat (medali segi delapan, konsisten dengan daftar
                // surah) + tombol audio yang jelas.
                Row(
                  children: [
                    MedaliNomor(nomor: ayat.nomor, ukuran: 40),
                    const SizedBox(width: 10),
                    Text(
                      'Ayat ${ayat.nomor}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: sedangDiputar
                          ? _berhenti
                          : () => _putarAyat(ayat.nomor),
                      icon: Icon(
                        sedangDiputar ? Icons.stop : Icons.play_arrow,
                        size: 18,
                      ),
                      label: Text(sedangDiputar ? 'Berhenti' : 'Dengar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Teks Arab yang lega (dengan/tanpa tanda warna tajwid)
                RichText(
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  text: bangunTeksTajwid(
                    ayat.teksArab,
                    gayaDasar: gayaArab.copyWith(height: 2.3),
                    aktif: store.showTajwid,
                  ),
                ),
                if (store.showLatin) ...[
                  const SizedBox(height: 12),
                  Text(
                    ayat.teksLatin,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: QBColors.tintaLembut,
                          height: 1.6,
                        ),
                  ),
                ],
                if (store.showTerjemahan) ...[
                  const SizedBox(height: 12),
                  Divider(color: primer.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 12),
                  Text(
                    ayat.teksIndonesia,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.7,
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
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: PembatasOrnamen(
              warna: primer.withValues(alpha: 0.3),
            ),
          ),
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
