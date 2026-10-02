import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  // Background audio + Android media notification.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ayatquran.audio',
    androidNotificationChannelName: 'تشغيل القرآن',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: false,
    androidNotificationClickStartsActivity: true,
    androidNotificationIcon: 'drawable/ic_stat_quran',
  );
  runApp(const ProviderScope(child: AyatQuranApp()));
}

class AyatQuranApp extends ConsumerWidget {
  const AyatQuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'آيات القرآن | Ayat Quran',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      themeAnimationDuration: const Duration(milliseconds: 350),
      home: const MainShell(),
    );
  }
}
