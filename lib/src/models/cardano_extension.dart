/// CIP-30 Extension — describes a CIP number extending the base API.
///
/// See: https://cips.cardano.org/cip/CIP-30#extension
class CardanoExtension {
  /// The CIP number of the extension.
  final int cip;

  /// Creates a new [CardanoExtension].
  const CardanoExtension({required this.cip});

  /// Serializes this to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'cip': cip};

  /// Deserializes a [CardanoExtension] from a JSON map.
  factory CardanoExtension.fromJson(Map<String, dynamic> json) =>
      CardanoExtension(cip: json['cip'] as int);

  @override
  String toString() => 'CardanoExtension(cip: $cip)';
}
