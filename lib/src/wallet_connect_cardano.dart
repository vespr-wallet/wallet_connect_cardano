import 'package:reown_walletkit/reown_walletkit.dart';

import 'cardano_request_handler.dart';
import 'cardano_wallet_delegate.dart';

/// The main entry point for the wallet_connect_cardano SDK.
///
/// Wraps [ReownWalletKit] to provide Cardano (CIP-30) support over
/// WalletConnect v2. Instantiate this class with your
/// [CardanoWalletDelegate], then call [initialize] before using it.
class WalletConnectCardano {
  /// Mainnet chain ID.
  static const String mainnet = 'cip34:1-764824073';

  /// Preprod testnet chain ID.
  static const String preprod = 'cip34:0-1';

  /// Preview testnet chain ID.
  static const String preview = 'cip34:0-2';

  static const List<String> _cip30Methods = <String>[
    'cardano_getExtensions',
    'cardano_getNetworkId',
    'cardano_getBalance',
    'cardano_getUsedAddresses',
    'cardano_getUnusedAddresses',
    'cardano_getChangeAddress',
    'cardano_getRewardAddresses',
    'cardano_getRewardAddress',
    'cardano_getUtxos',
    'cardano_signTx',
    'cardano_signData',
    'cardano_submitTx',
  ];

  static const List<String> _sessionEvents = <String>[
    'chainChanged',
    'accountsChanged',
    'cardano_onNetworkChange',
    'cardano_onAccountChange',
  ];

  /// WalletConnect Cloud project ID.
  final String projectId;

  /// Wallet metadata exposed to dApps.
  final PairingMetadata metadata;

  /// Delegate that performs all wallet-side CIP-30 actions.
  final CardanoWalletDelegate delegate;

  /// Chain IDs supported by this SDK instance.
  ///
  /// Defaults to [mainnet].
  final List<String> chainIds;

  late final IReownWalletKit _walletKit;
  late final CardanoRequestHandler _requestHandler;

  /// Creates a WalletConnect Cardano SDK instance.
  WalletConnectCardano({
    required this.projectId,
    required this.metadata,
    required this.delegate,
    List<String>? chainIds,
  }) : chainIds = chainIds ?? <String>[mainnet];

  /// The underlying WalletKit instance for advanced integration use-cases.
  IReownWalletKit get walletKit => _walletKit;

  /// Emits when a dApp proposes a new WalletConnect session.
  Event<SessionProposalEvent> get onSessionProposal =>
      _walletKit.onSessionProposal;

  /// Emits when a session proposal cannot be satisfied (e.g. namespace mismatch).
  Event<SessionProposalErrorEvent> get onSessionProposalError =>
      _walletKit.onSessionProposalError;

  /// Emits when a dApp sends a session authentication request.
  Event<SessionAuthRequest> get onSessionAuthRequest =>
      _walletKit.onSessionAuthRequest;

  /// Initializes WalletKit and registers Cardano request and event handlers.
  ///
  /// Must be called before calling [pair], [approveSession], or event emitters.
  Future<void> initialize() async {
    _walletKit = await ReownWalletKit.createInstance(
      projectId: projectId,
      metadata: metadata,
    );
    _requestHandler = CardanoRequestHandler(delegate);

    for (final String chainId in chainIds) {
      _requestHandler.registerHandlers(_walletKit, chainId);
      _walletKit.registerEventEmitter(chainId: chainId, event: 'chainChanged');
      _walletKit.registerEventEmitter(
        chainId: chainId,
        event: 'accountsChanged',
      );
      _walletKit.registerEventEmitter(
        chainId: chainId,
        event: 'cardano_onNetworkChange',
      );
      _walletKit.registerEventEmitter(
        chainId: chainId,
        event: 'cardano_onAccountChange',
      );
    }
  }

  /// Registers a wallet account for [chainId].
  ///
  /// Required so WalletKit can match incoming session proposals to the cip34
  /// namespace. Call once per supported chain after [initialize].
  void registerAccount({
    required String chainId,
    required String accountAddress,
  }) {
    _walletKit.registerAccount(
      chainId: chainId,
      accountAddress: accountAddress,
    );
  }

  /// Pairs with a dApp using a WalletConnect URI.
  Future<PairingInfo> pair({required Uri uri}) => _walletKit.pair(uri: uri);

  /// Approves a pending session proposal and creates a Cardano session.
  ///
  /// [id] must be the proposal ID from [onSessionProposal].
  /// Pass [namespaces] from `proposal.params.generatedNamespaces` when present;
  /// otherwise [accountAddress] is used to build the cip34 namespace manually.
  Future<ApproveResponse> approveSession({
    required int id,
    required String accountAddress,
    String? chainId,
    Map<String, Namespace>? namespaces,
  }) {
    final Map<String, Namespace> approvedNamespaces = namespaces ??
        <String, Namespace>{
          'cip34': Namespace(
            accounts: <String>[
              '${chainId ?? chainIds.first}:$accountAddress',
            ],
            methods: _cip30Methods,
            events: _sessionEvents,
          ),
        };

    return _walletKit.approveSession(
      id: id,
      namespaces: approvedNamespaces,
    );
  }

  /// Rejects a pending session proposal.
  Future<void> rejectSession({
    required int id,
    required ReownSignError reason,
  }) {
    return _walletKit.rejectSession(id: id, reason: reason);
  }

  /// Disconnects an active session by topic.
  Future<void> disconnectSession({
    required String topic,
    required ReownSignError reason,
  }) {
    return _walletKit.disconnectSession(topic: topic, reason: reason);
  }

  /// Returns all currently active sessions.
  Map<String, SessionData> getActiveSessions() =>
      _walletKit.getActiveSessions();

  /// Emits account change events using both common ecosystem conventions.
  Future<void> emitAccountChange({
    required String topic,
    required String chainId,
    required String newAddress,
  }) async {
    await _walletKit.emitSessionEvent(
      topic: topic,
      chainId: chainId,
      event: SessionEventParams(name: 'accountsChanged', data: newAddress),
    );

    await _walletKit.emitSessionEvent(
      topic: topic,
      chainId: chainId,
      event: SessionEventParams(
        name: 'cardano_onAccountChange',
        data: newAddress,
      ),
    );
  }

  /// Emits network change events using both common ecosystem conventions.
  Future<void> emitNetworkChange({
    required String topic,
    required String newChainId,
  }) async {
    await _walletKit.emitSessionEvent(
      topic: topic,
      chainId: newChainId,
      event: SessionEventParams(name: 'chainChanged', data: newChainId),
    );

    await _walletKit.emitSessionEvent(
      topic: topic,
      chainId: newChainId,
      event: SessionEventParams(
        name: 'cardano_onNetworkChange',
        data: newChainId,
      ),
    );
  }
}
