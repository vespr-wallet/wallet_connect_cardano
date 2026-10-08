import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';
import 'package:wc_cardano_example/delegate/demo_wallet_delegate.dart';

// Same self-transfer (built with CSL) paying to a testnet vs a mainnet base address.
const _testnetTx =
    '84a300d9010281825820cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd000181825839008b218424ad74df25d35c2ea8e094a4c5c5aeb2cbb4424193315693138b218424ad74df25d35c2ea8e094a4c5c5aeb2cbb4424193315693131a0049c4ef021a00028651a0f5f6';
const _mainnetTx =
    '84a300d9010281825820cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd000181825839018b218424ad74df25d35c2ea8e094a4c5c5aeb2cbb4424193315693138b218424ad74df25d35c2ea8e094a4c5c5aeb2cbb4424193315693131a0049c4ef021a00028651a0f5f6';

void main() {
  test('accepts preprod transactions', () {
    DemoWalletDelegate.requirePreprodTransaction(_testnetTx);
  });

  test('refuses transactions with mainnet outputs', () {
    expect(
      () => DemoWalletDelegate.requirePreprodTransaction(_mainnetTx),
      throwsA(
        isA<CardanoApiError>().having(
          (e) => e.code,
          'code',
          CardanoApiError.refused,
        ),
      ),
    );
  });

  test('rejects malformed CBOR', () {
    expect(
      () => DemoWalletDelegate.requirePreprodTransaction('nope'),
      throwsA(
        isA<CardanoApiError>().having(
          (e) => e.code,
          'code',
          CardanoApiError.invalidRequest,
        ),
      ),
    );
  });
}
