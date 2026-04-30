import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/icon_button_circle.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButtonCircle(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: AppDimens.spaceMd),
                  const Text('Settings', style: AppTextStyles.headline),
                ],
              ),
              const SizedBox(height: AppDimens.space2xl),
              const Text(
                'MP3 Craft v0.1.0',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
