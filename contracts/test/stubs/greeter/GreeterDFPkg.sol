// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IGreeter} from "@crane/contracts/test/stubs/greeter/IGreeter.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {GreeterFacet} from "@crane/contracts/test/stubs/greeter/GreeterFacet.sol";
import {GreeterLayout, GreeterRepo} from "@crane/contracts/test/stubs/greeter/GreeterRepo.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

interface IGreeterDFPkg is IDiamondFactoryPackage {
    struct PkgInit {
        IDiamondPackageCallBackFactory diamondPackageFactory;
        IFacet greeterFacet;
    }

    struct PkgArgs {
        string message;
    }
}

contract GreeterDFPkg is GreeterFacet, IGreeterDFPkg {
    using BetterEfficientHashLib for bytes;

    IGreeterDFPkg immutable SELF;

    IDiamondPackageCallBackFactory public immutable DIAMOND_FACTORY;

    IFacet public immutable GREETER_FACET;

    constructor(PkgInit memory pkgInit) {
        SELF = this;
        DIAMOND_FACTORY = pkgInit.diamondPackageFactory;
        GREETER_FACET = pkgInit.greeterFacet;
    }

    function deployGreeter(string memory initMessage) public returns (IGreeter instance) {
        return IGreeter(DIAMOND_FACTORY.deploy(SELF, abi.encode(IGreeterDFPkg.PkgArgs({message: initMessage}))));
    }

    function packageName() public pure returns (string memory name_) {
        return type(GreeterDFPkg).name;
    }

    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](1);
        facetAddresses_[0] = address(GREETER_FACET);
    }

    function facetInterfaces()
        public
        pure
        virtual
        override(GreeterFacet, IDiamondFactoryPackage)
        returns (bytes4[] memory interfaces)
    {
        return GreeterFacet.facetInterfaces();
    }

    function facetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](1);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(GREETER_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: GREETER_FACET.facetFuncs()
        });
    }

    function diamondConfig() public view virtual returns (IDiamondFactoryPackage.DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        salt = abi.encode(pkgArgs)._hash();
    }

    function processArgs(bytes memory pkgArgs)
        public
        pure
        returns (
            // bytes32 salt,
            bytes memory processedPkgArgs
        )
    {
        // salt = keccak256(abi.encode(pkgArgs));
        processedPkgArgs = pkgArgs;
    }

    function updatePkg(
        address, // expectedProxy,
        bytes memory // pkgArgs
    )
        public
        virtual
        returns (bool)
    {
        return true;
    }

    /**
     * @dev A standardized proxy initialization function.
     */
    function initAccount(bytes memory initArgs) public {
        PkgArgs memory pkgArgs = abi.decode(initArgs, (PkgArgs));
        GreeterRepo._setMessage(pkgArgs.message);
    }

    // account
    function postDeploy(address) public virtual returns (bool) {
        return true;
    }
}
