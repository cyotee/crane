# Building Custom Modules with Crane

This guide is written for AI agents and developers who want to extend Crane or build production DeFi features on top of it.

Crane's value proposition: **write once (facet + package), deploy cheaply everywhere (deterministic proxies), test rigorously, and let other agents reuse your work via skills**.

## The Mandatory Pattern: Facet-Target-Repo (FTR)

Every substantial feature follows three files + optional supporting contracts:

1. **`*Repo.sol`** (library) — All storage + internal accessors + guard functions (`_onlyXxx`).
   - Use dual `_layoutStruct()` overloads.
   - Storage slot: hierarchical keccak, e.g. `"crane.feature.mything"`.
   - Never use state variables in the library.

2. **`*Target.sol`** (contract) — Business logic that inherits interfaces and calls into the Repo.
   - Thin; delegates heavy lifting to Repo.

3. **`*Facet.sol`** (contract) — Extends Target and implements `IFacet` for metadata (name, interfaces, funcs).
   - The only thing attached to Diamonds.

Supporting:
- `*Modifiers.sol` — Thin modifiers delegating to Repo guards (e.g. `onlyOperator`).
- `*Service.sol` — Stateless complex logic (use structs to avoid stack-too-deep).
- `*AwareRepo.sol` — For injecting external addresses (e.g. router, vault).
- `I*DFPkg.sol` + `*DFPkg.sol` — Bundle facets + init for repeatable Diamonds.

See `crane-architecture` skill and `contracts/access/operable/` for the complete reference implementation.

## Step-by-Step: New Feature

1. Define the interface(s) first (`contracts/interfaces/...`).
   - Add full NatSpec + `@custom:selector` / `signature` / `topiczero`.
   - Wrap with `// tag::IFoo[] ... // end::IFoo[]`.

2. Create the Repo.
   - Dual functions for every operation.
   - `_onlyXxx(Storage storage, ...)` guards.
   - NatSpec + include tags.

3. Implement Target + tests.
   - Use Behavior libraries for interface compliance.
   - Write handler + invariant tests for stateful properties.

4. Create the Facet.
   - Implement `facetName`, `facetInterfaces`, `facetFuncs`, `facetMetadata`.
   - Add NatSpec.

5. (Recommended) Create a DFPkg.
   - `PkgInit` and `PkgArgs` live **in the interface**.
   - Provide a `deploy(...)` helper.
   - Wire `initAccount` to apply cuts + call initializers.

6. Write a FactoryService (if multiple related deploys).
   - Group facet + package deployment.
   - Always `vm.label`.
   - Salt = `abi.encode(type(X).name)._hash()`.

7. Add or update a skill under `.claude/skills/`.
   - Document usage, examples, gotchas.
   - Make it usable by other agents.

8. Update docs (SUMMARY, relevant md files) and NatSpec extraction points.

## Deployment Cost Savings

- One facet deployment (gas paid once).
- Each proxy instance costs only the minimal proxy + init calldata.
- Same package + args = same address on every chain (CREATE3).
- Agents reuse published facets/packages across projects.

## NatSpec & Documentation Requirement

Every external/public symbol that forms part of the API **must** have:
- `/// @notice` (and @dev/@param/@return as applicable).
- `@custom:signature` and the matching selector (use `cast sig`).
- `// tag::SymbolName[]` / `// end::SymbolName[]` exactly.

Interfaces get `@custom:interfaceid`.

Run `cast` to verify before committing.

See `development/natspec.md` and `crane-natspec` skill.

## Testing

- Co-locate `TestBase_*.sol` and `Behavior_*.sol` next to the code.
- Use declarative invariants + handlers for fuzz.
- Protocol ports have deep TestBase inheritance chains.

See `crane-testing` skill.

## Security Model

- BattleChain gate for factories, core DFPkgs, and major components.
- Reentrancy protection (transient), operable access, multi-step ownership.
- Comprehensive behavior + invariant testing.
- Never bypass patterns for "simplicity".

## Agent-Specific Tips

- When asked to implement something, first consult the relevant Crane skill(s).
- Prefer extending existing `*AwareRepo` + `*Service` rather than reinventing.
- After shipping, package the knowledge into a new or updated skill.
- Use `CraneTest` base for all specs.
- Emit clear NatSpec — future agents (and docs) will `include::` it.

## Examples in the Repo

- `contracts/tokens/ERC20/` — Full native ERC20/2612/4626 with DFPkg.
- `contracts/access/operable/` — Canonical access control.
- `contracts/factories/...` — All the deployment machinery itself.
- Protocol integrations under `contracts/protocols/` (study how they wrap external logic).

Start small, follow the pattern strictly, document everything, and publish the skill.

Other agents will thank you by reusing your facets and saving gas.

## See also

- [Facet-Target-Repo](facet-target-repo.md)
- [DFPkg Pattern](dfpkg.md)
- [Registries](registries.md)
- [Getting Started](../getting-started.md)
- [Testing Patterns](../development/testing.md)
