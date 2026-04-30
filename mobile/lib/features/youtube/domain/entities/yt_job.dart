import 'package:equatable/equatable.dart';

enum YtJobStatus {
  pending,
  downloading,
  converting,
  completed,
  failed;

  static YtJobStatus parse(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return YtJobStatus.pending;
      case 'downloading':
        return YtJobStatus.downloading;
      case 'converting':
        return YtJobStatus.converting;
      case 'completed':
        return YtJobStatus.completed;
      case 'failed':
        return YtJobStatus.failed;
      default:
        return YtJobStatus.failed;
    }
  }

  bool get isTerminal => this == completed || this == failed;
  bool get isCompleted => this == completed;
  bool get isFailed => this == failed;
}

class YtJob extends Equatable {
  const YtJob({
    required this.jobId,
    required this.status,
    this.progress = 0,
    this.title,
    this.thumbnailUrl,
    this.durationSec,
    this.errorCode,
    this.errorMessage,
  });

  final String jobId;
  final YtJobStatus status;
  final int progress;
  final String? title;
  final String? thumbnailUrl;
  final int? durationSec;
  final String? errorCode;
  final String? errorMessage;

  @override
  List<Object?> get props => <Object?>[
        jobId,
        status,
        progress,
        title,
        thumbnailUrl,
        durationSec,
        errorCode,
        errorMessage,
      ];
}
