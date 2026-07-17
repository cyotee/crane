# Factory Services

FactoryService libraries group the deployment of related facets and packages.

## Purpose

- Centralize salt constants and deployment ordering.
- Apply consistent labeling for traces (`vm.label`).
- Encapsulate constructor argument construction for packages.
- Provide a single place to update when new core facets are added.

## Example Pattern

```solidity
library AccessFacetFactoryService {
    using BetterEfficientHashLib for bytes;

    Vm constant vm = Vm(VM_ADDRESS);

    function deployMultiStepOwnableFacet(ICreate3Factory factory)
        internal
        returns (IFacet)
    {
        IFacet facet = factory.deployFacet(
            type(MultiStepOwnableFacet).creationCode,
            abi.encode(type(MultiStepOwnableFacet).name)._hash()
        );
        vm.label(address(facet), type(MultiStepOwnableFacet).name);
        return facet;
    }

    function deployOperableFacet(ICreate3Factory factory)
        internal
        returns (IFacet)
    {
        IFacet facet = factory.deployFacet(
            type(OperableFacet).creationCode,
            abi.encode(type(OperableFacet).name)._hash()
        );
        vm.label(address(facet), type(OperableFacet).name);
        return facet;
    }
}
```

Similar services exist for introspection facets and for full DFPkg deployment sequences.

## Usage in Tests and Scripts

```solidity
IFacet msOwnable = AccessFacetFactoryService.deployMultiStepOwnableFacet(create3Factory);
IFacet operable = AccessFacetFactoryService.deployOperableFacet(create3Factory);

// later, when constructing a package that needs them:
SomePkg pkg = ... (deployPackageWithArgs(..., abi.encode(PkgInit({
    multiStepOwnableFacet: msOwnable,
    operableFacet: operable,
    ...
}))));
```

## Benefits for Reuse

All consumers resolve to the same canonical facet addresses. When a package is constructed with these facets, every proxy it creates references the identical implementations. Updating a facet requires only redeploying the facet (new salt or new versioned package) and updating packages that depend on it.

## See also

- [CREATE3 & New Chain Setup](create3.md)
- [Diamond Factory Packages](dfpkg.md)
- [Registries](../concepts/registries.md)
