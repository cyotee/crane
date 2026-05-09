# Aave V4 Test Failure Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve the 253 failing Aave V4 tests reported at the end of the port (commit `0f13fcde`) so the Aave V4 test slice runs cleanly under Crane's main `foundry.toml` profile, or — for any failures rooted in the env (forks, RPC) — accurately categorize and document them so future work has a sharp picture.

**Architecture:** Two mechanical root-cause fixes followed by a discovery pass.
1. **vm.getCode path rewrite.** Every `vm.getCode('src/<path>/<File>.sol:<Contract>')` call still references the *upstream* source path. After the port these contracts live at `contracts/protocols/lending/aave/v4/<path>/<File>.sol`. A one-shot sed pipeline rewrites all 7 call sites. This alone clears the ~236 `vm.getCode: no matching artifact found` failures.
2. **fs_permissions for test output dirs.** Tests that call `vm.createDir`/`vm.writeFile` on `output/reports/deployments/...` paths get blocked even though `foundry.toml` has a `./` `read-write` entry — Foundry's behavior is to require an explicit-prefix entry. Add `./output` and re-test.
3. **Re-run, categorize what remains.** Tasks 1+2 are expected to cascade-clear the bulk of the 253 because each `setUp()` failure was failing every test in the contract that depends on it. Whatever fails after that is either (a) a real test bug, (b) an env requirement we haven't met (fork RPC, deploy-script prebuild), or (c) something else worth its own investigation.

**Tech Stack:** Foundry / Forge, Bash sed, `vm.getCode` cheatcode semantics, `foundry.toml` `fs_permissions`.

**Pre-port baseline reference:** Aave V4 port complete at commit `0f13fcde` (provenance doc in `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md`). Test results recorded there: **205 passed / 253 failed / 0 skipped**.

**Out of scope (do NOT do in this plan):**
- Building Crane-native Repo/Target/Facet/Service/DFPkg wrappers around Aave V4 (separate "wrap phase" effort)
- Dedup against Crane's existing OZ/Solady/WETH (separate brainstorm in progress)
- Fixes that require modifying production source code (only test files + `foundry.toml` here)
- Resolving the macOS-specific `forge test` full-suite crash documented in VENDOR_PROVENANCE.md
- Any fork-RPC fixtures or env wiring that would require external infrastructure

---

## File Structure

### Test files modified by Task 1 (`vm.getCode` path rewrite)

These 4 files contain all 7 `vm.getCode('src/...')` call sites. The sed pipeline targets the whole v4 test tree but only these files match:

- `test/foundry/spec/protocols/lending/aave/v4/scripts/utils/SpokeDeployUtils.sol` — 1 site
- `test/foundry/spec/protocols/lending/aave/v4/deployments/procedures/ProceduresBase.t.sol` — 2 sites
- `test/foundry/spec/protocols/lending/aave/v4/deployments/orchestration/AaveV4TestOrchestration.sol` — 2 sites
- `test/foundry/spec/protocols/lending/aave/v4/deployments/batches/BatchBase.t.sol` — 2 sites

Each site changes from `vm.getCode('src/<path>/<File>.sol:<Contract>')` to `vm.getCode('contracts/protocols/lending/aave/v4/<path>/<File>.sol:<Contract>')`. No other content in those files changes.

### Config files modified by Task 2 (`fs_permissions`)

- `foundry.toml` — add `{ access = "read-write", path = "./output" }` entry inside the existing `fs_permissions = [...]` array. No other change.

### Provenance / docs updated by Task 3 (discovery + record)

- `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md` — replace the existing "Port completion status" pass/fail line with the post-fix numbers; replace the "Aave V4 failure categories" line with the post-Task-3 categorization.

### Optional: Task 4 (conditional)

If Task 3 surfaces a small number of new categories that are mechanically fixable in scope (not fork-RPC, not Crane-native swaps), Task 4 addresses them. Files and code shown only when the failure list is known.

---

## Conventions used by every task

