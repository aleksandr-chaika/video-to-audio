import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/icon_button_circle.dart';
import '../../../../core/widgets/icon_card_button.dart';
import '../../../../core/widgets/url_input_field.dart';
import '../../../history/domain/entities/history_item.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../history/presentation/widgets/history_empty.dart';
import '../../../history/presentation/widgets/history_grid.dart';

/// Image#1 — главный экран приложения.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryLoadRequested());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    _startConvert(file.path);
  }

  Future<void> _pickFromFiles() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['mp3', 'mp4', 'm4a', 'wav', 'mov'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;
    _startConvert(result.files.single.path!);
  }

  void _startConvert(String path) {
    if (FileUtils.isWav(path)) {
      // Файл уже WAV — отправляем сразу на Result без конвертации.
      context.go(
        '/result',
        extra: <String, Object?>{
          'path': path,
          'durationMs': 0,
          'sourceFormat': 'wav',
          'title': FileUtils.basenameWithoutExt(path),
        },
      );
      return;
    }
    context.go('/processing', extra: path);
  }

  void _submitYoutube(String url) {
    context.go('/youtube', extra: url);
  }

  @override
  Widget build(BuildContext context) {
    final double horizontal = PlatformUtils.horizontalPadding(context);
    final bool isTablet = PlatformUtils.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: AppDimens.spaceLg),
                Row(
                  children: <Widget>[
                    IconButtonCircle(
                      icon: CupertinoIcons.settings,
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.spaceLg),
                const AppLogo(),
                const SizedBox(height: AppDimens.space2xl),
                _SourceCards(
                  isTablet: isTablet,
                  onGallery: _pickFromGallery,
                  onFiles: _pickFromFiles,
                ),
                const SizedBox(height: AppDimens.spaceLg),
                UrlInputField(
                  controller: _urlController,
                  onSubmit: _submitYoutube,
                ),
                const SizedBox(height: AppDimens.space2xl),
                const Text('History', style: AppTextStyles.subtitle),
                const SizedBox(height: AppDimens.spaceMd),
                _HistorySection(
                  onTapItem: (HistoryItem item) => context.go(
                    '/result',
                    extra: <String, Object?>{
                      'path': item.filePath,
                      'durationMs': item.durationMs,
                      'sourceFormat': item.sourceFormat.name,
                      'title': item.title,
                      'thumbnailPath': item.thumbnailPath,
                    },
                  ),
                  onMore: (HistoryItem item) => _showMore(context, item),
                ),
                const SizedBox(height: AppDimens.space2xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMore(BuildContext context, HistoryItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.danger),
              title: const Text('Delete', style: AppTextStyles.body),
              onTap: () {
                if (item.id != null) {
                  context
                      .read<HistoryBloc>()
                      .add(HistoryItemDeleted(item.id!));
                }
                Navigator.of(sheetCtx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceCards extends StatelessWidget {
  const _SourceCards({
    required this.isTablet,
    required this.onGallery,
    required this.onFiles,
  });

  final bool isTablet;
  final VoidCallback onGallery;
  final VoidCallback onFiles;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[
      Expanded(
        child: IconCardButton(
          label: 'Gallery',
          icon: const Icon(Icons.image_outlined,
              color: AppColors.accentPrimary, size: 22),
          onTap: onGallery,
        ),
      ),
      const SizedBox(width: AppDimens.spaceMd),
      Expanded(
        child: IconCardButton(
          label: 'Files',
          icon: const Icon(Icons.folder_outlined,
              color: AppColors.accentPrimary, size: 22),
          onTap: onFiles,
        ),
      ),
    ];
    return Row(children: cards);
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.onTapItem, required this.onMore});

  final ValueChanged<HistoryItem> onTapItem;
  final ValueChanged<HistoryItem> onMore;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (BuildContext context, HistoryState state) {
        return switch (state) {
          HistoryInitial() || HistoryLoading() => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimens.space2xl),
                child: CircularProgressIndicator(
                    color: AppColors.accentPrimary),
              ),
            ),
          HistoryEmpty() => const HistoryEmptyView(),
          HistoryLoaded(:final List<HistoryItem> items) =>
            HistoryGrid(items: items, onTap: onTapItem, onMore: onMore),
          HistoryError(:final String message) => Padding(
              padding: const EdgeInsets.all(AppDimens.spaceLg),
              child: Text(message, style: AppTextStyles.bodySecondary),
            ),
        };
      },
    );
  }
}
