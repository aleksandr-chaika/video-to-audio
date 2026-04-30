import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// Empty history state.
/// Figma (frame 3:69 Main Page-Empty): rounded square 110×110 radius 24
/// #14191F + микрофон-иконка по центру. Никаких waveform-волн вокруг.
class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space24),
      child: Column(
        children: <Widget>[
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppDimens.radius24),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/mic_3d.png',
              width: 78,
              height: 78,
              fit: BoxFit.contain,
              errorBuilder: (BuildContext c, Object err, StackTrace? st) {
                if (kDebugMode) {
                  debugPrint('mic_3d.png load failed: $err');
                }
                return const Icon(
                  Icons.mic_rounded,
                  size: 56,
                  color: AppColors.accentSolid,
                );
              },
            ),
          ),
          const SizedBox(height: AppDimens.space20),
          Text(
            'Your History Is Empty',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 21.6 / 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'To get started tap “Gallery” or “Files”,\nor just insert link of YouTube video',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 18.2 / 13,
              color: AppColors.textPrimary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
