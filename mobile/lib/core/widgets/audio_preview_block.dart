import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';

/// Preview-блок (Result/Crop): 311 wide × 175 (с иконкой) или 301 (с обложкой) высоты.
/// Контейнер — radius 32, white@5%. Внутри — либо обложка, либо иконка ноты/камеры.
class AudioPreviewBlock extends StatelessWidget {
  const AudioPreviewBlock({
    super.key,
    this.imagePath,
    this.placeholderIcon = Icons.music_note_rounded,
    this.height = AppDimens.previewIconOnlyHeight,
    this.bottomOverlay,
  });

  final String? imagePath;
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
          color: const Color(0x0DFFFFFF), // 5%
          borderRadius: BorderRadius.circular(AppDimens.radius32),
          border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: hasImage
                  ? Image.file(File(imagePath!), fit: BoxFit.cover)
                  : Center(
                      child: Icon(
                        placeholderIcon,
                        size: 122,
                        color: AppColors.accentSolid,
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
