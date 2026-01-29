# Task CRANE-148: Verify Aerodrome Contract Port Completeness

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** None
**Worktree:** `feature/aerodrome-port-verification`

---

## Description

Verify that all contracts from `lib/aerodrome-contracts` have been correctly ported to `contracts/protocols/dexes/aerodrome/v1/`. The ported contracts must be behavior and interface equivalent to serve as drop-in replacements for the original submodule. Upon successful verification, the submodule can be removed.

## Goal

Enable removal of the `lib/aerodrome-contracts` submodule by confirming the local port is complete and functionally equivalent.

## Source Analysis

**Submodule Location:** `lib/aerodrome-contracts/contracts/`
**Local Port Location:** `contracts/protocols/dexes/aerodrome/v1/`

### Submodule Structure (62 files)
```
contracts/
├── Pool.sol, PoolFees.sol
├── Router.sol
├── VotingEscrow.sol
├── Minter.sol, Voter.sol, Aero.sol
├── RewardsDistributor.sol
├── factories/ (GaugeFactory, PoolFactory, VotingRewardsFactory)
├── gauges/ (Gauge.sol, LeafGauge.sol)
├── governance/ (Governor.sol, VetoGovernor.sol)
├── interfaces/ (28 interface files)
├── libraries/ (Clones, SafeERC20Namer, etc.)
├── rewards/ (Reward.sol, VotingReward.sol, FeesVotingReward.sol, BribeVotingReward.sol)
```

### Local Structure (73 files)
```
v1/
├── stubs/ - Stubbed implementations
├── interfaces/ - Ported interfaces
├── services/ - Crane-specific service wrappers (DOCUMENT)
├── aware/ - Crane-specific awareness contracts (DOCUMENT)
├── test/ - Test utilities
```

## User Stories

### US-CRANE-148.1: Core Contract Verification

As a developer, I want to verify core Aerodrome contracts are correctly ported.

**Acceptance Criteria:**
- [ ] Pool.sol behavior matches original
- [ ] PoolFees.sol behavior matches original
- [ ] Router.sol behavior matches original
- [ ] All function signatures identical to original

### US-CRANE-148.2: Governance Contract Verification

As a developer, I want to verify governance contracts are correctly ported.

**Acceptance Criteria:**
- [ ] VotingEscrow.sol behavior matches original
- [ ] Voter.sol behavior matches original
- [ ] Minter.sol behavior matches original
- [ ] Governor.sol behavior matches original

### US-CRANE-148.3: Rewards System Verification

As a developer, I want to verify reward contracts are correctly ported.

**Acceptance Criteria:**
- [ ] RewardsDistributor.sol behavior matches original
- [ ] Gauge.sol behavior matches original
- [ ] VotingReward.sol and variants behavior match original

### US-CRANE-148.4: Factory Verification

As a developer, I want to verify factory contracts are correctly ported.

**Acceptance Criteria:**
- [ ] PoolFactory.sol behavior matches original
- [ ] GaugeFactory.sol behavior matches original
- [ ] VotingRewardsFactory.sol behavior matches original

### US-CRANE-148.5: Interface Completeness

As a developer, I want all interfaces correctly ported.

**Acceptance Criteria:**
- [ ] All 28 interface files from submodule have local equivalents
- [ ] All function signatures match
- [ ] All events match
- [ ] All custom errors match

### US-CRANE-148.6: Test Suite Adaptation

As a developer, I want Aerodrome tests adapted to verify the port.

**Acceptance Criteria:**
- [ ] Fork/adapt Aerodrome's test suite
- [ ] All critical path tests pass against local contracts
- [ ] Tests run against Base mainnet fork
- [ ] Document any test modifications required

### US-CRANE-148.7: Document Crane Additions

As a developer, I want Crane-specific additions documented.

**Acceptance Criteria:**
- [ ] Document all files in `services/` directory
- [ ] Document all files in `aware/` directory
- [ ] Note that these are Crane extensions, not part of original Aerodrome
- [ ] Create README.md in aerodrome/v1/ explaining structure

## Technical Details

### Verification Approach

1. **Interface Comparison**
   - Extract all function signatures from submodule contracts
   - Compare against local contract signatures
   - Report any mismatches

2. **Event/Error Comparison**
   - Compare all events between versions
   - Compare all custom errors between versions

3. **Test Suite**
   - Adapt Aerodrome's existing tests
   - Run against local contracts
   - Use Base mainnet fork for realistic state

### Key Contracts to Verify

| Contract | Priority | Notes |
|----------|----------|-------|
| Pool.sol | Critical | Core AMM logic |
| Router.sol | Critical | User-facing swap interface |
| VotingEscrow.sol | High | veAERO mechanics |
| Voter.sol | High | Gauge voting |
| Gauge.sol | High | LP staking rewards |
| PoolFactory.sol | Medium | Pool deployment |

### Expected Differences

The local port may have:
- Different import paths (adjusted for monorepo structure)
- Pragma version updates (if needed)
- Crane-specific extensions in `services/` and `aware/`

These differences are acceptable as long as external behavior matches.

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/aerodrome/v1/README.md` - Structure documentation
- `test/foundry/protocols/aerodrome/v1/*.t.sol` - Adapted test suite

**Analysis Files:**
- Create interface comparison report
- Create test coverage report

## Completion Criteria

- [ ] All core contracts verified as behavior equivalent
- [ ] All interfaces verified as signature equivalent
- [ ] Adapted test suite passes
- [ ] Crane additions documented
- [ ] README.md created explaining local structure
- [ ] Submodule can be safely removed

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
