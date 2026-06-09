import 'package:cardano_dart_types/cardano_dart_types.dart';

/// Builds a simple lovelace-only self-transfer on preprod.
class TransferBuilder {
  TransferBuilder._();

  /// Fixed fee for demo self-transfers (0.3 ADA). The Cardano Flutter SDK does
  /// not expose fee estimation; this is a conservative hardcoded value.
  static final BigInt selfTransferFeeLovelace = BigInt.from(300000);

  /// Picks the largest lovelace-only UTXO (no native assets).
  static Utxo pickLargestLovelaceOnlyUtxo(List<Utxo> utxos) {
    Utxo? best;
    var bestLovelace = BigInt.zero;

    for (final utxo in utxos) {
      if (utxo.content.value.multiAssets.isNotEmpty) continue;
      final lovelace = utxo.content.value.lovelace.toBigInt();
      if (lovelace > bestLovelace) {
        bestLovelace = lovelace;
        best = utxo;
      }
    }

    if (best == null) {
      throw StateError('No lovelace-only UTXO available');
    }
    return best;
  }

  /// Self-transfer: one input, one output back to [destinationBech32], minus [feeLovelace].
  static CardanoTransaction buildSelfTransfer({
    required Utxo inputUtxo,
    required String destinationBech32,
    required BigInt feeLovelace,
  }) {
    final inputLovelace = inputUtxo.content.value.lovelace.toBigInt();
    final outputLovelace = inputLovelace - feeLovelace;
    if (outputLovelace <= BigInt.zero) {
      throw StateError('UTXO balance too low for fee $feeLovelace');
    }

    final body = CardanoTransactionBody.create(
      inputs: CardanoTransactionInputs(
        data: <CardanoTransactionInput>[inputUtxo.identifier],
        cborTags: <int>[],
      ),
      outputs: <CardanoTransactionOutput>[
        CardanoTransactionOutput.postAlonzo(
          address: Address.fromBase58OrBech32(destinationBech32),
          value: Value.v0(lovelace: outputLovelace.toCborInt()),
          outDatum: null,
          scriptRef: null,
          lengthType: CborLengthType.definite,
        ),
      ],
      fee: feeLovelace.toCborInt(),
    );

    return CardanoTransaction(
      body: body,
      witnessSet: const WitnessSet(),
      isValidDi: true,
      auxiliaryData: null,
      overrideBodyMetadataHash: false,
    );
  }
}