**Bash usage:** Per session memory, never chain commands with `&&`/`||`/`;`. Never use backslash-newline. Shell pipelines `|` are one Bash call — fine. Each shell command = one Bash tool call. Run independent commands in parallel (multiple Bash tool calls in one response).

**Sandbox bypass:** `dangerouslyDisableSandbox: true` ONLY for `git add` and `git commit`. The parent indexedex repo's `.git/modules/.../index.lock` lives outside the sandbox-writable paths and will fail with "Operation not permitted" otherwise.

**Settings files off-limits:** Do NOT modify `.claude/settings.json` or `.claude/settings.local.json`. Do NOT invoke the `update-config` skill. If a sandbox failure persists, escalate as BLOCKED.

**Commit messages:** `fix(aave-v4-tests): <one-line summary>` style. Single-line, no HEREDOC.

**Working directory:** `/Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane`.

---

## Task 1: Rewrite upstream `vm.getCode('src/...')` paths to vendored paths

**Files:**
- Modify: `test/foundry/spec/protocols/lending/aave/v4/scripts/utils/SpokeDeployUtils.sol`
- Modify: `test/foundry/spec/protocols/lending/aave/v4/deployments/procedures/ProceduresBase.t.sol`
- Modify: `test/foundry/spec/protocols/lending/aave/v4/deployments/orchestration/AaveV4TestOrchestration.sol`
- Modify: `test/foundry/spec/protocols/lending/aave/v4/deployments/batches/BatchBase.t.sol`

### Step 1: Inventory call sites (before-state baseline)

Single Bash call:
```
grep -rE "vm\.getCode\('src/" test/foundry/spec/protocols/lending/aave/v4 --include="*.sol"
```

Expected: exactly 7 hits across the 4 files listed above. Record the count and the full list — used in Step 4 to verify nothing leaked.

If the count is not 7 OR if hits appear in files outside the 4 above, STOP and report — the upstream may have evolved since the port and the plan needs adjustment.

### Step 2: Capture a "before" failure baseline (for one targeted file)

Pick one deployment-procedure test that's known to fail with `vm.getCode: no matching artifact found`. Single Bash call:
```
forge test --match-path "test/foundry/spec/protocols/lending/aave/v4/deployments/procedures/**" 2>&1 | tail -30
```

Expected: at least one `vm.getCode: no matching artifact found` failure in the output. This is the canary the rewrite is meant to clear. Record the failing test name(s) for Step 5's verification.

If the test passes (no `vm.getCode` failure), the env may have been fixed already since `0f13fcde` — confirm and skip to Task 2.

### Step 3: Rewrite the paths

Two single-pipeline Bash calls (one per quote style — Aave V4 tests use single quotes, but the double-quoted variant is cheap defense in depth):

Single-quoted form:
```
find test/foundry/spec/protocols/lending/aave/v4 -name "*.sol" -print0 | xargs -0 sed -i '' "s|vm.getCode('src/|vm.getCode('contracts/protocols/lending/aave/v4/|g"
```

Double-quoted form:
```
find test/foundry/spec/protocols/lending/aave/v4 -name "*.sol" -print0 | xargs -0 sed -i '' 's|vm.getCode("src/|vm.getCode("contracts/protocols/lending/aave/v4/|g'
```

### Step 4: Verify no surviving `'src/...'` paths in vm.getCode calls

Single Bash call:
```
grep -rE "vm\.getCode\(['\"]src/" test/foundry/spec/protocols/lending/aave/v4 --include="*.sol"
```

Expected: empty output. If any hits remain, hand-fix with Edit before Step 5.

Cross-check: count the rewritten sites — single Bash call:
```
grep -rE "vm\.getCode\(['\"]contracts/protocols/lending/aave/v4/" test/foundry/spec/protocols/lending/aave/v4 --include="*.sol" | wc -l
```

