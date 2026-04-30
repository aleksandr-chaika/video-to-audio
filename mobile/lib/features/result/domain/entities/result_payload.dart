import 'package:equatable/equatable.dart';

import '../../../history/domain/entities/history_item.dart';

class ResultPayload extends Equatable {
  const ResultPayload({
    required this.filePath,
    required this.durationMs,
    required this.sourceFormat,
    this.title,
    this.thumbnailPath,
  });

  final String filePath;
  final int durationMs;
  final SourceFormat sourceFormat;
  final String? title;
  final String? thumbnailPath;

  Duration get duration => Duration(milliseconds: durationMs);

  static ResultPayload fromMap(Map<String, Object?> map) => ResultPayload(
        filePath: map['path'] as String,
        durationMs: (map['durationMs'] as int?) ?? 0,
        sourceFormat:
            SourceFormatX.fromString(map['sourceFormat'] as String?),
        title: map['title'] as String?,
        thumbnailPath: map['thumbnailPath'] as String?,
      );

  @override
  List<Object?> get props => <Object?>[
        filePath,
        durationMs,
        sourceFormat,
        title,
        thumbnailPath,
      ];
}
