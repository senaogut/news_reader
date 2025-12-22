/// App spacing constants
class AppSpacing {
  AppSpacing._();

  // Base spacing unit
  static const double base = 8.0;

  // Specific spacing values
  static const double xs = base * 0.5; // 4.0
  static const double sm = base; // 8.0
  static const double md = base * 2; // 16.0
  static const double lg = base * 3; // 24.0
  static const double xl = base * 4; // 32.0
  static const double xxl = base * 6; // 48.0
  static const double xxxl = base * 8; // 64.0
}

/// App border radius constants
class AppBorderRadius {
  AppBorderRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0; // For fully rounded corners
}

/// App icon sizes
class AppIconSizes {
  AppIconSizes._();

  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 40.0;
  static const double xxl = 48.0;
}

/// App button heights
class AppButtonSizes {
  AppButtonSizes._();

  static const double small = 36.0;
  static const double medium = 44.0;
  static const double large = 48.0;
  static const double extraLarge = 56.0;
}

/// App container constraints
class AppConstraints {
  AppConstraints._();

  static const double maxContentWidth = 480.0;
  static const double minButtonWidth = 84.0;
  static const double qrCodeSize = 192.0;
}