Expected: 7 (or higher if Task 1's Step 1 baseline saw more sites than expected).

### Step 5: Re-run the canary test to verify the fix

Single Bash call:
```
forge test --match-path "test/foundry/spec/protocols/lending/aave/v4/deployments/procedures/**" 2>&1 | tail -30
```

Expected: the specific `vm.getCode: no matching artifact found` failure(s) recorded in Step 2 are GONE. Other failures may remain (the contract being instantiated may itself fail to deploy for unrelated reasons — those become Task 3 discoveries) but the artifact-lookup failure must be cleared.

If `vm.getCode` failures remain in the output, the rewrite missed something — investigate before continuing.

### Step 6: Commit

Two Bash calls (`dangerouslyDisableSandbox: true` on both):
1. `git add test/foundry/spec/protocols/lending/aave/v4`
2. `git commit -m "fix(aave-v4-tests): retarget vm.getCode paths from upstream src/ to vendored contracts/protocols/lending/aave/v4/"`

Then read-only `git rev-parse HEAD` to report the SHA.

---

## Task 2: Add explicit `output/` write permission to `fs_permissions`

**Files:**
- Modify: `foundry.toml`

### Step 1: Confirm the failure is reproducible

Single Bash call:
```
forge test --match-path "test/foundry/spec/protocols/lending/aave/v4/deployments/utils/Logger.t.sol" 2>&1 | tail -20
```

Expected: a `vm.createDir: path not allowed for write` failure (or `vm.writeFile`/`vm.readFile` variant) referencing a path like `output/reports/deployments/test/`. Confirms the existing `./` `read-write` entry isn't sufficient — Foundry requires the prefix to be explicit.

If the test already passes, skip to Task 3.

### Step 2: Read the current `fs_permissions` block

Single Bash call:
```
grep -E "fs_permissions" foundry.toml -A 12
```

Records the existing array contents so the Edit in Step 3 splices in the right place.

### Step 3: Add the `./output` entry

Use the Edit tool (not sed — the toml array is brittle). Splice a new line into the array. Locate the exact text:
```
    { access = "read-write", path = "./script/output" },
```
and replace with:
```
    { access = "read-write", path = "./script/output" },
    { access = "read-write", path = "./output" },
```

The new line goes immediately after the existing `./script/output` entry (preserves logical grouping — both are deployment-script output dirs).

### Step 4: Re-run the canary test

Single Bash call:
```
forge test --match-path "test/foundry/spec/protocols/lending/aave/v4/deployments/utils/Logger.t.sol" 2>&1 | tail -20
```

Expected: the `vm.createDir`/`vm.writeFile`/`vm.readFile` failure from Step 1 is gone.

If a different fs failure remains (different path needs its own entry), add an additional `fs_permissions` line for that path and rerun. Cap at 3 attempts before escalating — if multiple unrelated paths need permissions, surface the list for human review.

### Step 5: Commit

Two Bash calls (`dangerouslyDisableSandbox: true` on both):
1. `git add foundry.toml`
2. `git commit -m "fix(aave-v4-tests): allow read-write on ./output for deployment-procedure tests"`

---

## Task 3: Re-run full Aave V4 test slice and categorize remaining failures

**Files:**
- Modify: `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md`

### Step 1: Full Aave V4 test run

Single Bash call (long-running — Aave V4 slice is hundreds of tests; allow several minutes):
```
forge test --match-path "test/foundry/spec/protocols/lending/aave/v4/**" 2>&1 | tee "$TMPDIR/aave-v4-tests.log" | tail -60
```

Record total passed / failed / skipped counts. Compare with the pre-Task-1 baseline (205 passed / 253 failed / 0 skipped).

Expected: pass count rises substantially. The 236 `vm.getCode` failures should be gone; the 1 `vm.createDir` failure should be gone; many tests in the same contracts that were failing because `setUp()` failed first should now run and pass.

### Step 2: Categorize remaining failures

Single Bash call to enumerate failure messages:
```
grep -E "^\[FAIL.*\]" "$TMPDIR/aave-v4-tests.log" | sort -u
```

Plus single Bash call for the underlying error reasons:
```
grep -E "(\[FAIL.*\]|Error:|revert:|panic)" "$TMPDIR/aave-v4-tests.log" | head -80
```

Group the remaining failures by root cause. Use these categories explicitly:
- **(A) Real test bugs** — the test logic itself is wrong (e.g., assumes upstream-specific behavior that the port broke)
- **(B) Env: fork-RPC required** — test calls `vm.createFork`, requires a `MAINNET_RPC_URL`-type env var, or expects to fork mainnet/Base/etc.
- **(C) Env: pre-built artifacts** — leftover `vm.getCode` calls referencing contracts whose path wasn't covered by Task 1 (e.g., upstream relative paths in vendored deps that Task 1 didn't catch)
- **(D) Env: fs_permissions** — additional paths beyond `./output` that need permission entries
- **(E) Cascading** — tests that fail because a setUp() they share with other tests still fails for a reason in (A)-(D)
- **(F) Other** — anything that doesn't fit above; surface verbatim for human triage

