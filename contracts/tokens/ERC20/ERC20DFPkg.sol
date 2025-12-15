// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

// import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
// import {
//     IERC20PermitStorage,
//     ERC20PermitStorage
// } from "@crane/contracts/token/ERC20/extensions/utils/ERC20PermitStorage.sol";
// import {BetterERC20Permit} from "@crane/contracts/crane/token/ERC20/extensions/BetterERC20Permit.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "@crane/contracts/interfaces/ICreate3Aware.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

interface IERC20DFPkg {
    struct PkgInit {
        IFacet erc20Facet;
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

    function deploy(
        IDiamondPackageCallBackFactory factory,
        string calldata name_,
        string calldata symbol,
        uint8 decimals,
        uint256 totalSupply,
        address recipient,
        bytes32 optionalSalt
    ) external returns (IERC20 token);

    function deploy(IDiamondPackageCallBackFactory factory, PkgArgs memory pkgArgs) external returns (IERC20 token);
}

contract ERC20DFPkg is IERC20DFPkg, IDiamondFactoryPackage {
    using BetterEfficientHashLib for bytes;

    IFacet immutable ERC20_FACET;

    constructor(PkgInit memory pkgInit) {
        /// forge-lint: disable-next-line(mixed-case-variable)
        // PkgInit memory pkgInit = abi.decode(initData, (PkgInit));
        ERC20_FACET = pkgInit.erc20Facet;
    }

    function deploy(
        IDiamondPackageCallBackFactory factory,
        string calldata name_,
        string calldata symbol,
        uint8 decimals,
        uint256 totalSupply,
        address recipient,
        bytes32 optionalSalt
    ) public returns (IERC20 token) {
        return deploy(
            factory,
            PkgArgs({
                name: name_,
                symbol: symbol,
                decimals: decimals,
                totalSupply: totalSupply,
                recipient: recipient,
                optionalSalt: optionalSalt
            })
        );
    }

    function deploy(IDiamondPackageCallBackFactory factory, PkgArgs memory pkgArgs) public returns (IERC20 token) {
        return IERC20(factory.deploy(this, abi.encode(pkgArgs)));
    }

    /* -------------------------------------------------------------------------- */
    /*                           IDiamondFactoryPackage                           */
    /* -------------------------------------------------------------------------- */

    function packageName() public pure returns (string memory name_) {
        return type(ERC20DFPkg).name;
    }

    function facetInterfaces() public view returns (bytes4[] memory interfaces) {
        return ERC20_FACET.facetInterfaces();
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](1);
        facetAddresses_[0] = address(ERC20_FACET);
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
        facetCuts_ = new IDiamond.FacetCut[](1);

        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_FACET.facetFuncs()
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
        if (decodedArgs.totalSupply > 0) {
            ERC20Repo._mint(decodedArgs.recipient, decodedArgs.totalSupply);
        }
    }

    // account
    function postDeploy(address) public pure returns (bool) {
        return true;
    }
}
