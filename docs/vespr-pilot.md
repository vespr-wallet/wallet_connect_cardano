# VESPR WalletConnect beta pilot

The VESPR implementation lives in the separate wallet application repository on
`feat/walletconnect-beta`. This SDK checkout contains pilot notes, not wallet
signing keys or VESPR application source. The pilot is removable, testnet-only,
and not a public-release commitment.

## Integration boundary

Application code is contained in `lib/features/wallet_connect/`, with matching
tests and two standalone design-book/probe entrypoints. External changes are:

- One scanner hook before ordinary deeplink handling.
- One `SliverToBoxAdapter` before the token section, outside the collapsing header.
- Package/native dependency resolution and one scoped Android Maven repository.

The feature calls existing VESPR wallet-data, authentication, approval, signing
and transaction-submission services. No database migration, generated DI change,
signing-engine change or secure-storage upgrade is required. The feature README
lists exact removal points; shared wallet storage must never be cleared as a
removal shortcut.

Authorization is bound to one session topic, chain, selected wallet, network and
receive address. A transport wrapper preserves topic/chain identity through
asynchronous delegate calls. The service owns both network and wallet listeners;
either change revokes local authorization before relay teardown. Persisted Reown
sessions are discarded when the lazy transport initializes, not accepted as
persisted wallet permission. A restart requires fresh approval.

## Verified compatibility

| Component | Verified version/configuration |
|---|---|
| SDK Git revision | `6109a69837a252adfe91807e26149314e7a50a72` |
| Reown WalletKit / Core | 1.5.0 |
| Reown Sign | 1.4.0 |
| `flutter_secure_storage` | **9.2.4**, explicit application override |
| Flutter | 3.44.8 |

The existing demo Reown project is supplied through `REOWN_PROJECT_ID`, not
hardcoded. Always run explicit dependency resolution and inspect the resolved
graph when testing an override; otherwise tests may use stale resolution.

The live pilot exposed three dependency integration requirements:

1. **Available `other` interfaces:** Reown's connectivity implementation treated
   `ConnectivityResult.other` as offline on the simulator. A feature-local
   `IConnectivity` implementation recognizes available interfaces and still
   establishes/observes the actual relay connection.
2. **JSON null:** CIP-30 legitimately returns null for unavailable collateral or
   insufficient UTXOs. Reown rejected a Dart response with both result and error
   null. A small serializable-null adapter preserves the success path and emits
   explicit JSON `result: null`, retaining Reown validation, encryption and
   pending-request cleanup. This was verified over the real relay, not only mocks.
3. **Android native artifact:** Reown's payment dependency requires JitPack for
   `com.github.reown-com.yttrium`. The application adds a repository scoped to
   that group, rather than exposing every dependency to another repository.

These are app-local compatibility seams; this pilot did not fork Reown or change
the published SDK API. Native iOS secure-store write/update/reopen/delete and
host-options-key preservation were verified. Android runtime storage behavior
still needs device testing.

## Live validation

The full VESPR iOS application, not the standalone preview, completed:

- Real relay pairing, existing VESPR connection approval and proposal rejection.
- CIP-30 extensions, network, balance, address, UTXO and pagination reads.
- Explicit null collateral/insufficient-UTXO results and invalid-amount rejection.
- `signData` through the existing UI; independently verified COSE/Ed25519
  signature, unchanged unhashed payload/protected address, and public-key hash
  matching the requested payment address. User decline tested.
- `signTx` through the existing UI; independently verified Ed25519 witness and
  unchanged transaction-body hash. Full-signing requests explicitly refused.
- `submitTx` through the existing backend, confirmed independently on preprod:
  [9ba243134728b95a9660f2271622b7208ce65cba41dd7b516c7ff547141e4e19](https://preprod.cardanoscan.io/transaction/9ba243134728b95a9660f2271622b7208ce65cba41dd7b516c7ff547141e4e19).
  Koios reported block **5173761** and fee **500000 lovelace**. This self-transfer
  retained 49.5 test ADA and all 1,000 test tokens; no mainnet funds were used.
- Wallet- and dApp-initiated disconnect, and removal of restored transport sessions.
  Open details reflect revocation rather than retaining a stale Connected badge;
  failed relay teardown still permits retry.
- Active preprod-to-preview revocation, then fresh `cip34:0-2` approval and reads
  showing network 0, zero balance and no UTXOs.
- Switching to mainnet during an unapproved signing request: local binding and
  transport session removed, prompt closed, peer disconnected, no signature
  returned. A valid mainnet `wc:` scan displayed the required restriction without
  adding a pairing. The same URI subsequently paired on preprod.
- Malformed WalletConnect input rejected without pairing; ordinary address QR
  still opened the existing transaction wizard and was cancelled without sending.
- Actual light/dark home/details UI and scrolling placement. The connected row
  moved from y=448 to y=276 while the wallet title stayed pinned at y=85.

## Evidence boundaries and remaining coverage

- **47 feature tests pass**, scoped analysis is clean, iOS simulator and Android
  debug APK builds pass. Architecture reassessment: **ACCEPTED**; prior listener
  ownership finding resolved.
- The simulator has no physical camera input. Decoded QR data was injected into
  the existing camera-controller stream through a temporary debug extension,
  exercising the real scanner callback, feature gate, relay and wallet UI. The
  extension is not shipped. Physical camera acquisition remains unverified.
- The localhost dApp's metadata origin was configured in browser memory. Preview
  checks used Sign Client directly with `cip34:0-2`; the stock demo UI defaults
  to preprod. No demo source/configuration secret was committed.
- Wallet/account substitution, stale topic/chain, lock refusal, late responses
  and failed-disconnect retry have automated coverage. A second native wallet,
  enrolled-biometric/device-lock flow and Android runtime were not exercised.
- Pilot limitations: one dApp, software-wallet data signing, partial transaction
  witnessing only, and Shelley testnet transaction outputs. Unsupported cases
  fail explicitly; no silent promise of full signing or hardware equivalence.
- A sanitized [validation record](../.sisyphus/evidence/vespr-beta-pilot.json)
  preserves the commands/results boundary and public transaction evidence.
- Temporary local evidence includes `vespr-wc-lifecycle.json`,
  `vespr-wc-null-regression.json`, `vespr-wc-chain-confirmation.json` and integrated
  screenshots under `/tmp/`. These are not durable hosted Catalyst submissions.

The fixture UI approval and standalone storage probe remain separate evidence.
Catalyst final report, close-out video, distribution and publication remain
separate work; this pilot validation does not mark Milestone 3 fully complete.
