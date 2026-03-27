# AGENTS.md — WalletConnect Cardano Flutter SDK

## Project Overview

**Repo**: `vespr-wallet/wallet_connect_cardano`
**Package name**: `wallet_connect_cardano`
**License**: MIT
**Language**: Dart (pure Dart code; Flutter dependency inherited transitively from `reown_walletkit`)

This is a Dart/Flutter SDK that bridges **WalletConnect v2** transport protocol with **Cardano's CIP-30** (dApp-Wallet Web Bridge) standard. It enables Cardano wallet apps (like VESPR) to communicate with desktop/web dApps via the WalletConnect relay network.

### What This SDK IS

A **communication bridge** — a transport layer that:
- Manages WalletConnect v2 sessions (pairing, approval, disconnect) via `reown_walletkit`
- Receives CIP-30 JSON-RPC requests from dApps (e.g., `cardano_signTx`)
- Routes them to the integrating wallet app via a **callback interface**
- Returns the wallet app's responses back to the dApp

### What This SDK is NOT

- NOT a signing engine — it never touches private keys
- NOT a blockchain client — it never queries nodes or submits transactions
- NOT a UTXO manager — it never tracks wallet state
- NOT a UI library — it is headless

The integrating wallet app (e.g., VESPR) implements the callback interface to provide the actual signing, balance queries, UTXO retrieval, etc. This SDK just shuttles the data over WalletConnect.

---

## Catalyst Proposal Context

