import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';
import '../../gen/assets.gen.dart';
import '../utils/url_validator.dart';
import 'app_icon.dart';

/// YouTube URL карточка (Figma 3:160): 343×121, radius 24, gradient
/// + decoration play-icon, + tonkий stroke white@15% 3px inside.
/// Внутри: header (link + YouTube logo) + Row(input pill + check-button OUTSIDE pill).
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
  String? _clipboardSuggestion; // URL из буфера, готовый к вставке
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
    // Текст изменился — скрыть chip suggestion (пользователь уже что-то ввёл).
    if (widget.controller.text.isNotEmpty && _clipboardSuggestion != null) {
      setState(() => _clipboardSuggestion = null);
    }
  }

  void _onFocus() {
    if (_focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _checkClipboardForSuggestion();
      } else {
        // При unfocus — скрыть chip
        setState(() => _clipboardSuggestion = null);
      }
    }
  }

  /// Проверяем clipboard при focus → если там валидный YouTube URL и
  /// поле пустое, показываем inline chip «Paste link» над input.
  Future<void> _checkClipboardForSuggestion() async {
    if (widget.controller.text.isNotEmpty) return;
    final ClipboardData? d = await Clipboard.getData('text/plain');
    final String? text = d?.text?.trim();
    if (!mounted) return;
    if (text == null ||
        text.isEmpty ||
        !YouTubeUrlValidator.isValid(text)) {
      return;
    }
    setState(() => _clipboardSuggestion = text);
  }

  void _acceptSuggestion() {
    final String? text = _clipboardSuggestion;
    if (text == null) return;
    widget.controller.text = text;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() => _clipboardSuggestion = null);
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

  /// Submit только если URL валиден. Иначе — просто скрываем клавиатуру.
  void _handleSubmit(String value) {
    if (YouTubeUrlValidator.isValid(value)) {
      widget.onSubmit(value);
    } else {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.controller.text.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radius24),
      child: SizedBox(
        height: 121,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            // Gradient-фон card.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                ),
              ),
            ),
            // Stroke (Figma: linear white→transparent, 15% opacity, 3px inside).
            // Реализован как тонкая накладка — DecoratedBox с border на stroke
            // gradient + clip RRect (внешний ClipRRect уже обрезает по radius).
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radius24),
                    border: Border.all(
                      color: const Color(0x26FFFFFF), // white@15%
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            // YouTube play-decoration — Figma 3:161: X:226 Y:-42 W:120.97
            // ∠-14.01° opacity 7%.
            Positioned(
              right: -4,
              top: -42,
              width: 120,
              height: 120,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -14.01 * 3.1415926535 / 180,
                  child: Opacity(
                    opacity: 0.07,
                    child: Assets.images.ytPlayDecoration.image(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      errorBuilder:
                          (BuildContext c, Object err, StackTrace? st) =>
                              const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            // Основной padded-контент.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space16,
                AppDimens.space14,
                AppDimens.space16,
                AppDimens.space16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Header сжимается до Row(link + YouTube logo + Spacer + chip)
                  // — chip с предложением вставки появляется справа в шапке
                  // когда есть фокус и в буфере YouTube URL.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const _YouTubeHeader(),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder:
                            (Widget child, Animation<double> a) {
                          return FadeTransition(
                            opacity: a,
                            child: SizeTransition(
                              sizeFactor: a,
                              axis: Axis.horizontal,
                              axisAlignment: 1.0,
                              child: child,
                            ),
                          );
                        },
                        child: _clipboardSuggestion != null
                            ? _PasteSuggestionChip(
                                key: const ValueKey<String>('paste-chip'),
                                onTap: _acceptSuggestion,
                              )
                            : const SizedBox.shrink(
                                key: ValueKey<String>('no-chip'),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Input pill сам по себе (Figma — 261×48 если есть check,
                      // иначе занимает всю ширину).
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0x26FFFFFF), // white@15%
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radius16),
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
                                    // Done/Далее в клавиатуре НЕ отправляет
                                    // запрос — только закрывает клавиатуру
                                    // если URL невалидный.
                                    onSubmitted: _handleSubmit,
                                    style: AppTextStyles.body,
                                    cursorColor: AppColors.textPrimary,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      hintText: widget.hint,
                                      hintStyle: AppTextStyles.body
                                          .copyWith(color: AppColors.textMuted),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                if (hasText)
                                  _RoundIconButton(
                                    icon: Icons.close_rounded,
                                    iconAsset:
                                        Assets.images.icons.icClose.path,
                                    onTap: _clear,
                                    background: Colors.transparent,
                                  ),
                                const SizedBox(width: AppDimens.space4),
                                _RoundIconButton(
                                  icon: Icons.content_paste_rounded,
                                  iconAsset:
                                      Assets.images.icons.icClipboard.path,
                                  onTap: _paste,
                                  background: Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Check-button СНАРУЖИ pill — отдельный круг справа.
                      // Появляется только когда URL валиден.
                      if (_isValid) ...<Widget>[
                        const SizedBox(width: AppDimens.space8),
                        GestureDetector(
                          onTap: () => widget.onSubmit(widget.controller.text),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0x33FFFFFF),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
        Assets.images.youtubeLogo.image(
          height: 20,
          fit: BoxFit.contain,
          errorBuilder: (BuildContext c, Object err, StackTrace? st) {
            if (kDebugMode) {
              debugPrint('youtube_logo.png load failed: $err');
            }
            return const _YouTubeWordmarkFallback();
          },
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

/// Inline-предложение вставки из буфера обмена. Появляется справа в
/// шапке YouTube-card, когда поле ввода в фокусе и в clipboard
/// валидный YouTube URL. Tap → вставка в input.
class _PasteSuggestionChip extends StatelessWidget {
  const _PasteSuggestionChip({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF), // white@20%
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0x4DFFFFFF),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              Icon(Icons.content_paste_rounded,
                  size: 14, color: AppColors.textPrimary),
              SizedBox(width: 6),
              Text(
                'Вставить',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.background,
    this.iconAsset,
  });
  final IconData icon;
  final String? iconAsset;
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
          child: Center(
            child: AppIcon(
              assetPath: iconAsset,
              fallback: icon,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
