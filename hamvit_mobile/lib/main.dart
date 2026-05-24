import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_env.dart';
import 'router/app_router.dart';
import 'theme/hamvit_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppEnv.hasSupabase) {
    await Supabase.initialize(url: AppEnv.supabaseUrl, anonKey: AppEnv.supabaseAnonKey);
  }
  runApp(const ProviderScope(child: HamvitApp()));
}

class HamvitApp extends ConsumerWidget {
  const HamvitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'HAMVIT',
      debugShowCheckedModeBanner: false,
      theme: HamvitTheme.light,
      routerConfig: router,
    );
  }
}
