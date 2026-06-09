import 'package:flutter/material.dart';

/// Scrollable approval sheet for sign / submit requests.
class SigningApprovalDialog extends StatelessWidget {
  const SigningApprovalDialog({
    super.key,
    required this.method,
    required this.detail,
    this.subtitle,
  });

  final String method;
  final String detail;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(method),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (subtitle != null) ...<Widget>[
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
              ],
              SelectableText(
                detail,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
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
    );
  }
}
