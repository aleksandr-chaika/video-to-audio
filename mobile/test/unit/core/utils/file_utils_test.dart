import 'package:flutter_test/flutter_test.dart';
import 'package:mp3craft/core/utils/file_utils.dart';

void main() {
  group('FileUtils', () {
    test('extensionOf returns lowercase extension without dot', () {
      expect(FileUtils.extensionOf('/tmp/file.MP3'), 'mp3');
      expect(FileUtils.extensionOf('/a/b/c.mp4'), 'mp4');
      expect(FileUtils.extensionOf('/a/b/c.WAV'), 'wav');
    });

    test('isMp3/isMp4/isWav', () {
      expect(FileUtils.isMp3('/x.mp3'), isTrue);
      expect(FileUtils.isMp4('/x.mp4'), isTrue);
      expect(FileUtils.isWav('/x.WAV'), isTrue);
      expect(FileUtils.isMp3('/x.wav'), isFalse);
    });

    test('isVideo treats common video extensions', () {
      expect(FileUtils.isVideo('/a.mp4'), isTrue);
      expect(FileUtils.isVideo('/a.MOV'), isTrue);
      expect(FileUtils.isVideo('/a.mp3'), isFalse);
    });

    test('basenameWithoutExt strips extension', () {
      expect(FileUtils.basenameWithoutExt('/a/b/track.mp3'), 'track');
    });
  });
}
