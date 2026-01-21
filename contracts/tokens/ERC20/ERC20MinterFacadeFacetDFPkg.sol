// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IERC20MinterFacade} from "@crane/contracts/tokens/ERC20/IERC20MinterFacade.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {ERC20MinterFacadeRepo} from "@crane/contracts/tokens/ERC20/ERC20MinterFacadeRepo.sol";
import {ERC20MinterFacadeFacet} from "@crane/contracts/tokens/ERC20/ERC20MinterFacadeFacet.sol";

interface IERC20MinterFacadeFacetDFPkg is IDiamondFactoryPackage {
    struct PkgArgs {
        uint256 maxMintAmount;
        uint256 minMintInterval;
    }
}

contract ERC20MinterFacadeFacetDFPkg is ERC20MinterFacadeFacet, IERC20MinterFacadeFacetDFPkg {
    using BetterEfficientHashLib for bytes;

    address immutable SELF;

    constructor() {
        SELF = address(this);
    }

    function packageName() public pure returns (string memory name_) {
        return type(ERC20MinterFacadeFacetDFPkg).name;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](1);
        facetAddresses_[0] = address(SELF);
    }

    function facetInterfaces() public pure virtual override(ERC20MinterFacadeFacet, IDiamondFactoryPackage) returns (bytes4[] memory interfaces)
    {
        interfaces = new bytes4[](1);

        interfaces[0] = type(IERC20MinterFacade).interfaceId;
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
            facetAddress: address(SELF),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: facetFuncs()
        });
    }

    /**
     * @return config Unified function to retrieved `facetInterfaces()` AND `facetCuts()` in one call.
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        return pkgArgs._hash();
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
        (PkgArgs memory decodedArgs) = abi.decode(initArgs, (PkgArgs));
        ERC20MinterFacadeRepo._initialize(
            // uint256 maxMintAmount,
            decodedArgs.maxMintAmount,
            // uint256 minMintInterval,
            decodedArgs.minMintInterval
        );
    }

    // account
    function postDeploy(address) public pure returns (bool) {
        return true;
    }
}