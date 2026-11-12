## 0.1.2

### Fixed

- Answer each request with its own id when a dApp sends two requests of the
  same method concurrently. Reown can store the second request before the
  handler for the first runs, so matching by topic and method could reply to
  the wrong id (#9).

### Changed

- Dependencies: no constraint changes (`reown_walletkit` / `reown_core`
  1.5.1 are still the latest). Toolchain: Flutter 3.50.0 in `.tool-versions`
  and CI; CI uses `actions/checkout@v7` and `actions/setup-node@v7`.
- Example: `cardano_flutter_sdk` ^4.0.1 → ^5.5.0, `material_ui` instead of the
  deprecated `package:flutter/material.dart`, Android AGP 9.3.1 / Gradle 9.5.0
  / Kotlin 2.4.20, iOS CocoaPods integration committed.
- Web demo: `@walletconnect/sign-client` and `@walletconnect/types` 2.26.0,
  Vite 8.3.7 (fixes a high-severity advisory in Vite's dev server), TypeScript 7.

## 0.1.1

### Fixed

- Send a `null` delegate result (for example `getUtxos` when the amount cannot
  be met) as an explicit JSON `null`. Reown WalletKit otherwise rejects a
  response with neither a result nor an error.
- Example wallet now signs and submits the transaction it receives instead of
  one it built itself, and refuses to sign transactions with mainnet outputs.

## 0.1.0

### Added

- Complete CIP-30 routing for 13 WalletConnect JSON-RPC methods, including the
  deprecated `cardano_getCollateral` compatibility method.
- Unit coverage for models, positional and named parameters, request routing,
  error mapping, and session lifecycle operations.
- GitHub Actions checks for formatting, analysis, SDK and example tests,
  package validation, and the TypeScript web demo build.
- pub.dev metadata and an explicit release archive allowlist.

### Changed

- Require Dart 3.8, Flutter 3.32, and `reown_walletkit` 1.5.0 or newer.
- Make SDK initialization idempotent and expose a clear pre-initialization
  `StateError`.
- Allow applications that already own an `IReownWalletKit` instance to inject
  it into `WalletConnectCardano`.
- Validate optional parameters and pagination bounds as CIP-30 invalid
  requests instead of leaking runtime type errors.
- Use `Object`-typed public JSON maps instead of `dynamic`.
- Require demo users to provide their own Reown project ID.

## 0.0.1 - Initial development version

- Initial WalletConnect v2 bridge with Cardano CIP-30 models, handlers, session
  lifecycle helpers, documentation, and preprod demo applications.
