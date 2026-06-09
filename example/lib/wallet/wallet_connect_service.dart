import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

import '../delegate/demo_wallet_delegate.dart';
import 'wallet_operation_status.dart';

class RequestLogEntry {
  RequestLogEntry({required this.method, required this.timestamp});

  final String method;
  final DateTime timestamp;
}

class WalletConnectService {
  WalletConnectService({
    required this.projectId,
    required this.delegate,
  });

  final String projectId;
  final DemoWalletDelegate delegate;

  WalletConnectCardano? _sdk;
  SessionProposalEvent? _pendingProposal;
  String? _connectedDappName;
  String? _activeSessionTopic;
  String? _lastError;
  String? _lastSubmittedTxHash;
  WalletOperationStatus? _operationStatus;
  bool _awaitingProposal = false;

  final StreamController<RequestLogEntry> _requestLogController =
      StreamController<RequestLogEntry>.broadcast();

  final StreamController<void> _stateController =
      StreamController<void>.broadcast();

  Stream<RequestLogEntry> get requestLog => _requestLogController.stream;
  Stream<void> get stateChanges => _stateController.stream;

  bool get isInitialized => _sdk != null;
  bool get hasPendingProposal => _pendingProposal != null;
  bool get isAwaitingProposal => _awaitingProposal;
  bool get isConnected => _activeSessionTopic != null;
  String? get connectedDappName => _connectedDappName;
  String? get activeSessionTopic => _activeSessionTopic;
  String? get lastError => _lastError;
  String? get lastSubmittedTxHash => _lastSubmittedTxHash;
  WalletOperationStatus? get operationStatus => _operationStatus;
  SessionProposalEvent? get pendingProposal => _pendingProposal;

  Future<void> initialize() async {
    if (_sdk != null) return;

    delegate.onRequest = (method) {
      _requestLogController.add(
        RequestLogEntry(method: method, timestamp: DateTime.now()),
      );
    };
    delegate.onOperationStarted = (method) {
      _operationStatus = WalletOperationStatus(
        method: method,
        phase: WalletOperationPhase.processing,
      );
      _lastError = null;
      _notify();
    };
    delegate.onOperationSucceeded = (method) {
      if (method == 'cardano_submitTx') {
        return;
      }
      _operationStatus = null;
      _notify();
    };
    delegate.onOperationFailed = (method, error) {
      _operationStatus = WalletOperationStatus(
        method: method,
        phase: WalletOperationPhase.failed,
        message: error,
      );
      _lastError = error;
      _notify();
    };
    delegate.onTransactionSubmitted = (txHash) {
      _lastSubmittedTxHash = txHash;
      _operationStatus = WalletOperationStatus(
        method: 'cardano_submitTx',
        phase: WalletOperationPhase.succeeded,
        txHash: txHash,
      );
      _notify();
    };

    _sdk = WalletConnectCardano(
      projectId: projectId,
      metadata: const PairingMetadata(
        name: 'WC Cardano Example Wallet',
        description: 'Milestone 1 demo wallet for wallet_connect_cardano',
        url: 'https://github.com/vespr-wallet/wallet_connect_cardano',
        icons: <String>['https://vespr.xyz/favicon.ico'],
      ),
      delegate: delegate,
      chainIds: <String>[WalletConnectCardano.preprod],
    );

    await _sdk!.initialize();

    _sdk!.registerAccount(
      chainId: WalletConnectCardano.preprod,
      accountAddress: delegate.demoWallet.paymentAddressBech32,
    );

    _sdk!.onSessionProposal.subscribe(_onSessionProposal);
    _sdk!.onSessionProposalError.subscribe(_onSessionProposalError);
    _sdk!.walletKit.onSessionConnect.subscribe(_onSessionConnect);
    _sdk!.walletKit.core.relayClient.onRelayClientError.subscribe(
      _onRelayClientError,
    );
    _sdk!.walletKit.onSessionDelete.subscribe((_) {
      _activeSessionTopic = null;
      _connectedDappName = null;
      _notify();
    });

    debugPrint(
      '[WC Example] relay connected: '
      '${_sdk!.walletKit.core.relayClient.isConnected}',
    );
  }

