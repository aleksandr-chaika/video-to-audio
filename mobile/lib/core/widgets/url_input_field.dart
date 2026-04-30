import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';
import '../utils/url_validator.dart';

/// YouTube URL карточка (Image#1): 343×121, radius 24, gradient.
/// Внутри сверху — link-иконка + YouTube-логотип.
/// Внизу — input-pill 307×48, radius 16, white@15%:
///   left link-icon, placeholder "Paste your link", right paste/clear/check-circle.
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
  bool _focused = false;
  late final FocusNode _focusNode = FocusNode()..addListener(_onFocus);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    _isValid = YouTubeUrlValidator.isValid(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _onChange() {
    final bool nv = YouTubeUrlValidator.isValid(widget.controller.text);
    if (nv != _isValid) setState(() => _isValid = nv);
  }

  void _onFocus() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  Future<void> _paste() async {
    final ClipboardData? d = await Clipboard.getData('text/plain');
    if (d?.text == null) return;
    widget.controller.text = d!.text!;
    widget.controller.selection =
        TextSelection.fromPosition(TextPosition(offset: d.text!.length));
  }

  void _clear() {
    widget.controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.controller.text.isNotEmpty;
    return Container(
      height: 121,
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space16,
        AppDimens.space14,
        AppDimens.space16,
        AppDimens.space16,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(AppDimens.radius24),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          Positioned(
            top: -130,
            right: -130,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x14FFFFFF),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _YouTubeHeader(),
              const SizedBox(height: AppDimens.space12),
              SizedBox(
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF), // 15%
                    borderRadius: BorderRadius.circular(AppDimens.radius16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space14,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.link_rounded,
                          size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: AppDimens.space8),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          onSubmitted: widget.onSubmit,
                          style: AppTextStyles.body,
                          cursorColor: AppColors.textPrimary,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: widget.hint,
                            hintStyle: AppTextStyles.body
                                .copyWith(color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      if (hasText)
                        _RoundIconButton(
                          icon: Icons.close_rounded,
                          onTap: _clear,
                          background: const Color(0x33FFFFFF),
                        )
                      else
                        _RoundIconButton(
                          icon: Icons.content_paste_rounded,
                          onTap: _paste,
                          background: Colors.transparent,
                        ),
                      if (_isValid) ...<Widget>[
                        const SizedBox(width: AppDimens.space8),
                        GestureDetector(
                          onTap: () => widget.onSubmit(widget.controller.text),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YouTubeHeader extends StatelessWidget {
  const _YouTubeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.link_rounded,
            size: 20, color: AppColors.textPrimary),
        const SizedBox(width: AppDimens.space8),
        Image.asset(
          'assets/images/youtube_logo.png',
          height: 20,
          fit: BoxFit.contain,
          errorBuilder: (c, o, s) => const _YouTubeWordmarkFallback(),
        ),
      ],
    );
  }
}

class _YouTubeWordmarkFallback extends StatelessWidget {
  const _YouTubeWordmarkFallback();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'You',
            style: TextStyle(
              color: AppColors.youtubeRed,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 1),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.youtubeRed,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'Tube',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.background,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
