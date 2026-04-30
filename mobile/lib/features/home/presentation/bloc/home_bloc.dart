import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeState extends Equatable {
  const HomeState({this.youtubeUrl = ''});
  final String youtubeUrl;

  HomeState copyWith({String? youtubeUrl}) =>
      HomeState(youtubeUrl: youtubeUrl ?? this.youtubeUrl);

  @override
  List<Object?> get props => <Object?>[youtubeUrl];
}

abstract class HomeEvent {
  const HomeEvent();
}

class HomeUrlChanged extends HomeEvent {
  const HomeUrlChanged(this.url);
  final String url;
}

/// Лёгкий cubit для домашнего экрана: трекает текущее значение URL-инпута
/// без избыточной логики (та живёт в YoutubeBloc / ConvertBloc).
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<HomeUrlChanged>(
      (HomeUrlChanged e, Emitter<HomeState> emit) =>
          emit(state.copyWith(youtubeUrl: e.url)),
    );
  }
}
