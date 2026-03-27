# Milestone 3: Pilot Integration & Close-out

## TL;DR

> **Quick Summary**: Complete the Catalyst deliverables — an integration guide for wallet developers, any SDK fixes discovered during VESPR pilot integration (done in a separate repo), the Catalyst Final Report, and the Close-out Video.
> 
> **Deliverables**:
> - Comprehensive integration guide for wallet developers
> - Any SDK bug fixes discovered during VESPR pilot
> - Catalyst Final Report (document template + content guidance)
> - Catalyst Close-out Video (script + content guidance)
> - Updated AGENTS.md with final project status
> 
> **Estimated Effort**: Short
> **Parallel Execution**: YES — 2 waves
> **Critical Path**: Integration Guide → SDK Fixes (if any) → Catalyst Report Prep → Close-out Video Prep

---

## Context

### Original Request
Catalyst Milestone 3: "Pilot Integration & Close-out". The VESPR wallet integration happens in a SEPARATE repo — that code is NOT part of this repo's scope. This repo's M3 work focuses on:
1. Making the SDK easy to integrate (comprehensive guide)
2. Fixing any SDK issues found during VESPR pilot
3. Preparing Catalyst deliverables (report and video content)

### CRITICAL SCOPE BOUNDARY
**The VESPR integration code is NOT in this repo.** This plan covers only what happens in the `wallet_connect_cardano` SDK repo:
- Integration documentation for any wallet developer
- SDK-side bug fixes discovered during the pilot
- Templates and content guidance for Catalyst deliverables

The actual VESPR integration, Catalyst Final Report submission, and Close-out Video recording/uploading are done outside this repo by the VESPR team.

### Catalyst Acceptance Criteria (verbatim from proposal)
- VESPR Wallet beta build must successfully establish WalletConnect sessions
- Integration must handle CIP-30 methods without errors
- Catalyst Final Report must comprehensively document all milestones achieved, metrics collected, and community impact
- Close-out Video must demonstrate the completion of this SDK and the pilot integration

### Evidence Required
- Screenshot: VESPR connecting via WalletConnect
- Link to Catalyst final report
- Link to Catalyst Close-out Video

---

## Prerequisites (MUST be verified before starting this milestone)

> **This plan depends on Milestones 1 AND 2 being complete.** Before executing ANY task, verify:

```bash
# Precondition check — run ALL before starting M3
test -f pubspec.yaml && echo "PASS: pubspec.yaml exists" || echo "FAIL: Run M1 first"
test -d lib/src && echo "PASS: lib/src/ exists" || echo "FAIL: Run M1 first"
test -d test && echo "PASS: test/ exists" || echo "FAIL: Run M2 first"
test -f AGENTS.md && echo "PASS: AGENTS.md exists" || echo "FAIL: Run M1 first"
test -f README.md && echo "PASS: README.md exists" || echo "FAIL: Run M1 first"
flutter test && echo "PASS: tests pass" || echo "FAIL: Fix tests first"
dart analyze && echo "PASS: analysis clean" || echo "FAIL: Fix analysis first"
dart pub publish --dry-run 2>&1 | head -5 && echo "PASS: publishable" || echo "FAIL: Fix pub issues"
```

**If ANY check fails**: Do NOT proceed. Complete M1 and M2 first.

---

## Work Objectives

### Core Objective
Ensure the SDK is well-documented for integration, fix any issues found during pilot, and prepare Catalyst close-out materials.

### Concrete Deliverables (this repo only)
- `docs/integration-guide.md` — step-by-step wallet integration guide
- SDK bug fixes (if any discovered during VESPR pilot)
- `docs/catalyst-final-report-template.md` — template and content guidance for Catalyst report
- `docs/catalyst-closeout-video-script.md` — script/outline for close-out video
- Updated `AGENTS.md` with final status
- Updated `CHANGELOG.md` with any M3 changes

### Definition of Done
- [ ] Integration guide covers complete wallet developer journey
- [ ] All known SDK bugs fixed
- [ ] Catalyst report template has all required sections filled or guided
- [ ] Close-out video script covers all required demonstration points

### Must Have
- Integration guide with complete code examples
- Troubleshooting section in integration guide
- Catalyst report template covering: milestones, metrics, community impact, lessons learned, future roadmap
- Close-out video script covering: SDK demo, VESPR integration demo, project outcomes

### Must NOT Have (Guardrails)
- No VESPR wallet source code in this repo
- No Catalyst Final Report submitted from this repo (VESPR team does that)
- No video files committed to this repo (hosted externally)
- No changes to the public API without backwards compatibility (SDK is published)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed.

