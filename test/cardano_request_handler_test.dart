import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_core/store/i_generic_store.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

void main() {
  const chainId = WalletConnectCardano.preprod;
  const topic = 'session-topic';

  late _RecordingDelegate delegate;
  late _TestWalletKit walletKit;
  late CardanoRequestHandler handler;
  var nextRequestId = 1;

  setUp(() {
    delegate = _RecordingDelegate();
    walletKit = _TestWalletKit();
    handler = CardanoRequestHandler(delegate);
    handler.registerHandlers(walletKit, chainId);
    nextRequestId = 1;
  });

  Future<JsonRpcResponse<dynamic>> invoke(
    String method, [
    Object? params = const <Object?>[],
  ]) async {
    walletKit.pending.requests.add(
      _sessionRequest(
        id: nextRequestId++,
        topic: topic,
        method: method,
        params: params,
      ),
    );
    await walletKit.handlers[method]!(topic, params);
    return walletKit.responses.last.response;
  }

  test('registers every supported method on the requested chain', () {
    expect(walletKit.handlers.keys, <String>{
      'cardano_getExtensions',
      'cardano_getNetworkId',
      'cardano_getBalance',
      'cardano_getUsedAddresses',
      'cardano_getUnusedAddresses',
      'cardano_getChangeAddress',
      'cardano_getRewardAddresses',
      'cardano_getRewardAddress',
      'cardano_getUtxos',
      'cardano_getCollateral',
      'cardano_signTx',
      'cardano_signData',
      'cardano_submitTx',
    });
    expect(walletKit.registeredChains, everyElement(chainId));
  });

  test('routes parameterless read methods and serializes results', () async {
    expect(
      (await invoke('cardano_getExtensions')).result,
      <Map<String, Object>>[
        <String, Object>{'cip': 95},
      ],
    );
    expect((await invoke('cardano_getNetworkId')).result, 0);
    expect((await invoke('cardano_getBalance')).result, 'balance-cbor');
    expect((await invoke('cardano_getUnusedAddresses')).result, <String>[
      'unused-address',
    ]);
    expect((await invoke('cardano_getChangeAddress')).result, 'change-address');
    expect((await invoke('cardano_getRewardAddresses')).result, <String>[
      'reward-address',
    ]);
    expect((await invoke('cardano_getRewardAddress')).result, 'reward-address');
  });

  test('routes positional and named pagination parameters', () async {
    await invoke('cardano_getUsedAddresses', <Object?>[
      <String, Object>{'page': 2, 'limit': 20},
    ]);
    expect(delegate.usedAddressesPaginate?.page, 2);
    expect(delegate.usedAddressesPaginate?.limit, 20);

    await invoke('cardano_getUsedAddresses', <String, Object>{
      'paginate': <String, Object>{'page': 3, 'limit': 10},
    });
    expect(delegate.usedAddressesPaginate?.page, 3);
    expect(delegate.usedAddressesPaginate?.limit, 10);
  });

  test('routes positional and named getUtxos parameters', () async {
    final positional = await invoke('cardano_getUtxos', <Object?>[
      'amount-cbor',
      <String, Object>{'page': 1, 'limit': 5},
    ]);
    expect(positional.result, <String>['utxo-cbor']);
    expect(delegate.utxoAmount, 'amount-cbor');
    expect(delegate.utxoPaginate?.page, 1);
    expect(delegate.utxoPaginate?.limit, 5);

    await invoke('cardano_getUtxos', <String, Object?>{
      'amount': 'named-amount',
      'paginate': <String, Object>{'page': 0, 'limit': 50},
    });
    expect(delegate.utxoAmount, 'named-amount');
    expect(delegate.utxoPaginate?.page, 0);
    expect(delegate.utxoPaginate?.limit, 50);
  });

  test(
    'accepts collateral params used by both connector conventions',
    () async {
      final named = await invoke('cardano_getCollateral', <String, Object>{
        'amount': '5000000',
      });
      expect(named.result, <String>['collateral-cbor']);
      expect(delegate.collateralAmount, '5000000');

      await invoke('cardano_getCollateral', <Object?>[
        <String, Object>{'amount': '6000000'},
      ]);
      expect(delegate.collateralAmount, '6000000');

      await invoke('cardano_getCollateral', <Object?>['7000000']);
      expect(delegate.collateralAmount, '7000000');
    },
  );

  test('rejects missing and malformed collateral amounts', () async {
    final missing = await invoke('cardano_getCollateral');
    expect(missing.error?.code, CardanoApiError.invalidRequest);
    expect(missing.error?.message, 'Missing required parameter: amount');

    final malformed = await invoke('cardano_getCollateral', <String, Object>{
      'amount': 5000000,
    });
    expect(malformed.error?.code, CardanoApiError.invalidRequest);
    expect(malformed.error?.message, 'Invalid parameter type for: amount');
  });

  test('routes signTx with optional partial signing', () async {
    expect(
      (await invoke('cardano_signTx', <Object?>['tx-cbor', true])).result,
      'witness-cbor',
    );
    expect(delegate.signedTx, 'tx-cbor');
    expect(delegate.partialSign, isTrue);

    await invoke('cardano_signTx', <String, Object>{
      'tx': 'named-tx',
      'partialSign': false,
    });
    expect(delegate.signedTx, 'named-tx');
    expect(delegate.partialSign, isFalse);
  });

  test('routes signData and submitTx in both parameter formats', () async {
    expect(
      (await invoke('cardano_signData', <Object?>[
        'address',
        'payload',
      ])).result,
      <String, Object>{'signature': 'signature-cbor', 'key': 'key-cbor'},
    );
    expect(delegate.dataAddress, 'address');
    expect(delegate.dataPayload, 'payload');

    expect(
      (await invoke('cardano_submitTx', <String, Object>{
        'tx': 'signed-tx',
      })).result,
      'tx-hash',
    );
    expect(delegate.submittedTx, 'signed-tx');
  });

  test('rejects malformed optional and pagination parameters', () async {
    final partialSign = await invoke('cardano_signTx', <Object?>[
      'tx-cbor',
      'yes',
    ]);
    expect(partialSign.error?.code, CardanoApiError.invalidRequest);
    expect(
      partialSign.error?.message,
      'Invalid parameter type for: partialSign',
    );

    final paginateType = await invoke('cardano_getUtxos', <String, Object>{
      'paginate': 'first-page',
    });
    expect(paginateType.error?.code, CardanoApiError.invalidRequest);

    final paginateBounds = await invoke(
      'cardano_getUsedAddresses',
      <String, Object>{
        'paginate': <String, Object>{'page': -1, 'limit': 0},
      },
    );
    expect(paginateBounds.error?.code, CardanoApiError.invalidRequest);
    expect(
      paginateBounds.error?.message,
      'paginate requires page >= 0 and limit > 0',
    );
  });

  test('maps every CIP-30 error family to JSON-RPC errors', () async {
    delegate.errors['cardano_getBalance'] = const CardanoApiError(
      code: CardanoApiError.refused,
      info: 'Balance refused',
    );
    expect(
      (await invoke('cardano_getBalance')).error?.code,
      CardanoApiError.refused,
    );

    delegate.errors['cardano_signData'] = const CardanoDataSignError(
      code: CardanoDataSignError.userDeclined,
      info: 'Data declined',
    );
    expect(
      (await invoke('cardano_signData', <Object?>[
        'address',
        'payload',
      ])).error?.code,
      CardanoDataSignError.userDeclined,
    );

    delegate.errors['cardano_getUsedAddresses'] = const CardanoPaginateError(
      maxSize: 100,
    );
    final paginate = await invoke('cardano_getUsedAddresses');
    expect(paginate.error?.code, CardanoApiError.invalidRequest);
    expect(paginate.error?.message, 'PaginateError: maxSize 100');

    delegate.errors['cardano_submitTx'] = const CardanoTxSendError(
      code: CardanoTxSendError.failure,
      info: 'Submit failed',
    );
    expect(
      (await invoke('cardano_submitTx', <Object?>['tx'])).error?.code,
      CardanoTxSendError.failure,
    );

    delegate.errors['cardano_signTx'] = const CardanoTxSignError(
      code: CardanoTxSignError.userDeclined,
      info: 'Signing declined',
    );
    expect(
      (await invoke('cardano_signTx', <Object?>['tx'])).error?.code,
      CardanoTxSignError.userDeclined,
    );
  });

  test('maps unexpected delegate failures to an internal error', () async {
    delegate.errors['cardano_getNetworkId'] = StateError('network unavailable');

    final response = await invoke('cardano_getNetworkId');

    expect(response.error?.code, CardanoApiError.internalError);
    expect(response.error?.message, contains('network unavailable'));
  });

  test('responds with the newest exact pending request id', () async {
    walletKit.pending.requests.addAll(<SessionRequest>[
      _sessionRequest(id: 41, topic: topic, method: 'cardano_getBalance'),
      _sessionRequest(id: 42, topic: topic, method: 'cardano_getNetworkId'),
      _sessionRequest(id: 43, topic: topic, method: 'cardano_getBalance'),
    ]);

    await walletKit.handlers['cardano_getBalance']!(topic, const <Object?>[]);

    expect(walletKit.responses.single.response.id, 43);
  });

  test('does not answer an unrelated pending request', () async {
    walletKit.pending.requests.add(
      _sessionRequest(
        id: 50,
        topic: 'other-topic',
        method: 'cardano_getBalance',
      ),
    );

    expect(
      () => walletKit.handlers['cardano_getBalance']!(topic, const <Object?>[]),
      throwsA(
        isA<CardanoApiError>().having(
          (error) => error.code,
          'code',
          CardanoApiError.internalError,
        ),
      ),
    );
    expect(walletKit.responses, isEmpty);
  });

  test('rejects an empty singular reward address result', () async {
    delegate.rewardAddresses = <String>[];

    final response = await invoke('cardano_getRewardAddress');

    expect(response.error?.code, CardanoApiError.internalError);
    expect(response.error?.message, 'Wallet returned no reward addresses');
  });
}

