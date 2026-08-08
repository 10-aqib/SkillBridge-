class AssetPaths {
  // Base paths
  static const String _imagesBase = 'assets/images/';
  // static const String _iconsBase = 'assets/icons/';
  static const String _animationsBase = 'assets/animations/';

  // Images
  static const String logo = '${_imagesBase}logo.png';
  static const String logoDark = '${_imagesBase}logo_dark.png';
  static const String placeholderAvatar = '${_imagesBase}placeholders/avatar.png';
  static const String placeholderImage = '${_imagesBase}placeholders/image.png';

  // Onboarding
  static const String onboardingClient = '${_imagesBase}onboarding/client.png';
  static const String onboardingWorker = '${_imagesBase}onboarding/worker.png';
  static const String onboardingDisputes = '${_imagesBase}onboarding/disputes.png';

  // Lottie Animations
  static const String splashAnimation = '${_animationsBase}splash.json';
  static const String loadingAnimation = '${_animationsBase}loading.json';
  static const String successAnimation = '${_animationsBase}success.json';
  static const String errorAnimation = '${_animationsBase}error.json';
}
