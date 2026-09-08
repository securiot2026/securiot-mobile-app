/// Shared 8pt spacing scale, inherited from the Web App / Landing Page UI-SPEC.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// A11Y.md SC 2.5.8 house rule: minimum touch target regardless of scale.
  static const double minTouchTarget = 44;
}
