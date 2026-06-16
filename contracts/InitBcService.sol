// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {IBCDeployer} from "battlechain-lib/interfaces/IBCDeployer.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {Create3Factory} from "@crane/contracts/factories/create3/Create3Factory.sol";
import {
    IDiamondPackageCallBackFactoryInit,
    DiamondPackageCallBackFactory
} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {ERC8109IntrospectionFacet} from "@crane/contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";
import {ICreate3FactoryBootstrap} from "@crane/contracts/interfaces/ICreate3FactoryBootstrap.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";
import {IPostDeployAccountHook} from "@crane/contracts/interfaces/IPostDeployAccountHook.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";
import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";
import {ICallTargetRegistryManagement} from "@crane/contracts/interfaces/ICallTargetRegistryManagement.sol";
import {CallTargetRegistryQueryFacet} from "@crane/contracts/registries/target/CallTargetRegistryQueryFacet.sol";
import {
    CallTargetRegistryManagementFacet
} from "@crane/contracts/registries/target/CallTargetRegistryManagementFacet.sol";
import {IBountyCommon} from "@crane/contracts/bounties/common/IBountyCommon.sol";
import {ISingleFinalBounty} from "@crane/contracts/bounties/single/ISingleFinalBounty.sol";
import {IMilestoneBounty} from "@crane/contracts/bounties/milestone/IMilestoneBounty.sol";
import {IContestBounty} from "@crane/contracts/bounties/contest/IContestBounty.sol";
import {IContinuousBounty} from "@crane/contracts/bounties/continuous/IContinuousBounty.sol";

