import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Hero-блок Main Page (Image#1).
/// 162h. Слева — текст «Craft» + субтитл, справа — 3D-композиция.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.heroAssetPath = 'assets/images/hero_logo_3d.png',
  });

  final String heroAssetPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 162,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // 3D-композиция справа.
          Positioned(
            right: -16,
            top: -8,
            child: SizedBox(
              width: 200,
              height: 162,
              child: Image.asset(
                heroAssetPath,
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                errorBuilder: (c, o, s) => const _HeroFallback(),
              ),
            ),
          ),
          // Текст слева, не перекрывает 3D (text width ~210, image starts at right-200)
          Positioned(
            left: 0,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      'assets/images/mp3_doc_3d.png',
                      width: AppDimens.heroLogoMP3Size,
                      height: AppDimens.heroLogoMP3Size,
                      errorBuilder: (c, o, s) => const SizedBox(
                        width: AppDimens.heroLogoMP3Size,
                        height: AppDimens.heroLogoMP3Size,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space4),
                    Text('Craft', style: AppTextStyles.display),
                  ],
                ),
                const SizedBox(height: AppDimens.space12),
                Text(
                  'Convert audio or video into\ncrystal-clear MP3s in second',
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          left: 0,
          top: 8,
          child: _gradShape(Icons.videocam_rounded, 78),
        ),
        Positioned(
          right: 0,
          top: 4,
          child: _gradShape(Icons.mic_rounded, 72),
        ),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.accentSolid.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.refresh_rounded,
              color: AppColors.accentSolid, size: 36),
        ),
      ],
    );
  }

  Widget _gradShape(IconData icon, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(size / 2.4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accentDeep.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}
