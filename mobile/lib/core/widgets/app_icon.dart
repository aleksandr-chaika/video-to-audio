import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Универсальная иконка: пытается загрузить asset PNG, при ошибке падает на Material IconData.
/// Используется чтобы сначала использовать Figma-PNG, а если его нет — стандартный glyph.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    this.assetPath,
    this.fallback,
    this.size = 24,
    this.color = AppColors.textPrimary,
  });

  final String? assetPath;
  final IconData? fallback;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        color: _shouldTint(assetPath!) ? color : null,
        errorBuilder: (c, o, s) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    if (fallback == null) return SizedBox(width: size, height: size);
    return Icon(fallback, size: size, color: color);
  }

  /// Не тонируем 3D-иллюстрации (они уже цветные).
  bool _shouldTint(String path) =>
      path.contains('/icons/'); // только flat-иконки
}
