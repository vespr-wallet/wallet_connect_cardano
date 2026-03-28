import 'package:reown_walletkit/reown_walletkit.dart';

import 'cardano_wallet_delegate.dart';
import 'models/models.dart';

/// Registers all 12 CIP-30 JSON-RPC handlers on a [IReownWalletKit]
/// instance, routing each incoming dApp request to the [CardanoWalletDelegate].
class CardanoRequestHandler {
  final CardanoWalletDelegate _delegate;

  CardanoRequestHandler(this._delegate);

  /// Registers all CIP-30 handlers for the given [chainId]
  /// (e.g. `'cip34:1-764824073'`).
  void registerHandlers(IReownWalletKit walletKit, String chainId) {
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getExtensions',
      handler: _handleGetExtensions,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getNetworkId',
      handler: _handleGetNetworkId,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getBalance',
      handler: _handleGetBalance,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getUsedAddresses',
      handler: _handleGetUsedAddresses,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getUnusedAddresses',
      handler: _handleGetUnusedAddresses,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getChangeAddress',
      handler: _handleGetChangeAddress,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getRewardAddresses',
      handler: _handleGetRewardAddresses,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getRewardAddress',
      handler: _handleGetRewardAddress,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_getUtxos',
      handler: _handleGetUtxos,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_signTx',
      handler: _handleSignTx,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_signData',
      handler: _handleSignData,
    );
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: 'cardano_submitTx',
      handler: _handleSubmitTx,
    );
  }

  T? _param<T>(dynamic params, int index, String key) {
    if (params is List && params.length > index && params[index] != null) {
      return params[index] as T?;
    }
    if (params is Map && params[key] != null) {
      return params[key] as T?;
    }
    return null;
  }

  T _requiredParam<T>(dynamic params, int index, String key) {
    final dynamic value = _param<dynamic>(params, index, key);
    if (value == null) {
      throw CardanoApiError(
        code: CardanoApiError.invalidRequest,
        info: 'Missing required parameter: $key',
      );
    }
    if (value is! T) {
      throw CardanoApiError(
        code: CardanoApiError.invalidRequest,
        info: 'Invalid parameter type for: $key',
      );
    }
    return value;
  }

  CardanoPaginate? _paginateFromParam(dynamic value) {
    if (value is Map) {
      return CardanoPaginate.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  Future<T> _execute<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CardanoApiError {
      rethrow;
    } on CardanoDataSignError {
      rethrow;
    } on CardanoPaginateError {
      rethrow;
    } on CardanoTxSendError {
      rethrow;
    } on CardanoTxSignError {
      rethrow;
    } catch (error) {
      throw CardanoApiError(
        code: CardanoApiError.internalError,
        info: error.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _handleGetExtensions(
    String topic,
    dynamic params,
  ) {
    return _execute(() async {
      final extensions = await _delegate.getExtensions();
      return extensions.map((extension) => extension.toJson()).toList();
    });
  }

  Future<int> _handleGetNetworkId(String topic, dynamic params) {
    return _execute(() => _delegate.getNetworkId());
  }

  Future<String> _handleGetBalance(String topic, dynamic params) {
    return _execute(() => _delegate.getBalance());
  }

  Future<List<String>> _handleGetUsedAddresses(String topic, dynamic params) {
    return _execute(() async {
      final dynamic paginateParam = _param<dynamic>(params, 0, 'paginate');
      final CardanoPaginate? paginate = _paginateFromParam(paginateParam);
      return _delegate.getUsedAddresses(paginate: paginate);
    });
  }

  Future<List<String>> _handleGetUnusedAddresses(String topic, dynamic params) {
    return _execute(() => _delegate.getUnusedAddresses());
  }

  Future<String> _handleGetChangeAddress(String topic, dynamic params) {
    return _execute(() => _delegate.getChangeAddress());
  }

  Future<List<String>> _handleGetRewardAddresses(String topic, dynamic params) {
    return _execute(() => _delegate.getRewardAddresses());
  }

  Future<String> _handleGetRewardAddress(String topic, dynamic params) {
    return _execute(() async {
      final rewardAddresses = await _delegate.getRewardAddresses();
      return rewardAddresses.isNotEmpty ? rewardAddresses.first : '';
    });
  }

  Future<List<String>?> _handleGetUtxos(String topic, dynamic params) {
    return _execute(() {
      final String? amount = _param<String>(params, 0, 'amount');
      final dynamic paginateParam = _param<dynamic>(params, 1, 'paginate');
      final CardanoPaginate? paginate = _paginateFromParam(paginateParam);
      return _delegate.getUtxos(amount: amount, paginate: paginate);
    });
  }

  Future<String> _handleSignTx(String topic, dynamic params) {
    return _execute(() {
      final String tx = _requiredParam<String>(params, 0, 'tx');
      final bool partialSign = _param<bool>(params, 1, 'partialSign') ?? false;
      return _delegate.signTx(tx, partialSign: partialSign);
    });
  }

  Future<Map<String, dynamic>> _handleSignData(String topic, dynamic params) {
    return _execute(() async {
      final String address = _requiredParam<String>(params, 0, 'address');
      final String payload = _requiredParam<String>(params, 1, 'payload');
      final signature = await _delegate.signData(address, payload);
      return signature.toJson();
    });
  }

  Future<String> _handleSubmitTx(String topic, dynamic params) {
    return _execute(() {
      final String tx = _requiredParam<String>(params, 0, 'tx');
      return _delegate.submitTx(tx);
    });
  }
}
