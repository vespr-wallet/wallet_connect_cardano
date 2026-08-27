import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

void main() {
  const metadata = PairingMetadata(
    name: 'Test Wallet',
    description: 'WalletConnect Cardano tests',
  );

  late _MockDelegate delegate;
  late _LifecycleWalletKit walletKit;
  late WalletConnectCardano sdk;

  setUp(() {
    delegate = _MockDelegate();
    walletKit = _LifecycleWalletKit();
    sdk = WalletConnectCardano(
      projectId: 'test-project-id',
      metadata: metadata,
      delegate: delegate,
      chainIds: const <String>[
        WalletConnectCardano.preprod,
        WalletConnectCardano.preview,
      ],
      walletKit: walletKit,
    );
  });

  test('requires at least one chain', () {
    expect(
      () => WalletConnectCardano(
        projectId: 'test-project-id',
        metadata: metadata,
        delegate: delegate,
        chainIds: const <String>[],
        walletKit: walletKit,
      ),
      throwsArgumentError,
    );
  });

  test('fails clearly when used before initialization', () {
    expect(sdk.isInitialized, isFalse);
    expect(() => sdk.walletKit, throwsStateError);
    expect(
      () => sdk.registerAccount(
        chainId: WalletConnectCardano.preprod,
        accountAddress: 'addr_test1',
      ),
      throwsStateError,
    );
  });

  test('initializes each chain exactly once', () async {
    final first = sdk.initialize();
    final second = sdk.initialize();
    await Future.wait(<Future<void>>[first, second]);
    await sdk.initialize();

    expect(sdk.isInitialized, isTrue);
    expect(sdk.walletKit, same(walletKit));
    expect(walletKit.registeredMethods, hasLength(26));
    expect(
      walletKit.registeredMethods.where(
        (entry) => entry.method == 'cardano_getCollateral',
      ),
      hasLength(2),
    );
    expect(walletKit.registeredEvents, hasLength(8));
    expect(
      walletKit.registeredEvents.map((entry) => entry.event).toSet(),
      <String>{
        'chainChanged',
        'accountsChanged',
        'cardano_onNetworkChange',
        'cardano_onAccountChange',
      },
    );
  });

  test('exposes WalletKit proposal events after initialization', () async {
    await sdk.initialize();

    expect(sdk.onSessionProposal, same(walletKit.sessionProposals));
    expect(sdk.onSessionProposalError, same(walletKit.sessionProposalErrors));
    expect(sdk.onSessionAuthRequest, same(walletKit.sessionAuthRequestEvents));
  });

  test('builds a complete cip34 namespace when approving', () async {
    await sdk.initialize();

    final response = await sdk.approveSession(
      id: 7,
      accountAddress: 'addr_test1wallet',
      chainId: WalletConnectCardano.preprod,
    );

    expect(response, same(walletKit.approveResponse));
    expect(walletKit.approvalId, 7);
    final namespace = walletKit.approvedNamespaces!['cip34']!;
    expect(namespace.accounts, <String>[
      '${WalletConnectCardano.preprod}:addr_test1wallet',
    ]);
    expect(namespace.methods, contains('cardano_getCollateral'));
    expect(namespace.methods, hasLength(13));
    expect(
      namespace.events,
      containsAll(<String>[
        'chainChanged',
        'accountsChanged',
        'cardano_onNetworkChange',
        'cardano_onAccountChange',
      ]),
    );
  });

  test('passes generated proposal namespaces through unchanged', () async {
    await sdk.initialize();
    final namespaces = <String, Namespace>{
      'cip34': const Namespace(
        accounts: <String>['cip34:0-1:addr_test1generated'],
        methods: <String>['cardano_getNetworkId'],
        events: <String>['chainChanged'],
      ),
    };

    await sdk.approveSession(
      id: 8,
      accountAddress: 'ignored',
      namespaces: namespaces,
    );

    expect(walletKit.approvedNamespaces, same(namespaces));
  });

  test('forwards account and session lifecycle operations', () async {
    await sdk.initialize();
    const reason = ReownSignError(code: 6000, message: 'User disconnected');

    sdk.registerAccount(
      chainId: WalletConnectCardano.preprod,
      accountAddress: 'addr_test1wallet',
    );
    await sdk.rejectSession(id: 9, reason: reason);
    await sdk.disconnectSession(topic: 'topic-1', reason: reason);

    expect(walletKit.registeredAccounts.single, (
      chainId: WalletConnectCardano.preprod,
      address: 'addr_test1wallet',
    ));
    expect(walletKit.rejectedSession, (id: 9, reason: reason));
    expect(walletKit.disconnectedSession, (topic: 'topic-1', reason: reason));
    expect(sdk.getActiveSessions(), isEmpty);
  });

  test('forwards pairing to WalletKit', () async {
    await sdk.initialize();
    final uri = Uri.parse('wc:pairing@2?relay-protocol=irn&symKey=abc');

    final result = await sdk.pair(uri: uri);

    expect(result, same(walletKit.pairingInfo));
    expect(walletKit.pairingUri, uri);
  });

  test('emits both account change event conventions', () async {
    await sdk.initialize();

    await sdk.emitAccountChange(
      topic: 'topic-1',
      chainId: WalletConnectCardano.preprod,
      newAddress: 'addr_test1new',
    );

    expect(walletKit.emittedEvents, hasLength(2));
    expect(walletKit.emittedEvents.map((entry) => entry.event.name), <String>[
      'accountsChanged',
      'cardano_onAccountChange',
    ]);
    expect(
      walletKit.emittedEvents.map((entry) => entry.event.data),
      everyElement('addr_test1new'),
    );
  });

  test('emits both network change event conventions', () async {
    await sdk.initialize();

    await sdk.emitNetworkChange(
      topic: 'topic-1',
      newChainId: WalletConnectCardano.preview,
    );

    expect(walletKit.emittedEvents, hasLength(2));
    expect(walletKit.emittedEvents.map((entry) => entry.event.name), <String>[
      'chainChanged',
      'cardano_onNetworkChange',
    ]);
    expect(
      walletKit.emittedEvents.map((entry) => entry.chainId),
      everyElement(WalletConnectCardano.preview),
    );
  });
}

