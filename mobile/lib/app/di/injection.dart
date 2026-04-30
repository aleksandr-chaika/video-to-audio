import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../features/convert/data/datasources/ffmpeg_local_ds.dart';
import '../../features/convert/data/repositories/converter_repository_impl.dart';
import '../../features/convert/domain/repositories/converter_repository.dart';
import '../../features/convert/domain/usecases/convert_local_file.dart';
import '../../features/crop/data/datasources/ffmpeg_crop_ds.dart';
import '../../features/crop/data/repositories/crop_repository_impl.dart';
import '../../features/crop/domain/repositories/crop_repository.dart';
import '../../features/crop/domain/usecases/crop_audio.dart';
import '../../features/history/data/datasources/history_local_ds.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/add_history_item.dart';
import '../../features/history/domain/usecases/delete_history_item.dart';
import '../../features/history/domain/usecases/get_history.dart';
import '../../features/youtube/data/datasources/youtube_remote_ds.dart';
import '../../features/youtube/data/repositories/youtube_repository_impl.dart';
import '../../features/youtube/domain/repositories/youtube_repository.dart';
import '../../features/youtube/domain/usecases/create_youtube_job.dart';
import '../../features/youtube/domain/usecases/download_youtube_file.dart';
import '../../features/youtube/domain/usecases/poll_youtube_job.dart';

/// Глобальный сервис-локатор. Принципы:
/// - все зависимости регистрируются один раз в [configureDependencies]
/// - тесты могут переопределить (см. `getIt.reset()` + manual register).
final GetIt getIt = GetIt.instance;

/// Регистрирует все зависимости приложения. Вызывается из `main()` до runApp.
///
/// Параметр [apiBaseUrl] позволяет подменить URL backend'а (нужно для разных
/// окружений: симулятор iOS использует `http://127.0.0.1:8000`, физическое
/// устройство — IP машины).
Future<void> configureDependencies({String? apiBaseUrl}) async {
  if (getIt.isRegistered<Dio>()) {
    return;
  }
  final String resolvedBaseUrl = apiBaseUrl ?? ApiEndpoints.defaultBaseUrl;
  final String dbPath = p.join(await getDatabasesPath(), 'mp3craft.db');

  // Externals
  getIt
    ..registerLazySingleton<ApiEndpoints>(
      () => ApiEndpoints(baseUrl: resolvedBaseUrl),
    )
    ..registerLazySingleton<Dio>(
      () => createDio(getIt<ApiEndpoints>().baseUrl),
    );

  // History storage (async)
  final HistoryLocalDataSource historyDs =
      await HistoryLocalDataSource.create(dbPath);
  getIt.registerLazySingleton<HistoryLocalDataSource>(() => historyDs);

  // Datasources
  getIt
    ..registerLazySingleton<FfmpegLocalDataSource>(FfmpegLocalDataSource.new)
    ..registerLazySingleton<FfmpegCropDataSource>(FfmpegCropDataSource.new)
    ..registerLazySingleton<YoutubeRemoteDataSource>(
      () => YoutubeRemoteDataSource(getIt<Dio>(), getIt<ApiEndpoints>()),
    );

  // Repositories
  getIt
    ..registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(getIt<HistoryLocalDataSource>()),
    )
    ..registerLazySingleton<ConverterRepository>(
      () => ConverterRepositoryImpl(getIt<FfmpegLocalDataSource>()),
    )
    ..registerLazySingleton<CropRepository>(
      () => CropRepositoryImpl(getIt<FfmpegCropDataSource>()),
    )
    ..registerLazySingleton<YoutubeRepository>(
      () => YoutubeRepositoryImpl(getIt<YoutubeRemoteDataSource>()),
    );

  // Use cases
  getIt
    ..registerFactory<GetHistoryUseCase>(
      () => GetHistoryUseCase(getIt<HistoryRepository>()),
    )
    ..registerFactory<AddHistoryItemUseCase>(
      () => AddHistoryItemUseCase(getIt<HistoryRepository>()),
    )
    ..registerFactory<DeleteHistoryItemUseCase>(
      () => DeleteHistoryItemUseCase(getIt<HistoryRepository>()),
    )
    ..registerFactory<ConvertLocalFileUseCase>(
      () => ConvertLocalFileUseCase(getIt<ConverterRepository>()),
    )
    ..registerFactory<CropAudioUseCase>(
      () => CropAudioUseCase(getIt<CropRepository>()),
    )
    ..registerFactory<CreateYoutubeJobUseCase>(
      () => CreateYoutubeJobUseCase(getIt<YoutubeRepository>()),
    )
    ..registerFactory<PollYoutubeJobUseCase>(
      () => PollYoutubeJobUseCase(getIt<YoutubeRepository>()),
    )
    ..registerFactory<DownloadYoutubeFileUseCase>(
      () => DownloadYoutubeFileUseCase(getIt<YoutubeRepository>()),
    );
}
