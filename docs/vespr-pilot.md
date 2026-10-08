# VESPR WalletConnect pilot

VESPR Wallet integrated this SDK in a testnet beta build as the pilot for
Catalyst Fund 14 project #1400124. VESPR is closed source; this page
summarises what was tested and what other integrators can learn from it.

## Scope

- Networks: **preprod and preview only**. Scanning a WalletConnect code on
  mainnet shows a "test networks only" message, and switching the wallet to
  mainnet disconnects any active dApp session.
- dApp: the example web dApp in [`demo/dapp-web`](../demo/dapp-web) on
  preprod, over the public WalletConnect relay. The demo is preprod-only, so
  preview was exercised with a WalletConnect Sign Client script instead.
- Wallet: VESPR's existing approval screens, signing and transaction services.
  The SDK only carries the messages.

## Tested

- Pairing by QR scan, connection approval and rejection.
- All read methods: network ID, extensions, balance, UTXOs (with pagination),
  used/unused/change/reward addresses and collateral.
- `signData` through VESPR's normal approval screens, including user decline.
  Signatures were verified independently.
- `signTx` through the same screens. VESPR returns its own witnesses and, like
  its in-app connector, does not enforce `partialSign`.
- `submitTx` on preprod:
  [9ba24313…4e19](https://preprod.cardanoscan.io/transaction/9ba243134728b95a9660f2271622b7208ce65cba41dd7b516c7ff547141e4e19).
- Disconnect from either side.
- Session revoked when the user switches network or wallet; a fresh approval is
  required afterwards.

## Notes for integrators

- **Null results.** CIP-30 `getUtxos` returns `null` when the amount cannot be
  met. Reown rejects a response with neither a result nor an error, so the SDK
  sends a `null` delegate result as an explicit JSON `null`; just return
  `null`.
- **Bind sessions to what the user approved.** Tie each session to the wallet
  and network it was approved for, and disconnect when either changes.
- **Android.** A Reown native dependency (`com.github.reown-com.yttrium`) is
  hosted on JitPack. Add that repository, ideally scoped to that group.
- **Dependency alignment.** If your app pins `flutter_secure_storage` 9.x, a
  `dependency_overrides` entry to 9.2.4 worked with Reown WalletKit 1.5.0.
- **Simulators.** Reown may treat the `other` connectivity type as offline on
  iOS simulators. Test on a device or provide your own connectivity check.

## Not yet covered

Physical camera scanning, Android runtime testing, hardware wallets and
biometric flows. These come before any mainnet rollout.
