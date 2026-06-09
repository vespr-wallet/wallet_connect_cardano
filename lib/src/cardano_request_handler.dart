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
    _register(walletKit, chainId, 'cardano_getExtensions', _handleGetExtensions);
    _register(walletKit, chainId, 'cardano_getNetworkId', _handleGetNetworkId);
    _register(walletKit, chainId, 'cardano_getBalance', _handleGetBalance);
    _register(
      walletKit,
      chainId,
      'cardano_getUsedAddresses',
      _handleGetUsedAddresses,
    );
    _register(
      walletKit,
      chainId,
      'cardano_getUnusedAddresses',
      _handleGetUnusedAddresses,
    );
    _register(
      walletKit,
      chainId,
      'cardano_getChangeAddress',
      _handleGetChangeAddress,
    );
    _register(
      walletKit,
      chainId,
      'cardano_getRewardAddresses',
      _handleGetRewardAddresses,
    );
    _register(
      walletKit,
      chainId,
      'cardano_getRewardAddress',
      _handleGetRewardAddress,
    );
    _register(walletKit, chainId, 'cardano_getUtxos', _handleGetUtxos);
    _register(walletKit, chainId, 'cardano_signTx', _handleSignTx);
    _register(walletKit, chainId, 'cardano_signData', _handleSignData);
    _register(walletKit, chainId, 'cardano_submitTx', _handleSubmitTx);
  }

  void _register(
    IReownWalletKit walletKit,
    String chainId,
    String method,
    Future<dynamic> Function(String topic, dynamic params) handler,
  ) {
    walletKit.registerRequestHandler(
      chainId: chainId,
      method: method,
      handler: (String topic, dynamic params) async {
        final SessionRequest request = _pendingRequest(
          walletKit,
          topic,
          method,
        );
        Object? handlerError;
        dynamic result;

        try {
          result = await handler(topic, params);
        } catch (error) {
          handlerError = error;
        }

        final JsonRpcResponse<dynamic> response = handlerError == null
            ? JsonRpcResponse<dynamic>(id: request.id, result: result)
            : JsonRpcResponse<dynamic>(
                id: request.id,
                error: _toJsonRpcError(handlerError),
              );

        await walletKit.respondSessionRequest(
          topic: topic,
          response: response,
        );
      },
    );
  }

  SessionRequest _pendingRequest(
    IReownWalletKit walletKit,
    String topic,
    String method,
  ) {
    final pending = walletKit.pendingRequests.getAll();
    for (var index = pending.length - 1; index >= 0; index--) {
      final request = pending[index];
      if (request.topic == topic && request.method == method) {
        return request;
      }
    }

    for (var index = pending.length - 1; index >= 0; index--) {
      final request = pending[index];
      if (request.topic == topic) {
        return request;
      }
    }

    if (pending.isEmpty) {
      throw CardanoApiError(
        code: CardanoApiError.internalError,
        info: 'No pending WalletConnect request for $method',
      );
    }

    return pending.last;
  }

  JsonRpcError _toJsonRpcError(Object error) {
    if (error is CardanoApiError) {
      return JsonRpcError(code: error.code, message: error.info);
    }
    if (error is CardanoDataSignError) {
      return JsonRpcError(code: error.code, message: error.info);
    }
    if (error is CardanoPaginateError) {
      return JsonRpcError(
        code: CardanoApiError.invalidRequest,
        message: 'PaginateError: maxSize ${error.maxSize}',
      );
    }
    if (error is CardanoTxSendError) {
      return JsonRpcError(code: error.code, message: error.info);
    }
    if (error is CardanoTxSignError) {
      return JsonRpcError(code: error.code, message: error.info);
    }

    return JsonRpcError(
      code: CardanoApiError.internalError,
      message: error.toString(),
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
