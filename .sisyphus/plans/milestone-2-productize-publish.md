# Milestone 2: Productizing SDK & Publishing

## TL;DR

> **Quick Summary**: Take the working SDK from Milestone 1 to production quality — clean architecture, unit tests, comprehensive docs, performance review, and publish to pub.dev.
> 
> **Deliverables**:
> - Refactored codebase following Dart/Flutter best practices
> - Technical debt resolved from M1
> - Comprehensive unit tests covering core functionality
> - Complete README with quick setup, usage examples, and API overview
> - Demo video showing WalletConnect pairing + CIP-30 method flow
> - Published package on pub.dev with semantic versioning and changelog
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 3 waves
> **Critical Path**: Code Review/Refactor → Unit Tests → README Finalize → pub.dev Publish

---

## Context

### Original Request
Catalyst Milestone 2: "Productizing SDK & Publishing". The SDK from M1 works functionally. This milestone brings it to production standards and makes it available to the Dart/Flutter community via pub.dev.

### Catalyst Acceptance Criteria (verbatim from proposal)
- Codebase must follow Flutter best practices with proper null safety, type definitions, and documentation comments for all public APIs
- Unit test coverage must cover relevant parts of the codebase
- README must include installation instructions, initialization code, and at least a simple use-case
- Demonstration video must show successful WalletConnect pairing and transaction approval
- Package must be successfully published to pub.dev with proper semantic versioning, package description, and changelog

### Evidence Required
- Link to published package on pub.dev
- Links to unit tests in GitHub and screenshot of them passing
- Video demonstrating WalletConnect working

---

## Prerequisites (MUST be verified before starting this milestone)

> **This plan depends on Milestone 1 being complete.** Before executing ANY task in this plan, verify these preconditions:

```bash
# Precondition check — run ALL of these before starting M2
test -f pubspec.yaml && echo "PASS: pubspec.yaml exists" || echo "FAIL: Run M1 first"
test -d lib/src && echo "PASS: lib/src/ exists" || echo "FAIL: Run M1 first"
test -f lib/wallet_connect_cardano.dart && echo "PASS: barrel file exists" || echo "FAIL: Run M1 first"
test -f AGENTS.md && echo "PASS: AGENTS.md exists" || echo "FAIL: Run M1 first"
test -f README.md && echo "PASS: README.md exists" || echo "FAIL: Run M1 first"
test -f CHANGELOG.md && echo "PASS: CHANGELOG.md exists" || echo "FAIL: Run M1 first"
test -f analysis_options.yaml && echo "PASS: analysis_options.yaml exists" || echo "FAIL: Run M1 first"
flutter pub get && echo "PASS: deps resolve" || echo "FAIL: deps broken"
dart analyze && echo "PASS: analysis clean" || echo "FAIL: analysis errors"
```

**If ANY check fails**: Do NOT proceed. Execute `.sisyphus/plans/milestone-1-core-sdk.md` first.

---

## Work Objectives

### Core Objective
Make the SDK production-ready, well-tested, well-documented, and publicly available on pub.dev.

### Concrete Deliverables
- Refactored `lib/` with clean architecture
- `test/` directory with unit tests
- Finalized `README.md` with complete documentation
- Updated `CHANGELOG.md` with all changes
- `pubspec.yaml` ready for publishing (description, homepage, repository, etc.)
- Published `wallet_connect_cardano` package on pub.dev
- Demo video (recorded)

### Definition of Done
- [ ] `dart analyze` passes with zero warnings
- [ ] All unit tests pass
- [ ] Package scores well on pub.dev analysis (aim for 130+ pub points)
- [ ] README has installation, quick start, full API reference, and example
- [ ] Package is live on pub.dev

### Must Have
- Unit tests for: handler registration, param parsing (both array and object), error mapping, session lifecycle
- Dartdoc comments on ALL public APIs
- Null safety throughout
- Proper `pubspec.yaml` with description, homepage, repository, topics
- CHANGELOG.md documenting all features
- Working pub.dev publication

