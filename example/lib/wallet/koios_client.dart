import 'dart:convert';

import 'package:cardano_dart_types/cardano_dart_types.dart';
import 'package:http/http.dart' as http;

/// Minimal [Koios preprod](https://preprod.koios.rest/) client — no API key required.
///
/// Always uses `preprod.koios.rest` (never mainnet `api.koios.rest`).
class KoiosPreprodClient {
  KoiosPreprodClient({this.baseUrl = 'https://preprod.koios.rest/api/v1'});

  final String baseUrl;

  Future<List<Map<String, dynamic>>> getAddressUtxos(
    String bech32Address, {
    bool extended = true,
  }) async {
    final uri = Uri.parse('$baseUrl/address_utxos');
    final response = await http.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        '_addresses': <String>[bech32Address],
        if (extended) '_extended': true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Koios error ${response.statusCode}: ${response.body}');
    }

    final dynamic body = jsonDecode(response.body);
    if (body is! List) return <Map<String, dynamic>>[];
    return body.cast<Map<String, dynamic>>();
  }

  Future<String?> getAddressBalanceLovelace(String bech32Address) async {
    final uri = Uri.parse('$baseUrl/address_info');
    final response = await http.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        '_addresses': <String>[bech32Address],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Koios error ${response.statusCode}: ${response.body}');
    }

    final dynamic body = jsonDecode(response.body);
    if (body is! List || body.isEmpty) return null;
    final info = body.first as Map<String, dynamic>;
    return info['balance'] as String?;
  }

  /// Submits a signed transaction CBOR hex to preprod via Koios `/submittx`.
  Future<String> submitTxCborHex(String signedTxHex) async {
    final uri = Uri.parse('$baseUrl/submittx');
    final response = await http.post(
      uri,
      headers: const <String, String>{'Content-Type': 'application/cbor'},
      body: signedTxHex.hexDecode(),
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception(
        'Koios submit error ${response.statusCode}: ${response.body}',
      );
    }

    return response.body.trim().replaceAll('"', '');
  }

  Future<void> waitForTx(String txHash, {int maxAttempts = 30}) async {
    final uri = Uri.parse('$baseUrl/tx_status');
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final response = await http.post(
        uri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          '_tx_hashes': <String>[txHash],
        }),
      );
      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        if (body is List &&
            body.isNotEmpty &&
            (body.first as Map<String, dynamic>)['num_confirmations'] != null) {
          return;
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw Exception('Timed out waiting for tx $txHash');
  }
}
