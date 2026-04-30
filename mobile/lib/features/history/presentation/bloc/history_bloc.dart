import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/usecases/add_history_item.dart';
import '../../domain/usecases/delete_history_item.dart';
import '../../domain/usecases/get_history.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({
    required GetHistoryUseCase getHistory,
    required AddHistoryItemUseCase addItem,
    required DeleteHistoryItemUseCase deleteItem,
  })  : _getHistory = getHistory,
        _addItem = addItem,
        _deleteItem = deleteItem,
        super(const HistoryInitial()) {
    on<HistoryLoadRequested>(_onLoad);
    on<HistoryItemAdded>(_onAdd);
    on<HistoryItemDeleted>(_onDelete);
  }

  final GetHistoryUseCase _getHistory;
  final AddHistoryItemUseCase _addItem;
  final DeleteHistoryItemUseCase _deleteItem;

  Future<void> _onLoad(
      HistoryLoadRequested event, Emitter<HistoryState> emit) async {
    emit(const HistoryLoading());
    final result = await _getHistory(const NoParams());
    result.fold(
      (l) => emit(HistoryError(l.message)),
      (items) => emit(items.isEmpty ? const HistoryEmpty() : HistoryLoaded(items)),
    );
  }

  Future<void> _onAdd(
      HistoryItemAdded event, Emitter<HistoryState> emit) async {
    final result = await _addItem(event.item);
    result.fold(
      (l) => emit(HistoryError(l.message)),
      (_) => add(const HistoryLoadRequested()),
    );
  }

  Future<void> _onDelete(
      HistoryItemDeleted event, Emitter<HistoryState> emit) async {
    final result = await _deleteItem(event.id);
    result.fold(
      (l) => emit(HistoryError(l.message)),
      (_) => add(const HistoryLoadRequested()),
    );
  }
}