- **Proposal**: [VESPR: WalletConnect Cardano Flutter SDK & VESPR Integration](https://projectcatalyst.io/funds/14/cardano-open-developers/vespr-walletconnect-cardano-flutter-sdk-and-vespr-integration)
- **Proposal ID**: #1400124 (Fund 14, Cardano Open: Developers)
- **Budget**: 75,000 ADA over 6 months
- **Team**: VESPR Wallet (Alex Dochioiu, Vlad Stan, Daniil Shumko)

---

## Milestones

### Milestone 1: Core SDK Development
- **Delivery**: Month 3 (Feb 2026) | **Budget**: 22,500 ADA
- **Scope**: Functional WalletConnect v2 client with complete session management, CIP-30 method routing, and basic documentation
- **Acceptance**: Stable sessions with test dApps, all CIP-30 methods routed correctly, basic docs
- **Evidence**: GitHub repo, video (tx signing flow), screenshot (WC session)
- **Plan**: `.sisyphus/plans/milestone-1-core-sdk.md`

### Milestone 2: Productizing SDK & Publishing
- **Delivery**: Month 5 (Apr 2026) | **Budget**: 22,500 ADA
- **Scope**: Production-quality codebase, unit tests, comprehensive README, pub.dev publishing
- **Acceptance**: Dart/Flutter best practices, unit test coverage, README with examples, published on pub.dev with semver + changelog
- **Evidence**: pub.dev link, test screenshots, demo video
- **Plan**: `.sisyphus/plans/milestone-2-productize-publish.md`

### Milestone 3: Pilot Integration & Close-out
- **Delivery**: Month 6 (May 2026) | **Budget**: 30,000 ADA
- **Scope**: VESPR Wallet pilot integration (in a SEPARATE repo), Catalyst Final Report, Close-out Video
- **Acceptance**: VESPR beta with WC sessions, CIP-30 working, Final Report, Close-out Video
- **Evidence**: VESPR screenshot, report link, video link
- **Plan**: `.sisyphus/plans/milestone-3-pilot-closeout.md`
- **NOTE**: The VESPR integration code is NOT in this repo. This repo's M3 work is limited to integration guides, any SDK fixes found during pilot, and documentation for the Catalyst deliverables.

---

## Architecture

### Dependency Stack

```
+---------------------------------------------+
|  Wallet App (e.g., VESPR)                   |
|  - Implements CardanoWalletHandler interface |
|  - Owns private keys, UTXOs, blockchain     |
+---------------------------------------------+
|  wallet_connect_cardano (THIS SDK)          |
|  - CIP-30 method routing                   |
|  - Cardano namespace (cip34) config        |
|  - Callback interface definition           |
|  - Session lifecycle helpers               |
+---------------------------------------------+
|  reown_walletkit v1.4.0                     |
|  - WalletConnect v2 session management     |
|  - JSON-RPC transport                      |
|  - Relay protocol                          |
+---------------------------------------------+
|  reown_sign v1.3.9 / reown_core v1.3.8     |
|  - Sign protocol / Core networking         |
+---------------------------------------------+
```

### No Fork Needed

`reown_walletkit` is chain-agnostic. Adding Cardano support is purely additive:
1. `registerAccount(chainId: 'cip34:1-764824073', accountAddress: '...')`
2. `registerRequestHandler(chainId: 'cip34:...', method: 'cardano_signTx', handler: ...)`
3. `approveSession(id: id, namespaces: {'cip34': Namespace(...)})`

No modifications to `reown_walletkit` source required. Forking is acceptable ONLY if a blocking limitation is discovered during implementation.

### Cardano Namespace (CAIP-2 / CIP-34)

| Network | Chain ID |
|---------|----------|
| Mainnet | `cip34:1-764824073` |
| Preprod | `cip34:0-1` |
| Preview | `cip34:0-2` |

Reference: [CIP-34](https://cips.cardano.org/cip/CIP-0034), [WalletConnect JS PR #1880](https://github.com/WalletConnect/walletconnect-monorepo/pull/1880)

---

## CIP-30 Methods (JSON-RPC Mapping)

All methods from [CIP-30 Full API](https://cips.cardano.org/cip/CIP-30#full-api), mapped to JSON-RPC:

| CIP-30 Method | JSON-RPC Method | Params | Returns |
|---|---|---|---|
| `getExtensions()` | `cardano_getExtensions` | none | `Extension[]` |
| `getNetworkId()` | `cardano_getNetworkId` | none | `number` (0=testnet, 1=mainnet) |
| `getUtxos(amount?, paginate?)` | `cardano_getUtxos` | `[cbor<value>?, Paginate?]` | `TransactionUnspentOutput[] or null` |
| `getBalance()` | `cardano_getBalance` | none | `cbor<value>` |
| `getUsedAddresses(paginate?)` | `cardano_getUsedAddresses` | `[Paginate?]` | `Address[]` |
| `getUnusedAddresses()` | `cardano_getUnusedAddresses` | none | `Address[]` |
| `getChangeAddress()` | `cardano_getChangeAddress` | none | `Address` |
| `getRewardAddresses()` | `cardano_getRewardAddresses` | none | `Address[]` |
| `getRewardAddresses()` | `cardano_getRewardAddress` | none | `Address` (singular variant, returns first) |
| `signTx(tx, partialSign?)` | `cardano_signTx` | `[cbor<tx>, bool?]` | `cbor<witness_set>` |
| `signData(addr, payload)` | `cardano_signData` | `[Address, Bytes]` | `DataSignature` |
| `submitTx(tx)` | `cardano_submitTx` | `[cbor<tx>]` | `hash32` |

**Wire format note**: Real dApps send params as **positional arrays** (e.g., `[tx, false]`), not named objects. The SDK must accept both formats.

### Events

Register emitters for both conventions used in the ecosystem:
- Standard WC: `chainChanged`, `accountsChanged`
- Cardano-prefixed: `cardano_onNetworkChange`, `cardano_onAccountChange`

### CIP-30 Error Types

| Error | Codes |
|-------|-------|
| `APIError` | InvalidRequest(-1), InternalError(-2), Refused(-3), AccountChange(-4) |
| `DataSignError` | ProofGeneration(1), AddressNotPK(2), UserDeclined(3) |
| `PaginateError` | maxSize: number |
| `TxSendError` | Refused(1), Failure(2) |
| `TxSignError` | ProofGeneration(1), UserDeclined(2) |

---

## Coding Conventions

- **Pure Dart**: All code written by us must be pure Dart (no Flutter imports). Flutter dependency only inherited transitively from `reown_walletkit`.
- **Null safety**: Required
- **Documentation comments**: All public APIs must have dartdoc comments
- **Naming**: Follow Dart naming conventions (lowerCamelCase for variables/methods, UpperCamelCase for classes)
- **Analysis**: Use `dart analyze` / recommended lints
- **Testing**: `dart test` (or `flutter test` if Flutter dependency forces it)

---

## Key References

- [CIP-30: Cardano dApp-Wallet Web Bridge](https://cips.cardano.org/cip/CIP-30)
- [CIP-34: Chain ID Registry](https://cips.cardano.org/cip/CIP-0034)
- [Reown WalletKit Flutter Docs](https://docs.reown.com/walletkit/flutter/installation)
- [Reown Flutter GitHub](https://github.com/reown-com/reown_flutter)
- [reown_walletkit on pub.dev](https://pub.dev/packages/reown_walletkit)
- [WalletConnect Cardano JS Reference (PR #1880)](https://github.com/WalletConnect/walletconnect-monorepo/pull/1880)
- [Catalyst Proposal Page](https://projectcatalyst.io/funds/14/cardano-open-developers/vespr-walletconnect-cardano-flutter-sdk-and-vespr-integration)
