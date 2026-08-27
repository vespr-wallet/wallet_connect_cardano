import 'package:reown_walletkit/reown_walletkit.dart';

import 'cardano_wallet_delegate.dart';
import 'models/models.dart';

/// Registers all 13 supported CIP-30 JSON-RPC handlers on an
/// [IReownWalletKit] instance, routing each incoming dApp request to the
/// [CardanoWalletDelegate].
class CardanoRequestHandler {
  final CardanoWalletDelegate _delegate;

  /// Creates a handler backed by the supplied wallet delegate.
  CardanoRequestHandler(this._delegate);

  /// Registers all CIP-30 handlers for the given [chainId]
  /// (e.g. `'cip34:1-764824073'`).
  void registerHandlers(IReownWalletKit walletKit, String chainId) {
    _register(
      walletKit,
      chainId,
      'cardano_getExtensions',
      _handleGetExtensions,
    );
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
    _register(
      walletKit,
      chainId,
      'cardano_getCollateral',
      _handleGetCollateral,
    );
    _register(walletKit, chainId, 'cardano_signTx', _handleSignTx);
    _register(walletKit, chainId, 'cardano_signData', _handleSignData);
    _register(walletKit, chainId, 'cardano_submitTx', _handleSubmitTx);
  }

  void _register(
    IReownWalletKit walletKit,
    String chainId,
    String method,
    Future<Object?> Function(String topic, Object? params) handler,
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
        Object? result;

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

        await walletKit.respondSessionRequest(topic: topic, response: response);
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

    throw CardanoApiError(
      code: CardanoApiError.internalError,
      info: 'No pending WalletConnect request for $method on topic $topic',
    );
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

  T? _param<T>(Object? params, int index, String key) {
    Object? value;
    if (params is List && params.length > index) {
      value = params[index];
    } else if (params is Map) {
      value = params[key];
    }

    if (value == null) {
      return null;
    }
    if (value is! T) {
      throw CardanoApiError(
        code: CardanoApiError.invalidRequest,
        info: 'Invalid parameter type for: $key',
      );
    }
    return value as T;
  }

  T _requiredParam<T>(Object? params, int index, String key) {
    final Object? value = _param<Object?>(params, index, key);
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
    return value as T;
  }

  CardanoPaginate? _paginateFromParam(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! Map) {
      throw const CardanoApiError(
        code: CardanoApiError.invalidRequest,
        info: 'Invalid parameter type for: paginate',
      );
    }

    final Object? page = value['page'];
    final Object? limit = value['limit'];
    if (page is! int || limit is! int || page < 0 || limit <= 0) {
      throw const CardanoApiError(
        code: CardanoApiError.invalidRequest,
        info: 'paginate requires page >= 0 and limit > 0',
      );
    }
    return CardanoPaginate(page: page, limit: limit);
  }

  String _collateralAmount(Object? params) {
    Object? amount = _param<Object?>(params, 0, 'amount');
    if (amount is Map) {
      amount = amount['amount'];
    }
    if (amount == null) {
      throw const CardanoApiError(
        code: CardanoApiError.invalidRequest,
        info: 'Missing required parameter: amount',
      );
    }
    if (amount is! String) {
      throw const CardanoApiError(
        code: CardanoApiError.invalidRequest,
        info: 'Invalid parameter type for: amount',
      );
    }
    return amount;
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

  Future<List<Map<String, Object>>> _handleGetExtensions(
    String topic,
    Object? params,
  ) {
    return _execute(() async {
      final extensions = await _delegate.getExtensions();
      return extensions.map((extension) => extension.toJson()).toList();
    });
  }

  Future<int> _handleGetNetworkId(String topic, Object? params) {
    return _execute(() => _delegate.getNetworkId());
  }

  Future<String> _handleGetBalance(String topic, Object? params) {
    return _execute(() => _delegate.getBalance());
  }

  Future<List<String>> _handleGetUsedAddresses(String topic, Object? params) {
    return _execute(() async {
      final Object? paginateParam = _param<Object?>(params, 0, 'paginate');
      final CardanoPaginate? paginate = _paginateFromParam(paginateParam);
      return _delegate.getUsedAddresses(paginate: paginate);
    });
  }

  Future<List<String>> _handleGetUnusedAddresses(String topic, Object? params) {
    return _execute(() => _delegate.getUnusedAddresses());
  }

  Future<String> _handleGetChangeAddress(String topic, Object? params) {
    return _execute(() => _delegate.getChangeAddress());
  }

  Future<List<String>> _handleGetRewardAddresses(String topic, Object? params) {
    return _execute(() => _delegate.getRewardAddresses());
  }

  Future<String> _handleGetRewardAddress(String topic, Object? params) {
    return _execute(() async {
      final rewardAddresses = await _delegate.getRewardAddresses();
      if (rewardAddresses.isEmpty) {
        throw const CardanoApiError(
          code: CardanoApiError.internalError,
          info: 'Wallet returned no reward addresses',
        );
      }
      return rewardAddresses.first;
    });
  }

  Future<List<String>?> _handleGetUtxos(String topic, Object? params) {
    return _execute(() {
      final String? amount = _param<String>(params, 0, 'amount');
      final Object? paginateParam = _param<Object?>(params, 1, 'paginate');
      final CardanoPaginate? paginate = _paginateFromParam(paginateParam);
      return _delegate.getUtxos(amount: amount, paginate: paginate);
    });
  }

  Future<List<String>?> _handleGetCollateral(String topic, Object? params) {
    return _execute(() {
      return _delegate.getCollateral(amount: _collateralAmount(params));
    });
  }

  Future<String> _handleSignTx(String topic, Object? params) {
    return _execute(() {
      final String tx = _requiredParam<String>(params, 0, 'tx');
      final bool partialSign = _param<bool>(params, 1, 'partialSign') ?? false;
      return _delegate.signTx(tx, partialSign: partialSign);
    });
  }

  Future<Map<String, Object>> _handleSignData(String topic, Object? params) {
    return _execute(() async {
      final String address = _requiredParam<String>(params, 0, 'address');
      final String payload = _requiredParam<String>(params, 1, 'payload');
      final signature = await _delegate.signData(address, payload);
      return signature.toJson();
    });
  }

  Future<String> _handleSubmitTx(String topic, Object? params) {
    return _execute(() {
      final String tx = _requiredParam<String>(params, 0, 'tx');
      return _delegate.submitTx(tx);
    });
  }
}
