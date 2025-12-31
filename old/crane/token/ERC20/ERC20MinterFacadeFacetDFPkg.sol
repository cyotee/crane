// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {ICreate3Aware} from "contracts/crane/interfaces/ICreate3Aware.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "contracts/crane/interfaces/IDiamondFactoryPackage.sol";
import {IDiamond} from "contracts/crane/interfaces/IDiamond.sol";
import {IOwnable} from "contracts/crane/interfaces/IOwnable.sol";
import {OwnableModifiers} from "contracts/crane/access/ownable/OwnableModifiers.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IERC20MinterFacade} from "contracts/crane/interfaces/IERC20MinterFacade.sol";

struct ERC20MinterFacadeLayout {
    uint256 maxMintAmount;
}

library ERC20MinterFacadeRepo {
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (ERC20MinterFacadeLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
}

abstract contract ERC20MinterFacadeFacetDFPkgStorage {
    using ERC20MinterFacadeRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(ERC20MinterFacadeRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE =
    // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
    // https://eips.ethereum.org/EIPS/eip-20
    type(IERC20MinterFacade).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_erc20MinterFacade()[]
    /**
     * @dev internal hook for the default storage range used by this contract.
     * @return The default storage range used with repos.
     */
    function _erc20MinterFacade() internal pure virtual returns (ERC20MinterFacadeLayout storage) {
        return STORAGE_SLOT._layout();
    }

    // end::_erc20MinterFacade()[]

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC20MinterFacade(uint256 maxMintAmount) internal {
        _erc20MinterFacade().maxMintAmount = maxMintAmount;
    }

    function _setMaxMintAmount(uint256 maxMintAmount) internal {
        _erc20MinterFacade().maxMintAmount = maxMintAmount;
    }

    function _maxMintAmount() internal view returns (uint256) {
        return _erc20MinterFacade().maxMintAmount;
    }
}

interface IERC20MinterFacadeFacetDFPkg {
    /// forge-lint: disable-next-line(pascal-case-struct)
    struct ERC20MinterFacadeFacetDFPkgInit {
        IFacet ownableFacet;
    }

    /// forge-lint: disable-next-line(pascal-case-struct)
    struct ERC20MinterFacadePkgArgs {
        address owner;
        uint256 maxMint;
    }
}

contract ERC20MinterFacadeFacetDFPkg is
    Create3AwareContract,
    ERC20MinterFacadeFacetDFPkgStorage,
    OwnableModifiers,
    IERC20MinterFacade,
    IFacet,
    IDiamondFactoryPackage,
    IERC20MinterFacadeFacetDFPkg
{
    using EfficientHashLib for bytes;

    IFacet immutable SELF;
    IFacet immutable OWNABLE_FACET;

    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        SELF = this;
        ERC20MinterFacadeFacetDFPkgInit memory pkgInit =
            abi.decode(create3InitData.initData, (ERC20MinterFacadeFacetDFPkgInit));
        OWNABLE_FACET = pkgInit.ownableFacet;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    /**
     * @custom:selector 0x2ea80826
     */
    function facetInterfaces()
        public
        pure
        override(IFacet, IDiamondFactoryPackage)
        returns (bytes4[] memory interfaces)
    {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IOwnable).interfaceId;
        interfaces[1] = type(IERC20MinterFacade).interfaceId;
    }

    /**
     * @custom:selector 0x574a4cff
     */
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IERC20MinterFacade.maxMintAmount.selector;
        funcs[1] = IERC20MinterFacade.setMaxMintAmount.selector;
        funcs[2] = IERC20MinterFacade.mint.selector;
    }

    /* ---------------------------------------------------------------------- */
    /*                         IDiamondFactoryPackage                         */
    /* ---------------------------------------------------------------------- */

    /**
     * @return facetCuts_ The IDiamond.FacetCut array to configuring a proxy with this package.
     * @custom:selector 0xa4b3ad35
     */
    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](4);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(OWNABLE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[3] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(SELF),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: facetFuncs()
        });
    }

    /**
     * @return config Unified function to retrieved `facetInterfaces()` AND `facetCuts()` in one call.
     * @custom:selector 0x65d375b3
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    /**
     * @custom:selector 0xd82be56e
     */
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        ERC20MinterFacadePkgArgs memory args = abi.decode(pkgArgs, (ERC20MinterFacadePkgArgs));
        // return keccak256(abi.encode(args.owner));
        return abi.encode(args.owner).hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        return pkgArgs;
    }

    function updatePkg(address, bytes memory) public pure returns (bool) {
        return true;
    }

    /**
     * @dev A standardized proxy initialization function.
     * @custom:selector 0x87d48380
     */
    function initAccount(bytes memory initArgs) public {
        ERC20MinterFacadePkgArgs memory args = abi.decode(initArgs, (ERC20MinterFacadePkgArgs));
        _initERC20MinterFacade(args.maxMint);
        _initOwnable(args.owner);
    }

    // TODO Make return bytes to pass post deploy results to account.
    /**
     * @custom:selector 0x70068fcf
     */
    function postDeploy(address) public pure returns (bytes memory postDeployData) {
        return "";
    }

    /* ---------------------------------------------------------------------- */
    /*                           IERC20MinterFacade                           */
    /* ---------------------------------------------------------------------- */

    function maxMintAmount() public view returns (uint256) {
        return _maxMintAmount();
    }

    function setMaxMintAmount(uint256 maxMintAmount_) public onlyOwner returns (bool result) {
        _setMaxMintAmount(maxMintAmount_);
        return true;
    }

    function mint(IERC20MintBurn token, address to, uint256 amount) public returns (uint256 actual) {
        uint256 maxMintAmount_ = maxMintAmount();
        if (amount > maxMintAmount_) {
            amount = maxMintAmount_;
        }
        token.mint(to, amount);
        return amount;
    }
}
