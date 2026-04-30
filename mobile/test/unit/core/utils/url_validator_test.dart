import 'package:flutter_test/flutter_test.dart';
import 'package:mp3craft/core/utils/url_validator.dart';

void main() {
  group('YouTubeUrlValidator', () {
    test('accepts standard youtube.com/watch URL', () {
      expect(
        YouTubeUrlValidator.isValid('https://youtube.com/watch?v=dQw4w9WgXcQ'),
        isTrue,
      );
    });

    test('accepts youtu.be short URL', () {
      expect(
        YouTubeUrlValidator.isValid('https://youtu.be/dQw4w9WgXcQ'),
        isTrue,
      );
    });

    test('accepts shorts URL', () {
      expect(
        YouTubeUrlValidator.isValid('https://youtube.com/shorts/abc123'),
        isTrue,
      );
    });

    test('rejects non-YouTube host', () {
      expect(
        YouTubeUrlValidator.isValid('https://example.com/watch?v=foo'),
        isFalse,
      );
    });

    test('rejects URL without scheme', () {
      expect(YouTubeUrlValidator.isValid('youtube.com/watch?v=x'), isFalse);
    });

    test('rejects empty string', () {
      expect(YouTubeUrlValidator.isValid('   '), isFalse);
    });

    test('rejects youtube.com without v param', () {
      expect(
        YouTubeUrlValidator.isValid('https://youtube.com/watch'),
        isFalse,
      );
    });
  });
}
