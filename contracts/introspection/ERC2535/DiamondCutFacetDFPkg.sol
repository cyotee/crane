// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterAddress as Address} from "@crane/contracts/utils/BetterAddress.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {DiamondCutTarget} from "@crane/contracts/introspection/ERC2535/DiamondCutTarget.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "@crane/contracts/interfaces/ICreate3Aware.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

interface IDiamondCutFacetDFPkg {
    struct PkgInit {
        IFacet MULTI_STEP_OWNABLE_FACET;
    }

    struct PkgArgs {
        address owner;
        // bytes diamondCutData;
        IDiamond.FacetCut[] diamondCut;
        bytes4[] supportedInterfaces;
        address initTarget;
        bytes initCalldata;
    }
}

contract DiamondCutFacetDFPkg is DiamondCutTarget, IDiamondFactoryPackage, IDiamondCutFacetDFPkg {
    using Address for address;

    IDiamondFactoryPackage immutable SELF;
    IFacet immutable MULTI_STEP_OWNABLE_FACET;

    constructor(PkgInit memory pkgInitArgs) {
        // PkgInit memory pkgInitArgs = abi.decode(create3InitData.initData, (PkgInit));
        SELF = this;
        MULTI_STEP_OWNABLE_FACET = pkgInitArgs.MULTI_STEP_OWNABLE_FACET;
    }

    function packageName() public pure returns (string memory name_) {
        return type(DiamondCutFacetDFPkg).name;
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
        facetAddresses_ = new address[](2);
        facetAddresses_[0] = address(SELF);
        facetAddresses_[1] = address(MULTI_STEP_OWNABLE_FACET);
    }

    function facetInterfaces() public view virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IMultiStepOwnable).interfaceId;
        interfaces[1] = type(IDiamondCut).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IDiamondCut.diamondCut.selector;
    }

    function _MULTI_STEP_OWNABLE_FACETFuncs() internal view virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](8);
        funcs[0] = IMultiStepOwnable.initiateOwnershipTransfer.selector;
        funcs[1] = IMultiStepOwnable.confirmOwnershipTransfer.selector;
        funcs[2] = IMultiStepOwnable.cancelPendingOwnershipTransfer.selector;
        funcs[3] = IMultiStepOwnable.acceptOwnershipTransfer.selector;
        funcs[4] = IMultiStepOwnable.owner.selector;
        funcs[5] = IMultiStepOwnable.pendingOwner.selector;
        funcs[6] = IMultiStepOwnable.preConfirmedOwner.selector;
        funcs[7] = IMultiStepOwnable.getOwnershipTransferBuffer.selector;
    }

    function facetCuts() public view virtual override returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](2);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(MULTI_STEP_OWNABLE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: MULTI_STEP_OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(SELF),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: facetFuncs()
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

    function initAccount(bytes memory initArgs) public virtual override {
        (PkgArgs memory accountInit) = abi.decode(initArgs, (PkgArgs));
        MultiStepOwnableRepo._initialize(accountInit.owner, 1 days);
        if (accountInit.diamondCut.length > 0) {
            ERC2535Repo._diamondCut(accountInit.diamondCut, accountInit.initTarget, accountInit.initCalldata);
        }
        if (accountInit.supportedInterfaces.length > 0) {
            ERC165Repo._registerInterfaces(accountInit.supportedInterfaces);
        }
    }

    /**
     * @dev account The address of the account on which to call the post-deploy hook.
     * @return postDeployData The data to be returned from the post-deploy hook.
     */
    function postDeploy(address) public virtual returns (bool) {
        return true;
    }
}
