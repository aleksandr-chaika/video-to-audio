import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimens.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../domain/entities/history_item.dart';
import 'history_card.dart';

class HistoryGrid extends StatelessWidget {
  const HistoryGrid({
    required this.items,
    required this.onTap,
    required this.onMore,
    super.key,
  });

  final List<HistoryItem> items;
  final ValueChanged<HistoryItem> onTap;
  final ValueChanged<HistoryItem> onMore;

  @override
  Widget build(BuildContext context) {
    final int columns = PlatformUtils.historyColumns(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppDimens.spaceMd,
        mainAxisSpacing: AppDimens.spaceMd,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (BuildContext context, int index) {
        final HistoryItem item = items[index];
        return HistoryCard(
          item: item,
          onTap: () => onTap(item),
          onMore: () => onMore(item),
        );
      },
    );
  }
}
