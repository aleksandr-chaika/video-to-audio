import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';
import '../utils/url_validator.dart';

/// Поле ввода YouTube ссылки с paste/clear/check-индикатором.
/// Изображение #1: «синяя» поверхность, YouTube-логотип сверху,
/// внизу — input с иконкой clipboard или check-mark.
class UrlInputField extends StatefulWidget {
  const UrlInputField({
    required this.controller,
    required this.onSubmit,
    super.key,
    this.hint = 'Paste your link',
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final String hint;

  @override
  State<UrlInputField> createState() => _UrlInputFieldState();
}

class _UrlInputFieldState extends State<UrlInputField> {
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
    _isValid = YouTubeUrlValidator.isValid(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    final bool nowValid = YouTubeUrlValidator.isValid(widget.controller.text);
    if (nowValid != _isValid) {
      setState(() => _isValid = nowValid);
    }
  }

  Future<void> _paste() async {
    final ClipboardData? data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    widget.controller.text = data!.text!;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
  }

  void _clear() => widget.controller.clear();

  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.controller.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppDimens.spaceLg),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimens.radius2xl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.link_rounded,
                  color: AppColors.textPrimary, size: 18),
              const SizedBox(width: AppDimens.spaceXs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    color: Color(0xFFFF0000),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: const Text(
                  'Tube',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceMd),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spaceLg,
              vertical: 4,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: widget.onSubmit,
                    style: AppTextStyles.body,
                    cursorColor: AppColors.textPrimary,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (hasText)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textPrimary,
                    onPressed: _clear,
                    tooltip: 'Clear',
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.content_paste_rounded, size: 20),
                    color: AppColors.textPrimary,
                    onPressed: _paste,
                    tooltip: 'Paste',
                  ),
                if (_isValid)
                  GestureDetector(
                    onTap: () => widget.onSubmit(widget.controller.text),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
