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
5. Serve as the foundation for IndexedEx vault infrastructure

### Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| IndexedEx Adoption | Full adoption | All IndexedEx contracts built on Crane patterns |
| Test Coverage | High coverage | All public APIs have unit tests, critical paths have fuzz tests |
| Developer Experience | Fast iteration | Clear patterns documented, minimal boilerplate required |
| Cross-Chain Determinism | Consistent addresses | Same deployment produces same addresses across all EVM chains |

## Non-Goals (Out of Scope)

- **End-user applications** - Crane is infrastructure, not end-user facing. UI, APIs, and user-facing features belong in consuming projects
- **Non-EVM chains** - Crane focuses exclusively on EVM-compatible chains. Solana, Cosmos, etc. are out of scope
- **Vault/strategy business logic** - Specific vault strategies and yield logic belong in IndexedEx, not Crane

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
| M2: IndexedEx Integration | Validate Crane patterns through IndexedEx usage | Pending |
| M3: Documentation Complete | Full NatSpec coverage, architecture docs | Pending |
| M4: Production Ready | Audit-ready, comprehensive test coverage | Pending |

## Current Focus: Review & Stabilization

The current development phase focuses on reviewing and stabilizing existing Crane components:

| Task | Description | Status |
|------|-------------|--------|
| C-1 | CREATE3 Factory and Deterministic Deployment Review | Ready |
| C-2 | Diamond Package and Proxy Architecture Review | Ready |
| C-3 | Test Framework and IFacet Pattern Audit | Ready |
| C-4 | DEX Utilities Review (Slipstream + Uniswap) | Ready |
| C-5 | Token Standards Review (ERC20, Permit, EIP-712) | Ready |
| C-6 | Constant Product & Bonding Math Review | Ready |

See `UNIFIED_PLAN.md` for detailed task specifications.

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
