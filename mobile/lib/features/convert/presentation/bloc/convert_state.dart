part of 'convert_bloc.dart';

sealed class ConvertState extends Equatable {
  const ConvertState();
  @override
  List<Object?> get props => <Object?>[];
}

class ConvertIdle extends ConvertState {
  const ConvertIdle();
}

class ConvertProcessing extends ConvertState {
  const ConvertProcessing();
}

class ConvertDone extends ConvertState {
  const ConvertDone({
    required this.wavPath,
    required this.durationMs,
    required this.sourcePath,
  });
  final String wavPath;
  final int durationMs;
  final String sourcePath;
  @override
  List<Object?> get props => <Object?>[wavPath, durationMs, sourcePath];
}

class ConvertFailure extends ConvertState {
  const ConvertFailure(this.message);
  final String message;
  @override
  List<Object?> get props => <Object?>[message];
}
