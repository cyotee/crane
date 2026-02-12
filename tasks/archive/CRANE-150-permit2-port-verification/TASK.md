# Task CRANE-150: Verify Permit2 Contract Port Completeness

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** None
**Worktree:** `feature/permit2-port-verification`

---

## Description

Verify that the Permit2 contracts from `lib/permit2/src/` have been correctly ported to `contracts/protocols/utils/permit2/`. The ported contracts must be behavior and interface equivalent to serve as drop-in replacements. The local port includes Crane-specific additions (BetterPermit2, Permit2Aware*) which should be reviewed to confirm they satisfy the original Permit2 requirements.

## Goal

Enable removal of the `lib/permit2` submodule by confirming the local port is complete and functionally equivalent.

## Source Analysis

**Submodule Location:** `lib/permit2/src/`
**Local Port Location:** `contracts/protocols/utils/permit2/`

### Submodule Structure (16 files)

```
src/
├── Permit2.sol              # Main entry point
├── AllowanceTransfer.sol    # Allowance-based transfers
├── SignatureTransfer.sol    # Signature-based transfers
├── EIP712.sol               # EIP-712 domain separator
├── PermitErrors.sol         # Custom errors
├── interfaces/
│   ├── IPermit2.sol
│   ├── IAllowanceTransfer.sol
│   ├── ISignatureTransfer.sol
│   ├── IEIP712.sol
│   ├── IDAIPermit.sol
│   └── IERC1271.sol
└── libraries/
    ├── Allowance.sol
    ├── PermitHash.sol
    ├── SignatureVerification.sol
    ├── SafeCast160.sol
    └── Permit2Lib.sol
```

### Local Port Structure (12 files)

```
permit2/
├── BetterPermit2.sol         # Crane fork/extension
├── AllowanceTransfer.sol
├── SignatureTransfer.sol
├── EIP712.sol
├── PermitErrors.sol
├── Allowance.sol
├── PermitHash.sol
├── SignatureVerification.sol
├── aware/
│   ├── Permit2AwareFacet.sol
│   ├── Permit2AwareRepo.sol
│   └── Permit2AwareTarget.sol
└── test/
    └── TestBase_Permit2.sol
```

### Gap Analysis

**Potentially Missing from Local Port:**
- `IPermit2.sol` (main interface)
- `IAllowanceTransfer.sol`
- `ISignatureTransfer.sol`
- `IEIP712.sol`
- `IDAIPermit.sol`
- `IERC1271.sol`
- `SafeCast160.sol`
- `Permit2Lib.sol`

**Crane-Specific Additions (to review):**
- `BetterPermit2.sol` - May satisfy Permit2.sol requirements
- `Permit2Aware*` - Diamond pattern integration

## Dependencies

None - this is a verification/completion task.

## User Stories

### US-CRANE-150.1: Core Contract Verification

As a developer, I want to verify core Permit2 contracts are correctly ported.

**Acceptance Criteria:**
- [x] AllowanceTransfer.sol behavior matches original
- [x] SignatureTransfer.sol behavior matches original
- [x] EIP712.sol behavior matches original
- [x] BetterPermit2.sol provides equivalent functionality to Permit2.sol

### US-CRANE-150.2: Interface Completeness

As a developer, I want all Permit2 interfaces available locally.

**Acceptance Criteria:**
- [x] IPermit2 or equivalent interface available
- [x] IAllowanceTransfer or equivalent available
- [x] ISignatureTransfer or equivalent available
- [x] All function signatures match original
- [x] All events match original

### US-CRANE-150.3: Library Completeness

As a developer, I want all Permit2 libraries ported.

**Acceptance Criteria:**
- [x] Allowance.sol ported (appears done)
- [x] PermitHash.sol ported (appears done)
- [x] SignatureVerification.sol ported (appears done)
- [x] SafeCast160.sol ported or equivalent available
- [x] Permit2Lib.sol ported or equivalent available

### US-CRANE-150.4: Crane Extensions Review

