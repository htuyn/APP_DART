/// Cấu hình AI Provider cho ứng dụng
class AiConfig {
  AiConfig._();

  // ─── Gemini ───────────────────────────────────────────────────────────────
  /// Model Gemini mặc định
  static const String defaultModel = 'gemini-1.5-flash';

  /// Key truyền qua build flag: `flutter run --dart-define=GEMINI_API_KEY=your_key`
  static const String envApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Gemini API Key lưu trong SharedPreferences
  static const String prefsApiKey = 'gemini_api_key_v1';

  // ─── OpenRouter ───────────────────────────────────────────────────────────
  /// OpenRouter API Key lưu trong SharedPreferences
  static const String prefsOpenRouterKey = 'openrouter_api_key_v1';

  /// OpenRouter Model ID lưu trong SharedPreferences
  static const String prefsOpenRouterModel = 'openrouter_model_v1';

  /// AI Provider đang chọn: 'gemini' | 'openrouter' | 'offline'
  static const String prefsAiProvider = 'ai_provider_v1';

  /// OpenRouter model mặc định (Free Tier)
  static const String defaultOpenRouterModel =
      'meta-llama/llama-3.1-8b-instruct:free';

  /// Danh sách model OpenRouter Free Tier gợi ý
  static const List<String> suggestedFreeModels = [
    'meta-llama/llama-3.1-8b-instruct:free',
    'meta-llama/llama-3.2-3b-instruct:free',
    'google/gemma-2-9b-it:free',
    'mistralai/mistral-7b-instruct:free',
    'qwen/qwen-2.5-7b-instruct:free',
  ];
}
