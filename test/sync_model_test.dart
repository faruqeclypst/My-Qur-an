import 'package:flutter_test/flutter_test.dart';
import 'package:quranku/core/app_store.dart';
import 'package:quranku/core/storage.dart';
import 'package:quranku/core/sync_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  AppStore isiStore() {
    final s = AppStore()
      ..onboarded = true
      ..mode = AppMode.anak
      ..nama = 'Budi'
      ..fontScale = 1.2
      ..showTajwid = false
      ..showLatin = true
      ..showTerjemahan = true
      ..lastRead = LastRead(
        surah: 112,
        namaSurah: 'Al-Ikhlas',
        ayat: 3,
        waktu: DateTime.utc(2026, 10, 17, 1, 0, 0),
      )
      ..reminderOn = true
      ..reminderHour = 5
      ..reminderMinute = 30
      ..challengeStreak = 4
      ..challengeLastDate = '2026-10-17'
      ..challengeScore = 120
      ..badges = ['konsisten_3']
      ..iqroProgress = {'j1': 10, 'j2': 5}
      ..kisahProgress = {'n0': 2, 'n5': 0}
      ..hijaiyahDipelajari = ['بَ', 'تَ'];
    return s;
  }

  test('export menghasilkan tree RTDB yang valid', () {
    final tree = SyncModel.export(isiStore());

    expect(SyncModel.rtdbPath('uid123'), 'users/uid123');
    expect(tree['meta']['schema'], 1);
    expect(tree['profile']['mode'], 'anak');
    expect(tree['profile']['nama'], 'Budi');
    expect(tree['tampilan']['tajwid'], false);
    expect(tree['terakhirDibaca']['ayat'], 3);
    expect(tree['reminder']['hour'], 5);
    expect(tree['challenge']['streak'], 4);
    expect(tree['challenge']['badges'], ['konsisten_3']);
    expect(tree['iqro'], {'1': 10, '2': 5, '3': 0});
    expect(tree['kisah'], {'0': 2, '5': 0});
    expect(tree['hijaiyah'], ['بَ', 'تَ']);

    // tidak ada karakter terlarang RTDB ($, #) pada key maupun value
    final teks = tree.toString();
    expect(teks.contains(r'$'), false);
    expect(teks.contains('#'), false);
  });

  test('round-trip export -> restore identik', () async {
    final asal = isiStore();
    final tree = SyncModel.export(asal);

    final baru = AppStore();
    await baru.restoreFromSync(tree);

    expect(baru.mode, AppMode.anak);
    expect(baru.nama, 'Budi');
    expect(baru.fontScale, 1.2);
    expect(baru.showTajwid, false);
    expect(baru.lastRead?.ayat, 3);
    expect(baru.lastRead?.namaSurah, 'Al-Ikhlas');
    expect(baru.reminderOn, true);
    expect(baru.reminderHour, 5);
    expect(baru.challengeStreak, 4);
    expect(baru.challengeScore, 120);
    expect(baru.badges, ['konsisten_3']);
    expect(baru.iqroProgress['j1'], 10);
    expect(baru.iqroProgress['j3'], 0);
    expect(baru.kisahProgress['n0'], 2);
    expect(baru.kisahProgress['n5'], 0);
    expect(baru.hijaiyahDipelajari, ['بَ', 'تَ']);
  });

  test('restore tree kosong/rusak tidak crash', () async {
    final s = AppStore();
    await s.restoreFromSync({});
    expect(s.mode, AppMode.normal);
    expect(s.iqroProgress['j1'], 0);

    await s.restoreFromSync({
      'profile': {'mode': 'mode-tidak-ada'},
      'iqro': {'1': 'bukan-angka'},
    });
    expect(s.mode, AppMode.normal); // fallback aman
    expect(s.iqroProgress['j1'], 0);
  });

  test('last-write-wins berdasarkan updatedAt', () {
    final lama = {
      'meta': {'updatedAt': '2026-10-16T00:00:00.000Z'}
    };
    final baru = {
      'meta': {'updatedAt': '2026-10-17T00:00:00.000Z'}
    };
    expect(SyncModel.remoteLebihBaru(lama, baru), true);
    expect(SyncModel.remoteLebihBaru(baru, lama), false);
    expect(SyncModel.remoteLebihBaru(lama, {}), false);
  });
}
