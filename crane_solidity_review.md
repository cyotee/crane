## contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol — Grade: C
- ERC20 metadata remains hard-coded to "Pachira BPT"/"BPT"/18 even though the comments point to `ERC20Repo`, so every deployment reports identical branding/decimals regardless of pool configuration; see [contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol#L77-L95](contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol#L77-L95).
- Core ERC20 flows simply forward to the shared Balancer vault (`approve`, `transfer`, `transferFrom`) and always return `true`, which keeps storage centralized but means any call made before `BalancerV3VaultAwareRepo` is initialized will just revert through an `address(0)` vault pointer—document that precondition in deploy scripts [contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol#L31-L52](contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol#L31-L52).
- `emitTransfer`/`emitApproval` are explicitly limited to the vault via `onlyBalancerV3Vault`, preventing arbitrary callers from faking BPT events and keeping indexers honest [contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol#L118-L124](contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolTarget.sol#L118-L124).

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol — Grade: B-
- Facet metadata stays focused: `facetInterfaces()` only advertises `IBalancerV3VaultAware`, which minimizes ERC165 clutter but also means callers must know that all three getters live behind the same interface [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol#L17-L20](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol#L17-L20).
- `facetFuncs()` hardcodes the three selector entries and lacks tests, so any change in `IBalancerV3VaultAware` would quietly desync the metadata; consider snapshot tests to guard the list [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol#L22-L27](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol#L22-L27).
- `facetMetadata()` simply reassembles the name/interface/function arrays, which is handy for tooling but duplicates logic—marking these helpers `internal` and reusing them elsewhere would avoid future drift [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol#L29-L37](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol#L29-L37).

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol — Grade: B-
- `_initialize` happily overwrites the stored vault pointer with no zero-address guard or once-only check, so any facet/library that calls it twice will silently repoint every Balancer-aware component—add an `if (address(vault) == address(0)) revert` or emit an event to catch mistakes [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol#L23-L30](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol#L23-L30).
- Getter helpers expose both slot-specific and default storage accessors, keeping the diamond layout flexible, but nothing enforces that the slot was initialized before reads—consider adding a non-zero assertion in `_balancerV3Vault()` to fail fast [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol#L31-L36](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol#L31-L36).

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareTarget.sol — Grade: B
- Both `balV3Vault()` and `getVault()` just return the same repo pointer, so the ABI exposes redundant selectors; deciding on a single canonical getter would shrink the interface surface [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareTarget.sol#L22-L26](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareTarget.sol#L22-L26).
- `getAuthorizer()` forwards straight to the cached vault instance each call, ensuring fresh data but also meaning a zero-initialized repo will revert via an external call—deploy scripts should set the vault before exposing this facet [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareTarget.sol#L30-L33](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareTarget.sol#L30-L33).

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol — Grade: B-
- `onlyBalancerV3Vault` pulls the vault address from the shared repo and reverts with `NotBalancerV3Vault` whenever an unrecognized caller tries to emit events, preventing spoofed `Transfer`/`Approval` logs [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol#L9-L17](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol#L9-L17).
- Because `_onlyBalancerV3Vault()` reads the repo slot every time, the guard adds an extra SLOAD per protected call; caching the address in an immutable during initialization would shave gas if the pointer is never expected to change [contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol#L13-L17](contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol#L13-L17).

## contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol — Grade: C+
- `facetInterfaces()` advertises seven interface IDs, but `interfaces[2]` is the XOR of ERC20 and metadata IDs—a value no interface actually owns—so `supportsInterface` consumers could cache a meaningless selector; scrub that entry or replace it with a real extension [contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol#L57-L72](contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol#L57-L72).
- `decimals()` is still hard-coded to return 18 even though `name()`/`symbol()` now defer to `ERC20Repo`, preventing non-18 BPTs from ever reporting their true precision [contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol#L122-L125](contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol#L122-L125).
- `transfer`/`transferFrom` delegate straight into the vault to mutate balances, so reentrancy protections rely entirely on the vault; document that expectation and consider wrapping state-changing entrypoints with the project-wide reentrancy guard [contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol#L141-L169](contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol#L141-L169).
- `permit` uses the shared EIP-712 repo plus `_useNonce` from `ERC2612Repo`, which keeps signature state centralized; hook tests should assert `approve` effects propagate through the vault since events are emitted there, not in the facet [contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol#L200-L229](contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol#L200-L229).

## contracts/protocols/dexes/balancer/v3/vault/SenderGuardCommon.sol — Grade: B
- `_saveSender` stores the outermost caller in transient storage so nested router invocations can always recover the original initiator, matching Balancer’s router contract expectations [contracts/protocols/dexes/balancer/v3/vault/SenderGuardCommon.sol#L32-L41](contracts/protocols/dexes/balancer/v3/vault/SenderGuardCommon.sol#L32-L41).
- `_discardSenderIfRequired` only clears the slot when the current frame was responsible for populating it, reducing accidental wipes during hook reentrancy [contracts/protocols/dexes/balancer/v3/vault/SenderGuardCommon.sol#L42-L48](contracts/protocols/dexes/balancer/v3/vault/SenderGuardCommon.sol#L42-L48).
- Consider surfacing a view helper that reverts if `_getSender()` is unset so integrators spot misuse of the modifier early; today `_getSender()` will quietly return `address(0)` with no diagnostics.

## contracts/protocols/dexes/balancer/v3/vault/SenderGuardFacet.sol — Grade: B
- Facet metadata is intentionally narrow: `facetInterfaces()` and `facetFuncs()` only expose the single `ISenderGuard.getSender` selector, making it easy to reason about upgrades [contracts/protocols/dexes/balancer/v3/vault/SenderGuardFacet.sol#L38-L52](contracts/protocols/dexes/balancer/v3/vault/SenderGuardFacet.sol#L38-L52).
- Because the facet performs no initialization itself, packages must ensure the underlying `SenderGuardCommon` logic is reachable (i.e., wrap entrypoints with `saveSender`); documenting that requirement next to the metadata helpers would prevent zero-address reads.
- `facetMetadata()` duplicates the helper calls; adding a Foundry test that asserts its return arrays match `facetInterfaces()`/`facetFuncs()` would catch accidental divergence [contracts/protocols/dexes/balancer/v3/vault/SenderGuardFacet.sol#L54-L67](contracts/protocols/dexes/balancer/v3/vault/SenderGuardFacet.sol#L54-L67).

## contracts/protocols/dexes/balancer/v3/vault/SenderGuardModifiers.sol — Grade: B
- The `saveSender` modifier captures the initiator before the body executes and clears it afterward, matching Balancer’s nested-router semantics and preventing intermediate hooks from clobbering the value [contracts/protocols/dexes/balancer/v3/vault/SenderGuardModifiers.sol#L43-L52](contracts/protocols/dexes/balancer/v3/vault/SenderGuardModifiers.sol#L43-L52).
- Because the modifier relies on callers to pass the right `sender` argument, misuse can still corrupt context; consider adding internal helpers that force the modifier to read `msg.sender` to reduce caller error.

## contracts/protocols/dexes/balancer/v3/vault/SenderGuardTarget.sol — Grade: B-
- `getSender()` simply exposes the transient slot managed by `SenderGuardCommon`, giving any diamond that uses the modifier an easy way to introspect the original caller [contracts/protocols/dexes/balancer/v3/vault/SenderGuardTarget.sol#L22-L24](contracts/protocols/dexes/balancer/v3/vault/SenderGuardTarget.sol#L22-L24).
- There are no guard rails for unset senders: when the modifier isn’t applied, this view just returns zero with no error, so tests should assert expected non-zero values after each router entrypoint.
# Crane Solidity Review

## contracts/GeneralErrors.sol — Grade: A
- Defines three custom errors (`ArgumentMustNotBeZero`, `ArgumentMustBeGreaterThan`, `InvalidPageSize`) with clear parameter naming, giving callers structured failure context.
- SPDX identifier and pragma are present and no dependencies are introduced, keeping compilation footprint minimal.
- File scope is limited to error declarations; there’s no namespace grouping or docstrings, but the error names are self-explanatory.
- Ensure downstream tests assert for these specific error selectors wherever guard functions rely on them so that shared validation failures remain observable.

## contracts/InitDevService.sol — Grade: A-
- Library encapsulates Foundry-only setup by deterministically deploying the `Create3Factory`, all required introspection/post-deploy facets, and wiring the `DiamondPackageCallBackFactory`, so tests mirror production wiring.
- Uses `BetterEfficientHashLib._hash()` on type names for salts and `vm.label` for every deployment, which keeps addresses stable and traces readable.
- Depends on the real facets (ERC165, diamond loupe, ERC8109, post-deploy hook) rather than mocks, so helper reverts reflect live code paths.
- Minor nit: commented console logs could be culled; consider adding a regression test confirming `initEnv(owner)` yields deterministic factory/facet addresses for a fixed owner input.

## contracts/StyleGuide.sol — Grade: C+
- Serves purely as a boilerplate example showing section delimiters, ordering, and naming conventions; helpful for onboarding but not referenced by executable code.
- Demonstrates full contract skeleton (events/errors/modifiers/functions) with structured comments, yet contains dead code (receive/fallback, private getter) that isn’t tested or linted.
- Because it compiles into bytecode, carrying this exemplar in production sources slightly increases artifact size; consider moving to docs or marking `abstract` to avoid deployment confusion.
- Tests do not cover this file (none needed if treated as documentation); if it stays in `contracts/`, ensure devs know it’s illustrative only.

## contracts/access/AccessFacetFactoryService.sol — Grade: A-
- Focused helper library that deploys the access-control facets (MultiStepOwnable, Operable, ReentrancyLock) through the shared `ICreate3Factory`, keeping deployment logic DRY.
- Uses hashed type-name salts and `vm.label` consistently, giving deterministic addresses and readable traces across tests and scripts.
- Only surface for improvement is documentation/tests explaining that each helper must be called via the same factory instance used by the package; otherwise very clean.
- Consider adding Foundry tests asserting each helper deploys once per salt and reverts if redeployed, to guard the deterministic deployment invariant.

## contracts/access/ERC8023/MultiStepOwnableFacet.sol — Grade: A
- Facet is a thin veneer over `MultiStepOwnableTarget`, exposing exactly the ERC8023 selectors and forwarding metadata expected by the Diamond runtime; no business logic duplication.
- Comprehensive metadata helpers (`facetName`, `facetInterfaces`, `facetFuncs`, `facetMetadata`) are kept in sync with `IMultiStepOwnable` selectors, reducing regression risk.
- Inline NatSpec tags (`tag::...[]`) document each method for inclusion in generated docs—great for keeping architectural references current.
- Recommend ensuring tests (see `TestBase_IMultiStepOwnable`) assert the selector arrays and interface IDs so any future additions get caught quickly.

## contracts/access/ERC8023/MultiStepOwnableFacetStub.sol — Grade: B
- Minimal harness that inherits the real facet and calls `MultiStepOwnableRepo._initialize` in the constructor so tests exercise production storage logic instead of mocks.
- Clear “not for production” warning plus dedicated NatSpec tags make its intent obvious and keep documentation snippets accurate.
- Because nothing prevents repeated initialization via delegatecalls, be sure tests only deploy this once and never expose it through a production package; consider adding a Foundry `expectRevert` proving re-initialization fails in context.

## contracts/access/ERC8023/MultiStepOwnableModifiers.sol — Grade: B+
- Abstract wrapper exposing `onlyOwner` and `onlyProposedOwner` by delegating to the Repo guards, so inheriting facets stay DRY and gas usage stays flat thanks to inlining.
- Documentation is concise and clarifies that modifiers are compiler-inlined, which helps explain why no events/logging exist in this layer.
- Could add integration tests demonstrating modifiers revert with the `IMultiStepOwnable` errors to catch accidental selector changes in the repo.

## contracts/access/ERC8023/MultiStepOwnableRepo.sol — Grade: A
- Comprehensive storage library that centralizes every state mutation and guard for ERC8023 ownership transfers, reducing the chance of divergent logic across facets.
- Exposes both slot-agnostic and default-slot helpers, so advanced packages can embed the logic under alternate namespaces without copy/paste.
- Emits the canonical `IMultiStepOwnable` events from within the repo, ensuring a single source of truth for state transitions and making it trivial to reason about invariants.
- Consider unit tests covering `_cancelPendingOwnershipTransfer` to ensure buffer timestamps reset correctly when multiple cancellations occur in a row.

## contracts/access/ERC8023/MultiStepOwnableTarget.sol — Grade: A-
- Target contract is purely an interface adapter: it forwards all calls to the repo and exposes `IMultiStepOwnable` ABI without storing any state itself.
- Separation keeps Diamond selectors clean and leaves upgrade risk confined to the repo logic, but the target lacks explicit access control comments (relies on repo guards), which could confuse newcomers.
- Suggest adding a lightweight Foundry test asserting each public function simply relays to the repo (e.g., via `expectCall`) to detect accidental logic additions.

## contracts/access/ERC8023/TestBase_IMultiStepOwnable.sol — Grade: A-
- Provides a reusable invariant test harness with a sophisticated handler that model-checks both positive and negative ownership transfer paths across multiple actors.
- Ghost variables for owner and buffer period keep the invariant suite honest and uncover TOCTOU bugs where state drifted without the handler noticing.
- Requires child tests to override `_deployOwnable()` and `setUp()`, which enforces explicit construction of the SUT before invariants run; the commented `require` hint could be reinstated to catch misconfigured inheritors earlier.

## contracts/access/operable/OperableFacet.sol — Grade: B+
- Facet composes `OperableTarget` plus metadata helpers so packages can expose `IOperable` via Diamonds without re-implementing selector plumbing.
- Keeps selector arrays tight (four functions) and reuses `MultiStepOwnableModifiers` to gate setter methods, ensuring operator enrollment aligns with the global ownership model.
- Lacks direct tests confirming `facetFuncs()` stays synchronized with `IOperable`; consider adding a snapshot test similar to the ERC8023 suite.

## contracts/access/operable/OperableModifiers.sol — Grade: B
- Supplies `onlyOperator` and `onlyOwnerOrOperator` modifiers that delegate to the repo guards, reducing boilerplate in stubs and targets.
- Documentation exists for `onlyOperator` but not for `onlyOwnerOrOperator`, so adding NatSpec there would help readers know it allows either the owner or a scoped operator to act.
- Recommend adding negative-path tests showing each modifier reverts with `IOperable.NotOperator` when unauthorized callers exercise target functions.

## contracts/access/operable/OperableRepo.sol — Grade: A-
- Uses deterministic storage slot plus mappings to manage both global and per-selector operator approvals, covering both broad and surgical delegation use cases.
- Enforces access through `MultiStepOwnableRepo._onlyOwner()` before mutating operators, ensuring operator escalation always goes through the owner path without duplicating logic.
- Error reuse (`IOperable.NotOperator`) keeps revert surface uniform; however, the repo doesn’t emit events when a per-function operator is removed, so consumers must monitor both events to track status.
- Consider adding fuzz tests verifying `_onlyOwnerOrOperator` allows function-specific operators even when not globally approved.

## contracts/access/operable/OperableTarget.sol — Grade: B+
- Implements the `IOperable` interface, pipes reads through the repo, and restricts mutating calls with `onlyOwner`, ensuring operator assignment can’t be performed by arbitrary addresses.
- Returns boolean success flags even though internal repo functions can’t fail silently; this matches the interface but invites tests to check both return value and event emission.
- Could expose view helpers enumerating operators for off-chain tooling, or at least document that enumeration must be handled externally since mappings aren’t iterable on-chain.

## contracts/access/operable/OperableTargetStub.sol — Grade: B
- Purpose-built testing harness that initializes ownership, exposes last-call state, and provides functions protected by each modifier so negative-path tests can target specific guards.
- Constructor selects a fixed 1-day buffer for ownership initialization, matching production defaults and ensuring MultiStepOwnable invariants remain realistic.
- Consider wiring in helper methods that expose the selectors for `onlyOwnerOrOperator` as well (only `restrictedByOnlyOperator` currently exposes its selector), which would ease automation scripts.

## contracts/access/reentrancy/ReentrancyLockFacet.sol — Grade: B
- Facet acts as a thin adapter that reuses `ReentrancyLockTarget` and publishes metadata, so the diamond only exposes the single `isLocked()` selector it needs for monitoring.
- Lacks NatSpec and tests confirming `facetFuncs()` stays aligned with `ReentrancyLockTarget`, which could allow accidental selector drift.
- Consider adding docs showing how this facet is meant to accompany `ReentrancyLockModifiers` so integrators know to include both pieces.

## contracts/access/reentrancy/ReentrancyLockModifiers.sol — Grade: B
- Provides a concise `lock` modifier that calls `_onlyUnlocked()`, `_lock()`, executes the body, then `_unlock()`, ensuring mutation paths are serialized without sprinkling guard logic everywhere.
- Because unlocking happens after `_`, any consumer that uses `return` before logic completes could still safely unroll, but it would be good to mention that reverts still reset the transient slot.
- A regression test demonstrating that reentrancy attempts revert with `IReentrancyLock.IsLocked()` would keep this utility honest.

## contracts/access/reentrancy/ReentrancyLockRepo.sol — Grade: A-
- Implements the locking primitive with transient storage, so state is confined to the transaction context and automatically clears at tx end—perfect for reentrancy guards.
- `_onlyUnlocked()` uses `IReentrancyLock.IsLocked` for consistent revert signatures, and `_lock()`/`_unlock()` are one-line operations, minimizing gas overhead.
- Worth adding coverage ensuring `_unlock()` always runs—even when nested modifiers revert—so future refactors don’t leave the guard stuck.

## contracts/access/reentrancy/ReentrancyLockTarget.sol — Grade: B-
- Exposes `isLocked()` via `IReentrancyLock` so external tooling can inspect guard state, but doesn’t offer any helper to force-unlock in emergencies (maybe intentional but worth documenting).
- File has no documentation or tests showing it’s safe for read-only exposure; adding a quick Foundry test that toggles the lock via modifiers would lock in behavior.

## contracts/constants/Constants.sol — Grade: B
- Central grab bag of primitive constants (hash seeds, fee denominators, `Q112`, WAD ladder, etc.) that removes magic numbers from the rest of the repo.
- Lack of inline documentation on some values (especially the large WAD ladder) makes it hard to know which are still in use; consider pruning or adding references to the subsystems that depend on each.
- Since this file compiles into every artifact, keeping the list tight helps keep bytecode size manageable.

## contracts/constants/FoundryConstants.sol — Grade: B
- Captures Foundry-specific cheatcode addresses plus pre-funded wallet keys, keeping test helpers from duplicating hard-coded secrets.
- Includes `INT256_MIN_ABS`, `SECP256K1_ORDER`, and `UINT256_MAX` to avoid recomputing them across tests.
- Recommend adding documentation pointing to the Foundry book so new contributors know these private keys are the default Anvil accounts.

## contracts/constants/networks/APE_CHAIN_CURTIS.sol — Grade: B-
- Provides deterministic addresses for Ape Chain’s Curtis environment (chain id, Camelot config, etc.), enabling scripts to swap RPC targets without manual edits.
- No tests assert that these addresses resolve or that the router code hash matches actual deployments, so mistakes would only surface on-chain.
- Consider grouping shared constants (factory, router, pair hash) into a base library to avoid copying between Curtis/Main.

## contracts/constants/networks/APE_CHAIN_MAIN.sol — Grade: B
- Much richer constant map covering Camelot, Ape Express, Crane deployments, and Indexed vault components, giving deploy scripts a single source of truth.
- Embeds raw `CREATE2` bytecode blobs to freeze canonical factories—great for determinism but lacking comments about the compiler version used to capture them.
- The sheer size makes manual auditing hard; unit tests that hash these blobs and assert equality against deployed bytecode would provide early warning if something drifts.

## contracts/constants/networks/ARB_OS_PRECOMPILES.sol — Grade: B
- Simple mapping that surfaces the Arbitrum OS owner precompile address so cross-chain scripts don’t rely on magic numbers.
- Would benefit from a reference to the official docs or a comment noting compatibility with Nitro vs. Nova deployments.

## contracts/constants/networks/ETHEREUM_MAIN.sol — Grade: B+
- Comprehensive registry for every major protocol the repo integrates with (Uniswap V2/V3, Multicall, Permit2, Balancer V2/V3, etc.), enabling deterministic scripting on mainnet.
- Organized into logical sections, which helps maintainers add/remove addresses without missing related entries.
- Coverage would be stronger if there were smoke tests that verify critical addresses (e.g., factory bytecode, chain IDs) before running live deployments; otherwise typos could go unnoticed.

## contracts/constants/networks/ETHEREUM_SEPOLIA.sol — Grade: B-
- Mirrors the mainnet registry with Sepolia endpoints so scripts/tests can flip networks without editing addresses, and keeps sections consistent (WETH, Uniswap V2, Balancer V2/V3, Permit2).
- Several entries still carry TODOs or obvious typos (e.g., `BLANACER` typo, missing Uniswap fee-to) and there is no validation harness confirming these addresses resolve, so drift will only be caught on-chain.
- Consider adding comments on which deployments are canonical testnets vs. mocks, and add smoke tests hashing deployed bytecode for the routers/factories to catch miscopied constants.

## contracts/constants/networks/LOCAL.sol — Grade: B
- Serves as the single source of truth for the local Anvil chain ID (31337), which prevents helpers from sprinkling the number throughout test code.
- No documentation or namespacing beyond the constant; add a comment noting this maps to the default Foundry network so future forks can adjust accordingly.
- Could expand to include default addresses (e.g., VM cheatcode, dev wallets) to keep local-only scripts DRY.

## contracts/constants/protocols/dexes/balancer/v3/BalancerV3_CONSTANTS.sol — Grade: B
- Captures the weighted pool pause window constant once so forks don’t duplicate the 365-day magic number.
- File lacks context (link to Balancer governance proposal or spec) making it unclear whether 365 days is immutable; a brief comment would help future auditors.
- Consider moving additional Balancer V3 protocol constants here instead of sprinkling them through packages to consolidate knowledge.

## contracts/constants/protocols/utils/permit2/PERMIT2_CONSTANTS.sol — Grade: B+
- Provides both init code and exec code blobs for `BetterPermit2`, plus the pre-computed creation code hash, which is critical for deterministic deployments.
- Massive inline hex blob is undocumented—include the compiler version or commit hash used to capture it so future engineers can regenerate it deterministically.
- Tests should assert `keccak256(type(BetterPermit2).creationCode)` matches `PERMIT2_INIT_CODE_HASH`; right now any mismatch would slip into production.

## contracts/factories/create3/Create3Factory.sol — Grade: B
- Factory cleanly centralizes deterministic deployments (plain create3, facets, packages) and auto-registers metadata so downstream discovery APIs stay in sync.
- Administrative flows reuse `MultiStepOwnable`/`Operable` modifiers, reducing duplicated access control, and storage sets make interface/function lookups efficient.
- `setDiamondPackageFactory` writes to `diamondPackageFactory` but nothing ever reads it, and `_deplayPackage` typo plus lack of events/tests around registration make it easy to introduce silent drift—consider wiring the factory reference into package deploys and adding coverage for the registration maps.

## contracts/factories/create3/Create3FactoryAwareFacet.sol — Grade: B
- Thin facet exposing the repo’s stored factory address via the `ICreate3FactoryAware` interface, avoiding duplicate storage across packages.
- No access control or initialization helpers—callers must ensure `Create3FactoryAwareRepo` is initialized elsewhere or this will return address zero; document that requirement.
- Tests verifying `create3Factory()` reflects the repo slot (and updates after reinit) would prevent regressions when the storage namespace changes.

## contracts/factories/create3/Create3FactoryAwareRepo.sol — Grade: B
- Storage library follows the standard pattern (fixed slot constant, `_layout()` helper) so both facets and targets can share the factory reference safely.
- Provides both explicit-slot and default-slot initialize helpers, which is handy for diamonds embedding the repo at alternate offsets.
- Missing events or guards make reinitialization silent; consider emitting when the factory pointer changes or at least documenting that repeated `_initialize` calls simply overwrite the pointer.

## contracts/factories/diamondPkg/Behavior_IFacet.sol — Grade: A-
- Rich behavior library for Foundry that logs expectations, records comparator baselines, and validates `IFacet` metadata (name, interfaces, selectors) with reusable helpers.
- Strong separation between expectation recording and validation, plus consistent error prefixes, makes debugging failing behavior tests far easier.
- Minor nit: heavily relies on global storage via repos/comparators but never cleans them up between tests; documenting that requirement or adding reset helpers would reduce cross-test coupling.

## contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol — Grade: B-
- Implements the deterministic CREATE2 proxy deployment loop for packages and wires ERC165/diamond loupe/post-deploy hook facets automatically before invoking the package’s own config.
- Uses `pkgOfAccount`/`pkgArgsOfAccount` to pass context into the proxy’s `initAccount`, but never deletes those entries once initialization succeeds, so stale data accumulates and could be read by a malicious package if the proxy address is reused.
- Duplicate `import {Creation}` line and unused `diamondPackageFactory`-style safety nets (e.g., no guard ensuring `pkg` implements expected callbacks) hint at drift; consider adding tests proving `deploy()` reverts when salts collide and that `pkgConfig()` data clears after `initAccount` runs.

## contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol — Grade: B
- Mirrors the other `*AwareRepo` patterns with a dedicated storage slot and overloads to initialize either via explicit layout or default slot, making it easy for facets to share the callback factory reference.
- No events or protections around `_initialize`, so multiple callers could race to replace the pointer; documenting ownership expectations or emitting a `FactoryUpdated` event would help auditing.
- Style nit: long `_initialize` line exceeds 120 chars; wrapping parameters would improve readability and match the rest of the repo’s formatting.

## contracts/factories/diamondPkg/DiamondPackageCallbackFactoryAwareFacet.sol — Grade: B
- Facet exposes the stored callback factory via `IDiamondPackageCallbackFactoryAware` so packages can wire the dependency without duplicating storage.
- Metadata helpers return a single selector and keep `type(...)` usage consistent, but there are no tests here verifying alignment with the interface or that `facetMetadata()` stays updated.
- Relies on `DiamondPackageFactoryAwareRepo` being initialized elsewhere; consider documenting that requirement or adding a setter function guarded by ownership so diamonds can self-configure.

## contracts/factories/diamondPkg/DiamondPackageFactoryAwareRepo.sol — Grade: B
- Storage helper follows the canonical layout/slot pattern and provides both explicit-slot and default-slot initialization helpers for flexibility inside diamonds.
- `_initialize` simply overwrites the pointer with no event or idempotency guard, so accidental double-initialization silently swaps factories; emitting a `FactoryUpdated` event would improve traceability.
- Naming of `diamondPackageFactory` parameter vs storage member matches but the API lacks a getter that enforces non-zero assignments—consider adding an `if (address(factory) == address(0)) revert` to prevent null configs.

## contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol — Grade: B
- Implements `IPostDeployAccountHook` by delegatecalling the associated package’s `postDeploy` routine, ensuring any diamond-specific wiring runs in the proxy’s context.
- Uses `BetterAddress.functionDelegateCall`, so reverts bubble correctly, but the facet never validates that `msg.sender` is the expected proxy/factory—malicious callers could trigger arbitrary package hooks if exposed publicly.
- Lacks NatSpec or events around the hook execution; adding a lightweight log would help diagnose failed post-deploy runs during scripted deployments.

## contracts/factories/diamondPkg/TestBase_IFacet.sol — Grade: A-
- Abstract Foundry test fixture that forces inheritors to supply the facet instance plus expected metadata, then reuses `Behavior_IFacet` comparators for deterministic assertions.
- `setUp()` auto-wires `testFacet = facetTestInstance()` which keeps individual tests lean, and helper comments explain the intended override points.
- Could add a guard ensuring `testFacet` is non-zero (or revert with a helpful message) to catch misconfigured inheritors earlier, but otherwise an excellent reusable base.

## contracts/factories/diamondPkg/utils/DiamondFactoryPackageAdaptor.sol — Grade: B
- Library centralizes delegatecall glue into `IDiamondFactoryPackage`, keeping the CREATE3 factory logic agnostic of each package’s internal storage schema.
- Each helper decodes return data but never checks for zero-length responses or malformed ABI—one bad package implementation could cause undefined behavior; consider relying on `abi.decode` with explicit error strings or adding sanity checks.
- Functions are `internal` and state-free, but adding NatSpec to clarify that they must be called from the intended proxy context (due to delegatecall) would prevent misuse.

## contracts/factories/diamondPkg/utils/FactoryCallBackAdaptor.sol — Grade: B-
- Provides a single `_initAccount` helper that delegatecalls `IFactoryCallBack.initAccount`, reducing boilerplate for factories wiring callbacks.
- Ignores the return data entirely (commented decode), so any information the callback tried to return is lost; if callbacks need to surface salts or hashes later, this adaptor will need to reintroduce decoding.
- Library should also document that it expects `callBack` to be deployed with the proper storage layout; otherwise `functionDelegateCall` could corrupt state without warning.

## contracts/interfaces/BetterIERC20.sol — Grade: B
- Simple composite interface extending ERC20 core, metadata, and standardized error set so downstream contracts can rely on a single import.
- Lacks NatSpec pointing to the merged selector set or clarifying that it does not add new functions; adding references to ERC-20 and ERC-6093 specs would improve clarity.
- Consider renaming the author placeholder (“who?”) to a real contact or removing it to keep documentation polished.

## contracts/interfaces/BetterIERC20Permit.sol — Grade: B
- Bundles ERC-5267 domain separator metadata with the repo’s `IERC2612` (which itself conforms to ERC-20 Permit), providing a single interface for wallets that need both views.
- Keeps SPDX/pragma aligned with the rest of the repo and includes a terse NatSpec summary; no custom selectors are introduced.
- Would benefit from explicit mention that it is equivalent to OpenZeppelin’s `IERC20Permit` plus `IERC5267` so auditors know there’s no bespoke behavior.

## contracts/interfaces/IBalancerV3BasePoolFactory.sol — Grade: B
- Extends the general `IBasePoolFactory` interface with a single `tokenConfigs()` helper to inspect per-pool token parameters, which matches Balancer V3 expectations.
- `TokenConfig` import comes from the shared Vault types module, keeping structs consistent across packages.
- Missing documentation for `tokenConfigs` return ordering or length guarantees; a comment referencing Balancer’s spec would make integrations safer.

## contracts/interfaces/IBalancerV3VaultAware.sol — Grade: B
- Minimal interface that standardizes how components expose the Balancer V3 vault and authorizer, reducing ABI drift across packages.
- Includes custom selector annotations, which helps codegen tools map to the right functions even if names change.
- No guarantees are stated about the relationship between `balV3Vault()` and `getVault()` (they likely alias); adding NatSpec clarifying this would avoid duplicated calls in consumers.

## contracts/interfaces/ICreate3Factory.sol — Grade: B+
- Comprehensive interface covering factory ownership hooks, Create3 deployment helpers, and the facet/package registries so downstream code can mock the factory cleanly.
- NatSpec at the top still references “Create2” (copy/paste nit) and several functions lack selector annotations, reducing ABI clarity.
- Consider tagging view functions that may revert (e.g., `packagesByFacet`) and documenting ordering guarantees so indexers know whether results are deterministic.

## contracts/interfaces/ICreate3FactoryAware.sol — Grade: B
- Straightforward awareness interface exposing the current factory pointer, keeping dependency injection consistent across facets.
- Depends on `ICreate3Factory`, so changes to the factory ABI automatically propagate.
- Missing NatSpec about initialization requirements (callers must ensure the repo slot is populated), which could prevent subtle address-zero bugs.

## contracts/interfaces/IDiamond.sol — Grade: C
- File merely re-exports the canonical ERC-2535 `IDiamond` interface from the repo’s introspection module, so consumers can import from a central location.
- Lacks any documentation or type aliasing; if consolidation is the only goal, consider deleting this passthrough to avoid double maintenance.
- If retained, adding NatSpec that points to the source contract would help explain why this wrapper exists.

## contracts/interfaces/IDiamondCut.sol — Grade: B
- Implements the standard ERC-2535 `diamondCut` signature with clear parameter names and selector annotation, useful for tooling.
- Imports the shared `IDiamond` type for facet definitions, reducing duplication.
- Could include notes on expected revert reasons/events to guide implementers; right now it references a custom event in comments but not in code.

## contracts/interfaces/IDiamondFactoryPackage.sol — Grade: B
- Defines the full package lifecycle (metadata, salt calculation, arg processing, init/post-deploy) and documents selector IDs for key operations.
- Helpful ASCII diagram explains the hand-off between factory, package, and proxy, which makes the workflow easier to reason about.
- Many NatSpec sections still contain placeholder text or missing return docstrings (e.g., `processArgs` comment missing `@return`), so polishing those would aid integrators.

## contracts/interfaces/IDiamondLoupe.sol — Grade: B
- Matches EIP-2535’s loupe API, adds custom errors for clearer revert reasons, and annotates selectors for ABI tooling.
- TODO comments admit NatSpec/tests are incomplete; implementing those would boost confidence, especially for the external versions hint.
- Consider documenting gas expectations or ordering guarantees for `facets()` since large diamonds can be expensive to introspect.

## contracts/interfaces/IDiamondPackageCallBackFactory.sol — Grade: B-
- Interface mirrors the large comment diagram from the implementation, covering constants, facet accessors, package tracking, and deployment helpers.
- Exposes storage mappings (`pkgOfAccount`, `pkgArgsOfAccount`) for read-only inspection, which is handy for monitoring deployments.
- Still lacks NatSpec for most functions and doesn’t mention lifecycle expectations (e.g., when pkg args are cleared), so consumers must dig into the implementation to understand invariants.

## contracts/interfaces/IDiamondPackageCallbackFactoryAware.sol — Grade: B
- Minimal interface that lets packages query the callback factory from any context, ensuring dependency wiring is discoverable.
- Purely declarative; suggests a clear seam for mocking or substituting factories during testing.
- Could specify whether the returned address may be zero or if implementations must guarantee a valid factory.

## contracts/interfaces/IEIP712.sol — Grade: C
- Simple passthrough importing Uniswap’s Permit2 `IEIP712`, ensuring consistency with upstream typed-data domain encodings.
- Local interface is entirely commented out, so the file provides no ABI on its own; either re-export the interface properly or delete to avoid confusion.
- Consider documenting why the external dependency is preferred (e.g., to align with Permit2) so future maintainers know not to rewrite it locally.

## contracts/interfaces/IERC165.sol — Grade: B
- Re-exports OpenZeppelin’s `IERC165`, which keeps remappings consistent and avoids accidental version drift between packages.
- With only two lines, serves as a convenient import alias for the rest of the repo.
- Could include a short note explaining why OZ’s implementation is reused (audit pedigree, etc.) to justify the wrapper’s existence.

## contracts/interfaces/IERC20.sol — Grade: B
- Thin alias that re-imports OpenZeppelin’s canonical ERC-20 interface so local packages inherit audited semantics without maintaining their own copy.
- Keeps SPDX/pragma aligned and relies on remappings, but offers no NatSpec explaining why the wrapper exists; consider clarifying to prevent duplicate local definitions.
- If additional hooks (errors, metadata) are always paired, documenting that expectation here would guide integrators toward `BetterIERC20` instead.

## contracts/interfaces/IERC20Errors.sol — Grade: B-
- Simple re-export of OZ’s draft IERC6093 error interface, ensuring downstream contracts share the same revert selectors.
- File is otherwise empty—adding comments about the draft status or version pinned would help future upgrades.
- Consider switching to the stable release once IERC6093 finalizes, and document any deviations the repo expects.

## contracts/interfaces/IERC20Metadata.sol — Grade: B
- Local reproduction of the optional metadata functions avoids pulling OZ’s full extension, which may simplify dependency trees.
- Because it manually declares the interface, it risks drifting from upstream (e.g., if OZ adds documentation/events); note in comments that this mirrors ERC-20 spec and should stay in sync.
- Uncommenting the OZ import and re-exporting would reduce maintenance overhead if no customizations are needed.

## contracts/interfaces/IERC20MintBurn.sol — Grade: B
- Adds mint/burn hooks with selector annotations so factories can reference standardized management interfaces.
- No events or error semantics are defined—implementers must emit their own transfer/mint logs—so documenting expectations would avoid inconsistent behavior.
- Consider extending `IERC20` here or explicitly noting that callers must also implement transfer/allowance to avoid misuse.

## contracts/interfaces/IERC20Permit.sol — Grade: B
- Straight OZ re-export, keeping Permit semantics consistent and audited.
- Lacks commentary on replay/nonces; referencing ERC-2612 or pointing consumers to `BetterIERC20Permit` would make the dependency chain clearer.

## contracts/interfaces/IERC2612.sol — Grade: B+
- Extends OZ’s `IERC20Permit` and adds explicit custom errors for expired signatures, invalid signers, and nonce mismatches, which improves revert clarity for integrators.
- Large explanatory comment from OZ provides security guidance; nice to keep for maintainers.
- Commented-out function declarations could be pruned or replaced with references to the inherited interface to avoid confusion.

## contracts/interfaces/IERC4626.sol — Grade: B
- Copies the full ERC-4626 spec (events, preview helpers, deposit/withdraw flows) and extends `IERC4626Errors` so implementers share the same revert surface.
- Because it removes the direct OZ dependency, future spec updates must be pulled manually—include a note about the upstream version (mentions v5.5.0) so diffing is easier later.
- Consider uncommenting the base ERC20 imports or referencing them to signal the interface requirements.

## contracts/interfaces/IERC4626Errors.sol — Grade: B
- Enumerates all standard ERC-4626 error cases plus a custom `TransferNotReceived`, giving vaults clearer revert messages.
- TODO comment suggests moving the transfer error elsewhere; documenting when that migration will happen would reduce confusion.
- Might add NatSpec on expected revert scenarios (e.g., when `max` is zero) to guide integrators implementing front-end guards.

## contracts/interfaces/IERC4626RateProvider.sol — Grade: B
- Consider documenting whether `rate()` should proxy `convertToAssets(1e18)` or some other metric so implementers stay consistent.


## contracts/interfaces/IERC721.sol — Grade: B

## contracts/interfaces/IERC721Enumerated.sol — Grade: B-
- Providing selector annotations or clarifying that `globalOperatorOf` is optional would help integrators know how to rely on this extension.

- Notes the upstream version (v5.4.0), which is helpful—keep that updated when pulling changes.
- Consider re-exporting OZ’s interface directly to avoid drift unless there’s a reason to freeze this version.
- Minimal mint/burn extension defining hooks for ID assignment and metadata-aware minting—helpful for factories issuing NFTs.
- Lacks selector annotations/events and does not specify access control expectations; adding NatSpec would make it clearer who may call these functions.
## contracts/interfaces/IERC8109Introspection.sol — Grade: B
- Simply re-exports the introspection interface from the canonical ERC8109 module, keeping remaps consistent.
## contracts/interfaces/IERC8109Update.sol — Grade: B
- Similar passthrough for the update interface; ensures consumers target the same ABI as the introspection module.

## contracts/interfaces/IFacet.sol — Grade: A-
- Could specify whether `facetInterfaces` must align with ERC165 interfaces and how to handle duplicates, but otherwise excellent.

- Since callbacks rely on delegatecall context, a note reminding implementers about storage layout assumptions would be valuable.

## contracts/interfaces/IFactoryWidePauseWindow.sol — Grade: B
- Encapsulates Balancer-style pause window queries so factories and pools can share the same ABI; selector annotations provide clarity.
- Docstrings explain intent and expected behaviors (return 0 after expiry), which is helpful for auditors.
- Might include ranges (e.g., units in seconds) or reference the Balancer governance proposal for completeness.

## contracts/interfaces/IHandler.sol — Grade: B-
- Tiny interface returning selector arrays, presumably for fuzz handlers or routers; useful but under-documented.
- No guidance on ordering or whether duplicates are allowed—tests relying on this may produce inconsistent results.
- Consider renaming to something more specific (e.g., `ICalleeSelectorProvider`) or adding NatSpec to explain the pattern.

## contracts/interfaces/IMultiStepOwnable.sol — Grade: A-

## contracts/tokens/ERC4626/TestBase_ERC4626.sol — Grade: B-
- `invariant_totalAssets_bounded()` immediately returns any time the ghost withdrawal counter exceeds deposits, so the test never flags the exact scenario it is supposed to catch (assets draining faster than deposits); the guard at [contracts/tokens/ERC4626/TestBase_ERC4626.sol#L55-L70](contracts/tokens/ERC4626/TestBase_ERC4626.sol#L55-L70) should assert instead of short-circuiting.
- `invariant_totalSupply_nonNegative()` asserts that an unsigned integer is ≥ 0 and therefore adds no coverage, leaving negative-share drifts or rounding debt entirely to other invariants; see [contracts/tokens/ERC4626/TestBase_ERC4626.sol#L71-L80](contracts/tokens/ERC4626/TestBase_ERC4626.sol#L71-L80).
- Both rounding invariants poke a single hard-coded magnitude (1000e18 for assets and 1000e21 for shares), so large and tiny conversions are never exercised and precision bugs can hide outside that scale; the fixed probes live at [contracts/tokens/ERC4626/TestBase_ERC4626.sol#L105-L140](contracts/tokens/ERC4626/TestBase_ERC4626.sol#L105-L140).

## contracts/tokens/ERC721/Behavior_IERC721.sol — Grade: B-
- `isValid_transfer()` subtracts `1` from the sender’s pre-transfer balance even when the transfer is supposed to be a no-op (e.g., `from == to`), so legitimate self-transfers are labelled invalid; see [contracts/tokens/ERC721/Behavior_IERC721.sol#L70-L81](contracts/tokens/ERC721/Behavior_IERC721.sol#L70-L81).
- The same subtraction executes unconditionally, so when tests intentionally probe zero-balance senders the helper underflows and reverts instead of returning `false`, masking the failure mode it is meant to observe ([contracts/tokens/ERC721/Behavior_IERC721.sol#L72-L78](contracts/tokens/ERC721/Behavior_IERC721.sol#L72-L78)).

## contracts/tokens/ERC721/ERC721EnumeratedFacet.sol — Grade: C
- `facetFuncs()` allocates a seven-entry selector array but never writes index 2, leaving a zero selector to be advertised through the loupe and breaking downstream tooling that expects every entry to be meaningful ([contracts/tokens/ERC721/ERC721EnumeratedFacet.sol#L45-L64](contracts/tokens/ERC721/ERC721EnumeratedFacet.sol#L45-L64)).
- The facet only declares the `IERC721Enumerated` interface ID even though it also exposes core ERC721 selectors (both `safeTransferFrom` overloads plus `transferFrom`), so ERC165 callers will never be told that this facet is servicing those methods ([contracts/tokens/ERC721/ERC721EnumeratedFacet.sol#L17-L70](contracts/tokens/ERC721/ERC721EnumeratedFacet.sol#L17-L70)).

## contracts/tokens/ERC721/ERC721EnumeratedRepo.sol — Grade: C-
- Global enumeration is never populated: `_mint()` calls into `ERC721Repo` and only updates the owner-set, so `tokenIds()` always returns an empty array because `allTokenIds` is untouched ([contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L20-L40](contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L20-L40) and [contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L132-L141](contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L132-L141)).
- `_burn()` deletes the owner’s entry but never removes the token from `allTokenIds`, meaning burned IDs remain observable even after they cease to exist ([contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L146-L155](contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L146-L155)).
- `globalOperatorOfAccount` is a single `address` slot per owner, so the public `globalOperatorOf()` helper can only ever return the last operator that was set to `true`—all previous approvals are silently lost and multiple concurrent operators (as permitted by ERC721) are impossible ([contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L16-L25](contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L16-L25) and [contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L118-L131](contracts/tokens/ERC721/ERC721EnumeratedRepo.sol#L118-L131)).

## contracts/tokens/ERC721/ERC721Facet.sol — Grade: B-
- `approve()` and `setApprovalForAll()` simply forward into `ERC721Repo`, which only lets the token owner call `approve` and forbids zero-address approvals, so operators delegated through `setApprovalForAll` cannot refresh per-token approvals and owners cannot clear approvals as the ERC721 spec requires ([contracts/tokens/ERC721/ERC721Facet.sol#L85-L104](contracts/tokens/ERC721/ERC721Facet.sol#L85-L104) and [contracts/tokens/ERC721/ERC721Repo.sol#L121-L130](contracts/tokens/ERC721/ERC721Repo.sol#L121-L130)).
- Because this facet omits `supportsInterface`, it cannot advertise ERC721 compliance on its own; any package exposing it must remember to route ERC165 checks through another facet or wallets will fail capability probing ([contracts/tokens/ERC721/ERC721Facet.sol#L17-L69](contracts/tokens/ERC721/ERC721Facet.sol#L17-L69)).

## contracts/tokens/ERC721/ERC721MetadataFacet.sol — Grade: C
- `tokenURI()` never verifies that `tokenId` actually exists in the core repo, so a query against an unminted ID returns the bare `baseURI` (or empty string) instead of reverting as ERC721 metadata requires ([contracts/tokens/ERC721/ERC721MetadataFacet.sol#L72-L86](contracts/tokens/ERC721/ERC721MetadataFacet.sol#L72-L86)).
- When only a `baseURI` is set, the function simply returns that base for every token and never appends the tokenId, producing identical metadata for the entire collection unless every token has an explicit override ([contracts/tokens/ERC721/ERC721MetadataFacet.sol#L72-L86](contracts/tokens/ERC721/ERC721MetadataFacet.sol#L72-L86)).

## contracts/tokens/ERC721/ERC721MetadataRepo.sol — Grade: C+
- Both `_initialize` overloads happily overwrite `name`, `symbol`, and `baseURI` without guarding against re-entry or zero values, so any facet granted access can silently mutate collection identity after deployment ([contracts/tokens/ERC721/ERC721MetadataRepo.sol#L24-L44](contracts/tokens/ERC721/ERC721MetadataRepo.sol#L24-L44)).
- `_setTokenURI` writes directly to storage without emitting an event, leaving indexers blind to metadata changes and forcing them to diff storage off-chain ([contracts/tokens/ERC721/ERC721MetadataRepo.sol#L77-L83](contracts/tokens/ERC721/ERC721MetadataRepo.sol#L77-L83)).

## contracts/tokens/ERC721/ERC721Repo.sol — Grade: D+
- `_approve` reverts when passed `address(0)`, so callers cannot clear approvals as mandated by ERC721 (`approve(address(0), tokenId)` should revoke); see [contracts/tokens/ERC721/ERC721Repo.sol#L121-L124](contracts/tokens/ERC721/ERC721Repo.sol#L121-L124).
- The same helper only allows the token owner to call it and ignores operator approvals, meaning `setApprovalForAll` cannot actually delegate approval management despite emitting success ([contracts/tokens/ERC721/ERC721Repo.sol#L124-L130](contracts/tokens/ERC721/ERC721Repo.sol#L124-L130)).
- Attempting to approve a nonexistent token yields `ERC721IncorrectOwner` because `_ownerOf` returns zero, rather than the standard `ERC721NonexistentToken`, making it harder to distinguish typos from access-control errors ([contracts/tokens/ERC721/ERC721Repo.sol#L124-L130](contracts/tokens/ERC721/ERC721Repo.sol#L124-L130)).

## contracts/tokens/ERC721/ERC721Target.sol — Grade: B-
- The target exposes the full ERC721 surface but never implements `supportsInterface`, so contracts that wire this target without an additional ERC165 facet will fail interface detection even though the methods exist ([contracts/tokens/ERC721/ERC721Target.sol#L16-L70](contracts/tokens/ERC721/ERC721Target.sol#L16-L70)).
- No metadata or enumerated hooks are provided, so anyone expecting `IERC721Metadata`/`IERC721Enumerable` compliance must bolt on extra facets; documenting that requirement alongside the target would prevent accidental under-featured deployments ([contracts/tokens/ERC721/ERC721Target.sol#L16-L70](contracts/tokens/ERC721/ERC721Target.sol#L16-L70)).

## contracts/tokens/ERC721/ERC721TargetStub.sol — Grade: C
- `mint()` is callable by any address and forwards straight into the repo, so if this stub ever leaks into production anyone can inflate supply arbitrarily ([contracts/tokens/ERC721/ERC721TargetStub.sol#L18-L23](contracts/tokens/ERC721/ERC721TargetStub.sol#L18-L23)).
- Both `burn` overloads are likewise permissionless, allowing arbitrary destruction of other users’ NFTs; this is acceptable in a test stub but should be loudly documented to avoid accidental reuse ([contracts/tokens/ERC721/ERC721TargetStub.sol#L26-L36](contracts/tokens/ERC721/ERC721TargetStub.sol#L26-L36)).

## contracts/tokens/ERC721/ERC721TargetStubHandler.sol — Grade: C
- The handler enforces that `approve` and `setApprovalForAll` revert when the operator is the zero address, so any ERC721 implementation that correctly uses `address(0)` to clear approvals will immediately fail these invariants and appear “unsafe” even though the standard requires that behaviour ([contracts/tokens/ERC721/ERC721TargetStubHandler.sol#L115-L149](contracts/tokens/ERC721/ERC721TargetStubHandler.sol#L115-L149)).
- `_removeToken()` only flips a boolean and never compacts `_tokenIds`, so `tokenCount()` keeps growing forever and invariants that rely on it are iterating tombstones rather than the live supply ([contracts/tokens/ERC721/ERC721TargetStubHandler.sol#L56-L66](contracts/tokens/ERC721/ERC721TargetStubHandler.sol#L56-L66) and [contracts/tokens/ERC721/ERC721TargetStubHandler.sol#L187-L190](contracts/tokens/ERC721/ERC721TargetStubHandler.sol#L187-L190)).

## contracts/tokens/ERC721/TestBase_ERC721.sol — Grade: C+
- `invariant_sumBalances_equals_supply()` subtracts `ghostTotalBurned` from `ghostTotalMinted` before making any assertion, so a genuine bug that lets burns outpace mints will panic with an underflow instead of failing with the custom error message ([contracts/tokens/ERC721/TestBase_ERC721.sol#L54-L70](contracts/tokens/ERC721/TestBase_ERC721.sol#L54-L70)).
- `invariant_balances_nonnegative()` simply asserts that a `uint256` is ≥ 0, which can never fail; keeping this placeholder around gives a false sense of coverage and wastes fuzz budget ([contracts/tokens/ERC721/TestBase_ERC721.sol#L85-L94](contracts/tokens/ERC721/TestBase_ERC721.sol#L85-L94)).

## contracts/utils/BetterAddress.sol — Grade: B-
- The recursive `_sort(address[] memory _arr, uint256 unsortedLen)` trusts callers to pass an `unsortedLen` that is ≤ the array’s length; any misuse (even an off-by-one) will read past the end of `_arr` and revert or scribble over memory ([contracts/utils/BetterAddress.sol#L219-L236](contracts/utils/BetterAddress.sol#L219-L236)).
- `codeAt()` silently returns empty bytes any time `isContract()` is false, even though the file already defines a `NotAContract` error; this makes it impossible for call sites to distinguish “account never deployed” from “contract self-destructed but had bytecode you expected” ([contracts/utils/BetterAddress.sol#L96-L120](contracts/utils/BetterAddress.sol#L96-L120)).

## contracts/utils/BetterBytes.sol — Grade: D
- Every scalar decoder (`_toUint8`, `_toUint16`, `_toUint32`, etc.) reads from `add(add(_bytes, N), _start)` where `N` is the element size, but ABI-encoded bytes store their payload after the first 32 bytes; these helpers therefore sample the length field (or the wrong offset) and return garbage for any `start > 0` ([contracts/utils/BetterBytes.sol#L108-L170](contracts/utils/BetterBytes.sol#L108-L170)).
- `_toBytes32` suffers the same missing `0x20` offset, so callers decoding struct fields out of calldata/storage will compare the wrong value and potentially accept malicious data ([contracts/utils/BetterBytes.sol#L170-L183](contracts/utils/BetterBytes.sol#L170-L183)).

## contracts/utils/BetterEfficientHashLib.sol — Grade: A-
- Thin wrappers around Solady’s `EfficientHashLib` keep the project on battle-tested hashing code while exposing a consistent `_hash` API that mirrors the local naming scheme ([contracts/utils/BetterEfficientHashLib.sol#L9-L214](contracts/utils/BetterEfficientHashLib.sol#L9-L214)).
- Helper methods like `_malloc`/`_free` and the slice hashing adapters make it easy to work with bytes32 buffers without reimplementing assembly, which reduces the surface for custom mistakes ([contracts/utils/BetterEfficientHashLib.sol#L214-L288](contracts/utils/BetterEfficientHashLib.sol#L214-L288)).

## contracts/utils/BetterStrings.sol — Grade: C+
- `_parseFixedPoint()` rescales values by multiplying with `10 ** (2 - decimals)` whenever `decimals < 2`, so a 256-bit input and a token with 0 decimals will overflow before producing the human-readable string ([contracts/utils/BetterStrings.sol#L205-L236](contracts/utils/BetterStrings.sol#L205-L236)).
- `_marshall()`/`_unmarshallAsString()` advertise consistency for encoded addresses, yet they actually ABI-encode plain strings; any component that expects packed address bytes will decode the wrong length and mis-handle cross-contract messages ([contracts/utils/BetterStrings.sol#L273-L302](contracts/utils/BetterStrings.sol#L273-L302)).

## contracts/utils/Bytecode.sol — Grade: B
- `_create3AddressFromOf()` plus `create3()` enforce deterministic CREATE3 deployments and explicitly revert when a salt has already been used, which prevents accidental overwrites of existing logic ([contracts/utils/Bytecode.sol#L245-L323](contracts/utils/Bytecode.sol#L245-L323)).
- The library also exposes `_create2WithArgsAddressFromOf()`/`create2WithArgs()` helpers so callers can compute deterministic CREATE2 addresses using the same bytecode concatenation logic as the factory, keeping tooling and runtime behaviour aligned ([contracts/utils/Bytecode.sol#L148-L214](contracts/utils/Bytecode.sol#L148-L214)).

## contracts/utils/Bytes32.sol — Grade: B
- `_toHexString()` and `_packEqualPartitions()` provide deterministic formatting of bytes32 values for logging and selector packing, keeping inspector tooling aligned with on-chain layouts ([contracts/utils/Bytes32.sol#L22-L78](contracts/utils/Bytes32.sol#L22-L78)).
- `_scramble()` derives a per-contract mask from `keccak256(address(this))`, which is useful for cheaply obfuscating storage-mapped sentinels when contracts running in the same diamond need disjoint guard values ([contracts/utils/Bytes32.sol#L13-L21](contracts/utils/Bytes32.sol#L13-L21)).

## contracts/utils/Bytes4.sol — Grade: C+
- `_toString()` concatenates `0x` with the raw four-byte selector payload, yielding a string that contains binary data rather than ASCII hex; any UI that expects human-readable selectors will render gibberish ([contracts/utils/Bytes4.sol#L26-L33](contracts/utils/Bytes4.sol#L26-L33)).
- `_append()` dynamically allocates a brand new array every time two selector lists are merged, so composing large policy tables is O(n²) in both gas and memory; consider reusing storage slots or in-place concatenation when possible ([contracts/utils/Bytes4.sol#L48-L74](contracts/utils/Bytes4.sol#L48-L74)).

## contracts/utils/Creation.sol — Grade: B-
- The library is a very thin façade over `Bytecode`, so contracts with `using Creation for bytes` inherit the deterministic CREATE2/CREATE3 helpers without re-importing the heavier file ([contracts/utils/Creation.sol#L1-L74](contracts/utils/Creation.sol#L1-L74)).
- `_create2()`/`create3WithArgs()` merely forward to the Bytecode implementations, but they duplicate the stale `ByteCodeUtils` revert strings—if you rely on these helpers for debugging you will get misleading error sources until the messages are updated ([contracts/utils/Creation.sol#L54-L115](contracts/utils/Creation.sol#L54-L115)).
- Clearly documented three-step ownership transfer interface with explicit events and custom errors, matching the repo’s implementation details.
- Comments explain each phase (initiate, confirm, accept) and emphasize buffer periods; great for integrators building UI flows.
- Could add selector annotations for consistency with other interfaces, but the NatSpec is otherwise thorough.

## contracts/interfaces/IOperable.sol — Grade: B+
- Defines operator authorization flows with selector annotations and custom events, giving packages a consistent ABI to enforce per-function permissions.
- Documentation explains the purpose of each call, though cross-referencing the repo’s repo library would help highlight storage expectations.
- Consider noting that setters should be owner-gated to prevent misuse; the interface alone doesn’t specify access control.

## contracts/interfaces/IPermit2Aware.sol — Grade: B
- Simple awareness pattern returning the configured Permit2 contract, letting packages inject the shared allowance router.
- Imports Uniswap’s canonical `IPermit2`, ensuring ABI compatibility.
- Lacks NatSpec describing whether the pointer can be zero or whether consumers may cache it; adding that would prevent subtle bugs.

## contracts/interfaces/IPostDeployAccountHook.sol — Grade: B
- Minimal interface for post-deployment hooks (`postDeploy()`), complete with selector annotation so factories can reference it reliably.
- Would benefit from documenting expected side effects (delegatecall context, revert semantics) since the implementation relies heavily on that behavior.

## contracts/interfaces/IReentrancyLock.sol — Grade: B
- Simple lock inspection interface with a custom `IsLocked` error, mirroring the repo’s guard library.
- Could include selector annotations and mention that `isLocked()` should be view-only, but otherwise straightforward.

## contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol — Grade: C
- `_initialize()` blindly accepts whatever `poolManager` it is passed; if a deployment script forgets to supply a real address the Balancer vault ends up with the zero address as pause manager, swap-fee manager, and pool creator ([contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol#L31-L63](contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol#L31-L63)).
- `_setTokenConfigs()` only ever appends into `tokensOfPool` and never removes addresses that disappear from later configs, so stale assets remain enumerable forever and `_getTokenConfigs()` keeps returning them even after the pool is supposed to be downgraded ([contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol#L96-L137](contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol#L96-L137)).
- The storage slot is globally fixed via `keccak256("protocols.dexes.balancer.v3.base.pool.factory.common")`, which means every factory instance inside the same diamond shares a single pool list, pause window, and manager ([contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol#L13-L25](contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol#L13-L25)).

## contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_WeightedPool.sol — Grade: D
- The file contains only the SPDX and pragma lines ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_WeightedPool.sol#L1-L2](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_WeightedPool.sol#L1-L2)), so inheriting from this “base” adds no setup, utilities, or shared assertions; any test suite that expects weighted-pool helpers silently gets nothing.
- Because the class is empty, it masks missing overrides: a child test that forgets to call the real Balancer Vault base will still compile but operate on uninitialized globals.
- Recommend deleting the file or forwarding to `TestBase_BalancerV3Vault` so the inheritance tree actually provides functionality.

## contracts/protocols/dexes/balancer/v3/utils/BalancerV38020WeightedPoolMath.sol — Grade: C
- `_calcEquivalentProportionalGivenSingleAndBPTOut()` unconditionally subtracts `_POOL_MINIMUM_TOTAL_SUPPLY` after computing the invariant ([contracts/protocols/dexes/balancer/v3/utils/BalancerV38020WeightedPoolMath.sol#L96-L118](contracts/protocols/dexes/balancer/v3/utils/BalancerV38020WeightedPoolMath.sol#L96-L118)); if the caller supplies less than 1e6 units on the first deposit the subtraction underflows and the helper reverts instead of minting the minimum-liquidity BPT.
- `_calcBptOutGivenSingleIn()` enforces `amountIn <= balances[tokenIndex] * _MAX_IN_RATIO` before checking `totalSupply` ([contracts/protocols/dexes/balancer/v3/utils/BalancerV38020WeightedPoolMath.sol#L389-L418](contracts/protocols/dexes/balancer/v3/utils/BalancerV38020WeightedPoolMath.sol#L389-L418)); when the pool is empty `balances[tokenIndex]` is zero, so the require statement fails and the very first single-sided deposit can never be priced by this library.
- Several proportional helpers still expect exactly-two-token arrays and strict weight sums, but they lack user-friendly errors; consider early returning with descriptive reverts so integrators know why the math failed.

## contracts/utils/cryptography/ERC5267/ERC5267Target.sol — Grade: C
- `EIP712Repo._layout()` is bound to a single `keccak256("eip.eip.712")` slot, so every facet or target that calls `eip712Domain()` shares the same cached name/version; wiring two independent tokens into the same diamond lets either one overwrite the other’s domain and invalidate live signatures across the system ([contracts/utils/cryptography/ERC5267/ERC5267Target.sol](contracts/utils/cryptography/ERC5267/ERC5267Target.sol)).
- The function always returns `fields = 0x0f` even if `_initialize()` was never called, meaning it advertises name/version/chainId/verifyingContract as set while actually returning empty strings; tooling that trusts the bitmask will accept signatures for an unconfigured domain ([contracts/utils/cryptography/ERC5267/ERC5267Target.sol](contracts/utils/cryptography/ERC5267/ERC5267Target.sol)).

## contracts/utils/cryptography/hash/MessageHashUtils.sol — Grade: B+
- Re-implements the EIP-191/EIP-712 digest helpers using `BetterEfficientHashLib` so callers get the standard `\x19` prefixes and typed-data binding without re-encoding manual keccak trees ([contracts/utils/cryptography/hash/MessageHashUtils.sol](contracts/utils/cryptography/hash/MessageHashUtils.sol)).
- Length-prefixed `personal_sign` hashes rely on `UInt256._toString`, keeping the emitted message identical to the JSON-RPC convention while avoiding re-entrancy into Solidity’s native string utilities ([contracts/utils/cryptography/hash/MessageHashUtils.sol](contracts/utils/cryptography/hash/MessageHashUtils.sol)).

## contracts/utils/math/AerodromeUtils.sol — Grade: C
- `_quoteSwapDepositWithFee()` bails out with `return 0` whenever `lpTotalSupply == 0`, so the helper cannot quote the very first deposit even though Aerodrome pools happily mint initial liquidity; onboarding automation built atop this routine will refuse to initialise fresh pools ([contracts/utils/math/AerodromeUtils.sol](contracts/utils/math/AerodromeUtils.sol)).
- `feePercent` is only checked in `_quoteWithdrawSwapWithFee` but not in `_quoteSwapDepositWithFee`, so a misconfigured fee ≥ 10_000 underflows `amountBWD - amountBWD * fee / 10_000` and reverts instead of cleanly signalling invalid input ([contracts/utils/math/AerodromeUtils.sol](contracts/utils/math/AerodromeUtils.sol)).

## contracts/utils/math/BetterMath.sol — Grade: C
- `_convertToShares()` adds a constant `10 ** decimalOffset` to `totalShares` and divides by `reserve + 1`, so when both supply and reserves are zero the very first depositor mints `assets * 10 ** decimalOffset` shares rather than matching the deposit size; this phantom boost permanently skews share price for every subsequent participant ([contracts/utils/math/BetterMath.sol](contracts/utils/math/BetterMath.sol)).
- `_totalFromPercentage()` and `_percentageOfTotal()` blindly divide by `percentage`/`total` with no guardrails, so passing 0% or a zero total bubbles up a `Panic(DIVISION_BY_ZERO)` instead of returning 0 or reverting with a descriptive custom error ([contracts/utils/math/BetterMath.sol](contracts/utils/math/BetterMath.sol)).

## contracts/utils/math/CamelotV2Utils.sol — Grade: B-
- Neither helper verifies `feePercent < feeDenominator`, so loading parameters straight from an on-chain pair with an unexpected fee will underflow `(feeDenominator - feePercent)` and revert mid-quote; the real Camelot pair sanitises fees at configuration time but this library offers no such defense ([contracts/utils/math/CamelotV2Utils.sol](contracts/utils/math/CamelotV2Utils.sol)).
- On the upside, the `_quoteWithdrawSwapWithFee()` path mirrors Camelot’s `_mintFee` arithmetic (including the owner share term) so LP redemption math stays in sync with the protocol’s integer rounding ([contracts/utils/math/CamelotV2Utils.sol](contracts/utils/math/CamelotV2Utils.sol)).

## contracts/utils/math/ConstProdUtils.sol — Grade: C
- `_quoteZapOutToTargetWithFee()` divides by `ownerFeeShare` when computing `feeFactor` but only bounds the value from above; passing `ownerFeeShare == 0` (which is a valid configuration for many pools) immediately triggers a division-by-zero panic and prevents quoting entirely ([contracts/utils/math/ConstProdUtils.sol](contracts/utils/math/ConstProdUtils.sol)).
- The quadratic solver’s `b` coefficient multiplies `desiredOut`, both reserves, and the fee denominator in plain `uint256`, so realistic values (1e24-level reserves) overflow and seed the binary search with nonsense, producing lpNeeded estimates that undershoot the real requirement ([contracts/utils/math/ConstProdUtils.sol](contracts/utils/math/ConstProdUtils.sol)).

## contracts/utils/math/UniswapV2Utils.sol — Grade: C
- The function signature accepts a `feeDenominator` but the implementation ignores it entirely (the parameter is even commented out), forcing callers to accept a hard-coded 1000/100000 heuristic and mispricing any pool that does not use those exact denominators ([contracts/utils/math/UniswapV2Utils.sol](contracts/utils/math/UniswapV2Utils.sol)).
- `feePercent` is interpreted as “small integer” whenever it is ≤ 10, yet in this codebase fees are expressed in parts-per-hundred-thousand; a normal `feePercent = 500` (0.5%) therefore takes the 100000 branch and quotes a swap as if the denominator were 1e5 instead of the 1000 used by most V2 forks, drifting every result ([contracts/utils/math/UniswapV2Utils.sol](contracts/utils/math/UniswapV2Utils.sol)).

## contracts/utils/vm/arbOS/stubs/precompiles/ArbOwnerPublicStub.sol — Grade: C
- Every setter (`setChainOwner`, `setNetworkFeeAccount`, `setSharePrice`, etc.) is `public` and entirely ungated, so shipping this stub anywhere outside tests lets any user rewrite the chain owner list, fee collectors, or upgrade schedule on a whim; at minimum the contract should scream “test-only” to prevent accidental deployment ([contracts/utils/vm/arbOS/stubs/precompiles/ArbOwnerPublicStub.sol](contracts/utils/vm/arbOS/stubs/precompiles/ArbOwnerPublicStub.sol)).
- `setAllChainOwners()` only appends to `_allChainOwners` and never clears stale entries, so repeated calls cannot model the real precompile’s ability to remove owners and tests that rely on it risk optimistic coverage ([contracts/utils/vm/arbOS/stubs/precompiles/ArbOwnerPublicStub.sol](contracts/utils/vm/arbOS/stubs/precompiles/ArbOwnerPublicStub.sol)).

## contracts/utils/vm/foundry/tools/BetterVM.sol — Grade: C
- `_bound(uint256,min,max)` computes `size = max - min + 1` without guarding overflow; if the caller ever asks for the full uint256 range (`min = 0`, `max = type(uint256).max`) the addition wraps to zero and the later modulo divides by zero, killing the fuzz run ([contracts/utils/vm/foundry/tools/BetterVM.sol](contracts/utils/vm/foundry/tools/BetterVM.sol)).
- The signed variant simply remaps to the unsigned helper, so it inherits the same wraparound/zero-size failure and offers no extra safety when users try to clamp across `[-2^255, 2^255-1]` ([contracts/utils/vm/foundry/tools/BetterVM.sol](contracts/utils/vm/foundry/tools/BetterVM.sol)).

## contracts/utils/vm/foundry/tools/betterconsole.sol — Grade: C
- Hundreds of functions are declared `internal pure` yet call Forge’s cheatcode consoles under the hood; because this library sits under `contracts/` nothing stops production code from inlining a `betterconsole.log()` and shipping bytecode that reverts on mainnet when it tries to call the non-existent `0x7109…` console address ([contracts/utils/vm/foundry/tools/betterconsole.sol](contracts/utils/vm/foundry/tools/betterconsole.sol)).
- Importing `forge-std/console.sol` and `console2.sol` directly from a runtime library drags development-only opcodes (and the AGPL-incompatible Forge ABI) into deployable builds, making contract verification brittle and inflating bytecode for no benefit outside local testing ([contracts/utils/vm/foundry/tools/betterconsole.sol](contracts/utils/vm/foundry/tools/betterconsole.sol)).

## contracts/utils/vm/foundry/tools/terminal.sol — Grade: C-
- The helpers invoke `vm.ffi` to run host binaries (`mkdir`, `touch`, `dirname`) but expose those methods as `public`, so any contract that inadvertently links this library outside a Forge cheatcode context will revert the moment a path helper is invoked ([contracts/utils/vm/foundry/tools/terminal.sol](contracts/utils/vm/foundry/tools/terminal.sol)).
- When used correctly in tests the wrappers make it trivial to scaffold directories before dumping artifacts, but nothing in the ABI or documentation warns integrators that these calls are Forge-only and therefore unsafe for deployment ([contracts/utils/vm/foundry/tools/terminal.sol](contracts/utils/vm/foundry/tools/terminal.sol)).

## contracts/utils/TransientSlot.sol — Grade: B+
- Thin shim simply re-exports OpenZeppelin’s `TransientSlot`, letting local contracts import the audited helper through the `@crane` namespace without cloning code or diverging from upstream semantics ([contracts/utils/TransientSlot.sol#L1-L8](contracts/utils/TransientSlot.sol#L1-L8)).
- Because there is zero bespoke logic here, any behavioural change must come from bumping the OZ dependency; keep that submodule pinned and reviewed so this alias does not silently change under your feet ([contracts/utils/TransientSlot.sol#L1-L8](contracts/utils/TransientSlot.sol#L1-L8)).

## contracts/utils/UInt256.sol — Grade: C+
- `_toAddress()`’s NatSpec promises to clamp values above $2^{160}-1$ to the max address, yet the implementation simply truncates with `address(uint160(value))`, so feeding it `2^{160}` yields `address(0)` instead of `0xffff…ffff`; any caller that trusts the documentation can end up sending value to an unexpected truncated address ([contracts/utils/UInt256.sol#L14-L23](contracts/utils/UInt256.sol#L14-L23)).
- The hex-format helpers mirror OZ’s proven implementation: inputs are formatted with a `0x` prefix, a minimal-length buffer, and a revert when the supplied length is insufficient, which keeps downstream UIs deterministic ([contracts/utils/UInt256.sol#L65-L97](contracts/utils/UInt256.sol#L65-L97)).

## contracts/utils/collections/BetterArrays.sol — Grade: B
- Library re-exports the full OpenZeppelin `Arrays` API (sorting, bounds search, unsafe access) so facets can stick to the local naming scheme while delegating the tricky implementations to upstream code ([contracts/utils/collections/BetterArrays.sol#L23-L214](contracts/utils/collections/BetterArrays.sol#L23-L214)).
- Custom errors like `IndexOutOfBounds`/`EndBeforeStart` wrap OZ’s panic codes and make misuse obvious during testing, which is handy when higher-level repos rely on precondition checks rather than return values ([contracts/utils/collections/BetterArrays.sol#L215-L320](contracts/utils/collections/BetterArrays.sol#L215-L320)).

## contracts/utils/collections/sets/AddressSetRepo.sol — Grade: C+
- `_values()` hands back the underlying storage array even though the comment pleads “DO NOT alter values via this pointer”; any facet that writes through that reference will desynchronize `indexes` from `values` with no way for the library to detect the corruption ([contracts/utils/collections/sets/AddressSetRepo.sol#L218-L228](contracts/utils/collections/sets/AddressSetRepo.sol#L218-L228)).
- Sorted helpers (`_addAsc`, `_removeAsc`, `_sortAsc`, `_quickSort`) keep both the packed array and the 1-index mapping synchronized, saving integrators from rewriting deterministic allow-list maintenance logic ([contracts/utils/collections/sets/AddressSetRepo.sol#L106-L320](contracts/utils/collections/sets/AddressSetRepo.sol#L106-L320)).

## contracts/utils/collections/sets/Bytes32SetRepo.sol — Grade: C
- Like the address set, `_values()` exposes the live storage array by reference, so any caller that mutates it directly (push/pop) will leave `indexes` pointing at stale slots and the library has no guardrails to prevent the drift ([contracts/utils/collections/sets/Bytes32SetRepo.sol#L139-L147](contracts/utils/collections/sets/Bytes32SetRepo.sol#L139-L147)).
- Single- and batch-add helpers share the same core implementation, which keeps insertion idempotent and guarantees that every element receives a deterministic index once present ([contracts/utils/collections/sets/Bytes32SetRepo.sol#L44-L107](contracts/utils/collections/sets/Bytes32SetRepo.sol#L44-L107)).

## contracts/utils/collections/sets/Bytes4SetRepo.sol — Grade: C
- `_values()` likewise returns the backing `bytes4[]` storage pointer, so any in-place edits outside the library’s `_add`/`_remove` helpers can scramble selector ordering and leave `indexes` inconsistent ([contracts/utils/collections/sets/Bytes4SetRepo.sol#L148-L158](contracts/utils/collections/sets/Bytes4SetRepo.sol#L148-L158)).
- `_wipeSet()` deliberately iterates from the end to delete each selector and reclaim gas, which makes it easy for cleanup scripts to zero the mapping without writing manual loops ([contracts/utils/collections/sets/Bytes4SetRepo.sol#L160-L178](contracts/utils/collections/sets/Bytes4SetRepo.sol#L160-L178)).

## contracts/utils/collections/sets/StringSetRepo.sol — Grade: C
- Returning the raw storage array from `_values()` lets any consumer rewrite strings in-place and bypass the library’s mapping book-keeping, so a sloppy caller can easily corrupt the set structure ([contracts/utils/collections/sets/StringSetRepo.sol#L133-L139](contracts/utils/collections/sets/StringSetRepo.sol#L133-L139)).
- Idempotent `_add`/`_remove` operations make it simple to maintain declarative desired state for string allow-lists without worrying about duplicates or order ([contracts/utils/collections/sets/StringSetRepo.sol#L66-L118](contracts/utils/collections/sets/StringSetRepo.sol#L66-L118)).

## contracts/utils/collections/sets/UInt256SetRepo.sol — Grade: C-
- `maxValue` only ever increases—`_remove()` never recomputes it—so `_max()` can report values that were already deleted, breaking consumers that rely on the maximum still being present in the set ([contracts/utils/collections/sets/UInt256SetRepo.sol#L8-L16](contracts/utils/collections/sets/UInt256SetRepo.sol#L8-L16) and [contracts/utils/collections/sets/UInt256SetRepo.sol#L70-L117](contracts/utils/collections/sets/UInt256SetRepo.sol#L70-L117)).
- `_values()` again exposes the storage array, so any direct edits will desynchronize `indexes` and the cached `maxValue`, compounding the stale-maximum problem ([contracts/utils/collections/sets/UInt256SetRepo.sol#L154-L166](contracts/utils/collections/sets/UInt256SetRepo.sol#L154-L166)).

## contracts/utils/cryptography/EIP712/EIP712Repo.sol — Grade: C
- The library hardcodes a single storage slot (`keccak256("eip.eip.712")`), meaning every facet in the diamond shares one EIP-712 domain; deploying two independent tokens that both call `_initialize()` will silently clobber each other’s names/versions because they cannot request distinct slots ([contracts/utils/cryptography/EIP712/EIP712Repo.sol#L33-L55](contracts/utils/cryptography/EIP712/EIP712Repo.sol#L33-L55) and [contracts/utils/cryptography/EIP712/EIP712Repo.sol#L65-L89](contracts/utils/cryptography/EIP712/EIP712Repo.sol#L65-L89)).
- `_initialize()` lacks any guard or “already initialized” check, so any facet with access to the library can rewrite `_hashedName`/`_hashedVersion` after deployment and instantly invalidate every previously issued signature ([contracts/utils/cryptography/EIP712/EIP712Repo.sol#L65-L89](contracts/utils/cryptography/EIP712/EIP712Repo.sol#L65-L89)).
- On the plus side, `_hashTypedDataV4()` composes the domain separator with `MessageHashUtils` so callers get a hardened `EIP-191` digest without reimplementing `abi.encodePacked("\x19\x01", ...)` ([contracts/utils/cryptography/EIP712/EIP712Repo.sol#L121-L135](contracts/utils/cryptography/EIP712/EIP712Repo.sol#L121-L135)).

## contracts/utils/cryptography/ERC5267/ERC5267Facet.sol — Grade: C
- `facetInterfaces()` allocates two slots but only populates index zero, so loupe tooling sees a phantom `0x00000000` interface ID and may reject the facet when validating declarations ([contracts/utils/cryptography/ERC5267/ERC5267Facet.sol#L31-L43](contracts/utils/cryptography/ERC5267/ERC5267Facet.sol#L31-L43)).
- `facetMetadata()` centralizes the facet name, interfaces, and selector list, which keeps package builders from recomputing those arrays in multiple places ([contracts/utils/cryptography/ERC5267/ERC5267Facet.sol#L59-L69](contracts/utils/cryptography/ERC5267/ERC5267Facet.sol#L59-L69)).

## contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol — Grade: D+
- The bubble-sort swaps only the `token` field and leaves `rateProvider`, `tokenType`, and `paysYieldFees` attached to their original slots ([contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol#L15-L28](contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol#L15-L28)), corrupting the metadata whenever two entries trade places.
- Because comparisons rely on `IERC20` (address) ordering, duplicate addresses are never deduped; consider short-circuiting identical tokens to avoid useless iterations.

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationFacet.sol — Grade: C+
- The facet exposes `getActionId()` but never offers an initialization hook to seed `BalancerV3AuthenticationRepo`’s disambiguator, so unless some other facet remembers to call `_initialize` every deployment will produce the default `keccak256(selector)` domain ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationFacet.sol#L5-L59](contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationFacet.sol#L5-L59)).
- `facetInterfaces()` advertises the `IAuthentication` interface, yet the diamond never reports ERC-165 support for that ID anywhere else; consumers that rely on ERC-165 will still see a false negative.
- Consider adding a constructor/initializer guard plus a short README comment referencing the facet that is responsible for wiring the repo.

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationModifiers.sol — Grade: C
- The `authenticate` modifier takes an arbitrary `where` parameter from the caller and forwards it straight into the Authorizer lookup ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationModifiers.sol#L11-L15](contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationModifiers.sol#L11-L15)); if an integrating facet mistakenly forwards a user-supplied address (or `address(0)`), the Authorizer check is trivially bypassed.
- There is no helper enforcing the canonical `where = address(this)` pattern, so different functions can accidentally encode different scopes for the same selector and produce inconsistent action IDs.

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol — Grade: C+
- `_initialize()` blindly overwrites `actionIdDisambiguator` every time it is called ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol#L21-L39](contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol#L21-L39)), so any rogue facet can reinitialize the repo through delegatecall and hijack all existing permissions.
- There is no validation that the disambiguator is non-zero or unique per deployment ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol#L8-L28](contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol#L8-L28)), meaning every pool can collapse onto the same action namespace if wiring scripts forget to pass entropy.
- Consider adding a one-time guard plus an event so operators can audit when the domain separator changes.

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationService.sol — Grade: C
- `authenticateCaller()` derives the action ID from `msg.sig` but lets callers provide any `where` address ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationService.sol#L9-L26](contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationService.sol#L9-L26)); if a facet passes an account that already has broad permissions (e.g., the vault itself), the modifier effectively devolves into “require true”.
- There is no logging or revert reason that tells ops teams which selector or where-address failed authorization, making on-chain debugging painful.

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationTarget.sol — Grade: C
- `getActionId()` simply reads whatever value is sitting in the repo ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationTarget.sol#L15-L19](contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationTarget.sol#L15-L19)) with no guard ensuring `_initialize` ever ran, so a forgotten setup call leaves every selector mapped to the zero disambiguator and collisions abound.
- Without an exposed initializer, there is no way for integrators to update the action namespace if they need to rotate Authorizers.

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol — Grade: C
- `facetInterfaces()` allocates nine slots but the third entry is `type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId`, which is not a real ERC-165 ID and will mislead tooling ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol#L17-L29](contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol#L17-L29)).
- The facet imports `IERC20Permit` and `IERC5267` but never advertises their selectors in `facetFuncs()`, so wallets probing for permit/domain-support will believe the pool lacks those features even if the target implements them ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol#L7-L45](contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol#L7-L45)).
- Metadata helpers are not marked `override`, which makes it easier for accidental signature drift to slip past reviews when the interface changes.

## contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol — Grade: C
- `_initialize()` never validates the invariant and swap-fee bounds (e.g., min < max) before committing them to storage ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol#L28-L50](contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol#L28-L50)), so a bad config permanently bricks fee updates.
- The `tokens` AddressSet only ever grows; there is no way to remove an asset or reset the set during upgrades ([contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol#L16-L46](contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol#L16-L46)), which prevents package migrations that need to rewrite the token list.
- If `_initialize()` is invoked twice the second call simply `_add`s the same tokens again, wasting gas and leaving the set in an undefined order.

## contracts/protocols/dexes/balancer/v3/pool-utils/FactoryWidePauseWindowTarget.sol — Grade: C-
- None of the three interface functions include the `override` keyword, so this contract does not actually compile against `IFactoryWidePauseWindow` ([contracts/protocols/dexes/balancer/v3/pool-utils/FactoryWidePauseWindowTarget.sol#L13-L28](contracts/protocols/dexes/balancer/v3/pool-utils/FactoryWidePauseWindowTarget.sol#L13-L28)).
- Just like the repo, every getter reads from a single global storage slot, so two factory packages wired into the same diamond stomp over each other’s pause-window values ([contracts/protocols/dexes/balancer/v3/pool-utils/FactoryWidePauseWindowTarget.sol#L9-L28](contracts/protocols/dexes/balancer/v3/pool-utils/FactoryWidePauseWindowTarget.sol#L9-L28)).
- The target never checks whether `_initialize()` ran; if the repo is still unset each call quietly returns zero, making it impossible for monitoring to detect misconfigured factories ([contracts/protocols/dexes/balancer/v3/pool-utils/FactoryWidePauseWindowTarget.sol#L13-L28](contracts/protocols/dexes/balancer/v3/pool-utils/FactoryWidePauseWindowTarget.sol#L13-L28)).

## contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol — Grade: B-
- The facet exposes only `getRate()` and `erc4626Vault()` selectors but never ships an initialization hook, so cutting it directly into a diamond without the DF package leaves both functions reverting on the zero vault address ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol#L9-L63](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol#L9-L63)).
- `facetInterfaces()` advertises compliance with both `IRateProvider` and `IERC4626RateProvider`, yet the facet does not register those IDs through ERC-165, so off-chain discovery tooling reading only the metadata gets a false positive ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol#L34-L51](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol#L34-L51)).
- There is no defensive check before calling deep-storage repos, so a simple `getRate()` call on an uninitialized deployment just bubbles a low-level revert with no context for the operator ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol#L52-L63](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol#L52-L63)).

## contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol — Grade: C
- `deployRateProvider()` happily spins up the CREATE3 deployment even if `erc4626Vault` is `address(0)`, only to revert much later inside `initAccount` after wasting gas ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol#L56-L89](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol#L56-L89)).
- `updatePkg()` is declared but left empty, so every upgrade attempt returns the default `false` value and no state ever changes ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol#L112-L116](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol#L112-L116)).
- `calcSalt()` merely hashes `pkgArgs` without canonicalizing the vault, letting equivalent inputs with different ABI padding produce different salts and duplicate deployments ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol#L103-L110](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol#L103-L110)).

## contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol — Grade: C+
- The helper deterministically salts both the facet and the DF package, so calling `initER4626RateProvicerDFPkg()` a second time on the same factory always reverts with a salt collision, yet the function omits any guard or documentation to warn callers ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol#L8-L30](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol#L8-L30)).
- There is no assertion that `create3Factory` is non-zero, allowing test harnesses to accidentally pass the zero address and panic only after paying to deploy creation bytecode ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol#L9-L27](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol#L9-L27)).
- A lingering typo in the public API (`initER4626RateProvicerDFPkg`) makes grep-based tooling miss call sites and raises the odds that a second, subtly different helper will be introduced later ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol#L9-L12](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol#L9-L12)).

## contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol — Grade: C+
- `_initialize()` never checks that the provided `IERC4626` vault is non-zero, so a misconfigured package happily persists address(0) and every later `previewRedeem()` call just reverts with an opaque error ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol#L24-L39](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol#L24-L39)).
- Because there is no reentrancy or caller guard, anyone that can reach the storage slot via delegatecall can re-run `_initialize()` and swap both the vault reference and stored `assetDecimals`, effectively hijacking the provider ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol#L24-L50](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol#L24-L50)).
- `assetDecimals` is trusted as-is; if upstream `safeDecimals` falls back to zero or 255 the repo still stores it, and the downstream math produces meaningless exchange rates without any warning ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol#L34-L50](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol#L34-L50)).

## contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol — Grade: C-
- `getRate()` redeems a fixed `1e18` shares regardless of the vault’s decimals, so 6-decimal vaults receive an impossible request and revert before returning a value ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol#L33-L42](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol#L33-L42)).
- The scaling factor `10 ** (18 - assetDecimals)` underflows whenever `assetDecimals > 18`, causing a `Panic(0x11)` rather than a clean error ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol#L37-L43](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol#L37-L43)).
- Neither `getRate()` nor `erc4626Vault()` validates that the repo has been initialized, so operators only discover a missing `initAccount` after hitting an opaque revert from the zero address ([contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol#L17-L44](contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol#L17-L44)).

## contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol — Grade: B-
- The base class overrides `setUp()` solely to call `BaseTest.setUp()`, forcing every inheritor to thread super-calls through multiple layers without gaining any shared state ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol#L5-L17](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol#L5-L17)).
- With no helper members or utilities defined here, this extra inheritance hop mainly increases linearization complexity and risks someone forgetting to invoke the BaseTest initializer ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol#L5-L17](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol#L5-L17)).
- The file sticks with pragma `^0.8.0` while the surrounding suite has moved to 0.8.24+, so Foundry must compile two separate versions of the Balancer mocks and slows every `forge test` run ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol#L1-L4](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol#L1-L4)).

## contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol — Grade: C-
- `_deployMainContracts()` wires routers, batch routers, and buffers but leaves `poolFactory`/`poolHooksContract` unset, so any subclass that forgets to override `createPool()` starts from an unusable zero address ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol#L145-L233](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol#L145-L233)).
- `mintPoolTokens()` calls ERC4626 `deposit()` on the wrapper tokens without first approving the wrapper to pull the freshly minted underlying, so most deposits revert midway and leave the helper in a half-updated state ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol#L430-L489](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol#L430-L489)).
- `onAfterDeployMainContracts()` assumes `create3Factory` is already populated but only invokes `CraneTest.setUp()`, so passing a zero factory into `initER4626RateProvicerDFPkg()` causes deterministic deployment failures for every derived test ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol#L333-L355](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol#L333-L355)).

## contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol — Grade: C
- `createPoolFactory()` overwrites the shared `poolFactory` from the Vault base without preserving the old reference, so composing this base with another pool type causes whichever runs last to hijack factory ownership ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol#L25-L54](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol#L25-L54)).
- The helper mints `200e18` units of USDC even though the stub token only uses 6 decimals, producing astronomically large balances and breaking the intended 80/20 weight ratio ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol#L60-L84](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol#L60-L84)).
- `initPool()` is overridden as a no-op, so no liquidity ever hits the weighted pool and every inherited test that expects initialized BPT supply immediately reverts with Balancer’s “pool not initialized” error ([contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol#L85-L103](contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol#L85-L103)).

## contracts/protocols/dexes/aerodrome/v1/stubs/rewards/ManagedReward.sol — Grade: C+
- Constructor permanently sets `authorized = _ve` with no rotation hook, so migrating the escrow contract strands any incentives governed by this reward stub ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/ManagedReward.sol#L10-L18](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/ManagedReward.sol#L10-L18)).
- Automatically pushing the escrow’s underlying token into `rewards` happens without zero-address or duplicate checks, letting a misconfigured voter lock an unusable reward asset in storage forever ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/ManagedReward.sol#L11-L15](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/ManagedReward.sol#L11-L15)).
- The inherited `getReward()` and `notifyRewardAmount()` selectors default to empty overrides, so any facet that forgets to supply logic will happily succeed but never transfer funds, making debugging miserable ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/ManagedReward.sol#L20-L24](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/ManagedReward.sol#L20-L24)).

## contracts/protocols/dexes/aerodrome/v1/stubs/rewards/Reward.sol — Grade: C+
- `_deposit()` and `_withdraw()` remain fully external and omit both `nonReentrant` guards and sanity checks beyond the `authorized` address, so a malicious or upgradable controller can reenter mid-checkpoint and desynchronize `totalSupply` from token balances ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/Reward.sol#L194-L215](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/Reward.sol#L194-L215)).
- `_notifyRewardAmount()` never enforces that `token` was flagged in `isReward`, allowing callers to send arbitrary ERC20s whose accounting is recorded but can never be claimed, effectively trapping funds in the contract ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/Reward.sol#L240-L248](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/Reward.sol#L240-L248)).
- `earned()` walks one checkpoint per epoch since the last claim; if a position stays idle for dozens of weeks the gas needed to iterate that loop will exceed the block limit, permanently DoSing reward collection for that NFT ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/Reward.sol#L160-L190](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/Reward.sol#L160-L190)).

## contracts/protocols/dexes/aerodrome/v1/stubs/rewards/VotingReward.sol — Grade: C
- `authorized` is pinned to the voter address in the constructor with no upgrade path, so replacing the voter contract instantly bricks deposits and withdrawals for all managed positions ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/VotingReward.sol#L10-L21](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/VotingReward.sol#L10-L21)).
- `getReward()` always transfers the payout to `ownerOf(tokenId)` even when the caller is the voter or an approved operator, preventing emergency sweepers from redirecting rewards to custody wallets during incident response ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/VotingReward.sol#L23-L31](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/VotingReward.sol#L23-L31)).
- Like `ManagedReward`, the default `notifyRewardAmount()` override is a no-op, so integrating teams that forget to supply logic will receive a false sense of success with zero rewards distributed ([contracts/protocols/dexes/aerodrome/v1/stubs/rewards/VotingReward.sol#L32-L34](contracts/protocols/dexes/aerodrome/v1/stubs/rewards/VotingReward.sol#L32-L34)).

## contracts/protocols/dexes/aerodrome/v1/stubs/test/SigUtils.sol — Grade: B-
- Helper captures the domain separator once in the constructor and never exposes a setter, so any test needing to mutate chain ID or verifying contract data must redeploy a fresh instance instead of reusing shared fixtures ([contracts/protocols/dexes/aerodrome/v1/stubs/test/SigUtils.sol#L6-L14](contracts/protocols/dexes/aerodrome/v1/stubs/test/SigUtils.sol#L6-L14)).
- `Delegation` encodes `delegator`/`delegatee` as `uint256`, which is fine for veNFT IDs but makes this utility incompatible with address-based delegation flows without rewriting the helper ([contracts/protocols/dexes/aerodrome/v1/stubs/test/SigUtils.sol#L17-L24](contracts/protocols/dexes/aerodrome/v1/stubs/test/SigUtils.sol#L17-L24)).
- The custom `_hash()` helper saves gas, but it silently assumes Solady-style hashing; surface-level comments explaining that equivalence to `keccak256(abi.encode(...))` would make the helper less surprising to newcomers ([contracts/protocols/dexes/aerodrome/v1/stubs/test/SigUtils.sol#L25-L52](contracts/protocols/dexes/aerodrome/v1/stubs/test/SigUtils.sol#L25-L52)).

## contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol — Grade: C+
- `setUp()` only deploys the Aerodrome stack when `address(AERO) == address(0)`, so the very first test creates global singletons and every subsequent test inherits mutated state rather than a clean environment ([contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol#L59-L150](contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol#L59-L150)).
- The call to `aeroVoter.initialize(aeroGaugeTokens, address(aeroMinter))` runs even when `aeroGaugeTokens` is the default empty array, which deviates from production behavior and masks bugs that depend on seeded gauges ([contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol#L123-L132](contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol#L123-L132)).
- No teardown or `vm.makePersistent` calls exist for these globals, so any test that mutates balances (e.g., draining the router) leaves the entire fixture in an inconsistent state for the next inheritor.

## contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol — Grade: C+
- Because `setUp()` calls the parent’s memoized deployment before minting/mapping pools, the ERC20 and pool instances also become shared singletons whose balances leak across every test extending this base ([contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol#L39-L89](contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol#L39-L89)).
- Liquidity bootstrap helpers use `block.timestamp` directly and accept `minAmount` arguments of `1`, so they provide zero slippage guarantees and make tests flaky when gas estimation reorders transactions ([contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol#L90-L106](contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol#L90-L106)).
- `_executeAerodromeTradesToGenerateFees()` loops through multiple swaps without checking pool liquidity first, so calling it on an uninitialized pair reverts mid-helper and leaves approvals/balances mutated for the remainder of the test run ([contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol#L107-L156](contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol#L107-L156)).

## contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol — Grade: C
- `facetInterfaces()` inserts `type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId` as the third entry, which is not a valid ERC-165 interface ID and causes downstream factories to advertise a selector that no contract actually implements ([contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol#L149-L160](contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol#L149-L160)).
- `calcSalt()` only checks `tokenConfigs.length == 2` and silently sorts duplicates, so supplying the same token twice produces an identical salt and lets a malicious caller overwrite an existing pool deployment ([contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol#L229-L247](contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol#L229-L247)).
- `postDeploy()` hard-codes a 5% swap fee, disables protocol fee exemptions, and never consults package args, which means every pool deployed through this package shares the exact fee schedule regardless of governance settings ([contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol#L311-L333](contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol#L311-L333)).

## contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol — Grade: C-
- `facetInterfaces()` allocates a three-element array but populates only index zero, leaving two zeroed interface IDs in metadata and confusing any ERC-165 based discovery tooling ([contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol#L45-L53](contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol#L45-L53)).
- `facetFuncs()` similarly allocates nine slots and fills just three selectors, so downstream registries will think the facet exposes `bytes4(0)` six times, which is undefined behavior when diamonds attempt to cut those selectors ([contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol#L57-L69](contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol#L57-L69)).
- The facet advertises the full `IBalancerV3Pool` interface but only forwards `computeInvariant`, `computeBalance`, and `onSwap`, so any caller expecting lifecycle hooks like `onInitialize` will revert once the diamond routes through this facet.

## contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol — Grade: D+
- `computeInvariant()` happily multiplies every entry in `balancesLiveScaled18` and never asserts a fixed token count, so if a package accidentally wires three tokens the returned invariant is meaningless ([contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol#L49-L72](contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol#L49-L72)).
- `onSwap()` ignores Balancer’s swap-fee inputs entirely, letting traders route through this pool (and therefore the Vault) without paying fees or respecting hook callbacks ([contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol#L94-L122](contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol#L94-L122)).
- The EXACT_OUT branch divides by `poolBalanceTokenOut - amountTokenOut` without bounding `amountTokenOut`, so requesting the full balance triggers a division by zero and bricks the pool instead of reverting neatly ([contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol#L107-L120](contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol#L107-L120)).

## contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol — Grade: C
- `getDeploymentAddress()` ignores the `salt` parameter entirely and just forwards `constructorArgs` to the diamond factory, so callers can never pre-compute CREATE3 addresses for different salts ([contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol#L39-L55](contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol#L39-L55)).
- `_registerPoolWithBalV3Vault()` appends the pool to the repo before calling `registerPool` on the actual Balancer vault; if the vault reverts, the failed pool is still marked as deployed and future attempts will think the address is live ([contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol#L115-L134](contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol#L115-L134)).
- There is no guard preventing `disable()` from being called twice; after the first call the function continues to write to storage and emit events even though the factory is already disabled, so off-chain monitors can’t rely on event counts to detect the first disable ([contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol#L23-L38](contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol#L23-L38)).

## contracts/protocols/dexes/aerodrome/v1/stubs/factories/PoolFactory.sol — Grade: B-
- `isPaused` is never consulted by `createPool()` (or any other code path), so flipping the pause switch merely sets a boolean; pausers currently have no way to halt new pool deployments or fee tweaks.
- `setVoter()` does not guard against `_voter == address(0)`, which means one fat-finger permanently bricks every `NotVoter`-guarded action (emergency council rename, metadata tweaks, etc.).
- `setFee()` emits no event, leaving observers blind to changes in the global stable/volatile fee schedule; external tooling cannot detect configuration drifts in time.

## contracts/protocols/dexes/aerodrome/v1/stubs/factories/VotingRewardsFactory.sol — Grade: C+
- `createRewards()` deploys via raw `new`, ignoring the repo-mandated Create3 factory pattern and producing non-deterministic addresses that depend on the caller’s nonce.
- Anyone can call `createRewards()` and it blindly uses `msg.sender` as the “gauge” argument, so griefers can mint endless reward contracts that pretend to be official and clutter registry data.
- Inputs are unchecked; zero `_forwarder` or `_rewards` entries happily deploy, yielding unusable contracts that still look legitimate on-chain.

## contracts/protocols/dexes/aerodrome/v1/stubs/gauges/Gauge.sol — Grade: C
- `_claimFees()` compares accumulated token balances against the time constant `DURATION` (604,800 seconds) before forwarding them, so fees must exceed 604,800 whole tokens before they ever leave the gauge—most pools will have their fees stuck indefinitely.
- `_depositFor()` allows `_recipient == address(0)`, which transfers staking tokens into the gauge while crediting the dead address; there is no way to withdraw those tokens afterward.
- Positive: every mutable entry point (`deposit`, `withdraw`, both reward notifiers, and `getReward`) is wrapped in `nonReentrant`, so hostile ERC20 hooks cannot reenter mid-accounting.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/GovernorCountingMajority.sol — Grade: C+
- The module advertises `quorum=for,abstain` in `COUNTING_MODE()` yet `_selectWinner()` ignores quorum entirely—any single vote decides the outcome.
- Tied votes resolve to `ProposalState.Expired`, but `GovernorSimple.execute()` explicitly allows execution when the state is `Expired`, so equally split votes still execute their payloads.
- No events summarize the final tallies; downstream analytics must off-chain read the storage struct to know how the three buckets resolved.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/GovernorSimple.sol — Grade: C
- `execute()` happily proceeds when the proposal is `Defeated` or `Expired`; supplying the right calldata is enough to run an action that governance explicitly rejected.
- `hashProposal()` ignores the supplied `descriptionHash` and instead hashes the next epoch’s start timestamp, so the user-facing description field no longer provides any integrity guarantees or replay protection.
- `quorum()` is hard-coded to zero even though the contract advertises a quorum-bearing counting mode, allowing a single veNFT to steer emissions.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/GovernorSimpleVotes.sol — Grade: B-
- The constructor never checks for `address(0)` tokens, so a misconfigured deployment quietly bricks every subsequent `_getVotes()` call.
- `clock()` silently falls back to block numbers when the vote token lacks `IERC6372`, yet `GovernorSimple` hashes proposals by timestamps; mixing units invites subtle off-by-one disputes between proposal IDs and vote windows.
- `_getVotes()` assumes the vote token implements the non-standard signature `getPastVotes(address,uint256,uint256)`, so only bespoke ERC-721 style vote tokens are compatible—document that requirement so integrators don’t plug in vanilla ERC20Votes contracts.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/IGovernor.sol — Grade: B
- Interface drops the `cancel()` function even though `ProposalCanceled` is still emitted, so tooling written against OZ’s canonical ABI fails unless it special-cases this fork.
- Docs still describe `descriptionHash`-based proposal IDs, yet the in-repo implementation reuses that slot for epoch start timestamps; add a note so off-chain clients compute hashes the same way.
- Arrays remain in the `ProposalCreated` event even though the concrete governor restricts proposals to a single target/selector, which forces indexers to decode dead data.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/IVetoGovernor.sol — Grade: B
- Introduces the `Vetoed` state but never documents who holds the veto key; implementations must add explicit access-control notes or governance can be captured by an undisclosed guardian.
- `hashProposal()` appends the proposer address, which prevents third parties from replaying payloads but also requires frontends to persist the proposer when scheduling execution—otherwise the hash check fails.
- Unlike `IGovernor`, this interface still exposes `cancel()`, so downstream tooling has to juggle two incompatible ABIs in the same repo; documenting the split would avoid confusion.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/VetoGovernor.sol — Grade: C+
- `propose()` evaluates the threshold at `clock() - 1` with no underflow guard; if the chosen clock ever returns 0 (e.g., timestamp clock at genesis), the subtraction wraps to `type(uint256).max` and any proposer trivially meets the requirement.
- `ProposalState.Expired` is referenced in guards but `state()` never returns it—after the deadline proposals go straight to Succeeded/Defeated—so downstream logic that tries to detect “expired” proposals can never trigger.
- `_veto()` is left as an unguarded internal helper; unless inheritors remember to wrap it with an access-controlled function, the veto switch is effectively unusable code.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/VetoGovernorCountingSimple.sol — Grade: B-
- Shares the same no-quorum behavior as `GovernorCountingMajority`: `_quorumReached()` delegates to whatever the parent contract returns, so if quorum is left at zero a single vote can pass and be veto-proof.
- Lacks any event summarizing the final tally, forcing off-chain services to chase storage just to show users how many votes landed in each bucket.
- Positive: reuses Governor Bravo’s three-bucket semantics (Against/For/Abstain) so analytical tooling can decode the vote layout without bespoke adapters.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/VetoGovernorVotes.sol — Grade: B-
- The constructor never checks `_tokenAddress != address(0)`, so a configuration typo deploys an unusable governor that reverts forever inside `_getVotes()`.
- There is no interface or code-size check before storing `tokenAddress`; if an arbitrary address without the `IVotes` ABI is passed in, every call to `token.getPastVotes()` reverts and bricks voting.
- The `clock()`/`CLOCK_MODE()` fallback silently switches to block-number based scheduling whenever the vote token stops implementing `IERC6372`, which completely changes epoch timing without emitting an event.

## contracts/protocols/dexes/aerodrome/v1/stubs/governance/VetoGovernorVotesQuorumFraction.sol — Grade: C+
- `quorum()` multiplies `token.getPastTotalSupply()` by the numerator before dividing (rather than using `Math.mulDiv` like OZ), so a sufficiently large ve supply will overflow and make quorum checks revert.
- The constructor accepts `quorumNumeratorValue == 0`, effectively disabling quorum until governance somehow passes a proposal to raise it.
- `_updateQuorumNumerator()` casts `clock()` to `uint32`, which will start reverting around the year 2106 when `block.timestamp` exceeds 2^32, permanently freezing further quorum adjustments.

## contracts/protocols/dexes/aerodrome/v1/stubs/libraries/BalanceLogicLibrary.sol — Grade: C
- Both `_checkpoint()` and `supplyAt()` stop iterating after 255 weeks (~4.9 years); any request further in the future silently returns a stale partial decay and never consumes the outstanding slope changes.
- Nothing in the library enforces periodic checkpoints, so if nobody calls `checkpoint()` for years the comment’s worst case materialises: supply accounting diverges permanently even though the functions keep returning seemingly valid numbers.
- `balanceOfNFTAt()` blindly returns the last stored `permanent` weight without checking whether the lock has since been flipped back to a timed position, so historical lookups can report hundreds of permanent votes that no longer exist until another checkpoint overwrites the slot.

## contracts/protocols/dexes/aerodrome/v1/stubs/libraries/DelegationLogicLibrary.sol — Grade: C+
- Delegated balances never decay automatically; `_checkpointDelegatee()` only runs when the delegator touches their lock, so delegates keep the original voting weight long after the underlying position has expired.
- The library depends on callers invoking `checkpointDelegator()` before mutating `_locked`, but there is no guard—forgetting that call silently desynchronises `_delegates` and the checkpoints and the helper just floors negative values to zero.
- `_isCheckpointInNewBlock()` collapses multiple writes that occur inside the same block, so batching operations like `_mint` → `_delegate` causes the earlier snapshot to disappear from history.

## contracts/protocols/dexes/aerodrome/v1/stubs/libraries/ProtocolTimeLibrary.sol — Grade: B-
- Epoch length (7 days) and the ±1 hour restricted voting window are hard-coded; changing cadence or buffer requires redeploying every consumer contract.
- The helpers happily accept historical timestamps and return windows that already elapsed, so every caller has to remember to compare the result against `block.timestamp` manually.
- All arithmetic is wrapped in `unchecked` blocks, so edge-case inputs near `type(uint256).max` wrap back to small numbers instead of reverting, which would be painful to debug if a caller accidentally overflows.

## contracts/protocols/dexes/aerodrome/v1/stubs/libraries/SafeCastLibrary.sol — Grade: B
- Only supports `uint256 ↔ int128` conversions; every other width used across the codebase still needs custom helpers, defeating the point of centralising casts.
- The generic `SafeCastOverflow/SafeCastUnderflow` errors carry no context (which value overflowed), so tracing failures through Foundry logs is needlessly time-consuming.
- `toInt128()` double-casts via `uint128` and then `int128`, which is gas-inefficient compared to a single bounds check plus cast.

## contracts/protocols/dexes/aerodrome/v1/stubs/rewards/BribeVotingReward.sol — Grade: B-
- `notifyRewardAmount()` lets any account register a new reward token (as long as the voter whitelist says yes) but emits no event when the array is extended, so indexers and alerting bots cannot detect configuration changes.
- Once `isReward[token]` flips to true there is no owner-only path to remove or pause that token; a malicious ERC20 can permanently bloat the `rewards` list and force claimers to handle it forever.
- Because there is no practical cap on how many tokens can be whitelisted, a single adversary can add dozens of junk tokens and make claims prohibitively expensive for users who try to iterate across the full list.

## contracts/protocols/dexes/aerodrome/v1/stubs/rewards/FeesVotingReward.sol — Grade: C+
- Fee tokens have to be seeded via the constructor; there is no runtime hook to approve a new ERC20 if the DAO decides to share fees in a different asset later on.
- Authorization hinges entirely on `gaugeToFees(sender)` equality, so if the gauge implementation is upgraded the old gauge contract can keep streaming tokens into this reward contract with no way to cut it off.
- `notifyRewardAmount()` emits no event when fees arrive, making it hard to reconcile distributions with off-chain accounting systems.

## contracts/protocols/dexes/aerodrome/v1/stubs/rewards/FreeManagedReward.sol — Grade: B
- `getReward()` always forwards proceeds to the current owner even when an operator or controller triggered the claim, so vault managers have no way to sweep rewards into custody contracts.
- Callers can pass any `tokens` array and the contract will happily spend gas computing `earned()` for ERC20s that were never registered; there is no helper to validate the request against the canonical rewards list.
- Like the bribe contract, new reward tokens can be appended permissionlessly but can never be removed again, so a compromised whitelist entry permanently bloats storage and claim costs.

## contracts/protocols/dexes/aerodrome/v1/stubs/rewards/LockedManagedReward.sol — Grade: B
- Both `getReward()` and `notifyRewardAmount()` are hard-coded to `ve` as the sole caller, so there is no guardian or emergency path to recover stuck balances if the voting escrow contract is paused or upgraded.
- `getReward()` enforces `tokens.length == 1` and `tokens[0] == IVotingEscrow(ve).token()`, so a single bad entry in the array reverts the entire call instead of skipping invalid tokens.
- `_getReward(sender, tokenId, tokens)` treats the escrow contract as the recipient, which means the `ClaimRewards` event never surfaces which end-user ultimately benefited, complicating any off-chain accounting.

## contracts/protocols/dexes/aerodrome/v1/stubs/Aero.sol — Grade: B-
- `owner` is written once in the constructor and never read again, so the deployer cannot exercise any differentiated authority despite the extra storage slot—either remove it or wire in actual ownership semantics to avoid confusing readers.
- `setMinter` lacks a zero-address guard and emits no event, so accidentally passing address(0) irrevocably bricks future emissions without an on-chain breadcrumb for forensic tooling.
- `mint` does not rate-limit or timelock supply expansion; once `setMinter` hands off authority, the new minter can instantly inflate supply arbitrarily with no circuit breaker, so ensure downstream governance wraps this contract with distribution logic.

## contracts/protocols/dexes/aerodrome/v1/stubs/AirdropDistributor.sol — Grade: B
- The helper hard-codes every lock to `1 weeks` even if `IVotingEscrow` enforces a longer minimum or prefers per-wallet expiries, so mismatched deployments will revert mid-loop and brick the entire batch.
- It approves the escrow for the entire `_sum` before iterating; if any recipient reverts (e.g., they are a multisig contract lacking `onERC721Received`), the approval remains live and lets the escrow pull all remaining tokens later—add rollback logic or zero the allowance inside the loop.
- No reentrancy guard protects the nested `ve.createLock → ve.lockPermanent → ve.safeTransferFrom` flow, so a malicious escrow implementation could call back into `distributeTokens` and reuse allowances/loops; wrap the external section with `nonReentrant` if the escrow is ever upgradable.

## contracts/protocols/dexes/aerodrome/v1/stubs/EpochGovernor.sol — Grade: B
- Governance timings are hard-coded (15 minute delay, 1 week voting window) via pure overrides, leaving no room to retune cadence for faster L2 blocks or slower L1s without a full redeploy.
- There is no hook to update quorum/majority parameters even though the docstring references a specification, so any misconfiguration discovered post-launch is permanent.
- Constructor parameters are simply forwarded to the parent classes with no validation (e.g., zero-address checks on `_forwarder`, `_ve`, `_minter`), making it easy to deploy an unusable governor by mistake.

## contracts/protocols/dexes/aerodrome/v1/stubs/Minter.sol — Grade: B-
- `calculateGrowth` divides by `aero.totalSupply()` without guarding for zero; if `updatePeriod()` is called before `initialize()` mints any supply, the contract reverts permanently until a privileged actor mints tokens manually.
- `UpdatePeriod` is fully permissionless yet performs external calls to `rewardsDistributor.checkpointToken()` and `voter.notifyRewardAmount()` without any reentrancy guard, so a compromised downstream contract could reenter and mutate `weekly`, `tailEmissionRate`, or `proposals` mid-execution.
- `initialize()` batches both liquid and locked airdrops but never checks for duplicate wallets or zero amounts, and if one lock creation fails the contract is left with unspent minted supply plus an allowance to the escrow—consider adding per-recipient try/catch or a way to claw back leftovers.

## contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol — Grade: B
- `observations` grows unbounded (new element every ~30 minutes), so `sample()` and `prices()` calls become progressively more expensive and can exceed block gas limits after long-lived deployments; consider pruning old observations.
- Stable-pool bootstrapping enforces an exact normalized ratio (`DepositsNotEqual` if `(amount0/dec0) != (amount1/dec1)`), which is unrealistic once tokens have different decimals or rounding—initial LPs can be permanently blocked without manual tweaks.
- `_update0/_update1` divide fee accrual by `totalSupply()` without checking for the edge case where all LPs burn down to the permanently locked `MINIMUM_LIQUIDITY`; fee collection would then revert and strand earnings.

## contracts/protocols/dexes/aerodrome/v1/stubs/PoolFees.sol — Grade: B
- The fee vault has no escape hatch—if the paired pool is paused or self-destructed, any residual token0/token1 balances are stuck forever because only the pool can call `claimFeesFor`.
- Missing events around fee withdrawals makes it harder to index how much of each token left the vault; mirroring the pool’s `Claim` event here would improve observability.
- Reentrancy is unchecked even though arbitrary ERC20s are transferred; a malicious token with callbacks could recursively reenter the pool (which already holds the same tokens) unless upstream logic guards around it.

## contracts/protocols/dexes/aerodrome/v1/stubs/ProtocolForwarder.sol — Grade: B
- Thin wrapper around OpenGSN’s `Forwarder`, but there is no owner/guardian role limiting who can register domains or execute relayed calls—document that the shared forwarder is effectively public infrastructure.
- Forwarder version/domain salt is whatever OpenGSN defaults to; if multiple protocol components expect different domains you need separate forwarders, otherwise signatures become replayable across systems.
- Consider surfacing a view that exposes the trusted forwarder address to downstream contracts rather than importing this stub everywhere.

## contracts/protocols/dexes/aerodrome/v1/stubs/ProtocolGovernor.sol — Grade: B
- Once `vetoer` calls `renounceVetoer()` the state is set to zero and `setVetoer()` can never succeed again (guard requires `msg.sender == vetoer`), so the project permanently loses its last-resort veto powers—either forbid renounce or allow `team` to reappoint.
- `proposalThreshold()` feeds `block.timestamp - 1` into `token.getPastTotalSupply`, but most `IVotes` implementations (e.g., OZ ERC20Votes) expect a block number; when wired to block-based voting power this call reverts or returns garbage.
- `setProposalNumerator()` trusts `IVotingEscrow(ve).team()` completely; compromise of that role lets an attacker set numerator to zero (spam proposals) or 5% (practically impossible), so consider timelocking or multi-sig gating.

## contracts/protocols/dexes/aerodrome/v1/stubs/RewardsDistributor.sol — Grade: B-
- `_checkpointToken()` limits catch-up to 20 iterations; if the minter forgets to call it for >20 weeks, emissions from the oldest weeks are never accounted and remain stranded in the contract.
- `claimMany()` stops iterating when it encounters `_tokenId == 0`, so any legitimate veNFT with ID 0 can never participate in batch claims (only single `claim`).
- The contract has no reentrancy guard even though `claim` and `claimMany` call back into `ve.depositFor`/`IERC20.transfer`; a malicious escrow implementation could reenter before `tokenLastBalance` is decremented and double-withdraw rewards.

## contracts/protocols/dexes/aerodrome/v1/stubs/Router.sol — Grade: B
- Zap helpers (`zapIn`, `zapOut`, `_internalSwap`) omit the `ensure(deadline)` guard entirely, so users rely solely on min-out checks and are exposed to multi-block MEV unless they wrap the call externally.
- `getAmountsOut()` silently leaves zeroes when a pool is missing (it just skips the assignment), yet `swapExactTokensForTokens` proceeds after transferring tokens into the first pool, leaving funds stuck if the chosen factory never deployed that pair; better to revert early.
- `_safeTransfer` / `_safeTransferFrom` enforce `token.code.length > 0`, so wrapping tricks that temporarily represent ETH with the sentinel `0xEeee...` will always revert—callers must ensure every hop is a real ERC20 contract.

## contracts/protocols/dexes/aerodrome/v1/stubs/VeArtProxy.sol — Grade: B
- `tokenURI()` recomputes voting power via `ve.balanceOfNFTAt(_tokenId, block.timestamp)`, so the "Voting Power" trait drifts every block and eventually shows zero once the lock expires, making cached metadata inconsistent across indexers. Snapshot the lock data or base the attribute on `_lockedEnd` instead of the current timestamp.
- Every shape renderer runs nested Perlin/trig loops for each `cfg.maxLines`. For large locks the view call regularly burns >3M gas, which makes on-chain consumers (e.g., bridges calling `lineArtPathsOnly()`) easy to DOS. Cache the seeds or cap the maximum line count further.
- Seeds depend only on `_tokenId`, meaning identical IDs across forks/chains yield the same art set. Mix in `block.chainid` or the escrow address if chain-specific uniqueness matters.

## contracts/protocols/dexes/aerodrome/v1/stubs/Voter.sol — Grade: B-
- `_distribute()` insists that `_claimable > IGauge(_gauge).left()` before forwarding rewards. Once a gauge has any outstanding emissions (`left() > 0`), this condition fails forever and new emissions accumulate in `claimable[_gauge]` without ever streaming. Compare against zero or drop the `left()` check entirely.
- `notifyRewardAmount()` divides by `Math.max(totalWeight, 1)`, so if `totalWeight == 0` the entire mint gets baked into `index` and whichever gauge is created later can retroactively claim those emissions. Reject deposits when no voting weight exists or refund the tokens to the minter.
- When the governor calls `createGauge()` the whitelist/`isPool` guards are skipped, yet the mapping is still populated. A typoed `_pool` address therefore bricks that slot permanently (future attempts revert with `GaugeExists`). Require `isPool` to be true for every caller and add an explicit override flow if governance really needs to map synthetic pools.

## contracts/protocols/dexes/aerodrome/v1/stubs/VotingEscrow.sol — Grade: B
- `setArtProxy()` is missing the zero-address guard used in `setTeam()`/`setAllowedManager()`. Setting it to `address(0)` instantly bricks `tokenURI()` for every NFT until someone notices; add `if (_proxy == address(0)) revert ZeroAddress();`.
- `depositManaged()`/`withdrawManaged()` invoke `_lockedManagedReward` and `_freeManagedReward` before emitting events and without any reentrancy guard. A malicious or buggy managed reward implementation can reenter the escrow (e.g., via `depositFor`) while state mutations are mid-flight and corrupt `permanentLockBalance`. Wrap the external calls or lock the factory so only audited reward code can be deployed.
- `_delegate()` allows anyone who controls a permanent lock to force delegation onto an arbitrary token ID without the delegatee’s consent. Besides griefing (bloating checkpoint history) this can block `unlockPermanent()` because delegates gain/lose weight unexpectedly. Require approval from the delegatee or restrict delegation targets to self-owned tokens.

## contracts/protocols/dexes/aerodrome/v1/stubs/art/BokkyPooBahsDateTimeLibrary.sol — Grade: B+
- `_daysFromDate()` still reverts for any year before 1970, so helper functions like `timestampFromDate()` cannot be used in tests that backdate unlock schedules. Either document the bound or extend the algorithm like the upstream library does.
- The “tested range 1970–2345” comment is the only mention of overflow behavior; downstream callers currently assume wraparound will not happen. Add explicit guards or expose a `MAX_YEAR` constant so UI code can clamp inputs before calling into the library.
- Consider declaring the constants as `uint256 constant` to avoid implicit widening at every call site and shave a few hundred gas off repeated conversions.

## contracts/protocols/dexes/aerodrome/v1/stubs/art/PerlinNoise.sol — Grade: B
- `noise2d()`/`noise3d()` allocate arrays and perform dozens of keccak/call-site operations per invocation. When combined with `VeArtProxy.generateShape()` this regularly pushes single-token metadata calls close to the 30M gas RPC cap. Cache gradients or move rendering off-chain to keep metadata responsive.
- The permutation and fade tables are expanded into thousands of nested `if` statements, which bloats bytecode to >80KB and risks hitting the 24KB limit on dependent contracts. Store the tables in `bytes` constants and index via `mload` to cut size dramatically.
- Inputs are expected to be 16-bit fixed point, but there is no clamping; feeding larger coordinates simply truncates and produces nonsense art. Add explicit range checks or normalize inputs so upstream code cannot silently corrupt outputs.

## contracts/protocols/dexes/aerodrome/v1/stubs/art/Trig.sol — Grade: B-
- Two entirely different trig implementations (lookup-table radians plus degree-based tables) co-exist, duplicating 720 entries’ worth of constants and inflating bytecode. Split the degree helpers into a separate library so consumers opt in explicitly.
- `dsin()`/`dcos()` handle negative degrees by multiplying by `-1` before applying `% 360`, so `dsin(-361)` returns `-sintable[1]` instead of `sintable[359]`. Normalize with `(degrees % 360 + 360) % 360` to respect periodicity.
- The comments still describe outputs in the int32 range even though the public APIs scale by `1e18`. Update the NatSpec so callers don’t double-scale the results.

## contracts/protocols/dexes/aerodrome/v1/stubs/dependencies/Timers.sol — Grade: B
- This is the deprecated OZ 4.4.1 version; copying it in-tree means you’ll have to touch every consumer once OZ removes it. Prefer importing `@openzeppelin/contracts/utils/Timers.sol` so upgrades flow automatically.
- The library duplicates identical logic for `Timestamp` and `BlockNumber`. Replacing one with a `using` alias (or a generic struct) would shrink bytecode and avoid accidental drift when one branch gains new guards.
- `isExpired()` reads `block.timestamp`/`block.number` directly, making view-heavy fuzz tests nondeterministic. Consider adding helper functions that compare against a cached deadline for deterministic testing.

## contracts/protocols/dexes/aerodrome/v1/stubs/factories/FactoryRegistry.sol — Grade: B
- Once a `poolFactory` has been approved, its `votingRewardsFactory`/`gaugeFactory` pair is burned into `_factoriesToPoolsFactory`. Even if you `unapprove` the pool factory, you cannot register it again with upgraded factories because the mapping enforces the original pair. Provide an explicit upgrade path or clear the mapping on `unapprove()`.
- The fallback pool factory can never be removed (`unapprove()` reverts) and there is no setter to rotate its linked factories. If a vulnerability is found in the fallback factories the only option today is a full registry redeploy.
- `poolFactories()` returns the entire set in one shot; as the ecosystem grows the call will eventually exceed RPC gas limits. Consider adding pagination helpers or exposing the underlying enumerable set so off-chain tooling can iterate safely.

## contracts/protocols/dexes/aerodrome/v1/stubs/factories/GaugeFactory.sol — Grade: B-
- The factory lacks any access control, so anyone can deploy gauges by calling `createGauge()` directly with arbitrary parameters. While Voter only registers its own deployments, this still pollutes logs and makes it hard to audit which gauges are canonical. Gate the call behind `onlyRegistry` or emit richer metadata.
- There is no input validation: passing zero addresses for `_pool` or `_feesVotingReward` happily deploys a gauge that will later revert on every interaction. Add zero-address checks so misconfigurations fail fast.
- The factory does not emit the created address, forcing downstream tooling to reconstruct events from `Gauge` constructors. Emit a `GaugeCreated` event for easier monitoring.

## contracts/protocols/dexes/aerodrome/v1/stubs/factories/ManagedRewardsFactory.sol — Grade: B
- `createRewards()` is also permissionless, so any account can mint pairs of managed reward contracts and spam the `ManagedRewardCreated` event. Restrict callers to the factory registry or expose a rate limit.
- `_forwarder` and `_voter` are not validated; passing `address(0)` deploys unusable reward contracts yet still emits the event, making it easy to poison registries. Add zero-address guards to match the rest of the system.
- There is no way to introspect which implementations were deployed (e.g., version hash, parameters). Surfacing metadata in the event would help future upgrades prove compatibility.

## contracts/interfaces/IWETHAware.sol — Grade: B
- Awareness interface returning the canonical `IWETH` address from Balancer’s interface set, enabling dependency injection for wrapping ETH.
- No comments about network-specific addresses; referencing the constant libraries would clarify expectations.

## contracts/interfaces/networks/IArbInfo.sol — Grade: B
- Mirrors Arbitrum’s Nitro precompile ABI so Crane packages can query balances/bytecode/yield configs without importing the upstream repo.
- Includes license header acknowledging Offchain Labs—good for legal clarity.
- Consider adding notes about which methods are available in which ArbOS versions since the precompile evolves over time.

## contracts/interfaces/networks/IArbOwnerPublic.sol — Grade: B
- Wraps the chain-owner precompile with documentation about address, events, and expected availability (ArbOS 11+), providing helpful context for governance tooling.
- Several functions retain TODO NatSpec comments (share price/count/APY); filling these in would complete the documentation story.
- Might mention that certain methods (rectify, scheduled upgrades) have version gates to prevent misuse on older chains.

## contracts/interfaces/protocols/dexes/aerodrome/IAero.sol — Grade: B-
- Thin re-export of the v1 Aero token interface so higher-level packages can import from a consistent path.
- No local documentation or version pinning—consider noting the upstream commit hash to keep parity clear.

## contracts/interfaces/protocols/dexes/aerodrome/IAirdropDistributor.sol — Grade: B-
- Mirrors the v1 airdrop distributor ABI; helpful for consolidating imports but adds no NatSpec explaining its purpose.
- Documenting whether this is mainnet or testnet specific would guide integrators.

## contracts/interfaces/protocols/dexes/aerodrome/IEpochGovernor.sol — Grade: B-
- Simple pass-through to the governance interface; consistency is good, but add comments on the upstream source to avoid drift.

## contracts/interfaces/protocols/dexes/aerodrome/IFactoryRegistry.sol — Grade: B-
- Re-exports the factory registry ABI (factories namespace) without extra documentation; consider annotating expected factories or version.

## contracts/interfaces/protocols/dexes/aerodrome/IGauge.sol — Grade: B-
- Alias to the v1 gauge interface; again, note the upstream version or share a brief description to justify the wrapper.

## contracts/interfaces/protocols/dexes/aerodrome/IGaugeFactory.sol — Grade: B-
- Mirrors the gauge factory interface; referencing the canonical repo or commit would reduce future ambiguity.

## contracts/interfaces/protocols/dexes/aerodrome/IManagedRewardsFactory.sol — Grade: B-
- Same pattern for the managed rewards factory; lacks NatSpec about expected behavior or compatibility.

## contracts/interfaces/protocols/dexes/aerodrome/IMinter.sol — Grade: B-
- Re-export of Aerodrome’s minter ABI; consider clarifying whether this matches the production contract or a forked version.

## contracts/interfaces/protocols/dexes/aerodrome/IPool.sol — Grade: B-
- Alias to the pool interface so packages don’t import from deep v1 paths, but documentation would help explain differences from Uniswap-style pools.

## contracts/interfaces/protocols/dexes/aerodrome/IPoolCallee.sol — Grade: B-
- Simple delegate interface for pool callbacks; again, no local NatSpec to describe expected selector semantics.

## contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol — Grade: B-
- MIT-licensed alias that simply re-exports the Aerodrome v1 pool factory interface so higher-level code can import from the unified `contracts/interfaces` path.
- Keeps pragma parity with the rest of the repo but adds zero NatSpec or upstream commit pinning, so consumers must read the source package to understand expected factories/fee logic.
- Consider adding a short comment referencing the canonical `factories/IPoolFactory` ABI or mirroring it locally to avoid breakage if the upstream path moves.

## contracts/interfaces/protocols/dexes/aerodrome/IReward.sol — Grade: B-
- AGPL wrapper that only imports the v1 reward interface, providing consistency but no documentation on roles, emissions, or upgrade expectations.
- Lacks selector annotations or version notes, making it hard for integrators to know whether this targets mainnet contracts or Crane-specific forks.
- A brief NatSpec summary and upstream commit hash would raise confidence without duplicating the entire ABI.

## contracts/interfaces/protocols/dexes/aerodrome/IRewardsDistributor.sol — Grade: B-
- Mirrors the Aerodrome rewards distributor ABI via a single import statement, keeping SPDX/pragma aligned with the rest of the awareness layer.
- No information about distribution cadence, epoch semantics, or whether Crane expects custom errors here, so auditors still have to consult the original source.
- Recommend annotating the interface with selector IDs or emitting docs that explain why this alias exists (e.g., to isolate licensing obligations).

## contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol — Grade: B-
- Thin AGPL pass-through to the real router interface, which helps packages depend on a stable import root but otherwise adds no safety guarantees.
- With zero commentary about slippage params or pool types, consumers still need to study the upstream router before wiring trades.
- Adding NatSpec that links to Aerodrome’s router spec or explicitly noting the supported pool flavors would improve discoverability.

## contracts/interfaces/protocols/dexes/aerodrome/IVeArtProxy.sol — Grade: B-
- Alias for the veNFT art proxy ABI; handy for consolidating imports but devoid of documentation about rendering hooks or expected callbacks.
- The wrapper doesn’t describe whether the proxy must be trusted or how metadata is generated, leaving important integration details implicit.
- Suggest referencing the canonical art contract (commit hash or deployment address) so future upgrades can be tracked.

## contracts/interfaces/protocols/dexes/aerodrome/IVoter.sol — Grade: B-
- Imports the Aerodrome voter interface verbatim, giving Crane packages a consistent path when wiring governance modules.
- Missing NatSpec around gauge voting semantics, whitelist flows, or reward emission assumptions, so the wrapper doesn’t stand on its own for auditors.
- Consider at least adding selector annotations or doc comments that summarize the key responsibilities of the voter contract.

## contracts/interfaces/protocols/dexes/aerodrome/IVotes.sol — Grade: B-
- Straight pass-through to the upstream voting power interface; keeps licensing intact but doesn’t explain how it differs from OZ’s `IVotes` or ERC-5805.
- Without context, downstream engineers won’t know whether Aerodrome extends checkpointing, delegation, or hook semantics.
- A one-line comment comparing it to standard `IVotes` plus a version pin would reduce guesswork.

## contracts/interfaces/protocols/dexes/aerodrome/IVotingEscrow.sol — Grade: B-
- Wrapper around the veNFT locking contract so consumers can import from `contracts/interfaces` rather than the deep `v1` path.
- Provides no NatSpec about lock durations, penalty model, or boosted voting behavior, meaning the wrapper carries minimal standalone value.
- Adding documentation or mirroring the interface locally (instead of import-only) would protect against upstream renames breaking builds.

## contracts/interfaces/protocols/dexes/aerodrome/IVotingRewardsFactory.sol — Grade: B-
- Alias for the factory that mints voting reward contracts; keeps licensing consistent but omits any mention of gauge relationships or deployment flow.
- Because it imports from `interfaces/factories`, integrators must still read the upstream file to know which selectors exist.
- Recommend documenting expected lifecycle (e.g., who can deploy rewards, how emissions are configured) to justify carrying the wrapper.

## contracts/interfaces/protocols/dexes/balancer/common/IRateProvider.sol — Grade: B
- Self-contained interface declaring a single `getRate()` view that returns 18-decimal fixed-point exchange rates, matching Balancer’s oracle expectations.
- GPL header and comments explain licensing and intended usage, which is more helpful than the Aerodrome aliases.
- Could benefit from clarifying whether the rate must be normalized to 1e18 or may revert when stale, but otherwise a faithful copy of Balancer’s spec.

## contracts/interfaces/protocols/dexes/balancer/v2/IAsset.sol — Grade: B-
- Empty type alias that the Vault uses to distinguish ERC20 tokens from the ETH sentinel; useful for compile-time type safety even though the interface body is blank.
- Comments explain the intent, but the file still compiles to bytecode because of the stray closing brace indentation—consider marking the interface explicitly as empty (`interface IAsset {}`) to avoid lint warnings.
- Would help to mention that Balancer treats `IAsset(address(0))` as native ETH so integrators know why this alias exists.

## contracts/interfaces/protocols/dexes/balancer/v2/IAuthentication.sol — Grade: B
- Minimal interface exposing `getActionId(bytes4)` so factories can query Balancer-style auth roles without pulling the full Vault ABI.
- NatSpec is concise and clarifies the selector→action mapping, but there’s no guidance on how action IDs are derived; linking to the Balancer docs would aid readers.
- Consider adding selector annotations for tooling parity with other interfaces.

## contracts/interfaces/protocols/dexes/balancer/v2/IAuthorizer.sol — Grade: B
- Declares the canonical `canPerform` check used by the Vault’s authorizer, keeping access-control hooks consistent.
- Lacks error semantics or event notes, so consumers must still inspect the implementation to understand revert behavior.
- A reminder that `where` should be the target contract (not the caller) would reduce common integration mistakes.

## contracts/interfaces/protocols/dexes/balancer/v2/IBalancerQueries.sol — Grade: B
- Provides the full query surface (`querySwap`, `queryBatchSwap`, `queryJoin`, `queryExit`) and imports the correct structs from `IVault`, matching Balancer v2 behavior.
- Extensive inline comments explain why the functions are non-view yet side-effect free, which is valuable context for script authors.
- Could add return-value ordering notes (e.g., `assetDeltas` sign conventions) to prevent integrators from misinterpreting results.

## contracts/interfaces/protocols/dexes/balancer/v2/IBasePool.sol — Grade: B
- Comprehensive pool lifecycle interface covering join/exit hooks, metadata getters, and query helpers; mirrors Balancer’s reference implementation closely.
- Uses experimental ABI encoder pragma plus explicit documentation for each parameter, so implementers know exactly what the Vault expects.
- The pragma mix (`^0.8.24` + `pragma experimental`) might be overkill now that ABIEncoderV2 is default—consider removing to silence compiler warnings.

## contracts/interfaces/protocols/dexes/balancer/v2/IComposableStablePoolFactory.sol — Grade: B
- Factory ABI for creating composable stable pools, wiring rate providers, caches, and ownership parameters so Crane scripts can deploy Balancer pools deterministically.
- Imports `BetterIERC20` and `IRateProvider`, keeping type expectations clear, but lacks NatSpec describing constraints on amplification or swap fees.
- Including events or documentation about salt usage (CREATE2 vs. CREATE3) would make it easier to integrate with Crane’s deterministic deployment tooling.

## contracts/interfaces/protocols/dexes/balancer/v2/IFlashLoanRecipient.sol — Grade: B
- Reuses Balancer’s flash-loan hook semantics, clearly documenting the expectation that principal+fee are repaid before return.
- Ties into `BetterIERC20`, which keeps the token type consistent across the repo.
- Could mention that reentrancy isn’t mitigated by the Vault, so implementers must guard their own logic.

## contracts/interfaces/protocols/dexes/balancer/v2/IGeneralPool.sol — Grade: B
- Extends `IBasePool` with the `onSwap` hook used by general-specialization pools, aligning Crane’s adapters with Balancer mainnet behavior.
- Comments explain when the Vault invokes this function and note that it can be `view`, which helps authors reason about gas costs.
- Adding selector annotations or references to MinimalSwapInfo differences would help developers choose the right specialization.

## contracts/interfaces/protocols/dexes/balancer/v2/IPoolSwapStructs.sol — Grade: B
- Defines the shared `SwapRequest` struct used across pool interfaces, preventing duplication and drift when additional fields are introduced.
- Verbose comments document each field, including specialization-specific semantics for `lastChangeBlock`.
- Since this isn’t a real interface, consider moving the struct to a `library` for clarity and to stop lint tools from flagging the unused pragma experimental directive.

## contracts/interfaces/protocols/dexes/balancer/v2/IProtocolFeesCollector.sol — Grade: B
- Captures admin hooks (set swap/flash fees, withdraw collected tokens) plus associated events, letting Crane governance modules program Balancer fee policies.
- Imports `IAuthorizer` and `IVault`, keeping dependencies explicit, but lacks NatSpec on permission requirements (e.g., who may call setters).
- Adding information about units (1e18 fixed point) and maximum fee caps would save integrators from trawling the Balancer docs.

## contracts/interfaces/protocols/dexes/balancer/v2/ISignaturesValidator.sol — Grade: B
- Meta-transaction helper interface exposing domain separator and per-user nonce queries so relayers can compose typed-data payloads without importing the full Vault.
- GPL header and brief NatSpec summarize intent, but the file never explains how nonces are consumed or whether they’re shared across functions; linking to Balancer’s signature flow would reduce guesswork.
- Consider adding selector annotations for tooling consistency.

## contracts/interfaces/protocols/dexes/balancer/v2/ITemporarilyPausable.sol — Grade: B
- Defines the pause-state struct (paused flag plus window/buffer deadlines) and the `PausedStateChanged` event that Vault consumers rely on.
- Helpful docstring clarifies this wraps the helper module, yet there’s no guidance on time units or who is authorized to flip the flag, so reviewers still need to inspect the implementation.
- Including getter selector annotations or referencing the helper library would improve traceability.

## contracts/interfaces/protocols/dexes/balancer/v2/IVault.sol — Grade: B+
- Massive, well-documented port of the Balancer v2 Vault ABI covering relayers, internal balances, pool registration, joins/exits, swaps, flash loans, and hooks, giving Crane full parity with mainnet expectations.
- Imports the local wrappers for `IAsset`, `IAuthorizer`, `IFlashLoanRecipient`, etc., so every dependent interface remains in sync; comments explain each struct and enum thoroughly—a great reference for auditors.
- Minor nits: still uses `pragma experimental ABIEncoderV2` style patterns in some structs and carries commented-out imports; trimming those would modernize the file. Adding selector annotations for key entry points (`joinPool`, `batchSwap`, etc.) would also help generate bindings.

## contracts/interfaces/protocols/dexes/balancer/v3/IAuthentication.sol — Grade: B-
- Simple AGPL wrapper re-exporting Balancer v3’s helper interface, ensuring Crane code imports it via the local path.
- Adds zero documentation about action IDs or usage; consider mirroring the interface locally with NatSpec so this file carries value even if the upstream path shifts.
- Providing a version pin or commit hash to the external package would keep upgrades auditable.

## contracts/interfaces/protocols/dexes/balancer/v3/IAuthorizer.sol — Grade: B-
- Same wrapper pattern for the v3 authorizer with no additional comments, so it mainly serves as a remapping convenience.
- Without local docs or selector annotations, consumers must inspect the upstream package; adding a short summary of expected permissions would help.
- Mentioning that this interface mirrors the v2 authorizer (with minor changes) would clarify migration expectations.

## contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol — Grade: B
- Local interface adds `emitTransfer`/`emitApproval` helpers on top of `IRateProvider`, matching Balancer’s MultiToken event forwarding model.
- Includes selector annotations and a brief NatSpec header, making it easier for tooling to hook into event emissions.
- Could describe when these emitters are meant to be called (e.g., only from the central MultiToken) to prevent misuse.

## contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol — Grade: B
- Provides invariant computation, balance recalculation, and swap hooks for Balancer v3 pools with detailed documentation on rounding requirements and invariants.
- Imports Vault type structs to keep parameter schemas aligned; helpful comments explain economic properties auditors should verify.
- Would benefit from explicit selector annotations and perhaps a note describing how new pool types extend this interface (e.g., extra hooks for hooks).

## contracts/interfaces/protocols/dexes/balancer/v3/IBasePoolFactory.sol — Grade: B-
- Thin AGPL wrapper doing nothing but importing Balancer’s upstream factory ABI, keeping the dependency tree manageable.
- Lacks local NatSpec or versioning info, so if the upstream interface changes this alias provides no warning.
- Consider duplicating the small ABI locally with comments so audits don’t need to cross repositories.

## contracts/interfaces/protocols/dexes/balancer/v3/IPoolInfo.sol — Grade: B-
- Another bare import wrapper pointing at Balancer’s `IPoolInfo`, useful for shared type definitions but otherwise undocumented.
- Adding a summary of what info the struct exposes (tokens, weights, etc.) would justify carrying the file.
- A version/commit pin would ensure deterministic builds even if the external package revs.

## contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol — Grade: B
- AGPL stub re-exporting the v3 helper so Crane contracts can depend on a consistent rate-provider ABI across both core and repo-specific interfaces.
- No comments or selector annotations, but given it only exposes `getRate()` this is acceptable; still, referencing the Balancer spec would aid reviewers.
- Ensure this doesn’t diverge from the v2 rate provider semantics to avoid subtle type mismatches when composing packages.

## contracts/interfaces/protocols/dexes/balancer/v3/IRouter.sol — Grade: B-
- Bare import wrapper pointing at Balancer’s v3 router interface; keeps remappings organized but adds no NatSpec or version pinning.
- Consider documenting which hook permutations Crane depends on or mirroring the ABI locally so audits don’t require checking the external package.
- A short note about the upstream commit (or a `type(IRouter)` alias) would make upgrades less error-prone.

## contracts/interfaces/protocols/dexes/balancer/v3/ISenderGuard.sol — Grade: B-
- GPL-licensed re-export that ensures Crane’s contracts import the same sender-guard ABI used by Balancer v3 vaults.
- With no documentation or selector annotations, consumers still have to navigate the upstream repo; add a summary explaining the guard’s purpose (preventing unexpected `msg.sender`).
- Version pinning or local struct copies would reduce reliance on external packages during audits.

## contracts/interfaces/protocols/dexes/balancer/v3/ISwapFeePercentageBounds.sol — Grade: B-
- Another minimal wrapper referencing the Balancer v3 bounds helper; useful for type consistency but otherwise empty.
- Adding a brief explanation of what bounds represent (min/max swap fee per pool) would justify keeping this file.
- Mirroring the small struct locally could avoid breakage if the upstream path changes.

## contracts/interfaces/protocols/dexes/balancer/v3/IUnbalancedLiquidityInvariantRatioBounds.sol — Grade: B-
- Thin alias to Balancer’s vault helper that constrains invariant ratios during unbalanced liquidity operations.
- No documentation exists locally, so integrators must chase the upstream spec; a one-liner describing the invariant guard would improve readability.
- Since the interface is tiny, consider copying its contents locally to reduce external dependency risk.

## contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol — Grade: B-
- AGPL wrapper importing the entire Balancer v3 Vault ABI; maintains a consistent path for Crane but contains no local commentary despite the interface’s importance.
- Without inline docs, readers cannot tell whether Crane tracks a specific upstream commit or relies on custom extensions.
- Recommend mirroring the interface or at least referencing the tag/commit so upgrades can be audited.

## contracts/interfaces/protocols/dexes/balancer/v3/IWeightedPool.sol — Grade: B-
- Pass-through import of the v3 weighted pool interface; keeps the dependency tree tidy but provides no local hints on functionality.
- Mentioning how this differs from v2 or linking to the spec would aid maintainers porting weighted pools into Crane.

## contracts/interfaces/protocols/dexes/balancer/v3/IWeightedPool8020Factory.sol — Grade: B
- Unlike the prior wrappers, this file defines the factory ABI locally, detailing creation parameters, token config structs, and lookup helpers.
- Makes good use of typed structs (`TokenConfig`, `PoolRoleAccounts`) and reuses `BetterIERC20`, which clarifies expectations for Crane deployments.
- Could add NatSpec describing the expected token ordering (high vs low weight) and swap fee units to round out documentation.

## contracts/interfaces/protocols/dexes/balancer/v3/RouterTypes.sol — Grade: B-
- Pure re-export of the router hook structs from Balancer’s package; helpful when sharing types between Crane routers/facets.
- No local docstrings; referencing each struct’s purpose (init, swap, add/remove liquidity) would improve discoverability.

## contracts/interfaces/protocols/dexes/balancer/v3/VaultTypes.sol — Grade: B-
- Similar wrapper re-importing the Vault’s rich type set (config bits, hook flags, swap params, etc.), ensuring Crane code uses the same definitions as upstream.
- The comment banner helps, but there’s still no documentation summarizing key structs or constants; consider adding a brief table of contents for maintainers.

## contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol — Grade: B
- Defines the core Camelot factory surface (pair enumeration, creation, referrer fee splits) with events, keeping Crane deployments aligned with Arbitrum’s canonical router.
- Missing NatSpec for owner/fee setters and doesn’t document stable-pair handling (e.g., `setStableOwner` is declared `view`), so integrators must infer semantics from upstream contracts.
- Consider clarifying whether `createPair` enforces token ordering and if `feeInfo()` returns additional referrer state to avoid misconfiguration.

## contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol — Grade: B-
- Extends `BetterIERC20` plus Permit, exposing all pool lifecycle events and both router swap signatures (with/without referrer) alongside fee customization hooks.
- Large blocks of commented-out ERC20/permit definitions clutter the file; either delete or add rationale for keeping them.
- No NatSpec on `stableSwap`, `setFeePercent`, or reserve layout, so auditors must read the implementation to understand fee percent ranges or referrer handling.

## contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol — Grade: B-
- Captures the Camelot router’s liquidity and swap helpers, including referrer-aware methods and fee-on-transfer variants, which Crane relies on for integrations.
- Function list mirrors UniswapV2 but lacks documentation about parameter units, deadline handling, or reentrancy expectations, and selector annotations are absent.
- Adding NatSpec per function plus a note on the referrer argument (address zero vs. affiliate) would improve clarity.

## contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Callee.sol — Grade: B
- Single-function interface defining the flash-loan callback hook; simple yet essential for pairs performing arbitrage callbacks.
- No NatSpec or documentation about expected `data` encoding, so newcomers must reference Uniswap docs.
- Consider adding selector annotation and reentrancy warning since misuse can brick pools.

## contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2ERC20.sol — Grade: B
- Extends the local ERC20 + ERC2612 interfaces so LP tokens inherit consistent metadata and permit behavior.
- Leaves commented-out helper functions for reference, which adds noise; either document why they’re disabled or delete them.
- Adding NatSpec for `PERMIT_TYPEHASH` and nonce expectations would make the file more self-contained.

## contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol — Grade: B
- Full factory ABI with selector annotations, covering pair enumeration, creation, and fee administration.
- Lack of NatSpec on setters (who may call, revert reasons) means integrators must consult upstream code.
- Could mention token ordering/duplicate prevention to prevent integration mistakes.

## contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol — Grade: B
- Standard pair interface plus custom events and metadata getters, keeping Crane’s LP tooling aligned with canonical Uniswap V2.
- Annotates the ERC-165 interface ID, but no selectors or comments describing reserve update semantics.
- Removing redundant commented-out imports would tidy the file; otherwise accurate.

## contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol — Grade: B
- Comprehensive router ABI including fee-on-transfer helpers, quotes, and swap math functions so Crane routers can be deterministic.
- No documentation on slippage expectations, path ordering, or payable semantics, leaving new contributors to infer from upstream.
- Consider referencing Router01/02 differences or linking to Uniswap docs for clarity.

## contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router01.sol — Grade: B
- Base router interface mirroring the original Uniswap release; useful for integrations that exclude fee-on-transfer helpers.
- Lack of NatSpec and selector annotations mirrors the upstream file, but a short description of differences vs Router02 would help.
- Could de-dupe repeated function docs by inheriting from Router base plus adding overrides.

## contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol — Grade: B
- Extends Router01 with the fee-on-transfer supporting methods, matching the widely deployed factory ABI.
- Imports Router01 cleanly but again lacks NatSpec; referencing the specific EIP or commit would guide audits.
- Consider adding `@custom:selector` tags to keep aggregator tooling aligned.

## contracts/interfaces/protocols/launchpads/ape-express/IDegenFactory.sol — Grade: C+
- Minimal interface exposing `creatorByToken`, enough for Crane packages that need to trace token provenance.
- No events, documentation, or view/pure annotations (function defaults to non-view), so gas estimates could be misleading; mark as `view` if appropriate.
- Needs NatSpec explaining what a “creator” is and whether null address is allowed.

## contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol — Grade: B-
- Pure import alias pointing at Balancer’s IWETH helper; keeps dependency consistent but adds no local value.
- Since WETH interfaces rarely change, consider mirroring it locally with basic NatSpec to avoid relying on the external package path.

## contracts/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol — Grade: A-
- Complete Permit2 allowance interface with detailed error/event docs and struct definitions, giving Crane code first-class typed access to allowance transfers.
- Extends IEIP712 and documents every struct field, making it easy to build custom permit flows; includes lockdown and nonce invalidation semantics.
- Minor spelling nits (`alownce`) and missing selector annotations are the only polish gaps.

## contracts/interfaces/protocols/utils/permit2/IPermit2.sol — Grade: B-
- Pure re-export of Uniswap’s canonical Permit2 interface to keep remappings aligned; no additional documentation or version pinning, so readers must check the external dependency for detail.
- Consider mirroring the interface locally (similar to `IAllowanceTransfer`) so upgrades are auditable and code search stays in-repo.
- Adding a short note on why this wrapper exists would reduce confusion when both local and external imports are available.

## contracts/interfaces/protocols/utils/permit2/ISignatureTransfer.sol — Grade: A-
- Comprehensive Permit2 signature-transfer ABI with rich NatSpec, detailed structs, and explicit error events, enabling sophisticated off-chain authorization flows.
- Reuses `IEIP712` to ensure domain separation is consistent; documents unordered nonce bitmap design—a valuable reference for auditors.
- Minor typos (`alownce`) and lack of selector annotations are the only polish gaps; otherwise excellent.

## contracts/interfaces/proxies/IERC20MintBurnProxy.sol — Grade: B
- Thin proxy interface combining `BetterIERC20` with mint/burn hooks and annotated selectors so factories can interact with proxied ERC20s uniformly.
- Function comments explain return semantics, but access control expectations are undocumented; consider clarifying who may call `mint`/`burn`.

## contracts/interfaces/proxies/IERC20PermitProxy.sol — Grade: B
- Defines a composite interface that guarantees both ERC20 and Permit (ERC5267+2612) support via the repo’s `Better` wrappers—handy for proxy-aware tooling.
- Contains commented-out OZ imports; removing or explaining them would cut noise.
- Lacks NatSpec describing why this proxy exists (e.g., to expose both metadata and permit view functions).

## contracts/interfaces/proxies/IERC4626PermitProxy.sol — Grade: B
- Simple inheritance diamond combining `IERC20PermitProxy` and `IERC4626`, ensuring vault proxies expose both permit and ERC-4626 methods without duplicating ABI declarations.
- BUSL-1.1 license signals heightened restrictions; highlight this when reusing code to avoid license drift.
- Could include selector annotations for the added ERC-4626 functions to help facet metadata tooling.

## contracts/introspection/ERC165/Behavior_IERC165.sol — Grade: A-
- Rich Foundry behavior library that logs expectations, records comparator baselines, and validates `supportsInterface` implementations with detailed console traces.
- Uses set comparators plus error-prefix helpers, making test failures actionable; consistent naming keeps behavior suites aligned across interfaces.
- Slight typos (`supportsInterFace`) and verbose logging comments could be trimmed, but functionality is solid.

## contracts/introspection/ERC165/ERC165Facet.sol — Grade: B
- Facet exposes ERC165 metadata via `IFacet`, returning name/interface/function arrays so diamonds can advertise their capabilities deterministically.
- Implementation is straightforward but lacks explicit comments about initialization requirements (facets rely on `ERC165Repo` being primed elsewhere).
- Consider asserting the repo has registered the interface in `facetInterfaces()` or referencing tests that cover the linkage.

## contracts/introspection/ERC165/ERC165Repo.sol — Grade: C+
- Storage helper binds ERC165 interface support to a fixed slot and offers batch registration helpers, mirroring other repos.
- Bug: `_registerInterface(bytes4)` writes `false` instead of `true`, so default registrations silently mark interfaces unsupported; either a typo or leftover stub that will break `supportsInterface` unless callers always use the layout-aware overload. Needs immediate fix/tests.
- Consider emitting events or reverting on duplicate registration to aid debugging.

## contracts/introspection/ERC165/ERC165Target.sol — Grade: B
- Minimal target contract that reads `ERC165Repo` to answer `supportsInterface`, keeping delegates thin and reusing storage helpers.
- No NatSpec describing how to register interfaces (callers must interact with the repo directly); adding guidance would prevent “always false” results when devs forget setup.

## contracts/introspection/ERC165/TestBase_IERC165.sol — Grade: B+
- Abstract Foundry test harness that wires a subject and expected interface list into `Behavior_IERC165`, ensuring every inheriting test asserts declared support.
- Encourages consistent overrides (`erc165_subject`, `expected_IERC165_interfaces`) and logs failures clearly; mixing in Behavior libs keeps tests DRY.
- Could add sanity checks ensuring `expected_IERC165_interfaces()` is non-empty to catch misconfigured inheritors earlier.

## contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol — Grade: A-
- Extensive Foundry behavior library that captures expected facet layouts via comparator repos, then validates every loupe view (`facets`, `facetAddresses`, `facetFunctionSelectors`, `facetAddress`) with detailed logging.
- Helper repo stores selector→facet expectations per subject, allowing `hasValid_IDiamondLoupe_facetAddress()` to detect mismatches across the entire diamond; logs include vm labels so failures are actionable.
- Known gaps: expectations for `facetFunctionSelectors` are tracked per facet address only (see TODO), so multiple diamonds sharing a facet but using different selector subsets could yield false positives. Also, heavy console logging may add noise/gas in large test suites.
- Recommend finishing the TODO (scoping selector expectations per subject+facet) and optionally gating logs via env flag to keep behavior output manageable.

## contracts/introspection/ERC2535/DiamondCutFacet.sol — Grade: C+
- `facetInterfaces()` allocates a two-entry array but only populates index 1, so callers reading index 0 get `0x00000000`, which can break ERC165 self-checks and tooling that expect tight arrays.
- Multi-step ownership wiring plus additional facet selectors are commented out, leaving this facet advertising only `diamondCut` while still inheriting `DiamondCutTarget`’s ownership modifiers; metadata and actual capabilities drift apart.
- Either restore the MultiStepOwnable facet support or shrink the advertised interface/function arrays so the facet doesn’t promise selectors it no longer exposes.

## contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol — Grade: B
- Package cleanly bundles the DiamondCut and MultiStepOwnable facets, providing deterministic `facetCuts()` output and initializing ownership + ERC165 registrations via `_initialize`.
- `initAccount` sensibly chains `_diamondCut` and `_registerInterfaces`, making this package usable as a one-shot bootstrap for new diamonds.
- Lifecycle hooks (`updatePkg`, `postDeploy`) are stubbed to always succeed and `calcSalt/processArgs` duplicate work, so CREATE3 deployments still rely on external determinism—worth tightening before shipping tooling around it.

## contracts/introspection/ERC2535/DiamondCutTarget.sol — Grade: B
- Minimal target that inherits `MultiStepOwnableModifiers` and forwards `diamondCut` calls into `ERC2535Repo`, so access control is centralized in the repo’s storage helpers.
- Emits the standard `IDiamond.DiamondCut` event via the repo path, keeping compatibility with off-chain indexers.
- Lacks any reentrancy guard or expectation that `initTarget` be trusted, so integrators must ensure `initCalldata` cannot clobber ownership on the first call.

## contracts/introspection/ERC2535/DiamondCutTargetStub.sol — Grade: B-
- Test-oriented stub combining `DiamondCutTarget` with `DiamondLoupeTarget`, seeding ownership via `MultiStepOwnableRepo._initialize` so behavior suites can exercise both cut + loupe calls on a single contract.
- Hardcodes a 1-day ownership transfer buffer and exposes loupe selectors directly, which is fine for tests but should remain isolated from production deployments.
- Could add helper functions to seed initial facet cuts/selectors so behavior tests don’t have to reach into repositories manually.

## contracts/introspection/ERC2535/DiamondLoupeFacet.sol — Grade: A-
- Provides the IFacet metadata wrapper around `DiamondLoupeTarget`, exposing all four ERC-2535 loupe selectors and the `IDiamondLoupe` interface id.
- `facetMetadata()` stays deterministic and mirrors the pattern other facets use, so package tooling can introspect it without special cases.
- Consider surfacing facet-level immutables (e.g., target address) if this facet ever needs to share deployment-time context the package currently hides.

## contracts/introspection/ERC2535/DiamondLoupeTarget.sol — Grade: A
- Straightforward proxy that reads from `ERC2535Repo` storage for facets, facet selectors, addresses, and selector→facet lookups; no ownership gates so it matches the ERC-2535 read-only expectations.
- By centralizing data in `ERC2535Repo`, every loupe call stays O(facets) without redundant storage layouts.
- Would benefit from NatSpec explaining that `_facetAddress` returning `address(0)` indicates an unknown selector, but functionality is sound.

## contracts/introspection/ERC2535/ERC2535Repo.sol — Grade: C
- Maintains facet address sets and per-facet selector sets via the shared AddressSet/Bytes4Set repos, and emits `IERC8109Update` hooks when delegatecalls or removals happen.
- `_replaceFacet` removes emptied facets from `layout.facetAddresses` using `facetCut.facetAddress` instead of the `currentFacet` being replaced, which can drop the newly-added facet while leaving the old address lingering—loupe views then drift from reality.
- `_removeFacet` assigns `layout.facetAddress[selector] = facetCut.facetAddress` instead of zeroing the selector, so “removed” selectors still resolve to the removing facet address, causing `facetAddress()` and `functionFacetPairs()` to lie; this needs correction before production use.

## contracts/introspection/ERC2535/IDiamond.sol — Grade: B-
- Captures the canonical `FacetCutAction`, `FacetCut`, and `DiamondCut` event definitions from ERC-2535, keeping tooling compatible with Mudgen’s reference implementation.
- Lacks NatSpec on members despite the TODO comment, and the note about “bad data normalization” hints at a desire to restructure arrays without actually providing helpers.
- Consider adding a comment explaining why functions are absent (since callable entry points live in `IDiamondCut`) to avoid confusion for new contributors.

## contracts/introspection/ERC2535/TestBase_IDiamondLoupe.sol — Grade: A-
- Foundry base test that wires a subject-specific `expected_IDiamondLoupe_facets()` result into `Behavior_IDiamondLoupe` expectations, then exercises every loupe view with assertions.
- Loops through each expected facet to validate selectors individually, catching per-facet drift that a single aggregated assertion might miss.
- Recomputes `expected_IDiamondLoupe_facets()` multiple times; caching in `setUp()` would reduce duplicated setup work for large expectation arrays.

## contracts/introspection/ERC8109/Behavior_IERC8109Introspection.sol — Grade: A-
- Mirrors the Behavior_IDiamondLoupe pattern for ERC-8109 by storing selector→facet expectations per subject and validating both `facetAddress(bytes4)` and `functionFacetPairs()` with rich logging.
- Uses `Bytes4Set` to guarantee coverage of all registered selectors and exposes helper contexts so tests can diff mismatched pairs quickly.
- Does not guard against calling `hasValid_*` without prior expectations (beyond a log warning) and always emits verbose console output, so large suites may wish for a silent mode flag; otherwise the behavior scaffolding is solid.

## contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol — Grade: A-
- Standard IFacet wrapper around `ERC8109IntrospectionTarget`, exposing only the `facetAddress` and `functionFacetPairs` selectors declared by `IERC8109Introspection`.
- Deterministic metadata keeps deployment tooling simple, and keeping the logic in the target avoids duplicated state.
- Consider extending `facetInterfaces()`/`facetFuncs()` to surface future optional selectors (e.g., paginated views) once the standard evolves.

## contracts/introspection/ERC8109/ERC8109IntrospectionTarget.sol — Grade: B+
- Thin proxy that reads selector→facet mappings from `ERC2535Repo` and pair listings from `ERC8109Repo`, so loupe-style reads share storage with the diamond.
- Lacks NatSpec around gas characteristics and does no caching, but functionality is correct and reuses shared repos effectively.
- Would benefit from reentrancy annotations or comments clarifying that both calls are pure reads from shared storage.

## contracts/introspection/ERC8109/ERC8109Repo.sol — Grade: B
- Implements add/replace/remove helpers on the same storage slot as `ERC2535Repo`, emitting the richer ERC-8109 events while keeping AddressSet/Bytes4Set bookkeeping consistent.
- `_getFacetFuncs` rebuilds a fresh array and copies existing pairs for every facet, making `functionFacetPairs()` O(n²) and gas-heavy on large diamonds; pre-sizing based on `_facetFunctionSelectors._length()` totals would cut costs.
- No guard rails around `delegate` caller authority—the repo happily executes arbitrary delegatecalls once invoked, so upstream targets must enforce access control.

## contracts/introspection/ERC8109/ERC8109UpdateTarget.sol — Grade: D
- Exposes `upgradeDiamond` externally without `onlyOwner` or auth hooks, meaning any account can add/replace/remove selectors and run delegatecalls the moment this target is deployed.
- Relies entirely on the caller to provide sane arrays and doesn’t surface errors from `_processDiamondUpgrade` beyond the repo-level reverts, so privilege management must wrap this contract before production use.
- Needs at least `MultiStepOwnableModifiers` or a shared guard to align with the rest of the diamond tooling.

## contracts/introspection/ERC8109/IERC8109Introspection.sol — Grade: A-
- Minimal interface declaring `FunctionFacetPair` plus the two read-only view functions with clear NatSpec, matching the behavior harness expectations.
- Could eventually inherit from `IERC165` once registration is standardized, but current scope is clean and self-contained.

## contracts/introspection/ERC8109/IERC8109Update.sol — Grade: B+
- Defines the richer upgrade API (grouped selectors, delegatecall hook, metadata) with well-documented events and error types so tooling can provide detailed revert reasons.
- Documentation clearly outlines call ordering (add → replace → remove) and logging semantics, though the interface does not mandate access control patterns, leaving implementers to add their own guards.

## contracts/introspection/ERC8109/TestBase_IERC8109Introspection.sol — Grade: A-
- Foundry base test that wires subjects into the behavior library once in `setUp()` and exposes coverage for `facetAddress`, `functionFacetPairs`, the combined interface, and a negative selector case.
- Similar to the IDiamondLoupe harness, so teams adopting ERC-8109 get a ready-made compliance suite with minimal overrides.
- Could memoize `expected_IERC8109Introspection_pairs()` in storage to avoid recomputing large arrays, but overall the harness is solid.

## contracts/introspection/IntrospectionFacetFactoryService.sol — Grade: B
- Helper library for scripts/tests that deterministically deploys ERC165, DiamondLoupe, DiamondCut facets, and the DiamondCut package via a provided CREATE3 factory, labeling each address for debugging.
- Uses hashed type-name salts to guarantee repeatable addresses but assumes the factory exposes `deployFacet/deployPackageWithArgs`; missing validation means misconfigured factories will revert deep inside.
- Consider exposing helpers for ERC8109 facets as well so the service covers the entire introspection suite.

## contracts/protocols/dexes/aerodrome/v1/aware/AerodromePoolMetadataRepo.sol — Grade: B
- Small storage helper that caches an `IPoolFactory` pointer and a boolean indicating whether pools are stable, with `_initialize` overloads for direct setup.
- No guard against re-initialization or zero-address factories, so accidental double-inits silently overwrite the stored metadata—callers must enforce invariants externally.

## contracts/protocols/dexes/aerodrome/v1/aware/AerodromeRouterAwareRepo.sol — Grade: B
- Mirrors the metadata repo but for the Aerodrome router address; exposes `_initialize` and `_aerodromeRouter()` helpers using a dedicated storage slot.
- Same caveat as above: no zero-address or initialized checks, so patterns relying on constructor-only writes should wrap these helpers carefully.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IAero.sol — Grade: B+
- Extends OpenZeppelin `IERC20` and adds minting hooks guarded by `NotMinter`/`NotOwner` errors, matching the production Aero token surface.
- Interface is intentionally small, but documenting whether `mint()` emits the standard `Transfer` would help implementers stay ERC-20 compliant.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IAirdropDistributor.sol — Grade: B
- Captures the airdrop contract’s dependency on `IAero` and `IVotingEscrow` with a single `distributeTokens` entrypoint, mirroring on-chain behavior.
- Lacks NatSpec around array length matching or ownership expectations even though the implementation reverts on mismatched inputs; callers must infer constraints from errors alone.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IEpochGovernor.sol — Grade: C
- Minimal interface that exposes the `ProposalState` enum and a single `result()` function but omits the `view` modifier, implying state writes when the real contract is read-only.
- Consider marking `result()` as `external view returns (ProposalState)` so downstream integrators can safely call it without worrying about gas stipends or mutations.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IGauge.sol — Grade: B
- Comprehensive definition of the Aerodrome gauge surface, including detailed events, reward accounting views, and dual `deposit` signatures.
- Does not declare functions for fee-claiming auth (team/voter) even though errors reference them, so periphery tooling still has to hardcode those invariants.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IMinter.sol — Grade: B
- Enumerates all governance/emission parameters plus the initialization and scheduling functions, giving integrators a single source of truth for constants like `WEEK`, `TAIL_START`, etc.
- Large block of events and getters keeps behavior transparent, but missing `view` on `initialized()` (it’s `external returns (bool)`) can trick static analyzers into thinking the call mutates state.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IPool.sol — Grade: B
- Mirrors the Velodrome/Aerodrome pool API with exhaustive accessors (metadata, TWAP sampling, fees) and emits canonical events.
- Uses non-view signature for `getK()` even though it should not mutate, and there’s no explicit reentrancy guidance for `swap/mint/burn`, so wrappers must rely on implementation details.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IPoolCallee.sol — Grade: B-
- Simple callback interface for flash hooks with a single `hook` function; matches Uniswap V2 style callee contracts.
- Lacks NatSpec explaining expected revert semantics or how `data` should be encoded, so integrators must dig into Pool implementation docs.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IReward.sol — Grade: B
- Captures both internal `_deposit/_withdraw` hooks and the public claiming surface, plus rich checkpoint metadata to support veNFT rewards accounting.
- Because the interface exposes internal-only methods, external tooling must gate calls carefully; splitting public vs internal surfaces would reduce the chance of misusing `_deposit` directly.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IRewardsDistributor.sol — Grade: B
- Declares the rebasing distributor API with epoch constants, events, and error types, ensuring Minter → Distributor integration is well specified.
- `setMinter` is documented as “callable once” but the interface doesn’t encode that constraint; highlighting the intended call order would help auditors.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol — Grade: B
- Very thorough router interface covering liquidity management, swaps (including fee-on-transfer variants), and zap helpers, closely tracking Velodrome v2’s Router.
- Error set is extensive, but many functions return raw arrays without enum typing; consider splitting zap helpers into a dedicated interface to keep consumers from having to import the entire router surface when they only need core swaps.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IVeArtProxy.sol — Grade: B
- Rich art-generation surface mirroring Aerodrome’s SVG proxy with configs, line helpers, and pure geometry routines so off-chain renderers can stay in sync.
- Interface is descriptive but lacks `view` tags on the pure geometry helpers (`twoStripes`, etc.); marking them `pure` (as in the implementation) would reduce lint noise for integrators building mocks.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IVoter.sol — Grade: B
- Exhaustive definition of the governance contract (errors, events, getters, and admin setters) so periphery code can build precise call data.
- Many mutating functions (`vote`, `depositManaged`, etc.) lack comments around expected reverts beyond the error enums, and the interface doesn’t communicate auth expectations (governor vs emergency council), so wrappers must hardcode those policies.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IVotes.sol — Grade: B-
- TokenId-scoped variant of OZ `IVotes`, exposing delegate events plus `delegateBySig` for veNFTs.
- `getPastVotes` signature accepts both `account` and `tokenId` yet docs claim passing a non-owner returns zero; that nuance should be enforced in code and clarified here to avoid misuse.

## contracts/protocols/dexes/aerodrome/v1/interfaces/IVotingEscrow.sol — Grade: B
- Massive interface combining ERC721, ERC165, ERC6372, art hooks, managed-NFT utilities, and DAO voting extensions—all the surface area veNFT tooling needs.
- Because it mixes read/write responsibilities in one file, consumers frequently import more than needed; consider splitting metadata/art, managed-lock management, and DAO voting portions into subinterfaces to keep type sizes manageable.

## contracts/protocols/dexes/aerodrome/v1/interfaces/factories/IFactoryRegistry.sol — Grade: B
- Specifies the registry responsibilities (approve/unapprove factories, get factory tuples, manage managedRewardsFactory) with clear events and error types.
- The `approve()` docs mention immutability but the interface doesn’t expose a view that returns whether a path is the immutable fallback; downstream contracts must infer it from errors.

## contracts/protocols/dexes/aerodrome/v1/interfaces/factories/IGaugeFactory.sol — Grade: B
- Minimal factory interface that enforces five constructor-like parameters (`forwarder`, `pool`, `feesVotingReward`, `ve`, `isPool`).
- Would benefit from emitting an event or returning more context so deployments can be indexed without inspecting transaction logs externally.

## contracts/protocols/dexes/aerodrome/v1/interfaces/factories/IManagedRewardsFactory.sol — Grade: B
- Describes the paired locked/free reward deployments for managed veNFTs and emits a helpful `ManagedRewardCreated` event.
- Doesn’t specify access control (governor vs voter) even though misuse could brick reward flows; documentation should clarify who is allowed to call `createRewards`.

## contracts/protocols/dexes/aerodrome/v1/interfaces/factories/IPoolFactory.sol — Grade: B
- Covers pool creation, fee configuration, pausing, and gauge voter wiring so scripts can orchestrate new pools deterministically.
- Some getters (`isPool`, `getPool`) omit NatSpec parameter names (doc comments show bare `@param .`), making generated docs hard to read; cleaning that up would improve usability.

## contracts/protocols/dexes/aerodrome/v1/interfaces/factories/IVotingRewardsFactory.sol — Grade: B
- Simple interface to mint the fees/bribe reward contracts per gauge, matching the Voter expectations.
- Similar to other factories, access control requirements aren’t encoded; noting if only the Voter may call it would reduce integration mistakes.

## contracts/protocols/dexes/aerodrome/v1/services/AerodromService.sol — Grade: C+
- Helper library that automates swap-and-deposit or withdraw-and-swap flows against Aerodrome pools using the router plus constant-product math.
- `_swap` and `_swapDepositVolatile` approve the router and execute swaps with `amountOutMin = 0`, so callers inherit full price-slippage risk; at minimum, these helpers should accept slippage thresholds.
- `_swapDepositVolatile` leaves token approvals at whatever value was last used and routes intermediate swaps through `address(this)` without allowing custom recipients, so reentrancy or leftover approvals could be abused if the library is linked into upgradeable contracts.

## contracts/protocols/dexes/balancer/v3/vault/VaultGuardModifiers.sol — Grade: D
- All logic is commented out, so importing this file contributes nothing but dead code and will break any contract expecting an `onlyVault` modifier [contracts/protocols/dexes/balancer/v3/vault/VaultGuardModifiers.sol#L1-L17](contracts/protocols/dexes/balancer/v3/vault/VaultGuardModifiers.sol#L1-L17).
- If the guard is deprecated, delete the file; otherwise re-enable the modifier to keep Balancer-aware facets from rolling their own ad hoc checks.

## contracts/protocols/dexes/camelot/v2/CamelotV2FactoryAwareRepo.sol — Grade: B-
- `_initialize` blindly overwrites the stored factory pointer with no zero-address guard or event, so calling it twice silently repoints every Camelot-aware facet [contracts/protocols/dexes/camelot/v2/CamelotV2FactoryAwareRepo.sol#L23-L30](contracts/protocols/dexes/camelot/v2/CamelotV2FactoryAwareRepo.sol#L23-L30).
- The getters simply return whatever sits in the slot and never assert initialization, meaning downstream reads can succeed with `address(0)` and mask wiring bugs [contracts/protocols/dexes/camelot/v2/CamelotV2FactoryAwareRepo.sol#L31-L36](contracts/protocols/dexes/camelot/v2/CamelotV2FactoryAwareRepo.sol#L31-L36).

## contracts/protocols/dexes/camelot/v2/CamelotV2RouterAwareRepo.sol — Grade: B-
- Same storage helper pattern as the factory-aware library, and it shares the same problems: `_initialize` will overwrite the router pointer without emitting anything or refusing `address(0)` [contracts/protocols/dexes/camelot/v2/CamelotV2RouterAwareRepo.sol#L23-L30](contracts/protocols/dexes/camelot/v2/CamelotV2RouterAwareRepo.sol#L23-L30).
- `_camelotV2Router()` performs no sanity checks, so consumers can happily fetch and use a zero router address until a runtime revert exposes the issue [contracts/protocols/dexes/camelot/v2/CamelotV2RouterAwareRepo.sol#L31-L36](contracts/protocols/dexes/camelot/v2/CamelotV2RouterAwareRepo.sol#L31-L36).

## contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol — Grade: C
- `_deposit` unconditionally calls `approve(router, amount)` for both tokens every time it runs and never resets allowances, so tokens that require zeroing allowances (USDT-style) will revert and any compromise of the router can drain lingering approvals [contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol#L59-L86](contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol#L59-L86).
- `_executeSwap` hardcodes `amountOutMin` to `1` for every router trade, effectively disabling slippage protection across `_swap`, `_swapDeposit`, and `_balanceAssetsInternal` flows [contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol#L96-L138](contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol#L96-L138).
- `_balanceAssetsInternal` always routes half the sale amount through `_swap` and never validates the post-swap ratio, so large orders can take any price the pool offers with no guardrails [contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol#L269-L305](contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol#L269-L305).

## contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol — Grade: B-
- `createPair` derives its CREATE2 salt solely from the token addresses, so any competing factory that reuses this bytecode on the same chain will collide at the exact same addresses and permanently DoS duplicate deployments [contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol#L63-L90](contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol#L63-L90).
- `setReferrerFeeShare` only enforces an absolute cap and never bounds the combined owner+referrer percentages, so misconfiguration can make the pair subtract more fees than it collected and revert every swap [contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol#L123-L132](contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol#L123-L132).

## contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol — Grade: C
- The contract is littered with `betterconsole` logging in `_mintFee`, `burn`, and `_getAmountOut`, so compiling this for production will either fail (cheatcodes aren’t linked outside Foundry) or waste massive gas [contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol#L166-L444](contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol#L166-L444).
- Swaps rely on `SafeMath` plus manual fee bookkeeping, but the debug logging hides the real invariant checks and makes it hard to reason about underflow when the factory misconfigures fee shares [contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol#L298-L420](contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol#L298-L420).

## contracts/protocols/dexes/camelot/v2/stubs/CamelotRouter.sol — Grade: B
- `_swapSupportingFeeOnTransferTokens` drives every path, yet it assumes `path.length >= 2` and will panic with an out-of-bounds array read if callers forget to validate inputs before funding the pair [contracts/protocols/dexes/camelot/v2/stubs/CamelotRouter.sol#L217-L236](contracts/protocols/dexes/camelot/v2/stubs/CamelotRouter.sol#L217-L236).
- All public swap functions forward to that helper and expose only the “supporting fee-on-transfer” variants, so there is no way to perform standard `swapExactTokensForTokens` or specify per-hop recipients—limiting compatibility with tooling that expects the full V2 router surface [contracts/protocols/dexes/camelot/v2/stubs/CamelotRouter.sol#L239-L307](contracts/protocols/dexes/camelot/v2/stubs/CamelotRouter.sol#L239-L307).

## contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol — Grade: B
- Implements ERC-20 + permit directly, but it never emits `Approval` when `transferFrom` spends an allowance of `type(uint256).max`, so wallets tracking allowance usage won’t observe any event [contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol#L71-L95](contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol#L71-L95).
- `permit` increments the nonce before verifying the signature, meaning a failing signature permanently burns the nonce and bricks the owner’s next permit attempt [contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol#L96-L115](contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol#L96-L115).

## contracts/protocols/dexes/camelot/v2/stubs/libraries/Math.sol — Grade: B
- Minimal helper containing only `min` and a Babylonian `sqrt`, but there are no overflow comments or unit tests verifying convergence, so consumers must trust an unaudited implementation [contracts/protocols/dexes/camelot/v2/stubs/libraries/Math.sol#L1-L18](contracts/protocols/dexes/camelot/v2/stubs/libraries/Math.sol#L1-L18).

## contracts/protocols/dexes/camelot/v2/stubs/libraries/SafeMath.sol — Grade: B
- Classic ds-math wrappers with revert strings, but they predate Solidity’s built-in checked arithmetic and add unnecessary bytecode while yielding no contextual errors [contracts/protocols/dexes/camelot/v2/stubs/libraries/SafeMath.sol#L1-L16](contracts/protocols/dexes/camelot/v2/stubs/libraries/SafeMath.sol#L1-L16).
- Recommend deleting this library and using native checked math to reduce deployment size and keep error surfaces consistent with the rest of the repo.

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Conversion.sol — Grade: C
- `_convertDecimalsFromTo` exponentiates ten by the raw decimal delta with no upper bound, so converting between tokens whose decimals differ by >77 (or fuzz tests that exceed that delta) overflows `10 ** delta` and silently returns truncated amounts [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Conversion.sol#L9-L21](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Conversion.sol#L9-L21).
- `_normalize` hardcodes every value to 2 decimal places by calling `_precision(..., 2)`, which irreversibly scales 18-decimal ERC20 amounts down to cents and loses most precision whenever the helper is used [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Conversion.sol#L23-L28](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Conversion.sol#L23-L28).

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/FixedPointWadMathLib.sol — Grade: C
- `_mulDivDown` and `_mulDivUp` attempt to skip the `div(z, x)` overflow check when `x == 0`, but EVM evaluates both `or` operands, so calling either helper with `x == 0` still executes `div(z, x)` and immediately reverts with a division-by-zero even though the math should simply return 0 [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/FixedPointWadMathLib.sol#L30-L59](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/FixedPointWadMathLib.sol#L30-L59).
- `_divWadDown`/`_divWadUp` had their explicit `require(y != 0)` checks commented out, so a zero denominator now bubbles the raw `revert(0,0)` from the assembly helpers, making it very hard to diagnose bad inputs and diverging from the rest of the math library’s error conventions [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/FixedPointWadMathLib.sol#L16-L29](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/FixedPointWadMathLib.sol#L16-L29).

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Fraction.sol — Grade: D
- The file only declares `Fraction`/`Fraction112` structs plus an `InvalidFraction` error and is littered with TODOs; there are no construction, normalization, or arithmetic helpers, so any contract importing “Fraction” still has to re-implement the missing utilities [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Fraction.sol#L1-L17](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Fraction.sol#L1-L17).
- Without normalization helpers, callers can freely create fractions with zero denominators or unbounded numerators and only discover the problem later when downstream math reverts; the TODOs should be closed before exposing this as a reusable type.

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Math.sol — Grade: C
- `_abs` guards against `type(int256).max` instead of `type(int256).min`, so calling `_abs(type(int256).min)` still overflows and wraps while the largest positive value is inexplicably forbidden [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Math.sol#L148-L153](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Math.sol#L148-L153).
- The file duplicates multiple sqrt implementations (`_sqrtFast`, `_sqrrt`, `_sqrt`, `_sqrtRoundDown`) yet none are unit-tested and the public `_sqrt(uint256 a)` simply devolves into the naive Babylonian loop without any overflow protection or iteration cap, making it very easy for malformed inputs to spin or return incorrect roots [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Math.sol#L43-L131](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/Math.sol#L43-L131).

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/MathEx.sol — Grade: C
- `exp2` passes whatever denominator the caller supplies straight into `mulDivF(LN2, f.n, f.d)` with no zero guard, so providing the default `Fraction(0,0)` blows up with a low-level divide-by-zero instead of a descriptive `InvalidFraction` [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/MathEx.sol#L26-L82](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/MathEx.sol#L26-L82).
- `mulDivF` assumes `z != 0` and never checks it, meaning a simple caller mistake (zero denominator) flows through to `_div512`/`_inv256` and produces meaningless `Overflow` errors instead of the explicit guard the struct-level error was meant to provide [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/MathEx.sol#L122-L214](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/MathEx.sol#L122-L214).

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/SafeMath.sol — Grade: C+
- Forked from OZ v4.4 with the strong “TODO Retire” warning, yet the file is still widely imported; every arithmetic helper just calls the native operator, so the library adds bytecode without providing better errors [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/SafeMath.sol#L1-L154](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/SafeMath.sol#L1-L154).
- If the team wants custom revert strings, the wrappers should emit them in the `try*` helpers; otherwise delete this file and rely on Solidity 0.8’s checked math to avoid duplicating dead code.

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/TransferHelper.sol — Grade: B-
- `safeApprove` sets allowances to any value without the required zero-first pattern, so interacting with USDT/USDC-style tokens that demand `approve(0)` before a new spend limit will revert outright [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/TransferHelper.sol#L6-L18](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/TransferHelper.sol#L6-L18).
- All helpers decode the return payload strictly as `bool`, which makes transfers for ERC20s that return nothing or `bytes32` (a common real-world variant) revert with `abi.decode` even though the token actually succeeded [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/TransferHelper.sol#L10-L33](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/TransferHelper.sol#L10-L33).

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/UQ112x112.sol — Grade: B-
- `uqdiv` divides by `y` with no zero check, so misconfigured reserve calls surface as raw division-by-zero panics rather than a controlled revert [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/UQ112x112.sol#L14-L21](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/UQ112x112.sol#L14-L21).
- The library exposes only encode/divide helpers and never documents the expected scaling factor or overflow caveats, making it easy for integrators to mix up raw reserve units with Q112 values.

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/UniswapV2Library.sol — Grade: C-
- `pairFor` just calls `IUniswapV2Factory.getPair` instead of deriving the CREATE2 address, so router code that expects deterministic pair addresses (to transfer tokens before the pair exists) ends up sending funds to `address(0)` whenever a pool hasn’t been deployed yet [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/UniswapV2Library.sol#L16-L29](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/UniswapV2Library.sol#L16-L29).
- Both `getAmountOut` and `getAmountIn` hard-code the classic 0.3% fee (997/1000) and ignore Camelot/Crane’s configurable fee percent fields, so any pool with custom fees will produce consistently wrong quotes [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/UniswapV2Library.sol#L35-L64](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/UniswapV2Library.sol#L35-L64).

## contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/WadRayMath.sol — Grade: C
- `_rayToWad` adds `a` and `WAD_RAY_RATIO / 2` without any overflow guard after the OZ checks were commented out, so large ray inputs wrap around `2^256` and return tiny wad values instead of reverting [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/WadRayMath.sol#L88-L100](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/WadRayMath.sol#L88-L100).
- `_wadToRay` multiplies by `1e9` with the same “overflow-safe in 0.8” comment, but removing the guard means any wad greater than ~2^247 silently wraps and corrupts the scaled value [contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/WadRayMath.sol#L102-L110](contracts/protocols/dexes/uniswap/v2/stubs/deps/libs/WadRayMath.sol#L102-L110).

## contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol — Grade: C
- `addBalancedUniswapLiquidity` “funds” the prospective LP by calling `deal(token, recipient, amount, true)` even though Uniswap pulls tokens from `msg.sender`, so when `recipient_ != address(this)` the router has no balances to draw from and the helper reverts before minting LP tokens [contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol#L66-L111](contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol#L66-L111).
- The same function approves the router from `address(this)` (the helper) while all balances sit on `recipient_`, so even if the recipient is pranked to hold tokens the router still lacks allowance and the test utility never succeeds off-harness [contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol#L86-L110](contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol#L86-L110).

## contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol — Grade: C+
- `_createUniswapPairs` blindly trusts `createPair` and never checks for `address(0)`, so calling the helper twice in a suite silently produces zeroed pair references that later liquidity inits and assertions dereference [contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol#L44-L82](contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol#L44-L82).
- `_executeUniswapTradesToGenerateFees` hardcodes `amountOutMin = 0` for every swap path, meaning fee-generation smoke tests happily pass even if routers return zero or dust and therefore can’t catch slippage handling bugs [contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol#L102-L144](contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol#L102-L144).

## contracts/protocols/launchpads/ape-express/test/stubs/MockDegenFactory.sol — Grade: B
- `addCreator` lacks even basic validation, so the owner can accidentally map `address(0)` tokens or creators and silently overwrite existing entries since there is no guard or event to surface the change [contracts/protocols/launchpads/ape-express/test/stubs/MockDegenFactory.sol#L14-L24](contracts/protocols/launchpads/ape-express/test/stubs/MockDegenFactory.sol#L14-L24).

## contracts/protocols/tokens/wrappers/wape/WAPE.sol — Grade: D
- WAPE just inherits `WETH9` and never overrides `name()`/`symbol()`, so on-chain metadata still reports “Wrapped Ether” / “WETH” instead of “Wrapped ApeCoin”, which breaks UI symbol routing [contracts/protocols/tokens/wrappers/wape/WAPE.sol#L8-L43](contracts/protocols/tokens/wrappers/wape/WAPE.sol#L8-L43).
- The contract continues to wrap native ETH (deposit/withdraw manage `msg.value`) and has zero integration with ApeCoin balances, so it never actually custodians the underlying asset it claims to represent [contracts/protocols/tokens/wrappers/wape/WAPE.sol#L8-L43](contracts/protocols/tokens/wrappers/wape/WAPE.sol#L8-L43).

## contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol — Grade: A
- No material issues; minimal harness that just deploys a test WETH instance [contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol#L1-L22](contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol#L1-L22).

## contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol — Grade: C-
- The canonical `Deposit`/`Withdrawal` bookkeeping no longer emits ERC20 `Transfer` events (the declarations are commented out), so indexers and downstream accounting can’t see mint/burn flows even though totalSupply changes [contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L24-L55](contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L24-L55).
- `withdraw` still relies on `transfer`, forwarding only 2.3k gas and risking hard-bricking contract callers after EIP-1884 style gas repricings; best practice is to use `call{value: wad}()` with success checks [contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L50-L55](contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L50-L55).

## contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol — Grade: C+
- `weth()` simply returns whatever lies in storage slot `protocols.tokens.wrappers.weth.v9` without verifying initialization, so misconfigured packages quietly return `address(0)` instead of reverting [contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol#L10-L38](contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol#L10-L38).
- The facet exposes no initializer or setter, meaning there is no diamond-level entry point that can actually populate `WETHAwareRepo`; deployments must rely on opaque external scripts and there is no way to rotate WETH if the canonical instance changes [contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol#L10-L38](contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol#L10-L38).

## contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol — Grade: C+
- `_initialize` can be called repeatedly and just overwrites the stored pointer, so any facet that gains access to this internal helper can silently retarget the shared WETH instance without leaving traces [contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol#L24-L34](contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol#L24-L34).
- `_setWeth` accepts `address(0)`, so a bad initializer call bricks every consumer by making `weth()` return zero forever [contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol#L32-L41](contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol#L32-L41).

## contracts/protocols/utils/permit2/Allowance.sol — Grade: C
- `updateAll` increments the nonce inside an `unchecked` block and never bounds the input, so once `nonce == type(uint48).max` the stored value wraps to zero and every historical signature for nonce 0 suddenly becomes valid again [contracts/protocols/utils/permit2/Allowance.sol#L13-L30](contracts/protocols/utils/permit2/Allowance.sol#L13-L30).
- None of the helpers validate that `amount <= type(uint160).max` or `expiration <= type(uint48).max` before packing, so oversize inputs silently truncate and end up approving drastically smaller allowances/shorter expirations than expected [contracts/protocols/utils/permit2/Allowance.sol#L13-L47](contracts/protocols/utils/permit2/Allowance.sol#L13-L47).

## contracts/protocols/utils/permit2/AllowanceTransfer.sol — Grade: B+
- No new issues beyond the underlying `Allowance` packing problems; the contract otherwise mirrors Uniswap’s Permit2 logic [contracts/protocols/utils/permit2/AllowanceTransfer.sol#L21-L151](contracts/protocols/utils/permit2/AllowanceTransfer.sol#L21-L151).

## contracts/proxies/MinimalDiamondCallBackProxy.sol — Grade: C
- The constructor blindly calls `IFactoryCallBack(msg.sender)._initAccount()` without checking that the deployer actually implements the callback interface, so any mistaken CREATE3 salt (or an EOA deploy) permanently bricks the proxy before it can ever route function selectors [contracts/proxies/MinimalDiamondCallBackProxy.sol#L24-L34](contracts/proxies/MinimalDiamondCallBackProxy.sol#L24-L34).

## contracts/proxies/Proxy.sol — Grade: B+
- Core delegate relay is sound; no additional issues spotted beyond the lack of NatSpec/tests already tracked in TODOs [contracts/proxies/Proxy.sol#L21-L53](contracts/proxies/Proxy.sol#L21-L53).

## contracts/registries/facet/FacetRegistry.sol — Grade: C
- `_registerFacet` fully trusts each facet’s self-reported metadata and never cross-checks the advertised selectors/interfaces against the deployed bytecode, so a malicious facet can pollute the registry with fake capabilities and misdirect consumers [contracts/registries/facet/FacetRegistry.sol#L70-L83](contracts/registries/facet/FacetRegistry.sol#L70-L83).

## contracts/registries/package/DiamondFactoryPackageRegistry.sol — Grade: C
- Packages likewise register whatever metadata they claim without validation, meaning a compromised package can declare arbitrary interfaces/facets and trick downstream deployments into wiring the wrong building blocks [contracts/registries/package/DiamondFactoryPackageRegistry.sol#L74-L87](contracts/registries/package/DiamondFactoryPackageRegistry.sol#L74-L87).

## contracts/script/BetterScript.sol — Grade: A
- Thin wrapper around `forge-std`’s `Script`; no issues [contracts/script/BetterScript.sol#L1-L8](contracts/script/BetterScript.sol#L1-L8).

## contracts/script/DeployedAddressesRepo.sol — Grade: B-
- `_registerDeployedAddress` accepts and stores whatever address the caller passes, including `address(0)` or duplicates, so a single bad registration can poison the shared set for all later lookups; add zero-address guards and either dedupe or expose delete utilities [contracts/script/DeployedAddressesRepo.sol#L31-L46](contracts/script/DeployedAddressesRepo.sol#L31-L46).

## contracts/test/BetterTest.sol — Grade: A
- Simple test base class; no issues [contracts/test/BetterTest.sol#L4-L11](contracts/test/BetterTest.sol#L4-L11).

## contracts/test/CraneTest.sol — Grade: C+
- `setUp` assigns `diamondFactory = diamondPackageFactory`, so the suite never keeps a handle to an actual factory separate from the package factory and tests that expect two distinct endpoints unknowingly hit the same contract [contracts/test/CraneTest.sol#L16-L21](contracts/test/CraneTest.sol#L16-L21).

## contracts/test/behaviors/BehaviorUtils.sol — Grade: A
- Helper library just formats error prefixes; no issues [contracts/test/behaviors/BehaviorUtils.sol#L16-L42](contracts/test/behaviors/BehaviorUtils.sol#L16-L42).

## contracts/test/comparators/AddressSetComparator.sol — Grade: C-
- `_compare` writes expected/actual addresses into storage buckets keyed by `abi.encode(actual)` but never clears them, so reusing the comparator in the same run accumulates stale entries and produces false positives/negatives on every subsequent assertion [contracts/test/comparators/AddressSetComparator.sol#L94-L130](contracts/test/comparators/AddressSetComparator.sol#L94-L130).

## contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol — Grade: C
- `addBalancedUniswapLiquidity` transfers tokens to `recipient_` via `deal` but approves the router from `address(this)` regardless of who actually holds the balance, so the helper reverts whenever the caller requests LP tokens for any address other than the test contract itself [contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol#L86-L111](contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol#L86-L111).
- The same helper tries to derive the missing leg with `_equivLiquidity` even when the pool has zero reserves; the util explicitly returns 0 in that case, which produces a zero-amount add and forces the router call to fail instead of seeding an empty pair [contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol#L78-L84](contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol#L78-L84) and [contracts/utils/math/ConstProdUtils.sol#L778-L797](contracts/utils/math/ConstProdUtils.sol#L778-L797).

## contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol — Grade: C+
- `setUp` only deploys tokens and pairs, leaving every helper to operate on pools with zero reserves; any derived test that calls `_executeUniswapTradesToGenerateFees` or uses router math before remembering to run one of the `_initialize*` helpers will revert immediately [contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol#L38-L100](contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol#L38-L100).
- `_executeUniswapTradesToGenerateFees` assumes prior initialization but never checks for non-zero LP balances, so it happily mints tokens and attempts swaps that will revert under the default zero-liquidity state, producing brittle, order-dependent tests [contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol#L102-L144](contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2_Pools.sol#L102-L144).

## contracts/protocols/launchpads/ape-express/test/stubs/MockDegenFactory.sol — Grade: B-
- The constructor forwards `owner_` straight into `MultiStepOwnableRepo._initialize` without validating it, so deploying with `address(0)` bricks ownership forever and leaves the factory without an operator [contracts/protocols/launchpads/ape-express/test/stubs/MockDegenFactory.sol#L14-L17](contracts/protocols/launchpads/ape-express/test/stubs/MockDegenFactory.sol#L14-L17).
- `addCreator` writes unconditionally to `creatorByToken` with no zero-address guard, no event, and no protection against overwriting an existing creator, making it easy for an operator to erase metadata accidentally [contracts/protocols/launchpads/ape-express/test/stubs/MockDegenFactory.sol#L19-L24](contracts/protocols/launchpads/ape-express/test/stubs/MockDegenFactory.sol#L19-L24).

## contracts/protocols/tokens/wrappers/wape/WAPE.sol — Grade: C
- `WAPE` is advertised as wrapped ApeCoin but simply inherits `WETH9`, so the token metadata and events still say “Wrapped Ether”/“WETH”, guaranteeing that wallets, explorers, and accounting software mislabel balances [contracts/protocols/tokens/wrappers/wape/WAPE.sol#L8-L11](contracts/protocols/tokens/wrappers/wape/WAPE.sol#L8-L11) and [contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L25-L33](contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L25-L33).
- Because no functionality is overridden, deposits/withdrawals keep the ETH-specific semantics (gas-stipend `transfer`, ETH balance backing, etc.), so the contract cannot actually wrap ApeCoin without significant additional plumbing [contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L45-L55](contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L45-L55).

## contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol — Grade: A
- Minimal fixture correctly deploys and labels a single `WETH9` instance per test contract; no issues identified [contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol#L16-L21](contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol#L16-L21).

## contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol — Grade: C
- `withdraw` still relies on `transfer`, limiting the refund to 2,300 gas and preventing contracts with non-trivial fallback logic from unwrapping WETH; the industry-standard fix is to switch to `call` and bubble the boolean result [contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L50-L55](contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L50-L55).
- The token inherits the classic ERC20 approval race condition (no requirement to zero-out before changing allowances), so integrators need to manually mitigate a well-known attack surface; consider implementing `increaseAllowance`/`decreaseAllowance` helpers or enforcing zero-first semantics [contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L61-L77](contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol#L61-L77).

## contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol — Grade: C+
- `weth()` simply returns whatever `_weth` holds with no zero-address guard, so packages wiring this facet can unknowingly operate against `address(0)` and end up sending ETH into a black hole [contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol#L36-L38](contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol#L36-L38).
- The facet exposes no initializer or admin surface to set WETH, forcing downstream packages to reach into the repo storage directly and increasing the chances of inconsistent wiring [contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol#L9-L38](contracts/protocols/tokens/wrappers/weth/v9/WETHAwareFacet.sol#L9-L38).

## contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol — Grade: C
- `_initialize` can be called repeatedly by any facet/library that links the repo, so a malicious initializer (or a misconfigured upgrade) can swap the stored WETH implementation after deployment [contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol#L24-L34](contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol#L24-L34).
- `_setWeth` accepts the zero address, meaning a single bad call clears the canonical WETH pointer and leaves every `IWETHAware` consumer interacting with `address(0)` [contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol#L32-L34](contracts/protocols/tokens/wrappers/weth/v9/WETHAwareRepo.sol#L32-L34).

## contracts/protocols/utils/permit2/Allowance.sol — Grade: C
- `updateAmountAndExpiration` treats an expiration of 0 as “expires at the current block timestamp,” so any integrator that passes 0 expecting “no expiry” immediately invalidates their own approval [contracts/protocols/utils/permit2/Allowance.sol#L32-L41](contracts/protocols/utils/permit2/Allowance.sol#L32-L41).
- `updateAll` increments the 48-bit nonce with unchecked addition; once it reaches `type(uint48).max` it silently wraps to 0, re-enabling every historical signature that used nonce 0 [contracts/protocols/utils/permit2/Allowance.sol#L19-L27](contracts/protocols/utils/permit2/Allowance.sol#L19-L27).

## contracts/protocols/utils/permit2/AllowanceTransfer.sol — Grade: C-
- `approve` updates only the amount/expiration and never bumps the nonce, so any previously leaked signature that references the current nonce can be replayed later to overwrite a manual approval [contracts/protocols/utils/permit2/AllowanceTransfer.sol#L34-L49](contracts/protocols/utils/permit2/AllowanceTransfer.sol#L34-L49) and [contracts/protocols/utils/permit2/AllowanceTransfer.sol#L140-L150](contracts/protocols/utils/permit2/AllowanceTransfer.sol#L140-L150).
- `lockdown` intends to revoke allowances but merely zeroes the stored amount without changing the nonce, allowing an attacker with an old signature to call `permit` after the lockdown and reinstate their allowance [contracts/protocols/utils/permit2/AllowanceTransfer.sol#L105-L150](contracts/protocols/utils/permit2/AllowanceTransfer.sol#L105-L150).

## contracts/protocols/utils/permit2/BetterPermit2.sol — Grade: A
- Thin composition of `SignatureTransfer` and `AllowanceTransfer`; domain separator routing and inheritance order match canonical Permit2 expectations and no defects were identified [contracts/protocols/utils/permit2/BetterPermit2.sol#L1-L18](contracts/protocols/utils/permit2/BetterPermit2.sol#L1-L18).

## contracts/protocols/utils/permit2/EIP712.sol — Grade: A
- Mirrors the OZ-style cached domain separator pattern (chainid + contract address) and uses Solady hashing helpers correctly; no issues detected [contracts/protocols/utils/permit2/EIP712.sol#L18-L51](contracts/protocols/utils/permit2/EIP712.sol#L18-L51).

## contracts/protocols/utils/permit2/PermitErrors.sol — Grade: A
- File only declares the common `SignatureExpired`/`InvalidNonce` errors and matches the external interfaces; nothing to fix [contracts/protocols/utils/permit2/PermitErrors.sol#L1-L12](contracts/protocols/utils/permit2/PermitErrors.sol#L1-L12).

## contracts/protocols/utils/permit2/PermitHash.sol — Grade: C
- Every signature-transfer hash substitutes `msg.sender` (the current caller) instead of the `spender` supplied inside the struct, so any signature produced with the canonical Uniswap Permit2 tooling (which encodes the spender field) will fail to verify here, making this implementation incompatible with existing wallets [contracts/protocols/utils/permit2/PermitHash.sol#L81-L166](contracts/protocols/utils/permit2/PermitHash.sol#L81-L166).
- Because the verifier no longer reads `permit.spender`, nothing prevents a future refactor (or library fix) from reusing the canonical struct hash and unintentionally letting arbitrary callers replay signatures; at minimum the contract that consumes these hashes needs an explicit `require(msg.sender == spender)` guard to avoid latent authorization bugs [contracts/protocols/utils/permit2/PermitHash.sol#L81-L166](contracts/protocols/utils/permit2/PermitHash.sol#L81-L166) and [contracts/protocols/utils/permit2/SignatureTransfer.sol#L36-L107](contracts/protocols/utils/permit2/SignatureTransfer.sol#L36-L107).

## contracts/protocols/utils/permit2/SignatureTransfer.sol — Grade: C+
- Authorization relies entirely on the hashing quirk above; there is no explicit comparison between the signer-approved spender and `msg.sender`, so correcting `PermitHash` to the L2/Uniswap spec would immediately let any address replay signatures they were never granted [contracts/protocols/utils/permit2/SignatureTransfer.sol#L36-L107](contracts/protocols/utils/permit2/SignatureTransfer.sol#L36-L107).
- `_permitTransferFrom` trusts the token pointer embedded in `permit.permitted` and never validates it against canonical registry lists, so a compromised signature can drain arbitrary ERC20s once the nonce is leaked; consider adding optional token allowlists when wiring this contract into user-facing flows [contracts/protocols/utils/permit2/SignatureTransfer.sol#L66-L138](contracts/protocols/utils/permit2/SignatureTransfer.sol#L66-L138).

## contracts/protocols/utils/permit2/SignatureVerification.sol — Grade: C
- ECDSA verification never enforces the low-`s` condition or restricts `v` to {27,28}, so every permit admits a second, malleated signature and wallets cannot rely on canonical encoding [contracts/protocols/utils/permit2/SignatureVerification.sol#L21-L41](contracts/protocols/utils/permit2/SignatureVerification.sol#L21-L41).
- The library treats any non-65-byte signature as EIP-2098 but does not reject odd lengths, which lets an attacker craft garbage payloads that pass length validation yet still feed uninitialized `v` values into `ecrecover`, reducing diagnosability [contracts/protocols/utils/permit2/SignatureVerification.sol#L26-L41](contracts/protocols/utils/permit2/SignatureVerification.sol#L26-L41).

## contracts/protocols/utils/permit2/aware/Permit2AwareFacet.sol — Grade: C
- The facet exposes metadata but never provides an initializer or setter for the underlying Permit2 pointer, so any package wiring this facet must still reach into storage manually, defeating the purpose of the abstraction [contracts/protocols/utils/permit2/aware/Permit2AwareFacet.sol#L12-L41](contracts/protocols/utils/permit2/aware/Permit2AwareFacet.sol#L12-L41).
- Bundling `Permit2AwareTarget` directly into the facet means there is still no zero-address guard; `permit2()` can legally return `address(0)` and downstream contracts will attempt to call an empty target [contracts/protocols/utils/permit2/aware/Permit2AwareFacet.sol#L12-L41](contracts/protocols/utils/permit2/aware/Permit2AwareFacet.sol#L12-L41).

## contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol — Grade: C
- `_initialize` can be invoked repeatedly, so any facet/library granted access to the repo can silently swap the globally cached Permit2 implementation after deployment [contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol#L36-L54](contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol#L36-L54).
- `_initialize`/`_permit2` never validate that the pointer is non-zero, so a single bad call wipes the repo and every consumer suddenly reads `address(0)` [contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol#L36-L62](contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol#L36-L62).

## contracts/protocols/utils/permit2/aware/Permit2AwareTarget.sol — Grade: C+
- `permit2()` forwards the repo value as-is, so callers get no indication when the pointer has not been initialized or has been cleared; surface a revert or explicit error to avoid silently operating against `address(0)` [contracts/protocols/utils/permit2/aware/Permit2AwareTarget.sol#L11-L14](contracts/protocols/utils/permit2/aware/Permit2AwareTarget.sol#L11-L14).
- The target also lacks any admin wiring helpers, forcing every consumer package to duplicate initialization logic and increasing the odds of inconsistent Permit2 addresses [contracts/protocols/utils/permit2/aware/Permit2AwareTarget.sol#L11-L36](contracts/protocols/utils/permit2/aware/Permit2AwareTarget.sol#L11-L36).

## contracts/protocols/utils/permit2/test/bases/TestBase_Permit2.sol — Grade: A
- Fixture cleanly deploys a single `BetterPermit2` instance and caches it for derived tests; no issues detected [contracts/protocols/utils/permit2/test/bases/TestBase_Permit2.sol#L12-L20](contracts/protocols/utils/permit2/test/bases/TestBase_Permit2.sol#L12-L20).

## contracts/protocols/dexes/camelot/v2/stubs/libraries/TransferHelper.sol — Grade: B-
- `safeApprove` blindly overwrites allowances via a low-level call and never enforces the zero-allowance reset that USDT-style tokens require, so any caller that tries to refresh approvals without first zeroing them will hit a hard revert [contracts/protocols/dexes/camelot/v2/stubs/libraries/TransferHelper.sol#L6-L18](contracts/protocols/dexes/camelot/v2/stubs/libraries/TransferHelper.sol#L6-L18).
- Every ERC20 helper decodes the return payload strictly as `bool`, so tokens that return other primitives (bytes32/int256) trip the `abi.decode` revert path even though the transfer succeeded, bubbling only the generic `TransferHelper::* failed` message and masking the real reason [contracts/protocols/dexes/camelot/v2/stubs/libraries/TransferHelper.sol#L10-L33](contracts/protocols/dexes/camelot/v2/stubs/libraries/TransferHelper.sol#L10-L33).

## contracts/protocols/dexes/camelot/v2/stubs/libraries/UQ112x112.sol — Grade: B-
- `uqdiv` performs `x / y` without checking that `y > 0`, so any caller that forwards unsanitized reserves will panic with `division by zero` rather than receiving a descriptive revert (the upstream Uniswap helper guards against this scenario) [contracts/protocols/dexes/camelot/v2/stubs/libraries/UQ112x112.sol#L18-L21](contracts/protocols/dexes/camelot/v2/stubs/libraries/UQ112x112.sol#L18-L21).
- The library never documents the fixed-point scaling factor it expects (Q112), which makes it easy for integrators to pass plain integers and silently skew price math; add NatSpec describing the required scaling alongside the constants [contracts/protocols/dexes/camelot/v2/stubs/libraries/UQ112x112.sol#L6-L17](contracts/protocols/dexes/camelot/v2/stubs/libraries/UQ112x112.sol#L6-L17).

## contracts/protocols/dexes/camelot/v2/stubs/libraries/UniswapV2Library.sol — Grade: D
- The library only exposes `sortTokens`, `pairFor`, `getReserves`, `quote`, and `getAmountsOut`; it never implements `getAmountOut`, `getAmountIn`, or `getAmountsIn`, yet the router calls each of those helpers multiple times, so this module cannot even compile with `UniV2Router02` [contracts/protocols/dexes/camelot/v2/stubs/libraries/UniswapV2Library.sol#L5-L64](contracts/protocols/dexes/camelot/v2/stubs/libraries/UniswapV2Library.sol#L5-L64) + [contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol#L257-L467](contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol#L257-L467).
- `pairFor` punts to `ICamelotFactory.getPair()` instead of deriving the CREATE2 address from `token0`, `token1`, and the init code hash, so any periphery that expects Uniswap’s deterministic formula will derive the wrong address and silently fail unless it performs an extra storage read every hop [contracts/protocols/dexes/camelot/v2/stubs/libraries/UniswapV2Library.sol#L17-L33](contracts/protocols/dexes/camelot/v2/stubs/libraries/UniswapV2Library.sol#L17-L33).

## contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol — Grade: C
- `setUp()` memoizes the factory and router singletons (`if (address(...) == address(0)) { ... }`) so the very first inheriting test seeds mutable global state and every later test inherits mutated reserves, liquidity, and fee settings from previous runs [contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol#L21-L33](contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol#L21-L33).
- Both the factory and router are instantiated with `new`, bypassing the repo’s deterministic CREATE3 factory and leaving the Camelot suite with addresses/tests that no longer match the production deployment pipeline [contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol#L22-L33](contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol#L22-L33).

## contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol — Grade: C+
- `_initialize` simply writes the supplied factory into storage with no zero-address guard or “already initialized” check, so any facet that accidentally calls it twice can silently hijack every Uniswap V2 integration [contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol#L23-L31](contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol#L23-L31).
- `_uniswapV2Factory()` just returns the slot contents without asserting initialization, meaning downstream code happily operates on address(0) until a swap reverts deep inside the router [contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol#L31-L36](contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol#L31-L36).

## contracts/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.sol — Grade: C+
- Router awareness mirrors the factory problem: `_initialize` will overwrite the stored router pointer every time it is called, even with address(0), and never emits an event to help operators spot the change [contracts/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.sol#L23-L31](contracts/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.sol#L23-L31).
- `_uniswapV2Router()` returns whatever happens to be in the slot without checking it was set, so callers can unknowingly forward swaps to address(0) and only discover the bug when SafeERC20 reverts [contracts/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.sol#L31-L36](contracts/protocols/dexes/uniswap/v2/aware/UniswapV2RouterAwareRepo.sol#L31-L36).

## contracts/protocols/dexes/uniswap/v2/services/UniswapV2Service.sol — Grade: C-
- `_prepareSwap` approves the router using the raw ERC20 `approve` (not `SafeERC20`) and never clears the allowance afterward, so tokens that require zeroing allowances before re-approval (USDT, KIN, etc.) will brick after the first call and leave stale approvals on every subsequent swap [contracts/protocols/dexes/uniswap/v2/services/UniswapV2Service.sol#L296-L304](contracts/protocols/dexes/uniswap/v2/services/UniswapV2Service.sol#L296-L304).
- `_executeSwap` hard-codes `amountOutMin = 1` and `deadline = block.timestamp + 1`, effectively removing any slippage protection or latency tolerance; even healthy pools will revert whenever the transaction isn’t mined within a single second or will be sandwiched with zero price bounds [contracts/protocols/dexes/uniswap/v2/services/UniswapV2Service.sol#L305-L314](contracts/protocols/dexes/uniswap/v2/services/UniswapV2Service.sol#L305-L314).
- The public swap helpers reuse the same `block.timestamp + 1` deadlines, so every caller inherits impossible-to-meet timeouts on mainnet/L2 and gets no way to configure a safer buffer [contracts/protocols/dexes/uniswap/v2/services/UniswapV2Service.sol#L195-L233](contracts/protocols/dexes/uniswap/v2/services/UniswapV2Service.sol#L195-L233).

## contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol — Grade: B-
- `createPair` salts `create2` with `abi.encodePacked(token0, token1)._hash()` but never exposes the resulting `INIT_CODE_PAIR_HASH`, so any periphery that relies on the canonical Uniswap V2 address derivation formula cannot reconstruct pair addresses and must fall back to storage lookups [contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol#L29-L44](contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol#L29-L44).
- The constructor accepts `feeToSetter = address(0)`, which permanently locks both `setFeeTo` and `setFeeToSetter` (the require guard can never pass) and yields a factory that cannot rotate fee recipients [contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol#L13-L20](contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol#L13-L20).

## contracts/protocols/dexes/uniswap/v2/stubs/UniV2Pair.sol — Grade: D+
- The `_PERMIT_TYPEHASH` constant is commented out even though `PERMIT_TYPEHASH()` and `permit()` both reference it, so the contract does not compile as written [contracts/protocols/dexes/uniswap/v2/stubs/UniV2Pair.sol#L33-L96](contracts/protocols/dexes/uniswap/v2/stubs/UniV2Pair.sol#L33-L96).
- `permit` increments `_nonces[owner]++` before verifying the signature, which means any failed signature attempt irreversibly burns the nonce and bricks all future permits for that signer [contracts/protocols/dexes/uniswap/v2/stubs/UniV2Pair.sol#L150-L166](contracts/protocols/dexes/uniswap/v2/stubs/UniV2Pair.sol#L150-L166).

## contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol — Grade: D
- The router calls `UniswapV2Library.getAmountsIn`, `getAmountsOut`, `getAmountOut`, and `getAmountIn` across both the standard and fee-on-transfer swap paths, but the current library only implements `getAmountsOut`, leaving the router impossible to compile or link [contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol#L235-L474](contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol#L235-L474) + [contracts/protocols/dexes/camelot/v2/stubs/libraries/UniswapV2Library.sol#L5-L64](contracts/protocols/dexes/camelot/v2/stubs/libraries/UniswapV2Library.sol#L5-L64).
- `_swapSupportingFeeOnTransferTokens` also relies on the missing `getAmountOut`, so even the fee-on-transfer fallbacks are dead code until those math helpers are implemented [contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol#L341-L376](contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol#L341-L376).

## contracts/test/comparators/Bytes4SetComparator.sol — Grade: C
- Temporary and actual selector sets are keyed solely by `ah = abi.encode(actual)._hash()` and never cleared, so two different subjects that expose the same selector array collide and the later call trips the duplicate/mismatch branches even though its expectations are correct [contracts/test/comparators/Bytes4SetComparator.sol#L102-L139](contracts/test/comparators/Bytes4SetComparator.sol#L102-L139).
- The post-processing loops walk both the expected and actual sets to count missing selectors, which yields precise diagnostics when a facet forgets to expose or unregisters a selector [contracts/test/comparators/Bytes4SetComparator.sol#L124-L141](contracts/test/comparators/Bytes4SetComparator.sol#L124-L141).

## contracts/test/comparators/ComparatorLogger.sol — Grade: B-
- `_logCompareError` only emits console output and never changes a return value or reverts, so behavior tests have no programmatic way to detect comparison failures without grepping logs [contracts/test/comparators/ComparatorLogger.sol#L16-L36](contracts/test/comparators/ComparatorLogger.sol#L16-L36).
- Normalizing bools to the strings "true"/"false" keeps log output consistent across Foundry traces and makes it easier to diff expected vs actual values when debugging [contracts/test/comparators/ComparatorLogger.sol#L31-L36](contracts/test/comparators/ComparatorLogger.sol#L31-L36).

## contracts/test/comparators/ERC2535/FacetsComparator.sol — Grade: C
- The comparator assumes `expected[i]` and `actual[i]` refer to the same facet; if `IDiamondLoupe.facets()` returns the same set in a different order, the expected selectors are recorded under the wrong facet address and immediately mis-compare despite the sets matching [contracts/test/comparators/ERC2535/FacetsComparator.sol#L94-L133](contracts/test/comparators/ERC2535/FacetsComparator.sol#L94-L133).
- After selector checks it still compares the facet address set as a whole, so at least the overall facet roster is validated independent of selector ordering [contracts/test/comparators/ERC2535/FacetsComparator.sol#L142-L189](contracts/test/comparators/ERC2535/FacetsComparator.sol#L142-L189).

## contracts/test/comparators/SetComparatorLogger.sol — Grade: B
- `ExpectedActualSizeMismatch` is declared but never used; callers always rely on console output when set lengths differ, so tests cannot assert on the mismatch programmatically [contracts/test/comparators/SetComparatorLogger.sol#L18-L46](contracts/test/comparators/SetComparatorLogger.sol#L18-L46).
- Helper methods emit the exact delta between actual/expected lengths and count of misses, making it easy to see whether a failure came from duplicates, missing declarations, or unexpected entries [contracts/test/comparators/SetComparatorLogger.sol#L48-L125](contracts/test/comparators/SetComparatorLogger.sol#L48-L125).

## contracts/test/comparators/StringComparator.sol — Grade: B-
- The repo stores both expected and actual strings keyed by `subject`/`func`, but nothing ever consumes the recorded `actualValues`, so the assignments at [contracts/test/comparators/StringComparator.sol#L37-L43](contracts/test/comparators/StringComparator.sol#L37-L43) just burn gas without improving diagnostics.
- Comparisons hash both inputs with `keccak256(abi.encodePacked(...))`, ensuring mismatches are detected even when the two strings differ in length or UTF-8 encoding [contracts/test/comparators/StringComparator.sol#L46-L58](contracts/test/comparators/StringComparator.sol#L46-L58).

## contracts/test/stubs/BetterSafeERC20Harness.sol — Grade: A-
- The harness exposes every wrapper in `BetterSafeERC20`, so tests can drive `safeTransfer`, `trySafeTransfer`, allowance helpers, and `forceApprove` without writing their own proxy logic [contracts/test/stubs/BetterSafeERC20Harness.sol#L21-L51](contracts/test/stubs/BetterSafeERC20Harness.sol#L21-L51).
- `safeName`, `safeSymbol`, `safeDecimals`, and `cast` are also surfaced, letting simulations assert that the metadata fallbacks behave correctly for tokens that omit the optional ERC20 views [contracts/test/stubs/BetterSafeERC20Harness.sol#L57-L75](contracts/test/stubs/BetterSafeERC20Harness.sol#L57-L75).

## contracts/test/stubs/MockERC20Variants.sol — Grade: B
- The file covers the most troublesome ERC20 behaviors—non-returning transfers, false-returning transfers, always-reverting tokens, no-metadata tokens, and USDT-style approval constraints—so SafeERC20 wrappers can exercise every edge case [contracts/test/stubs/MockERC20Variants.sol#L65-L330](contracts/test/stubs/MockERC20Variants.sol#L65-L330).
- Consider adding at least one permit-capable mock so the same fixture set can be reused to regression-test Permit flows; today only basic transfer/allowance paths are represented [contracts/test/stubs/MockERC20Variants.sol#L14-L330](contracts/test/stubs/MockERC20Variants.sol#L14-L330).

## contracts/test/stubs/MockFacet.sol — Grade: B-
- `facetInterfaces()` always returns an empty array, so these mocks cannot be used to test ERC165 metadata propagation or interface registration even though they expose deterministic selectors [contracts/test/stubs/MockFacet.sol#L16-L118](contracts/test/stubs/MockFacet.sol#L16-L118).
- Providing V1/V2/C variants plus `MockInitTarget` makes it easy to exercise add/replace/remove flows and init-call regressions when validating DiamondCut implementations [contracts/test/stubs/MockFacet.sol#L11-L137](contracts/test/stubs/MockFacet.sol#L11-L137).

## contracts/test/stubs/counter/Counter.sol — Grade: C+
- The stub uses a standalone pragma (`^0.8.13`) and no shared base class, so compiling it alongside the rest of the repo forces an extra compiler target just to provide a two-function counter [contracts/test/stubs/counter/Counter.sol#L1-L13](contracts/test/stubs/counter/Counter.sol#L1-L13).
- That said, the minimal `setNumber`/`increment` surface is perfect for fuzz handlers that need a predictable storage slot to mutate when validating comparators or behavior libraries [contracts/test/stubs/counter/Counter.sol#L4-L13](contracts/test/stubs/counter/Counter.sol#L4-L13).

## contracts/test/stubs/greeter/GreeterFacet.sol — Grade: B
- Metadata helpers correctly expose the `IGreeter` interface id plus both selectors, so facet-discovery tooling can enumerate this facet without special casing [contracts/test/stubs/greeter/GreeterFacet.sol#L9-L33](contracts/test/stubs/greeter/GreeterFacet.sol#L9-L33).
- There is no guard ensuring `GreeterTarget` has been initialized before exposing `getMessage`, so a miswired package just returns the default empty string without any diagnostic; documenting or enforcing that precondition would make the facet safer to reuse [contracts/test/stubs/greeter/GreeterFacet.sol#L8-L33](contracts/test/stubs/greeter/GreeterFacet.sol#L8-L33).

## contracts/tokens/ERC20/ERC20Facet.sol — Grade: C+
- `facetInterfaces()` still advertises the XOR of `IERC20Metadata` and `IERC20` as a pseudo-interface, so ERC165 consumers can cache an ID that no contract actually implements [contracts/tokens/ERC20/ERC20Facet.sol#L29-L36](contracts/tokens/ERC20/ERC20Facet.sol#L29-L36).
- `facetFuncs()` hand-lists nine selectors without any relationship to the interface definition, so future ERC-20 extensions risk desynchronizing metadata and will only be caught post-deploy [contracts/tokens/ERC20/ERC20Facet.sol#L37-L60](contracts/tokens/ERC20/ERC20Facet.sol#L37-L60).
- `facetMetadata()` just reassembles those arrays, duplicating logic instead of reusing a shared helper, so every change requires touching three functions to stay in sync [contracts/tokens/ERC20/ERC20Facet.sol#L62-L70](contracts/tokens/ERC20/ERC20Facet.sol#L62-L70).

## contracts/tokens/ERC20/ERC20MetadataTarget.sol — Grade: B-
- File imports `IERC20Metadata` twice (OZ path and remapped path), hinting at stale scaffolding and risking inconsistent interface versions if one changes while the other doesn’t [contracts/tokens/ERC20/ERC20MetadataTarget.sol#L12-L18](contracts/tokens/ERC20/ERC20MetadataTarget.sol#L12-L18).
- `name()`, `symbol()`, and `decimals()` blindly read from `ERC20Repo` and return default values when the repo has not been initialized yet; production facets should either guard or document that initialization must precede any metadata reads [contracts/tokens/ERC20/ERC20MetadataTarget.sol#L25-L34](contracts/tokens/ERC20/ERC20MetadataTarget.sol#L25-L34).

## contracts/tokens/ERC20/ERC20MintBurnOperableTarget.sol — Grade: B-
- `mint()`/`burn()` are exposed to both the owner and every global operator with no per-function scoping, so granting operator status for some other purpose implicitly hands over full monetary policy control [contracts/tokens/ERC20/ERC20MintBurnOperableTarget.sol#L18-L25](contracts/tokens/ERC20/ERC20MintBurnOperableTarget.sol#L18-L25).
- The contract relies entirely on `ERC20Repo` for accounting but never inherits `ERC20PermitTarget`, so it cannot surface the repo’s permit/domain state; integrators expecting permit support must bolt on another facet.

## contracts/tokens/ERC20/ERC20MintBurnOwnableFacet.sol — Grade: B
- Facet simply inherits the operable target, so any package wiring this facet must ensure `MultiStepOwnableRepo` and `OperableRepo` are initialized elsewhere; otherwise `onlyOwnerOrOperator` will read zeroed state and allow nobody to mint/burn [contracts/tokens/ERC20/ERC20MintBurnOwnableFacet.sol#L9-L21](contracts/tokens/ERC20/ERC20MintBurnOwnableFacet.sol#L9-L21).
- `facetFuncs()` only advertises `mint` and `burn`, so operator-management helpers or other repo utilities can never be exposed through this facet even though the target inherits them—consider splitting privilege-management selectors into their own facet [contracts/tokens/ERC20/ERC20MintBurnOwnableFacet.sol#L23-L35](contracts/tokens/ERC20/ERC20MintBurnOwnableFacet.sol#L23-L35).

## contracts/tokens/ERC20/ERC20PermitDFPkg.sol — Grade: C
- `facetCuts_[1]` mistakenly reuses `ERC20_FACET.facetFuncs()` when wiring the ERC-5267 facet, meaning the domain separator selector set is never added to the diamond despite the facet being included [contracts/tokens/ERC20/ERC20PermitDFPkg.sol#L84-L115](contracts/tokens/ERC20/ERC20PermitDFPkg.sol#L84-L115).
- `PkgArgs` exposes an `optionalSalt` but neither `calcSalt` nor `processArgs` reads it, so callers cannot disambiguate two tokens that share identical metadata blobs [contracts/tokens/ERC20/ERC20PermitDFPkg.sol#L26-L46](contracts/tokens/ERC20/ERC20PermitDFPkg.sol#L26-L46) [contracts/tokens/ERC20/ERC20PermitDFPkg.sol#L120-L171](contracts/tokens/ERC20/ERC20PermitDFPkg.sol#L120-L171).
- `initAccount` reinitializes both `ERC20Repo` and `EIP712Repo` on every call, so a malicious upgrade or factory bug could rerun initialization to rename the token or remint total supply [contracts/tokens/ERC20/ERC20PermitDFPkg.sol#L183-L212](contracts/tokens/ERC20/ERC20PermitDFPkg.sol#L183-L212).

## contracts/tokens/ERC20/ERC20PermitFacet.sol — Grade: C+
- The XORed interface ID issue persists, so `facetInterfaces()` still publishes a meaningless selector that can never be satisfied by real contracts [contracts/tokens/ERC20/ERC20PermitFacet.sol#L26-L42](contracts/tokens/ERC20/ERC20PermitFacet.sol#L26-L42).
- The 13-element `facetFuncs()` array is maintained manually, mixing ERC-20, ERC-2612, and ERC-5267 selectors; without tests, any selector insertion/removal will quietly desync metadata [contracts/tokens/ERC20/ERC20PermitFacet.sol#L44-L74](contracts/tokens/ERC20/ERC20PermitFacet.sol#L44-L74).
- Because the facet inherits three targets but performs no initialization, every function reverts or returns zero until `ERC20Repo`/`EIP712Repo` are configured elsewhere—document that dependency alongside the metadata helpers.

## contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol — Grade: C-
- `facetCuts()` allocates an array of length two but writes to index `0` three times, so only the last assignment survives and neither the ERC-20 nor ERC-2612 facets are actually added to the diamond [contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol#L108-L145](contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol#L108-L145).
- `PkgArgs.optionalSalt` is never consulted by `calcSalt`, which just hashes the unprocessed arg blob, so deterministic deployments cannot be namespaced even though the struct promises that ability [contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol#L42-L57](contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol#L42-L57) [contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol#L149-L167](contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol#L149-L167).
- `initAccount` initializes ERC20/EIP712 repos and seeds MultiStepOwnable with a hard-coded one-day lock but never mints supply or guards against re-entry, so a second call can silently rename the token or change ownership [contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol#L179-L204](contracts/tokens/ERC20/ERC20PermitMintBurnLockedOwnableDFPkg.sol#L179-L204).

## contracts/tokens/ERC20/ERC20PermitMintableStub.sol — Grade: C
- `mint()` and `burn()` are public entrypoints with no ownership/operator guard, letting any caller arbitrarily change supply in this test harness; document that it is intentionally insecure before someone reuses it in production [contracts/tokens/ERC20/ERC20PermitMintableStub.sol#L12-L20](contracts/tokens/ERC20/ERC20PermitMintableStub.sol#L12-L20).
- Because it inherits `ERC20PermitStub`, all instances share the same `ERC20Repo` storage slot; deploying multiple stubs inside one diamond will overwrite each other’s metadata and balances unless the slot is remapped.

## contracts/tokens/ERC20/ERC20PermitStub.sol — Grade: B-
- Constructor writes directly into the shared `ERC20Repo` layout with no guard, so deploying two stubs within the same storage context (diamond/tests) will clobber prior metadata and balances [contracts/tokens/ERC20/ERC20PermitStub.sol#L28-L35](contracts/tokens/ERC20/ERC20PermitStub.sol#L28-L35).
- Initialization path mints the full `initialAmount` to `recipient` even if that address is zero; consider mirroring the production repo’s zero-address guard.

## contracts/tokens/ERC20/ERC20PermitTarget.sol — Grade: B-
- Acts purely as a reminder shim combining ERC-20, ERC-2612, and ERC-5267 targets, but because it inherits three storage-heavy parents it pulls all associated state into any facet that uses it—document the storage layout requirements so other facets don’t accidentally collide [contracts/tokens/ERC20/ERC20PermitTarget.sol#L5-L11](contracts/tokens/ERC20/ERC20PermitTarget.sol#L5-L11).
- No functions are added, so packages still need dedicated metadata facets/tests to ensure selector arrays stay in sync.

## contracts/tokens/ERC20/ERC20Repo.sol — Grade: C
- `_mint` and `_burn` bypass the `_increaseBalanceOf`/`_decreaseBalanceOf` helpers, so they never enforce the zero-address/insufficient-balance guards and happily mint to `address(0)` or burn from it until a Panic underflow stops execution [contracts/tokens/ERC20/ERC20Repo.sol#L142-L162](contracts/tokens/ERC20/ERC20Repo.sol#L142-L162).
- Because those code paths also skip the `IERC20Errors` flows, failures surface as generic arithmetic errors instead of the standardized `ERC20InvalidReceiver/Sender` diagnostics emitted everywhere else, which makes debugging and invariant tests much noisier.

## contracts/tokens/ERC20/ERC20Target.sol — Grade: D
- `transferFrom` forwards straight into `_transfer` instead of `_transferFrom`, so allowances are never checked or decremented and any spender can drain an approved balance forever after a single approval [contracts/tokens/ERC20/ERC20Target.sol#L37-L41](contracts/tokens/ERC20/ERC20Target.sol#L37-L41).
- The function still returns `true`, so downstream code sees a “successful” transfer even though the allowance book-keeping never changed, hiding the bug from integration tests unless they explicitly read allowances afterward.

## contracts/tokens/ERC20/TestBase_ERC20.sol — Grade: B-
- `invariant_totalSupply_equals_sumBalances` only adds balances for addresses recorded in the handler’s `_addrs` array, so any mint/burn that touches an address outside the fuzzed seed set goes unnoticed and the invariant happily matches an incomplete sum [contracts/tokens/ERC20/TestBase_ERC20.sol#L223-L235](contracts/tokens/ERC20/TestBase_ERC20.sol#L223-L235).
- `invariant_nonnegative` asserts `b >= 0` for unsigned integers, which is tautologically true and never fails; replace it with something meaningful (e.g., checking balances stay within total supply) or drop it [contracts/tokens/ERC20/TestBase_ERC20.sol#L237-L244](contracts/tokens/ERC20/TestBase_ERC20.sol#L237-L244).

## contracts/tokens/ERC20/TestBase_ERC20Permit.sol — Grade: B
- Extends the base ERC20 harness by wiring a dedicated permit handler so fuzzing can exercise valid, bad-signer, and expired signature paths without touching production code [contracts/tokens/ERC20/TestBase_ERC20Permit.sol#L7-L46](contracts/tokens/ERC20/TestBase_ERC20Permit.sol#L7-L46).
- The additional handler only registers selectors but doesn’t add invariants unless tests inherit `TestBase_ERC20Permit_Invariants`, so permit allowances are never cross-checked by default—remember to opt into that helper if you actually want enforcement [contracts/tokens/ERC20/TestBase_ERC20Permit.sol#L115-L164](contracts/tokens/ERC20/TestBase_ERC20Permit.sol#L115-L164).

## contracts/tokens/ERC20/utils/BetterSafeERC20.sol — Grade: C+
- `callOptionalReturn` assumes any token that returns data must return the literal boolean `1`; tokens that return other success values (e.g., some wrappers that echo the amount transferred) will now revert even though the operation succeeded [contracts/tokens/ERC20/utils/BetterSafeERC20.sol#L108-L138](contracts/tokens/ERC20/utils/BetterSafeERC20.sol#L108-L138).
- The TODOs at the top acknowledge NatSpec/tests are missing, and without coverage the relaxed IERC1363 helpers (`transferAndCallRelaxed`, etc.) remain unverified despite touching arbitrary receiver code [contracts/tokens/ERC20/utils/BetterSafeERC20.sol#L31-L79](contracts/tokens/ERC20/utils/BetterSafeERC20.sol#L31-L79).

## contracts/tokens/ERC20TargetStub.sol — Grade: C
- Constructor mints balances but never calls `ERC20Repo._initialize`, so `name()`, `symbol()`, and `decimals()` all return zeroed defaults whenever the stub is used in tests [contracts/tokens/ERC20TargetStub.sol#L6-L10](contracts/tokens/ERC20TargetStub.sol#L6-L10).
- Because it inherits the full `ERC20Target`, any call to `transferFrom` inside test suites will still hit the real facet bug (allowances never decrease), which can mask production regressions.

## contracts/tokens/ERC2612/ERC2612Facet.sol — Grade: B-
- `facetInterfaces()` only advertises `IERC20Permit`, so tooling that expects ERC-5267 domain introspection or plain `IERC20` metadata from this facet can’t discover those selectors even though the underlying target pulls in `EIP712Repo` [contracts/tokens/ERC2612/ERC2612Facet.sol#L23-L43](contracts/tokens/ERC2612/ERC2612Facet.sol#L23-L43).
- The selector list is hand-maintained; add a Foundry test asserting `facetFuncs()` stays aligned with `IERC20Permit` so future spec bumps don’t silently desync the metadata [contracts/tokens/ERC2612/ERC2612Facet.sol#L45-L63](contracts/tokens/ERC2612/ERC2612Facet.sol#L45-L63).

## contracts/tokens/ERC2612/ERC2612Repo.sol — Grade: A-
- Clean storage wrapper that binds nonces to a single slot and exposes `_useCheckedNonce`, ensuring replay attempts revert with `IERC2612.InvalidAccountNonce` instead of silently consuming the wrong nonce [contracts/tokens/ERC2612/ERC2612Repo.sol#L19-L63](contracts/tokens/ERC2612/ERC2612Repo.sol#L19-L63).
- `_useNonce` increments inside an `unchecked` block but, because it returns the pre-increment value, it mirrors the OZ pattern and keeps gas low while still guaranteeing monotonic nonces.

## contracts/tokens/ERC2612/ERC2612Target.sol — Grade: B-
- `permit` routes through `EIP712Repo._hashTypedDataV4` but the contract never initializes the domain itself, so any package that forgets to call `EIP712Repo._initialize(name, version)` will have every signature fail with an all-zero domain separator [contracts/tokens/ERC2612/ERC2612Target.sol#L55-L88](contracts/tokens/ERC2612/ERC2612Target.sol#L55-L88).
- The function relies on `ERC20Repo._approve`, which rejects `address(0)` spenders; if you intend to let users clear allowances via permits, document that they must choose a non-zero recipient.

## contracts/tokens/ERC4626/ERC4626Facet.sol — Grade: C+
- `facetFuncs()` manually lists all 16 ERC-4626 selectors with no accompanying tests, so any spec change (e.g., adding `convertToIdleShares`) would quietly desync metadata and confuse loupe tooling [contracts/tokens/ERC4626/ERC4626Facet.sol#L26-L65](contracts/tokens/ERC4626/ERC4626Facet.sol#L26-L65).
- The facet doesn’t advertise the underlying ERC20 interface even though `ERC4626Target` usually inherits ERC20, so a package that only cuts this facet will lack `transfer`/`balanceOf` selectors unless it remembers to include a separate ERC20 facet.

## contracts/tokens/ERC4626/ERC4626PermitDFPkg.sol — Grade: C
- `facetCuts_[1]` mistakenly reuses the ERC20 selector list when wiring the ERC-5267 facet, so domain separator selectors are never added despite shipping that facet [contracts/tokens/ERC4626/ERC4626PermitDFPkg.sol#L104-L140](contracts/tokens/ERC4626/ERC4626PermitDFPkg.sol#L104-L140).
- `calcSalt`/`processArgs` clamp `optionalDecimalOffset` to 10 but ignore the provided `optionalSalt`, so two vaults with identical assets and parameters will always collide on the same deterministic address [contracts/tokens/ERC4626/ERC4626PermitDFPkg.sol#L147-L175](contracts/tokens/ERC4626/ERC4626PermitDFPkg.sol#L147-L175).
- The transient-slot initial deposit flow trusts `BetterMath._convertToSharesDown` with zero `lastTotalAssets`, which mints zero shares whenever the vault is empty; the intended bootstrap recipient never receives shares and the deposit remains trapped [contracts/tokens/ERC4626/ERC4626PermitDFPkg.sol#L178-L233](contracts/tokens/ERC4626/ERC4626PermitDFPkg.sol#L178-L233).

## contracts/tokens/ERC4626/ERC4626Repo.sol — Grade: B-
- `_initialize` happily overwrites the reserve asset pointer and decimals without zero-address or once-only guards, so a misbehaving facet can silently repoint the vault after launch [contracts/tokens/ERC4626/ERC4626Repo.sol#L23-L57](contracts/tokens/ERC4626/ERC4626Repo.sol#L23-L57).
- `lastTotalAssets` is just a cached uint with no invariant tying it to `reserveAsset.balanceOf`, so any manual mint/burn of reserve tokens leaves the vault accounting permanently skewed until a deposit/withdraw updates the cache [contracts/tokens/ERC4626/ERC4626Repo.sol#L12-L74](contracts/tokens/ERC4626/ERC4626Repo.sol#L12-L74).

## contracts/tokens/ERC4626/ERC4626Service.sol — Grade: C
- `_secureReserveDeposit` computes `actualIn = currentBalance - lastTotalAssets` before verifying `currentBalance >= lastTotalAssets`, so if attackers flash-transfer tokens out of the vault it will underflow and revert with a generic panic instead of a descriptive error [contracts/tokens/ERC4626/ERC4626Service.sol#L15-L52](contracts/tokens/ERC4626/ERC4626Service.sol#L15-L52).
- Permit2 fallback uses `uint160(amountTokenToDeposit)` when calling `transferFrom`, so any deposit larger than 2^160-1 silently truncates and mints shares for fewer assets than expected [contracts/tokens/ERC4626/ERC4626Service.sol#L26-L33](contracts/tokens/ERC4626/ERC4626Service.sol#L26-L33).

## contracts/tokens/ERC4626/ERC4626Target.sol — Grade: C
- `withdraw` and `redeem` rely on `ERC20Repo._burn` for share accounting, but `_burn` skips the zero-address guard so griefers can call `withdraw` with `owner = address(0)` and underflow the share supply before a Panic halts execution [contracts/tokens/ERC4626/ERC4626Target.sol#L51-L100](contracts/tokens/ERC4626/ERC4626Target.sol#L51-L100) plus [contracts/tokens/ERC20/ERC20Repo.sol#L153-L162](contracts/tokens/ERC20/ERC20Repo.sol#L153-L162).
- The maxDeposit/maxMint functions return `type(uint256).max` regardless of reserve capacity, so routers receive no guidance about actual limits; consider mirroring OZ’s `maxDeposit = type(uint256).max` only when deposits are unbounded.

## contracts/tokens/ERC4626/ERC4626TargetStub.sol — Grade: B-
- Constructor initializes ERC20/4626 repos but never seeds `EIP712Repo`, so permit-based tests targeting this stub will always read an all-zero domain separator unless they initialize it separately [contracts/tokens/ERC4626/ERC4626TargetStub.sol#L16-L26](contracts/tokens/ERC4626/ERC4626TargetStub.sol#L16-L26).
- `Permit2AwareRepo._initialize` runs with no guard against multiple calls, so deploying two stubs in the same diamond context can silently overwrite the shared Permit2 pointer.

## contracts/tokens/ERC4626/ERC4626TargetStubHandler.sol — Grade: B
- Handler deposits/mints by first transferring assets from itself to the actor, but it never replenishes its own balance after large withdrawals; once the local asset buffer dries up, all deposit/mint operations become no-ops even though the vault would accept them [contracts/tokens/ERC4626/ERC4626TargetStubHandler.sol#L33-L123](contracts/tokens/ERC4626/ERC4626TargetStubHandler.sol#L33-L123).
- Ghost tracking (`ghostTotalDeposited`/`ghostTotalWithdrawn`) is never asserted via invariants, so the extra bookkeeping does not currently detect any mismatches—consider adding invariant hooks comparing total shares/asset deltas.