  void _onRelayClientError(ErrorEvent? event) {
    if (event == null) return;
    debugPrint('[WC Example] relay error: ${event.error}');
    _lastError = 'Relay error: ${event.error}';
    _notify();
  }

  void _onSessionProposal(SessionProposalEvent event) {
    debugPrint(
      '[WC Example] session proposal from ${event.params.proposer.metadata.name}',
    );
    _pendingProposal = event;
    _awaitingProposal = false;
    _lastError = null;
    _notify();
  }

  void _onSessionProposalError(SessionProposalErrorEvent event) {
    debugPrint('[WC Example] session proposal error: ${event.error.message}');
    _awaitingProposal = false;
    _lastError = event.error.message;
    _notify();
  }

  void _onSessionConnect(SessionConnect? event) {
    if (event == null) return;
    debugPrint('[WC Example] session connected: ${event.session.topic}');
    _pendingProposal = null;
    _awaitingProposal = false;
    _activeSessionTopic = event.session.topic;
    _connectedDappName = event.session.peer.metadata.name;
    _notify();
  }

  Future<void> pair(Uri uri) async {
    _lastError = null;
    _awaitingProposal = true;
    _notify();

    await _sdk!.pair(uri: uri);
    _ingestPendingProposals();

    if (_pendingProposal != null) {
      return;
    }

    for (var attempt = 0; attempt < 45; attempt++) {
      if (!_awaitingProposal || _pendingProposal != null) {
        return;
      }

      await Future<void>.delayed(const Duration(seconds: 1));
      _ingestPendingProposals();

      if (_pendingProposal != null) {
        return;
      }
    }

    if (_awaitingProposal && _pendingProposal == null) {
      _awaitingProposal = false;
      final relayConnected = _sdk!.walletKit.core.relayClient.isConnected;
      _lastError = relayConnected
          ? 'Timed out waiting for session proposal. In the browser, click Connect '
              'first so it shows "Waiting for wallet…", then scan the fresh QR.'
          : 'Wallet relay is offline — rebuild the app after granting INTERNET '
              'permission and check your network.';
      _notify();
    }
  }

  void _ingestPendingProposals() {
    final pending = _sdk!.walletKit.getPendingSessionProposals();
    if (pending.isEmpty) {
      return;
    }

    final proposal = pending.values.first;
    _onSessionProposal(SessionProposalEvent(proposal.id, proposal));
  }

  Future<void> approvePendingSession() async {
    final proposal = _pendingProposal;
    if (proposal == null) return;

    final generated = proposal.params.generatedNamespaces;
    await _sdk!.approveSession(
      id: proposal.id,
      accountAddress: delegate.demoWallet.paymentAddressBech32,
      chainId: WalletConnectCardano.preprod,
      namespaces: generated != null && generated.isNotEmpty ? generated : null,
    );

    _pendingProposal = null;
    _connectedDappName = proposal.params.proposer.metadata.name;
    final sessions = _sdk!.getActiveSessions();
    if (sessions.isNotEmpty) {
      _activeSessionTopic = sessions.values.first.topic;
    }
    _notify();
  }

  Future<void> rejectPendingSession() async {
    final proposal = _pendingProposal;
    if (proposal == null) return;

    await _sdk!.rejectSession(
      id: proposal.id,
      reason: const ReownSignError(code: 5000, message: 'User rejected'),
    );
    _pendingProposal = null;
    _notify();
  }

  Future<void> disconnect() async {
    final topic = _activeSessionTopic;
    if (topic == null) return;

    await _sdk!.disconnectSession(
      topic: topic,
      reason: const ReownSignError(code: 6000, message: 'User disconnected'),
    );
    _activeSessionTopic = null;
    _connectedDappName = null;
    _notify();
  }

  void _notify() => _stateController.add(null);

  Future<void> dispose() async {
    await _requestLogController.close();
    await _stateController.close();
  }
}
