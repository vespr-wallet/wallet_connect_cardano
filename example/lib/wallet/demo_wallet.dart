import 'package:cardano_dart_types/cardano_dart_types.dart';
import 'package:cardano_flutter_sdk/cardano_flutter_sdk.dart';
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

import '../config.dart';
import 'koios_client.dart';
import 'transfer_builder.dart';

/// Demo preprod wallet backed by [cardano_flutter_sdk].
class DemoWallet {
  DemoWallet._({
    required this.wallet,
    required this.paymentAddress,
    required this.changeAddress,
    required this.koios,
  });

  final CardanoWallet wallet;
  final CardanoAddress paymentAddress;
  final CardanoAddress changeAddress;
  final KoiosPreprodClient koios;

  String get paymentAddressBech32 => paymentAddress.bech32Encoded;
  String get paymentAddressHex => paymentAddress.hexEncoded;
  String get changeAddressHex => changeAddress.hexEncoded;
  String get stakeAddressHex => wallet.stakeAddress.hexEncoded;

  static Future<DemoWallet> create() async {
    final words = AppConfig.demoMnemonic.trim().split(RegExp(r'\s+'));
    final wallet = await WalletFactory.fromMnemonic(NetworkId.testnet, words);

    final paymentKit = await wallet.getPaymentAddressKit(addressIndex: 0);
    final changeKit = await wallet.getChangeAddressKit(addressIndex: 0);

    return DemoWallet._(
      wallet: wallet,
      paymentAddress: paymentKit.address,
      changeAddress: changeKit.address,
      koios: KoiosPreprodClient(),
    );
  }

  Future<List<String>> fetchUtxoCborHexList() async {
    final utxos = await koios.getAddressUtxos(paymentAddressBech32);
    return utxos.map(_koiosUtxoToCborHex).toList();
  }

  String _koiosUtxoToCborHex(Map<String, dynamic> utxo) {
    final txHash = utxo['tx_hash'] as String;
    final txIndex = utxo['tx_index'] as int;
    final valueLovelace = BigInt.parse(utxo['value'] as String);
    final addressBech32 = utxo['address'] as String? ?? paymentAddressBech32;

    final multiAssets = _parseAssetList(utxo['asset_list']);

    final outputValue = multiAssets.isEmpty
        ? Value.v0(lovelace: valueLovelace.toCborInt())
        : Value.v1(lovelace: valueLovelace.toCborInt(), mA: multiAssets);

    final utxoObj = Utxo(
      identifier: CardanoTransactionInput(
        transactionHash: TransactionHash.fromHex(txHash),
        index: txIndex,
      ),
      content: CardanoTransactionOutput.postAlonzo(
        address: Address.fromBase58OrBech32(addressBech32),
        value: outputValue,
        outDatum: null,
        scriptRef: null,
        lengthType: CborLengthType.definite,
      ),
    );

    return utxoObj.serializeHexString();
  }

  List<MultiAsset> _parseAssetList(dynamic assetList) {
    if (assetList is! List) return <MultiAsset>[];

    final byPolicy = <String, List<Asset>>{};

    for (final dynamic item in assetList) {
      if (item is! Map<String, dynamic>) continue;
      final policyId = item['policy_id'] as String;
      final assetNameHex = item['asset_name'] as String? ?? '';
      final quantity = BigInt.parse(item['quantity'] as String);

      byPolicy.putIfAbsent(policyId, () => <Asset>[]).add(
            Asset(
              assetName: AssetName.fromHex(assetNameHex),
              value: quantity.toCborInt(),
            ),
          );
    }

    return byPolicy.entries
        .map(
          (entry) => MultiAsset(
            policyId: PolicyId.fromHex(entry.key),
            assets: entry.value,
          ),
        )
        .toList();
  }

  Future<String> fetchBalanceCborHex() async {
    final balance = await koios.getAddressBalanceLovelace(paymentAddressBech32);
    if (balance == null) {
      return Value.v0(lovelace: BigInt.zero.toCborInt()).serializeHexString();
    }

    return Value.v0(lovelace: BigInt.parse(balance).toCborInt())
        .serializeHexString();
  }

  Future<String> signTransactionHex(String unsignedTxHex) async {
    final tx = CardanoTransaction.deserializeFromHex(unsignedTxHex);
    final witnessSet = await wallet.signTransaction(
      tx: tx,
      witnessBech32Addresses: <String>{paymentAddressBech32},
    );
    return witnessSet.serializeHexString();
  }

  /// Builds an unsigned self-transfer to the payment address using the largest
  /// lovelace-only UTXO from Koios.
  Future<CardanoTransaction> buildSelfTransferUnsigned() async {
    final utxoHexList = await fetchUtxoCborHexList();
    final utxos = utxoHexList.map(Utxo.deserializeHex).toList();
    final input = TransferBuilder.pickLargestLovelaceOnlyUtxo(utxos);
    return TransferBuilder.buildSelfTransfer(
      inputUtxo: input,
      destinationBech32: paymentAddressBech32,
      feeLovelace: TransferBuilder.selfTransferFeeLovelace,
    );
  }

  Future<String> signAndSerializeTransaction(CardanoTransaction unsignedTx) async {
    final witnessSet = await wallet.signTransaction(
      tx: unsignedTx,
      witnessBech32Addresses: <String>{paymentAddressBech32},
    );
    return unsignedTx
        .copyWithAdditionalSignatures(witnessSet)
        .serializeHexString();
  }

  Future<String> submitSignedTransactionHex(String signedTxHex) =>
      koios.submitTxCborHex(signedTxHex);

  /// Submits [txHex] to preprod. Signs first when the CBOR has no witnesses.
  Future<String> submitTransactionHex(String txHex) async {
    try {
      return await submitSignedTransactionHex(txHex);
    } catch (_) {
      final unsigned = CardanoTransaction.deserializeFromHex(txHex);
      final signed = await signAndSerializeTransaction(unsigned);
      return submitSignedTransactionHex(signed);
    }
  }

  Future<CardanoDataSignature> signDataHex(
    String addressHex,
    String payloadHex,
  ) async {
    final result = await wallet.signData(
      payloadHex: payloadHex,
      requestedSignerRaw: addressHex,
    );
    return CardanoDataSignature(
      signature: result.coseSignHex,
      key: result.coseKeyHex,
    );
  }
}
