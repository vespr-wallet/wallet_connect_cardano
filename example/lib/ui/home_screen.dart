import 'dart:async';

import 'package:flutter/material.dart';
import '../wallet/wallet_connect_service.dart';
import 'qr_scan_screen.dart';
import 'session_proposal_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.service});

  final WalletConnectService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _uriController = TextEditingController();
  final List<RequestLogEntry> _log = <RequestLogEntry>[];
  bool _proposalSheetOpen = false;

  @override
  void initState() {
    super.initState();
    widget.service.delegate.approvalHandler = _confirmSigning;
    widget.service.requestLog.listen((entry) {
      if (!mounted) return;
      setState(() => _log.insert(0, entry));
    });
    widget.service.stateChanges.listen((_) {
      if (!mounted) return;
      setState(() {});
      _scheduleShowProposal();
    });
  }

  void _scheduleShowProposal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_maybeShowProposal());
      }
    });
  }

  Future<void> _maybeShowProposal() async {
    final proposal = widget.service.pendingProposal;
    if (proposal == null || !mounted || _proposalSheetOpen) return;

    _proposalSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => SessionProposalSheet(
          proposal: proposal,
          onApprove: () async {
            Navigator.of(context).pop();
            await widget.service.approvePendingSession();
          },
          onReject: () async {
            Navigator.of(context).pop();
            await widget.service.rejectPendingSession();
          },
        ),
      );
    } finally {
      _proposalSheetOpen = false;
    }
  }

  Future<bool> _confirmSigning(String method, String summary) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(method),
        content: Text(summary),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _scanQr() async {
    final uri = await Navigator.of(context).push<Uri>(
      MaterialPageRoute<Uri>(builder: (_) => const QrScanScreen()),
    );
    if (uri != null) await _pair(uri);
  }

  Future<void> _pasteAndPair() async {
    final text = _uriController.text.trim();
    if (!text.startsWith('wc:')) {
      _showSnack('Paste a valid wc: URI');
      return;
    }
    await _pair(Uri.parse(text));
  }

  Future<void> _pair(Uri uri) async {
    try {
      await widget.service.pair(uri);
      if (!mounted) return;
      _scheduleShowProposal();
      _showSnack('Pairing initiated — approve the connection on this device');
    } catch (error) {
      _showSnack('Pairing failed: $error');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final connected = service.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WC Cardano Example'),
        actions: <Widget>[
          if (connected)
            TextButton(
              onPressed: service.disconnect,
              child: const Text('Disconnect'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (connected)
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Connected',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text('dApp: ${service.connectedDappName ?? "Unknown"}'),
                    const Text('Chain: cip34:0-1 (preprod)'),
                  ],
                ),
              ),
            ),
          if (service.isAwaitingProposal && !service.hasPendingProposal) ...<Widget>[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Waiting for connection request from dApp…'),
          ],
          if (service.lastError != null) ...<Widget>[
            const SizedBox(height: 8),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  service.lastError!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Wallet address', style: Theme.of(context).textTheme.titleSmall),
          SelectableText(service.delegate.demoWallet.paymentAddressBech32),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _scanQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _uriController,
            decoration: const InputDecoration(
              labelText: 'WalletConnect URI',
              hintText: 'wc:...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pasteAndPair,
            child: const Text('Pair from pasted URI'),
          ),
          const SizedBox(height: 24),
          Text('CIP-30 request log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_log.isEmpty)
            const Text('No requests yet — connect to the web dApp demo.')
          else
            ..._log.map(
              (entry) => ListTile(
                dense: true,
                title: Text(entry.method),
                subtitle: Text(entry.timestamp.toIso8601String()),
              ),
            ),
        ],
      ),
    );
  }
}
