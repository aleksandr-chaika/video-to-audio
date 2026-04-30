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

  HistoryItem sample() => HistoryItem(
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
        (_) async => Right<Failure, List<HistoryItem>>(<HistoryItem>[sample()]),
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
        (_) async => Right<Failure, HistoryItem>(sample()),
      );
      when(() => getHistory(any())).thenAnswer(
        (_) async => Right<Failure, List<HistoryItem>>(<HistoryItem>[sample()]),
      );
      return build();
    },
    act: (HistoryBloc bloc) => bloc.add(HistoryItemAdded(sample())),
    wait: const Duration(milliseconds: 50),
    verify: (HistoryBloc _) {
      verify(() => addItem(any())).called(1);
      verify(() => getHistory(any())).called(1);
    },
  );

  // ---- regression: FE-1 — silent data loss при Left из usecase ----

  blocTest<HistoryBloc, HistoryState>(
    'add emits HistoryError when AddItemUseCase returns Left',
    build: () {
      when(() => addItem(any())).thenAnswer(
        (_) async => const Left<Failure, HistoryItem>(StorageFailure('disk full')),
      );
      return build();
    },
    act: (HistoryBloc bloc) => bloc.add(HistoryItemAdded(sample())),
    expect: () => <Matcher>[
      isA<HistoryError>(),
    ],
    verify: (HistoryBloc _) {
      verify(() => addItem(any())).called(1);
      verifyNever(() => getHistory(any()));
    },
  );

  blocTest<HistoryBloc, HistoryState>(
    'delete emits HistoryError when DeleteItemUseCase returns Left',
    build: () {
      when(() => deleteItem(any())).thenAnswer(
        (_) async => const Left<Failure, Unit>(StorageFailure('locked')),
      );
      return build();
    },
    act: (HistoryBloc bloc) => bloc.add(const HistoryItemDeleted(1)),
    expect: () => <Matcher>[
      isA<HistoryError>(),
    ],
    verify: (HistoryBloc _) {
      verify(() => deleteItem(any())).called(1);
      verifyNever(() => getHistory(any()));
    },
  );

  blocTest<HistoryBloc, HistoryState>(
    'delete then triggers reload on success',
    build: () {
      when(() => deleteItem(any())).thenAnswer(
        (_) async => const Right<Failure, Unit>(unit),
      );
      when(() => getHistory(any())).thenAnswer(
        (_) async => const Right<Failure, List<HistoryItem>>(<HistoryItem>[]),
      );
      return build();
    },
    act: (HistoryBloc bloc) => bloc.add(const HistoryItemDeleted(1)),
    wait: const Duration(milliseconds: 50),
    verify: (HistoryBloc _) {
      verify(() => deleteItem(any())).called(1);
      verify(() => getHistory(any())).called(1);
    },
  );
}
