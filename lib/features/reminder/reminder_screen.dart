// Layar pengaturan pengingat ngaji harian.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_store.dart';
import '../../core/theme.dart';
import 'reminder_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  Future<void> _pilihJam(AppStore store) async {
    final hasil = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: store.reminderHour, minute: store.reminderMinute),
    );
    if (hasil == null) return;
    await store.setReminder(store.reminderOn, hasil.hour, hasil.minute);
    await ReminderService.reschedule(store);
  }

  Future<void> _toggle(AppStore store, bool on) async {
    await store.setReminder(on, store.reminderHour, store.reminderMinute);
    await ReminderService.reschedule(store);
  }

  String _formatJam(int h, int m) {
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh.$mm';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final anak = store.mode == AppMode.anak;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengingat Ngaji')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.alarm_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    anak
                        ? 'Jangan lupa ngaji setiap hari, ya!'
                        : 'Ingatkan saya ngaji setiap hari',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Aktifkan pengingat'),
                    value: store.reminderOn,
                    onChanged: (v) => _toggle(store, v),
                  ),
                  ListTile(
                    title: const Text('Jam pengingat'),
                    trailing: Text(
                      _formatJam(store.reminderHour, store.reminderMinute),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _pilihJam(store),
                  ),
                  if (ReminderService.didukung)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: ReminderService.testNow,
                        icon: const Icon(Icons.notifications_outlined),
                        label: const Text('Tes notifikasi sekarang'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!ReminderService.didukung || kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Card(
                color: QBColors.emasMuda,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Di versi web, notifikasi sistem belum didukung. '
                    'Pengingat tetap tersimpan, dan aplikasi akan '
                    'menampilkan pengingat saat dibuka pada jam tersebut.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
