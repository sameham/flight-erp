/// إعدادات الاتصال بـ Supabase
class SupabaseConfig {
  static const String url = 'https://ifsqkwunlxeyewszdmct.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlmc3Frd3VubHhleWV3c3pkbWN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4ODIyNzYsImV4cCI6MjA5NjQ1ODI3Nn0.2McHVCv0ZWSP1Wl2meXFATjWycMYcFCo-vcZdIwPPWg';

  static bool get isConfigured =>
      !url.contains('YOUR_') && !anonKey.contains('YOUR_');
}
