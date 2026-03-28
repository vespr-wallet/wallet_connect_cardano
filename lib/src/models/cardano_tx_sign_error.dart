/// CIP-30 TxSignError from signTx operations.
///
/// See: https://cips.cardano.org/cip/CIP-30#txsignerror
class CardanoTxSignError implements Exception {
  /// Wallet could not construct the witness.
  static const int proofGeneration = 1;
  /// The user declined the signing request.
  static const int userDeclined = 2;

  /// The error code.
  final int code;
  /// A human-readable description of the error.
  final String info;

  /// Creates a new [CardanoTxSignError].
  const CardanoTxSignError({required this.code, required this.info});

  /// Serializes this error to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'code': code, 'info': info};

  /// Deserializes a [CardanoTxSignError] from a JSON map.
  factory CardanoTxSignError.fromJson(Map<String, dynamic> json) =>
      CardanoTxSignError(code: json['code'] as int, info: json['info'] as String);

  @override
  String toString() => 'CardanoTxSignError(code: $code, info: $info)';
}
