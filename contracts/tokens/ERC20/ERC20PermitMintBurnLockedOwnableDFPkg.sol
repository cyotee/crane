// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20 as OZIERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {ERC20MintBurnOwnableStorage} from "@crane/contracts/crane/token/ERC20/utils/ERC20MintBurnOwnableStorage.sol";
// import {BetterIERC20 as IERC20} from "@crane/contracts/crane/interfaces/BetterIERC20.sol";
import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {IERC20MintBurn} from "@crane/contracts/interfaces/IERC20MintBurn.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "@crane/contracts/interfaces/ICreate3Aware.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

interface IERC20PermitMintBurnLockedOwnableDFPkg {
    struct PkgInit {
        IFacet erc20Facet;
        IFacet erc5267Facet;
        IFacet erc2612Facet;
        IFacet erc20MintBurnOwnableFacet;
    }

    struct PkgArgs {
        string name;
        string symbol;
        uint8 decimals;
        address owner;
        bytes32 optionalSalt;
    }
}

contract ERC20PermitMintBurnLockedOwnableDFPkg is

    // Create3AwareContract,
    IDiamondFactoryPackage,
    IERC20PermitMintBurnLockedOwnableDFPkg
{
    IFacet immutable ERC20_FACET;
    IFacet immutable ERC5267_FACET;
    IFacet immutable ERC2612_FACET;
    IFacet public immutable ERC20_MINT_BURN_OWNABLE_FACET;

    constructor(PkgInit memory pkgInit) {
        // PkgInit memory pkgInit = abi.decode(create3InitData.initData, (PkgInit));
        ERC20_FACET = pkgInit.erc20Facet;
        ERC5267_FACET = pkgInit.erc5267Facet;
        ERC2612_FACET = pkgInit.erc2612Facet;
        ERC20_MINT_BURN_OWNABLE_FACET = pkgInit.erc20MintBurnOwnableFacet;
    }

    function packageName() public pure returns (string memory name_) {
        return type(ERC20PermitMintBurnLockedOwnableDFPkg).name;
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
        facetAddresses_ = new address[](4);
        facetAddresses_[0] = address(ERC20_FACET);
        facetAddresses_[1] = address(ERC5267_FACET);
        facetAddresses_[2] = address(ERC2612_FACET);
        facetAddresses_[3] = address(ERC20_MINT_BURN_OWNABLE_FACET);
    }

    function facetInterfaces()
        public
        pure
        virtual
        override(IDiamondFactoryPackage)
        returns (bytes4[] memory interfaces)
    {
        interfaces = new bytes4[](6);
        interfaces[0] = type(OZIERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(OZIERC20).interfaceId;
        interfaces[3] = type(IERC20Permit).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;
        interfaces[5] = type(IERC20MintBurn).interfaceId;
    }

    function facetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](2);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_FACET.facetFuncs()
        });
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC5267_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_FACET.facetFuncs()
        });
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC2612_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC2612_FACET.facetFuncs()
        });

        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_MINT_BURN_OWNABLE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_MINT_BURN_OWNABLE_FACET.facetFuncs()
        });
    }

    function diamondConfig() public view virtual returns (IDiamondFactoryPackage.DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        salt = keccak256(abi.encode(pkgArgs));
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
        (PkgArgs memory pkgArgs) = abi.decode(initArgs, (PkgArgs));
        ERC20Repo._initialize(
            // string memory name,
            pkgArgs.name,
            // string memory symbol,
            pkgArgs.symbol,
            // uint8 decimals,
            pkgArgs.decimals
        );
        EIP712Repo._initialize(
            // string memory name,
            pkgArgs.name,
            // string memory version
            "1"
        );
        MultiStepOwnableRepo._initialize(
            // address initialOwner,
            pkgArgs.owner,
            // uint256 lockDuration
            1 days
        );
    }

    // account
    function postDeploy(address) public virtual returns (bool) {
        return true;
    }
}
