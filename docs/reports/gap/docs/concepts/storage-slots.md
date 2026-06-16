# Gap Report: docs/concepts/storage-slots.md

**File Type:** Documentation

**Primary LR Violations:** LR-2 (GitBook content) + LR-6 (ERC1967 storage slots)

**Status:** CLOSED

## Current State
Updated with full LR-2/LR-6 coverage for storage concepts. Previously used non-compliant slot derivation examples and lacked required detail/cross-links.

## Specific Gaps (Closed)
- [x] Updated all code examples and explanations to the ERC1967-compliant form: `bytes32 internal constant DEFAULT_SLOT = bytes32(uint256(keccak256(abi.encode("name"))) - 1);` (LR-6). Canonical examples now use real compliant Repos: FacetRegistryRepo (`crane.registries.facets`), OperableRepo, ERC2535Repo (`eip.erc.2535`).
- [x] Added detailed rationale (EIP-1967 reference, collision resistance, proxy friendliness) taken from PRD LR-6.
- [x] Added explicit ties to NatSpec + AsciiDoc include-tags (LR-1): `// tag::STORAGE_SLOT[]`, `// tag::Storage[]`, `// tag::_layoutStruct(bytes32)[]` etc. on slot/Storage/_layout symbols + rich @dev NatSpec. References the verification Foundry Script and that selector/interfaceId values come **ONLY** from `CENTRALLY_COMPUTED_NATSPEC_VALUES.md` (e.g. IFacet 0x5b6f4d01 / 0x2ea80826 / 0x574a4cff / 0xf10d7a75; IDiamondPackageCallBackFactory 0x949da331 etc.).
- [x] Expanded detailed explanation of dual layout, overloading, why libraries, storage isolation (foundational for Diamond reuse).
- [x] Added comprehensive cross-links to all required LR-2 GitBook areas: CREATE3 Package / chain setup (Create3FactoryDFPkg), explicit DiamondPackageCallBackFactory reuse (0x949da331), Registries (purpose + auto-pop + canonical usage), ported protocol test usage (CraneTest/TestBase_* + handlers + Behavior), protocol utilities + general type libs (Sets/AddressSetRepo inside Repos, ConstProdUtils, AwareRepos), agent value prop (LR-4: "reuse already-deployed verified code...", "deploy once, attach everywhere").
- [x] Cross-links to concepts/facet-target-repo.md, building-with-crane.md, deployment/create3.md, deployment/dfpkg.md, development/natspec.md, development/testing.md, CODEBASE_MAP.md, getting-started.md, AGENTS.md, and source Repos.
- [x] Included LR-4 reuse/security/cost rationale tied directly to stateless facets + per-proxy ERC1967 storage slots.

## Required Changes (Completed)
1. Added the specific missing detailed content sections per LR-2 in PRD (with storage-slot-specific framing for CREATE3/DFPkg reuse, registries, protocols, Sets/utilities) + full LR-6 ERC1967 updates.
2. Ensured rich cross-links (internal to concepts + to deployment/getting-started/CODEBASE_MAP/testing/natspec).
3. Updated for ERC1967 standard, NatSpec verification script/central values process, testing standards (storage isolation under LR-7).

## Notes
- Content supports other agents deploying factories and reusing packages (storage isolation guarantees safe reuse of shared facets/Pkgs).
- Edits strictly limited to: this gap report + the doc (`docs/concepts/storage-slots.md`) + GAP_REPORT.md.
- Followed strict read order exactly: 1. this (target) gap report, 2. `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md` (used ONLY its values for any referenced NatSpec/selector examples; none fabricated for slots), 3. PRD.md (LR-2 full required GitBook areas + LR-6 ERC1967 section + rationale), 4. AGENTS.md (storage slot pattern, naming, duals, NatSpec rules, key files), 5. source file(s) referenced (the concepts doc itself + canonical `contracts/registries/facet/FacetRegistryRepo.sol`, `contracts/introspection/ERC2535/ERC2535Repo.sol`, `contracts/access/operable/OperableRepo.sol`, `docs/concepts/facet-target-repo.md`, plus cross-referenced deployment/dfpkg/create3 sources and registry Repos for accuracy).
- No values were taken from ad-hoc cast; all central NatSpec examples pulled verbatim from CENTRALLY... (IFacet, IDiamond*, DFPkg selectors).
- See updated `docs/concepts/storage-slots.md` for the full expanded content.

**Priority:** High (now resolved)
