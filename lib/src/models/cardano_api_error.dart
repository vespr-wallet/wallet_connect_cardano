/// CIP-30 APIError for the dApp-wallet bridge.
///
/// See: https://cips.cardano.org/cip/CIP-30#apierror
class CardanoApiError implements Exception {
  /// The request was rejected due to invalid parameters.
  static const int invalidRequest = -1;
  /// An internal wallet error occurred.
  static const int internalError = -2;
  /// The request was refused by the user or wallet.
  static const int refused = -3;
  /// The account has changed since the request was made.
  static const int accountChange = -4;

  /// The error code.
  final int code;
  /// A human-readable description of the error.
  final String info;

  /// Creates a new [CardanoApiError].
  const CardanoApiError({required this.code, required this.info});

  /// Serializes this error to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'code': code, 'info': info};

  /// Deserializes a [CardanoApiError] from a JSON map.
  factory CardanoApiError.fromJson(Map<String, dynamic> json) =>
      CardanoApiError(code: json['code'] as int, info: json['info'] as String);

  @override
  String toString() => 'CardanoApiError(code: $code, info: $info)';
}
