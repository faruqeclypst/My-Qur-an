// Penanda warna tajwid berbasis aturan (tanpa data eksternal).
// Aturan yang dicakup: ikhfa, idgham bighunnah, idgham bilaghunnah, iqlab,
// idzhar, qalqalah, dan mad thabi'i. Implementasi: pemindaian rune per rune,
// lalu batas span dijepit ke batas grapheme cluster agar huruf +
// harakat/tandanya tidak pernah terpisah ke span berbeda.
import 'package:flutter/material.dart';

// Karakter Arab yang relevan
const _nun = '\u0646'; // ن
const _tanwinFathah = '\u064B'; // ً
const _tanwinKasrah = '\u064D'; // ٍ
const _tanwinDhammah = '\u064C'; // ٌ
const _mim = '\u0645'; // م
const _ba = '\u0628'; // ب
const _sukun = '\u0652'; // ْ
const _syaddah = '\u0651'; // ّ

const _hurufIkhfa = {
  '\u062a', '\u062b', '\u062c', '\u062f', '\u0630', '\u0632',
  '\u0633', '\u0634', '\u0635', '\u0636', '\u0637', '\u0638',
  '\u0641', '\u0642', '\u0643',
}; // ت ث ج د ذ ز س ش ص ض ط ظ ف ق ك
const _hurufIdghamGhunnah = {'\u064a', '\u0646', '\u0645', '\u0648'}; // ي ن م و
const _hurufIdghamBila = {'\u0644', '\u0631'}; // ل ر
const _hurufQalqalah = {
  '\u0642', '\u0637', '\u0628', '\u062c', '\u062f'
}; // ق ط ب ج د

// Palet tajwid: dibatasi 5 warna agar tidak ramai (R-29)
class TajwidColors {
  static const ikhfa = Color(0xFFB7791F); // cokelat keemasan
  static const idgham = Color(0xFF1B7F5A); // hijau
  static const iqlab = Color(0xFF7C4DFF); // ungu lembut (satu-satunya)
  static const qalqalah = Color(0xFFC0392B); // merah bata
  static const mad = Color(0xFF1565C0); // biru
}

class TajwidSpan {
  final int start; // indeks rune mulai
  final int end; // indeks rune selesai (eksklusif)
  final Color warna;
  final String label;
  const TajwidSpan(this.start, this.end, this.warna, this.label);
}

bool _isTanwin(String ch) =>
    ch == _tanwinFathah || ch == _tanwinKasrah || ch == _tanwinDhammah;

bool _isHuruf(String ch) {
  final c = ch.codeUnitAt(0);
  return c >= 0x0627 && c <= 0x064A; // rentang huruf hijaiyah dasar
}

/// Tanda diakritik Arab (harakat, tanwin, sukun, syaddah, tanda waqaf kecil)
/// yang secara tipografi menempel pada huruf induknya. Batas pewarnaan
/// tajwid tidak boleh memotong di tengah kelompok ini.
bool _isTandaDiakritik(int rune) {
  return (rune >= 0x064B && rune <= 0x0655) || // ً-ٟ (harakat/tanwin/syaddah/sukun)
      rune == 0x0670 || // superscript alef
      (rune >= 0x06D6 && rune <= 0x06DC) || // tanda waqaf kecil
      (rune >= 0x06DF && rune <= 0x06E4) ||
      (rune >= 0x06E7 && rune <= 0x06E8) ||
      (rune >= 0x06EA && rune <= 0x06ED);
}

/// Pindai [teks] dan kembalikan daftar rentang tajwid (indeks dalam rune).
List<TajwidSpan> tandaiTajwid(String teks) {
  final runes = teks.runes.toList();
  final spans = <TajwidSpan>[];

  String charAt(int i) =>
      (i >= 0 && i < runes.length) ? String.fromCharCode(runes[i]) : '';

  // Huruf berikutnya yang bukan harakat/tanda baca
  int nextHuruf(int i) {
    var j = i + 1;
    while (j < runes.length && !_isHuruf(charAt(j))) {
      j++;
    }
    return j;
  }

  for (var i = 0; i < runes.length; i++) {
    final ch = charAt(i);

    // --- Nun mati (نْ) atau tanwin ---
    final isNunMati = ch == _nun && charAt(i + 1) == _sukun;
    final isTanwin = _isTanwin(ch);
    if (isNunMati || isTanwin) {
      final j = nextHuruf(isNunMati ? i + 1 : i);
      if (j < runes.length) {
        final berikut = charAt(j);
        final akhirNun = isNunMati ? i + 2 : i + 1;
        if (berikut == _ba) {
          spans.add(TajwidSpan(i, akhirNun, TajwidColors.iqlab, 'Iqlab'));
        } else if (_hurufIdghamGhunnah.contains(berikut)) {
          spans.add(TajwidSpan(
              i, akhirNun, TajwidColors.idgham, 'Idgham Bighunnah'));
        } else if (_hurufIdghamBila.contains(berikut)) {
          spans.add(TajwidSpan(
              i, akhirNun, TajwidColors.idgham, 'Idgham Bilaghunnah'));
        } else if (_hurufIkhfa.contains(berikut)) {
          spans.add(TajwidSpan(i, akhirNun, TajwidColors.ikhfa, 'Ikhfa'));
        }
        // Idzhar: nun/tanwin dibaca jelas, tidak diwarnai (default)
      }
      continue;
    }

    // --- Mim mati (مْ) ---
    if (ch == _mim && charAt(i + 1) == _sukun) {
      final j = nextHuruf(i + 1);
      if (j < runes.length) {
        final berikut = charAt(j);
        if (berikut == _mim) {
          spans.add(TajwidSpan(
              i, i + 2, TajwidColors.idgham, 'Idgham Mimi'));
        } else if (berikut == _ba) {
          spans.add(
              TajwidSpan(i, i + 2, TajwidColors.ikhfa, 'Ikhfa Syafawi'));
        }
      }
      continue;
    }

    // --- Qalqalah: huruf qalqalah bersukun ---
    if (_hurufQalqalah.contains(ch) && charAt(i + 1) == _sukun) {
      spans.add(TajwidSpan(i, i + 2, TajwidColors.qalqalah, 'Qalqalah'));
      continue;
    }

    // --- Mad thabi'i: fathah+alif, kasrah+ya, dhammah+wau ---
    if (_isHuruf(ch)) {
      final h1 = charAt(i + 1);
      final h2 = charAt(i + 2);
      if ((h1 == '\u064E' && h2 == '\u0627') || // fathah + alif
          (h1 == '\u0650' && h2 == '\u064A') || // kasrah + ya
          (h1 == '\u064F' && h2 == '\u0648')) // dhammah + wau
      {
        // Abaikan bila ada syaddah setelahnya (bukan mad thabi'i murni)
        if (charAt(i + 3) != _syaddah) {
          spans.add(TajwidSpan(i, i + 3, TajwidColors.mad, 'Mad Thabi\u2019i'));
        }
      }
    }
  }
  return spans;
}

