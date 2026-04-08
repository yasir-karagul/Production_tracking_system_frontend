import '../constants/app_constants.dart';

/// Resolves pattern image references from API/cache into display-ready values.
class PatternImageUtils {
  PatternImageUtils._();

  static String? resolvePatternImageRef(Map<String, dynamic>? pattern) {
    if (pattern == null) return null;
    final raw = pattern['local_image_path'] ??
        pattern['localImagePath'] ??
        pattern['image_url'] ??
        pattern['imageUrl'] ??
        pattern['thumbnail_url'] ??
        pattern['thumbnailUrl'];
    return resolveImageRef(raw?.toString());
  }

  static String? resolveImageRef(String? rawValue) {
    final value = rawValue?.trim();
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('file://')) return value;
    if (_looksLikeWindowsPath(value)) return Uri.file(value).toString();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri != null) {
        final host = uri.host.toLowerCase();
        if (host == 'localhost' || host == '127.0.0.1') {
          final apiUri = Uri.parse(AppConstants.baseUrl);
          return uri.replace(host: apiUri.host).toString();
        }
      }
      return value;
    }

    final base = AppConstants.baseUrl.replaceFirst(
      RegExp(r'/api(?:/v\d+)?/?$'),
      '',
    );
    if (value.startsWith('/')) return '$base$value';
    return '$base/$value';
  }

  static bool isLocalFileRef(String? value) {
    if (value == null || value.isEmpty) return false;
    return value.startsWith('file://') || _looksLikeWindowsPath(value);
  }

  static bool _looksLikeWindowsPath(String value) {
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value) ||
        value.startsWith(r'\\');
  }
}
