import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/convert/presentation/bloc/convert_bloc.dart';
import '../../features/convert/presentation/pages/processing_page.dart';
import '../../features/crop/presentation/bloc/crop_bloc.dart';
import '../../features/crop/presentation/pages/crop_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/result/domain/entities/result_payload.dart';
import '../../features/result/presentation/pages/result_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/youtube/presentation/bloc/youtube_bloc.dart';
import '../../features/youtube/presentation/pages/youtube_page.dart';
import '../../features/convert/domain/usecases/convert_local_file.dart';
import '../../features/crop/domain/usecases/crop_audio.dart';
import '../../features/youtube/domain/usecases/create_youtube_job.dart';
import '../../features/youtube/domain/usecases/download_youtube_file.dart';
import '../../features/youtube/domain/usecases/poll_youtube_job.dart';
import '../di/injection.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext _, GoRouterState state) {
          final _ = state;
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/processing',
        builder: (BuildContext _, GoRouterState state) {
          final String sourcePath = state.extra! as String;
          return BlocProvider<ConvertBloc>(
            create: (_) => ConvertBloc(
              convertUseCase: getIt<ConvertLocalFileUseCase>(),
            ),
            child: ProcessingPage(sourcePath: sourcePath),
          );
        },
      ),
      GoRoute(
        path: '/youtube',
        builder: (BuildContext _, GoRouterState state) {
          final String url = state.extra! as String;
          return BlocProvider<YoutubeBloc>(
            create: (_) => YoutubeBloc(
              createJob: getIt<CreateYoutubeJobUseCase>(),
              pollJob: getIt<PollYoutubeJobUseCase>(),
              downloadFile: getIt<DownloadYoutubeFileUseCase>(),
            ),
            child: YoutubePage(url: url),
          );
        },
      ),
      GoRoute(
        path: '/result',
        builder: (BuildContext _, GoRouterState state) {
          final ResultPayload payload =
              ResultPayload.fromMap(state.extra! as Map<String, Object?>);
          return ResultPage(payload: payload);
        },
      ),
      GoRoute(
        path: '/crop',
        builder: (BuildContext _, GoRouterState state) {
          final Map<String, Object?> args =
              state.extra! as Map<String, Object?>;
          return BlocProvider<CropBloc>(
            create: (_) =>
                CropBloc(cropUseCase: getIt<CropAudioUseCase>()),
            child: CropPage(
              sourcePath: args['path'] as String,
              totalMs: (args['durationMs'] as int?) ?? 0,
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext _, GoRouterState state) {
          final _ = state;
          return const SettingsPage();
        },
      ),
    ],
  );
}
