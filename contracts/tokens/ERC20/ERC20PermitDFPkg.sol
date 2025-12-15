// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";

interface IERC20PermitDFPkg {
    struct PkgInit {
        IFacet erc20Facet;
        IFacet erc5267Facet;
        IFacet erc2612Facet;
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

contract ERC20PermitDFPkg is IERC20PermitDFPkg, IDiamondFactoryPackage {
    using BetterEfficientHashLib for bytes;

    IFacet immutable ERC20_FACET;
    IFacet immutable ERC5267_FACET;
    IFacet immutable ERC2612_FACET;

    constructor(PkgInit memory pkgInit) {
        ERC20_FACET = pkgInit.erc20Facet;
        ERC5267_FACET = pkgInit.erc5267Facet;
        ERC2612_FACET = pkgInit.erc2612Facet;
    }

    function packageName() public pure returns (string memory name_) {
        return type(ERC20PermitDFPkg).name;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](3);
        facetAddresses_[0] = address(ERC20_FACET);
        facetAddresses_[1] = address(ERC5267_FACET);
        facetAddresses_[2] = address(ERC2612_FACET);
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](5);

        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        interfaces[3] = type(IERC20Permit).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;
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

    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](3);

        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC5267_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_FACET.facetFuncs()
        });
        facetCuts_[2] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC2612_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC2612_FACET.facetFuncs()
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

        return abi.encode(decodedArgs)._hash();
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
