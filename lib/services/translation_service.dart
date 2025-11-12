
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

class TranslationService {
  // ⚠️ SECURITY WARNING: This API key is exposed. Please secure it properly!
  // NOTE: This key should be secured in a real application.
  static const String _apiKey = 'AIzaSyBbRSbC0gSqwbS7OioIDOqNW_3Tp-H7_co';

  // Cache for translated texts to avoid repeated API calls
  static final Map<String, String> _translationCache = {};

  // Indian languages list + English and French
  static const List<Map<String, String>> indianLanguages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'French', 'code': 'fr'},
    {'name': 'Hindi', 'code': 'hi'},
    {'name': 'Bengali', 'code': 'bn'},
    {'name': 'Telugu', 'code': 'te'},
    {'name': 'Marathi', 'code': 'mr'},
    {'name': 'Tamil', 'code': 'ta'},
    {'name': 'Gujarati', 'code': 'gu'},
    {'name': 'Urdu', 'code': 'ur'},
    {'name': 'Kannada', 'code': 'kn'},
    {'name': 'Odia', 'code': 'or'},
    {'name': 'Malayalam', 'code': 'ml'},
    {'name': 'Punjabi', 'code': 'pa'},
    {'name': 'Assamese', 'code': 'as'},
    {'name': 'Maithili', 'code': 'mai'},
    {'name': 'Sanskrit', 'code': 'sa'},
    {'name': 'Konkani', 'code': 'kok'},
    {'name': 'Nepali', 'code': 'ne'},
    {'name': 'Sindhi', 'code': 'sd'},
    {'name': 'Dogri', 'code': 'doi'},
    {'name': 'Kashmiri', 'code': 'ks'},
    {'name': 'Manipuri', 'code': 'mni'},
    {'name': 'Santali', 'code': 'sat'},
    {'name': 'Bodo', 'code': 'brx'},
  ];

  // The targetLanguageCode is expected to be the ISO 639-1 code (e.g., 'en', 'ta')
  Future<String> translateText(String text, String targetLanguageCode) async {
    // Don't translate empty text
    if (text.trim().isEmpty) {
      return text;
    }

    // Check cache first
    final cacheKey = '${text}_$targetLanguageCode';
    if (_translationCache.containsKey(cacheKey)) {
      print('✅ Using cached translation for: "$text"');
      return _translationCache[cacheKey]!;
    }

    // Try Google Translator first (more reliable)
    try {
      print('🔄 Translating with Google Translator: "$text" to $targetLanguageCode');

      final translator = GoogleTranslator();
      final translation = await translator.translate(
        text,
        to: targetLanguageCode, // Use language code here
      );

      final translated = translation.text.trim();

      if (translated.isNotEmpty && 
          translated.toLowerCase() != 'error' && 
          translated.toLowerCase() != text.toLowerCase()) {
        _translationCache[cacheKey] = translated;
        print('✅ Google Translation successful: "$translated"');
        return translated;
      }
    } catch (e) {
      print('⚠️ Google Translator failed: $e');
      print('⚠️ Falling back to Gemini AI...');
    }

    // Fallback to Gemini AI if Google Translator fails
    if (_apiKey.isEmpty) {
      print('❌ ERROR: API key not set, returning original text');
      return text;
    }

    try {
      final languageName = getLanguageName(targetLanguageCode); // Get full name for prompt
      print('🔄 Translating with Gemini: "$text" to $languageName');

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      // IMPROVED: Much more explicit prompt
      final prompt = '''You are a professional translator. Your task is to translate text from any language to $languageName.

Text to translate: "$text"

Rules:
1. Detect the source language automatically
2. Translate ONLY to $languageName language
3. Return ONLY the translated text in $languageName
4. Do NOT return the original text
5. Do NOT add explanations
6. Do NOT add quotes
7. If the text is already in $languageName or if translation fails/is the same, return the original text.

Translation in $languageName:''';

      final content = [Content.text(prompt)];

      final response = await model.generateContent(content);

      print('📥 Raw Gemini Response: "${response.text}"');

      if (response.text == null || response.text!.isEmpty) {
        print('❌ Empty response from Gemini API');
        return text;
      }

      String translated = response.text!.trim();

      // Remove common prefixes
      final prefixesToRemove = [
        'Translation:',
        'translation:',
        '$languageName:',
        '${languageName.toLowerCase()}:',
        'Here is the translation:',
        'The translation is:',
        'Translation in $languageName:',
      ];

      for (final prefix in prefixesToRemove) {
        if (translated.toLowerCase().startsWith(prefix.toLowerCase())) {
          translated = translated.substring(prefix.length).trim();
        }
      }

      // Remove quotes
      if (translated.startsWith('"') && translated.endsWith('"')) {
        translated = translated.substring(1, translated.length - 1);
      }
      if (translated.startsWith("'") && translated.endsWith("'")) {
        translated = translated.substring(1, translated.length - 1);
      }

      // Remove markdown
      translated = translated.replaceAll('**', '').replaceAll('*', '');

      // Validate translation
      if (translated.toLowerCase() == 'unknown' || 
          translated.toLowerCase() == 'error' ||
          translated.isEmpty ||
          translated.toLowerCase() == text.toLowerCase()) { // Added check for redundant translation
        print('⚠️ Invalid/Redundant Gemini translation: "$translated"');
        return text;
      }

      _translationCache[cacheKey] = translated;
      print('✅ Gemini Translation successful: "$translated"');
      return translated;

    } catch (e) {
      print('❌ Gemini Translation error: $e');
      return text;
    }
  }

  // Clear translation cache
  static void clearCache() {
    _translationCache.clear();
    print('🗑️ Translation cache cleared');
  }

  // Save selected language preference
  static Future<void> saveSelectedLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', languageCode);
      clearCache(); // Clear cache when language changes
      print('💾 Saved language preference: $languageCode');
    } catch (e) {
      print('❌ Error saving language preference: $e');
    }
  }

  // Get saved language preference
  static Future<String?> getSelectedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('selected_language');
      if (lang != null) {
        print('📖 Retrieved language preference: $lang');
      }
      return lang;
    } catch (e) {
      print('❌ Error retrieving language preference: $e');
      return null;
    }
  }

  // Clear language preference (to disable translation)
  static Future<void> clearSelectedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_language');
      clearCache();
      print('🗑️ Cleared language preference');
    } catch (e) {
      print('❌ Error clearing language preference: $e');
    }
  }

  static String getLanguageName(String code) {
    final language = indianLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'name': 'Unknown', 'code': 'unknown'},
    );
    return language['name'] ?? 'Unknown';
  }
}