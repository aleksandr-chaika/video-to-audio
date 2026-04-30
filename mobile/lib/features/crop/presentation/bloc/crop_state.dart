part of 'crop_bloc.dart';

sealed class CropState extends Equatable {
  const CropState();
  @override
  List<Object?> get props => <Object?>[];
}

class CropInitial extends CropState {
  const CropInitial();
}

class CropReady extends CropState {
  const CropReady({
    required this.sourcePath,
    required this.total,
    required this.start,
    required this.end,
  });

  final String sourcePath;
  final Duration total;
  final Duration start;
  final Duration end;

  Duration get selected => end - start;

  CropReady copyWith({Duration? start, Duration? end}) => CropReady(
        sourcePath: sourcePath,
        total: total,
        start: start ?? this.start,
        end: end ?? this.end,
      );

  @override
  List<Object?> get props => <Object?>[sourcePath, total, start, end];
}

class CropSaving extends CropState {
  const CropSaving(this.sourcePath, this.total, this.start, this.end);
  final String sourcePath;
  final Duration total;
  final Duration start;
  final Duration end;
  @override
  List<Object?> get props => <Object?>[sourcePath, total, start, end];
}

class CropSaved extends CropState {
  const CropSaved(this.outputPath, this.duration);
  final String outputPath;
  final Duration duration;
  @override
  List<Object?> get props => <Object?>[outputPath, duration];
}

class CropError extends CropState {
  const CropError(this.message, this.previous);
  final String message;
  final CropReady previous;
  @override
  List<Object?> get props => <Object?>[message, previous];
}
