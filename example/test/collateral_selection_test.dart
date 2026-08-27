import 'package:flutter_test/flutter_test.dart';
import 'package:wc_cardano_example/wallet/demo_wallet.dart';

void main() {
  group('DemoWallet collateral selection', () {
    test('decodes a CIP-30 CBOR coin amount', () {
      expect(
        DemoWallet.decodeCollateralAmount('1a004c4b40'),
        BigInt.from(5000000),
      );
    });

    test('rejects malformed collateral amounts', () {
      expect(
        () => DemoWallet.decodeCollateralAmount('5000000'),
        throwsFormatException,
      );
    });

    test('selects the smallest lovelace-only UTXO covering the amount', () {
      final tokenUtxo = _utxo('token', 9000000, hasAssets: true);
      final smallPureAda = _utxo('small', 4000000);
      final eligiblePureAda = _utxo('eligible', 6000000);

      final selected = DemoWallet.selectCollateralUtxos(
        utxos: <Map<String, dynamic>>[tokenUtxo, eligiblePureAda, smallPureAda],
        requiredLovelace: BigInt.from(5000000),
      );

      expect(selected, <Map<String, dynamic>>[eligiblePureAda]);
    });

    test('combines at most three lovelace-only UTXOs when needed', () {
      final first = _utxo('first', 2000000);
      final second = _utxo('second', 2000000);
      final third = _utxo('third', 2000000);

      final selected = DemoWallet.selectCollateralUtxos(
        utxos: <Map<String, dynamic>>[first, second, third],
        requiredLovelace: BigInt.from(5000000),
      );

      expect(selected, hasLength(3));
      expect(
        selected!.fold<BigInt>(
          BigInt.zero,
          (sum, utxo) => sum + BigInt.parse(utxo['value'] as String),
        ),
        greaterThanOrEqualTo(BigInt.from(5000000)),
      );
    });

    test('returns null when suitable collateral is unavailable', () {
      final selected = DemoWallet.selectCollateralUtxos(
        utxos: <Map<String, dynamic>>[
          _utxo('token', 10000000, hasAssets: true),
          _utxo('pure', 2000000),
        ],
        requiredLovelace: BigInt.from(5000000),
      );

      expect(selected, isNull);
    });
  });
}

Map<String, dynamic> _utxo(String id, int lovelace, {bool hasAssets = false}) {
  return <String, dynamic>{
    'tx_hash': id,
    'value': '$lovelace',
    'asset_list': hasAssets
        ? <Map<String, String>>[
            <String, String>{'policy_id': 'policy'},
          ]
        : <Object>[],
  };
}
