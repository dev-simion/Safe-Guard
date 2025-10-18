import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    const supabaseUrl = String.fromEnvironment('https://xyipwzrftoipayfxrmcy.supabase.co');
    const supabaseKey = String.fromEnvironment('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5aXB3enJmdG9pcGF5ZnhybWN5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA3Mzg3MjcsImV4cCI6MjA3NjMxNDcyN30.aGj7zXs490ViP6VK0tP3hFhEkxgmEEFQ8VuWbJA2SjQ');
    
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception('Supabase credentials not configured');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized');
    }
    return _client!;
  }

  static bool get isInitialized => _client != null;
}
