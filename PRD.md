---
project: Crane Framework
version: 1.0
created: 2026-01-12
last_updated: 2026-01-12
---

# Crane Framework - Product Requirements Document

## Vision

Crane is a Diamond-first (ERC2535) Solidity development framework for building modular, upgradeable smart contracts. It provides structured patterns, deterministic deployment infrastructure, and protocol integration utilities that enable DeFi developers to build complex, upgradeable systems with confidence.

## Problem Statement

DeFi protocol development faces several recurring challenges:

1. **Fragmented Diamond tooling** - Existing Diamond (ERC2535) implementations lack cohesive patterns for storage management, facet composition, and testing
2. **Deployment determinism** - Cross-chain deployments require predictable contract addresses, but existing solutions are ad-hoc
3. **Upgrade complexity** - Diamond upgrades are error-prone without structured patterns for selector management and initialization
4. **Protocol integration boilerplate** - DEX and protocol integrations require repeated scaffolding for each new project

Crane solves these by providing a cohesive framework with battle-tested patterns, CREATE3 deterministic deployment, and reusable protocol integrations.

## Target Users

| User Type | Description | Primary Needs |
|-----------|-------------|---------------|
| DeFi Protocol Developers | Teams building vaults, DEX integrations, yield strategies | Reliable patterns, minimal boilerplate, cross-chain deployment |

## Goals

### Primary Goals

1. Provide a cohesive Diamond (ERC2535) development framework with clear patterns
2. Enable deterministic cross-chain deployment via CREATE3
3. Reduce protocol integration boilerplate with reusable DEX utilities
4. Support rigorous testing through structured TestBase and Behavior patterns
5. Enable reuse by consuming projects and AI agents building modular, upgradeable contracts

### Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Framework Adoption | Growing ecosystem | Multiple external projects and agents successfully building on Crane |
| Test Coverage | High coverage | All public APIs have unit tests, critical paths have fuzz tests |
| Developer Experience | Fast iteration | Clear patterns documented, minimal boilerplate required |
| Cross-Chain Determinism | Consistent addresses | Same deployment produces same addresses across all EVM chains |

## Non-Goals (Out of Scope)

- **End-user applications** - Crane is infrastructure, not end-user facing. UI, APIs, and user-facing features belong in consuming projects
- **Non-EVM chains** - Crane focuses exclusively on EVM-compatible chains. Solana, Cosmos, etc. are out of scope
- **Application-specific business logic** - Specific vault strategies, yield logic, or end-application features belong in consuming projects, not Crane

## Key Features

### Feature 1: Facet-Target-Repo Pattern

A three-tier architecture for Diamond facet development:

| Layer | Purpose |
|-------|---------|
| **Repo** | Storage library with assembly-based slot binding. Defines `Storage` struct and dual `_layout()` functions |
| **Target** | Implementation contract with business logic. Uses Repo for storage access |
| **Facet** | Diamond facet. Extends Target and implements `IFacet` for metadata |

### Feature 2: Diamond Package System (DFPkg)

Bundles related facets into deployable packages with standardized interfaces:

- `IDiamondFactoryPackage` interface for consistent deployment
- Constructor args (PkgInit) and deployment args (PkgArgs) separation
- Automatic facet cut generation and initialization

### Feature 3: CREATE3 Deterministic Deployment

Cross-chain deployment infrastructure ensuring identical addresses:

- `Create3Factory` for any contract deployment
- `DiamondPackageCallBackFactory` for Diamond proxy deployment
- Salt derivation from type names for reproducibility
- Facet and package registry for deployment tracking

### Feature 4: Protocol Integrations

Reusable utilities for major DeFi protocols:

| Protocol | Version | Components |
|----------|---------|------------|
| Uniswap | V2, V3, V4 | Router wrappers, quote utilities |
| Camelot | V2 | Router integration, fee handling |
| Aerodrome | V1 (Slipstream) | Concentrated liquidity support |
| Balancer | V3 | Vault integration, batch swaps |

### Feature 5: Testing Framework

Structured testing patterns for Diamond development:

- **TestBase** contracts for protocol setup and behavior validation
- **Behavior** libraries for interface compliance checking
- **Handler** pattern for invariant/fuzz testing
- Fork testing support for mainnet protocol integrations

## Technical Requirements

### Architecture

```
contracts/
├── access/           # Access control (operable/, reentrancy/, ERC8023/)
├── factories/        # Diamond and Create3 factories
├── interfaces/       # All contract interfaces
├── introspection/    # ERC165, ERC2535 (Diamond), ERC8109
├── protocols/dexes/  # Protocol integrations
├── test/             # Test utilities, stubs, comparators
├── tokens/           # Token implementations
└── utils/            # Math, collections, cryptography utilities
```

