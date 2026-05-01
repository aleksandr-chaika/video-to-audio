// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

/// Type-safe references to bundled assets. Совместим по API с flutter_gen.
///
/// Использование:
/// ```dart
/// Image.asset(Assets.images.youtubeLogo.path)
/// Assets.images.icons.icGallery.image()
/// ```
///
/// При добавлении новых ассетов: добавить файл в `assets/images/...`,
/// зарегистрировать в pubspec.yaml `flutter > assets`, добавить новое
/// поле в этот класс.
class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/camera_3d.png
  AssetGenImage get camera3d =>
      const AssetGenImage('assets/images/camera_3d.png');

  /// File path: assets/images/hero_logo_3d.png
  AssetGenImage get heroLogo3d =>
      const AssetGenImage('assets/images/hero_logo_3d.png');

  /// File path: assets/images/mic_3d.png
  AssetGenImage get mic3d => const AssetGenImage('assets/images/mic_3d.png');

  /// File path: assets/images/mp3_doc_3d.png
  AssetGenImage get mp3Doc3d =>
      const AssetGenImage('assets/images/mp3_doc_3d.png');

  /// File path: assets/images/music_note_3d.png
  AssetGenImage get musicNote3d =>
      const AssetGenImage('assets/images/music_note_3d.png');

  /// File path: assets/images/youtube_logo.png
  AssetGenImage get youtubeLogo =>
      const AssetGenImage('assets/images/youtube_logo.png');

  /// File path: assets/images/yt_play_decoration.png
  AssetGenImage get ytPlayDecoration =>
      const AssetGenImage('assets/images/yt_play_decoration.png');

  $AssetsImagesIconsGen get icons => const $AssetsImagesIconsGen();
}

class $AssetsImagesIconsGen {
  const $AssetsImagesIconsGen();

  /// File path: assets/images/icons/ic_arrow_right.png
  AssetGenImage get icArrowRight =>
      const AssetGenImage('assets/images/icons/ic_arrow_right.png');

  /// File path: assets/images/icons/ic_chevron_right.png
  AssetGenImage get icChevronRight =>
      const AssetGenImage('assets/images/icons/ic_chevron_right.png');

  /// File path: assets/images/icons/ic_clipboard.png
  AssetGenImage get icClipboard =>
      const AssetGenImage('assets/images/icons/ic_clipboard.png');

  /// File path: assets/images/icons/ic_close.png
  AssetGenImage get icClose =>
      const AssetGenImage('assets/images/icons/ic_close.png');

  /// File path: assets/images/icons/ic_delete.png
  AssetGenImage get icDelete =>
      const AssetGenImage('assets/images/icons/ic_delete.png');

  /// File path: assets/images/icons/ic_files.png
  AssetGenImage get icFiles =>
      const AssetGenImage('assets/images/icons/ic_files.png');

  /// File path: assets/images/icons/ic_files_decoration.png
  AssetGenImage get icFilesDecoration =>
      const AssetGenImage('assets/images/icons/ic_files_decoration.png');

  /// File path: assets/images/icons/ic_gallery.png
  AssetGenImage get icGallery =>
      const AssetGenImage('assets/images/icons/ic_gallery.png');

  /// File path: assets/images/icons/ic_gallery_decoration.png
  AssetGenImage get icGalleryDecoration =>
      const AssetGenImage('assets/images/icons/ic_gallery_decoration.png');

  /// File path: assets/images/icons/ic_link.png
  AssetGenImage get icLink =>
      const AssetGenImage('assets/images/icons/ic_link.png');

  /// File path: assets/images/icons/ic_more.png
  AssetGenImage get icMore =>
      const AssetGenImage('assets/images/icons/ic_more.png');

  /// File path: assets/images/icons/ic_pause.png
  AssetGenImage get icPause =>
      const AssetGenImage('assets/images/icons/ic_pause.png');

  /// File path: assets/images/icons/ic_settings.png
  AssetGenImage get icSettings =>
      const AssetGenImage('assets/images/icons/ic_settings.png');
}

class Assets {
  const Assets._();

  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName);

  final String _assetName;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;
  String get keyName => _assetName;
}
