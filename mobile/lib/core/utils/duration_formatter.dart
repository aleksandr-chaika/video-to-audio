/// Format Duration в строки `06:34` / `01:03:23` / `-2:38`.
class DurationFormatter {
  DurationFormatter._();

  static String format(Duration d) {
    final int totalSeconds = d.inSeconds.abs();
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final String hh = hours.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  /// Отрицательная длительность для оставшегося времени: `-2:38`.
  static String formatRemaining(Duration d) {
    final String s = format(d);
    return d.inSeconds <= 0 && s != '00:00' ? '-$s' : s;
  }
}
