part of 'history_bloc.dart';

sealed class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => <Object?>[];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.items);
  final List<HistoryItem> items;
  @override
  List<Object?> get props => <Object?>[items];
}

class HistoryError extends HistoryState {
  const HistoryError(this.message);
  final String message;
  @override
  List<Object?> get props => <Object?>[message];
}
