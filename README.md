# wallet_connect_cardano

A WalletConnect v2 communication bridge for Cardano wallets, implementing [CIP-30](https://cips.cardano.org/cip/CIP-30) over the WalletConnect relay protocol.

> **⚠️ This SDK is a transport layer, not a signing engine.** It routes CIP-30 JSON-RPC requests from dApps to your wallet app via callbacks. Your wallet app performs the actual signing, balance queries, and UTXO management.

## What it does

When a dApp connects to your Cardano wallet via WalletConnect:

1. **dApp sends a CIP-30 request** (e.g., `cardano_signTx`) over WalletConnect
2. **SDK receives and deserializes** the JSON-RPC request
3. **SDK routes to your delegate** — calls the corresponding method on your `CardanoWalletDelegate` implementation
4. **Your wallet app does the work** — signs the transaction, queries UTXOs, submits to the network, etc.
5. **SDK returns the response** — serializes the result and sends it back to the dApp over WalletConnect

The SDK handles all WalletConnect session management, CIP-30 method routing, and error handling. You implement the `CardanoWalletDelegate` interface to provide the actual wallet functionality.

## Installation

Add `wallet_connect_cardano` to your `pubspec.yaml`:

```yaml
dependencies:
  wallet_connect_cardano: ^0.0.1
```

Then run:

```bash
flutter pub get
```

The SDK depends on `reown_walletkit` for WalletConnect v2 transport. This dependency is automatically included.

## Quick Start

### 1. Implement CardanoWalletDelegate

Create a class that implements `CardanoWalletDelegate`:

```dart
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

class MyWalletDelegate implements CardanoWalletDelegate {
  @override
  Future<int> getNetworkId() async {
    // Return 0 for testnet, 1 for mainnet
    return 1;
  }

  @override
  Future<List<String>?> getUtxos({String? amount, CardanoPaginate? paginate}) async {
    // Return list of hex-encoded CBOR TransactionUnspentOutput values
    // or null if pagination exceeded
    return ['hex_encoded_utxo_1', 'hex_encoded_utxo_2'];
  }

  @override
  Future<String> getBalance() async {
    // Return hex-encoded CBOR value (lovelace + multi-asset)
    return 'a1581c...'; // CBOR hex
  }

  @override
  Future<List<String>> getUsedAddresses({CardanoPaginate? paginate}) async {
    // Return list of hex-encoded payment addresses
    return ['addr1qy2...', 'addr1qz3...'];
  }

  @override
  Future<List<String>> getUnusedAddresses() async {
    // Return list of hex-encoded unused payment addresses
    return ['addr1qa4...'];
  }

  @override
  Future<String> getChangeAddress() async {
    // Return hex-encoded change address
    return 'addr1qb5...';
  }

  @override
  Future<List<String>> getRewardAddresses() async {
    // Return list of hex-encoded reward (staking) addresses
    return ['stake1u9...'];
  }

  @override
  Future<String> signTx(String tx, {bool partialSign = false}) async {
    // Sign the transaction (hex-encoded CBOR)
    // Return hex-encoded CBOR witness set
    // Throw CardanoTxSignError on failure
    return 'a200...'; // CBOR hex
  }

  @override
  Future<CardanoDataSignature> signData(String address, String payload) async {
    // Sign arbitrary data with the given address
    // Return CardanoDataSignature with signature and key (both hex-encoded CBOR)
    // Throw CardanoDataSignError on failure
    return CardanoDataSignature(
      signature: 'd8...', // CBOR hex
      key: 'a4...',       // CBOR hex
    );
  }

  @override
  Future<String> submitTx(String tx) async {
    // Submit signed transaction to the network
    // Return transaction hash as hex-encoded string
    // Throw CardanoTxSendError on failure
    return 'a1b2c3d4...'; // tx hash hex
  }

  @override
  Future<List<CardanoExtension>> getExtensions() async {
    // Return list of supported CIP extensions
    // Return empty list if no extensions supported
    return [];
  }
}
```

### 2. Initialize the SDK

```dart
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:wallet_connect_cardano/wallet_connect_cardano.dart';

void main() async {
  final delegate = MyWalletDelegate();
  
  final walletConnect = WalletConnectCardano(
    projectId: 'YOUR_WALLETCONNECT_PROJECT_ID',
    metadata: PairingMetadata(
      name: 'My Cardano Wallet',
      description: 'A Cardano wallet with WalletConnect support',
      url: 'https://mywalletapp.com',
      icons: ['https://mywalletapp.com/icon.png'],
    ),
    delegate: delegate,
    chainIds: [WalletConnectCardano.mainnet], // or .preprod, .preview
  );

  await walletConnect.initialize();
  
  // Listen for session proposals from dApps
  walletConnect.onSessionProposal.listen((SessionProposalEvent event) {
    // Show UI to user asking to approve/reject
    // Then call approveSession or rejectSession
  });
}
```

### 3. Handle Session Proposals

```dart
walletConnect.onSessionProposal.listen((SessionProposalEvent event) async {
  // User approved the connection
  await walletConnect.approveSession(
    id: event.id,
    accountAddress: 'addr1qy2...', // The user's payment address
    chainId: WalletConnectCardano.mainnet,
  );
  
  // Or reject if user declined
  // await walletConnect.rejectSession(
  //   id: event.id,
  //   reason: ReownSignError(code: 5000, message: 'User rejected'),
  // );
});
```

### 4. Pair with a dApp

```dart
// Get the WalletConnect URI from the dApp (usually via QR code)
final uri = Uri.parse('wc:...');

// Pair with the dApp
final pairingInfo = await walletConnect.pair(uri: uri);
```

## CardanoWalletDelegate

Your wallet app must implement all 11 methods of `CardanoWalletDelegate`:

| Method | Parameters | Returns | Throws |
|--------|-----------|---------|--------|
| `getNetworkId()` | none | `int` (0=testnet, 1=mainnet) | — |
| `getUtxos()` | `amount?`, `paginate?` | `List<String>?` (hex CBOR) | — |
| `getBalance()` | none | `String` (hex CBOR value) | — |
| `getUsedAddresses()` | `paginate?` | `List<String>` (hex addresses) | — |
| `getUnusedAddresses()` | none | `List<String>` (hex addresses) | — |
| `getChangeAddress()` | none | `String` (hex address) | — |
| `getRewardAddresses()` | none | `List<String>` (hex addresses) | — |
| `signTx()` | `tx`, `partialSign?` | `String` (hex CBOR witness) | `CardanoTxSignError` |
| `signData()` | `address`, `payload` | `CardanoDataSignature` | `CardanoDataSignError` |
| `submitTx()` | `tx` | `String` (tx hash hex) | `CardanoTxSendError` |
| `getExtensions()` | none | `List<CardanoExtension>` | — |

All address, transaction, and CBOR values are **lowercase hex-encoded strings**. The SDK never encodes or decodes CBOR itself — that is the responsibility of your wallet app and the dApp.

## Session Management

### Approve a Session

```dart
await walletConnect.approveSession(
  id: proposalEvent.id,
  accountAddress: 'addr1qy2...',
  chainId: WalletConnectCardano.mainnet,
);
```

### Reject a Session

```dart
await walletConnect.rejectSession(
  id: proposalEvent.id,
  reason: ReownSignError(code: 5000, message: 'User rejected'),
);
```

### Disconnect a Session

```dart
await walletConnect.disconnectSession(
  topic: sessionTopic,
  reason: ReownSignError(code: 5000, message: 'User disconnected'),
);
```

### Get Active Sessions

```dart
final sessions = walletConnect.getActiveSessions();
for (final session in sessions.values) {
  print('Session: ${session.topic}');
}
```

### Emit Account Change

When the user switches accounts in your wallet:

```dart
await walletConnect.emitAccountChange(
  topic: sessionTopic,
  chainId: WalletConnectCardano.mainnet,
  newAddress: 'addr1qz3...',
);
```

### Emit Network Change

When the user switches networks:

```dart
await walletConnect.emitNetworkChange(
  topic: sessionTopic,
  newChainId: WalletConnectCardano.preprod,
);
```

## CIP-30 Methods Reference

The SDK routes these CIP-30 JSON-RPC methods from dApps to your delegate:

| JSON-RPC Method | CIP-30 Method | Description |
|---|---|---|
| `cardano_getExtensions` | `getExtensions()` | List supported CIP extensions |
| `cardano_getNetworkId` | `getNetworkId()` | Get current network (0=testnet, 1=mainnet) |
| `cardano_getBalance` | `getBalance()` | Get total wallet balance |
| `cardano_getUtxos` | `getUtxos()` | Get unspent transaction outputs |
| `cardano_getUsedAddresses` | `getUsedAddresses()` | Get addresses that have received funds |
| `cardano_getUnusedAddresses` | `getUnusedAddresses()` | Get addresses that have never received funds |
| `cardano_getChangeAddress` | `getChangeAddress()` | Get change address |
| `cardano_getRewardAddresses` | `getRewardAddresses()` | Get staking addresses |
| `cardano_getRewardAddress` | `getRewardAddresses()` | Get first staking address (singular variant) |
| `cardano_signTx` | `signTx()` | Sign a transaction |
| `cardano_signData` | `signData()` | Sign arbitrary data |
| `cardano_submitTx` | `submitTx()` | Submit signed transaction to network |

## Error Handling

The SDK propagates CIP-30 errors from your delegate back to the dApp. Throw the appropriate error type in your delegate methods:

### CardanoApiError

General API errors:

```dart
throw CardanoApiError(
  code: CardanoApiError.invalidRequest,
  info: 'Invalid parameters',
);
```

Error codes:
- `invalidRequest` (-1): Invalid parameters
- `internalError` (-2): Internal wallet error
- `refused` (-3): Request refused by user or wallet
- `accountChange` (-4): Account changed since request

### CardanoTxSignError

Transaction signing errors:

```dart
throw CardanoTxSignError(
  code: CardanoTxSignError.userDeclined,
  info: 'User declined to sign',
);
```

Error codes:
- `proofGeneration` (1): Could not construct witness
- `userDeclined` (2): User declined the request

### CardanoDataSignError

Data signing errors:

```dart
throw CardanoDataSignError(
  code: CardanoDataSignError.addressNotPK,
  info: 'Address is not a public key address',
);
```

Error codes:
- `proofGeneration` (1): Could not construct proof
- `addressNotPK` (2): Address is not P2PKH
- `userDeclined` (3): User declined the request

### CardanoTxSendError

Transaction submission errors:

```dart
throw CardanoTxSendError(
  code: CardanoTxSendError.failure,
  info: 'Transaction failed to submit',
);
```

Error codes:
- `refused` (1): Transaction was refused
- `failure` (2): Transaction failed to submit

## Configuration

### Chain IDs

The SDK supports three Cardano networks:

```dart
WalletConnectCardano.mainnet   // 'cip34:1-764824073'
WalletConnectCardano.preprod   // 'cip34:0-1'
WalletConnectCardano.preview   // 'cip34:0-2'
```

Pass one or more chain IDs when creating the SDK:

```dart
final walletConnect = WalletConnectCardano(
  projectId: 'YOUR_PROJECT_ID',
  metadata: metadata,
  delegate: delegate,
  chainIds: [
    WalletConnectCardano.mainnet,
    WalletConnectCardano.preprod,
  ],
);
```

### Wallet Metadata

Provide metadata about your wallet that will be shown to dApps:

```dart
final metadata = PairingMetadata(
  name: 'My Cardano Wallet',
  description: 'A secure Cardano wallet with WalletConnect support',
  url: 'https://mywalletapp.com',
  icons: ['https://mywalletapp.com/icon-192.png'],
);
```

### WalletConnect Project ID

Get a free project ID from [WalletConnect Cloud](https://cloud.walletconnect.com):

```dart
final walletConnect = WalletConnectCardano(
  projectId: 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
  metadata: metadata,
  delegate: delegate,
);
```

## References

- [CIP-30: Cardano dApp-Wallet Web Bridge](https://cips.cardano.org/cip/CIP-30)
- [CIP-34: Chain ID Registry](https://cips.cardano.org/cip/CIP-0034)
- [Reown WalletKit Documentation](https://docs.reown.com/walletkit/flutter/installation)
- [WalletConnect](https://walletconnect.com)

## License

MIT