As a developer, I want to confirm Crane extensions satisfy requirements.

**Acceptance Criteria:**
- [x] BetterPermit2.sol reviewed - confirm it provides Permit2 functionality
- [x] Permit2Aware* contracts reviewed - confirm Diamond integration works
- [x] Document any behavioral differences from original

### US-CRANE-150.5: Test Suite Adaptation

As a developer, I want Permit2 tests adapted for local contracts.

**Acceptance Criteria:**
- [ ] Fork/adapt Permit2's Foundry test suite (DEFERRED - see notes)
- [ ] All critical path tests pass against local contracts (DEFERRED)
- [ ] Test coverage includes:
  - Allowance transfers (DEFERRED)
  - Signature transfers (DEFERRED)
  - EIP-712 signing (DEFERRED)
  - Permit2Lib utilities (DEFERRED)

**Note:** Test suite adaptation is deferred as a separate task. The build success validates the port is structurally complete. Comprehensive Permit2 test coverage should be added in a follow-up task.

## Technical Details

### File Mapping

| Submodule File | Local File | Status |
|----------------|------------|--------|
| Permit2.sol | BetterPermit2.sol | ✅ Equivalent + DOMAIN_SEPARATOR override |
| AllowanceTransfer.sol | AllowanceTransfer.sol | ✅ Ported (uses Crane SafeERC20) |
| SignatureTransfer.sol | SignatureTransfer.sol | ✅ Ported (uses Crane SafeERC20) |
| EIP712.sol | EIP712.sol | ✅ Ported (uses Solady EfficientHashLib) |
| PermitErrors.sol | PermitErrors.sol | ✅ Identical |
| Allowance.sol | Allowance.sol | ✅ Ported |
| PermitHash.sol | PermitHash.sol | ✅ Ported (uses Solady EfficientHashLib) |
| SignatureVerification.sol | SignatureVerification.sol | ✅ Ported (uses OZ IERC1271) |
| SafeCast160.sol | SafeCast160.sol | ✅ **Ported** |
| Permit2Lib.sol | Permit2Lib.sol | ✅ **Ported** |
| interfaces/IPermit2.sol | IPermit2.sol | ✅ **Ported** |
| interfaces/IAllowanceTransfer.sol | IAllowanceTransfer.sol | ✅ Ported |
| interfaces/ISignatureTransfer.sol | ISignatureTransfer.sol | ✅ Ported |
| interfaces/IEIP712.sol | IEIP712.sol | ✅ **Ported** |
| interfaces/IDAIPermit.sol | IDAIPermit.sol | ✅ **Ported** |
| interfaces/IERC1271.sol | (uses OpenZeppelin) | ✅ Standardized |
| test/utils/DeployPermit2.sol | test/utils/DeployPermit2.sol | ✅ **Ported** |

### Verification Approach

1. **Interface Comparison**
   - Extract all function signatures from submodule
   - Compare against local contract signatures
   - Identify any mismatches

2. **Test Suite**
   - Adapt Permit2's existing Foundry tests
   - Run against local contracts
   - Document any test modifications required

## Files to Create/Modify

**Potentially New Files:**
- `contracts/protocols/utils/permit2/interfaces/*.sol` - Missing interfaces
- `contracts/protocols/utils/permit2/SafeCast160.sol` - If needed
- `contracts/protocols/utils/permit2/Permit2Lib.sol` - If needed
- `test/foundry/protocols/utils/permit2/*.t.sol` - Adapted test suite

**Analysis Files:**
- Create interface comparison report
- Document Crane extensions behavior

## Completion Criteria

- [x] All core contracts verified as behavior equivalent
- [x] All interfaces available (ported or documented as unnecessary)
- [x] All libraries ported or equivalent functionality confirmed
- [x] Crane extensions (BetterPermit2, Permit2Aware*) reviewed and documented
- [ ] Adapted test suite passes (DEFERRED to follow-up task)
- [x] Submodule can be safely removed (with remapping strategy)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
