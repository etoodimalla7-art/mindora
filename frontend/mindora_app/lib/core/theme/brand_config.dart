/// Centralized brand configuration.
///
/// Everything that identifies the product as "MINDORA" lives here. To
/// rebrand, edit this file only — no other file references the name,
/// logo asset path, or brand colors directly.
class BrandConfig {
  const BrandConfig._();

  static const String appName = 'MINDORA';
  static const String tagline = 'Study smarter. Know exactly what to learn.';

  static const String logoAssetPath = 'assets/brand/logo.png';
  static const String iconAssetPath = 'assets/brand/icon.png';
  static const String splashAssetPath = 'assets/brand/splash.png';

  /// Brand seed color — every other color token derives from this.
  static const int primarySeedColorValue = 0xFF3454D1; // deep academic blue
  static const int secondarySeedColorValue = 0xFF16B3AC; // calm teal accent
}
