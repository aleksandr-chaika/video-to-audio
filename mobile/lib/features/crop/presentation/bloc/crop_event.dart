part of 'crop_bloc.dart';

sealed class CropEvent extends Equatable {
  const CropEvent();
  @override
  List<Object?> get props => <Object?>[];
}

class CropLoaded extends CropEvent {
  const CropLoaded({required this.sourcePath, required this.total});
  final String sourcePath;
  final Duration total;
  @override
  List<Object?> get props => <Object?>[sourcePath, total];
}

class CropRangeChanged extends CropEvent {
  const CropRangeChanged({required this.start, required this.end});
  final Duration start;
  final Duration end;
  @override
  List<Object?> get props => <Object?>[start, end];
}

class CropSaveRequested extends CropEvent {
  const CropSaveRequested();
}
