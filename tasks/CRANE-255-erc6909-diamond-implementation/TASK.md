# Task CRANE-255: Diamond Implementation of ERC-6909 Multi-Token Standard

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** None
**Worktree:** `feature/CRANE-255-erc6909-diamond-implementation`

---

## Description

Implement ERC-6909 (Minimal Multi-Token Interface) as a full Repo->Target->Facet Diamond implementation. ERC-6909 is a minimal multi-token standard (like a simplified ERC-1155) that manages multiple fungible token types identified by `uint256 id`. Each token ID has independent balances, allowances, and metadata. The implementation includes three facets (Core, Metadata, MintBurn), a Diamond Factory Package for deployment, and comprehensive tests proving token ID isolation.

The ERC-165 `supportsInterface` is handled by the Diamond Factory's default facets (ERC165Facet), so this implementation does NOT need to implement IERC165 itself -- only declare the correct interface IDs in `facetInterfaces()`.

## ERC-6909 Specification Reference

**EIP:** https://eips.ethereum.org/EIPS/eip-6909
**Core Interface ID:** `0x0f632fb3`

### Core Interface (IERC6909)

```solidity
interface IERC6909 {
    event Transfer(address caller, address indexed sender, address indexed receiver, uint256 indexed id, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);
    event OperatorSet(address indexed owner, address indexed spender, bool approved);

    function balanceOf(address owner, uint256 id) external view returns (uint256 amount);
    function allowance(address owner, address spender, uint256 id) external view returns (uint256 amount);
    function isOperator(address owner, address spender) external view returns (bool status);
    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);
    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);
    function approve(address spender, uint256 id, uint256 amount) external returns (bool);
    function setOperator(address spender, bool approved) external returns (bool);
}
```

### Metadata Extension (IERC6909Metadata)

```solidity
interface IERC6909Metadata {
    function name(uint256 id) external view returns (string memory);
    function symbol(uint256 id) external view returns (string memory);
    function decimals(uint256 id) external view returns (uint8);
}
```

### Token Supply Extension (IERC6909TokenSupply) — included in core Repo

```solidity
interface IERC6909TokenSupply {
    function totalSupply(uint256 id) external view returns (uint256);
}
```

## Dependencies

None — this is a new token standard implementation.

## User Stories

### US-CRANE-255.1: ERC6909Repo — Storage Layer

As a developer, I want a Repo library that manages ERC-6909 state using the Diamond storage pattern so that all facets can share state safely.

**Acceptance Criteria:**
- [ ] `ERC6909Repo` library with deterministic storage slot `keccak256(abi.encode("eip.erc.6909"))`
- [ ] Storage struct includes:
  - `mapping(address owner => mapping(uint256 id => uint256 balance)) balanceOf`
  - `mapping(address owner => mapping(address spender => mapping(uint256 id => uint256 allowance))) allowances`
  - `mapping(address owner => mapping(address operator => bool approved)) operators`
  - `mapping(uint256 id => uint256 supply) totalSupply`
  - `mapping(uint256 id => string name) names`
  - `mapping(uint256 id => string symbol) symbols`
  - `mapping(uint256 id => uint8 decimals) tokenDecimals`
- [ ] Dual function signatures (explicit storage pointer + default slot convenience)
- [ ] Internal `_transfer`, `_transferFrom`, `_approve`, `_setOperator`, `_mint`, `_burn` functions
- [ ] Proper error handling with custom errors (e.g., `InsufficientBalance`, `InsufficientAllowance`, `InvalidReceiver`, `InvalidSender`)
- [ ] Events emitted per ERC-6909 spec: `Transfer`, `Approval`, `OperatorSet`
- [ ] `_setTokenMetadata(uint256 id, string name, string symbol, uint8 decimals)` for metadata
- [ ] Operator bypass in `_transferFrom` (operators skip allowance checks per spec)
- [ ] `totalSupply` tracking updated on mint/burn

### US-CRANE-255.2: IERC6909 Interface + Events + Errors

As a developer, I want clean Solidity interfaces matching the ERC-6909 spec so that the Facet correctly declares its supported interface IDs.

