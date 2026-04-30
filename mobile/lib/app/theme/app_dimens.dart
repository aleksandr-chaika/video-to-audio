/// Layout-токены MP3 Craft. Извлечены из Figma 375x812 reference.
class AppDimens {
  AppDimens._();

  // Spacing scale (8-pt + special)
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // Aliases для миграции
  static const double spaceXs = space4;
  static const double spaceSm = space8;
  static const double spaceMd = space12;
  static const double spaceLg = space16;
  static const double spaceXl = space20;
  static const double space2xl = space24;
  static const double space3xl = space32;

  // Radii (точные значения из Figma)
  static const double radius12 = 12;
  static const double radius16 = 16;
  static const double radius20 = 20;
  static const double radius24 = 24;
  static const double radius32 = 32;
  static const double radius42 = 42;
  static const double radiusPill = 999;

  // Aliases
  static const double radiusSm = 8;
  static const double radiusMd = radius12;
  static const double radiusLg = radius16;
  static const double radiusXl = radius20;
  static const double radius2xl = radius24;

  // Component sizes
  static const double headerButtonSize = 38; // settings/close/delete
  static const double headerInnerIcon = 24;
  static const double iconButtonSize = 38;
  static const double iconCardHeight = 119;
  static const double iconCardInnerBox = 48; // white box inside card
  static const double iconCardInnerIcon = 36;
  static const double primaryButtonHeight = 56;
  static const double formatPillHeight = 25;
  static const double formatPillSmallHeight = 22;
  static const double playerBarHeight = 76;
  static const double cropTrimmerHeight = 76;
  static const double playerControlSize = 44; // pause circle
  static const double previewWithImageHeight = 301;
  static const double previewIconOnlyHeight = 175;
  static const double historyCardHeight = 143;
  static const double homeIndicatorWidth = 134;
  static const double homeIndicatorHeight = 5;
  static const double statusBarHeight = 47;
  static const double appBarHeight = 56;

  // Hero (Main Page)
  static const double heroHeight = 209;
  static const double heroLogoMP3Size = 42;

  // Modal "Processing"
  static const double modalBoxSize = 140;

  // Breakpoints
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;
}
