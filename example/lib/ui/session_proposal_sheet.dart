import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class SessionProposalSheet extends StatelessWidget {
  const SessionProposalSheet({
    super.key,
    required this.proposal,
    required this.onApprove,
    required this.onReject,
  });

  final SessionProposalEvent proposal;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final metadata = proposal.params.proposer.metadata;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Connection request',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(metadata.name, style: Theme.of(context).textTheme.titleMedium),
          if (metadata.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(metadata.description),
          ],
          const SizedBox(height: 8),
          Text(metadata.url, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          FilledButton(onPressed: onApprove, child: const Text('Approve')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onReject, child: const Text('Reject')),
        ],
      ),
    );
  }
}
