// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondPackageCallbackFactoryAware} from "@crane/contracts/interfaces/IDiamondPackageCallbackFactoryAware.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {DiamondPackageFactoryAwareRepo} from "@crane/contracts/factories/diamondPkg/DiamondPackageFactoryAwareRepo.sol";
// import {
//     DiamondPackageCallbackFactoryAwareStorage
// } from "@crane/contracts/factories/create2/callback/diamondPkg/DiamondPackageCallbackFactoryAwareStorage.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

contract DiamondPackageFactoryAwareFacet is
    // DiamondPackageCallbackFactoryAwareStorage,
    // Create3AwareContract,
    IDiamondPackageCallbackFactoryAware,
    IFacet
{
    // constructor(CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {}

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetName() public pure returns (string memory name) {
        return type(DiamondPackageFactoryAwareFacet).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IDiamondPackageCallbackFactoryAware).interfaceId;
        return interfaces;
    }

    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IDiamondPackageCallbackFactoryAware.diamondPackageCallbackFactory.selector;
        return funcs;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) {
            name = facetName();
            interfaces = facetInterfaces();
            functions = facetFuncs();
        }

    /* ---------------------------------------------------------------------- */
    /*                   IDiamondPackageCallbackFactoryAware                  */
    /* ---------------------------------------------------------------------- */

    function diamondPackageCallbackFactory()
        external
        view
        returns (IDiamondPackageCallBackFactory diamondPackageCallbackFactory_)
    {
        return DiamondPackageFactoryAwareRepo._diamondPackageFactory();
    }
}
