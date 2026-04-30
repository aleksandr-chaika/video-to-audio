import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/crop_audio.dart';

part 'crop_event.dart';
part 'crop_state.dart';

class CropBloc extends Bloc<CropEvent, CropState> {
  CropBloc({required CropAudioUseCase cropUseCase})
      : _cropUseCase = cropUseCase,
        super(const CropInitial()) {
    on<CropLoaded>((CropLoaded e, Emitter<CropState> emit) {
      emit(CropReady(
        sourcePath: e.sourcePath,
        total: e.total,
        start: Duration.zero,
        end: e.total,
      ));
    });
    on<CropRangeChanged>((CropRangeChanged e, Emitter<CropState> emit) {
      final CropState s = state;
      if (s is! CropReady) return;
      emit(s.copyWith(start: e.start, end: e.end));
    });
    on<CropSaveRequested>(_onSave);
  }

  final CropAudioUseCase _cropUseCase;

  Future<void> _onSave(
      CropSaveRequested event, Emitter<CropState> emit) async {
    final CropState s = state;
    if (s is! CropReady) return;
    emit(CropSaving(s.sourcePath, s.total, s.start, s.end));
    final result = await _cropUseCase(
      CropAudioParams(
        sourcePath: s.sourcePath,
        start: s.start,
        end: s.end,
      ),
    );
    result.fold(
      (l) => emit(CropError(l.message, s)),
      (path) => emit(CropSaved(path, s.end - s.start)),
    );
  }
}
