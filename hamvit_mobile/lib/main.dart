import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_env.dart';
import 'features/privacy/app_blur_overlay.dart';
import 'features/privacy/privacy_protection_service.dart';
import 'features/security/biometric_lock_screen.dart';
import 'features/security/biometric_settings_provider.dart';
import 'router/app_router.dart';
import 'theme/hamvit_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppEnv.hasSupabase) {
    await Supabase.initialize(url: AppEnv.supabaseUrl, anonKey: AppEnv.supabaseAnonKey);
  }
  runApp(const ProviderScope(child: HamvitApp()));
}

class HamvitApp extends ConsumerStatefulWidget {
  const HamvitApp({super.key});

  @override
  ConsumerState<HamvitApp> createState() => _HamvitAppState();
}

class _HamvitAppState extends ConsumerState<HamvitApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(privacyProtectionServiceProvider).ensureInitialized(),
    );
    Future.microtask(
      () => ref.read(biometricAppLockControllerProvider).ensureInitialized(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'HAMVIT',
      debugShowCheckedModeBanner: false,
      theme: HamvitTheme.light,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      builder: (context, child) {
        return HamvitBiometricAppLockOverlay(
          child: HamvitAppBlurOverlay(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
