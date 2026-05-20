# Crane BattleChain Pilot — Working Plan

Status: all sections approved. Ready for implementation review.

## Goal

Replace the existing Crane ERC20Permit pilot test with a BattleChain-driven pilot that:

1. Deploys the core `Create3Factory` through `bcDeployCreate2` so it is tracked as a top-level BattleChain deploy.
2. Lets the `Create3Factory` deploy its child `DiamondPackageCallBackFactory` via the normal CREATE3 path (a lineage child — no separate registration tx).
3. Deploys ERC20 / ERC5267 / ERC2612 facets and `ERC20PermitDFPkg` via the core factory (more lineage children).
4. Deploys an ERC20 permit proxy via the diamond factory (grandchild of the core factory).
5. Creates and adopts a Safe Harbor agreement that lists the core factory as the only scope account with `ChildContractScope.All` — this is how the diamond factory, facets, package, and proxy become "registered children" without any extra calls.
6. Verifies the flow under two test modes: local with the lib's vendored mocks, and forked against BattleChain testnet (chain 627).

## Decisions Locked In

| Decision | Choice |
| --- | --- |
| Test environment | Both — local mock test AND forked testnet test |
| Relation to existing `Pilot_ERC20Permit_Deploy.t.sol` | Replace it. No non-BC baseline kept. |
| Deploy script | Yes — alongside the tests, runnable against real BC testnet |
| Crane integration seam | New `InitBcService` parallel to `InitDevService` (existing `initEnv` untouched) |
| Local-mock fidelity | Full agreement flow exercised (deployer + factory + registry + attack registry) |
| Mock source | Reuse `battlechain-lib`'s `test/mocks/MockBCInfra.sol` via a new remapping — do not write our own mocks |
| Agreement scope shape | (A) Coarse — single `BcAccount` for the Create3Factory with `ChildContractScope.All`. All descendants covered by lineage. No per-deploy agreement updates. |

## How BattleChain "Child Registration" Actually Works

There is no separate "register as child" transaction. BattleChain tracks deployer lineage from on-chain deploy traces (every CREATE / CREATE2 / CREATE3 emits a record the indexer can walk). What the protocol controls is the `ChildContractScope` setting on each `BcAccount` listed in the agreement at creation time:

| `ChildContractScope` | Coverage |
| --- | --- |
| `None` | Only this exact address. |
| `ExistingOnly` | This address + children deployed before the agreement was signed. |
| `FutureOnly` | This address + children deployed after the agreement was signed. |
| `All` | This address + ALL children, past and future. (Default in `BCSafeHarbor.buildAccounts`.) |

For this pilot we use the coarse shape (Option A above): one `BcAccount` listing the Create3Factory with `ChildContractScope.All`. Because the Diamond Factory is deployed by the Create3Factory, and packages / proxies are deployed by either factory (and their lineage chains back through the Create3Factory), all of them are covered through deployer lineage. The agreement does not need to be amended after any later deploy.

Facets are also covered by this same lineage rule, since they are deployed by the Create3Factory via `deployCanonicalFacet`. This matches the intent: the Crane code under test should be attackable through whichever entry point (proxy, package, or factory) the whitehat reaches it from — and the actual vulnerability, when found, lives in a facet.

## Library + Remappings

`battlechain-lib@0.1.2` is installed at `lib/battlechain-lib/`. The released tag does NOT include `BCQuery.sol`, so the FFI-based `isAttackable(...)` path is unavailable; we use the real `IAttackRegistry` on the fork instead.

`remappings.txt` entries (the first already exists; add the second):

```
battlechain-lib/=lib/battlechain-lib/src/
battlechain-lib-mocks/=lib/battlechain-lib/test/mocks/
```

What `battlechain-lib` ships:

- Script helpers: `BCBase`, `BCConfig`, `BCDeploy`, `BCSafeHarbor`, `BCScript`, `CreateXChains`
- Interfaces only for the on-chain primitives: `IAgreement`, `IAgreementFactory`, `IAttackRegistry`, `IBCDeployer`, `IBCSafeHarborRegistry`
- Types: `AgreementDetails`, `BcChain`, `BcAccount`, `ChildContractScope`, `BountyTerms`, `IdentityRequirements`, `Contact`
- Mocks (under `test/mocks/MockBCInfra.sol`): `MockBCDeployer`, `MockAgreementFactory`, `MockAgreement`, `MockBCRegistry`, `MockAttackRegistry`