### Test Decision
- **Infrastructure exists**: YES (from M2)
- **Automated tests**: YES (run existing tests to verify fixes don't break anything)
- **Framework**: `flutter test`

### QA Policy
Every task includes agent-executed QA scenarios. Evidence saved to `.sisyphus/evidence/`.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Documentation — all independent):
+-- Task 1: Comprehensive integration guide [deep]
+-- Task 2: Catalyst Final Report template [quick]
+-- Task 3: Catalyst Close-out Video script [quick]

Wave 2 (Fixes + Finalization — after pilot feedback):
+-- Task 4: SDK bug fixes from pilot (if any) [deep]
+-- Task 5: Final AGENTS.md and CHANGELOG update [quick]

Critical Path: T1 → T4 (if bugs) → T5
Max Concurrent: 3 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | 4 |
| 2 | — | — |
| 3 | — | — |
| 4 | 1 (pilot feedback) | 5 |
| 5 | 4 | — |

---

## TODOs

- [ ] 1. Comprehensive integration guide for wallet developers

  **What to do**:
  - Create `docs/integration-guide.md` — a step-by-step guide for any Flutter wallet app to integrate the SDK
  - Structure:
    1. **Prerequisites**: Flutter setup, WalletConnect Cloud account (project ID), Cardano wallet backend
    2. **Installation**: Add dependency, run pub get
    3. **Step 1 — Implement CardanoWalletDelegate**: Full example implementation showing how to connect each callback to the wallet's existing functionality (getBalance, signTx, etc.). Include detailed comments explaining what each method should return and in what format (hex-encoded CBOR strings).
    4. **Step 2 — Initialize the SDK**: Create WalletConnectCardano instance with configuration
    5. **Step 3 — Handle Pairing**: How to get WalletConnect URI (QR code scanning), call pair()
    6. **Step 4 — Handle Session Proposals**: Listen for proposals, present to user, approve/reject
    7. **Step 5 — Handle CIP-30 Requests**: How requests flow from dApp → SDK → delegate → SDK → dApp
    8. **Step 6 — Session Management**: Disconnect, list sessions, handle expiry
    9. **Step 7 — Events**: Emit account/network change events
    10. **Advanced Topics**: Multiple networks (mainnet + testnet), error handling best practices, reconnection handling
    11. **Troubleshooting**: Common issues and solutions (connection failures, namespace mismatches, timeout handling)
    12. **Testing Your Integration**: How to test with Reown AppKit example dApp
  - Include complete, compilable code examples at each step
  - Link back to README for API reference

  **Must NOT do**:
  - Do not include VESPR-specific code (keep it generic for any wallet)
  - Do not document internal SDK implementation details
  - Do not assume readers know WalletConnect internals

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []
    - Reason: Comprehensive technical writing requiring understanding of full SDK flow

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: Task 4 (guide informs what pilot testers need)
  - **Blocked By**: None

  **References**:
  - `README.md` — existing API documentation
  - `lib/src/` — actual SDK API to document
  - [reown_walletkit docs](https://docs.reown.com/walletkit/flutter/installation) — reference for WalletConnect setup steps
  - [CIP-30 Full API](https://cips.cardano.org/cip/CIP-30#full-api) — method descriptions
  - AGENTS.md — architecture diagram, CIP-30 methods table

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Integration guide is complete and practical
    Tool: Bash
    Steps:
      1. Verify docs/integration-guide.md exists
      2. Verify all 12 sections listed above are present
      3. Verify at least 5 code examples (dart code blocks)
      4. Verify Troubleshooting section has at least 3 common issues
    Expected Result: Comprehensive guide a wallet developer can follow end-to-end
    Evidence: .sisyphus/evidence/task-1-integration-guide.txt
  ```

  **Commit**: YES
  - Message: `docs: add comprehensive wallet integration guide`
  - Files: `docs/integration-guide.md`

---

- [ ] 2. Catalyst Final Report template and content guidance

  **What to do**:
  - Create `docs/catalyst-final-report-template.md` with:
    1. **Project Summary**: Pre-filled with proposal details (#1400124, Fund 14, objectives)
    2. **Milestone 1 Summary**: Section template covering:
       - What was delivered (core SDK, session management, CIP-30 routing)
       - Evidence links (GitHub repo, video, screenshot)
       - Challenges encountered and how they were resolved
    3. **Milestone 2 Summary**: Section template covering:
       - What was delivered (production quality, tests, pub.dev)
       - Evidence links (pub.dev link, test screenshots, video)
       - Metrics (pub points score, test count, code quality stats)
    4. **Milestone 3 Summary**: Section template covering:
       - VESPR pilot integration results
       - Evidence (screenshot, report, video)
    5. **Metrics & Impact**: Template sections for:
       - pub.dev download count
       - GitHub stars/forks
       - dApps using the SDK (if any)
       - Community engagement
    6. **Lessons Learned**: Prompts for what to write about
    7. **Future Roadmap**: Template for planned improvements
    8. **Budget Breakdown**: Template matching proposal budget
  - Add guidance comments (e.g., `<!-- FILL IN: Describe the specific challenges... -->`)
  - This is a TEMPLATE — the VESPR team fills in the actual content

  **Must NOT do**:
  - Do not fill in actual metrics (they don't exist yet)
  - Do not fabricate evidence or results
  - Do not submit the report — VESPR team does that

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - [Catalyst proposal page](https://projectcatalyst.io/funds/14/cardano-open-developers/vespr-walletconnect-cardano-flutter-sdk-and-vespr-integration) — original proposal text, milestone definitions, budget
  - [Catalyst milestone reporting guidelines](https://docs.projectcatalyst.io/) — reporting format requirements
  - AGENTS.md — milestone definitions

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Report template covers all required sections
    Tool: Bash
    Steps:
      1. Verify docs/catalyst-final-report-template.md exists
      2. Verify sections: Project Summary, M1/M2/M3 summaries, Metrics, Lessons, Roadmap, Budget
      3. Verify guidance comments exist (grep for FILL IN or similar markers)
    Expected Result: Complete template ready for VESPR team to fill in
    Evidence: .sisyphus/evidence/task-2-report-template.txt
  ```

  **Commit**: YES
  - Message: `docs: add Catalyst Final Report template`
  - Files: `docs/catalyst-final-report-template.md`

---

- [ ] 3. Catalyst Close-out Video script

  **What to do**:
  - Create `docs/catalyst-closeout-video-script.md` with:
    1. **Video Structure** (suggested 5-10 minutes):
       - Intro (30s): Project name, Catalyst Fund 14, team
       - Problem Statement (1min): Why Cardano needs WalletConnect Flutter SDK
       - Solution Overview (1min): Architecture, communication bridge approach
       - SDK Demo (2-3min): Show the SDK in action — pairing, session, CIP-30 methods
       - VESPR Integration Demo (1-2min): Show VESPR wallet connecting to a dApp via WalletConnect
       - Metrics & Impact (1min): Downloads, community response, ecosystem impact
       - Future Plans (30s): What's next for the SDK
       - Close (30s): Thank Catalyst, community
    2. **Key Talking Points**: Bullet points for each section with what to say
    3. **Demo Script**: Exact steps to demonstrate during the video
       - What dApp to connect to
       - What actions to perform
       - What to highlight on screen
    4. **Technical Setup**: What needs to be prepared before recording
       - Test dApp running
       - VESPR beta installed
       - Screen recording software
    5. **Catalyst Requirements Checklist**: What the video MUST show per acceptance criteria

  **Must NOT do**:
  - Do not record the video — VESPR team does that
  - Do not commit video files to this repo

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: None
  - **Blocked By**: None

  **References**:
  - Catalyst proposal — acceptance criteria for Close-out Video
  - AGENTS.md — project overview, architecture
  - SDK README — feature list

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: Video script covers all required sections
    Tool: Bash
    Steps:
      1. Verify docs/catalyst-closeout-video-script.md exists
      2. Verify sections: Structure, Talking Points, Demo Script, Setup, Checklist
      3. Verify demo script has concrete steps (not vague "show the SDK working")
    Expected Result: Actionable video script ready for recording
    Evidence: .sisyphus/evidence/task-3-video-script.txt
  ```

  **Commit**: YES
  - Message: `docs: add Catalyst Close-out Video script and outline`
  - Files: `docs/catalyst-closeout-video-script.md`

---

- [ ] 4. SDK bug fixes from pilot integration (if any)

  **What to do**:
  - This task is **conditional** — it only applies if bugs are discovered during the VESPR pilot integration
  - Review any issues reported during VESPR integration:
    - Session handling edge cases (reconnection, expiry, concurrent sessions)
    - Param parsing issues with specific dApps
    - Error handling gaps
    - Missing or incorrect CIP-30 method behavior
  - For each bug:
    1. Reproduce the issue
    2. Write a failing test
    3. Fix the issue
    4. Verify the test passes
    5. Run full test suite to check for regressions
  - Update `CHANGELOG.md` with fixes
  - If no bugs are found during pilot — mark this task as completed with "No bugs found" evidence

  **Must NOT do**:
  - Do not add new features — bug fixes only
  - Do not break backwards compatibility
  - Do not change the public API without major version bump consideration

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO (depends on pilot feedback)
  - **Parallel Group**: Wave 2
  - **Blocks**: Task 5
  - **Blocked By**: Task 1 (pilot uses integration guide)

  **References**:
  - VESPR integration feedback (external — provided by VESPR team)
  - `lib/src/` — SDK source to fix
  - `test/` — existing tests to extend
  - `CHANGELOG.md` — document fixes

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: All reported bugs fixed (or none found)
    Tool: Bash
    Steps:
      1. Run `flutter test` — all tests pass (including new regression tests)
      2. Run `dart analyze` — zero errors/warnings
      3. Verify CHANGELOG.md updated with fixes (if any)
    Expected Result: All bugs fixed with regression tests, or documented "no bugs found"
    Evidence: .sisyphus/evidence/task-4-bug-fixes.txt

  Scenario: No regressions introduced
    Tool: Bash
    Steps:
      1. Run full test suite
      2. Verify no existing tests broken
    Expected Result: All pre-existing tests still pass
    Evidence: .sisyphus/evidence/task-4-no-regressions.txt
  ```

  **Commit**: YES (if fixes made)
  - Message: `fix: resolve issues found during VESPR pilot integration`
  - Files: `lib/src/`, `test/`, `CHANGELOG.md`

---

- [ ] 5. Final AGENTS.md and CHANGELOG update

  **What to do**:
  - Update AGENTS.md with final project status:
    - Mark all milestones as completed
    - Add final pub.dev package link
    - Add links to Catalyst evidence (report, video) once available
    - Update any architecture details that changed during development
  - Update CHANGELOG.md:
    - Ensure all M3 changes documented
    - Add version bump if bug fixes were published
  - If a new version is warranted (due to bug fixes), run `dart pub publish --dry-run` and document readiness. Actual publishing requires human with pub.dev credentials (same as M2 Task 8).

  **Must NOT do**:
  - Do not remove historical information from AGENTS.md
  - Do not change milestone definitions retroactively

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (after Task 4)
  - **Blocks**: None
  - **Blocked By**: Task 4

  **References**:
  - `AGENTS.md` — current content to update
  - `CHANGELOG.md` — add entries
  - pub.dev package page — link to include

  **Acceptance Criteria**:

  **QA Scenarios**:
  ```
  Scenario: AGENTS.md reflects completed project
    Tool: Bash
    Steps:
      1. Verify AGENTS.md shows all milestones as completed
      2. Verify pub.dev link is present
      3. Verify CHANGELOG.md is up to date
    Expected Result: Final project documentation updated
    Evidence: .sisyphus/evidence/task-5-final-update.txt
  ```

  **Commit**: YES
  - Message: `docs: finalize AGENTS.md and CHANGELOG for project close-out`
  - Files: `AGENTS.md`, `CHANGELOG.md`

---

## Final Verification Wave

> After ALL tasks complete. ALL must approve.

- [ ] F1. **Catalyst Evidence Completeness**
  Verify all Milestone 3 evidence items are accounted for:
  1. Integration guide exists and is comprehensive
  2. Catalyst report template is ready for VESPR team
  3. Close-out video script is ready for VESPR team
  4. All SDK bugs fixed (or documented as none)
  5. Package on pub.dev is latest version
  Output: `Evidence items [5/5] | VERDICT`

- [ ] F2. **Full Test Suite**
  Run `flutter test` — ALL tests must pass. Run `dart analyze` — zero issues. Verify no regressions from M2.
  Output: `Tests [N pass / N fail] | Analyze [PASS/FAIL] | VERDICT`

- [ ] F3. **Documentation Quality**
  Review all docs/ files for: completeness, accuracy against actual SDK API, no placeholder text, actionable guidance. Review AGENTS.md for accuracy. Review README for any updates needed.
  Output: `Docs [N/N complete] | VERDICT`

---

## Commit Strategy

| Task | Commit Message | Key Files |
|------|---------------|-----------|
| 1 | `docs: add comprehensive wallet integration guide` | `docs/integration-guide.md` |
| 2 | `docs: add Catalyst Final Report template` | `docs/catalyst-final-report-template.md` |
| 3 | `docs: add Catalyst Close-out Video script` | `docs/catalyst-closeout-video-script.md` |
| 4 | `fix: resolve issues found during VESPR pilot` | `lib/src/`, `test/`, `CHANGELOG.md` |
| 5 | `docs: finalize AGENTS.md and CHANGELOG for close-out` | `AGENTS.md`, `CHANGELOG.md` |

---

## Success Criteria

### Verification Commands
```bash
dart analyze           # Expected: zero issues
flutter test           # Expected: all tests pass
```

### Final Checklist
- [ ] Integration guide covers complete developer journey
- [ ] Catalyst report template has all required sections
- [ ] Close-out video script has concrete demo steps
- [ ] All known bugs fixed with regression tests
- [ ] AGENTS.md reflects completed project
- [ ] CHANGELOG.md is up to date
- [ ] Package on pub.dev is latest version
- [ ] No VESPR-specific code in this repo
