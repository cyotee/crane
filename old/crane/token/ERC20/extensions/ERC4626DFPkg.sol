// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "contracts/crane/interfaces/IDiamond.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {ICreate3Aware} from "contracts/crane/interfaces/ICreate3Aware.sol";
import {IDiamondFactoryPackage} from "contracts/crane/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {BetterIERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "contracts/crane/token/ERC20/utils/BetterSafeERC20.sol";
import {IERC2612} from "contracts/crane/interfaces/IERC2612.sol";
import {ERC4626Storage} from "contracts/crane/token/ERC20/extensions/utils/ERC4626Storage.sol";
// import {
//     IERC20PermitStorage,
//     ERC20PermitStorage
// } from "contracts/crane/token/ERC20/extensions/utils/ERC20PermitStorage.sol";

interface IERC4626DFPkg {
    error NoUnderlying();

    /// forge-lint: disable-next-line(pascal-case-struct)
    struct ERC4626DFPkgInit {
        IFacet erc20PermitFacet;
        IFacet erc4626Facet;
    }

    /// forge-lint: disable-next-line(pascal-case-struct)
    struct ERC4626DFPkgArgs {
        address underlying;
        uint8 decimalsOffset;
        string name;
        string symbol;
    }
}

contract ERC4626DFPkg is ERC4626Storage, Create3AwareContract, IERC4626DFPkg, IDiamondFactoryPackage {
    using EfficientHashLib for bytes;

    using SafeERC20 for BetterIERC20;

    IFacet immutable ERC20_PERMIT_FACET;
    IFacet immutable ERC4626_FACET;

    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        /// forge-lint: disable-next-line(mixed-case-variable)
        ERC4626DFPkgInit memory erc4626DFPkgInit_ = abi.decode(initData, (ERC4626DFPkgInit));
        ERC20_PERMIT_FACET = erc4626DFPkgInit_.erc20PermitFacet;
        ERC4626_FACET = erc4626DFPkgInit_.erc4626Facet;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](6);

        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        interfaces[3] = type(IERC2612).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;
        interfaces[5] = type(IERC4626).interfaceId;
    }

    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](2);

        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_PERMIT_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_PERMIT_FACET.facetFuncs()
        });

        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC4626_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC4626_FACET.facetFuncs()
        });
    }

    /**
     * @return config Unified function to retrieved `facetInterfaces()` AND `facetCuts()` in one call.
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        (ERC4626DFPkgArgs memory decodedArgs) = abi.decode(pkgArgs, (ERC4626DFPkgArgs));

        // Fast fail an invalid configuration.
        if (decodedArgs.underlying == address(0)) {
            revert NoUnderlying();
        }

        // We do include the decimalsOffset in the salt to allow for different decimals offsets.
        // return keccak256(abi.encode(decodedArgs));
        return abi.encode(decodedArgs).hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        return pkgArgs;
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

    function initAccount(bytes memory initArgs) public {
        (ERC4626DFPkgArgs memory decodedArgs) = abi.decode(initArgs, (ERC4626DFPkgArgs));
        if (bytes(decodedArgs.name).length == 0) {
            decodedArgs.name = string.concat(BetterIERC20(decodedArgs.underlying).name(), " Vault");
        }
        if (bytes(decodedArgs.symbol).length == 0) {
            decodedArgs.symbol = "4626Vault";
        }
        _initERC4626(
            // string memory name,
            decodedArgs.name,
            // string memory symbol,
            decodedArgs.symbol,
            // IERC20 asset,
            BetterIERC20(address(decodedArgs.underlying)),
            // uint8 decimalsOffset
            decodedArgs.decimalsOffset
        );
    }

    function postDeploy(address) public pure returns (bytes memory postDeployData) {
        return "";
    }
}