The lib does NOT ship production implementations of the on-chain registries — those live only at the addresses in `BCConfig.sol`.

## Key BattleChain Mechanics

- `bcDeployCreate*` delegates to `IBCDeployer` (`BattleChainDeployer` on chain 627, `CreateX` elsewhere) and pushes every deployed address into `BCDeploy._deployedContracts`, queryable via `getDeployedContracts()`.
- Child registration is implicit: `BcAccount.childContractScope = ChildContractScope.All` covers all past and future children of a top-level account through deployer lineage. There is no `registerChild(parent, child)` call.
- `BCSafeHarbor.buildAccounts(...)` defaults every supplied address to `ChildContractScope.All`.
- `BCBase._setBcAddresses(registry, factory, attackRegistry, deployer)` overrides resolution so the same script runs against mocks locally and real contracts on chain 627.
- `requestAttackMode(agreement)` reverts off chain 626/627; tests must skip it when running locally.

## Section 1 — File Inventory (Approved)

### Files added

| Path | Purpose |
| --- | --- |
| `contracts/InitBcService.sol` | New parallel bootstrap library. Same return shape as `InitDevService.initEnv` but routes the core `Create3Factory` through `IBCDeployer.deployCreate2`. Library form (not a `BCDeploy` subclass) — see Section 2 for rationale. |
| `scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol` | `BCScript` subclass. Runs `InitBcService.initEnvBc`, deploys the three facets and the package, deploys an ERC20 permit proxy, builds `AgreementDetails` with the core factory as the only scope account (`ChildContractScope.All`), calls `createAndAdoptAgreement`, conditionally calls `requestAttackMode` on chain 627. |
| `test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol` | Local test. Deploys lib mocks in `setUp`, wires them via `_setBcAddresses`, then runs the script's deploy logic and asserts. |
| `test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol` | Fork test against `https://testnet.battlechain.com`. Gated by `block.chainid == 627`. Lives under `test/foundry/fork/<chain>/` per Crane convention. |

### Files removed

| Path | Reason |
| --- | --- |
| `test/foundry/spec/pilot/Pilot_ERC20Permit_Deploy.t.sol` | Replaced by the two BC variants above. |

### Files reused (untouched)

- `contracts/InitDevService.sol` (remains the non-BC bootstrap for every other Crane test)
- `contracts/tokens/ERC20/ERC20PermitDFPkg.sol`
- `contracts/factories/create3/Create3Factory.sol`
- `contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol`
- `contracts/tokens/ERC20/facets/ERC20Facet.sol`, `ERC5267Facet.sol`, `ERC2612Facet.sol`
- `lib/battlechain-lib/` (installed at v0.1.2)

## Assertion Plan (consequence of reusing lib mocks)

The lib's mocks are minimal (`MockAgreement` discards `AgreementDetails`; `MockAttackRegistry` does not implement `getAgreementForContract` or `isTopLevelContractUnderAttack`; `MockBCRegistry` only stores `adopter → agreement`). Assertions are therefore split between the two test paths:

| Property to verify | Local-mock path | Fork path |
| --- | --- | --- |
| `bcDeployCreate2` actually invoked for the core factory | `MockBCDeployer.Deployed` event emitted with the core factory's address (`InitBcService` is a library and does not maintain its own tracker — see Section 2) | Real `BattleChainDeployer` emits an equivalent deploy event |
| `AgreementDetails` lists the core factory with `ChildContractScope.All` | `vm.expectCall(mockFactory, abi.encodeCall(IAgreementFactory.create, (expectedDetails, owner, salt)))` before the call (the mock discards the struct, so we verify at the call-encoding seam) | Read the agreement's scope back from `IAgreement.getDetails()` after creation and assert the account list / scope enum |
| Adoption succeeded | `MockBCRegistry.getAgreement(adopter) != address(0)` | `IBCSafeHarborRegistry.getAgreement(adopter) != address(0)` |
| Commitment window set (14 days) | `MockAgreement.cantChangeUntil > 0` | `IAgreement.getCantChangeUntil() > 0` |
| Diamond factory and proxy are children-by-lineage of the core factory | Verified through Crane state only: `factory.getDiamondPackageFactory() == diamondFactory` and `diamondFactory.calcAddress(pkg, args) == proxy` | Same, plus `attackRegistry.getAgreementForContract(diamondFactory)` resolves to the agreement |
| `requestAttackMode` accepted | Skipped (helper reverts off chain 626/627) | `attackRegistry.isTopLevelContractUnderAttack(coreFactory) == true` after request |
| ERC20 metadata + permit signature flow | Standard Crane assertions (token name/symbol/decimals, totalSupply to recipient, nonces start at 0, DOMAIN_SEPARATOR non-zero, valid permit signature updates allowance and nonce) | Same |

