import 'package:equatable/equatable.dart';

enum SourceType { local, youtube }

enum SourceFormat { mp3, mp4, wav, unknown }

extension SourceFormatX on SourceFormat {
  String get label => name.toUpperCase();
  static SourceFormat fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'mp3':
        return SourceFormat.mp3;
      case 'mp4':
        return SourceFormat.mp4;
      case 'wav':
        return SourceFormat.wav;
      default:
        return SourceFormat.unknown;
    }
  }
}

class HistoryItem extends Equatable {
  const HistoryItem({
    required this.id,
    required this.sourceType,
    required this.sourceFormat,
    required this.outputFormat,
    required this.filePath,
    required this.durationMs,
    required this.createdAt,
    this.title,
    this.thumbnailPath,
  });

  final int? id;
  final SourceType sourceType;
  final SourceFormat sourceFormat;
  final SourceFormat outputFormat;
  final String filePath;
  final String? title;
  final int durationMs;
  final String? thumbnailPath;
  final DateTime createdAt;

  Duration get duration => Duration(milliseconds: durationMs);

  HistoryItem copyWith({int? id}) {
    return HistoryItem(
      id: id ?? this.id,
      sourceType: sourceType,
      sourceFormat: sourceFormat,
      outputFormat: outputFormat,
      filePath: filePath,
      title: title,
      durationMs: durationMs,
      thumbnailPath: thumbnailPath,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        sourceType,
        sourceFormat,
        outputFormat,
        filePath,
        title,
        durationMs,
        thumbnailPath,
        createdAt,
      ];
}
