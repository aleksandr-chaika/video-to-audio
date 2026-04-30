import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/history/domain/usecases/add_history_item.dart';
import '../features/history/domain/usecases/delete_history_item.dart';
import '../features/history/domain/usecases/get_history.dart';
import '../features/history/presentation/bloc/history_bloc.dart';
import '../features/home/presentation/bloc/home_bloc.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MP3CraftApp extends StatelessWidget {
  MP3CraftApp({super.key}) : _router = buildRouter();

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<HistoryBloc>(
          lazy: false,
          create: (_) => HistoryBloc(
            getHistory: getIt<GetHistoryUseCase>(),
            addItem: getIt<AddHistoryItemUseCase>(),
            deleteItem: getIt<DeleteHistoryItemUseCase>(),
          )..add(const HistoryLoadRequested()),
        ),
        BlocProvider<HomeBloc>(create: (_) => HomeBloc()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MP3 Craft',
        theme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}