### Must NOT Have (Guardrails)
- No skipping tests for "hard to test" code — mock reown_walletkit
- No `// ignore` or `// ignore_for_file` directives without justification
- No `dynamic` types in public API signatures (use proper types)
- No publishing without passing `dart pub publish --dry-run`
- No committed WalletConnect project IDs or secrets

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: NO (setting up in this milestone)
- **Automated tests**: YES (tests-after, not TDD — code exists from M1)
- **Framework**: `flutter test` (due to transitive Flutter dependency from reown_walletkit)

### QA Policy
Every task includes agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/`.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Assessment + Setup):
+-- Task 1: Code review and technical debt assessment [deep]
+-- Task 2: Test infrastructure setup [quick]

Wave 2 (Core Work — after Wave 1):
+-- Task 3: Code refactoring and cleanup [deep]
+-- Task 4: Unit tests — models and error types [quick]
+-- Task 5: Unit tests — handler registration and param parsing [deep]
+-- Task 6: Unit tests — session lifecycle [deep]

Wave 3 (Polish + Publish — after Wave 2):
+-- Task 7: README finalization and dartdoc review [quick]
+-- Task 8: pub.dev publishing preparation and publish [deep]
+-- Task 9: Demo video recording [unspecified-high]

Critical Path: T1 → T3 → T5 → T7 → T8
Max Concurrent: 4 (Wave 2)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | 3 |
| 2 | — | 4, 5, 6 |
| 3 | 1 | 4, 5, 6, 7 |
| 4 | 2, 3 | 7, 8 |
| 5 | 2, 3 | 7, 8 |
| 6 | 2, 3 | 7, 8 |
| 7 | 4, 5, 6 | 8 |
| 8 | 7 | — |
| 9 | 3 | — |

---

## TODOs

- [ ] 1. Code review and technical debt assessment

  **What to do**:
  - Review all code from Milestone 1 for:
    - Dart best practices compliance (naming, null safety, type annotations)
    - Missing or inadequate dartdoc comments
    - Code organization (file structure, separation of concerns)
    - Error handling completeness
    - Unnecessary complexity or over-abstraction
    - Any TODO/FIXME/HACK comments left from M1
  - Produce a prioritized list of issues to fix in Task 3
  - Check for any `dynamic` types in public API signatures
  - Verify barrel exports are complete and correct
  - Save assessment report to `.sisyphus/evidence/task-1-code-review.md`

  **Must NOT do**:
  - Do not fix anything yet — assessment only
  - Do not rewrite working code for aesthetic reasons

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 2)
  - **Blocks**: Task 3
  - **Blocked By**: None

  **References**:
  - All `lib/` files from Milestone 1
  - [Effective Dart](https://dart.dev/effective-dart) — style, documentation, usage, design guidelines
  - [Dart linting rules](https://dart.dev/tools/linter-rules) — recommended lint rules

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Assessment report is comprehensive
    Tool: Bash
    Steps:
      1. Verify .sisyphus/evidence/task-1-code-review.md exists
      2. Verify it covers: naming, null safety, docs, structure, error handling
      3. Verify it has a prioritized issue list
    Expected Result: Complete assessment document with actionable items
    Evidence: .sisyphus/evidence/task-1-code-review.md
  ```

  **Commit**: NO (assessment only)

---

