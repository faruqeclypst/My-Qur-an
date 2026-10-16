// Model sinkronisasi cloud: memetakan seluruh state lokal ke struktur
// JSON tree Firebase Realtime Database.
//
// Struktur tree (ditulis ke path `users/{uid}`):
//
//   users/{uid}/
//     meta:          { updatedAt, appVersion, schema }
//     profile:       { mode, nama, fontScale }
//     tampilan:      { tajwid, latin, terjemahan }
//     terakhirDibaca:{ surah, namaSurah, ayat, waktu }   (opsional)
//     reminder:      { on, hour, minute }
//     challenge:     { streak, lastDate, score, badges: [...] }
//     iqro:          { "1": halaman, "2": halaman, "3": halaman }
//     kisah:         { "0": episodeIdx, ... }   (hanya nabi yg pernah dibaca)
//     hijaiyah:      [ "بَ", "تَ", ... ]
//
// Aturan main (didokumentasikan agar implementasi Firebase nanti tinggal colok):
// - Satu dokumen per user, key datar (RTDB tidak suka nesting dalam).
// - Tidak ada karakter terlarang RTDB (`.`, `$`, `#`, `[`, `]`, `/`) pada key.
// - Strategi konflik: last-write-wins berdasarkan `meta.updatedAt`.
//   Saat login di perangkat baru: unduh tree, yang `updatedAt`-nya lebih baru
//   menang; perangkat lama mengunggah bila lokalnya lebih baru.
// - Tanpa login: semua fungsi ini tidak dipakai, aplikasi tetap lokal penuh.
import 'app_store.dart';

class SyncModel {
  static const int schemaVersion = 1;
  static const String appVersion = '1.0.0';

  /// Path RTDB untuk satu pengguna.
  static String rtdbPath(String uid) => 'users/$uid';

  /// Ekspor seluruh state lokal menjadi JSON tree siap tulis ke RTDB.
  static Map<String, dynamic> export(AppStore s) {
    final tree = <String, dynamic>{
      'meta': {
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'appVersion': appVersion,
        'schema': schemaVersion,
      },
      'profile': {
        'mode': s.mode.key,
        'nama': s.nama,
        'fontScale': s.fontScale,
      },
      'tampilan': {
        'tajwid': s.showTajwid,
        'latin': s.showLatin,
        'terjemahan': s.showTerjemahan,
      },
      'reminder': {
        'on': s.reminderOn,
        'hour': s.reminderHour,
        'minute': s.reminderMinute,
      },
      'challenge': {
        'streak': s.challengeStreak,
        'lastDate': s.challengeLastDate,
        'score': s.challengeScore,
        'badges': s.badges,
      },
      'iqro': {
        for (var j = 1; j <= 3; j++) '$j': (s.iqroProgress['j$j'] as num?)?.toInt() ?? 0,
      },
      'kisah': {
        // kunci lokal 'n5' -> kunci tree '5' (tanpa prefix, tanpa karakter khusus)
        for (final e in s.kisahProgress.entries)
          e.key.replaceFirst(RegExp(r'^n'), ''): (e.value as num).toInt(),
      },
      'hijaiyah': s.hijaiyahDipelajari,
    };
    if (s.lastRead != null) {
      tree['terakhirDibaca'] = s.lastRead!.toJson();
    }
    return tree;
  }

  /// Ambil `updatedAt` dari sebuah tree (untuk perbandingan last-write-wins).
  /// Mengembalikan null bila tidak ada / tidak valid.
  static DateTime? updatedAtOf(Map<String, dynamic> tree) {
    try {
      final meta = tree['meta'];
      if (meta is Map) {
        final raw = meta['updatedAt'];
        if (raw is String) return DateTime.parse(raw);
      }
    } catch (_) {}
    return null;
  }

  /// true bila [remote] lebih baru dari [local] (berdasarkan meta.updatedAt).
  static bool remoteLebihBaru(
      Map<String, dynamic> local, Map<String, dynamic> remote) {
    final l = updatedAtOf(local);
    final r = updatedAtOf(remote);
    if (r == null) return false;
    if (l == null) return true;
    return r.isAfter(l);
  }
}