The trade-off accepted by reusing lib mocks: child-scope-through-lineage resolution (`getAgreementForContract(child) == agreement`) is verified ONLY on the fork test. The local test verifies the intent (`AgreementDetails` built correctly with `ChildContractScope.All`) via `vm.expectCall`; the fork test verifies the resulting behavior against the real registry.

## Section 2 — Library / Bootstrap Layer (Approved)

### Core insight

Only one line of `InitDevService.initEnv` is a top-level EOA deploy: `new Create3Factory{salt: salt}(owner)` (line 108). Every other deploy in the bootstrap (the nine canonical facets, the `Create3FactoryDFPkg`, the `DiamondPackageCallBackFactory`) is initiated by the Create3Factory contract via `deployCanonicalFacet` / `create3WithArgs` / `deployCanonicalPackageWithArgs`. Those are lineage children automatically.

So `InitBcService` only needs to change that one line. Everything from line 111 onward is identical to `InitDevService`.

### `contracts/InitBcService.sol` API

Library (same shape as `InitDevService` — a Crane convention) that mirrors `initEnv` and `initDiamondFactory`, swapping only the `Create3Factory` constructor invocation.

```solidity
library InitBcService {
    using BetterEfficientHashLib for bytes;
    Vm constant vm = Vm(VM_ADDRESS);

    // Salts identical to InitDevService — re-declared to avoid coupling.
    bytes32 constant ERC165_FACET_SALT = keccak256(abi.encode(type(ERC165Facet).name));
    // ... 9 more salt constants identical to InitDevService ...

    /// @notice BattleChain-aware bootstrap. Mirrors `InitDevService.initEnv` exactly,
    /// except the top-level Create3Factory is deployed through `IBCDeployer.deployCreate2`
    /// rather than `new Create3Factory{salt: salt}(owner)`.
    ///
    /// @param owner       Initial Create3Factory owner.
    /// @param bcDeployer  Address of the IBCDeployer. On chain 627 this is `BCConfig.deployer()`;
    ///                    locally it is a `MockBCDeployer`.
    function initEnvBc(address owner, address bcDeployer)
        internal
        returns (ICreate3FactoryProxy factory, IDiamondPackageCallBackFactory diamondFactory);

    function initFactoryBc(address owner, bytes32 salt, address bcDeployer)
        internal
        returns (ICreate3FactoryProxy factory);

    /// @dev Identical to InitDevService.initDiamondFactory — copied verbatim.
    function initDiamondFactory(ICreate3FactoryProxy factory)
        internal
        returns (IDiamondPackageCallBackFactory diamondFactory);
}
```

`initFactoryBc` swaps line 108 of `InitDevService.initFactory` from `new Create3Factory{salt: salt}(owner)` to:

```solidity
bytes memory initCode = abi.encodePacked(type(Create3Factory).creationCode, abi.encode(owner));
factory = ICreate3FactoryProxy(IBCDeployer(bcDeployer).deployCreate2(salt, initCode));
```

All nine `deployCanonicalFacet` calls inside `initFactoryBc` are copied verbatim from `InitDevService.initFactory`.

### Why a library and not a `BCDeploy` subclass

`BCDeploy` is an abstract contract holding private state (`_deployedContracts`). A library cannot inherit from it.

This is fine because `BCDeploy._deployedContracts` only exists to feed `getDeployedContracts()`, which builds the agreement scope. With Option (A) we list exactly one `BcAccount` (the Create3Factory) — so the script only needs one address, which the library returns directly. No tracker is needed.

Keeping `InitBcService` as a library also lets both scripts (which inherit `BCDeploy`) and tests (which do not) call the same bootstrap.

### Caller responsibilities

The BCScript subclass owns the BattleChain-side concerns:

1. Resolve `bcDeployer = _bcDeployer()` (override locally, `BCConfig.deployer()` on chain 627).
2. Call `(factory, diamondFactory) = InitBcService.initEnvBc(owner, bcDeployer)`.
3. Build the single-element scope: `address[] memory scope = new address[](1); scope[0] = address(factory);`.
4. `createAndAdoptAgreement(defaultAgreementDetails(name, contacts, scope, recovery), owner, AGREEMENT_SALT)`.
5. If `_isBattleChain()`, `requestAttackMode(agreement)`.

