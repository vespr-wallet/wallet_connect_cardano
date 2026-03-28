/// CIP-30 PaginateError — pagination limit exceeded.
///
/// See: https://cips.cardano.org/cip/CIP-30#paginateerror
class CardanoPaginateError implements Exception {
  /// The maximum number of items the wallet can return.
  final int maxSize;

  /// Creates a new [CardanoPaginateError].
  const CardanoPaginateError({required this.maxSize});

  /// Serializes this error to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'maxSize': maxSize};

  /// Deserializes a [CardanoPaginateError] from a JSON map.
  factory CardanoPaginateError.fromJson(Map<String, dynamic> json) =>
      CardanoPaginateError(maxSize: json['maxSize'] as int);

  @override
  String toString() => 'CardanoPaginateError(maxSize: $maxSize)';
}
