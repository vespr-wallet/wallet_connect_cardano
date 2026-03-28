/// CIP-30 DataSignError from signData operations.
///
/// See: https://cips.cardano.org/cip/CIP-30#datasignerror
class CardanoDataSignError implements Exception {
  /// Wallet could not construct the proof.
  static const int proofGeneration = 1;
  /// The address is not a public key address (not P2PKH).
  static const int addressNotPK = 2;
  /// The user declined the signing request.
  static const int userDeclined = 3;

  /// The error code.
  final int code;
  /// A human-readable description of the error.
  final String info;

  /// Creates a new [CardanoDataSignError].
  const CardanoDataSignError({required this.code, required this.info});

  /// Serializes this error to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'code': code, 'info': info};

  /// Deserializes a [CardanoDataSignError] from a JSON map.
  factory CardanoDataSignError.fromJson(Map<String, dynamic> json) =>
      CardanoDataSignError(code: json['code'] as int, info: json['info'] as String);

  @override
  String toString() => 'CardanoDataSignError(code: $code, info: $info)';
}
