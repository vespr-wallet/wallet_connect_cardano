/// CIP-30 TxSendError from submitTx operations.
///
/// See: https://cips.cardano.org/cip/CIP-30#txsenderror
class CardanoTxSendError implements Exception {
  /// The transaction was refused.
  static const int refused = 1;
  /// The transaction failed to submit.
  static const int failure = 2;

  /// The error code.
  final int code;
  /// A human-readable description of the error.
  final String info;

  /// Creates a new [CardanoTxSendError].
  const CardanoTxSendError({required this.code, required this.info});

  /// Serializes this error to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'code': code, 'info': info};

  /// Deserializes a [CardanoTxSendError] from a JSON map.
  factory CardanoTxSendError.fromJson(Map<String, dynamic> json) =>
      CardanoTxSendError(code: json['code'] as int, info: json['info'] as String);

  @override
  String toString() => 'CardanoTxSendError(code: $code, info: $info)';
}