/// Bangun TextSpan Arab dengan warna tajwid. [warnaDasar] untuk teks biasa.
///
/// Jaminan tipografi: teks disegmentasi per grapheme cluster (huruf +
/// harakat/tandanya selalu satu paket), dan span berwarna HANYA mengubah
/// warna — tidak mengubah fontSize, fontFamily, maupun fontWeight. Amiri
/// Quran hanya punya satu weight; weight berbeda memicu font fallback
/// sistem yang merusak posisi harakat.
TextSpan bangunTeksTajwid(
  String teks, {
  required TextStyle gayaDasar,
  bool aktif = true,
}) {
  if (!aktif) {
    return TextSpan(text: teks, style: gayaDasar);
  }
  final runes = teks.runes.toList();
  if (runes.isEmpty) {
    return TextSpan(text: teks, style: gayaDasar);
  }
  final spans = tandaiTajwid(teks);
  if (spans.isEmpty) {
    return TextSpan(text: teks, style: gayaDasar);
  }

  // Jepit batas setiap span ke batas grapheme cluster: bila batas jatuh
  // di tengah huruf + tanda diakritiknya, geser hingga satu cluster utuh
  // masuk ke span yang sama.
  final dijepit = spans.map((s) {
    var start = s.start;
    var end = s.end;
    while (start > 0 && _isTandaDiakritik(runes[start])) {
      start--;
    }
    while (end < runes.length && _isTandaDiakritik(runes[end])) {
      end++;
    }
    return TajwidSpan(start, end, s.warna, s.label);
  }).toList();

  // Tandai rune mana yang berwarna
  final warnaPerRune = List<Color?>.filled(runes.length, null);
  for (final s in dijepit) {
    for (var i = s.start; i < s.end && i < runes.length; i++) {
      warnaPerRune[i] ??= s.warna;
    }
  }

  // Bangun span per grapheme cluster: tidak ada cluster yang terbelah,
  // dan cluster yang berdekatan dengan warna sama digabung.
  final children = <TextSpan>[];
  String? berjalan;
  Color? warnaBerjalan;

  void siram() {
    if (berjalan == null) return;
    children.add(
      TextSpan(
        text: berjalan,
        style: warnaBerjalan == null
            ? gayaDasar
            : gayaDasar.copyWith(color: warnaBerjalan),
      ),
    );
    berjalan = null;
  }

  var idxRune = 0;
  for (final cluster in teks.characters) {
    final jumlahRune = cluster.runes.length;
    // Setelah dijepit, seluruh rune dalam satu cluster selalu seragam.
    Color? w;
    for (var k = idxRune; k < idxRune + jumlahRune; k++) {
      w ??= warnaPerRune[k];
    }
    if (w != warnaBerjalan) {
      siram();
      warnaBerjalan = w;
      berjalan = cluster;
    } else {
      berjalan = (berjalan ?? '') + cluster;
    }
    idxRune += jumlahRune;
  }
  siram();

  return TextSpan(children: children, style: gayaDasar);
}

/// Legenda warna tajwid untuk ditampilkan di bawah teks.
List<TajwidLegenda> legendaTajwid = const [
  TajwidLegenda('Ikhfa', TajwidColors.ikhfa),
  TajwidLegenda('Idgham', TajwidColors.idgham),
  TajwidLegenda('Iqlab', TajwidColors.iqlab),
  TajwidLegenda('Qalqalah', TajwidColors.qalqalah),
  TajwidLegenda('Mad', TajwidColors.mad),
];

class TajwidLegenda {
  final String label;
  final Color warna;
  const TajwidLegenda(this.label, this.warna);
}
