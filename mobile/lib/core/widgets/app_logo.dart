import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Заголовок «Craft» с иконкой MP3-документа слева и 3D-композицией справа.
/// Image#1: блок «MP3 Craft / Convert audio or video into crystal-clear MP3s».
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: const Text(
                      'MP3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceSm),
                  const Text('Craft', style: AppTextStyles.title),
                ],
              ),
              const SizedBox(height: AppDimens.spaceSm),
              const Text(
                'Convert audio or video into\ncrystal-clear MP3s in second',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimens.spaceMd),
        const _LogoComposition(),
      ],
    );
  }
}

class _LogoComposition extends StatelessWidget {
  const _LogoComposition();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 100,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 6,
            child: _shape(Icons.videocam_rounded, size: 60),
          ),
          Positioned(
            right: 4,
            top: 0,
            child: _shape(Icons.mic_rounded, size: 56),
          ),
          Positioned(
            left: 38,
            top: 36,
            child: _shape(Icons.refresh_rounded, size: 48, light: true),
          ),
        ],
      ),
    );
  }

  Widget _shape(IconData icon, {required double size, bool light = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: light
              ? const <Color>[Color(0xFFFFFFFF), Color(0xFFB6D2FF)]
              : const <Color>[Color(0xFF8FBEFF), Color(0xFF2256D6)],
        ),
        borderRadius: BorderRadius.circular(size / 2.4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon,
          color: light ? AppColors.accentPrimary : Colors.white, size: size * 0.5),
    );
  }
}
