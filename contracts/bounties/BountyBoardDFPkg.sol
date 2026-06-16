// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";
import {ICallTargetRegistryManagement} from "@crane/contracts/interfaces/ICallTargetRegistryManagement.sol";
import {IBountyCommon} from "@crane/contracts/bounties/common/IBountyCommon.sol";
import {IArbitrable} from "@crane/contracts/interfaces/IArbitrable.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {BountyBoardConfigRepo} from "@crane/contracts/bounties/common/BountyBoardConfigRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

// Type specific interfaces (to be defined in subdirs)
import {ISingleFinalBounty} from "@crane/contracts/bounties/single/ISingleFinalBounty.sol";
import {IMilestoneBounty} from "@crane/contracts/bounties/milestone/IMilestoneBounty.sol";
import {IContestBounty} from "@crane/contracts/bounties/contest/IContestBounty.sol";
import {IContinuousBounty} from "@crane/contracts/bounties/continuous/IContinuousBounty.sol";

// tag::IBountyBoardDFPkg[]
interface IBountyBoardDFPkg is IDiamondFactoryPackage {
    // tag::PkgInit[]
    /// @dev Constructor args for the BountyBoardDFPkg. Contains the canonical facets
    ///      that will be bundled into the BountyBoard Diamond (Cut + ownership + common + all bounty type facets).
    struct PkgInit {
        IFacet diamondCutFacet;
        IFacet multiStepOwnableFacet;
        IFacet bountyCommonFacet;
        IFacet singleFinalBountyFacet;
        IFacet milestoneBountyFacet;
        IFacet contestBountyFacet;
        IFacet continuousBountyFacet;
        IDiamondPackageCallBackFactory diamondFactory;
    }
    // end::PkgInit[]

    // tag::PkgArgs[]
    /// @dev Args passed when deploying a BountyBoard instance via the DFPkg.
    struct PkgArgs {
        address owner;
        address configOracle;
        address arbitratorOverride; // 0 = use oracle
    }
    // end::PkgArgs[]

    // tag::deployBountyBoard(address,address,address)[]
    /// @notice Deploys a fully configured BountyBoard Diamond proxy (with supporting facets for common + single/milestone/contest/continuous bounties).
    /// @param owner Initial owner (receives MultiStepOwnable control).
    /// @param configOracle Address providing bounty board configuration.
    /// @param arbitratorOverride Optional arbitrator override (pass 0 to use the configOracle).
    /// @return The deployed IDiamond (BountyBoard proxy).
    /// @custom:signature deployBountyBoard(address,address,address)
    function deployBountyBoard(address owner, address configOracle, address arbitratorOverride) external returns (IDiamond);
    // end::deployBountyBoard(address,address,address)[]
}
// end::IBountyBoardDFPkg[]

