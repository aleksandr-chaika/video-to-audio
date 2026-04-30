import 'package:flutter_test/flutter_test.dart';
import 'package:mp3craft/features/youtube/domain/entities/yt_job.dart';

void main() {
  group('YtJobStatus.parse', () {
    test('parses known statuses case-insensitively', () {
      expect(YtJobStatus.parse('pending'), YtJobStatus.pending);
      expect(YtJobStatus.parse('DOWNLOADING'), YtJobStatus.downloading);
      expect(YtJobStatus.parse('Converting'), YtJobStatus.converting);
      expect(YtJobStatus.parse('completed'), YtJobStatus.completed);
      expect(YtJobStatus.parse('failed'), YtJobStatus.failed);
    });

    test('falls back to failed on unknown / null', () {
      expect(YtJobStatus.parse('???'), YtJobStatus.failed);
      expect(YtJobStatus.parse(null), YtJobStatus.failed);
    });
  });

  group('YtJobStatus.isTerminal', () {
    test('completed is terminal', () {
      expect(YtJobStatus.completed.isTerminal, isTrue);
    });
    test('failed is terminal', () {
      expect(YtJobStatus.failed.isTerminal, isTrue);
    });
    test('pending/downloading/converting are not terminal', () {
      expect(YtJobStatus.pending.isTerminal, isFalse);
      expect(YtJobStatus.downloading.isTerminal, isFalse);
      expect(YtJobStatus.converting.isTerminal, isFalse);
    });
  });
}