The script does not need to call `bcDeployCreate2` itself — the library does that via `IBCDeployer.deployCreate2`. `BCDeploy._deployedContracts` on the script stays empty, intentionally.

### Salt strategy

| Salt | Value | Why |
| --- | --- | --- |
| Top-level Create3Factory | `keccak256(abi.encode(owner))` | Matches `InitDevService.initEnv`. |
| Diamond factory, facets, package | Per-contract-name salts inherited from `InitDevService`. | Internal deploys, unchanged. |
| Safe Harbor agreement | `keccak256("crane-erc20permit-pilot-v1")` | New constant on the script. Deterministic per pilot version. |
| ERC20 proxy `optionalSalt` (`PkgArgs`) | `bytes32(0)` | Default for the pilot; parameterize later if needed. |

### Compatibility

`InitBcService` pins to `pragma solidity ^0.8.24;` to match `battlechain-lib@0.1.2`. `InitDevService` stays at `^0.8.0;`. Both libraries co-exist; existing Crane tests continue to use `InitDevService`.

## Section 3 — Script + Test Wiring (Approved)

### File layout

```
scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol
test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol
test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol
```

(The fork test lives under `test/foundry/fork/<chain>/` per Crane convention; the local-mock test stays under `test/foundry/spec/pilot/`.)

### `Script_Pilot_BC_ERC20Permit.s.sol` shape

- Extends `BCScript`.
- Constants: `AGREEMENT_SALT = keccak256("crane-erc20permit-pilot-v1")`, `TOKEN_NAME = "Crane Permit Pilot"`, `TOKEN_SYMBOL = "CPP"`, `TOKEN_DECIMALS = 18`, `TOKEN_SUPPLY = 1_000_000 ether`.
- Public state: `coreFactory`, `diamondFactory`, `permitPackage`, `permitProxy`, `agreement` — set by `_runDeploy`, readable from tests.
- Required `BCScript` hooks: `_protocolName()`, `_contacts()` (single contact: Crane Security), `_recoveryAddress()` (returns `msg.sender`).
- `run()` wraps `_runDeploy(msg.sender, msg.sender)` in `vm.startBroadcast / stopBroadcast`.
- `_runDeploy(owner, recipient)` performs in order:
  1. `(coreFactory, diamondFactory) = InitBcService.initEnvBc(owner, _bcDeployer())`
  2. Three `deployCanonicalFacet` calls for `ERC20Facet`, `ERC5267Facet`, `ERC2612Facet`.
  3. `permitPackage = coreFactory.deployPackageWithArgs(type(ERC20PermitDFPkg).creationCode, abi.encode(PkgInit{...}), keccak256(abi.encode(type(ERC20PermitDFPkg).name)))`.
  4. `permitProxy = diamondFactory.deploy(IDiamondFactoryPackage(permitPackage), abi.encode(PkgArgs{name, symbol, decimals, totalSupply, recipient, optionalSalt: 0}))`.
  5. `agreement = createAndAdoptAgreement(_buildAgreementDetails(), owner, AGREEMENT_SALT)`.
  6. `if (_isBattleChain()) requestAttackMode(agreement);`
- `_buildAgreementDetails()` exposed `internal view` so the local-mock test can compute the exact `AgreementDetails` struct independently and assert on it.

### `Pilot_BC_ERC20Permit_LocalMock.t.sol` shape

