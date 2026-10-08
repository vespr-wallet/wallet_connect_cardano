import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

import '../wallet/demo_wallet.dart';
import '../wallet/signing_display.dart';

/// Context shown in the wallet approval UI before signing or submitting.
class SigningApprovalRequest {
  const SigningApprovalRequest({
    required this.method,
    required this.detail,
    this.subtitle,
  });

  final String method;
  final String detail;
  final String? subtitle;
}

typedef RequestApproval = Future<bool> Function(SigningApprovalRequest request);

/// [CardanoWalletDelegate] backed by a real preprod demo wallet.
class DemoWalletDelegate implements CardanoWalletDelegate {
  DemoWalletDelegate({
    required this.demoWallet,
    this.onRequest,
    this.onTransactionSubmitted,
    this.requireApprovalForSigning = true,
  });

  final DemoWallet demoWallet;
  void Function(String method)? onRequest;
  void Function(String method)? onOperationStarted;
  void Function(String method)? onOperationSucceeded;
  void Function(String method, String error)? onOperationFailed;
  void Function(String txHash)? onTransactionSubmitted;
  final bool requireApprovalForSigning;
  RequestApproval? approvalHandler;

  /// Max UTXOs / addresses returned per paginate page (CIP-30 PaginateError threshold).
  static const int maxPaginateLimit = 100;

  Future<bool> _maybeApprove(SigningApprovalRequest request) async {
    onRequest?.call(request.method);
    if (!requireApprovalForSigning) return true;
    if (approvalHandler == null) return true;
    return approvalHandler!(request);
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

    final start = paginate.page * paginate.limit;
    if (start >= utxos.length) {
      return null;
    }
    final end = start + paginate.limit;
    return utxos.sublist(start, end > utxos.length ? utxos.length : end);
  }

  @override
  Future<List<String>?> getCollateral({required String amount}) async {
    try {
      return await demoWallet.fetchCollateralCborHexList(amount);
    } on FormatException catch (error) {
      throw CardanoApiError(
        code: CardanoApiError.invalidRequest,
        info: error.message,
      );
    }
  }

  @override
  Future<String> getBalance() => demoWallet.fetchBalanceCborHex();

  /// Account 0 / address index 0 payment (receive) address.
  List<String> get _receiveAddresses => <String>[demoWallet.paymentAddressHex];

  @override
  Future<List<String>> getUsedAddresses({CardanoPaginate? paginate}) async {
    return _paginateAddresses(_receiveAddresses, paginate);
  }

  @override
  Future<List<String>> getUnusedAddresses() async => _receiveAddresses;

  @override
  Future<String> getChangeAddress() async => demoWallet.paymentAddressHex;

  @override
  Future<List<String>> getRewardAddresses() async {
    return <String>[demoWallet.stakeAddressHex];
  }

  @override
  Future<String> signTx(String tx, {bool partialSign = false}) async {
    final approved = await _maybeApprove(
      SigningApprovalRequest(
        method: 'cardano_signTx',
        subtitle: 'Review transaction',
        detail: SigningDisplay.formatTransaction(tx),
      ),
    );
    if (!approved) {
      throw const CardanoTxSignError(
        code: CardanoTxSignError.userDeclined,
        info: 'User declined',
      );
    }

    onOperationStarted?.call('cardano_signTx');
    try {
      final witnessHex = await demoWallet.signTransactionHex(tx);
      onOperationSucceeded?.call('cardano_signTx');
      return witnessHex;
    } catch (error) {
      onOperationFailed?.call('cardano_signTx', error.toString());
      throw CardanoTxSignError(
        code: CardanoTxSignError.proofGeneration,
        info: error.toString(),
      );
    }
  }

  @override
  Future<CardanoDataSignature> signData(String address, String payload) async {
    final message = SigningDisplay.formatPayloadUtf8(payload);
    final approved = await _maybeApprove(
      SigningApprovalRequest(
        method: 'cardano_signData',
        subtitle: 'Message to sign',
        detail: message,
      ),
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
    final signedTx = tx.trim();

    final approved = await _maybeApprove(
      SigningApprovalRequest(
        method: 'cardano_submitTx',
        subtitle: 'Submit to preprod',
        detail: SigningDisplay.formatSubmitApproval(signedTx),
      ),
    );
    if (!approved) {
      throw const CardanoTxSendError(
        code: CardanoTxSendError.refused,
        info: 'User declined',
      );
    }

    onOperationStarted?.call('cardano_submitTx');
    try {
      final txHash = await demoWallet.submitSignedTransactionHex(signedTx);
      onTransactionSubmitted?.call(txHash);
      return txHash;
    } catch (error) {
      final message = error.toString();
      onOperationFailed?.call('cardano_submitTx', message);
      throw CardanoTxSendError(code: CardanoTxSendError.failure, info: message);
    }
  }

  @override
  Future<List<CardanoExtension>> getExtensions() async => <CardanoExtension>[];
}
