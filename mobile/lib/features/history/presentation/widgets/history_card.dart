import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/format_badge.dart';
import '../../domain/entities/history_item.dart';

/// History card 165×143, radius 20-24, fill #14191F.
/// Format pill (top-left) + more dots (top-right) + duration pill (bottom-right).
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
        borderRadius: BorderRadius.circular(AppDimens.radius20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppDimens.radius20),
            border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
          ),
          child: Stack(
            children: <Widget>[
              if (hasThumb)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radius20),
                  child: Image.file(
                    File(item.thumbnailPath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              else
                Center(
                  child: Icon(
                    item.sourceFormat == SourceFormat.mp4
                        ? Icons.videocam_rounded
                        : Icons.music_note_rounded,
                    size: 64,
                    color: AppColors.accentSolid,
                  ),
                ),
              // Top row
              Positioned(
                top: AppDimens.space14,
                left: AppDimens.space14,
                right: AppDimens.space14,
                child: Row(
                  children: <Widget>[
                    FormatBadge(item.outputFormat.label,
                        size: FormatBadgeSize.small),
                    const Spacer(),
                    _MoreButton(onTap: onMore),
                  ],
                ),
              ),
              // Bottom-right duration
              Positioned(
                right: AppDimens.space14,
                bottom: AppDimens.space14,
                child: Container(
                  height: AppDimens.formatPillSmallHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius:
                        BorderRadius.circular(AppDimens.radius16),
                  ),
                  child: Text(
                    DurationFormatter.format(item.duration),
                    style: AppTextStyles.formatBadgeSm,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x1AFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radius16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radius16),
        onTap: onTap,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: AppIcon(
              assetPath: 'assets/images/icons/ic_more.png',
              fallback: Icons.more_horiz_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
