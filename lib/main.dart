import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'features/notifications/push_notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'motion/app_motion.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PushNotificationService.instance.initialize();
  await Supabase.initialize(
    url: 'https://srfldjfrzmtnlabusssq.supabase.co',
    anonKey: 'sb_publishable_UW2Wzzp8Y-KKd82nZHQUKA_RGl876RB',
  );
  AppMotion.personality = MotionPersonality.calm;
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUi);
  runApp(const ProviderScope(child: FlutterGoApp()));
}

class FlutterGoApp extends ConsumerWidget {
  const FlutterGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemUi,
      child: MaterialApp.router(
        title: 'Alishams DS',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: AppTheme.defaultMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => AppTheme.withSystemUi(context, child!),
        locale: const Locale('fa'),
        supportedLocales: const [
          Locale('fa'),
          Locale('en'),
          Locale('ar'),
          Locale('ur'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
      ),
    );
  }
}