**Acceptance Criteria:**
- [ ] `IERC6909.sol` — core interface with all 7 functions
- [ ] `IERC6909Events.sol` — `Transfer`, `Approval`, `OperatorSet` events
- [ ] `IERC6909Errors.sol` — custom errors for invalid operations
- [ ] `IERC6909Metadata.sol` — metadata extension interface (name, symbol, decimals per ID)
- [ ] `IERC6909TokenSupply.sol` — totalSupply extension interface
- [ ] Interface IDs match spec: core = `0x0f632fb3`

### US-CRANE-255.3: ERC6909Target — Logic Layer (Core)

As a developer, I want a Target contract that implements the core ERC-6909 interface by delegating to the Repo.

**Acceptance Criteria:**
- [ ] `ERC6909Target` implements `IERC6909` and `IERC6909TokenSupply`
- [ ] All functions delegate to `ERC6909Repo`
- [ ] Functions marked `virtual` for inheritance
- [ ] `transfer` uses `msg.sender` as caller
- [ ] `transferFrom` checks operator status OR per-token allowance
- [ ] `totalSupply(uint256 id)` returns per-token-ID supply

### US-CRANE-255.4: ERC6909Facet — Core Interface Facet

As a developer, I want a Facet that exposes the core ERC-6909 interface + totalSupply in the Diamond pattern.

**Acceptance Criteria:**
- [ ] `ERC6909Facet` extends `ERC6909Target` and implements `IFacet`
- [ ] `facetName()` returns `"ERC6909Facet"`
- [ ] `facetInterfaces()` returns `[type(IERC6909).interfaceId, type(IERC6909TokenSupply).interfaceId]`
- [ ] `facetFuncs()` returns all 8 function selectors (7 core + totalSupply)
- [ ] `facetMetadata()` aggregates name, interfaces, and functions

### US-CRANE-255.5: ERC6909MetadataTarget + ERC6909MetadataFacet — Metadata Extension

As a developer, I want a separate Metadata Facet conforming to the IERC6909Metadata interface ID.

**Acceptance Criteria:**
- [ ] `ERC6909MetadataTarget` implements `IERC6909Metadata`
- [ ] Delegates to `ERC6909Repo` for name/symbol/decimals per token ID
- [ ] `ERC6909MetadataFacet` extends `ERC6909MetadataTarget` and implements `IFacet`
- [ ] `facetInterfaces()` returns `[type(IERC6909Metadata).interfaceId]`
- [ ] `facetFuncs()` returns 3 selectors: `name(uint256)`, `symbol(uint256)`, `decimals(uint256)`

### US-CRANE-255.6: ERC6909MintBurnTarget + ERC6909MintBurnFacet — Testing Facet

As a developer, I want a Mint/Burn Facet for testing that also allows setting per-token-ID metadata.

**Acceptance Criteria:**
- [ ] `ERC6909MintBurnTarget` with:
  - `mint(address to, uint256 id, uint256 amount)` — mints tokens
  - `burn(address from, uint256 id, uint256 amount)` — burns tokens
  - `setTokenMetadata(uint256 id, string name, string symbol, uint8 decimals)` — sets metadata
- [ ] `ERC6909MintBurnFacet` extends `ERC6909MintBurnTarget` and implements `IFacet`
- [ ] `facetFuncs()` returns all 3 selectors
- [ ] This facet is NOT included in production DFPkg; only in the test DFPkg

### US-CRANE-255.7: ERC6909DFPkg — Diamond Factory Package

As a developer, I want a DFPkg that deploys an ERC-6909 Diamond proxy with all three facets for testing.

**Acceptance Criteria:**
- [ ] `IERC6909DFPkg` interface with `PkgInit` and `PkgArgs` structs
- [ ] `PkgInit` holds references to all 3 facets: `erc6909Facet`, `metadataFacet`, `mintBurnFacet`
- [ ] `PkgArgs` includes initial token configurations (array of `{id, name, symbol, decimals, supply, recipient}`)
- [ ] `facetCuts()` returns 3 `FacetCut` entries (one per facet)
- [ ] `facetInterfaces()` aggregates interfaces from all 3 facets
- [ ] `initAccount()` initializes metadata and mints initial supplies per `PkgArgs`
- [ ] `calcSalt()` deterministic based on token configs
- [ ] `deploy()` convenience function

