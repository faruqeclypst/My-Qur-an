// State global aplikasi: mode, preferensi, progres. Semua tersimpan lokal.
import 'package:flutter/foundation.dart';

import 'storage.dart';

enum AppMode { lansia, normal, anak }

extension AppModeX on AppMode {
  String get key => name;
  String get label {
    switch (this) {
      case AppMode.lansia:
        return 'Lansia';
      case AppMode.normal:
        return 'Normal';
      case AppMode.anak:
        return 'Anak';
    }
  }

  String get sapaan {
    switch (this) {
      case AppMode.lansia:
        return 'Assalamu\u2019alaikum, mari ngaji dengan tenang';
      case AppMode.normal:
        return 'Assalamu\u2019alaikum, selamat datang kembali';
      case AppMode.anak:
        return 'Hai! Ayo ngaji sambil bermain';
    }
  }
}

class LastRead {
  final int surah;
  final String namaSurah;
  final int ayat;
  final DateTime waktu;

  LastRead({
    required this.surah,
    required this.namaSurah,
    required this.ayat,
    required this.waktu,
  });

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'namaSurah': namaSurah,
        'ayat': ayat,
        'waktu': waktu.toIso8601String(),
      };

  static LastRead? fromJson(Map<String, dynamic> j) {
    try {
      return LastRead(
        surah: (j['surah'] as num).toInt(),
        namaSurah: j['namaSurah'] as String,
        ayat: (j['ayat'] as num).toInt(),
        waktu: DateTime.parse(j['waktu'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

class AppStore extends ChangeNotifier {
  bool onboarded = false;
  AppMode mode = AppMode.normal;
  String nama = '';

  double fontScale = 1.0;
  bool showTajwid = true;
  bool showLatin = true;
  bool showTerjemahan = true;
  String modeBaca = 'ayat'; // 'ayat' | 'mushaf' — pilihan tampilan halaman baca

  LastRead? lastRead;

  bool reminderOn = false;
  int reminderHour = 5;
  int reminderMinute = 0;

  int challengeStreak = 0;
  String challengeLastDate = '';
  int challengeScore = 0;
  List<String> badges = [];

  Map<String, dynamic> iqroProgress = {};
  Map<String, dynamic> kisahProgress = {};
  List<String> hijaiyahDipelajari = [];

  Future<void> load() async {
    onboarded = Storage.getBool('qb_onboarded');
    final modeKey = Storage.getString('qb_mode') ?? 'normal';
    mode = AppMode.values.firstWhere(
      (m) => m.key == modeKey,
      orElse: () => AppMode.normal,
    );
    nama = Storage.getString('qb_name') ?? '';
    fontScale = Storage.getDouble('qb_font_scale', 1.0);
    showTajwid = Storage.getBool('qb_show_tajwid', true);
    showLatin = Storage.getBool('qb_show_latin', true);
    showTerjemahan = Storage.getBool('qb_show_terjemahan', true);
    final mb = Storage.getString('qb_read_mode') ?? 'ayat';
    modeBaca = mb == 'mushaf' ? 'mushaf' : 'ayat';

    final lr = Storage.getJson('qb_last_read');
    lastRead = lr.isEmpty ? null : LastRead.fromJson(lr);

    reminderOn = Storage.getBool('qb_reminder_on');
    reminderHour = Storage.getInt('qb_reminder_hour', 5);
    reminderMinute = Storage.getInt('qb_reminder_minute');

    challengeStreak = Storage.getInt('qb_challenge_streak');
    challengeLastDate = Storage.getString('qb_challenge_last_date') ?? '';
    challengeScore = Storage.getInt('qb_challenge_score');
    badges = Storage.getStringList('qb_badges');

    iqroProgress = Storage.getJson('qb_iqro_progress');
    kisahProgress = Storage.getJson('qb_kisah_progress');
    hijaiyahDipelajari = Storage.getStringList('qb_hijaiyah');
    notifyListeners();
  }

  Future<void> completeOnboarding(AppMode m, String name) async {
    mode = m;
    nama = name.trim();
    onboarded = true;
    if (m == AppMode.lansia && fontScale < 1.3) {
      fontScale = 1.35; // default lebih besar untuk lansia
    }
    await Storage.setString('qb_mode', m.key);
    await Storage.setString('qb_name', nama);
    await Storage.setBool('qb_onboarded', true);
    await Storage.setDouble('qb_font_scale', fontScale);
    notifyListeners();
  }

  Future<void> setMode(AppMode m) async {
    mode = m;
    await Storage.setString('qb_mode', m.key);
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v.clamp(0.8, 2.2);
    await Storage.setDouble('qb_font_scale', fontScale);
    notifyListeners();
  }

  Future<void> setToggles({
    bool? tajwid,
    bool? latin,
    bool? terjemahan,
  }) async {
    if (tajwid != null) {
      showTajwid = tajwid;
      await Storage.setBool('qb_show_tajwid', tajwid);
    }
    if (latin != null) {
      showLatin = latin;
      await Storage.setBool('qb_show_latin', latin);
    }
    if (terjemahan != null) {
      showTerjemahan = terjemahan;
      await Storage.setBool('qb_show_terjemahan', terjemahan);
    }
    notifyListeners();
  }

  /// Pilihan tampilan halaman baca: 'ayat' (kartu per ayat) atau 'mushaf'
  /// (teks Arab mengalir penuh). Diingat per preferensi lokal.
  Future<void> setModeBaca(String v) async {
    modeBaca = v == 'mushaf' ? 'mushaf' : 'ayat';
    await Storage.setString('qb_read_mode', modeBaca);
    notifyListeners();
  }

  Future<void> saveLastRead(int surah, String namaSurah, int ayat) async {
    lastRead = LastRead(
      surah: surah,
      namaSurah: namaSurah,
      ayat: ayat,
      waktu: DateTime.now(),
    );
    await Storage.setJson('qb_last_read', lastRead!.toJson());
    notifyListeners();
  }

  Future<void> setReminder(bool on, int hour, int minute) async {
    reminderOn = on;
    reminderHour = hour;
    reminderMinute = minute;
    await Storage.setBool('qb_reminder_on', on);
    await Storage.setInt('qb_reminder_hour', hour);
    await Storage.setInt('qb_reminder_minute', minute);
    notifyListeners();
  }

  /// Dipanggil saat challenge harian selesai. Mengembalikan true bila streak bertambah.
  Future<bool> recordChallengeDay(int skor) async {
    final today = DateTime.now();
    final key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    challengeScore += skor;
    bool naik = false;
    if (challengeLastDate != key) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      challengeStreak = (challengeLastDate == yKey) ? challengeStreak + 1 : 1;
      challengeLastDate = key;
      naik = true;
    }
    _cekBadge();
    await Storage.setInt('qb_challenge_streak', challengeStreak);
    await Storage.setString('qb_challenge_last_date', challengeLastDate);
    await Storage.setInt('qb_challenge_score', challengeScore);
    await Storage.setStringList('qb_badges', badges);
    notifyListeners();
    return naik;
  }

  void _cekBadge() {
    void beri(String id) {
      if (!badges.contains(id)) badges.add(id);
    }

    if (challengeStreak >= 3) beri('konsisten_3');
    if (challengeStreak >= 7) beri('seminggu_penuh');
    if (challengeStreak >= 30) beri('sebulan_rajin');
    if (challengeScore >= 100) beri('skor_100');
    if (challengeScore >= 500) beri('skor_500');
  }

  Future<void> saveIqroProgress(int jilid, int halaman) async {
    final cur = (iqroProgress['j$jilid'] as num?)?.toInt() ?? 0;
    if (halaman > cur) {
      iqroProgress['j$jilid'] = halaman;
      await Storage.setJson('qb_iqro_progress', iqroProgress);
      notifyListeners();
    }
  }

  Future<void> saveKisahProgress(int nabiIndex, int episodeIndex) async {
    kisahProgress['n$nabiIndex'] = episodeIndex;
    await Storage.setJson('qb_kisah_progress', kisahProgress);
    notifyListeners();
  }

  Future<void> tandaiHijaiyah(String huruf) async {
    if (!hijaiyahDipelajari.contains(huruf)) {
      hijaiyahDipelajari = [...hijaiyahDipelajari, huruf];
      await Storage.setStringList('qb_hijaiyah', hijaiyahDipelajari);
      notifyListeners();
    }
  }

  /// Pulihkan seluruh state dari JSON tree sinkronisasi (format SyncModel).
  /// Dipakai saat login Google + Realtime Database aktif dan data remote
  /// menang (last-write-wins). Semua nilai dibaca defensif: tree yang
  /// tidak lengkap tetap bisa dipulihkan sebagian tanpa crash.
  Future<void> restoreFromSync(Map<String, dynamic> tree) async {
    Map<String, dynamic> bagian(String key) {
      final v = tree[key];
      return v is Map<String, dynamic> ? v : {};
    }

    T ambil<T>(Map<String, dynamic> m, String key, T fallback) {
      final v = m[key];
      return v is T ? v : fallback;
    }

    final profil = bagian('profile');
    final modeKey = ambil<String>(profil, 'mode', 'normal');
    mode = AppMode.values.firstWhere(
      (m) => m.key == modeKey,
      orElse: () => AppMode.normal,
    );
    nama = ambil<String>(profil, 'nama', '');
    final fs = profil['fontScale'];
    fontScale = (fs is num ? fs.toDouble() : 1.0).clamp(0.8, 2.2);

    final tampilan = bagian('tampilan');
    showTajwid = ambil<bool>(tampilan, 'tajwid', true);
    showLatin = ambil<bool>(tampilan, 'latin', true);
    showTerjemahan = ambil<bool>(tampilan, 'terjemahan', true);
    final mb = ambil<String>(tampilan, 'modeBaca', 'ayat');
    modeBaca = mb == 'mushaf' ? 'mushaf' : 'ayat';

    final lr = tree['terakhirDibaca'];
    lastRead = lr is Map<String, dynamic> ? LastRead.fromJson(lr) : null;

    final rem = bagian('reminder');
    reminderOn = ambil<bool>(rem, 'on', false);
    reminderHour = (rem['hour'] is num ? (rem['hour'] as num).toInt() : 5)
        .clamp(0, 23);
    reminderMinute = (rem['minute'] is num ? (rem['minute'] as num).toInt() : 0)
        .clamp(0, 59);

    final ch = bagian('challenge');
    challengeStreak = ch['streak'] is num ? (ch['streak'] as num).toInt() : 0;
    challengeLastDate = ambil<String>(ch, 'lastDate', '');
    challengeScore = ch['score'] is num ? (ch['score'] as num).toInt() : 0;
    final b = ch['badges'];
    badges = b is List ? [for (final x in b) '$x'] : [];

    final iq = bagian('iqro');
    iqroProgress = {
      for (var j = 1; j <= 3; j++)
        'j$j': iq['$j'] is num ? (iq['$j'] as num).toInt() : 0,
    };

    final ks = bagian('kisah');
    kisahProgress = {
      for (final e in ks.entries)
        if (e.value is num) 'n${e.key}': (e.value as num).toInt(),
    };

    final hj = tree['hijaiyah'];
    hijaiyahDipelajari = hj is List ? [for (final x in hj) '$x'] : [];

    // Persist ke penyimpanan lokal
    await Storage.setString('qb_mode', mode.key);
    await Storage.setString('qb_name', nama);
    await Storage.setDouble('qb_font_scale', fontScale);
    await Storage.setBool('qb_show_tajwid', showTajwid);
    await Storage.setBool('qb_show_latin', showLatin);
    await Storage.setBool('qb_show_terjemahan', showTerjemahan);
    await Storage.setString('qb_read_mode', modeBaca);
    if (lastRead != null) {
      await Storage.setJson('qb_last_read', lastRead!.toJson());
    } else {
      await Storage.remove('qb_last_read');
    }
    await Storage.setBool('qb_reminder_on', reminderOn);
    await Storage.setInt('qb_reminder_hour', reminderHour);
    await Storage.setInt('qb_reminder_minute', reminderMinute);
    await Storage.setInt('qb_challenge_streak', challengeStreak);
    await Storage.setString('qb_challenge_last_date', challengeLastDate);
    await Storage.setInt('qb_challenge_score', challengeScore);
    await Storage.setStringList('qb_badges', badges);
    await Storage.setJson('qb_iqro_progress', iqroProgress);
    await Storage.setJson('qb_kisah_progress', kisahProgress);
    await Storage.setStringList('qb_hijaiyah', hijaiyahDipelajari);
    notifyListeners();
  }
}