// tag::BountyBoardDFPkg[]
contract BountyBoardDFPkg is IBountyBoardDFPkg {
    using BetterEfficientHashLib for bytes;

    IBountyBoardDFPkg immutable SELF;

    IFacet public immutable DIAMOND_CUT_FACET;
    IFacet public immutable MULTI_STEP_OWNABLE_FACET;
    IFacet public immutable BOUNTY_COMMON_FACET;
    IFacet public immutable SINGLE_FINAL_BOUNTY_FACET;
    IFacet public immutable MILESTONE_BOUNTY_FACET;
    IFacet public immutable CONTEST_BOUNTY_FACET;
    IFacet public immutable CONTINUOUS_BOUNTY_FACET;
    IDiamondPackageCallBackFactory public immutable DIAMOND_FACTORY;

    // tag::constructor(IBountyBoardDFPkg.PkgInit)[]
    /// @notice Constructs the package, capturing all facet references that will be attached
    ///         to every BountyBoard Diamond deployed from it.
    constructor(PkgInit memory pkgInit) {
        SELF = this;
        DIAMOND_CUT_FACET = pkgInit.diamondCutFacet;
        MULTI_STEP_OWNABLE_FACET = pkgInit.multiStepOwnableFacet;
        BOUNTY_COMMON_FACET = pkgInit.bountyCommonFacet;
        SINGLE_FINAL_BOUNTY_FACET = pkgInit.singleFinalBountyFacet;
        MILESTONE_BOUNTY_FACET = pkgInit.milestoneBountyFacet;
        CONTEST_BOUNTY_FACET = pkgInit.contestBountyFacet;
        CONTINUOUS_BOUNTY_FACET = pkgInit.continuousBountyFacet;
        DIAMOND_FACTORY = pkgInit.diamondFactory;
    }
    // end::constructor(IBountyBoardDFPkg.PkgInit)[]

    // tag::deployBountyBoard-impl[]
    /// @notice Deploys a fully configured BountyBoard Diamond proxy (with supporting facets).
    /// @param owner Initial owner (receives MultiStepOwnable control).
    /// @param configOracle Address providing bounty board configuration.
    /// @param arbitratorOverride Optional arbitrator override (pass 0 to use the configOracle).
    /// @return The deployed IDiamond (BountyBoard proxy).
    /// @custom:signature deployBountyBoard(address,address,address)
    /// @inheritdoc IBountyBoardDFPkg
    function deployBountyBoard(address owner, address configOracle, address arbitratorOverride) external returns (IDiamond) {
        return IDiamond(
            DIAMOND_FACTORY.deploy(
                SELF,
                abi.encode(PkgArgs({owner: owner, configOracle: configOracle, arbitratorOverride: arbitratorOverride}))
            )
        );
    }
    // end::deployBountyBoard-impl[]

    /* -------------------------------------------------------------------------- */
    /*                           IDiamondFactoryPackage                           */
    /* -------------------------------------------------------------------------- */

    // tag::packageName-bountyboard[]
    /// @notice Returns the canonical name of this Diamond Factory Package.
    /// @return name_ The package name string.
    /// @custom:signature packageName()
    /// @custom:selector 0xabc8b346
    /// @inheritdoc IDiamondFactoryPackage
    function packageName() public pure returns (string memory name_) {
        return type(BountyBoardDFPkg).name;
    }
    // end::packageName-bountyboard[]

    // tag::packageMetadata-bountyboard[]
    /// @notice Returns the full metadata for this package (name, supported interfaces, facet addresses).
    /// @return name_ The package name.
    /// @return interfaces The interface IDs provided by the package's facets.
    /// @return facets The addresses of the bundled facets.
    /// @custom:signature packageMetadata()
    /// @custom:selector 0xf45469e7
    /// @inheritdoc IDiamondFactoryPackage
    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        return (packageName(), facetInterfaces(), facetAddresses());
    }
    // end::packageMetadata-bountyboard[]

    // tag::facetAddresses-bountyboard[]
    /// @notice Returns the addresses of all facet implementations provided by this DFPkg.
    /// @return facetAddresses_ Array of 7 facet addresses in package order.
    /// @custom:signature facetAddresses()
    /// @custom:selector 0x52ef6b2c
    /// @inheritdoc IDiamondFactoryPackage
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](7);
        facetAddresses_[0] = address(DIAMOND_CUT_FACET);
        facetAddresses_[1] = address(MULTI_STEP_OWNABLE_FACET);
        facetAddresses_[2] = address(BOUNTY_COMMON_FACET);
        facetAddresses_[3] = address(SINGLE_FINAL_BOUNTY_FACET);
        facetAddresses_[4] = address(MILESTONE_BOUNTY_FACET);
        facetAddresses_[5] = address(CONTEST_BOUNTY_FACET);
        facetAddresses_[6] = address(CONTINUOUS_BOUNTY_FACET);
    }
    // end::facetAddresses-bountyboard[]

    // tag::facetInterfaces-bountyboard[]
    /// @notice Returns the ERC-165 interface IDs supported by the facets in this package.
    /// @return interfaces Array of 7 interface IDs corresponding to the bundled facets.
    /// @custom:signature facetInterfaces()
    /// @custom:selector 0x2ea80826
    /// @inheritdoc IDiamondFactoryPackage
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](7);
        interfaces[0] = type(IDiamondCut).interfaceId;
        interfaces[1] = type(IMultiStepOwnable).interfaceId;
        interfaces[2] = type(IBountyCommon).interfaceId;
        interfaces[3] = type(ISingleFinalBounty).interfaceId;
        interfaces[4] = type(IMilestoneBounty).interfaceId;
        interfaces[5] = type(IContestBounty).interfaceId;
        interfaces[6] = type(IContinuousBounty).interfaceId;
    }
    // end::facetInterfaces-bountyboard[]

    // tag::facetCuts-bountyboard[]
    /// @notice Returns the facet cuts (add actions) needed to install this package's facets on a Diamond.
    /// @return facetCuts_ Array of 7 FacetCut structs for DiamondCut.
    /// @custom:signature facetCuts()
    /// @custom:selector 0xa4b3ad35
    /// @inheritdoc IDiamondFactoryPackage
    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](7);
        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(DIAMOND_CUT_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: DIAMOND_CUT_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(MULTI_STEP_OWNABLE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: MULTI_STEP_OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[2] = IDiamond.FacetCut({
            facetAddress: address(BOUNTY_COMMON_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BOUNTY_COMMON_FACET.facetFuncs()
        });
        facetCuts_[3] = IDiamond.FacetCut({
            facetAddress: address(SINGLE_FINAL_BOUNTY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: SINGLE_FINAL_BOUNTY_FACET.facetFuncs()
        });
        facetCuts_[4] = IDiamond.FacetCut({
            facetAddress: address(MILESTONE_BOUNTY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: MILESTONE_BOUNTY_FACET.facetFuncs()
        });
        facetCuts_[5] = IDiamond.FacetCut({
            facetAddress: address(CONTEST_BOUNTY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: CONTEST_BOUNTY_FACET.facetFuncs()
        });
        facetCuts_[6] = IDiamond.FacetCut({
            facetAddress: address(CONTINUOUS_BOUNTY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: CONTINUOUS_BOUNTY_FACET.facetFuncs()
        });
    }
    // end::facetCuts-bountyboard[]

    // tag::diamondConfig-bountyboard[]
    /// @notice Returns the full diamond configuration (facet cuts + interfaces) for instantiating a Diamond from this package.
    /// @return config The DiamondConfig struct containing cuts and interfaces.
    /// @custom:signature diamondConfig()
    /// @custom:selector 0x65d375b3
    /// @inheritdoc IDiamondFactoryPackage
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }
    // end::diamondConfig-bountyboard[]

    // tag::calcSalt-bountyboard[]
    /// @notice Computes the CREATE3 salt for a given package deployment args (used for deterministic proxy address).
    /// @param pkgArgs The encoded PkgArgs for the deployment.
    /// @return salt The derived bytes32 salt (hash of pkgArgs).
    /// @custom:signature calcSalt(bytes)
    /// @custom:selector 0xd82be56e
    /// @inheritdoc IDiamondFactoryPackage
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        return pkgArgs._hash();
    }
    // end::calcSalt-bountyboard[]

    // tag::processArgs-bountyboard[]
    /// @notice Processes (and here, passthrough) the package args prior to use in deployment/calc.
    /// @param pkgArgs The raw PkgArgs bytes.
    /// @return processedPkgArgs The processed bytes (identity in this impl).
    /// @custom:signature processArgs(bytes)
    /// @custom:selector 0x87c3adb3
    /// @inheritdoc IDiamondFactoryPackage
    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        return pkgArgs;
    }
    // end::processArgs-bountyboard[]

    // tag::updatePkg-bountyboard[]
    /// @notice Hook for post-deploy package update validation (returns true, no-op here).
    /// @return True (update always accepted for this package).
    /// @custom:signature updatePkg(address,bytes)
    /// @custom:selector 0xa9089235
    /// @inheritdoc IDiamondFactoryPackage
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
    // end::updatePkg-bountyboard[]

    // tag::initAccount-bountyboard[]
    /// @notice Initializes the deployed Diamond proxy account (called via delegatecall by factory). Sets up MultiStepOwnable ownership and BountyBoard config.
    /// @param initArgs The encoded PkgArgs containing the initial owner, configOracle and arbitratorOverride.
    /// @custom:signature initAccount(bytes)
    /// @custom:selector 0x870d4838
    /// @inheritdoc IDiamondFactoryPackage
    function initAccount(bytes memory initArgs) public {
        (PkgArgs memory accountInit) = abi.decode(initArgs, (PkgArgs));
        MultiStepOwnableRepo._initialize(accountInit.owner, 1 days);
        BountyBoardConfigRepo._setConfig(accountInit.configOracle, accountInit.arbitratorOverride);
    }
    // end::initAccount-bountyboard[]

    // tag::postDeploy-bountyboard[]
    /// @notice Post-deployment hook (no-op for this package; returns true).
    /// @return True to indicate success.
    /// @custom:signature postDeploy(address)
    /// @custom:selector 0x70068fcf
    /// @inheritdoc IDiamondFactoryPackage
    function postDeploy(address /*account*/)
        public
        pure
        returns (bool)
    {
        return true;
    }
    // end::postDeploy-bountyboard[]
}
// end::BountyBoardDFPkg[]