### US-CRANE-255.8: Comprehensive Tests — Functionality + Token ID Isolation

As a developer, I want tests that prove all ERC-6909 functionality works correctly and that operations on one token ID do not affect another.

**Acceptance Criteria:**
- [ ] **IFacet tests** for all 3 facets (using TestBase_IFacet pattern):
  - `ERC6909Facet_IFacet.t.sol`
  - `ERC6909MetadataFacet_IFacet.t.sol`
  - `ERC6909MintBurnFacet_IFacet.t.sol`
- [ ] **Core functionality tests** (`ERC6909DFPkg_IERC6909.t.sol`):
  - `test_transfer` — basic transfer reduces sender balance, increases receiver balance
  - `test_transferFrom_withAllowance` — spender uses per-token-ID allowance
  - `test_transferFrom_withOperator` — operator bypasses allowance
  - `test_approve` — sets per-token-ID allowance, emits Approval
  - `test_setOperator` — sets cross-token operator, emits OperatorSet
  - `test_balanceOf` — returns correct per-ID balance
  - `test_allowance` — returns correct per-ID allowance
  - `test_isOperator` — returns correct operator status
  - `test_totalSupply` — returns correct per-ID supply
- [ ] **Revert tests:**
  - `test_transfer_revert_InsufficientBalance`
  - `test_transferFrom_revert_InsufficientAllowance` (when not operator)
  - `test_transfer_revert_InvalidReceiver` (address(0))
- [ ] **Metadata tests:**
  - `test_name_returnsPerIdName`
  - `test_symbol_returnsPerIdSymbol`
  - `test_decimals_returnsPerIdDecimals`
- [ ] **Token ID isolation tests** (CRITICAL — the key requirement):
  - `test_transfer_doesNotAffectOtherTokenId` — transfer token ID 1, assert token ID 2 balances unchanged
  - `test_approve_doesNotAffectOtherTokenId` — approve token ID 1, assert token ID 2 allowances unchanged
  - `test_setOperator_affectsAllTokenIds` — operator IS cross-token (per spec), verify this
  - `test_mint_doesNotAffectOtherTokenId` — mint token ID 1, assert token ID 2 supply unchanged
  - `test_burn_doesNotAffectOtherTokenId` — burn token ID 1, assert token ID 2 supply unchanged
- [ ] **Fuzz tests:**
  - `testFuzz_transfer_isolation(uint256 id1, uint256 id2, uint256 amount)` — fuzz that operations on id1 never affect id2 balances
  - `testFuzz_approve_isolation(uint256 id1, uint256 id2, uint256 amount)` — fuzz that approvals on id1 never affect id2 allowances
  - `testFuzz_totalSupply_isolation(uint256 id1, uint256 id2, uint256 amount)` — fuzz that minting id1 never changes id2 supply
- [ ] All tests pass with `forge test`
- [ ] Build succeeds with `forge build`

## Technical Details

### Architecture

```
contracts/tokens/ERC6909/
├── IERC6909.sol                    # Core interface (7 functions)
├── IERC6909Events.sol              # Transfer, Approval, OperatorSet
├── IERC6909Errors.sol              # Custom errors
├── IERC6909Metadata.sol            # Metadata extension interface
├── IERC6909TokenSupply.sol         # TokenSupply extension interface
├── ERC6909Repo.sol                 # Storage library (Diamond storage pattern)
├── ERC6909Target.sol               # Core logic (implements IERC6909 + IERC6909TokenSupply)
├── ERC6909Facet.sol                # Core facet (IFacet)
├── ERC6909MetadataTarget.sol       # Metadata logic
├── ERC6909MetadataFacet.sol        # Metadata facet (IFacet)
├── ERC6909MintBurnTarget.sol       # Mint/burn/setMetadata logic (testing)
├── ERC6909MintBurnFacet.sol        # Mint/burn facet (IFacet)
├── IERC6909DFPkg.sol               # DFPkg interface
└── ERC6909DFPkg.sol                # Diamond Factory Package

test/foundry/spec/tokens/ERC6909/
├── ERC6909Facet_IFacet.t.sol       # IFacet behavior tests
├── ERC6909MetadataFacet_IFacet.t.sol
├── ERC6909MintBurnFacet_IFacet.t.sol
└── ERC6909DFPkg_IERC6909.t.sol     # Full functional + isolation tests
```