- Extends `Script_Pilot_BC_ERC20Permit, Test`. (Inherits `_runDeploy` for free; `Test` does not extend `Script`, so no diamond conflict.)
- `setUp()` instantiates `MockBCDeployer`, `MockBCRegistry`, `MockAgreementFactory`, `MockAttackRegistry` and wires them via `_setBcAddresses(...)`.
- Test cases:
  1. `test_coreFactory_deployedViaBcDeployer` — `vm.expectEmit` on `MockBCDeployer.Deployed`; sanity-check code lengths > 0 on all four artifacts.
  2. `test_agreementDetails_listCoreFactory_withChildScopeAll` — call `_buildAgreementDetails()` and assert: 1 chain, 1 account, account address equals `vm.toString(address(coreFactory))`, `childContractScope == ChildContractScope.All`.
  3. `test_agreementFactory_calledWithExpectedDetails` — snapshot/revert dance to learn `coreFactory` address, then `vm.expectCall(mockFactory, abi.encodeCall(IAgreementFactory.create, (expected, OWNER, AGREEMENT_SALT)))` before the second `_runDeploy`.
  4. `test_adoption_andCommitmentWindow` — `mockRegistry.getAgreement(address(this)) == agreement`; `MockAgreement(agreement).cantChangeUntil() > block.timestamp`.
  5. `test_diamondFactory_isWiredToCoreFactory` — `ICreate3Factory(coreFactory).getDiamondPackageFactory() == diamondFactory`.
  6. `test_proxy_addressIsDeterministic` — `diamondFactory.calcAddress(...) == permitProxy`.
  7. `test_proxy_erc20Metadata` — name, symbol, decimals, `balanceOf(RECIPIENT) == TOKEN_SUPPLY`.
  8. `test_proxy_permitSignature_updatesAllowanceAndNonce` — EIP-712 sign + permit; assert allowance updated and nonce incremented.
  9. `test_proxy_domainSeparator_nonZero_nonces_startAtZero` — DOMAIN_SEPARATOR != 0; `nonces(owner) == 0` before permit.

### `Pilot_BC_ERC20Permit_Fork.t.sol` shape

- Extends `Script_Pilot_BC_ERC20Permit, Test`.
- `setUp()`:
  - Read RPC from env `BC_TESTNET_RPC`, fall back to `https://testnet.battlechain.com`.
  - `try vm.createSelectFork(rpc) catch { vm.skip(true); return; }`.
  - `if (block.chainid != 627) { vm.skip(true); return; }`
  - `vm.deal(address(this), 100 ether)`.
  - No `_setBcAddresses` — `BCConfig` defaults resolve to real testnet addresses.
- Test cases:
  1. `test_fork_endToEnd_deployAndCoverChildren` — `_runDeploy(address(this), address(this))`, then assert via real `IAttackRegistry`:
     - `getAgreementForContract(coreFactory) == agreement`
     - `isTopLevelContractUnderAttack(coreFactory) == true`
     - `getAgreementForContract(diamondFactory) == agreement` (lineage)
     - `getAgreementForContract(permitPackage) == agreement` (lineage)
     - `getAgreementForContract(permitProxy) == agreement` (lineage)
     - `IBCSafeHarborRegistry(_bcRegistry()).getAgreement(address(this)) == agreement`
     - `IAgreement(agreement).getCantChangeUntil() > block.timestamp`
  2. `test_fork_permitSignature_works` — same EIP-712 flow as local-mock variant, against the real proxy.

### Notable design points

- **Test inherits the script** to reuse `_runDeploy`. `forge-std/Test` does not extend `forge-std/Script`, so the only `Script` in the inheritance chain comes from `BCScript`. No diamond conflict.
- **`vm.expectCall` snapshot dance** (`vm.snapshotState → _runDeploy → revertToState → expectCall → _runDeploy`) is the only test-only trick. Used so we can install the matcher with the concrete `coreFactory` address that `_runDeploy` itself produces.
- **No FFI required.** `BCQuery.sol` is absent from v0.1.2, so `--ffi` is not needed. Plain `forge test` works.
- **`foundry.toml` needs no changes.** The fork directory is already excluded from the default test pass (existing convention), so the local-mock test runs in every `forge test`, the fork test runs only when explicitly matched.

## Section 4 — Acceptance Criteria & Run Plan (Approved)

### Build & lint

```bash
forge build
forge fmt --check
```

Acceptance:

- All four new files compile under Solidity 0.8.x with `viaIR` (existing Crane setting).
- No new cspell warnings. `Attackable` / `attackable` already added to `.cspell/custom-dictionary.txt`.
- `InitBcService.sol` uses `@crane/` for Crane imports and `battlechain-lib/` for BC imports. No relative or bare `contracts/` paths.

### Local-mock test

```bash
forge test --match-path "test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol" -vv
```

Acceptance — all 9 tests pass:

