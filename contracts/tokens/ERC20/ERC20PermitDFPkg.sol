// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondFactoryPackage} from "contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";
import {IDiamond} from "contracts/interfaces/IDiamond.sol";
// import {
//     IERC20PermitStorage,
//     ERC20PermitStorage
// } from "contracts/token/ERC20/extensions/utils/ERC20PermitStorage.sol";
// import {BetterERC20Permit} from "contracts/crane/token/ERC20/extensions/BetterERC20Permit.sol";
import {Create3AwareContract} from "contracts/factories/create2/aware/Create3AwareContract.sol";
import {ICreate3Aware} from "contracts/interfaces/ICreate3Aware.sol";
import {ERC20Repo} from "contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "contracts/utils/cryptography/EIP712/EIP712Repo.sol";

interface IERC20PermitDFPkg {
    struct PkgInit {
        IFacet erc20PermitFacet;
    }

    struct PkgArgs {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        address recipient;
        bytes32 optionalSalt;
    }

    error NoNameAndSymbol();

    error NoRecipient();
}

contract ERC20PermitDFPkg is Create3AwareContract, IERC20PermitDFPkg, IDiamondFactoryPackage {
    using EfficientHashLib for bytes;

    IFacet immutable ERC20_PERMIT_FACET;

    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        /// forge-lint: disable-next-line(mixed-case-variable)
        PkgInit memory pkgInit = abi.decode(initData, (PkgInit));
        ERC20_PERMIT_FACET = pkgInit.erc20PermitFacet;
    }

    function facetInterfaces() public view returns (bytes4[] memory interfaces) {
        return ERC20_PERMIT_FACET.facetInterfaces();
    }

    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](1);

        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_PERMIT_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_PERMIT_FACET.facetFuncs()
        });
    }

    /**
     * @return config Unified function to retrieved `facetInterfaces()` AND `facetCuts()` in one call.
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        (PkgArgs memory decodedArgs) = abi.decode(pkgArgs, (PkgArgs));

        if (bytes(decodedArgs.name).length == 0) {
            if (bytes(decodedArgs.symbol).length != 0) {
                decodedArgs.name = decodedArgs.symbol;
            } else {
                revert NoNameAndSymbol();
            }
        } else if (bytes(decodedArgs.symbol).length == 0) {
            decodedArgs.symbol = decodedArgs.name;
        }

        if (decodedArgs.totalSupply != 0) {
            if (decodedArgs.recipient == address(0)) {
                revert NoRecipient();
            }
        }

        if (decodedArgs.decimals == 0) {
            decodedArgs.decimals = 18;
        }

        // if (bytes(decodedArgs.version).length == 0) {
        //     decodedArgs.version = "1";
        // }

        // return keccak256(abi.encode(decodedArgs));
        return abi.encode(decodedArgs).hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        (PkgArgs memory decodedArgs) = abi.decode(pkgArgs, (PkgArgs));

        if (bytes(decodedArgs.name).length == 0) {
            if (bytes(decodedArgs.symbol).length != 0) {
                decodedArgs.name = decodedArgs.symbol;
            } else {
                revert NoNameAndSymbol();
            }
        } else if (bytes(decodedArgs.symbol).length == 0) {
            decodedArgs.symbol = decodedArgs.name;
        }

        if (decodedArgs.totalSupply != 0) {
            if (decodedArgs.recipient == address(0)) {
                revert NoRecipient();
            }
        }

        if (decodedArgs.decimals == 0) {
            decodedArgs.decimals = 18;
        }

        // if (bytes(decodedArgs.version).length == 0) {
        //     decodedArgs.version = "1";
        // }

        return abi.encode(decodedArgs);
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
        (PkgArgs memory decodedArgs) = abi.decode(initArgs, (PkgArgs));
        ERC20Repo._initialize(
            // string memory name,
            decodedArgs.name,
            // string memory symbol,
            decodedArgs.symbol,
            // uint8 decimals,
            decodedArgs.decimals
        );
        EIP712Repo._initialize(
            // string memory name,
            decodedArgs.name,
            // string memory version
            "1"
        );
        if (decodedArgs.totalSupply > 0) {
            ERC20Repo._mint(decodedArgs.recipient, decodedArgs.totalSupply);
        }
    }

    // account
    function postDeploy(address) public pure returns (bool) {
        return true;
    }
}
