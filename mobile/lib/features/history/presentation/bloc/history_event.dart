part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => <Object?>[];
}

class HistoryLoadRequested extends HistoryEvent {
  const HistoryLoadRequested();
}

class HistoryItemAdded extends HistoryEvent {
  const HistoryItemAdded(this.item);
  final HistoryItem item;
  @override
  List<Object?> get props => <Object?>[item];
}

class HistoryItemDeleted extends HistoryEvent {
  const HistoryItemDeleted(this.id);
  final int id;
  @override
  List<Object?> get props => <Object?>[id];
}
