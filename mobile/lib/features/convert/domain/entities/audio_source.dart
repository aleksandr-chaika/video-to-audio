import 'package:equatable/equatable.dart';

class AudioSource extends Equatable {
  const AudioSource({required this.path, required this.isVideo});

  final String path;
  final bool isVideo;

  @override
  List<Object?> get props => <Object?>[path, isVideo];
}
