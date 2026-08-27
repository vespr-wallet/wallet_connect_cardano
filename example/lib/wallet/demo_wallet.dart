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

  /// Returns up to three lovelace-only UTXOs that cover [amountCborHex].
  Future<List<String>?> fetchCollateralCborHexList(String amountCborHex) async {
    final requiredLovelace = decodeCollateralAmount(amountCborHex);
    final utxos = await koios.getAddressUtxos(paymentAddressBech32);
    final selected = selectCollateralUtxos(
      utxos: utxos,
      requiredLovelace: requiredLovelace,
    );
    return selected?.map(_koiosUtxoToCborHex).toList();
  }

  /// Decodes the CIP-30 `cbor<Coin>` collateral amount.
  static BigInt decodeCollateralAmount(String amountCborHex) {
    try {
      final decoded = cbor.decode(amountCborHex.hexDecode());
      if (decoded is CborInt) {
        final amount = decoded.toBigInt();
        if (amount > BigInt.zero) {
          return amount;
        }
      }
    } catch (_) {
      // Normalize malformed hex and CBOR into one public validation error.
    }
    throw const FormatException(
      'Collateral amount must be a positive CBOR integer',
    );
  }

  /// Selects lovelace-only Koios UTXOs covering [requiredLovelace].
  ///
  /// Prefers the smallest single qualifying UTXO. When no single UTXO covers
  /// the amount, combines the largest available entries up to Cardano's
  /// three-collateral-input protocol limit.
  static List<Map<String, dynamic>>? selectCollateralUtxos({
    required List<Map<String, dynamic>> utxos,
    required BigInt requiredLovelace,
  }) {
    if (requiredLovelace <= BigInt.zero) {
      throw ArgumentError.value(
        requiredLovelace,
        'requiredLovelace',
        'must be positive',
      );
    }

    final candidates = <({Map<String, dynamic> utxo, BigInt lovelace})>[];
    for (final utxo in utxos) {
      final assetList = utxo['asset_list'];
      final lovelace = BigInt.tryParse(utxo['value'] as String? ?? '');
      if (assetList is List && assetList.isEmpty && lovelace != null) {
        candidates.add((utxo: utxo, lovelace: lovelace));
      }
    }
    candidates.sort((left, right) => left.lovelace.compareTo(right.lovelace));

    for (final candidate in candidates) {
      if (candidate.lovelace >= requiredLovelace) {
        return <Map<String, dynamic>>[candidate.utxo];
      }
    }

    final selected = <Map<String, dynamic>>[];
    var selectedLovelace = BigInt.zero;
    for (final candidate in candidates.reversed) {
      selected.add(candidate.utxo);
      selectedLovelace += candidate.lovelace;
      if (selectedLovelace >= requiredLovelace) {
        return selected;
      }
      if (selected.length == 3) {
        break;
      }
    }
    return null;
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

      byPolicy
          .putIfAbsent(policyId, () => <Asset>[])
          .add(
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

    return Value.v0(
      lovelace: BigInt.parse(balance).toCborInt(),
    ).serializeHexString();
  }

  Future<String> signTransactionHex(String unsignedTxHex) async {
    final tx = CardanoTransaction.deserializeFromHex(unsignedTxHex);
    final witnessSet = await wallet.signTransaction(
      tx: tx,
      witnessBech32Addresses: <String>{paymentAddressBech32},
    );
    return witnessSet.serializeHexString();
  }

  /// Builds an unsigned self-transfer from live Koios UTXOs:
  ///
  /// 1. Largest lovelace-only input (no native tokens / NFTs)
  /// 2. One output to the payment address with `inputLovelace - fee`
  /// 3. Fixed fee of [TransferBuilder.selfTransferFeeLovelace] (0.3 ADA)
  Future<CardanoTransaction> buildSelfTransferUnsigned() async {
    final koiosUtxos = await koios.getAddressUtxos(paymentAddressBech32);
    final input = _pickLargestLovelaceOnlyKoiosUtxo(koiosUtxos);
    return TransferBuilder.buildSelfTransfer(
      inputUtxo: _koiosUtxoMapToUtxo(input),
      destinationBech32: paymentAddressBech32,
      feeLovelace: TransferBuilder.selfTransferFeeLovelace,
    );
  }

  Map<String, dynamic> _pickLargestLovelaceOnlyKoiosUtxo(
    List<Map<String, dynamic>> utxos,
  ) {
    Map<String, dynamic>? best;
    var bestLovelace = BigInt.zero;

    for (final utxo in utxos) {
      final assetList = utxo['asset_list'];
      if (assetList is List && assetList.isNotEmpty) {
        continue;
      }

      final lovelace = BigInt.parse(utxo['value'] as String);
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

  Utxo _koiosUtxoMapToUtxo(Map<String, dynamic> utxo) {
    return Utxo.deserializeHex(_koiosUtxoToCborHex(utxo));
  }

  Future<String> signAndSerializeTransaction(
    CardanoTransaction unsignedTx,
  ) async {
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
