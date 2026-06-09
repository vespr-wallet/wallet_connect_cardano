# Milestone 1 Demo Runbook

End-to-end proof for [Catalyst Milestone 1](https://milestones.projectcatalyst.io/projects/1400124/milestones/1): a **web test dApp** connects to the **Flutter example wallet** over WalletConnect v2 (`cip34:0-1` preprod).

## Components

| Path | Role |
|------|------|
| [`example/`](../example/) | Flutter mobile wallet using `wallet_connect_cardano` + real signing via `cardano_flutter_sdk` |
| [`demo/dapp-web/`](../demo/dapp-web/) | Browser test dApp using `@walletconnect/sign-client` |
| [`docs/poa-milestone-1-draft.md`](poa-milestone-1-draft.md) | PoA submission template |

## Prerequisites

1. **Reown project ID** — create at [cloud.reown.com](https://cloud.reown.com)
2. **Flutter SDK** (3.x) with iOS or Android toolchain
3. **Node.js 20+** for the web dApp
4. **Preprod faucet** — fund the demo wallet (see below)

No blockchain API key is required. UTXO/balance queries use the free [Koios preprod API](https://preprod.koios.rest/).

## Demo wallet

Default mnemonic is the `chief fiber ...` test vector from `cardano_flutter_sdk` (override with `--dart-define=DEMO_MNEMONIC=...`).

**Default preprod payment address** (fund this for `signTx`):

```
addr_test1qrjn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qhkdw7e
```

Fund via the [Cardano preprod faucet](https://docs.cardano.org/cardano-testnet/tools/faucet).

## Setup

### 1. Web dApp

```bash
cd demo/dapp-web
cp .env.example .env
# Edit .env — set VITE_REOWN_PROJECT_ID=your_id
npm install
npm run dev
```

Open `http://localhost:5173` on your desktop browser.

### 2. Generate unsigned tx fixture (after funding)

From `example/` (requires FFI — use Flutter on macOS or a device, not plain `dart run`):

```bash
cd example
flutter run -t tool/generate_fixture.dart -d macos --release
```

This writes `demo/dapp-web/public/fixtures/unsigned-tx.hex`.

To verify signing and submission on preprod (2 self-transfers):

```bash
cd example
flutter run -t tool/e2e_transfer_test.dart -d macos --release
```

### 3. Flutter example wallet (phone)

```bash
cd example
flutter run \
  --dart-define=REOWN_PROJECT_ID=your_id
```

## Demo flow (video script ~3 min)

1. Open web dApp → click **Connect via WalletConnect** → QR appears
2. On phone: open example app → **Scan QR** (or paste URI)
3. Approve session proposal on phone
4. Web dApp shows **Connected** with `cip34:0-1` account — **screenshot this + phone connected banner**
5. Click **getNetworkId** → log shows `0`
6. Click **signTx** → approve on phone → log shows witness CBOR hex
7. Optionally run **Run all read methods**

## Screenshot checklist (PoA)

- [ ] Browser: green **Connected** status + session accounts visible
- [ ] Phone: green **Connected** banner with dApp name
- [ ] Browser log: `cardano_signTx` response with witness hex

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `signTx` fails — missing fixture | Fund wallet, run `generate_fixture.dart` |
| Pairing hangs | Same `REOWN_PROJECT_ID` on both sides; check network |
| Empty balance/UTXOs | Confirm faucet sent to the address shown in the app |
| Koios errors | Retry; API is `https://preprod.koios.rest/api/v1` |

## Evidence links (fill before PoA)

- Video: _[YouTube/Drive URL]_
- Screenshot: _[URL]_
- GitHub: `example/` + `demo/dapp-web/`
