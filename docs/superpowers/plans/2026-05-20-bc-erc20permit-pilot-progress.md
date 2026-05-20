# BC ERC20Permit Pilot — Progress Summary

**Date:** 2026-05-20
**Plan:** `docs/superpowers/plans/2026-05-20-bc-erc20permit-pilot.md`
**Spec:** `PROMPT.md`
**Branch:** `main` (user explicitly consented to implement on main)

## Status

- **All 8 tasks complete and committed.** Pilot implementation done.
- Local-mock suite: 9/9 passing.
- Fork suite: 2/2 passing against live BattleChain testnet (chain 627).
- Full Crane test suite excluding fork: 75 pre-existing failures (all Aave V3.6/V4 `--ffi` gated); zero regressions attributable to the pilot.
- Total commits: 9.

## Commits Landed (newest first)

```
1b0aa031 style(pilot): apply forge fmt to BC ERC20Permit pilot files
5c269f62 test(pilot): add BC ERC20Permit fork test against testnet
a96906b8 test(pilot): add BC ERC20Permit local-mock ERC20 + permit tests
3793d6cf test(pilot): add BC ERC20Permit local-mock agreement + adoption tests
d4e8b1db test(pilot): add BC ERC20Permit local-mock deploy + lineage tests
4743ffca feat(crane): add Script_Pilot_BC_ERC20Permit deploy script
53d00e23 feat(crane): add InitBcService BattleChain bootstrap library
e0d90888 chore(pilot): add battlechain-lib mocks remapping; remove non-BC pilot
```

## Files Added / Modified

### New files (all four pilot artifacts in place)
- `contracts/InitBcService.sol` — BC-aware bootstrap library (parallel to `InitDevService`)
- `scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol` — BCScript subclass
- `test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol` — 9 local-mock tests, all passing
- `test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol` — 2 fork tests, both passing on live testnet

### Config changes
- `remappings.txt` — added two remappings:
  - `battlechain-lib-mocks/=lib/battlechain-lib/test/mocks/`
  - `lib/battlechain-lib/:src/=lib/battlechain-lib/src/` (context-scoped so the vendored mock file can resolve its `src/types/AgreementTypes.sol` import)

### File removed
- `test/foundry/spec/pilot/Pilot_ERC20Permit_Deploy.t.sol` — replaced by the BC variants

## Test Results

**Local-mock suite:** `forge test --match-path "test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol"`
- `test_coreFactory_deployedViaBcDeployer` — PASS
- `test_diamondFactory_isWiredToCoreFactory` — PASS
- `test_proxy_addressIsDeterministic` — PASS
- `test_agreementDetails_listCoreFactory_withChildScopeAll` — PASS
- `test_agreementFactory_calledWithExpectedDetails` — PASS
- `test_adoption_andCommitmentWindow` — PASS
- `test_proxy_erc20Metadata` — PASS
- `test_proxy_domainSeparator_nonZero_nonces_startAtZero` — PASS
- `test_proxy_permitSignature_updatesAllowanceAndNonce` — PASS

Result: **9 passed; 0 failed; 0 skipped** in ~27 ms.

**Fork suite:** `forge test --match-path "test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol"`
- `test_fork_endToEnd_deployAndScopeIsCorrect` — PASS
- `test_fork_permitSignature_works` — PASS

Result: **2 passed; 0 failed; 0 skipped** in ~6.2 s against the public testnet RPC.

## Design Deviations From Spec / Plan

These adjustments were made during implementation; PROMPT.md and the plan file still reflect the original design language.

