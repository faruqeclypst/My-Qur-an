// Quranku: teman ngaji harian untuk lansia, dewasa, dan anak.
// Tanpa login wajib, tanpa backend. Semua data tersimpan di perangkat.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_store.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reminder/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final store = AppStore();
  await store.load();
  if (!kIsWeb) {
    await ReminderService.init();
    await ReminderService.reschedule(store);
  }
  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const QurankuApp(),
    ),
  );
}

class QurankuApp extends StatelessWidget {
  const QurankuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return MaterialApp(
      title: 'Quranku',
      debugShowCheckedModeBanner: false,
      theme: QBTheme.forMode(store.mode, store.fontScale),
      home: store.onboarded ? const HomeScreen() : const OnboardingScreen(),
      builder: (context, child) {
        // Pastikan teks Arab selalu punya arah RTL yang benar di seluruh app
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
