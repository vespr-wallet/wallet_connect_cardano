## Unreleased

### Fixed

- Send a `null` delegate result (for example `getUtxos` when the amount cannot
  be met) as an explicit JSON `null`. Reown WalletKit otherwise rejects a
  response with neither a result nor an error.

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
