# Centrally Computed NatSpec Values - Crane Framework

**Date of this pass:** 2026-07-02
**Method:** `cast sig "..."` for selectors, `cast keccak "..."` for event topic0.
**InterfaceIds:** Computed where available from source or XOR; prefer `type(Interface).interfaceId` in Solidity for accuracy.
**Purpose:** Single source of truth so subagents do not independently compute and risk errors. These values should be inserted into the per-file gap reports and then into the actual source code.

## How to use
1. Find the symbol in the relevant gap report under `docs/reports/gap/`.
2. Insert the @custom: lines.
3. Wrap with the // tag:: // end:: as per standard.
4. Verify with `forge build` and tests.

---

## Core Symbols (from PRD examples + factories + access + introspection)

### IOperable
- interfaceId: 0xa7f11160

**Events**
- NewGlobalOperatorStatus(address,bool)
  - topic0: 0x26ba28058a3c072a70c8fd315037fe9b3957237cef5c61a9652a8da41c673daa

- NewFunctionOperatorStatus(address,bytes4,bool)
  - topic0: 0xf071216dc06459e77b915d1883909d92f41239172000b60261dfdc0351889569

**Errors**
- NotOperator(address)
  - selector: 0x76c6c93a

**Functions**
- isOperator(address) : 0x6d70f7ae
- isOperatorFor(bytes4,address) : 0xea562a25
- setOperator(address,bool) : 0x558a7297
- setOperatorFor(bytes4,address,bool) : 0x755dbe7c

### ICreate3Factory
**Functions**
- diamondPackageFactory() : 0x0fe96d13
- setDiamondPackageFactory(address) : 0x1cdca5df
- create3(bytes,bytes32) : 0xa7b62a7f
- create3WithArgs(bytes,bytes,bytes32) : 0x1f7fe4db

### IDiamondFactoryPackage
**Interface**
- interfaceId: (compute with type(IDiamondFactoryPackage).interfaceId or XOR of all its external selectors)

**Functions**
- packageName() : 0xabc8b346
- facetInterfaces() : 0x2ea80826
- facetAddresses() : 0x52ef6b2c
- packageMetadata() : 0xf45469e7
- facetCuts() : 0xa4b3ad35
- diamondConfig() : 0x65d375b3
- calcSalt(bytes) : 0xd82be56e
- processArgs(bytes) : 0x87c3adb3
- updatePkg(address,bytes) : 0xa9089235
- initAccount(bytes) : 0x870d4838
- postDeploy(address) : 0x70068fcf

### IDiamondPackageCallBackFactory
**Interface**
- interfaceId: 0x949da331

**Functions**
- PROXY_INIT_HASH() : 0x1c8b7630
- ERC165_FACET() : 0x421d0c7b
- DIAMOND_LOUPE_FACET() : 0x978d23cf
- POST_DEPLOY_HOOK_FACET() : 0xbce46817
- pkgOfAccount(address) : 0x8a648684
- pkgArgsOfAccount(address) : 0x3f58dd6d
- calcAddress(address,bytes) : 0x33a41d70
- deploy(address,bytes) : 0xe97fac05
- initAccount(address,bytes) : 0x8e85783e

**Errors**
- DeploymentAddressMismatch(address,address)
  - selector: 0x37dd4fb4

**Other public surface on impl (for NatSpec)**
- facetInterfaces() : 0x2ea80826
- facetCuts() : 0xa4b3ad35
- erc8109Funcs() : 0x7cbde55d
- pkgConfig() : 0x8072e14e
- postDeploy(address) : 0x70068fcf
- postDeployFacetCuts() : 0xd5a7944d
- initAccount() : 0x4ec1ce21

### IFacet (common)
**Functions**
- facetName() : 0x5b6f4d01
- facetInterfaces() : 0x2ea80826
- facetFuncs() : 0x574a4cff
- facetMetadata() : 0xf10d7a75

**ERC165**
- supportsInterface(bytes4) : 0x01ffc9a7

### Other commonly referenced
- diamondCut(...) (IDiamondCut) : 0x1f931c1c
- (Add more as reports are reviewed)

### ICallTargetRegistryManagement
**Interface**
- interfaceId: 0x9400c76a

**Functions**
- setDefaultCallTargetForID(bytes4,address) : 0xaf87fa1d
- setCallTargetForIDForCaller(bytes4,address,address) : 0x3b873d77

### ICallTargetRegistryQuery
**Interface**
- interfaceId: 0xb6dd59b7

**Functions**
- defaultCallTargetForID(bytes4) : 0xd2cfb6ed
- callTargetForIDForCaller(bytes4,address) : 0x6412ef5a

---

## ERC8023 Gold Standard (for reference, already well-populated in source)
See contracts/access/ERC8023/IMultiStepOwnable.sol for the model with correct topic0 and selectors.

---

**Next steps for full population:**
- Use this file + scripts/compute_natspec_values.sh to expand.
- For every core gap report, add a section like the ones in the examples.
- Then use the values to patch the .sol files (in implementation phase after plan).

This document is the single source for the current central pass.
