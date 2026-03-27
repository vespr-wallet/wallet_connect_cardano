# Milestone 1: Core SDK Development

## TL;DR

> **Quick Summary**: Build the core `wallet_connect_cardano` SDK — a communication bridge that wraps `reown_walletkit` to route CIP-30 JSON-RPC requests between desktop dApps and Cardano mobile wallets over WalletConnect v2.
> 
> **Deliverables**:
> - AGENTS.md project knowledge base
> - Dart package scaffolding with `reown_walletkit` dependency
> - Callback interface (abstract class) for wallet app integration
> - CIP-30 JSON-RPC method routing (12 handlers)
> - Session lifecycle management (pair, approve, reject, disconnect)
> - Cardano namespace configuration (`cip34:*`)
> - CIP-30 error types
> - Basic documentation (installation, setup, core API usage)
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 3 waves
> **Critical Path**: Scaffolding → Namespace Spike → Callback Interface → Method Handlers → Session Management → Docs

---

## Context

### Original Request
Catalyst Fund 14 proposal #1400124. Deliver a functional WalletConnect v2 client for Flutter with complete session management and CIP-30 compatibility. This is the core development milestone.

### Key Architectural Decisions
1. **Communication bridge only** — SDK routes requests to wallet app callbacks, never signs/queries itself
2. **Built on `reown_walletkit` v1.4.0** — no fork, purely additive Cardano namespace registration
3. **Pure Dart code** — Flutter dependency only through `reown_walletkit` transitive dep
4. **Params format**: Accept both positional arrays AND named objects
5. **Events**: Register both standard WC and Cardano-prefixed conventions
6. **12 handlers**: 11 CIP-30 methods + `cardano_getRewardAddress` (singular variant)

### Metis Review Findings (addressed)
- **Namespace spike required** — Task 2 validates `cip34` acceptance before building anything else
- **Params are positional arrays** — Accounted for in handler implementation tasks
- **Dual event conventions** — Both WC standard and Cardano-prefixed events registered
- **Account format** — Wallet app provides addresses during session approval

---

## Work Objectives

### Core Objective
Deliver a functional Dart SDK that enables any Cardano wallet app to accept WalletConnect v2 connections from dApps, routing all CIP-30 method calls to wallet-app-provided callbacks.

### Concrete Deliverables
- `AGENTS.md` at repo root
- `pubspec.yaml` with correct dependencies
- `lib/` with SDK source code
- Callback interface abstract class
- 12 JSON-RPC method handlers
- Session lifecycle wrapper
- CIP-30 error types and data models
- `README.md` with installation and basic usage

### Definition of Done
- [ ] `dart analyze` passes with no errors
- [ ] A test harness can instantiate the SDK, simulate a session proposal, and verify handlers are invoked
- [ ] All 12 CIP-30 methods are routed to callbacks
- [ ] Session approve/reject/disconnect work via reown_walletkit

### Must Have
- All CIP-30 Full API methods mapped to JSON-RPC handlers
- Callback interface that wallet apps implement
- Cardano namespace (`cip34`) session handling
- CIP-30 error types (APIError, TxSignError, DataSignError, TxSendError, PaginateError)
- Basic README with installation and initialization example

### Must NOT Have (Guardrails)
- No private key handling or cryptographic operations
- No blockchain/node interaction
- No UTXO management or balance tracking
- No transaction construction or submission logic
- No UI components
- No Flutter-specific imports in our code (only transitive through reown_walletkit)
- No hardcoded WalletConnect project IDs
- No over-abstraction — keep it thin and direct

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: NO (fresh repo)
- **Automated tests**: Deferred to Milestone 2 (per Catalyst milestone structure)
- **Framework**: Will be set up in M2

