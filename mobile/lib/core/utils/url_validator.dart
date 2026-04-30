/// Валидация YouTube-URL до отправки на backend.
class YouTubeUrlValidator {
  YouTubeUrlValidator._();

  static const Set<String> _allowedHosts = <String>{
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtu.be',
  };

  static bool isValid(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    final String host = uri.host.toLowerCase();
    if (!_allowedHosts.contains(host)) return false;
    // youtu.be — короткая ссылка, /<id>
    if (host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty && uri.pathSegments.first.isNotEmpty;
    }
    if (uri.path == '/watch') {
      return uri.queryParameters.containsKey('v') &&
          (uri.queryParameters['v']?.isNotEmpty ?? false);
    }
    if (uri.pathSegments.isNotEmpty &&
        (uri.pathSegments.first == 'shorts' ||
            uri.pathSegments.first == 'embed')) {
      return uri.pathSegments.length > 1 && uri.pathSegments[1].isNotEmpty;
    }
    return false;
  }
}