### Integrations

| System | Purpose | Type |
|--------|---------|------|
| Uniswap V2/V3/V4 | DEX quotes and swaps | Read/Write |
| Camelot V2 | DEX quotes and swaps | Read/Write |
| Aerodrome/Slipstream | Concentrated liquidity DEX | Read/Write |
| Balancer V3 | Pool operations, batch swaps | Read/Write |

### Chains & Networks

| Network | Purpose | Priority |
|---------|---------|----------|
| All EVM-compatible | Chain-agnostic framework | P0 |
| Ethereum Mainnet | Primary testing and integration | P0 |
| Arbitrum | L2 deployment target | P1 |
| Base | L2 deployment target | P1 |
| Optimism | L2 deployment target | P1 |

### Security Requirements

- **Reentrancy guards** - Prevent reentrancy attacks in all state-modifying functions
- **Access control** - Operator-based permissions via OperableRepo pattern
- **Safe math** - Overflow/underflow protection (Solidity 0.8+)
- **Slippage protection** - Quote validation for all swap operations
- **Audit-ready patterns** - Well-documented, testable patterns that simplify security audits

### Constraints

- **Solidity 0.8.30** - Minimum compiler version
- **No viaIR** - IR compilation is forbidden; use struct refactoring for stack-too-deep
- **EVM Prague** - Target EVM version
- **Optimizer runs: 1** - Optimized for contract size limits

## Development Approach

### Repository Structure

```
crane/
├── contracts/           # All Solidity source code
│   ├── access/          # Access control patterns
│   ├── factories/       # Deployment factories
│   ├── protocols/dexes/ # Protocol integrations
│   └── ...
├── test/foundry/spec/   # Test specifications
├── docs/                # Architecture documentation
└── tasks/               # Task management
```

### Layers

| Layer | Location | Purpose |
|-------|----------|---------|
| Core | contracts/access/, contracts/introspection/ | Fundamental Diamond patterns |
| Factories | contracts/factories/ | Deployment infrastructure |
| Protocols | contracts/protocols/dexes/ | Protocol integrations |
| Utils | contracts/utils/ | Math, collections, crypto utilities |
| Test | contracts/test/, test/foundry/ | Testing infrastructure |

### Key Dependencies

| Dependency | Purpose |
|------------|---------|
| Foundry | Build, test, and deployment tooling |
| Solady | Gas-optimized Solidity utilities |
| OpenZeppelin | Standard contract implementations |
| forge-std | Foundry testing utilities |

### Testing Requirements

- **Foundry unit tests** - All public APIs must have unit test coverage
- **Invariant/fuzz testing** - Critical math and state transitions must have property-based tests
- **Fork testing** - Protocol integrations must be tested against mainnet forks
- **Behavior-based testing** - Use TestBase + Behavior library pattern for interface compliance

### Documentation Standards

- **NatSpec + AsciiDoc tags** - All public functions must have NatSpec; include-tags for doc extraction
- **Custom NatSpec tags** - `@custom:signature`, `@custom:selector`, `@custom:interfaceid`
- **Inline code comments** - Self-documenting code with explanatory comments where logic is non-obvious
- **Architecture docs** - High-level documentation in docs/ directory

## Milestones

| Milestone | Description | Status |
|-----------|-------------|--------|
| M1: Review & Stabilization | Review existing code, add tests, document patterns | In Progress |
| M2: Consumer Validation | Validate Crane patterns through real external consumer projects and agent usage | Pending |
| M3: Documentation Complete | Full NatSpec coverage, architecture docs | Pending |
| M4: Production Ready | Audit-ready, comprehensive test coverage | Pending |

## Current Focus: Professional Launch Standards (Bankr Token Funding Preparation)

**Objective**: Bring the Crane repository to a level of professional quality suitable for launching a funding token via Bankrbot. The token will help sustain development of Crane as a reusable framework that other AI agents can confidently use to develop and deploy secure, modular, upgradeable Solidity contracts with reduced deployment costs through reusable Facets and Diamond Factory Packages (DFPkgs).

This phase prioritizes:
- Complete, accurate, and verifiable NatSpec documentation (all .sol files including tests, with Foundry Script verification)
- ERC1967-compliant storage slot derivation for all Repos
- GitBook-formatted documentation with specific required content on factories, registries, protocols, utilities, and agent usage for chain setup
- Up-to-date skills (in-repo and global) aligned to current standards
- Accurate documentation of the security and cost benefits derived from code reuse
- Clear guidance enabling other agents to deploy their own factories and reuse the shared Diamond Package Factory and Registries

