import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/yt_job.dart';
import '../../domain/usecases/create_youtube_job.dart';
import '../../domain/usecases/download_youtube_file.dart';
import '../../domain/usecases/poll_youtube_job.dart';

part 'youtube_event.dart';
part 'youtube_state.dart';

class YoutubeBloc extends Bloc<YoutubeEvent, YoutubeState> {
  YoutubeBloc({
    required CreateYoutubeJobUseCase createJob,
    required PollYoutubeJobUseCase pollJob,
    required DownloadYoutubeFileUseCase downloadFile,
  })  : _createJob = createJob,
        _pollJob = pollJob,
        _downloadFile = downloadFile,
        super(const YoutubeIdle()) {
    on<YoutubeExtractRequested>(_onExtract);
    on<YoutubeReset>((_, Emitter<YoutubeState> emit) =>
        emit(const YoutubeIdle()));
  }

  final CreateYoutubeJobUseCase _createJob;
  final PollYoutubeJobUseCase _pollJob;
  final DownloadYoutubeFileUseCase _downloadFile;

  Future<void> _onExtract(
      YoutubeExtractRequested event, Emitter<YoutubeState> emit) async {
    emit(const YoutubeCreating());
    final result = await _createJob(event.url);

    YtJob? job;
    Failure? failure;
    result.fold((l) => failure = l, (r) => job = r);
    if (failure != null || job == null) {
      emit(YoutubeFailure(failure?.message ?? 'Не удалось создать задачу'));
      return;
    }

    final String jobId = job!.jobId;
    emit(YoutubePolling(job!));

    final Stream<Either<Failure, YtJob>> stream = _pollJob(jobId);
    await for (final Either<Failure, YtJob> tick in stream) {
      bool shouldStop = false;
      tick.fold(
        (Failure l) {
          emit(YoutubeFailure(l.message));
          shouldStop = true;
        },
        (YtJob updated) {
          if (updated.status.isCompleted) {
            shouldStop = true;
          } else if (updated.status.isFailed) {
            emit(YoutubeFailure(
                updated.errorMessage ?? 'Сервер не смог обработать видео'));
            shouldStop = true;
            return;
          }
          emit(YoutubePolling(updated));
        },
      );
      if (shouldStop) {
        // Если completed — переходим к скачиванию.
        if (state is YoutubePolling &&
            (state as YoutubePolling).job.status.isCompleted) {
          await _downloadAndEmit(emit, (state as YoutubePolling).job, event.targetDir);
        }
        return;
      }
    }
  }

  Future<void> _downloadAndEmit(
      Emitter<YoutubeState> emit, YtJob job, String targetDir) async {
    emit(YoutubeDownloading(job));
    final result = await _downloadFile(
      DownloadYoutubeFileParams(jobId: job.jobId, targetDir: targetDir),
    );
    result.fold(
      (Failure l) => emit(YoutubeFailure(l.message)),
      (String path) => emit(YoutubeDone(job: job, filePath: path)),
    );
  }

}
