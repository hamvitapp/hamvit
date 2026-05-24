import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_env.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppEnv.hasSupabase) return null;
  return Supabase.instance.client;
});
