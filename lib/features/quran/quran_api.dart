// Klien API equran.ninja v2 + cache lokal (hemat kuota).
// Parsing dibuat defensif: beberapa bentuk respons tetap bisa dibaca.
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/storage.dart';

class Surah {
  final int nomor;
  final String namaArab;
  final String namaLatin;
  final int jumlahAyat;
  final String tempatTurun;
  final String arti;

  Surah({
    required this.nomor,
    required this.namaArab,
    required this.namaLatin,
    required this.jumlahAyat,
    required this.tempatTurun,
    required this.arti,
  });

  factory Surah.fromJson(Map<String, dynamic> j) {
    return Surah(
      nomor: _toInt(j['nomor']),
      namaArab: '${j['nama'] ?? ''}',
      namaLatin: '${j['namaLatin'] ?? j['nama_latin'] ?? ''}',
      jumlahAyat: _toInt(j['jumlahAyat'] ?? j['jumlah_ayat']),
      tempatTurun: '${j['tempatTurun'] ?? j['tempat_turun'] ?? ''}',
      arti: '${j['arti'] ?? ''}',
    );
  }
}

class Ayat {
  final int nomor;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;
  final String audioUrl;

  Ayat({
    required this.nomor,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    required this.audioUrl,
  });

  factory Ayat.fromJson(Map<String, dynamic> j) {
    return Ayat(
      nomor: _toInt(j['nomorAyat'] ?? j['nomor_ayat'] ?? j['nomor']),
      teksArab: '${j['teksArab'] ?? j['teks_arab'] ?? ''}',
      teksLatin: '${j['teksLatin'] ?? j['teks_latin'] ?? ''}',
      teksIndonesia:
          '${j['teksIndonesia'] ?? j['teks_indonesia'] ?? ''}',
      audioUrl: _audioDari(j['audio']),
    );
  }

  static String _audioDari(dynamic audio) {
    if (audio == null) return '';
    if (audio is String) return audio;
    if (audio is Map) {
      // Preferensi qari: 05 = Misyari Rasyid Al-Afasi (paling umum), lalu 01
      for (final k in ['05', '01', 'primer', 'primary', 'sekunder', 'secondary']) {
        final v = audio[k];
        if (v is String && v.isNotEmpty) return v;
      }
      for (final v in audio.values) {
        if (v is String && v.isNotEmpty) return v;
      }
    }
    return '';
  }
}

int _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class QuranApi {
  static const _base = 'https://equran.ninja/api/v2';

  /// Daftar 114 surah. Coba cache dulu, lalu jaringan.
  static Future<List<Surah>> daftarSurah({bool paksaRefresh = false}) async {
    const key = 'qb_cache_surah_list';
    if (!paksaRefresh) {
      final cached = Storage.getString(key);
      if (cached != null && cached.isNotEmpty) {
        try {
          final list = (jsonDecode(cached) as List)
              .map((e) => Surah.fromJson(e as Map<String, dynamic>))
              .toList();
          if (list.length >= 100) return list;
        } catch (_) {}
      }
    }
    final res = await http.get(Uri.parse('$_base/surat'));
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat daftar surah (${res.statusCode})');
    }
    final data = _ambilData(jsonDecode(res.body));
    final list = (data as List)
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList();
    await Storage.setString(key, jsonEncode(data));
    return list;
  }

  /// Isi satu surah: daftar ayat + info surah.
  static Future<SurahDetail> detailSurah(int nomor,
      {bool paksaRefresh = false}) async {
    final key = 'qb_cache_surah_$nomor';
    if (!paksaRefresh) {
      final cached = Storage.getString(key);
      if (cached != null && cached.isNotEmpty) {
        try {
          return SurahDetail.fromJson(
              jsonDecode(cached) as Map<String, dynamic>);
        } catch (_) {}
      }
    }
    final res = await http.get(Uri.parse('$_base/surat/$nomor'));
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat surah $nomor (${res.statusCode})');
    }
    final data =
        _ambilData(jsonDecode(res.body)) as Map<String, dynamic>;
    await Storage.setString(key, jsonEncode(data));
    return SurahDetail.fromJson(data);
  }

  /// Bersihkan semua cache surah.
  static Future<void> bersihkanCache() async {
    await Storage.remove('qb_cache_surah_list');
    for (var i = 1; i <= 114; i++) {
      await Storage.remove('qb_cache_surah_$i');
    }
  }

  static dynamic _ambilData(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }
}

class SurahDetail {
  final Surah info;
  final List<Ayat> ayat;

  SurahDetail({required this.info, required this.ayat});

  factory SurahDetail.fromJson(Map<String, dynamic> j) {
    final ayatList = (j['ayat'] as List? ?? [])
        .map((e) => Ayat.fromJson(e as Map<String, dynamic>))
        .toList();
    return SurahDetail(info: Surah.fromJson(j), ayat: ayatList);
  }
}