1. **`coreFactory.deployPackageWithArgs` return type** — the API returns `IDiamondFactoryPackage`, not `address`. Script wraps the call in `address(...)`. Plan said the assignment was direct.
2. **Diamond-factory getter name** — Crane exposes `diamondPackageFactory()` (not `getDiamondPackageFactory()`). Test #5 updated accordingly.
3. **Factory-owner address in tests** — Plan/spec implied the factory owner could be `vm.addr(0xA11CE)` (the EIP-712 signer). In practice, the bootstrap library makes facet-deploy calls from `msg.sender`, which is the test contract — so the test contract MUST be the factory owner. Tests now call `_runDeploy(address(this), owner)` (owner = recipient/signer only).
4. **`requestAttackMode` moved out of `_runDeploy`** — original design had it inside `_runDeploy` gated on `_isBattleChain()`. That breaks the fork test because the real on-chain `AttackRegistry.requestUnderAttack` requires authorization our test contract doesn't have. Moved to `run()` (broadcast path only). Tests calling `_runDeploy` no longer trigger it.
5. **Fork test child-coverage assertions** — `battlechain-lib@0.1.2`'s `IAttackRegistry` interface does NOT expose `getAgreementForContract` or `isTopLevelContractUnderAttack` (those exist only on the live contract beyond the interface surface). Fork test now verifies coverage via `IAgreement.isContractInScope`, `IAgreement.getBattleChainScopeAddresses`, and `IBCSafeHarborRegistry.getAgreement` — all of which ARE in the v0.1.2 interfaces. Lineage-child coverage of diamond factory / package / proxy is moved to the manual block-explorer step in the pilot "done" checklist.
6. **Pre-existing Crane natspec bug fixed inline** — `contracts/access/ERC8023/MultiStepOwnableViewTarget.sol` had four `@inheritdoc IMultiStepOwnable` tags but the contract inherits `IMultiStepOwnableView`. Surfaced by `forge clean`. Edited the file in the working tree (file is **untracked** so the fix lives unstaged; it will travel with whoever first commits that file).

## Working-Tree State at Interrupt

```
M .cspell/custom-dictionary.txt        (Attackable / attackable / Indexedex — from brainstorming)
M PROMPT.md                            (final spec doc, not yet committed)
M contracts/access/ERC8023/MultiStepOwnableViewTarget.sol  (natspec fix, file is untracked)
?? contracts/access/ERC8023/IMultiStepOwnableView.sol      (pre-existing Crane WIP, not mine)
?? contracts/access/ERC8023/MultiStepOwnableViewFacet.sol  (pre-existing Crane WIP, not mine)
?? contracts/interfaces/IMultiStepOwnableView.sol          (pre-existing Crane WIP, not mine)
?? docs/superpowers/plans/2026-05-20-bc-erc20permit-pilot.md             (the plan file)
?? docs/superpowers/plans/2026-05-20-bc-erc20permit-pilot-progress.md    (this file)
```

## Task 8 — Final Acceptance Results

| Step | Outcome |
| --- | --- |
| 1. `forge build` | exit 0, no errors |
| 2. Local-mock suite | 9/9 passed in ~25 ms |
| 3. Fork suite | 2/2 passed in ~1.2 s against public BattleChain testnet |
| 4. Full Crane suite (excl. fork) | 7984 passed / 75 failed / 28 skipped of 8087. **All 71 failing suites are in `aave/3.6/` or `aave/v4/` trees and fail with `vm.ffi: FFI is disabled` — environmental, not regressions.** Zero failing suites touch pilot files. |
| 5. `forge fmt --check` | Three pilot files needed reformatting; applied via `forge fmt` and committed as `1b0aa031`. The pre-existing formatting drift in unrelated Crane files (FacetRegistryTarget, ECDSA, SafeERC20, etc.) is out of scope for the pilot PR. |
| 6. Broadcast smoke run | Optional. Deferred — requires a `battlechain` cast keystore that's not present in this environment. |

The 75 failures are all in Aave V3.6/V4 suites that require `--ffi` (a flag we deliberately don't enable). None touch the pilot files. The local-mock and fork suites both pass in isolation. **Task 8 complete; pilot implementation done.**

## How to Resume

```bash
cd /Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane

# Quick re-verification (Task 8 Steps 1–3):
forge build
forge test --match-path "test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol" -vv
forge test --match-path "test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol" -vv

# Full suite excluding fork:
forge test --no-match-path "test/foundry/fork/**"

# Lint:
forge fmt --check
```

Note: `forge test` panics in macOS sandbox (`SCDynamicStore` crash inside foundry's HTTP-client proxy detection). Run with `dangerouslyDisableSandbox: true` if invoking through Claude Bash tool. From a normal terminal it works fine.

## Notable Decisions From Brainstorming (for reference)

- **Agreement scope shape:** coarse — single `BcAccount` for the Create3Factory with `ChildContractScope.All`. All descendants covered through lineage. No per-deploy agreement updates needed.
- **Test environment:** both local-mock and forked-testnet test suites.
- **Mock source:** reuse `battlechain-lib`'s `test/mocks/MockBCInfra.sol` via remapping. Do not write custom mocks.
- **Crane integration seam:** new `InitBcService` library parallel to `InitDevService`; existing `initEnv` untouched.
