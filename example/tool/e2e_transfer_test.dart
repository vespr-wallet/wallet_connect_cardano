// ignore_for_file: avoid_print
//
// End-to-end preprod test: Koios UTXOs → build self-transfer → sign → submit.
//
// Usage (from example/ — requires FFI, so use Flutter, not plain dart):
//   flutter run -t tool/e2e_transfer_test.dart -d macos --release
//
// Uses https://preprod.koios.rest/ only (never api.koios.rest).

import 'dart:io';

import 'package:cardano_dart_types/cardano_dart_types.dart';
import 'package:wc_cardano_example/delegate/demo_wallet_delegate.dart';
import 'package:wc_cardano_example/wallet/demo_wallet.dart';

import 'repo_paths.dart';

Future<void> main() async {
  final demoWallet = await DemoWallet.create();
  print('Address: ${demoWallet.paymentAddressBech32}');

  final balanceBefore = await demoWallet.koios.getAddressBalanceLovelace(
    demoWallet.paymentAddressBech32,
  );
  print('Balance before: ${balanceBefore ?? "0"} lovelace');

  const transferCount = 2;
  final txHashes = <String>[];

  for (var i = 0; i < transferCount; i++) {
    print('\n--- Self-transfer ${i + 1}/$transferCount ---');
    final unsigned = await demoWallet.buildSelfTransferUnsigned();
    final unsignedHex = unsigned.serializeHexString();
    print('Unsigned tx: ${unsignedHex.substring(0, 40)}...');

    final witnessHex = await demoWallet.signTransactionHex(unsignedHex);
    print('Witness set: ${witnessHex.substring(0, 40)}...');

    final delegate = DemoWalletDelegate(
      demoWallet: demoWallet,
      requireApprovalForSigning: false,
    );
    final delegateWitness = await delegate.signTx(unsignedHex);
    if (delegateWitness != witnessHex) {
      stderr.writeln('WARN: delegate signTx witness differs from direct sign');
    } else {
      print('Delegate signTx: OK');
    }

    final signedHex = await demoWallet.signAndSerializeTransaction(unsigned);
    final txHash = await demoWallet.submitSignedTransactionHex(signedHex);
    print('Submitted: $txHash');
    txHashes.add(txHash);

    await demoWallet.koios.waitForTx(txHash);
    print('Confirmed on-chain');
  }

  final balanceAfter = await demoWallet.koios.getAddressBalanceLovelace(
    demoWallet.paymentAddressBech32,
  );
  print('\nBalance after: ${balanceAfter ?? "0"} lovelace');
  print('Tx hashes:');
  for (final hash in txHashes) {
    print('  $hash');
  }

  print('\nRegenerating unsigned-tx.hex fixture...');
  final fixtureUnsigned = await demoWallet.buildSelfTransferUnsigned();
  final fixtureFile = repoFile('demo/dapp-web/public/fixtures/unsigned-tx.hex');
  await fixtureFile.parent.create(recursive: true);
  await fixtureFile.writeAsString(fixtureUnsigned.serializeHexString());
  print('Wrote ${fixtureFile.path}');
  exit(0);
}
