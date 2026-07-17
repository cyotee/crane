# Gap Report: docs/CODEBASE_MAP.md

**File Type:** Documentation

**Primary LR Violations:** LR-2 (GitBook content)

## Current State
(High-level or partial coverage of required topics. Dedicated registries + general utilities sections added/updated to close LR-2 gaps in CODEBASE_MAP.md. Enhanced in final pass for fuller dedicated coverage.)

## Specific Gaps (Addressed)
- [x] Missing detailed explanation of required LR-2 areas (CREATE3 Package for chain setup, Diamond Package Factory reuse, Registries, ported protocol test usage, protocol utilities, general type libraries like Sets). — CLOSED: Added/updated full dedicated **Registries** and **General Utilities** sections in the doc. Registries section now starts with "Dedicated Registries Documentation (LR-2 GitBook requirement)" + explicit chain setup note (via Create3FactoryDFPkg) + verbatim "DiamondPackageCallBackFactory ... does not need to be redeployed per chain" + detailed purpose/population/usage for Facet/Package/CallTarget + consumer/agent flows + Behavior + LR-7 asserts + cross to GitBook. General utilities now has expanded detailed coverage of Sets (all 5 types + full Repo pattern details from AddressSetRepo: 1-indexed, _add/_addAsc/_remove/_values etc), ConstProdUtils (sorting, quotes, LP, usage), other helpers.
- [x] May lack links or sections tying to agent usage and value prop (LR-4). — Updated to include LR-4 verbatim security/cost quotes, "deploy once, attach everywhere", "agent-proof reuse", reuse rationale in registries + utilities sections + cross-links.
- [x] Needed more central values usage, explicit GitBook cross-links, source-derived depth for remaining registries/utilities. — Addressed with ONLY CENTRALLY... values (IFacet: 0x5b6f4d01/0x2ea80826/0x574a4cff/0xf10d7a75; IDiamondPackageCallBackFactory: 0x949da331 + its funcs; IDiamondFactoryPackage: 0xabc8b346/0x870d4838/0x70068fcf etc.) in examples; added links to docs/deployment/*.md, docs/protocols/*, docs/development/testing.md, AGENTS.md, PRD LR-2/4.
- SUMMARY.md may need updates to surface new content. (Not touched per edit rules.)

## Required Changes (Completed per strict process)
1. Read in strict order: 1. this gap report (docs/reports/gap/docs/CODEBASE_MAP.md), 2. CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY its values in all examples), 3. PRD.md (LR-2 required areas + LR-4), 4. AGENTS.md (registries notes, utils mentions, CODEBASE_MAP ref, architecture, key files including Create3Factory/ConstProdUtils), 5. source files (registries/facet/* including IFacetRegistry.sol + FacetRegistryRepo.sol + FacetRegistryFacet etc, registries/package/* + IDiamondFactoryPackageRegistry, registries/target/*, contracts/factories/create3/Create3Factory.sol for _register*, contracts/InitDevService.sol for canonical usage + bootstrap salts, contracts/interfaces/IDiamondPackageCallBackFactory.sol + IFacet.sol + IDiamondFactoryPackage, contracts/utils/collections/sets/AddressSetRepo.sol + other sets, contracts/utils/math/ConstProdUtils.sol + related).
2. Updated/added the dedicated sections in the doc (docs/CODEBASE_MAP.md) with detailed registries (purpose/population/usage + Create3 auto-pop + canonical + explicit reuse statement + chain setup + Behavior + tests) + detailed general utilities (Sets all types + exact Repo patterns/structs/funcs like _addAsc, math/ConstProdUtils details + examples, other collections/crypto/helpers) as per LR-2. Used central values ONLY. Added LR-4 ties + GitBook cross-links.
3. Ensured cross-links (AGENTS.md, PRD.md, deployment/create3/dfpkg, protocols/dexes, development/testing, source paths).
4. Updated this gap report and GAP_REPORT.md only (per rules).

## Notes
- Content must support other agents deploying factories and reusing packages. (Registries + reuse statements + central-value examples + chain presence note added/updated.)
- After central NatSpec pass, any code examples in docs should match. (Followed; only central values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md.)
- Edits strictly limited to: the doc (docs/CODEBASE_MAP.md) + this gap report + GAP_REPORT.md.

**Priority:** High (CLOSED)