### Storage Slot

```solidity
bytes32 internal constant DEFAULT_SLOT = keccak256(abi.encode("eip.erc.6909"));
```

### Key Design Decisions

1. **Operator semantics**: Per ERC-6909, operators have cross-token approval. `transferFrom` checks `isOperator(sender, msg.sender)` first; if true, skips allowance check entirely.
2. **Metadata in shared Repo**: Even though Metadata is a separate Facet, the storage lives in the shared `ERC6909Repo` so MintBurnFacet can set metadata via the same Repo.
3. **No ERC-165 in facets**: The Diamond Factory handles `supportsInterface` via the default ERC165Facet. Our facets just declare their interface IDs in `facetInterfaces()`.
4. **totalSupply in core Facet**: `totalSupply(uint256 id)` is exposed through the core `ERC6909Facet` alongside the 7 core functions (8 total selectors).

### Interface ID Verification

The core interface ID `0x0f632fb3` should be verified by XOR-ing all 7 core function selectors. Add a test asserting this.

## Files to Create

**New Files:**
- `contracts/tokens/ERC6909/IERC6909.sol`
- `contracts/tokens/ERC6909/IERC6909Events.sol`
- `contracts/tokens/ERC6909/IERC6909Errors.sol`
- `contracts/tokens/ERC6909/IERC6909Metadata.sol`
- `contracts/tokens/ERC6909/IERC6909TokenSupply.sol`
- `contracts/tokens/ERC6909/ERC6909Repo.sol`
- `contracts/tokens/ERC6909/ERC6909Target.sol`
- `contracts/tokens/ERC6909/ERC6909Facet.sol`
- `contracts/tokens/ERC6909/ERC6909MetadataTarget.sol`
- `contracts/tokens/ERC6909/ERC6909MetadataFacet.sol`
- `contracts/tokens/ERC6909/ERC6909MintBurnTarget.sol`
- `contracts/tokens/ERC6909/ERC6909MintBurnFacet.sol`
- `contracts/tokens/ERC6909/IERC6909DFPkg.sol`
- `contracts/tokens/ERC6909/ERC6909DFPkg.sol`
- `test/foundry/spec/tokens/ERC6909/ERC6909Facet_IFacet.t.sol`
- `test/foundry/spec/tokens/ERC6909/ERC6909MetadataFacet_IFacet.t.sol`
- `test/foundry/spec/tokens/ERC6909/ERC6909MintBurnFacet_IFacet.t.sol`
- `test/foundry/spec/tokens/ERC6909/ERC6909DFPkg_IERC6909.t.sol`

## Inventory Check

Before starting, verify:
- [ ] `contracts/tokens/ERC20/` exists as reference for Repo->Target->Facet pattern
- [ ] `contracts/factories/diamondPkg/TestBase_IFacet.sol` exists for IFacet test pattern
- [ ] `contracts/interfaces/IFacet.sol` exists
- [ ] `contracts/interfaces/IDiamondFactoryPackage.sol` exists
- [ ] `contracts/InitDevService.sol` exists for test factory setup
- [ ] `contracts/utils/BetterEfficientHashLib.sol` exists for salt hashing

## Completion Criteria

- [ ] All acceptance criteria across all user stories met
- [ ] `forge build` succeeds
- [ ] `forge test --match-path test/foundry/spec/tokens/ERC6909/` passes all tests
- [ ] Interface ID `0x0f632fb3` verified in test
- [ ] Token ID isolation proven by both unit and fuzz tests

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
