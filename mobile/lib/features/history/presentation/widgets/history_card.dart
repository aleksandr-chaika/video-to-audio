import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/entities/history_item.dart';

/// Карточка элемента истории (Image#1, Result preview-list-style).
/// Показывает иконку/обложку, бейдж формата, длительность, three-dots.
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    required this.item,
    required this.onTap,
    required this.onMore,
    super.key,
  });

  final HistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final bool hasThumb = item.thumbnailPath != null &&
        File(item.thumbnailPath!).existsSync();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: Stack(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                child: hasThumb
                    ? Image.file(
                        File(item.thumbnailPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : _placeholderBackground(),
              ),
              Positioned(
                top: AppDimens.spaceSm,
                left: AppDimens.spaceSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spaceSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Text(
                    item.outputFormat.label,
                    style: AppTextStyles.badge.copyWith(fontSize: 10),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  color: AppColors.textPrimary,
                  onPressed: onMore,
                ),
              ),
              Positioned(
                bottom: AppDimens.spaceSm,
                right: AppDimens.spaceSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spaceSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Text(
                    DurationFormatter.format(item.duration),
                    style: AppTextStyles.duration.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderBackground() {
    return Container(
      color: AppColors.surfaceCard,
      child: Center(
        child: Icon(
          item.sourceFormat == SourceFormat.mp4
              ? Icons.videocam_rounded
              : Icons.music_note_rounded,
          size: 36,
          color: AppColors.accentPrimary,
        ),
      ),
    );
  }
}
