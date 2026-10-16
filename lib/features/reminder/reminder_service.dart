// Pengingat ngaji harian via notifikasi lokal (Android/iOS).
// Di web tidak didukung: pemanggil harus menampilkan fallback dalam aplikasi.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/app_store.dart';

class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _siap = false;

  static bool get didukung => !kIsWeb;

  static Future<void> init() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    _siap = true;
  }

  static Future<void> reschedule(AppStore store) async {
    if (!_siap || kIsWeb) return;
    await _plugin.cancel(1001);
    if (!store.reminderOn) return;
    try {
      final jakarta = tz.getLocation('Asia/Jakarta');
      final now = tz.TZDateTime.now(jakarta);
      var jadwal = tz.TZDateTime(
        jakarta,
        now.year,
        now.month,
        now.day,
        store.reminderHour,
        store.reminderMinute,
      );
      if (jadwal.isBefore(now)) {
        jadwal = jadwal.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        1001,
        'Waktunya ngaji',
        'Luangkan waktu sejenak untuk membaca Al-Quran.',
        jadwal,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ngaji_harian',
            'Pengingat Ngaji',
            channelDescription: 'Pengingat harian untuk membaca Al-Quran',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Penjadwalan gagal: jangan crash, pengguna tetap bisa pakai pengingat dalam aplikasi
    }
  }

  static Future<void> testNow() async {
    if (!_siap || kIsWeb) return;
    try {
      await _plugin.show(
        1002,
        'Quranku',
        'Ini contoh pengingat ngaji.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ngaji_harian',
            'Pengingat Ngaji',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (_) {}
  }
}
