import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

import '../wallet/demo_wallet.dart';

typedef RequestApproval = Future<bool> Function(String method, String summary);

/// [CardanoWalletDelegate] backed by a real preprod demo wallet.
class DemoWalletDelegate implements CardanoWalletDelegate {
  DemoWalletDelegate({
    required this.demoWallet,
    this.onRequest,
    this.requireApprovalForSigning = true,
  });

  final DemoWallet demoWallet;
  void Function(String method)? onRequest;
  final bool requireApprovalForSigning;
  RequestApproval? approvalHandler;

  /// Max UTXOs / addresses returned per paginate page (CIP-30 PaginateError threshold).
  static const int maxPaginateLimit = 100;

  Future<bool> _maybeApprove(String method, String summary) async {
    onRequest?.call(method);
    if (!requireApprovalForSigning) return true;
    if (approvalHandler == null) return true;
    return approvalHandler!(method, summary);
  }

  List<T> _paginateAddresses<T>(List<T> items, CardanoPaginate? paginate) {
    if (paginate == null) {
      return items;
    }
    if (paginate.limit > maxPaginateLimit) {
      throw CardanoPaginateError(maxSize: maxPaginateLimit);
    }

    final start = paginate.page * paginate.limit;
    if (start >= items.length) {
      return <T>[];
    }

    final end = start + paginate.limit;
    return items.sublist(start, end > items.length ? items.length : end);
  }

  @override
  Future<int> getNetworkId() async => 0;

  @override
  Future<List<String>?> getUtxos({
    String? amount,
    CardanoPaginate? paginate,
  }) async {
    final utxos = await demoWallet.fetchUtxoCborHexList();
    if (paginate == null) {
      return utxos;
    }
    if (paginate.limit > maxPaginateLimit) {
      throw CardanoPaginateError(maxSize: maxPaginateLimit);
    }

    // Amount-based coin selection is wallet-specific; return all UTXOs for demo.
    final start = paginate.page * paginate.limit;
    if (start >= utxos.length) {
      return null;
    }
    final end = start + paginate.limit;
    return utxos.sublist(start, end > utxos.length ? utxos.length : end);
  }

  @override
  Future<String> getBalance() => demoWallet.fetchBalanceCborHex();

  @override
  Future<List<String>> getUsedAddresses({CardanoPaginate? paginate}) async {
    return _paginateAddresses(<String>[demoWallet.paymentAddressHex], paginate);
  }

  @override
  Future<List<String>> getUnusedAddresses() async => <String>[];

  @override
  Future<String> getChangeAddress() async => demoWallet.changeAddressHex;

  @override
  Future<List<String>> getRewardAddresses() async {
    return <String>[demoWallet.stakeAddressHex];
  }

  @override
  Future<String> signTx(String tx, {bool partialSign = false}) async {
    final approved = await _maybeApprove(
      'cardano_signTx',
      'Sign transaction (${tx.length ~/ 2} bytes CBOR)',
    );
    if (!approved) {
      throw const CardanoTxSignError(
        code: CardanoTxSignError.userDeclined,
        info: 'User declined',
      );
    }

    try {
      return await demoWallet.signTransactionHex(tx);
    } catch (error) {
      throw CardanoTxSignError(
        code: CardanoTxSignError.proofGeneration,
        info: error.toString(),
      );
    }
  }

  @override
  Future<CardanoDataSignature> signData(String address, String payload) async {
    final approved = await _maybeApprove(
      'cardano_signData',
      'Sign data for address $address',
    );
    if (!approved) {
      throw const CardanoDataSignError(
        code: CardanoDataSignError.userDeclined,
        info: 'User declined',
      );
    }

    try {
      return await demoWallet.signDataHex(address, payload);
    } catch (error) {
      throw CardanoDataSignError(
        code: CardanoDataSignError.proofGeneration,
        info: error.toString(),
      );
    }
  }

  @override
  Future<String> submitTx(String tx) async {
    final approved = await _maybeApprove(
      'cardano_submitTx',
      'Submit transaction to Cardano preprod',
    );
    if (!approved) {
      throw const CardanoTxSendError(
        code: CardanoTxSendError.refused,
        info: 'User declined',
      );
    }

    try {
      return await demoWallet.submitTransactionHex(tx);
    } catch (error) {
      throw CardanoTxSendError(
        code: CardanoTxSendError.failure,
        info: error.toString(),
      );
    }
  }

  @override
  Future<List<CardanoExtension>> getExtensions() async => <CardanoExtension>[];
}
