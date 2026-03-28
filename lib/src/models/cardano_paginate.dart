/// CIP-30 Paginate — pagination parameters for address/UTXO queries.
///
/// See: https://cips.cardano.org/cip/CIP-30#paginate
class CardanoPaginate {
  /// The page number (zero-indexed).
  final int page;
  /// The maximum number of items per page.
  final int limit;

  /// Creates a new [CardanoPaginate].
  const CardanoPaginate({required this.page, required this.limit});

  /// Serializes this to a JSON-compatible map.
  Map<String, dynamic> toJson() => {'page': page, 'limit': limit};

  /// Deserializes a [CardanoPaginate] from a JSON map.
  factory CardanoPaginate.fromJson(Map<String, dynamic> json) =>
      CardanoPaginate(page: json['page'] as int, limit: json['limit'] as int);

  @override
  String toString() => 'CardanoPaginate(page: $page, limit: $limit)';
}
