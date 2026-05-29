import 'package:flutter/foundation.dart';

class AppEnv {
  static const _definedSupabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const _definedSupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static String get supabaseUrl => _definedSupabaseUrl;

  static String get supabaseAnonKey => _definedSupabaseAnonKey;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
