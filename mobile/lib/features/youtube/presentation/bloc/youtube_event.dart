part of 'youtube_bloc.dart';

sealed class YoutubeEvent extends Equatable {
  const YoutubeEvent();
  @override
  List<Object?> get props => <Object?>[];
}

class YoutubeExtractRequested extends YoutubeEvent {
  const YoutubeExtractRequested({required this.url, required this.targetDir});
  final String url;
  final String targetDir;
  @override
  List<Object?> get props => <Object?>[url, targetDir];
}

class YoutubeReset extends YoutubeEvent {
  const YoutubeReset();
}
