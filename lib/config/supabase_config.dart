/// إعدادات الاتصال بـ Supabase
///
/// ⚠️ بعد إنشاء مشروعك على supabase.com:
/// 1. افتح Project Settings → API
/// 2. انسخ Project URL و anon public key
/// 3. الصقهما هنا مكان القيم الافتراضية
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL'; // مثال: https://xxxx.supabase.co
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';

  /// هل تم ضبط الإعدادات؟
  static bool get isConfigured =>
      !url.contains('YOUR_') && !anonKey.contains('YOUR_');
}
