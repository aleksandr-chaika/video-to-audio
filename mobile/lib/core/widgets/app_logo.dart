import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Hero-блок Main Page (Image#1): MP3-иконка + "Craft" + подпись слева,
/// 3D-иллюстрация справа.
///
/// Если в `assets/images/hero_logo_3d.png` есть PNG — использует его; иначе —
/// CustomPainter-композиция (камера + микрофон + refresh-circle + sparkles).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.heroAssetPath = 'assets/images/hero_logo_3d.png'});

  final String heroAssetPath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.heroHeight - AppDimens.appBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(top: AppDimens.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const _Mp3Glyph(size: AppDimens.heroLogoMP3Size),
                      const SizedBox(width: AppDimens.space8),
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
          ),
          Expanded(
            flex: 5,
            child: _HeroIllustration(assetPath: heroAssetPath),
          ),
        ],
      ),
    );
  }
}

/// MP3-иконка слева от "Craft" — стилизованный документ.
class _Mp3Glyph extends StatelessWidget {
  const _Mp3Glyph({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _Mp3Painter()),
    );
  }
}

class _Mp3Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = AppColors.accentSolid
      ..strokeWidth = size.width * 0.06
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;
    final Path doc = Path()
      ..moveTo(w * 0.2, h * 0.15)
      ..lineTo(w * 0.6, h * 0.15)
      ..lineTo(w * 0.85, h * 0.4)
      ..lineTo(w * 0.85, h * 0.85)
      ..lineTo(w * 0.2, h * 0.85)
      ..close()
      ..moveTo(w * 0.6, h * 0.15)
      ..lineTo(w * 0.6, h * 0.4)
      ..lineTo(w * 0.85, h * 0.4);
    canvas.drawPath(doc, stroke);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'MP3',
        style: TextStyle(
          color: AppColors.accentSolid,
          fontWeight: FontWeight.w900,
          fontSize: size.width * 0.30,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        (w - tp.width) / 2,
        h * 0.55,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.assetPath});
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      alignment: Alignment.topRight,
      errorBuilder: (BuildContext c, Object o, StackTrace? s) =>
          const _HeroFallback(),
    );
  }
}

/// CustomPainter-композиция (если PNG-ассет недоступен).
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
