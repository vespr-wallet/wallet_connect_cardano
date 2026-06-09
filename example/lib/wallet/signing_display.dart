import 'dart:convert';

import 'package:cardano_dart_types/cardano_dart_types.dart';

/// Formats CIP-30 signing payloads for the approval UI.
class SigningDisplay {
  SigningDisplay._();

  static const String cardanoscanPreprodTxBase =
      'https://preprod.cardanoscan.io/transaction/';

  static String cardanoscanPreprodTxUrl(String txHash) =>
      '$cardanoscanPreprodTxBase$txHash';

  static String formatTransaction(String unsignedTxHex) {
    try {
      final tx = CardanoTransaction.deserializeFromHex(unsignedTxHex.trim());
      return tx.toJson(prettyPrint: true);
    } catch (error) {
      return 'Could not parse transaction CBOR.\n\n$error';
    }
  }

  static String formatPayloadUtf8(String payloadHex) {
    try {
      final bytes = payloadHex.trim().hexDecode();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return payloadHex;
    }
  }

  static String formatSubmitApproval(String txHex) {
    try {
      final tx = CardanoTransaction.deserializeFromHex(txHex.trim());
      final summary = tx.toJson(prettyPrint: true);
      return 'Submit this transaction to Cardano preprod?\n\n$summary';
    } catch (_) {
      return 'Submit this transaction to Cardano preprod?';
    }
  }
}
