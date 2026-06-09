// ignore_for_file: avoid_print
//
// Generates demo/dapp-web/public/fixtures/unsigned-tx.hex for the signTx demo.
//
// Usage (from example/ — requires FFI):
//   flutter run -t tool/generate_fixture.dart -d macos --release
//
// Prerequisites:
//   - Fund the demo wallet payment address on preprod (see docs/milestone-1-demo.md)
//   - Koios preprod API at https://preprod.koios.rest/

import 'dart:io';

import 'package:cardano_dart_types/cardano_dart_types.dart';
import 'package:wc_cardano_example/wallet/demo_wallet.dart';

import 'repo_paths.dart';

Future<void> main() async {
  final demoWallet = await DemoWallet.create();
  print('Payment address: ${demoWallet.paymentAddressBech32}');

  final unsignedTx = await demoWallet.buildSelfTransferUnsigned();
  final hex = unsignedTx.serializeHexString();

  final outFile = repoFile('demo/dapp-web/public/fixtures/unsigned-tx.hex');
  await outFile.parent.create(recursive: true);
  await outFile.writeAsString(hex);

  print('Wrote ${outFile.path}');
  print('Unsigned tx hex length: ${hex.length}');
  exit(0);
}
