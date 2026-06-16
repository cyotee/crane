# Gap Report: contracts/factories/create3/Create3FactoryFacet.sol

**File Type:** Facet  
**Primary LR Violations:** LR-1 (NatSpec), LR-7 (Testing - declaration tests), LR-3 (Skills may need update)  
**Related:** LR-2 (Docs), LR-4 (Value prop)

**Status:** [x] LR-1 closed (NatSpec + AsciiDoc tags added using centrally computed values and ERC8023 gold standard include-tag style). Edits limited to this Facet per instructions. See source for details. LR-7 (Behavior declaration test assertions) and LR-3 (skill updates) remain open for follow-up as no test/skill files were edited for this isolated gap report.

## Current State
- Implements IFacet.
- Delegates to Create3FactoryTarget.
- Has basic facetName, facetInterfaces, facetFuncs, facetMetadata.
- No NatSpec comments at all (no // tag::, no @custom:).
- No include tags for documentation extraction.
- Functions are not wrapped.

## Specific Gaps
- **Missing full NatSpec + AsciiDoc tags (LR-1)**: [x] CLOSED
  - [x] Added `// tag::Create3FactoryFacet[]` wrapper for the contract.
  - [x] Added tags for each method: facetName(), facetInterfaces(), facetFuncs(), facetMetadata().
  - [x] Added @inheritdoc (from IFacet), @custom:selector, @custom:signature for all using exact central values.
  - [x] Documented the ICreate3Factory interfaceId usage in facetInterfaces (via @dev).
- No verification that this facet declares the correct interfaces/functions (though there is Behavior test elsewhere). (LR-7 remains)
- Storage/implementation details in Target not cross-referenced. (partial - @dev mentions delegation)
- Does not document that this is part of the core Create3Factory DFPkg. [x] Added to contract NatSpec.

## Required Changes to Close Gap
1. Wrap the entire contract: [x] DONE
   ```solidity
   // tag::Create3FactoryFacet[]
   contract Create3FactoryFacet is ... {
       ...
   }
   // end::Create3FactoryFacet[]
   ```

2. Add detailed NatSpec + tags for each function, matching the style of IMultiStepOwnable.sol (and gold facet): [x] DONE
   - Used @inheritdoc IFacet + @custom:selector + @custom:signature (with exact values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md)

3. Similarly for facetInterfaces(), facetFuncs(), facetMetadata(). [x] DONE

4. Add @custom:interfaceid if appropriate at contract level if it implements one. (N/A - IFacet interface itself does not declare one in current central values; no @custom:interfaceid added here.)

5. Update corresponding test to assert the exact declared values using Behavior. (Not performed - limited scope to Facet + reports only per "do not touch unrelated files" and "focus only on NatSpec"; LR-7 note left open. General Behavior_IFacet tests cover IFacet pattern.)

6. Add entry in relevant skill (crane-deployment or crane-architecture) if missing. (Not performed - would touch unrelated skill files.)

**NatSpec Values Note (Central Pass - Populated):**
- facetName(): selector 0x5b6f4d01 (cast sig "facetName()")
- facetInterfaces(): selector 0x2ea80826
- facetFuncs(): selector 0x574a4cff
- facetMetadata(): selector 0xf10d7a75

(These were computed centrally from the gap reports to avoid subagent conflicts. Use in source + update tags.)

## Subagent Task Notes
- Focus only on NatSpec addition and tag wrapping.
- Do not change logic.
- After central computation, populate the @custom: fields.
- Cross-check against ICreate3Factory.

**Priority:** High (core factory surface)**Centrally Computed Values (from this pass):**
- facetName() selector: 0x5b6f4d01
- facetInterfaces() selector: 0x2ea80826
- facetFuncs() selector: 0x574a4cff
- facetMetadata() selector: 0xf10d7a75

Use these in the source NatSpec.

## Central NatSpec Population (coordinated pass)
See docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md for the authoritative list of computed selectors, topic0, and interfaceIds.
Use those values when implementing the NatSpec tags in this file's source.

(Values pre-computed centrally to ensure accuracy and avoid duplication across subagents.)

## Completion Note
[x] NatSpec gaps closed for contracts/factories/create3/Create3FactoryFacet.sol on 2026-07-02.
- Source updated with exact tags and central @custom values.
- Changes verified via forge build + targeted tests (see task log).
- Only this gap report's files + main GAP_REPORT were modified.