### QA Policy
Every task includes agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/`.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — all independent):
+-- Task 1: Create AGENTS.md from draft [quick]
+-- Task 2: Dart package scaffolding + reown_walletkit dep [quick]
+-- Task 3: Namespace spike — verify cip34 acceptance [deep]

Wave 2 (Core — after Wave 1):
+-- Task 4: CIP-30 error types and data models [quick]
+-- Task 5: Callback interface (abstract class) [deep]

Wave 3 (Integration — after Wave 2):
+-- Task 6: CIP-30 method handlers (12 handlers) [deep]
+-- Task 7: Session lifecycle management [deep]

Wave 4 (Documentation — after Wave 3):
+-- Task 8: Basic README and docs [quick]

Critical Path: T2 → T3 → T5 → T6 → T7 → T8
Max Concurrent: 3 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | — |
| 2 | — | 3, 4, 5 |
| 3 | 2 | 5, 6, 7 |
| 4 | 2 | 5, 6 |
| 5 | 3, 4 | 6, 7 |
| 6 | 5 | 7, 8 |
| 7 | 5, 6 | 8 |
| 8 | 6, 7 | — |

---

## TODOs

- [ ] 1. Create AGENTS.md from draft content

  **What to do**:
  - Copy content from `.sisyphus/drafts/agents-md-content.md` to `AGENTS.md` at repo root
  - Verify all sections are present and formatted correctly
  - This is the project knowledge base for all agents working on this repo

  **Must NOT do**:
  - Do not modify the content beyond formatting fixes
  - Do not add implementation details not yet decided

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - `.sisyphus/drafts/agents-md-content.md` — Complete AGENTS.md content ready to copy

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: AGENTS.md exists with correct content
    Tool: Bash
    Steps:
      1. Run `cat AGENTS.md | head -5` — verify file exists and starts with "# AGENTS.md"
      2. Run `grep -c "## Milestones" AGENTS.md` — verify milestones section exists (expect: 1)
      3. Run `grep -c "cardano_signTx" AGENTS.md` — verify CIP-30 methods documented (expect: >= 1)
    Expected Result: File exists with all sections from draft
    Evidence: .sisyphus/evidence/task-1-agents-md.txt
  ```

  **Commit**: YES
  - Message: `docs: add AGENTS.md project knowledge base`
  - Files: `AGENTS.md`

---

