# WC Cardano Example Wallet

Flutter demo wallet for Milestone 1 evidence. Uses [`wallet_connect_cardano`](../) with real preprod signing via `cardano_flutter_sdk`.

## Run

```bash
flutter run
```

A default Reown project ID is baked in; override with `--dart-define=REOWN_PROJECT_ID=...` if needed.

Pair with the web dApp in [`demo/dapp-web/`](../demo/dapp-web/). See [`docs/milestone-1-demo.md`](../docs/milestone-1-demo.md).

## Optional defines

| Define | Purpose |
|--------|---------|
| `REOWN_PROJECT_ID` | Required — Reown Cloud project ID |
| `DEMO_MNEMONIC` | Override demo wallet mnemonic |

On-chain queries use [Koios preprod](https://preprod.koios.rest/) (no API key).

## Android

`reown_walletkit` pulls `yttrium-wcpay` from JitPack — already configured in
`android/build.gradle.kts`. If you regenerate the Android folder, keep:

```kotlin
maven { url = uri("https://jitpack.io") }
```