| # | Test | Verifies |
| --- | --- | --- |
| 1 | `test_coreFactory_deployedViaBcDeployer` | `MockBCDeployer.Deployed` emitted; all artifacts have code |
| 2 | `test_agreementDetails_listCoreFactory_withChildScopeAll` | `AgreementDetails` shape is correct (Option A scope) |
| 3 | `test_agreementFactory_calledWithExpectedDetails` | `IAgreementFactory.create` invoked with the exact expected struct |
| 4 | `test_adoption_andCommitmentWindow` | `adoptSafeHarbor` called; 14-day commitment window set |
| 5 | `test_diamondFactory_isWiredToCoreFactory` | Crane state shows diamond factory registered on core factory |
| 6 | `test_proxy_addressIsDeterministic` | `calcAddress` matches deployed proxy address |
| 7 | `test_proxy_erc20Metadata` | name / symbol / decimals / totalSupply on recipient |
| 8 | `test_proxy_permitSignature_updatesAllowanceAndNonce` | EIP-712 permit increments nonce, sets allowance |
| 9 | `test_proxy_domainSeparator_nonZero_nonces_startAtZero` | Permit surface initialized correctly |

Runtime budget: under 30 seconds (no fork, no FFI).

### Fork test

```bash
# Default RPC
forge test --match-path "test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol" -vv

# Custom RPC (recommended for CI)
BC_TESTNET_RPC="https://my-private-rpc/..." \
  forge test --match-path "test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol" -vv
```

Acceptance — both tests pass when chain 627 is reachable, both skip cleanly (`vm.skip(true)`) when it is not:

| # | Test | Verifies |
| --- | --- | --- |
| 1 | `test_fork_endToEnd_deployAndCoverChildren` | All four contracts resolve to the same agreement through the real `IAttackRegistry`; adoption + commitment window state correct |
| 2 | `test_fork_permitSignature_works` | EIP-712 flow against the real proxy |

### Deploy script (real testnet, optional)

```bash
# One-time keystore setup
cast wallet import battlechain --interactive

# Dry run
forge script scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol \
  --rpc-url https://testnet.battlechain.com \
  --skip-simulation

# Broadcast
forge script scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol \
  --rpc-url https://testnet.battlechain.com \
  --skip-simulation \
  --broadcast \
  --account battlechain
```

Acceptance:

- Script emits a CREATE2 deploy from the `BattleChainDeployer` for the Create3Factory.
- An agreement is created and adopted by the script contract.
- `cast call $ATTACK_REGISTRY "isTopLevelContractUnderAttack(address)" $CORE_FACTORY` returns `true` post-run.
- `cast call $ATTACK_REGISTRY "getAgreementForContract(address)" $DIAMOND_FACTORY` returns the same agreement (lineage child resolution).

### Pilot "done" checklist

The pilot is done when:

1. `forge build` is clean.
2. All 9 local-mock tests pass.
3. Both fork tests pass against the public testnet RPC, or skip cleanly with a clear message if RPC is down.
4. The deploy script runs end-to-end on testnet at least once, producing on-chain artifacts (core factory, diamond factory, package, proxy, agreement).
5. Manual spot-check: open the block-explorer URL for the deployed agreement, confirm scope shows one account (the Create3Factory) with `ChildContractScope.All`.

### Out of scope for the pilot

- Promotion to production (3-day delay path).
- Bounty terms tuning. We use the lib defaults: 10%, $1M cap, retainable, anonymous.
- Multiple proxy / multiple package fan-out. One of each is enough to prove the lineage model.
- Wiring the BattleChain deploy path into other Crane test suites. Opt-in via `InitBcService` only.

### Post-pilot follow-ups (not in this PR)

- Add a parallel BC-aware bootstrap helper at the Indexedex level (one layer up) that uses the pilot's pattern for the full Indexedex protocol contracts.
- Add a `BCQuery.sol` shim or upgrade to a newer `battlechain-lib` tag once one ships, to enable FFI `isAttackable` checks in CI.
- Consider whether `requestAttackMode` should be called from the script or via a separate operator action.

## Implementation Order

Recommended order for the implementation PR (each step is independently green before moving on):

1. Add the `battlechain-lib-mocks/` remapping to `remappings.txt`.
2. Write `contracts/InitBcService.sol`. Verify it compiles.
3. Write `scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol`. Verify it compiles.
4. Delete `test/foundry/spec/pilot/Pilot_ERC20Permit_Deploy.t.sol`.
5. Write `test/foundry/spec/pilot/Pilot_BC_ERC20Permit_LocalMock.t.sol`. Make all 9 tests pass.
6. Write `test/foundry/fork/battlechain_testnet/Pilot_BC_ERC20Permit_Fork.t.sol`. Verify the two tests pass against the public testnet RPC (or skip cleanly if unreachable).
7. Smoke-run the deploy script against testnet at least once and capture the deployed addresses in a comment or commit message.
