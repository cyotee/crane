# Gap Report for: contracts/introspection/ERC2535/IDiamond.sol

**File Type:** Interface (core ERC2535 types + event)

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (Mandatory & Verifiable)

**Current State Summary:**
Pre-edit: minimal placeholder NatSpec + TODO + no // tag:: / end:: at all. Original code, enum, struct, and event preserved exactly. LR-6 n/a (no storage). This is the canonical source for DiamondCut types/event (reexported by contracts/interfaces/IDiamond.sol).

**Detailed Gaps:**
- LR-1: Was missing rich NatSpec + // tag:: and @custom: tags (per ERC8023 gold standard). Now CLOSED.

**Process Followed (strict read order before ANY edit) and full recap:**
1. docs/reports/gap/contracts/introspection/ERC2535/IDiamond.sol.md (initial gap)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (for related: diamondCut selector 0x1f931c1c on IDiamondCut; no DiamondCut event topic0 listed so computed via cast keccak of canonical "DiamondCut((address,uint8,bytes4[])[],address,bytes)" per AGENTS guidance; no fabrication of interfaceid/selectors as IDiamond defines no functions)
3. PRD.md (LR-1 full): rich NatSpec + exact // tag:: / end:: (hyphen param form for events e.g. Foo(bar-baz)[]), @custom:signature/@custom:topiczero/@custom:selector for documented symbols on interfaces, canonical gold IMultiStepOwnable, scope includes core interfaces.
4. AGENTS.md (interface NatSpec gold + "ONLY 3 relative files"): from IMultiStepOwnable or closed I* (IOperable, IReentrancyLock); exact // tag::IDiamond[] + for enum/struct if documented + event with topic; hyphen event tags; ONLY edit this .sol + its .md + GAP_REPORT.md ; relative paths; targeted verif only after.
5. Golds:
   - contracts/access/ERC8023/IMultiStepOwnable.sol (full: top // tag::IMultiStepOwnable[] , events with (addr-addr), @custom:topic-signature + @custom:topiczero, errors with (addr), funcs with @custom:selector/signature, end tag after })
   - contracts/access/operable/IOperable.sol (closed I*: same patterns, hyphen tags like NewGlobalOperatorStatus(address-bool), centrals used)
   - contracts/access/reentrancy/IReentrancyLock.sol (closed; tags for IReentrancyLock[] + IsLocked() + funcs; prose only when no central entry)
   - contracts/interfaces/IDiamondLoupe.sol (if tagged: partial selectors present, no full tags yet)
   - contracts/interfaces/IDiamondCut.sol (references IDiamond.FacetCut; partial NatSpec with selector for diamondCut)
6. Source: contracts/introspection/ERC2535/IDiamond.sol (full re-read pre-edit; symbols: IDiamond, FacetCutAction enum, FacetCut struct, DiamondCut event)

**ONLY 3 relative files edited:** contracts/introspection/ERC2535/IDiamond.sol + docs/reports/gap/contracts/introspection/ERC2535/IDiamond.sol.md + GAP_REPORT.md . Relative paths only. No other files touched.

**Symbols documented (post edit):**
- IDiamond (interface)
- FacetCutAction (enum)
- FacetCut (struct)
- DiamondCut(FacetCut[]-address-bytes) (event)

**Pre/post tag count:** Pre: 0 (no // tag:: anywhere). Post: 4 opening tags (IDiamond[], FacetCutAction[], FacetCut[], DiamondCut(FacetCut[]-address-bytes)[] ) + matching ends.

**LR-1 changes applied:**
- Added full rich NatSpec modeled exactly on golds (IMultiStepOwnable / IOperable / IReentrancyLock): @title/@author/@notice/@dev/@param , @custom:topic-signature + @custom:topiczero for event.
- EXACT // tag::IDiamond[]  ... // end::IDiamond[] 
- EXACT // tag::FacetCutAction[] ... // end:: 
- EXACT // tag::FacetCut[] ... // end::
- EXACT // tag::DiamondCut(FacetCut[]-address-bytes)[] ... // end:: (hyphen per task + gold event pattern)
- @custom:topiczero computed (prefer listed, but absent in central for event) via `cast keccak "DiamondCut((address,uint8,bytes4[])[],address,bytes)"` = 0x8faa70878671ccd212d20771b795c50af8fd3ff6cf27f4bde57e5d4de0aeb673 (confirmed post by forge inspect)
- No @custom:interfaceid (IDiamond provides types/event only; no functions; consistent with non-use of type(IDiamond).interfaceId in codebase + central absence; no fabrication)
- Preserved original code/enum/struct/event EXACTLY (no param renames, kept comments moved to @dev).
- Used section headers inside per gold style (Types / Events).
- NO logic/pragma/import changes.

**Verification outputs (targeted only, post-edit, relative):**
```
$ forge inspect contracts/introspection/ERC2535/IDiamond.sol:IDiamond (abi|methodIdentifiers)
```
abi (events only):
```
╭-------+-----------------------------------------------+--------------------------------------------------------------------╮
| Type  | Signature                                     | Selector                                                           |
+============================================================================================================================+
| event | DiamondCut(IDiamond.FacetCut[],address,bytes) | 0x8faa70878671ccd212d20771b795c50af8fd3ff6cf27f4bde57e5d4de0aeb673 |
╰-------+-----------------------------------------------+--------------------------------------------------------------------╯
```
methodIdentifiers: (empty table, as expected for type/event-only interface)

```
$ forge build --skip test --quiet contracts/introspection/ERC2535/IDiamond.sol
BUILD_EXIT=0
```

Narrow list '*IDiamond*':
```
Narrow list *IDiamond*:
./test/foundry/spec/introspection/ERC2535/IDiamondLoupe_Behavior_Test.sol
...
./contracts/introspection/ERC2535/IDiamond.sol
...
build ok for narrow IDiamond scope
NARROW_LIST_DONE=0
```

**LR-1 CLOSED**
(Advances core ERC2535 introspection interface coverage for launch readiness.)