Detailed Bankrbot runbook work is explicitly deferred until after refactoring.

**Process (strict order)**:
1. Iteratively define and agree requirements in this PRD.
2. Perform systematic codebase review against the requirements.
3. Produce a detailed gap report.
4. Produce a detailed implementation plan.
5. Only after explicit agreement on the plan: implement changes (no premature code edits).

### Launch Readiness Requirements

#### LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)

Crane adopts the documentation style demonstrated in the ERC8023 Multi-Step Ownable implementation as the **canonical reference** for full NatSpec + AsciiDoc include-tags:

**Canonical Reference Files** (these represent the required quality and format):
- `contracts/access/ERC8023/IMultiStepOwnable.sol`
- `contracts/access/ERC8023/MultiStepOwnableTarget.sol`
- `contracts/access/ERC8023/MultiStepOwnableRepo.sol`
- `contracts/access/ERC8023/MultiStepOwnableFacet.sol`

**Required Elements for Every Documented Symbol**:
- Every public/external symbol in interfaces, and corresponding implementations, must be wrapped with exact `// tag::SymbolName(params)[]` ... `// end::SymbolName(params)[]` include tags (no extra spaces).
- Interfaces must declare `@custom:interfaceid` (computed bytes4).
- Events must declare `@custom:topiczero` (full bytes32 keccak topic hash) and preferably `@custom:topic-signature`.
- Errors and functions must declare:
  - `@custom:selector` (exact bytes4)
  - `@custom:signature` (canonical string form)
- Functions must include rich NatSpec: `@notice`, `@param`, `@return`, `@custom:emits`, `@custom:throws` where applicable.
- Repos must document both the parameterized (`Storage storage layoutStruct`) and default overload versions.
- Targets and Facets should use `@inheritdoc` where they delegate, plus their own tags for clarity.
- Facets must fully implement `IFacet` with documented `facetName()`, `facetInterfaces()`, `facetFuncs()`, `facetMetadata()`.

**Critical Accuracy Rule**:
All `@custom:selector`, `@custom:topiczero`, and `@custom:interfaceid` values **MUST** be authoritatively computed using a Forge Script or Foundry Test (not ad-hoc terminal `cast` commands or manual calculation). This ensures values are verifiable, reproducible in CI, and eliminates hallucination risk. Verification scripts/tests must be part of the repository and runnable as part of the release process.

**Scope**:
- **All Solidity code**, including production contracts, libraries, interfaces, DFPkgs, and **all test files** (e.g. `*.t.sol`, TestBase_*.sol, Behavior_*.sol, handlers, stubs, etc.).

**Verification Script Requirement (Mandatory)**:
The custom NatSpec tag values (interface IDs, function selectors, and event topic0 where applicable) **MUST** be calculated using a dedicated **Foundry Script** (not one-off terminal `cast` commands or manual math). 

- The script must output compiler-computed values for interface IDs (using `type(I).interfaceId` where possible) and function selectors.
- For events (topic0 hashes), the script should calculate or derive the values if direct compiler output for the event signature is not available in the script context.
- This script is intended for one-time / iterative use by developers/agents to generate the exact values to paste into `@custom:*` tags.
- The script (and instructions for running it) must be committed to the repository so values can be regenerated or audited at any time.

Existing `docs/development/natspec.md` and the `crane-natspec` skill must be updated to reflect the full scope (incl. tests) and the required Foundry Script verification approach.

#### LR-2: GitBook-Formatted Documentation

- Maintain and expand `docs/SUMMARY.md` as the primary navigation for GitBook publishing.
- All major sections must have clear, up-to-date Markdown with proper headings, code examples, and cross-links.
- Documentation must enable other agents/developers to use Crane effectively.

**Required GitBook Content Areas (at minimum)**:
- How to set up a chain presence: using the CREATE3 Package (Create3FactoryDFPkg / related) to deploy your own Create3Factory for a new chain.
- Explicit statement that the Diamond Package Factory (DiamondPackageCallBackFactory) does **not** need to be redeployed per chain — it is safe and intended for public reuse across deployments.
- Detailed explanation of the included Registries (Facet Registry, Package Registry, CallTarget Registry, etc.), their purpose, how they are populated, and how consumers interact with them.
- Detailed explanations of all ported protocols, including:
  - How to integrate and use them.
  - How to use them inside tests (TestBases, stubs, etc.).
