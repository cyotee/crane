# GAP_REPORT.md - Crane LR-1 / NatSpec Closure Tracking

This is the master tracker for LR-1 (rich NatSpec + // tag:: / end:: + @custom from central) and related (LR-6/7) gap closures.

**Process (mandatory for all subagents):** 
- Read per-file gap md(s)
- Read CENTRALLY_COMPUTED_NATSPEC_VALUES.md 
- Read AGENTS.md relevant (NatSpec, Facet-Target-Repo, tags, IFacet)
- Read gold examples + closed recap mds
- Read source(s)
- ONLY edit scoped files (max per instructions)
- Update this + per-file md to recap
- Targeted verif only: inspect, build --skip test --quiet, --list match, git status

## Closed Items

- [x] contracts/introspection/ERC2535/DiamondLoupeFacet.sol + its gap md (LR-1) + paired
- [x] contracts/introspection/ERC2535/DiamondLoupeTarget.sol + its gap md (LR-1)
  - 5 symbols each with exact tags; used central IFacet values + facetAddresses()=0x52ef6b2c
  - Rich @title etc + @inheritdoc + @dev delegates modeled on golds (ERC165Facet, Operable*, Targets)
  - Note surfaced: other IDiamondLoupe @custom selectors (facets 0x7a0ed627, facetFunctionSelectors 0xadfca15e, facetAddress 0xcdffacc6) not in central (only in interface file); future central update needed if to be added in impls.
  - See per-file gap mds for full recap + verif cmds.
- [x] contracts/tokens/ERC721/IERC721.sol + docs/reports/gap/contracts/tokens/ERC721/IERC721.sol.md + GAP_REPORT.md (LR-1)
  - Strict read order 1-6 completed before edit.
  - 13 symbols tagged (IERC721 + 3 events + 9 funcs incl. safe* overloads using hyphen tags); rich NatSpec + @custom:selector/signature/topiczero/interfaceid (0x80ac58cd) + @emits
  - Events Transfer/Approval/ApprovalForAll included with topic0 from computation; original code (incl. commented stubs) preserved exactly.
  - Pre tags: 0 / Post tags: 13
  - Verif: forge inspect ...:IERC721 (abi+methodIdentifiers matched selectors), build --skip test --quiet SUCCESS, test --list '*IERC721*' (related tests listed), no other files edited.
  - LR-1 CLOSED (note: values not in CENTRALLY so cast+inspect used per AGENTS; no IERC165 or errors in this interface file).
  - See per-file gap md for process/symbols/verif details.

## In Progress / Open Core Gaps (examples)
(Other gaps per their .md ; use same process)

## Verification Summary (from recent closures)
Targeted commands used (exit 0 expected):
- forge inspect ...:DiamondLoupeFacet (methodIdentifiers | abi)
- forge build --skip test --quiet <the .sol>
- forge test --list --match-path '*DiamondLoupe*'
- git status docs/reports/gap/contracts/introspection/ERC2535/
- (This pass) forge inspect contracts/tokens/ERC721/IERC721.sol:IERC721 (abi), forge build --skip test --quiet contracts/tokens/ERC721/IERC721.sol , forge test --list '*IERC721*'

Files edited in this LR-1 sub pass: prior 2.sol+2.md+1 + this: 1 .sol + 1 .md + 1 GAP_REPORT.md (scoped to IERC721 only).

For full status run librarian or see docs/CODEBASE_MAP.md .

Last updated: 2026-07-03 (LR-1 subagent pass on DiamondLoupe* + IERC721)
