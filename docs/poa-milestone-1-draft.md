# Milestone 1 — Proof of Achievement (Draft)

**Project:** VESPR: WalletConnect Cardano Flutter SDK & VESPR Integration (#1400124)  
**Milestone:** [Core SDK Development](https://milestones.projectcatalyst.io/projects/1400124/milestones/1)  
**Budget:** 22,500 ADA

---

## Summary

We delivered a functional WalletConnect v2 communication bridge for Cardano (`wallet_connect_cardano`) with complete CIP-30 method routing and session lifecycle management. Because no Cardano WalletConnect dApp or wallet existed in the ecosystem, we also built:

- **Flutter example wallet** — [`example/`](../example/)
- **Web test dApp** — [`demo/dapp-web/`](../demo/dapp-web/)

Together these demonstrate stable sessions, all CIP-30 Full API methods, and real transaction signing on preprod.

## Deliverables

### GitHub repo with working SDK

- Package: [`lib/`](../lib/) — `WalletConnectCardano`, `CardanoWalletDelegate`, 12 JSON-RPC handlers
- Documentation: [`README.md`](../README.md), [`AGENTS.md`](../AGENTS.md)

### Session + CIP-30 proof

- Example wallet pairs via QR / URI paste, approves `cip34` namespace on preprod
- Web dApp connects via Sign Client, calls `cardano_getNetworkId`, `cardano_signTx`, and other Full API methods
- Runbook: [`docs/milestone-1-demo.md`](milestone-1-demo.md)

### Evidence

| Item | Link |
|------|------|
| Video (session + signTx) | _[ADD URL]_ |
| Screenshot (connected session) | _[ADD URL]_ |
| GitHub repo | https://github.com/vespr-wallet/wallet_connect_cardano |

## Success criteria mapping

| Criterion | Evidence |
|-----------|----------|
| Stable WC sessions with test dApp | Video + screenshot; `example/` + `demo/dapp-web/` |
| Correct transaction signing (witness CBOR) | Video shows `signTx` witness hex in dApp log |
| All CIP-30 Full API methods functional | Handler registration in SDK; dApp method panel |
| Setup guide and usage docs | `README.md`, `docs/milestone-1-demo.md` |

## Notes for reviewers

- The SDK is a **transport bridge** — signing is performed by the integrating wallet (`CardanoWalletDelegate`), demonstrated with real crypto via `cardano_flutter_sdk` in the example app.
- Chain ID: `cip34:0-1` (preprod). Namespace: `cip34`.
- On-chain queries use [Koios preprod](https://preprod.koios.rest/) (no API key).