class _TestPendingRequests extends Mock
    implements IGenericStore<SessionRequest> {
  final List<SessionRequest> requests = <SessionRequest>[];

  @override
  List<SessionRequest> getAll() => requests;
}

class _TestWalletKit extends Mock implements IReownWalletKit {
  final _TestPendingRequests pending = _TestPendingRequests();
  final Map<String, dynamic Function(String, dynamic)> handlers =
      <String, dynamic Function(String, dynamic)>{};
  final List<String> registeredChains = <String>[];
  final List<({String topic, JsonRpcResponse<dynamic> response})> responses =
      <({String topic, JsonRpcResponse<dynamic> response})>[];

  @override
  IGenericStore<SessionRequest> get pendingRequests => pending;

  @override
  void registerRequestHandler({
    required String chainId,
    required String method,
    dynamic Function(String, dynamic)? handler,
  }) {
    registeredChains.add(chainId);
    handlers[method] = handler!;
  }

  @override
  Future<void> respondSessionRequest({
    required String topic,
    required JsonRpcResponse response,
  }) async {
    responses.add((topic: topic, response: response));
  }
}

class _RecordingDelegate implements CardanoWalletDelegate {
  final Map<String, Object> errors = <String, Object>{};

  List<CardanoExtension> extensions = const <CardanoExtension>[
    CardanoExtension(cip: 95),
  ];
  int networkId = 0;
  String balance = 'balance-cbor';
  List<String> usedAddresses = <String>['used-address'];
  List<String> unusedAddresses = <String>['unused-address'];
  String changeAddress = 'change-address';
  List<String> rewardAddresses = <String>['reward-address'];
  List<String>? utxos = <String>['utxo-cbor'];
  List<String>? collateral = <String>['collateral-cbor'];

