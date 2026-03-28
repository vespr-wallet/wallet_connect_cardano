/// CIP-30 DataSignature — result of a signData operation.
///
/// See: https://cips.cardano.org/cip/CIP-30#datasignature
class CardanoDataSignature {
  /// Hex-encoded CBOR of COSE_Sign1.
  final String signature;
  /// Hex-encoded CBOR of COSE_Key.
  final String key;

  /// Creates a new [CardanoDataSignature].
  const CardanoDataSignature({required this.signature, required this.key});

  /// Serializes this to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'signature': signature, 'key': key};

  /// Deserializes a [CardanoDataSignature] from a JSON map.
  factory CardanoDataSignature.fromJson(Map<String, dynamic> json) =>
      CardanoDataSignature(
        signature: json['signature'] as String,
        key: json['key'] as String,
      );

  @override
  String toString() => 'CardanoDataSignature(signature: $signature, key: $key)';
}