Produce a count per category. Save the categorized list — used in Step 3 and to decide whether Task 4 is needed.

### Step 3: Update provenance doc with new numbers and categorization

Use the Edit tool. Locate the existing "Port completion status" section in `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md` and replace these two lines:
```
- Aave V4 test results: 205 passed / 253 failed / 0 skipped (run isolated with FOUNDRY_SOLC=0.8.34 --offline)
- Aave V4 failure categories: vm.getCode artifact lookup (no pre-built artifacts in Crane env), vm.createDir write-permission restriction — all env-dependent, not code bugs
```

with the post-fix values, AND append a new section immediately below:
```markdown
## Aave V4 test-fix pass (commit <Task 1 SHA>..<Task 3 SHA>)

- vm.getCode paths retargeted from `src/...` to `contracts/protocols/lending/aave/v4/...` (7 call sites across 4 files)
- foundry.toml fs_permissions extended with `./output` read-write
- Post-fix Aave V4 test slice: <X passed / Y failed / Z skipped>

### Remaining failure categories (post-fix)

| Category | Count | Example test | Recommended next step |
|---|---|---|---|
| <fill in from Step 2> | ... | ... | ... |
```

Substitute actual values everywhere `<...>` appears.

### Step 4: Decide whether Task 4 is needed

After the doc update, look at the categories table. Task 4 is warranted ONLY if:
- There is a category (A) or (C) or (D) entry with ≤ 5 failures AND a clear mechanical fix path

Task 4 is NOT warranted if:
- All remaining failures are category (B) (env: fork-RPC) — those need infrastructure decisions
- The remaining failures are category (F) (other) — those need human triage
- The category (A) bugs are non-trivial (cross-file state, require behavior reasoning)

If Task 4 is not warranted, the implementer reports DONE and the plan ends with Task 3's commit. If Task 4 is warranted, the implementer should report DONE_WITH_CONCERNS and include the specific failure list — the controller then writes a focused Task 4 with the actual fixes inline (do NOT write Task 4 speculatively in this plan).

### Step 5: Commit

Two Bash calls (`dangerouslyDisableSandbox: true` on both):
1. `git add docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md`
2. `git commit -m "docs(aave-v4): record post-test-fix pass/fail and remaining failure categories"`

---

## Self-review notes (for the executing agent)

- Tasks 1 and 2 are independent — they touch disjoint files. They could in principle be done in parallel by the same implementer, but for review clarity each gets its own commit. Don't bundle them.
- Task 3's value is the categorization, not the doc update — if Task 3 finds zero remaining failures, that's a clean "all passing" record. The provenance doc is updated either way.
- The cascade-clear hypothesis (fixing setUp() chains un-fails many downstream tests) is testable in Task 3's output. If pass count rises by 200+ from the two fixes, the hypothesis is confirmed. If it rises only modestly, there are real bugs underneath that Task 4 must address.
- Task 4 is intentionally not pre-written. Conditional tasks specified in advance lead to either (a) over-scoping (fixing things that turn out not to be problems) or (b) wrong-tool selection (the right fix depends on the specific failure shape). Reactive Task 4 is the right discipline.
- Per AGENTS.md, the alternative to fixing `vm.getCode` test paths would be to add a `src/` symlink or remapping aliasing upstream paths to the vendored tree. **Don't do that.** It hides the port location, breaks the @crane/-rooted convention, and would surprise anyone reading the test code.
