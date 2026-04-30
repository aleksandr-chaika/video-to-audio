import 'package:flutter_test/flutter_test.dart';
import 'package:mp3craft/core/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter.format', () {
    test('formats sub-hour duration as MM:SS', () {
      expect(DurationFormatter.format(const Duration(seconds: 394)), '06:34');
      expect(DurationFormatter.format(const Duration(seconds: 0)), '00:00');
      expect(DurationFormatter.format(const Duration(seconds: 5)), '00:05');
    });

    test('formats hour-or-more duration as HH:MM:SS', () {
      expect(
        DurationFormatter.format(const Duration(seconds: 3803)),
        '01:03:23',
      );
    });
  });

  group('DurationFormatter.formatRemaining', () {
    test('formats negative duration with leading dash', () {
      expect(
        DurationFormatter.formatRemaining(const Duration(seconds: -158)),
        '-02:38',
      );
    });
    test('zero stays zero', () {
      expect(DurationFormatter.formatRemaining(Duration.zero), '00:00');
    });
  });
}
