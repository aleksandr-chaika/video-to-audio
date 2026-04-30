import 'package:flutter/widgets.dart';

import '../../app/theme/app_dimens.dart';

/// Адаптивные хелперы для iPhone vs iPad.
class PlatformUtils {
  PlatformUtils._();

  static bool isTablet(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return width >= AppDimens.tabletBreakpoint;
  }

  static int historyColumns(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width >= AppDimens.desktopBreakpoint) return 4;
    if (width >= AppDimens.tabletBreakpoint) return 3;
    return 2;
  }

  static double horizontalPadding(BuildContext context) {
    return isTablet(context) ? AppDimens.space2xl : AppDimens.spaceLg;
  }
}
