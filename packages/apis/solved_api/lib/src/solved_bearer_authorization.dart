/// Internal validated capability for a solved-proxy Bearer header.
///
/// This file is intentionally not exported from `solved_api.dart`.
final class SolvedBearerAuthorization {
  SolvedBearerAuthorization._(this._headerValue);

  factory SolvedBearerAuthorization.fromAccessToken(String accessToken) {
    validateAccessToken(accessToken);
    return SolvedBearerAuthorization._('Bearer $accessToken');
  }

  static const int maximumHeaderValueBytes = 4096;
  static const int maximumTokenBytes = 4089;

  static final RegExp _tokenPattern = RegExp(r'[A-Za-z0-9\-._~+/]+={0,}');

  final String _headerValue;

  String get headerValue => _headerValue;

  static void validateAccessToken(String accessToken) {
    if (accessToken.length > maximumTokenBytes) {
      throw const FormatException('access_token is not a valid Bearer token');
    }
    final match = _tokenPattern.matchAsPrefix(accessToken);
    if (match == null || match.end != accessToken.length) {
      throw const FormatException('access_token is not a valid Bearer token');
    }
  }

  @override
  String toString() => 'SolvedBearerAuthorization(<redacted>)';
}