- [ ] 2. Dart package scaffolding with reown_walletkit dependency

  **What to do**:
  - Create `pubspec.yaml` with package name `wallet_connect_cardano`, MIT license
  - Add dependency on `reown_walletkit: ^1.4.0`
  - Create standard Dart package directory structure: `lib/`, `lib/src/`, `lib/wallet_connect_cardano.dart` (barrel export)
  - Create `analysis_options.yaml` with recommended Dart lints
  - Create `.gitignore` for Dart projects
  - Create `CHANGELOG.md` with initial entry
  - Create `LICENSE` file (MIT)
  - Run `flutter pub get` to resolve dependencies and generate lockfile
  - Verify `dart analyze` passes on the empty package

  **Must NOT do**:
  - Do not add Flutter-specific code in our files
  - Do not pin exact versions of dependencies (use caret `^` syntax)
  - Do not add unnecessary dependencies

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: Tasks 3, 4, 5
  - **Blocked By**: None

  **References**:
  - [reown_walletkit on pub.dev](https://pub.dev/packages/reown_walletkit) — dependency to add, check latest version
  - [Dart package layout conventions](https://dart.dev/tools/pub/package-layout) — follow standard structure
  - [pub.dev publishing requirements](https://dart.dev/tools/pub/publishing) — structure package for eventual publishing

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Package resolves dependencies successfully
    Tool: Bash
    Steps:
      1. Run `flutter pub get` — should complete without errors
      2. Run `dart analyze` — should produce no errors
      3. Check `pubspec.yaml` contains `reown_walletkit: ^1.4.0`
      4. Check `lib/wallet_connect_cardano.dart` exists (barrel file)
    Expected Result: Clean package with resolved deps and passing analysis
    Evidence: .sisyphus/evidence/task-2-scaffolding.txt

  Scenario: Package structure follows Dart conventions
    Tool: Bash
    Steps:
      1. Verify `lib/src/` directory exists
      2. Verify `analysis_options.yaml` exists
      3. Verify `LICENSE` contains "MIT"
      4. Verify `CHANGELOG.md` exists
    Expected Result: All conventional files present
    Evidence: .sisyphus/evidence/task-2-structure.txt
  ```

  **Commit**: YES
  - Message: `chore: scaffold Dart package with reown_walletkit dependency`
  - Files: `pubspec.yaml`, `lib/`, `analysis_options.yaml`, `.gitignore`, `LICENSE`, `CHANGELOG.md`

---

- [ ] 3. Namespace spike — verify cip34 acceptance by reown_walletkit

  **What to do**:
  - This is a **go/no-go validation** task. Before building anything, verify that `reown_walletkit` accepts the `cip34` namespace.
  - **Two-pronged approach** (source code inspection FIRST, runtime spike SECOND):
    - **Approach A (primary)**: Inspect the `reown_flutter` source code (clone or browse on GitHub) to determine if namespace/chainId validation exists. Look at `registerRequestHandler`, `registerAccount`, and `approveSession` implementations. If the code just stores the string without validation, `cip34` is accepted by definition. Document the relevant source file and line.
    - **Approach B (confirmation)**: If source inspection is inconclusive, create a minimal spike script:
      1. Instantiates `ReownWalletKit` — requires a WalletConnect project ID via `WC_PROJECT_ID` environment variable. If `WC_PROJECT_ID` is not set, the spike must fail fast with: `"ERROR: Set WC_PROJECT_ID env var (get one from https://cloud.reown.com)"` and exit code 1.
      2. Attempts `registerRequestHandler(chainId: 'cip34:1-764824073', method: 'cardano_getNetworkId', handler: ...)`
      3. Attempts `registerAccount(chainId: 'cip34:1-764824073', accountAddress: 'cip34:1-764824073:test_addr')`
      4. Prints "PASS: cip34 namespace accepted" or captures exception details.
  - Document the results: does reown_walletkit accept arbitrary namespace strings, or does it validate against a whitelist?
  - If `cip34` is REJECTED: document the error, investigate the source code, and determine if a fork or PR to reown_flutter is needed. Flag this as a blocker.
  - If `cip34` is ACCEPTED: proceed — this confirms the no-fork approach.

  **Must NOT do**:
  - Do not build the full SDK yet — this is validation only
  - Do not skip this step — it's the go/no-go gate

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
    - Reason: Requires investigation, reading reown source code, potentially debugging

  **Parallelization**:
  - **Can Run In Parallel**: YES (starts in Wave 1, but depends on Task 2 for pubspec)
  - **Parallel Group**: Wave 1 (after Task 2 completes pub get)
  - **Blocks**: Tasks 5, 6, 7
  - **Blocked By**: Task 2

  **References**:
  - [reown_walletkit pub.dev docs](https://pub.dev/packages/reown_walletkit) — `registerRequestHandler` API
  - [Reown Flutter GitHub](https://github.com/reown-com/reown_flutter) — source code to inspect if namespace validation exists
  - `packages/reown_sign/lib/i_sign_wallet.dart` in reown_flutter repo — wallet interface definition
  - [WalletConnect Cardano JS PR #1880](https://github.com/WalletConnect/walletconnect-monorepo/pull/1880) — reference for how JS SDK handles cip34

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: cip34 namespace accepted — source code inspection
    Tool: Bash
    Steps:
      1. Clone or browse https://github.com/reown-com/reown_flutter
      2. Run `grep -rn "chainId" packages/reown_sign/lib/src/` to find validation logic
      3. Inspect `registerRequestHandler` implementation — check if chainId is validated against a whitelist or stored as-is
      4. Save relevant source file paths and line numbers to evidence
    Expected Result: Source shows chainId is stored/used as opaque string with no namespace whitelist
    Failure Indicators: Source contains a Set/List of allowed namespaces that doesn't include 'cip34'
    Evidence: .sisyphus/evidence/task-3-namespace-spike.txt

  Scenario: cip34 namespace accepted — runtime confirmation (if Approach A inconclusive)
    Tool: Bash
    Preconditions: WC_PROJECT_ID env var must be set
    Steps:
      1. Run `WC_PROJECT_ID=$WC_PROJECT_ID dart run test/spike_cip34.dart` (or equivalent)
      2. If WC_PROJECT_ID not set: verify script exits with code 1 and prints "ERROR: Set WC_PROJECT_ID"
      3. If set: verify output contains "PASS: cip34 namespace accepted"
    Expected Result: Script prints PASS or source inspection already confirmed acceptance
    Failure Indicators: Exception mentioning invalid namespace, or script prints FAIL with error details
    Evidence: .sisyphus/evidence/task-3-namespace-spike.txt

  Scenario: If cip34 rejected — document blocker
    Tool: Bash
    Steps:
      1. Capture the full error message/source code evidence
      2. Run `grep -rn "eip155\|solana\|polkadot\|namespace" packages/reown_sign/lib/src/` to find the whitelist
      3. Document: which file, which line, what the whitelist contains, and recommend fork vs PR vs workaround
    Expected Result: Actionable blocker report with file:line references and recommended resolution
    Evidence: .sisyphus/evidence/task-3-namespace-blocker.txt
  ```

  **Commit**: YES
  - Message: `spike: validate cip34 namespace acceptance by reown_walletkit`
  - Files: test script, evidence

---

- [ ] 4. CIP-30 error types and data models

  **What to do**:
  - Create Dart classes/enums for all CIP-30 error types:
    - `CardanoApiError` with codes: `invalidRequest` (-1), `internalError` (-2), `refused` (-3), `accountChange` (-4)
    - `CardanoDataSignError` with codes: `proofGeneration` (1), `addressNotPK` (2), `userDeclined` (3)
    - `CardanoPaginateError` with `maxSize` field
    - `CardanoTxSendError` with codes: `refused` (1), `failure` (2)
    - `CardanoTxSignError` with codes: `proofGeneration` (1), `userDeclined` (2)
  - Create data model classes:
    - `CardanoPaginate` with `page` and `limit` fields
    - `CardanoExtension` with `cip` field
    - `CardanoDataSignature` with `signature` and `key` fields (both hex strings)
  - All classes should have `toJson()` and `fromJson()` for JSON-RPC serialization
  - All classes should have proper dartdoc comments
  - Place in `lib/src/models/`

  **Must NOT do**:
  - Do not create CBOR serialization — hex strings pass through as-is
  - Do not create Address or Transaction types — those are opaque hex strings to us

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 5)
  - **Blocks**: Tasks 5, 6
  - **Blocked By**: Task 2

  **References**:
  - [CIP-30 Error Types](https://cips.cardano.org/cip/CIP-30#error-types) — exact codes and field names
  - [CIP-30 Data Types](https://cips.cardano.org/cip/CIP-30#data-types) — Paginate, Extension, DataSignature
  - AGENTS.md (once created) — CIP-30 Error Types table

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: All error types compile and pass analysis
    Tool: Bash
    Steps:
      1. Run `dart analyze lib/src/models/` — expect exit code 0, no errors in output
      2. Run `grep -rl "class Cardano" lib/src/models/` — expect 8 files (5 error types + 3 data models)
      3. Run `grep -c "invalidRequest\|internalError\|refused\|accountChange" lib/src/models/cardano_api_error.dart` — expect 4 (one per code)
      4. Run `grep -c "toJson\|fromJson" lib/src/models/cardano_api_error.dart` — expect >= 2
    Expected Result: All 8 model classes exist, compile, have correct codes and serialization methods
    Failure Indicators: dart analyze reports errors, grep counts don't match expected
    Evidence: .sisyphus/evidence/task-4-models.txt
  ```

  **Commit**: YES
  - Message: `feat: add CIP-30 error types and data models`
  - Files: `lib/src/models/`

---

- [ ] 5. Callback interface (abstract class) for wallet app integration

  **What to do**:
  - Create an abstract Dart class (e.g., `CardanoWalletDelegate` or similar) that wallet apps implement
  - The interface defines one method per CIP-30 operation, accepting deserialized params and returning the response:
    - `Future<int> getNetworkId()`
    - `Future<List<String>?> getUtxos({String? amount, CardanoPaginate? paginate})` — returns hex-encoded CBOR UTXOs or null
    - `Future<String> getBalance()` — returns hex-encoded CBOR value
    - `Future<List<String>> getUsedAddresses({CardanoPaginate? paginate})` — hex addresses
    - `Future<List<String>> getUnusedAddresses()` — hex addresses
    - `Future<String> getChangeAddress()` — hex address
    - `Future<List<String>> getRewardAddresses()` — hex addresses
    - `Future<String> signTx(String tx, {bool partialSign = false})` — tx is hex CBOR, returns hex CBOR witness set
    - `Future<CardanoDataSignature> signData(String address, String payload)` — address is hex, payload is hex
    - `Future<String> submitTx(String tx)` — tx is hex CBOR, returns tx hash hex
    - `Future<List<CardanoExtension>> getExtensions()`
  - All params and returns use hex-encoded strings (the SDK does NOT parse CBOR, it passes through)
  - Add thorough dartdoc comments explaining what each method should do and what format the wallet app should return
  - Place in `lib/src/`

  **Must NOT do**:
  - Do not make the interface too granular (one class, not twelve)
  - Do not add methods beyond CIP-30 spec
  - Do not handle CBOR parsing — the wallet app and dApp handle that

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
    - Reason: Core API design decision, needs careful thought on naming and ergonomics

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 4)
  - **Blocks**: Tasks 6, 7
  - **Blocked By**: Tasks 3, 4

  **References**:
  - [CIP-30 Full API](https://cips.cardano.org/cip/CIP-30#full-api) — method signatures and return types
  - AGENTS.md CIP-30 Methods table — JSON-RPC mapping and param formats
  - [reown_walletkit registerRequestHandler](https://pub.dev/packages/reown_walletkit) — handler signature `(String topic, dynamic params)`
  - Task 4 models — error types and data models used in the interface

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Interface compiles and covers all CIP-30 methods
    Tool: Bash
    Steps:
      1. Run `dart analyze lib/src/` — expect exit code 0
      2. Run `grep -c "Future<" lib/src/cardano_wallet_delegate.dart` — expect exactly 11 (one per CIP-30 method)
      3. Run `grep "getNetworkId\|getUtxos\|getBalance\|getUsedAddresses\|getUnusedAddresses\|getChangeAddress\|getRewardAddresses\|signTx\|signData\|submitTx\|getExtensions" lib/src/cardano_wallet_delegate.dart | wc -l` — expect 11
      4. Run `grep -c "///" lib/src/cardano_wallet_delegate.dart` — expect >= 11 (at least one dartdoc line per method)
    Expected Result: Abstract class with exactly 11 Future-returning methods, all with dartdoc
    Failure Indicators: Method count != 11, missing dartdoc, analyze errors
    Evidence: .sisyphus/evidence/task-5-interface.txt
  ```

  **Commit**: YES
  - Message: `feat: define CardanoWalletDelegate callback interface`
  - Files: `lib/src/cardano_wallet_delegate.dart` (or similar)

---

- [ ] 6. CIP-30 JSON-RPC method handlers (12 handlers)

  **What to do**:
  - Create the handler registration logic that connects `reown_walletkit.registerRequestHandler()` with the `CardanoWalletDelegate` callbacks
  - For each CIP-30 method, create a handler that:
    1. Receives `(String topic, dynamic params)` from reown_walletkit
    2. Parses params — support BOTH positional array format (`params[0]`, `params[1]`) AND named object format (`params['tx']`) for compatibility
    3. Calls the corresponding method on the `CardanoWalletDelegate`
    4. Returns the result (which reown_walletkit will serialize as JSON-RPC response)
    5. Catches delegate exceptions and maps them to CIP-30 error types (JSON-RPC error responses)
  - Register handlers for all 12 methods:
    - `cardano_getExtensions`, `cardano_getNetworkId`, `cardano_getUtxos`, `cardano_getBalance`
    - `cardano_getUsedAddresses`, `cardano_getUnusedAddresses`, `cardano_getChangeAddress`
    - `cardano_getRewardAddresses`, `cardano_getRewardAddress` (singular variant — delegates to plural, returns first)
    - `cardano_signTx`, `cardano_signData`, `cardano_submitTx`
  - Handler registration should work for any chain ID matching `cip34:*` pattern (mainnet, preprod, preview)
  - Place handler logic in `lib/src/`

  **Must NOT do**:
  - Do not parse or validate CBOR content — pass hex strings through
  - Do not handle the signing logic — that's the delegate's job
  - Do not hardcode a single chain ID — support configurable networks

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
    - Reason: Core routing logic, needs careful error handling and param parsing

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (with Task 7)
  - **Blocks**: Tasks 7, 8
  - **Blocked By**: Task 5

  **References**:
  - [CIP-30 Full API](https://cips.cardano.org/cip/CIP-30#full-api) — method params and return types
  - [reown_walletkit registerRequestHandler](https://pub.dev/packages/reown_walletkit) — handler signature
  - [WalletConnect Cardano JS PR #1880](https://github.com/WalletConnect/walletconnect-monorepo/pull/1880) — reference for method names and param formats
  - AGENTS.md — CIP-30 Methods table with exact JSON-RPC names and param arrays
  - Task 5 — CardanoWalletDelegate interface to call
  - Task 4 — Error types to use in error responses

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: All 12 handlers register without error
    Tool: Bash
    Steps:
      1. Run `dart analyze` — no errors
      2. Verify 12 handler registrations in the source code (grep for registerRequestHandler)
      3. Verify both array and object param parsing exists (grep for params[0] or equivalent)
    Expected Result: 12 handlers registered, dual param format supported
    Evidence: .sisyphus/evidence/task-6-handlers.txt

  Scenario: Error mapping works correctly
    Tool: Bash
    Steps:
      1. Verify handler catch blocks exist for delegate exceptions
      2. Verify CIP-30 error codes are used in JSON-RPC error responses
    Expected Result: Delegate errors correctly mapped to CIP-30 error types
    Evidence: .sisyphus/evidence/task-6-error-mapping.txt
  ```

  **Commit**: YES
  - Message: `feat: implement CIP-30 JSON-RPC method handlers with dual param format`
  - Files: `lib/src/` handler files

---

- [ ] 7. Session lifecycle management

  **What to do**:
  - Create the main SDK entry point class (e.g., `WalletConnectCardano` or similar) that:
    1. Wraps `ReownWalletKit` initialization
    2. Accepts a `CardanoWalletDelegate` instance from the wallet app
    3. Provides a high-level API for session management:
       - `pair(String uri)` — pair with a dApp via WalletConnect URI (from QR code)
       - Session proposal handling — listen for proposals, auto-configure Cardano namespace
       - `approveSession(...)` — approve with `cip34` namespace, methods, and events
       - `rejectSession(...)` — reject with reason
       - `disconnectSession(...)` — disconnect from a session
       - `getActiveSessions()` — list active sessions
    4. On initialization, registers all 12 CIP-30 handlers (from Task 6) for the configured chain ID(s)
    5. Registers event emitters for both conventions:
       - Standard WC: `chainChanged`, `accountsChanged`
       - Cardano-prefixed: `cardano_onNetworkChange`, `cardano_onAccountChange`
    6. Provides methods to emit events (e.g., when wallet changes account)
  - The class should accept configuration:
    - WalletConnect project ID
    - Wallet metadata (name, description, url, icon)
    - Chain IDs to support (default: mainnet `cip34:1-764824073`)
    - The CardanoWalletDelegate
  - Update `lib/wallet_connect_cardano.dart` barrel to export all public APIs

  **Must NOT do**:
  - Do not manage WalletConnect project ID registration — wallet app provides it
  - Do not create UI for session approval — wallet app handles that
  - Do not auto-approve sessions — always surface to wallet app for user consent

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
    - Reason: Central orchestration class, needs careful API design

  **Parallelization**:
  - **Can Run In Parallel**: YES (in Wave 3 with Task 6, but practically sequential)
  - **Parallel Group**: Wave 3
  - **Blocks**: Task 8
  - **Blocked By**: Tasks 5, 6

  **References**:
  - [reown_walletkit README](https://pub.dev/packages/reown_walletkit) — initialization, pairing, session approval patterns
  - [Reown WalletKit Flutter Docs](https://docs.reown.com/walletkit/flutter/installation) — official docs
  - AGENTS.md — Architecture section, Cardano namespace table, Events section
  - Task 5 — CardanoWalletDelegate interface
  - Task 6 — Handler registration logic

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: SDK entry point compiles and exports correctly
    Tool: Bash
    Steps:
      1. Run `dart analyze` — no errors
      2. Verify the main class exists with pair/approve/reject/disconnect methods
      3. Verify barrel file exports all public APIs
      4. Verify both event conventions are registered (grep for chainChanged and cardano_onNetworkChange)
    Expected Result: Clean entry point class with full session lifecycle API
    Evidence: .sisyphus/evidence/task-7-session.txt

  Scenario: Configuration accepts required parameters
    Tool: Bash
    Steps:
      1. Verify constructor/factory accepts: projectId, metadata, chainIds, delegate
      2. Verify default chain ID is cip34:1-764824073
    Expected Result: Configurable entry point with sensible defaults
    Evidence: .sisyphus/evidence/task-7-config.txt
  ```

  **Commit**: YES
  - Message: `feat: add session lifecycle management and SDK entry point`
  - Files: `lib/src/`, `lib/wallet_connect_cardano.dart`

---

- [ ] 8. Basic README and documentation

  **What to do**:
  - Write `README.md` covering:
    1. **What it does** — one paragraph explaining it's a communication bridge for CIP-30 over WalletConnect
    2. **Installation** — pubspec.yaml dependency, flutter pub get
    3. **Quick Start** — minimal code to initialize SDK, implement delegate, and pair with a dApp
    4. **CardanoWalletDelegate** — explanation of the callback interface and what each method should return
    5. **Session Management** — how to handle proposals, approve/reject, disconnect
    6. **CIP-30 Methods** — table of all supported methods
    7. **Error Handling** — CIP-30 error types
    8. **Configuration** — chain IDs, metadata, project ID
  - Add inline dartdoc comments to all public APIs if not already present
  - Ensure README is accurate to the actual implemented API (review source code)

  **Must NOT do**:
  - Do not over-document — keep it concise and practical
  - Do not include VESPR-specific details
  - Do not document internal implementation details

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 (sequential, after all code)
  - **Blocks**: None
  - **Blocked By**: Tasks 6, 7

  **References**:
  - All previous tasks — review actual implemented APIs
  - [reown_walletkit README](https://pub.dev/packages/reown_walletkit) — style reference for SDK documentation
  - AGENTS.md — CIP-30 methods table, architecture diagram

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: README covers all required sections
    Tool: Bash
    Steps:
      1. Verify README.md exists and is non-empty
      2. Verify sections: Installation, Quick Start, CardanoWalletDelegate, Session Management, CIP-30 Methods
      3. Verify code examples are present (grep for triple-backtick dart blocks)
    Expected Result: Complete README with installation, usage, and API reference
    Evidence: .sisyphus/evidence/task-8-readme.txt
  ```

  **Commit**: YES
  - Message: `docs: add README with installation, usage, and API reference`
  - Files: `README.md`

---

## Final Verification Wave

> After ALL implementation tasks, run these in parallel. ALL must approve.

- [ ] F1. **Plan Compliance Audit**
  Read this plan end-to-end. For each Must Have: verify implementation exists. For each Must NOT Have: search codebase for forbidden patterns (private key handling, Flutter imports in our code, hardcoded project IDs). Check evidence files exist. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review**
  Run `dart analyze`. Review all files for: unused imports, missing dartdoc on public APIs, inconsistent naming, empty catch blocks. Check that all code in lib/src/ is pure Dart (no `import 'package:flutter/`).
  Output: `Analyze [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **API Completeness Check**
  Verify all 12 CIP-30 methods have registered handlers. Verify CardanoWalletDelegate has all 11 methods. Verify all 5 error types exist. Verify barrel file exports everything. Verify both event conventions registered.
  Output: `Handlers [12/12] | Delegate [11/11] | Errors [5/5] | Events [4/4] | VERDICT`

---

## Commit Strategy

| Task | Commit Message | Key Files |
|------|---------------|-----------|
| 1 | `docs: add AGENTS.md project knowledge base` | `AGENTS.md` |
| 2 | `chore: scaffold Dart package with reown_walletkit dependency` | `pubspec.yaml`, `lib/`, config files |
| 3 | `spike: validate cip34 namespace acceptance by reown_walletkit` | test script, evidence |
| 4 | `feat: add CIP-30 error types and data models` | `lib/src/models/` |
| 5 | `feat: define CardanoWalletDelegate callback interface` | `lib/src/` |
| 6 | `feat: implement CIP-30 JSON-RPC method handlers` | `lib/src/` |
| 7 | `feat: add session lifecycle management and SDK entry point` | `lib/src/`, `lib/wallet_connect_cardano.dart` |
| 8 | `docs: add README with installation, usage, and API reference` | `README.md` |

---

## Success Criteria

### Verification Commands
```bash
dart analyze              # Expected: no errors
flutter pub get           # Expected: resolves successfully
grep -r "cardano_signTx" lib/  # Expected: handler exists
```

### Final Checklist
- [ ] All 12 CIP-30 methods have JSON-RPC handlers
- [ ] CardanoWalletDelegate interface defines all 11 callback methods
- [ ] All 5 CIP-30 error types implemented
- [ ] Session lifecycle (pair, approve, reject, disconnect) works
- [ ] Both event conventions registered
- [ ] `dart analyze` passes
- [ ] README covers installation, quick start, and API reference
- [ ] No Flutter imports in our own code
- [ ] No private key handling anywhere
- [ ] AGENTS.md present at repo root
