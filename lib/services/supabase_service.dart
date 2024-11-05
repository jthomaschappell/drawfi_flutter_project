import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static SupabaseClient? _instance;
  late final Supabase _supabase;

  SupabaseClient._() {
    _supabase = Supabase.instance;
  }

  static Future<SupabaseClient> init() async {
    if (_instance == null) {
      await dotenv.load();
      await Supabase.initialize(
        url: dotenv.env['https://your-supabase-url.supabase.co']!,
        anonKey: dotenv.env[
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwbmRha3BxY2lqa2dkY2ljYWZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA1ODI1NzEsImV4cCI6MjA0NjE1ODU3MX0.1xdfqEE64YgUbGMWWJue2iCvlRhgvzHwii8sNxNB2_o']!,
      );
      _instance = SupabaseClient._();
    }
    return _instance!;
  }

  static SupabaseClient get instance {
    if (_instance == null) {
      throw Exception('SupabaseClient not initialized. Call init() first.');
    }
    return _instance!;
  }

  Supabase get client => _supabase;
}
