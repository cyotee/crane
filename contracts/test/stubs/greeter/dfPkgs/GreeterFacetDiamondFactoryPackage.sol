// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import {
//     IGreeter
// } from "contracts/crane/test/stubs/greeter/interfaces/IGreeter.sol";
import {
    GreeterFacet
} from "../facets/GreeterFacet.sol";

import {
    IDiamond
} from "../../../../introspection/erc2535/interfaces/IDiamond.sol";
import {
    IDiamondFactoryPackage
} from "../../../../factories/create2/callback/diamondPkg/interfaces/IDiamondFactoryPackage.sol";

contract GreeterFacetDiamondFactoryPackage
is
GreeterFacet,
IDiamondFactoryPackage
{

    IDiamondFactoryPackage immutable SELF;

    constructor() {
        SELF = this;
    }

    function facetInterfaces()
    public view virtual
    override(
        GreeterFacet,
        IDiamondFactoryPackage
    )
    returns(bytes4[] memory interfaces) {
        return GreeterFacet.facetInterfaces();
    }

    function facetCuts()
    public view virtual returns(IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](1);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(SELF),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: facetFuncs()
        });
    }

    function diamondConfig()
    public view virtual returns(IDiamondFactoryPackage.DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({
            facetCuts: facetCuts(),
            interfaces: facetInterfaces()
        });
    }

    function calcSalt(
        bytes memory pkgArgs
    ) public pure returns(bytes32 salt) {
        salt = keccak256(abi.encode(pkgArgs));
    }

    function processArgs(
        bytes memory pkgArgs
    ) public pure returns(
        // bytes32 salt,
        bytes memory processedPkgArgs
    ) {
        // salt = keccak256(abi.encode(pkgArgs));
        processedPkgArgs = pkgArgs;
    }

    /**
     * @dev A standardized proxy initialization function.
     */
    function initAccount(
        bytes memory initArgs
    ) public {
        _initGreeter(abi.decode(initArgs, (string)));
    }

    // account
    function postDeploy(address )
    public virtual returns(bytes memory postDeployData) {
        return "";
    }

}