- Detailed coverage of all protocol-specific utility libraries.
- Detailed coverage of all general utility and type libraries, including (but not limited to):
  - Type-specific Set implementations (AddressSet, Bytes32Set, etc.) and their Repo patterns.
  - Math utilities (e.g. ConstProdUtils).
  - Other collections, cryptography, and helper libraries.

Agent-focused "Getting Started", "Building with Crane", and architecture sections must tie everything back to reusability benefits.

#### LR-3: Up-to-Date Agent Skills

- The relevant Crane and protocol skills must be installed and available both inside this repository (`.claude/skills/`) **and** in the user's global Claude/agent environment.
- `.claude/skills/` must be clean (no leftover "copy" directories or drift artifacts).
- All skills (core framework + every ported DeFi protocol) must be kept in sync with the current code standards, patterns (especially Facet-Target-Repo, DFPkg, NatSpec rules, ERC1967 slots), and documentation.
- When standards evolve (e.g. new NatSpec verification process, ERC1967 slot format), skills must be updated accordingly.
- Skills should enable agents to correctly use CREATE3 factories, registries, ported protocols in tests, utility libraries, etc.

#### LR-4: Framework Value Proposition for Other Agents (Security & Cost Claims)

Documentation, skills, and examples must clearly and accurately communicate the following **specific rationale**:

**Security benefit**:
The primary security advantage is the ability to **reuse already deployed and verified code**. When code is known to be good, reusing it (via facets attached through DFPkgs) eliminates the risk of introducing new bugs through inadvertent changes. This risk is especially high when development or deployment work is delegated to an AI agent. Reusing battle-tested, already-audited deployed logic removes that class of error.

**Reduced deployment cost benefit**:
Because you can reuse already deployed facets and packages, you do not need to deploy that code yourself on every project or chain instance. This directly saves gas by simply not needing to deploy as much bytecode.

All claims in README, docs, and skills must be grounded in this reuse-based reasoning rather than generic statements. Examples should highlight "deploy once, attach everywhere" and "agent-proof reuse".

#### LR-5: Bankrbot Token Launch Preparation

Once the above quality bars are met:
- Detailed runbook for launching the funding token using Bankrbot CLI.
- Process for funding a dedicated Bankr Agent wallet, paying the Bankr Club subscription, and executing `bankr launch` with appropriate fee recipient configuration.
- Token economics and fee routing must direct proceeds toward Crane development (and the on-chain bounty board).

**Important Constraint**: Detailed research, spiking, and final decisions for the Bankrbot runbook content and execution process will be deferred until **after** the repository refactoring and standards alignment work is complete.

See `BANKR_LAUNCH.md` (to be maintained as the executable playbook once the post-refactor spike is done).

#### LR-6: ERC1967-Compliant Storage Slot Derivation (DEFAULT_SLOT / STORAGE_SLOT)

All storage slot constants in Repos (and any other storage libraries) **MUST** conform to the ERC1967 derivation pattern:

```solidity
bytes32 internal constant DEFAULT_SLOT = bytes32(uint256(keccak256(abi.encode("your.hierarchical.slot.name"))) - 1);
```

