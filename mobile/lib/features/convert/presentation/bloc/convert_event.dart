part of 'convert_bloc.dart';

sealed class ConvertEvent extends Equatable {
  const ConvertEvent();
  @override
  List<Object?> get props => <Object?>[];
}

class ConvertStarted extends ConvertEvent {
  const ConvertStarted(this.sourcePath);
  final String sourcePath;
  @override
  List<Object?> get props => <Object?>[sourcePath];
}

class ConvertReset extends ConvertEvent {
  const ConvertReset();
}
