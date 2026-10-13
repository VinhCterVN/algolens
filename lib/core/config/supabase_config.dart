import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL']?.trim() ?? '';

  static String get publishableKey => dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';
  static const redirectUrl = 'io.algolens.app://auth/callback';

  static Future<void> load() => dotenv.load(fileName: '.env');

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;

  static void validate() {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty || uri.scheme != 'https') {
      throw const FormatException('Use an HTTPS Supabase project URL.');
    }
    if (publishableKey.startsWith('sb_secret_')) {
      throw const FormatException('Only a publishable or legacy anon key is allowed.');
    }
    if (publishableKey.startsWith('eyJ')) {
      final parts = publishableKey.split('.');
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      if (payload['role'] != 'anon') {
        throw const FormatException('Only a legacy anon key is allowed.');
      }
    } else if (!publishableKey.startsWith('sb_publishable_')) {
      throw const FormatException('Invalid publishable key.');
    }
  }
}
