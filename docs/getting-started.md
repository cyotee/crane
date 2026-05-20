# Getting Started

## Install

Add Crane as a Foundry dependency:

```bash
forge install cyotee/crane
```

Update `remappings.txt` and `foundry.toml` with the required aliases (see repository for current mappings).

## Initialize Factories

Most workflows begin by deploying the Create3Factory and DiamondPackageCallBackFactory.

```solidity
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

contract Example is Test {
    ICreate3FactoryProxy internal create3Factory;
    IDiamondPackageCallBackFactory internal diamondFactory;

    function setUp() public {
        (create3Factory, diamondFactory) = InitDevService.initEnv(address(this));
    }
}
```

`InitDevService.initEnv` deploys core facets (ERC165, DiamondCut, Loupe, ownership, operable) and the two factories.

## Deploy a Facet

Facets are deployed through the Create3Factory using a salt derived from the contract name.

```solidity
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

using BetterEfficientHashLib for bytes;

IFacet myFacet = IFacet(
    create3Factory.deployFacet(
        type(MyFacet).creationCode,
        abi.encode(type(MyFacet).name)._hash()
    )
);
vm.label(address(myFacet), type(MyFacet).name);
```

The resulting address is deterministic given the creation code and salt.

## Deploy a Package

Packages bundle facet references (in the constructor) and expose `facetCuts()` and initialization logic.

```solidity
IMyDFPkg pkg = IMyDFPkg(
    address(
        create3Factory.deployPackageWithArgs(
            type(MyDFPkg).creationCode,
            abi.encode(IMyDFPkg.PkgInit({ myFacet: myFacet })),
            abi.encode(type(MyDFPkg).name)._hash()
        )
    )
);
```

## Deploy a Proxy from a Package

```solidity
address proxy = diamondFactory.deploy(pkg, abi.encode(pkgArgs));
```

The factory deploys a minimal callback proxy, invokes the package for cuts and initialization, and returns the proxy address. The same package and arguments produce the same address on any chain.

## Next Steps

- Read the Facet-Target-Repo pattern.
- Study an existing DFPkg such as `ERC20DFPkg`.
- Follow the testing patterns when writing specifications.