import {Create3FactoryFacet} from "@crane/contracts/factories/create3/Create3FactoryFacet.sol";
import {FacetRegistryFacet} from "@crane/contracts/registries/facet/FacetRegistryFacet.sol";
import {
    DiamondFactoryPackageRegistryFacet
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryFacet.sol";
import {ICREATE3DFPkg, Create3FactoryDFPkg} from "@crane/contracts/factories/create3/Create3FactoryDFPkg.sol";
import {
    ICallTargetRegistryDFPkg,
    CallTargetRegistryDFPkg
} from "@crane/contracts/registries/target/CallTargetRegistryDFPkg.sol";
import {IBountyBoardDFPkg, BountyBoardDFPkg} from "@crane/contracts/bounties/BountyBoardDFPkg.sol";
import {BountyCommonFacet} from "@crane/contracts/bounties/common/BountyCommonFacet.sol";
import {SingleFinalBountyFacet} from "@crane/contracts/bounties/single/SingleFinalBountyFacet.sol";
import {MilestoneBountyFacet} from "@crane/contracts/bounties/milestone/MilestoneBountyFacet.sol";
import {ContestBountyFacet} from "@crane/contracts/bounties/contest/ContestBountyFacet.sol";
import {ContinuousBountyFacet} from "@crane/contracts/bounties/continuous/ContinuousBountyFacet.sol";
import {DiamondCutFacet} from "@crane/contracts/introspection/ERC2535/DiamondCutFacet.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {OperableFacet} from "@crane/contracts/access/operable/OperableFacet.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";

/// @notice BattleChain-aware variant of `InitDevService`. Identical bootstrap, but the
///         top-level Create3Factory is deployed through `IBCDeployer.deployCreate2`.
///         Every other contract is deployed by the Create3Factory itself, so they are
///         children-by-lineage automatically.
library InitBcService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    bytes32 constant ERC165_FACET_SALT = keccak256(abi.encode(type(ERC165Facet).name));
    bytes32 constant DIAMOND_LOUPE_FACET_SALT = keccak256(abi.encode(type(DiamondLoupeFacet).name));
    bytes32 constant ERC8109_INTROSPECTION_FACET_SALT = keccak256(abi.encode(type(ERC8109IntrospectionFacet).name));
    bytes32 constant POST_DEPLOY_HOOK_FACET_SALT = keccak256(abi.encode(type(PostDeployAccountHookFacet).name));
    bytes32 constant DIAMOND_FACTORY_SALT = keccak256(abi.encode(type(DiamondPackageCallBackFactory).name));
    bytes32 constant DIAMOND_CUT_FACET_SALT = keccak256(abi.encode(type(DiamondCutFacet).name));
    bytes32 constant MULTI_STEP_OWNABLE_FACET_SALT = keccak256(abi.encode(type(MultiStepOwnableFacet).name));
    bytes32 constant OPERABLE_FACET_SALT = keccak256(abi.encode(type(OperableFacet).name));
    bytes32 constant CREATE3_FACTORY_FACET_SALT = keccak256(abi.encode(type(Create3FactoryFacet).name));
    bytes32 constant FACET_REGISTRY_FACET_SALT = keccak256(abi.encode(type(FacetRegistryFacet).name));
    bytes32 constant DIAMOND_FACTORY_PACKAGE_FACET_SALT =
        keccak256(abi.encode(type(DiamondFactoryPackageRegistryFacet).name));
    bytes32 constant CALL_TARGET_REGISTRY_QUERY_FACET_SALT =
        keccak256(abi.encode(type(CallTargetRegistryQueryFacet).name));
    bytes32 constant CALL_TARGET_REGISTRY_MANAGEMENT_FACET_SALT =
        keccak256(abi.encode(type(CallTargetRegistryManagementFacet).name));
    bytes32 constant CREATE3_FACTORY_PACKAGE_SALT = keccak256(abi.encode(type(Create3FactoryDFPkg).name));
    bytes32 constant CALL_TARGET_REGISTRY_PACKAGE_SALT = keccak256(abi.encode(type(CallTargetRegistryDFPkg).name));
    bytes32 constant BOUNTY_COMMON_FACET_SALT = keccak256(abi.encode(type(BountyCommonFacet).name));
    bytes32 constant SINGLE_FINAL_BOUNTY_FACET_SALT = keccak256(abi.encode(type(SingleFinalBountyFacet).name));
    bytes32 constant MILESTONE_BOUNTY_FACET_SALT = keccak256(abi.encode(type(MilestoneBountyFacet).name));
    bytes32 constant CONTEST_BOUNTY_FACET_SALT = keccak256(abi.encode(type(ContestBountyFacet).name));
    bytes32 constant CONTINUOUS_BOUNTY_FACET_SALT = keccak256(abi.encode(type(ContinuousBountyFacet).name));
    bytes32 constant BOUNTY_BOARD_PACKAGE_SALT = keccak256(abi.encode(type(BountyBoardDFPkg).name));

    function initEnvBc(address owner, address bcDeployer)
        internal
        returns (ICreate3FactoryProxy factory, IDiamondPackageCallBackFactory diamondFactory)
    {
        factory = initFactoryBc(owner, keccak256(abi.encode(owner)), bcDeployer);
        diamondFactory = initDiamondFactory(factory);

        IDiamondFactoryPackage create3DFPkg_ = IDiamondFactoryPackage(
            factory.deployCanonicalPackageWithArgs(
                type(Create3FactoryDFPkg).creationCode,
                abi.encode(
                    ICREATE3DFPkg.PkgInit({
                        diamondCutFacet: IFacetRegistry(address(factory)).canonicalFacet(type(IDiamondCut).interfaceId),
                        multiStepOwnableFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IMultiStepOwnable).interfaceId),
                        operableFacet: IFacetRegistry(address(factory)).canonicalFacet(type(IOperable).interfaceId),
                        create3FactoryFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(ICreate3Factory).interfaceId),
                        facetRegistryFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IFacetRegistry).interfaceId),
                        packageRegistryFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IDiamondFactoryPackageRegistry).interfaceId),
                        callTargetRegistryQueryFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(ICallTargetRegistryQuery).interfaceId),
                        callTargetRegistryManagementFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(ICallTargetRegistryManagement).interfaceId),
                        diamondFactory: diamondFactory
                    })
                ),
                CREATE3_FACTORY_PACKAGE_SALT,
                type(ICREATE3DFPkg).interfaceId
            )
        );
        vm.label(address(create3DFPkg_), type(Create3FactoryDFPkg).name);
        Create3Factory(payable(address(factory))).initFactory();

        IDiamondFactoryPackage callTargetRegistryDFPkg_ = IDiamondFactoryPackage(
            factory.deployCanonicalPackageWithArgs(
                type(CallTargetRegistryDFPkg).creationCode,
                abi.encode(
                    ICallTargetRegistryDFPkg.PkgInit({
                        diamondCutFacet: IFacetRegistry(address(factory)).canonicalFacet(type(IDiamondCut).interfaceId),
                        multiStepOwnableFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IMultiStepOwnable).interfaceId),
                        callTargetRegistryQueryFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(ICallTargetRegistryQuery).interfaceId),
                        callTargetRegistryManagementFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(ICallTargetRegistryManagement).interfaceId),
                        diamondFactory: diamondFactory
                    })
                ),
                CALL_TARGET_REGISTRY_PACKAGE_SALT,
                type(ICallTargetRegistryDFPkg).interfaceId
            )
        );
        vm.label(address(callTargetRegistryDFPkg_), type(CallTargetRegistryDFPkg).name);

        IDiamondFactoryPackage bountyBoardDFPkg_ = IDiamondFactoryPackage(
            factory.deployCanonicalPackageWithArgs(
                type(BountyBoardDFPkg).creationCode,
                abi.encode(
                    IBountyBoardDFPkg.PkgInit({
                        diamondCutFacet: IFacetRegistry(address(factory)).canonicalFacet(type(IDiamondCut).interfaceId),
                        multiStepOwnableFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IMultiStepOwnable).interfaceId),
                        bountyCommonFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IBountyCommon).interfaceId),
                        singleFinalBountyFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(ISingleFinalBounty).interfaceId),
                        milestoneBountyFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IMilestoneBounty).interfaceId),
                        contestBountyFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IContestBounty).interfaceId),
                        continuousBountyFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IContinuousBounty).interfaceId),
                        diamondFactory: diamondFactory
                    })
                ),
                BOUNTY_BOARD_PACKAGE_SALT,
                type(IBountyBoardDFPkg).interfaceId
            )
        );
        vm.label(address(bountyBoardDFPkg_), type(BountyBoardDFPkg).name);
    }

    function initFactoryBc(address owner, bytes32 salt, address bcDeployer)
        internal
        returns (ICreate3FactoryProxy factory)
    {
        bytes memory initCode = abi.encodePacked(type(Create3Factory).creationCode, abi.encode(owner));
        factory = ICreate3FactoryProxy(IBCDeployer(bcDeployer).deployCreate2(salt, initCode));
        vm.label(address(factory), type(Create3Factory).name);

        IFacet erc165Facet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(ERC165Facet).creationCode, ERC165_FACET_SALT);
        vm.label(address(erc165Facet), type(ERC165Facet).name);

        IFacet diamondLoupeFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(DiamondLoupeFacet).creationCode, DIAMOND_LOUPE_FACET_SALT);
        vm.label(address(diamondLoupeFacet), type(DiamondLoupeFacet).name);

        IFacet erc8109IntrospectionFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(ERC8109IntrospectionFacet).creationCode, ERC8109_INTROSPECTION_FACET_SALT);
        vm.label(address(erc8109IntrospectionFacet), type(ERC8109IntrospectionFacet).name);

        IFacet postDeployAccountHookFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(PostDeployAccountHookFacet).creationCode, POST_DEPLOY_HOOK_FACET_SALT);
        vm.label(address(postDeployAccountHookFacet), type(PostDeployAccountHookFacet).name);

        IFacet diamondCutFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(DiamondCutFacet).creationCode, DIAMOND_CUT_FACET_SALT);
        vm.label(address(diamondCutFacet), type(DiamondCutFacet).name);

        IFacet multiStepOwnableFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(MultiStepOwnableFacet).creationCode, MULTI_STEP_OWNABLE_FACET_SALT);
        vm.label(address(multiStepOwnableFacet), type(MultiStepOwnableFacet).name);

        IFacet operableFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(OperableFacet).creationCode, OPERABLE_FACET_SALT);
        vm.label(address(operableFacet), type(OperableFacet).name);

        IFacet create3FactoryFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(Create3FactoryFacet).creationCode, CREATE3_FACTORY_FACET_SALT);
        vm.label(address(create3FactoryFacet), type(Create3FactoryFacet).name);

        IFacet facetRegistryFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(FacetRegistryFacet).creationCode, FACET_REGISTRY_FACET_SALT);
        vm.label(address(facetRegistryFacet), type(FacetRegistryFacet).name);

        IFacet packageRegistryFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(
                type(DiamondFactoryPackageRegistryFacet).creationCode, DIAMOND_FACTORY_PACKAGE_FACET_SALT
            );
        vm.label(address(packageRegistryFacet), type(DiamondFactoryPackageRegistryFacet).name);

        IFacet callTargetRegistryQueryFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(
                type(CallTargetRegistryQueryFacet).creationCode, CALL_TARGET_REGISTRY_QUERY_FACET_SALT
            );
        vm.label(address(callTargetRegistryQueryFacet), type(CallTargetRegistryQueryFacet).name);

        IFacet callTargetRegistryManagementFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(
                type(CallTargetRegistryManagementFacet).creationCode, CALL_TARGET_REGISTRY_MANAGEMENT_FACET_SALT
            );
        vm.label(address(callTargetRegistryManagementFacet), type(CallTargetRegistryManagementFacet).name);

        // Reuse temp to avoid stack-too-deep with many IFacet locals in initFactory
        IFacet tempFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(BountyCommonFacet).creationCode, BOUNTY_COMMON_FACET_SALT);
        vm.label(address(tempFacet), type(BountyCommonFacet).name);

        tempFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(SingleFinalBountyFacet).creationCode, SINGLE_FINAL_BOUNTY_FACET_SALT);
        vm.label(address(tempFacet), type(SingleFinalBountyFacet).name);

        tempFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(MilestoneBountyFacet).creationCode, MILESTONE_BOUNTY_FACET_SALT);
        vm.label(address(tempFacet), type(MilestoneBountyFacet).name);

        tempFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(ContestBountyFacet).creationCode, CONTEST_BOUNTY_FACET_SALT);
        vm.label(address(tempFacet), type(ContestBountyFacet).name);

        tempFacet = ICreate3FactoryBootstrap(address(factory))
            .deployCanonicalFacet(type(ContinuousBountyFacet).creationCode, CONTINUOUS_BOUNTY_FACET_SALT);
        vm.label(address(tempFacet), type(ContinuousBountyFacet).name);
    }

    function initDiamondFactory(ICreate3FactoryProxy factory)
        internal
        returns (IDiamondPackageCallBackFactory diamondFactory)
    {
        diamondFactory = IDiamondPackageCallBackFactory(
            factory.create3WithArgs(
                type(DiamondPackageCallBackFactory).creationCode,
                abi.encode(
                    IDiamondPackageCallBackFactoryInit.InitArgs({
                        erc165Facet: IFacetRegistry(address(factory)).canonicalFacet(type(IERC165).interfaceId),
                        diamondLoupeFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IDiamondLoupe).interfaceId),
                        erc8109IntrospectionFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IERC8109Introspection).interfaceId),
                        postDeployHookFacet: IFacetRegistry(address(factory))
                            .canonicalFacet(type(IPostDeployAccountHook).interfaceId)
                    })
                ),
                DIAMOND_FACTORY_SALT
            )
        );
        factory.setDiamondPackageFactory(diamondFactory);
        vm.label(address(diamondFactory), "DiamondPackageCallBackFactory");
    }
}