- [ ] 2. Test infrastructure setup

  **What to do**:
  - Add test dependencies to `pubspec.yaml`: `flutter_test` (or `test`), `mockito` or `mocktail` for mocking
  - Create `test/` directory
  - Create a test helper file with common setup (mock CardanoWalletDelegate, mock ReownWalletKit if needed)
  - Verify `flutter test` (or `dart test`) runs successfully (even with zero tests)
  - Add test-related entries to `analysis_options.yaml` if needed

  **Must NOT do**:
  - Do not write actual tests yet — just infrastructure
  - Do not add heavy test dependencies that inflate package size

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: Tasks 4, 5, 6
  - **Blocked By**: None

  **References**:
  - [Dart testing guide](https://dart.dev/guides/testing)
  - [mocktail package](https://pub.dev/packages/mocktail) — recommended for Dart mocking (no code generation needed)
  - `pubspec.yaml` — add dev dependencies

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Test infrastructure works
    Tool: Bash
    Steps:
      1. Run `flutter test` — should complete (0 tests, no errors)
      2. Verify `test/` directory exists
      3. Verify mock helper file exists
    Expected Result: Test framework ready for use
    Evidence: .sisyphus/evidence/task-2-test-setup.txt
  ```

  **Commit**: YES
  - Message: `chore: set up test infrastructure with mocktail`
  - Files: `pubspec.yaml`, `test/`

---

- [ ] 3. Code refactoring and cleanup

  **What to do**:
  - Address all issues from Task 1 assessment, prioritized by severity
  - Specific focus areas:
    - Add missing dartdoc comments to ALL public APIs
    - Fix any null safety issues
    - Replace `dynamic` in public API signatures with proper types
    - Resolve TODO/FIXME/HACK comments
    - Improve error messages
    - Ensure consistent naming conventions
    - Clean up imports (remove unused, organize)
    - Ensure proper file organization in `lib/src/`
  - Run `dart analyze` after each change — must stay at zero warnings
  - Do NOT change public API signatures unless fixing a bug — avoid breaking changes

  **Must NOT do**:
  - Do not change the public API surface (method names, param types) without justification
  - Do not add new features — refactoring only
  - Do not over-engineer or add premature abstractions

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (starts first, before tests)
  - **Blocks**: Tasks 4, 5, 6, 7
  - **Blocked By**: Task 1

  **References**:
  - Task 1 assessment report — prioritized issue list
  - [Effective Dart](https://dart.dev/effective-dart) — guidelines to follow
  - All `lib/` source files

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Code passes strict analysis
    Tool: Bash
    Steps:
      1. Run `dart analyze` — zero errors, zero warnings
      2. Verify no TODO/FIXME/HACK comments remain (grep)
      3. Verify all public APIs have dartdoc comments
    Expected Result: Clean, well-documented codebase
    Evidence: .sisyphus/evidence/task-3-refactor.txt
  ```

  **Commit**: YES
  - Message: `refactor: clean up codebase for production quality`
  - Files: `lib/`

---

- [ ] 4. Unit tests — models and error types

  **What to do**:
  - Write unit tests for all CIP-30 models and error types (from M1 Task 4):
    - `CardanoApiError` — test all error codes, toJson/fromJson round-trip
    - `CardanoDataSignError` — test all codes
    - `CardanoPaginateError` — test maxSize field
    - `CardanoTxSendError` — test all codes
    - `CardanoTxSignError` — test all codes
    - `CardanoPaginate` — test page/limit, serialization
    - `CardanoExtension` — test cip field
    - `CardanoDataSignature` — test signature/key fields
  - Place tests in `test/models/`

  **Must NOT do**:
  - Do not test private implementation details
  - Do not create overly brittle tests (test behavior, not implementation)

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6)
  - **Blocks**: Tasks 7, 8
  - **Blocked By**: Tasks 2, 3

  **References**:
  - `lib/src/models/` — model source code to test
  - [CIP-30 Error Types](https://cips.cardano.org/cip/CIP-30#error-types) — verify against spec
  - Task 2 test helpers — mocking setup

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: All model tests pass
    Tool: Bash
    Steps:
      1. Run `flutter test test/models/` — all pass
      2. Verify each error type has at least one test per error code
      3. Verify serialization round-trip tests exist
    Expected Result: All model tests green
    Evidence: .sisyphus/evidence/task-4-model-tests.txt
  ```

  **Commit**: YES
  - Message: `test: add unit tests for CIP-30 models and error types`
  - Files: `test/models/`

---

- [ ] 5. Unit tests — handler registration and param parsing

  **What to do**:
  - Write unit tests for the CIP-30 method handler logic:
    - Test that all 12 handlers are registered for the correct chain ID and method name
    - Test param parsing for **positional array format**: `[tx, false]` → `signTx(tx, partialSign: false)`
    - Test param parsing for **named object format**: `{'tx': tx, 'partialSign': false}` → same
    - Test that params with optional fields work (e.g., `getUtxos` with/without amount, with/without paginate)
    - Test error mapping: when delegate throws a CIP-30 error, handler returns correct JSON-RPC error
    - Test error mapping: when delegate throws unexpected exception, handler returns InternalError
    - Test handler correctly calls the CardanoWalletDelegate method and returns its result
  - Use mocked CardanoWalletDelegate (from test helpers)
  - Place tests in `test/handlers/`

  **Must NOT do**:
  - Do not test reown_walletkit internals — only test our handler logic
  - Do not make tests dependent on network connectivity

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
    - Reason: Most critical tests — param parsing edge cases are subtle

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 6)
  - **Blocks**: Tasks 7, 8
  - **Blocked By**: Tasks 2, 3

  **References**:
  - `lib/src/` handler files — code under test
  - AGENTS.md CIP-30 Methods table — param formats for each method
  - [WalletConnect Cardano JS PR #1880](https://github.com/WalletConnect/walletconnect-monorepo/pull/1880) — reference for actual param formats used by dApps

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Handler tests pass with both param formats
    Tool: Bash
    Steps:
      1. Run `flutter test test/handlers/` — all pass
      2. Verify tests exist for array params AND object params
      3. Verify error mapping tests exist (at least 3 error scenarios)
    Expected Result: All handler tests green, both param formats covered
    Evidence: .sisyphus/evidence/task-5-handler-tests.txt
  ```

  **Commit**: YES
  - Message: `test: add unit tests for CIP-30 method handlers and param parsing`
  - Files: `test/handlers/`

---

- [ ] 6. Unit tests — session lifecycle

  **What to do**:
  - Write unit tests for session lifecycle management:
    - Test SDK initialization (constructor accepts required params)
    - Test session approval creates correct `cip34` namespace with configured methods and events
    - Test session rejection passes correct reason
    - Test disconnect calls reown_walletkit disconnect
    - Test getActiveSessions returns sessions
    - Test event emitter registration for both conventions (4 events total)
    - Test that all 12 handlers are registered during initialization
  - Use mocked ReownWalletKit (from test helpers)
  - Place tests in `test/session/`

  **Must NOT do**:
  - Do not test actual WalletConnect network connectivity
  - Do not test reown_walletkit internal behavior

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5)
  - **Blocks**: Tasks 7, 8
  - **Blocked By**: Tasks 2, 3

  **References**:
  - `lib/src/` main SDK class — code under test
  - [reown_walletkit API](https://pub.dev/packages/reown_walletkit) — understand what to mock
  - AGENTS.md Events section — 4 event names to verify

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Session lifecycle tests pass
    Tool: Bash
    Steps:
      1. Run `flutter test test/session/` — all pass
      2. Verify namespace construction test verifies 'cip34' key
      3. Verify event registration tests check all 4 event names
    Expected Result: All session tests green
    Evidence: .sisyphus/evidence/task-6-session-tests.txt
  ```

  **Commit**: YES
  - Message: `test: add unit tests for session lifecycle management`
  - Files: `test/session/`

---

- [ ] 7. README finalization and dartdoc review

  **What to do**:
  - Rewrite/expand README.md to meet Catalyst acceptance criteria:
    1. **Header**: Package name, badges (pub.dev version, license, build status if applicable)
    2. **Overview**: What the SDK does (communication bridge, NOT signing engine)
    3. **Installation**: pubspec.yaml snippet, flutter pub get
    4. **Prerequisites**: WalletConnect project ID (how to get one from cloud.reown.com)
    5. **Quick Start**: Complete minimal example showing:
       - Implement CardanoWalletDelegate
       - Initialize WalletConnectCardano
       - Pair with a dApp URI
       - Handle session proposals
    6. **CardanoWalletDelegate Reference**: Each method with expected input/output format
    7. **Session Management**: Approve, reject, disconnect, list sessions
    8. **Supported CIP-30 Methods**: Complete table
    9. **Error Handling**: How errors propagate, CIP-30 error types
    10. **Configuration**: Chain IDs, networks, metadata
    11. **Contributing**: How to contribute (standard OSS section)
    12. **License**: MIT
  - Review all dartdoc comments in `lib/` — ensure completeness
  - Verify all code examples in README actually compile (or are at minimum syntactically valid)

  **Must NOT do**:
  - Do not include VESPR-specific integration details
  - Do not include WalletConnect project IDs in examples
  - Do not bloat with unnecessary sections

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3
  - **Blocks**: Task 8
  - **Blocked By**: Tasks 4, 5, 6

  **References**:
  - Current `README.md` from M1
  - [reown_walletkit README](https://pub.dev/packages/reown_walletkit) — good SDK readme example
  - [pub.dev scoring criteria](https://pub.dev/help/scoring) — README quality affects pub points
  - AGENTS.md — CIP-30 methods table, architecture diagram

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: README meets Catalyst criteria
    Tool: Bash
    Steps:
      1. Verify README.md has sections: Installation, Quick Start, API Reference
      2. Verify at least one complete code example exists (dart code block)
      3. Verify CIP-30 methods table is present
      4. Verify no placeholder text or TODOs remain
    Expected Result: Complete, publishable README
    Evidence: .sisyphus/evidence/task-7-readme.txt
  ```

  **Commit**: YES
  - Message: `docs: finalize README and dartdoc for pub.dev publishing`
  - Files: `README.md`, `lib/` (dartdoc updates)

---

- [ ] 8. pub.dev publishing preparation and publish

  **What to do**:
  - Update `pubspec.yaml` for publishing:
    - `description`: Clear, concise (60-180 chars)
    - `homepage`: GitHub repo URL
    - `repository`: GitHub repo URL
    - `issue_tracker`: GitHub issues URL
    - `topics`: `['cardano', 'walletconnect', 'cip30', 'blockchain', 'web3']` (max 5)
    - `version`: `0.1.0` (or appropriate based on actual state)
    - Verify `environment` SDK constraints are correct
  - Update `CHANGELOG.md` with all M1 + M2 changes
  - Run `dart pub publish --dry-run` — fix ALL issues reported
  - Run `flutter test` — all tests must pass
  - Run `dart analyze` — zero warnings
  - Run `dart doc` — verify documentation generates correctly
  - **Publishing step** (requires human credentials — NOT fully automated):
    - Run `dart pub publish --dry-run` to verify everything passes (this IS automated)
    - Log the dry-run output as evidence
    - The actual `dart pub publish` requires pub.dev authentication (OAuth via browser). This step must be executed by a team member with pub.dev credentials. Document exact command and expected output.
    - After publishing (done by human), verify package appears on pub.dev

  **Must NOT do**:
  - Do not publish with warnings from dry-run
  - Do not use version 1.0.0 yet (pre-1.0 signals development stage)
  - Do not include test files or example apps in the published package (use `.pubignore` if needed)
  - Do not commit any authentication tokens

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
    - Reason: Publishing requires careful validation and may need troubleshooting

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (after Task 7)
  - **Blocks**: None
  - **Blocked By**: Task 7

  **References**:
  - [pub.dev publishing guide](https://dart.dev/tools/pub/publishing) — official publishing steps
  - [pub.dev scoring](https://pub.dev/help/scoring) — maximize pub points
  - `pubspec.yaml` — update metadata fields

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Dry run passes with zero issues
    Tool: Bash
    Steps:
      1. Run `dart pub publish --dry-run` — zero warnings/errors
      2. Verify package name, version, description are correct
      3. Verify topics are set (max 5)
    Expected Result: Clean dry run ready for publish
    Evidence: .sisyphus/evidence/task-8-dry-run.txt

  Scenario: Publishing prepared — human handoff ready
    Tool: Bash
    Steps:
      1. Verify dry-run evidence file exists at .sisyphus/evidence/task-8-dry-run.txt
      2. Verify dry-run output contains "Package has 0 warnings" (or similar clean output)
      3. Log message: "Ready to publish. Run `dart pub publish` with pub.dev credentials."
    Expected Result: Dry-run passes, publishing command documented for human execution
    Evidence: .sisyphus/evidence/task-8-publish-ready.txt
    Note: Actual `dart pub publish` requires OAuth — cannot be fully automated
  ```

  **Commit**: YES
  - Message: `chore: prepare and publish v0.1.0 to pub.dev`
  - Files: `pubspec.yaml`, `CHANGELOG.md`

---

- [ ] 9. Demo video recording

  **What to do**:
  - Record a demonstration video showing:
    1. SDK installation in a sample Flutter project
    2. Implementing the CardanoWalletDelegate with mock data
    3. Initializing WalletConnectCardano
    4. Pairing with a test dApp (show QR code scan or URI paste)
    5. Session proposal appearing and being approved
    6. CIP-30 method request being received and responded to (e.g., getBalance, signTx)
    7. Session disconnect
  - Video should be 2-5 minutes
  - Can use a simple test dApp that sends WalletConnect requests (or the Reown example dApp)
  - This is Catalyst evidence — must clearly show the SDK working

  **Must NOT do**:
  - Do not show any real private keys or wallet data
  - Do not use real funds
  - Do not make it longer than necessary

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []
    - Reason: May need to set up test dApp, create sample project, and record screen

  **Parallelization**:
  - **Can Run In Parallel**: YES (can start after Task 3, independent of tests)
  - **Parallel Group**: Wave 3 (parallel with Tasks 7, 8)
  - **Blocks**: None
  - **Blocked By**: Task 3 (needs working refactored code)

  **References**:
  - Working SDK code from Tasks 3-8
  - [Reown AppKit example](https://github.com/reown-com/reown_flutter/tree/master/packages/reown_appkit/example) — potential test dApp
  - Catalyst proposal evidence requirements — "Video demonstrating WalletConnect working"

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Video demonstrates required flows
    Tool: Bash
    Steps:
      1. Verify video file exists
      2. Verify video is 2-5 minutes in length
    Expected Result: Video showing pairing, session approval, and CIP-30 method flow
    Evidence: .sisyphus/evidence/task-9-demo-video.mp4 (or link)
  ```

  **Commit**: NO (video stored externally, linked in README or Catalyst report)

---

## Final Verification Wave

> After ALL tasks complete. ALL must approve.

- [ ] F1. **Test Suite Integrity**
  Run `flutter test` — ALL tests must pass. Report count: passed, failed, skipped. Verify test files cover: models, handlers, session lifecycle. No skipped tests without justification.
  Output: `Tests [N pass / N fail / N skip] | Coverage areas [models, handlers, session] | VERDICT`

- [ ] F2. **pub.dev Quality Check**
  Run `dart pub publish --dry-run`. Check pub points score. Verify description, topics, homepage, repository fields. Verify CHANGELOG.md is up to date. Verify dartdoc coverage.
  Output: `Dry-run [PASS/FAIL] | Pub points [N] | VERDICT`

- [ ] F3. **Catalyst Evidence Checklist**
  Verify all three evidence items exist:
  1. Published package link on pub.dev
  2. Unit tests passing (screenshot or CI output)
  3. Demo video showing WalletConnect working
  Output: `Evidence [3/3] | VERDICT`

---

## Commit Strategy

| Task | Commit Message | Key Files |
|------|---------------|-----------|
| 2 | `chore: set up test infrastructure with mocktail` | `pubspec.yaml`, `test/` |
| 3 | `refactor: clean up codebase for production quality` | `lib/` |
| 4 | `test: add unit tests for CIP-30 models and error types` | `test/models/` |
| 5 | `test: add unit tests for CIP-30 method handlers` | `test/handlers/` |
| 6 | `test: add unit tests for session lifecycle management` | `test/session/` |
| 7 | `docs: finalize README and dartdoc for pub.dev publishing` | `README.md`, `lib/` |
| 8 | `chore: prepare and publish v0.1.0 to pub.dev` | `pubspec.yaml`, `CHANGELOG.md` |

---

## Success Criteria

### Verification Commands
```bash
dart analyze          # Expected: zero errors, zero warnings
flutter test          # Expected: all tests pass
dart pub publish --dry-run  # Expected: no issues
dart doc              # Expected: generates successfully
```

### Final Checklist
- [ ] `dart analyze` passes with zero warnings
- [ ] All unit tests pass
- [ ] README has: Installation, Quick Start, API Reference, Examples
- [ ] All public APIs have dartdoc comments
- [ ] `CHANGELOG.md` documents all features
- [ ] Package published to pub.dev
- [ ] Demo video recorded showing WalletConnect flow
- [ ] No dynamic types in public API signatures
- [ ] No `// ignore` without justification
- [ ] No committed secrets or project IDs