**Rationale**: This matches the established EIP-1967 standard practice for deterministic storage slot calculation (see https://eips.ethereum.org/EIPS/eip-1967). Using the `- 1` offset after the keccak provides a standard, collision-resistant approach that is already used in parts of the codebase (e.g. `FacetRegistryRepo`).

**Current State Note (to be validated in review)**: Many existing Repos use the direct form `keccak256(abi.encode(...))` without the `- 1`. These must be updated for consistency, along with all `_layoutStruct()` calls and any hardcoded slot assumptions.

This applies to every `STORAGE_SLOT`, `DEFAULT_SLOT`, or equivalent constant used for assembly-based storage binding across the entire codebase (including tests if they define such slots).

The canonical example is:
- `contracts/registries/facet/FacetRegistryRepo.sol`

All new or refactored Repos must use this form. A migration of existing slots will be required (with care for upgrade safety where relevant).

#### LR-7: Testing Standards

All tests in the repository (unit, integration, invariant, fork, and behavior tests) must meet high standards of correctness and completeness. The following are mandatory (this list is not exhaustive):

- **Full and Correct Initialization**: Every test must fully initialize the component under test before making assertions. 
  - Deploying a Package with any Facet address set to `address(0)` is invalid.
  - The subject of the test must be in a properly initialized, production-like state. Tests that bypass initialization cannot claim to validate real behavior.

- **Exact Expected Value Assertions**: Tests must assert precise expected values, not just that a side effect occurred.
  - Example failure: Checking only that a balance changed after a transfer.
  - Correct: Asserting that the balance changed by exactly the expected amount (using the precise delta).

- **Preview Function Exact Match (Vaults and Similar)**: For any operation that exposes preview functions (e.g. `previewDeposit`, `previewMint`, `previewWithdraw`, `previewRedeem`), tests must verify that the value returned by the preview function exactly matches the actual result when the previewed action is executed.

- **Facet Declaration Tests**: Every deployed Facet must be tested to correctly declare its interfaces and functions via `facetInterfaces()` and `facetFuncs()`. These must match the expected values for that Facet.

- **Package Declaration Tests**: Packages must be tested for correct declaration of:
  - `facetAddresses()`
  - `facetCuts()`
  - `diamondConfig()`
  - `packageName()`
  - `calcSalt(...)`
  - `processArgs(...)`
  - and any other package metadata or behavior.

- **Mandatory Use of Behavior Libraries**: Standard interfaces and patterns (especially `IFacet`, `IDiamondFactoryPackage`, and protocol behaviors) must be validated using the appropriate `Behavior_*` libraries (e.g. `Behavior_IFacet`, `Behavior_IPackage`) rather than duplicating or bypassing the shared behavior validation logic.

Additional testing expectations (not exhaustive) include:

1. **Behavior libraries must be used for standards**  
   Every Facet must be validated using `Behavior_IFacet` (or equivalent). Every DFPkg must be validated using `Behavior_IDiamondFactoryPackage`. Protocol standards must use their dedicated Behavior libraries. Hand-written assertions for these are insufficient.

2. **Exact event emission + precise state deltas**  
   Every state-changing operation must use `vm.expectEmit` for events and must assert the exact resulting state change (e.g., balance delta must match the expected amount exactly).

3. **CREATE3 / salt determinism verification**  
   Tests using `Create3Factory`, DFPkgs, or package deployment must assert that identical inputs always produce identical addresses and that different inputs produce different addresses.

4. **Registry population must be asserted**  
   After any factory or package-based deployment, tests must verify that FacetRegistry, PackageRegistry, CallTargetRegistry, and similar registries contain the expected entries and data.

5. **Storage isolation and multi-instance safety**  
   Tests creating multiple instances (different proxies, custom slots, etc.) must explicitly prove that storage does not leak or interfere between instances.

6. **Full DFPkg lifecycle coverage**  
   DFPkgs must be tested end-to-end: `calcSalt` consistency, `processArgs`, `initAccount` (via the real delegatecall mechanism), and `postDeploy`.

7. **Error selectors and custom errors**  
   All custom errors must be tested using both `vm.expectRevert(CustomError.selector)` and the typed error form. The tested selector must match the one declared in NatSpec.

8. **Preview parity must be exhaustive**  
   Every preview function (previewDeposit, previewMint, etc.) must be asserted for exact equality against the result of actually executing the previewed operation, including edge cases and revert paths.

9. **Correct TestBase / CraneTest usage**  
   Tests must properly inherit from `CraneTest` or the relevant `TestBase_*` chains, call parent `setUp()` methods in the correct order, and must not bypass or duplicate initialization logic.

10. **NatSpec on test code**  
    Test contracts, complex helpers, handlers, and TestBases that expose public APIs must follow the same NatSpec + include-tag standards as production code (see LR-1).

11. **Reentrancy and access-control matrix testing**  
    Contracts using `ReentrancyLockRepo` or `OperableRepo` must have dedicated tests proving the reentrancy lock functions and that all operator/owner/pending-owner permission paths are correctly enforced.

12. **Fork-test parity for protocol ports**  
    Faithful ports of external protocols must include fork tests that compare key outputs (quotes, state changes, events) against the original on-chain contracts for parity.

Tests that do not meet these standards will be considered insufficient during review.

We are currently in the **requirements definition** phase. No source code changes to contracts, skills, or implementation docs will be made until:
1. Requirements are captured and agreed in this PRD.
2. A full codebase review produces a gap report.
3. A detailed implementation plan is written and agreed.

See the process stated at the top of this section.

Previous ad-hoc documentation and NatSpec work must be evaluated against the finalized requirements rather than assumed complete.

## Appendix

### Glossary

| Term | Definition |
|------|------------|
| Facet | A contract containing logic that can be added to a Diamond proxy |
| Target | Implementation layer that contains business logic, used by Facets |
| Repo | Storage library using Diamond storage pattern with dual `_layout()` functions |
| DFPkg | Diamond Factory Package - bundles facets into deployable units |
| CREATE3 | Deployment method providing deterministic addresses independent of deployer nonce |

### References

- [EIP-2535: Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535)
- [Solady Library](https://github.com/Vectorized/solady)
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
