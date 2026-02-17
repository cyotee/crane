// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

interface ICREATE3DFPkg is IDiamondFactoryPackage {
    struct PkgInit {
        // IFacet erc165Facet;
        // IFacet diamondLoupeFacet;
        // IFacet erc8109IntrospectionFacet;
        // IFacet postDeployHookFacet;
        IFacet diamondCutFacet;
        IFacet multiStepOwnableFacet;
        IFacet operableFacet;
        IFacet create3FactoryFacet;
        IFacet facetRegistryFacet;
        IFacet packageRegistryFacet;
        IDiamondPackageCallBackFactory diamondFactory;
    }

    struct PkgArgs {
        address owner;
    }

    function deployCreate3Factory(address owner) external returns(ICreate3FactoryProxy);
}

contract Create3FactoryDFPkg is ICREATE3DFPkg {
    using BetterEfficientHashLib for bytes;

    ICREATE3DFPkg immutable SELF;

    // IFacet public immutable ERC165_FACET;
    // IFacet public immutable DIAMOND_LOUPE_FACET;
    // IFacet public immutable ERC8109_INTROSPECTION_FACET;
    // IFacet public immutable POST_DEPLOY_HOOK_FACET;
    IFacet public immutable DIAMOND_CUT_FACET;
    IFacet public immutable MULTI_STEP_OWNABLE_FACET;
    IFacet public immutable OPERABLE_FACET;
    IFacet public immutable CREATE3_FACTORY_FACET;
    IFacet public immutable FACET_REGISTRY_FACET;
    IFacet public immutable DIAMOND_FACTORY_PACKAGE_FACET;

    IDiamondPackageCallBackFactory public immutable DIAMOND_FACTORY;

    constructor(PkgInit memory pkgInit) {
        SELF = this;
        // ERC165_FACET = pkgInit.erc165Facet;
        // DIAMOND_LOUPE_FACET = pkgInit.diamondLoupeFacet;
        // ERC8109_INTROSPECTION_FACET = pkgInit.erc8109IntrospectionFacet;
        // POST_DEPLOY_HOOK_FACET = pkgInit.postDeployHookFacet;
        DIAMOND_CUT_FACET = pkgInit.diamondCutFacet;
        MULTI_STEP_OWNABLE_FACET = pkgInit.multiStepOwnableFacet;
        OPERABLE_FACET = pkgInit.operableFacet;
        CREATE3_FACTORY_FACET = pkgInit.create3FactoryFacet;
        FACET_REGISTRY_FACET = pkgInit.facetRegistryFacet;
        DIAMOND_FACTORY_PACKAGE_FACET = pkgInit.packageRegistryFacet;
        DIAMOND_FACTORY = pkgInit.diamondFactory;
    }

    function deployCreate3Factory(address owner) external returns(ICreate3FactoryProxy) {
        return ICreate3FactoryProxy(
            DIAMOND_FACTORY.deploy(
                SELF,
                abi.encode(PkgArgs({owner: owner}))
            )
        );
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function packageName() public pure returns (string memory name_) {
        return type(Create3FactoryDFPkg).name;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        return (packageName(), facetInterfaces(), facetAddresses());
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](6);
        facetAddresses_[0] = address(DIAMOND_CUT_FACET);
        facetAddresses_[1] = address(MULTI_STEP_OWNABLE_FACET);
        facetAddresses_[2] = address(OPERABLE_FACET);
        facetAddresses_[3] = address(CREATE3_FACTORY_FACET);
        facetAddresses_[4] = address(FACET_REGISTRY_FACET);
        facetAddresses_[5] = address(DIAMOND_FACTORY_PACKAGE_FACET);
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](6);
        interfaces[0] = type(IDiamondCut).interfaceId;
        interfaces[1] = type(IMultiStepOwnable).interfaceId;
        interfaces[2] = type(IOperable).interfaceId;
        interfaces[3] = type(ICreate3Factory).interfaceId;
        interfaces[4] = type(IFacetRegistry).interfaceId;
        interfaces[5] = type(IDiamondFactoryPackageRegistry).interfaceId;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](6);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(DIAMOND_CUT_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: DIAMOND_CUT_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(MULTI_STEP_OWNABLE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: MULTI_STEP_OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[2] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(OPERABLE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: OPERABLE_FACET.facetFuncs()
        });
        facetCuts_[3] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(CREATE3_FACTORY_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: CREATE3_FACTORY_FACET.facetFuncs()
        });
        facetCuts_[4] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(FACET_REGISTRY_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: FACET_REGISTRY_FACET.facetFuncs()
        });
        facetCuts_[5] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(DIAMOND_FACTORY_PACKAGE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: DIAMOND_FACTORY_PACKAGE_FACET.facetFuncs()
        });
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        return pkgArgs._hash();
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        return pkgArgs;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function updatePkg(
        address,
        /* expectedProxy */
        bytes memory /* pkgArgs */
    )
        public
        pure
        returns (bool)
    {
        return true;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function initAccount(bytes memory initArgs) public {
        (PkgArgs memory accountInit) = abi.decode(initArgs, (PkgArgs));
        MultiStepOwnableRepo._initialize(accountInit.owner, 1 days);
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function postDeploy(address /*account*/) public pure returns (bool) {
        return true;
    }
}
