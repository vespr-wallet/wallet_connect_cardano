## Unreleased

### Changed

- CI checks formatting for the whole example app (it covered three example
  files and `example/test`), and the example is formatted. The README's
  development checks match CI (`dart analyze --fatal-infos`). The package code
  is unchanged.
- Dependencies (example and web demo only, the package is unchanged): example
  Kotlin Gradle plugin 2.4.20 → 2.4.21; web demo Vite 8.3.7 → 8.3.8 (rolldown
  1.2.19), and the demo gets an `.npmrc` with `min-release-age=5`, so npm
  skips releases younger than five days.
- Tooling: Flutter 3.50.1 (still Dart 3.14.0) in `.tool-versions` and CI.
- Tooling: CI reads the Flutter version from `.tool-versions` instead of a
  hard-coded `flutter-version`, so a Flutter bump only edits `.tool-versions`.
  The step fails if the `flutter` line is missing.
- Web demo lockfile refresh (transitive only, the package is unchanged):
  postcss 8.5.33, source-map-js 1.2.3, ws 7.5.14, @rolldown/pluginutils
  1.1.1, @tybys/wasm-util 0.10.5. `npm audit` stays at 0.
- Web demo: ESLint 10 with typescript-eslint 8.73 (`eslint.config.js`, the
  recommended rule sets, `npm run lint`), and the CI "Web demo" job fails the
  PR on lint issues. TypeScript goes back from 7.0 to 6.0.3, because
  typescript-eslint supports TypeScript below 6.1 only; the other VESPR
  TypeScript repos stay on 6 for the same reason. The package is unchanged.
- Web demo: no non-null assertions or element casts. A `requireElement`
  helper checks each element's type and names the missing id, and lint
  rejects new `!` assertions. The package is unchanged.

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
