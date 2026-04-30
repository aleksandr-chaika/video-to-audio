part of 'youtube_bloc.dart';

sealed class YoutubeState extends Equatable {
  const YoutubeState();
  @override
  List<Object?> get props => <Object?>[];
}

class YoutubeIdle extends YoutubeState {
  const YoutubeIdle();
}

class YoutubeCreating extends YoutubeState {
  const YoutubeCreating();
}

class YoutubePolling extends YoutubeState {
  const YoutubePolling(this.job);
  final YtJob job;
  @override
  List<Object?> get props => <Object?>[job];
}

class YoutubeDownloading extends YoutubeState {
  const YoutubeDownloading(this.job);
  final YtJob job;
  @override
  List<Object?> get props => <Object?>[job];
}

class YoutubeDone extends YoutubeState {
  const YoutubeDone({required this.job, required this.filePath});
  final YtJob job;
  final String filePath;
  @override
  List<Object?> get props => <Object?>[job, filePath];
}

class YoutubeFailure extends YoutubeState {
  const YoutubeFailure(this.message);
  final String message;
  @override
  List<Object?> get props => <Object?>[message];
}
