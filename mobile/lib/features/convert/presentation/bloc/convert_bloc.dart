import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/convert_local_file.dart';

part 'convert_event.dart';
part 'convert_state.dart';

class ConvertBloc extends Bloc<ConvertEvent, ConvertState> {
  ConvertBloc({required ConvertLocalFileUseCase convertUseCase})
      : _convertUseCase = convertUseCase,
        super(const ConvertIdle()) {
    on<ConvertStarted>(_onStarted);
    on<ConvertReset>((_, Emitter<ConvertState> emit) => emit(const ConvertIdle()));
  }

  final ConvertLocalFileUseCase _convertUseCase;

  Future<void> _onStarted(
      ConvertStarted event, Emitter<ConvertState> emit) async {
    emit(const ConvertProcessing());
    final result = await _convertUseCase(event.sourcePath);
    result.fold(
      (l) => emit(ConvertFailure(l.message)),
      (audio) => emit(ConvertDone(
        wavPath: audio.path,
        durationMs: audio.durationMs,
        sourcePath: event.sourcePath,
      )),
    );
  }
}
