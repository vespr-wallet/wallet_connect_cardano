import 'dart:async';

import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

import '../delegate/demo_wallet_delegate.dart';

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

  final StreamController<RequestLogEntry> _requestLogController =
      StreamController<RequestLogEntry>.broadcast();

  final StreamController<void> _stateController =
      StreamController<void>.broadcast();

  Stream<RequestLogEntry> get requestLog => _requestLogController.stream;
  Stream<void> get stateChanges => _stateController.stream;

  bool get isInitialized => _sdk != null;
  bool get hasPendingProposal => _pendingProposal != null;
  bool get isConnected => _activeSessionTopic != null;
  String? get connectedDappName => _connectedDappName;
  String? get activeSessionTopic => _activeSessionTopic;
  SessionProposalEvent? get pendingProposal => _pendingProposal;

  Future<void> initialize() async {
    if (_sdk != null) return;

    delegate.onRequest = (method) {
      _requestLogController.add(
        RequestLogEntry(method: method, timestamp: DateTime.now()),
      );
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

    _sdk!.onSessionProposal.subscribe(_onSessionProposal);
    _sdk!.walletKit.onSessionDelete.subscribe((_) {
      _activeSessionTopic = null;
      _connectedDappName = null;
      _notify();
    });
  }

  void _onSessionProposal(SessionProposalEvent event) {
    _pendingProposal = event;
    _notify();
  }

  Future<void> pair(Uri uri) async {
    await _sdk!.pair(uri: uri);
  }

  Future<void> approvePendingSession() async {
    final proposal = _pendingProposal;
    if (proposal == null) return;

    await _sdk!.approveSession(
      id: proposal.id,
      accountAddress: delegate.demoWallet.paymentAddressBech32,
      chainId: WalletConnectCardano.preprod,
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
