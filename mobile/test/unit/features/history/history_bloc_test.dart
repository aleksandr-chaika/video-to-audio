import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mp3craft/core/error/failures.dart';
import 'package:mp3craft/core/usecase/usecase.dart';
import 'package:mp3craft/features/history/domain/entities/history_item.dart';
import 'package:mp3craft/features/history/domain/usecases/add_history_item.dart';
import 'package:mp3craft/features/history/domain/usecases/delete_history_item.dart';
import 'package:mp3craft/features/history/domain/usecases/get_history.dart';
import 'package:mp3craft/features/history/presentation/bloc/history_bloc.dart';

class _MockGetHistory extends Mock implements GetHistoryUseCase {}

class _MockAddItem extends Mock implements AddHistoryItemUseCase {}

class _MockDeleteItem extends Mock implements DeleteHistoryItemUseCase {}

void main() {
  late _MockGetHistory getHistory;
  late _MockAddItem addItem;
  late _MockDeleteItem deleteItem;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      HistoryItem(
        id: null,
        sourceType: SourceType.local,
        sourceFormat: SourceFormat.mp3,
        outputFormat: SourceFormat.wav,
        filePath: '/x',
        durationMs: 0,
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    getHistory = _MockGetHistory();
    addItem = _MockAddItem();
    deleteItem = _MockDeleteItem();
  });

  HistoryBloc build() => HistoryBloc(
        getHistory: getHistory,
        addItem: addItem,
        deleteItem: deleteItem,
      );

  HistoryItem _sample() => HistoryItem(
        id: 1,
        sourceType: SourceType.youtube,
        sourceFormat: SourceFormat.mp4,
        outputFormat: SourceFormat.wav,
        filePath: '/x.wav',
        durationMs: 1000,
        createdAt: DateTime(2026),
      );

  blocTest<HistoryBloc, HistoryState>(
    'emits loading → empty when repository returns empty list',
    build: () {
      when(() => getHistory(any())).thenAnswer(
        (_) async => const Right<Failure, List<HistoryItem>>(<HistoryItem>[]),
      );
      return build();
    },
    act: (HistoryBloc bloc) => bloc.add(const HistoryLoadRequested()),
    expect: () => <Matcher>[
      isA<HistoryLoading>(),
      isA<HistoryEmpty>(),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'emits loading → loaded when repository returns items',
    build: () {
      when(() => getHistory(any())).thenAnswer(
        (_) async => Right<Failure, List<HistoryItem>>(<HistoryItem>[_sample()]),
      );
      return build();
    },
    act: (HistoryBloc bloc) => bloc.add(const HistoryLoadRequested()),
    expect: () => <Matcher>[
      isA<HistoryLoading>(),
      isA<HistoryLoaded>(),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'emits error when repository fails',
    build: () {
      when(() => getHistory(any())).thenAnswer(
        (_) async => const Left<Failure, List<HistoryItem>>(StorageFailure('boom')),
      );
      return build();
    },
    act: (HistoryBloc bloc) => bloc.add(const HistoryLoadRequested()),
    expect: () => <Matcher>[
      isA<HistoryLoading>(),
      isA<HistoryError>(),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'add then triggers reload',
    build: () {
      when(() => addItem(any())).thenAnswer(
        (_) async => Right<Failure, HistoryItem>(_sample()),
      );
      when(() => getHistory(any())).thenAnswer(
        (_) async => Right<Failure, List<HistoryItem>>(<HistoryItem>[_sample()]),
      );
      return build();
    },
    act: (HistoryBloc bloc) => bloc.add(HistoryItemAdded(_sample())),
    wait: const Duration(milliseconds: 50),
    verify: (HistoryBloc _) {
      verify(() => addItem(any())).called(1);
      verify(() => getHistory(any())).called(1);
    },
  );
}
