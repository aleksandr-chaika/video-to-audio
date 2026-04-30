import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';

/// Preview-блок (Result/Crop): 311 wide × 175 / 301.
/// Контейнер — radius 32, white@5%. Внутри:
/// 1) если есть `imagePath` (обложка) — Image.file;
/// 2) иначе — 3D-asset (по умолчанию music note из Figma);
/// 3) иначе — Material-иконка fallback.
class AudioPreviewBlock extends StatelessWidget {
  const AudioPreviewBlock({
    super.key,
    this.imagePath,
    this.placeholderAsset = 'assets/images/music_note_3d.png',
    this.placeholderIcon = Icons.music_note_rounded,
    this.height = AppDimens.previewIconOnlyHeight,
    this.bottomOverlay,
  });

  final String? imagePath;
  final String? placeholderAsset;
  final IconData placeholderIcon;
  final double height;
  final Widget? bottomOverlay;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath != null && File(imagePath!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radius32),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(AppDimens.radius32),
          border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: hasImage
                  ? Image.file(File(imagePath!), fit: BoxFit.cover)
                  : Center(
                      child: SizedBox(
                        width: 130,
                        height: 130,
                        child: placeholderAsset != null
                            ? Image.asset(
                                placeholderAsset!,
                                fit: BoxFit.contain,
                                errorBuilder: (c, o, s) => Icon(
                                  placeholderIcon,
                                  size: 122,
                                  color: AppColors.accentSolid,
                                ),
                              )
                            : Icon(placeholderIcon,
                                size: 122, color: AppColors.accentSolid),
                      ),
                    ),
            ),
            if (bottomOverlay != null)
              Positioned(
                left: AppDimens.space14,
                right: AppDimens.space14,
                bottom: AppDimens.space14,
                child: bottomOverlay!,
              ),
          ],
        ),
      ),
    );
  }
}
