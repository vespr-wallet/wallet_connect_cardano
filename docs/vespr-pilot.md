# VESPR WalletConnect beta pilot

The VESPR implementation lives in the separate, private wallet application
repository ([PR #500](https://github.com/vespr-wallet/nft-craze-wallet/pull/500)).
This SDK checkout contains pilot notes, not wallet
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

Proposal admission also binds the exact scanned pairing topic to that wallet
snapshot. Only requested supported capabilities are approved; unrelated or late
proposals cannot borrow permission. Teardown removes captured pairings as well
as sessions, including restored/orphan pairings. Pending approval cancellation
is effective even before the modal builder runs.

## Verified compatibility

| Component | Verified version/configuration |
|---|---|
| SDK Git revision | `6109a69837a252adfe91807e26149314e7a50a72` |
| Reown WalletKit / Core | 1.5.0 |
| Reown Sign | 1.4.0 |
| `flutter_secure_storage` | **9.2.4**, explicit application override |
| Flutter | 3.44.8 |

At the owner's request, the existing demo's public Reown project identifier is
embedded in the private app's feature-local configuration; no Dart define is
required. Its value is deliberately omitted from this public SDK repository and
evidence. Always resolve dependencies explicitly and inspect the graph when
testing an override; otherwise tests may use stale resolution.

The live pilot exposed three dependency integration requirements:

1. **Available `other` interfaces:** Reown's connectivity implementation treated
   `ConnectivityResult.other` as offline on the simulator. A feature-local
   `IConnectivity` implementation recognizes available interfaces and still
   establishes/observes the actual relay connection. Connect/disconnect operations
   are serialized and reconcile the latest notification after I/O; a delayed
   initial snapshot cannot overwrite newer availability.
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

## Historical end-to-end pilot

The full VESPR iOS application, not the standalone preview, completed the flows
below. The [historical record](../.sisyphus/evidence/vespr-beta-pilot.json) retains
its original uncommitted-at-validation flag; no exact working-tree hash was
captured then. Do not attribute every historical check to the later committed
checkpoint. That checkpoint's narrower rerun scope is listed separately below.

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

## Committed follow-up validation

Commit `579cc3afd464ca68b333ef97b20bdb0cd0667920` (tree
`0b919b5353453868aa9a08da5faf556789620fea`) was checked from a clean application
checkout. **79 focused tests**, iOS simulator build and Android debug APK build
pass. Full repository analysis exits 0 with **57 informational findings**, no
errors/warnings; it is not an issue-free analysis claim. Independent closing
architecture/correctness review accepted the narrow lifecycle/race fixes.

The installed build was then exercised over the relay: pairing and reads,
singular/plural reward-address equivalence, approved message signing with
independent COSE/Ed25519 verification, mainnet revocation during signing (no
signature; peer error 6000), mainnet scan restriction and subsequent preprod
recovery, read-only capability approval, and disconnect in both directions.
Both endpoints ultimately had zero sessions/pairings. Peer-initiated disconnect
can resolve before the asynchronous pairing-delete notification reaches it.
Transaction submission, preview and the full theme/scroll/storage-probe sweep
were not repeated at this checkpoint.

The [committed validation record](../.sisyphus/evidence/vespr-beta-committed.json)
contains exact command invocations/selectors, exit codes, result summaries,
source commit/tree, and SHA-256 references to logs in the operator-local evidence
bundle. Those bundle-relative paths are not hosted download links.

## Evidence boundaries and remaining coverage
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
- The five-minute proposal/decision deadline invalidates authority and pending
  UI, not underlying Reown pair/init I/O. Reown exposes no cancellation API;
  admission remains held until that work settles to avoid unsafe topic reuse.
  A permanently stalled transport requires app restart. This is a documented
  testnet-beta limitation, not a hard I/O timeout guarantee.
- The historical record contains the public transaction evidence. The committed
  follow-up separately preserves reproducible command/results and source-tree
  provenance without rewriting the earlier validation history. Local evidence
  collection is not a hosted Catalyst submission.

The fixture UI approval and standalone storage probe remain separate evidence.
Catalyst final report, close-out video, distribution and publication remain
separate work; this pilot validation does not mark Milestone 3 fully complete.
