/// Tracks in-flight CIP-30 write operations for the example wallet UI.
enum WalletOperationPhase { idle, processing, succeeded, failed }

class WalletOperationStatus {
  const WalletOperationStatus({
    required this.method,
    required this.phase,
    this.message,
    this.txHash,
  });

  final String method;
  final WalletOperationPhase phase;
  final String? message;
  final String? txHash;

  bool get isProcessing => phase == WalletOperationPhase.processing;
  bool get isFailed => phase == WalletOperationPhase.failed;
}
