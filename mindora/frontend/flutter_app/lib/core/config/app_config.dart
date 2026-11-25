/// Central, replaceable application configuration.
///
/// The branding system reads every user-visible string and identifier
/// from here, so the product can be rebranded without touching UI code.
class AppConfig {
  AppConfig._();

  // Brand
  static const String appName = 'MINDORA';
  static const String appTagline = 'Learn smarter. Prepare better.';
  static const String appVersion = '0.1.0';

  // Feature flags
  static const bool enableVoice = false;
  static const bool enableVision = false;
  static const bool enablePayments = false;
  static const bool enableContributions = true;

  // Defaults
  static const String defaultLanguageCode = 'en';
  static const List<String> supportedLanguages = ['en', 'fr'];
}
