/// Service health states of the official v4 API.
enum HealthStatus {
  ok('ok'),
  degraded('degraded'),
  down('down');

  const HealthStatus(this.value);

  final String value;
}

/// The official v4 service health status.
final class HealthResult {
  const HealthResult({required this.status, required this.timestamp});

  final HealthStatus status;

  /// Raw `date-time` string. It is not parsed.
  final String timestamp;
}
