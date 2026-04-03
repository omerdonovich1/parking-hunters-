class AppConfig {
  AppConfig._();

  // ⚠️ Replace with your Anthropic API key before running on device.
  // In production, move this call to a backend so the key is never in the app binary.
  static const String claudeApiKey = 'YOUR_CLAUDE_API_KEY';

  static const String googleMapsApiKey = '';
  static const String admobBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String admobRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String appName = 'Parking Hunter';
}