  CardanoPaginate? usedAddressesPaginate;
  String? utxoAmount;
  CardanoPaginate? utxoPaginate;
  String? collateralAmount;
  String? signedTx;
  bool? partialSign;
  String? dataAddress;
  String? dataPayload;
  String? submittedTx;

  void _throwIfConfigured(String method) {
    final error = errors[method];
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<List<CardanoExtension>> getExtensions() async {
    _throwIfConfigured('cardano_getExtensions');
    return extensions;
  }

  @override
  Future<int> getNetworkId() async {
    _throwIfConfigured('cardano_getNetworkId');
    return networkId;
  }

  @override
  Future<List<String>?> getUtxos({
    String? amount,
    CardanoPaginate? paginate,
  }) async {
    _throwIfConfigured('cardano_getUtxos');
    utxoAmount = amount;
    utxoPaginate = paginate;
    return utxos;
  }

  @override
  Future<List<String>?> getCollateral({required String amount}) async {
    _throwIfConfigured('cardano_getCollateral');
    collateralAmount = amount;
    return collateral;
  }

  @override
  Future<String> getBalance() async {
    _throwIfConfigured('cardano_getBalance');
    return balance;
  }

  @override
  Future<List<String>> getUsedAddresses({CardanoPaginate? paginate}) async {
    _throwIfConfigured('cardano_getUsedAddresses');
    usedAddressesPaginate = paginate;
    return usedAddresses;
  }

  @override
  Future<List<String>> getUnusedAddresses() async {
    _throwIfConfigured('cardano_getUnusedAddresses');
    return unusedAddresses;
  }

  @override
  Future<String> getChangeAddress() async {
    _throwIfConfigured('cardano_getChangeAddress');
    return changeAddress;
  }

  @override
  Future<List<String>> getRewardAddresses() async {
    _throwIfConfigured('cardano_getRewardAddresses');
    return rewardAddresses;
  }

  @override
  Future<String> signTx(String tx, {bool partialSign = false}) async {
    _throwIfConfigured('cardano_signTx');
    signedTx = tx;
    this.partialSign = partialSign;
    return 'witness-cbor';
  }

  @override
  Future<CardanoDataSignature> signData(String address, String payload) async {
    _throwIfConfigured('cardano_signData');
    dataAddress = address;
    dataPayload = payload;
    return const CardanoDataSignature(
      signature: 'signature-cbor',
      key: 'key-cbor',
    );
  }

  @override
  Future<String> submitTx(String tx) async {
    _throwIfConfigured('cardano_submitTx');
    submittedTx = tx;
    return 'tx-hash';
  }
}

SessionRequest _sessionRequest({
  required int id,
  required String topic,
  required String method,
  Object? params = const <Object?>[],
}) {
  return SessionRequest(
    id: id,
    topic: topic,
    chainId: WalletConnectCardano.preprod,
    method: method,
    params: params,
    verifyContext: const VerifyContext(
      origin: 'https://dapp.example',
      validation: Validation.VALID,
      verifyUrl: 'https://verify.walletconnect.com',
    ),
  );
}