class _MockDelegate extends Mock implements CardanoWalletDelegate {}

class _LifecycleWalletKit extends Mock implements IReownWalletKit {
  final Event<SessionProposalEvent> sessionProposals =
      Event<SessionProposalEvent>();
  final Event<SessionProposalErrorEvent> sessionProposalErrors =
      Event<SessionProposalErrorEvent>();
  final Event<SessionAuthRequest> sessionAuthRequestEvents =
      Event<SessionAuthRequest>();
  final List<({String chainId, String method})> registeredMethods =
      <({String chainId, String method})>[];
  final List<({String chainId, String event})> registeredEvents =
      <({String chainId, String event})>[];
  final List<({String chainId, String address})> registeredAccounts =
      <({String chainId, String address})>[];
  final List<({String topic, String chainId, SessionEventParams event})>
  emittedEvents =
      <({String topic, String chainId, SessionEventParams event})>[];
  final ApproveResponse approveResponse = ApproveResponse(
    topic: 'approved-topic',
    session: null,
  );
  late final PairingInfo pairingInfo = PairingInfo(
    topic: 'pairing-topic',
    expiry: 0,
    relay: Relay('irn'),
    active: true,
  );

  int? approvalId;
  Map<String, Namespace>? approvedNamespaces;
  ({int id, ReownSignError reason})? rejectedSession;
  ({String topic, ReownSignError reason})? disconnectedSession;
  Uri? pairingUri;

  @override
  Event<SessionProposalEvent> get onSessionProposal => sessionProposals;

  @override
  Event<SessionProposalErrorEvent> get onSessionProposalError =>
      sessionProposalErrors;

  @override
  Event<SessionAuthRequest> get onSessionAuthRequest =>
      sessionAuthRequestEvents;

  @override
  void registerRequestHandler({
    required String chainId,
    required String method,
    dynamic Function(String, dynamic)? handler,
  }) {
    registeredMethods.add((chainId: chainId, method: method));
  }

  @override
  void registerEventEmitter({required String chainId, required String event}) {
    registeredEvents.add((chainId: chainId, event: event));
  }

  @override
  void registerAccount({
    required String chainId,
    required String accountAddress,
  }) {
    registeredAccounts.add((chainId: chainId, address: accountAddress));
  }

  @override
  Future<ApproveResponse> approveSession({
    required int id,
    required Map<String, Namespace> namespaces,
    Map<String, String>? sessionProperties,
    String? relayProtocol,
    ProposalRequestsResponses? proposalRequestsResponses,
  }) async {
    approvalId = id;
    approvedNamespaces = namespaces;
    return approveResponse;
  }

  @override
  Future<void> rejectSession({
    required int id,
    required ReownSignError reason,
  }) async {
    rejectedSession = (id: id, reason: reason);
  }

  @override
  Future<void> disconnectSession({
    required String topic,
    required ReownSignError reason,
  }) async {
    disconnectedSession = (topic: topic, reason: reason);
  }

  @override
  Map<String, SessionData> getActiveSessions() => <String, SessionData>{};

  @override
  Future<PairingInfo> pair({required Uri uri}) async {
    pairingUri = uri;
    return pairingInfo;
  }

  @override
  Future<void> emitSessionEvent({
    required String topic,
    required String chainId,
    required SessionEventParams event,
  }) async {
    emittedEvents.add((topic: topic, chainId: chainId, event: event));
  }
}
