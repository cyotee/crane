// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ManagedRewardsFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/ManagedRewardsFactory.sol";
import {VotingRewardsFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/VotingRewardsFactory.sol";
import {GaugeFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/GaugeFactory.sol";
import {PoolFactory, IPoolFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/PoolFactory.sol";
import {IFactoryRegistry, FactoryRegistry} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/FactoryRegistry.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";
import {IMinter, Minter} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Minter.sol";
import {IReward, Reward} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/rewards/Reward.sol";
import {FeesVotingReward} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/rewards/FeesVotingReward.sol";
import {BribeVotingReward} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/rewards/BribeVotingReward.sol";
import {FreeManagedReward} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/rewards/FreeManagedReward.sol";
import {LockedManagedReward} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/rewards/LockedManagedReward.sol";
import {IGauge, Gauge} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/gauges/Gauge.sol";
import {PoolFees} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/PoolFees.sol";
import {RewardsDistributor, IRewardsDistributor} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/RewardsDistributor.sol";
import {IAirdropDistributor, AirdropDistributor} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/AirdropDistributor.sol";
import {IRouter, Router} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Router.sol";
import {IAero, Aero} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Aero.sol";
import {IVoter, Voter} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Voter.sol";
import {VeArtProxy} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/VeArtProxy.sol";
import {IVotingEscrow, VotingEscrow} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/VotingEscrow.sol";
import {ProtocolGovernor} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/ProtocolGovernor.sol";
import {EpochGovernor} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/EpochGovernor.sol";
import {SafeCastLibrary} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/libraries/SafeCastLibrary.sol";
import {IWETH} from "@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC20} from "@crane/contracts/external/openzeppelin/token/ERC20/ERC20.sol";
import {SigUtils} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/test/SigUtils.sol";
import {Forwarder} from "@crane/contracts/protocols/utils/gsn/forwarder/Forwarder.sol";
import {BetterTest} from "@crane/contracts/test/BetterTest.sol";
import {TestBase_Weth9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol";

contract TestBase_Aerodrome is TestBase_Weth9 {

    address team = makeAddr("team");
    address emergencyCouncil = makeAddr("emergencyCouncil");
    address feeManager = makeAddr("feeManager");

    // IWETH public WETH;
    Aero public AERO;
    address[] public aeroGaugeTokens;


    /// @dev Core Deployment
    Forwarder public aeroFowarder;
    Pool public aeroPoolImplementation;
    Router public aerodromeRouter;
    VotingEscrow public aeroEsrow;
    VeArtProxy public aeroArtProxy;
    PoolFactory public aerodromePoolFactory;
    FactoryRegistry public aerodromePoolFactoryRegistry;
    GaugeFactory public aeroGuageFactory;
    VotingRewardsFactory public aeroVotingRewardsFactory;
    ManagedRewardsFactory public aeroManagedRewardsFactory;
    Voter public aeroVoter;
    RewardsDistributor public aeroDistributor;
    Minter public aeroMinter;
    AirdropDistributor public aeroAirdrop;
    Gauge public aeroGauge;
    ProtocolGovernor public aeroGovernor;
    EpochGovernor public aeroEpochGovernor;

    /// @dev Global address to set
    address public aeroAllowedManager;

    function setUp() public virtual override {
        // console.log("TestBase_Aerodrome.setUp: start");
        TestBase_Weth9.setUp();
        // Deploy native AERO token before base setup so downstream constructors can interact with it
        if (address(AERO) == address(0)) {
            AERO = new Aero();
            vm.label(address(AERO), type(IAero).name);
            aeroPoolImplementation = new Pool();
            vm.label(address(aeroPoolImplementation), "aeroPoolImplementation");
            aerodromePoolFactory = new PoolFactory(address(aeroPoolImplementation));
            vm.label(address(aerodromePoolFactory), "aerodromePoolFactory");
            aeroVotingRewardsFactory = new VotingRewardsFactory();
            vm.label(address(aeroVotingRewardsFactory), "aeroVotingRewardsFactory");
            aeroGuageFactory = new GaugeFactory();
            vm.label(address(aeroGuageFactory), "aeroGuageFactory");
            aeroManagedRewardsFactory = new ManagedRewardsFactory();
            vm.label(address(aeroManagedRewardsFactory), "aeroManagedRewardsFactory");
            aerodromePoolFactoryRegistry = new FactoryRegistry(
                address(aerodromePoolFactory),
                address(aeroVotingRewardsFactory),
                address(aeroGuageFactory),
                address(aeroManagedRewardsFactory)
            );
            vm.label(address(aerodromePoolFactoryRegistry), "aerodromePoolFactoryRegistry");
            aeroFowarder = new Forwarder();
            vm.label(address(aeroFowarder), "aeroFowarder");
            aeroEsrow = new VotingEscrow(address(aeroFowarder), address(AERO), address(aerodromePoolFactoryRegistry));
            vm.label(address(aeroEsrow), "aeroEsrow");
            aeroArtProxy = new VeArtProxy(address(aeroEsrow));
            vm.label(address(aeroArtProxy), "aeroArtProxy");
            aeroEsrow.setArtProxy(address(aeroArtProxy));
            aeroDistributor = new RewardsDistributor(address(aeroEsrow));
            vm.label(address(aeroDistributor), "aeroDistributor");
            aeroVoter = new Voter(address(aeroFowarder), address(aeroEsrow), address(aerodromePoolFactoryRegistry));
            vm.label(address(aeroVoter), "aeroVoter");
            aeroEsrow.setVoterAndDistributor(address(aeroVoter), address(aeroDistributor));
            if (aeroAllowedManager != address(0)) {
                aeroEsrow.setAllowedManager(aeroAllowedManager);
            }
            aerodromeRouter = new Router(
                address(aeroFowarder),
                address(aerodromePoolFactoryRegistry),
                address(aerodromePoolFactory),
                address(aeroVoter),
                address(weth)
            );
            vm.label(address(aerodromeRouter), "aerodromeRouter");
            aeroMinter = new Minter(address(aeroVoter), address(aeroEsrow), address(aeroDistributor));
            vm.label(address(aeroMinter), "aeroMinter");
            aeroDistributor.setMinter(address(aeroMinter));
            AERO.setMinter(address(aeroMinter));
            aeroAirdrop = new AirdropDistributor(address(aeroEsrow));
            vm.label(address(aeroAirdrop), "aeroAirdrop");

            /// @dev tokens are already set in the respective setupBefore()
            aeroVoter.initialize(aeroGaugeTokens, address(aeroMinter));

            // Set protocol state to team
            aeroEsrow.setTeam(team);
            aeroMinter.setTeam(team);
            aerodromePoolFactory.setPauser(team);
            aeroVoter.setEmergencyCouncil(emergencyCouncil);
            aeroVoter.setEpochGovernor(team);
            aeroVoter.setGovernor(team);
            aerodromePoolFactoryRegistry.transferOwnership(team);

            // Set contract vars
            aerodromePoolFactory.setFeeManager(feeManager);
            aerodromePoolFactory.setVoter(address(aeroVoter));

        }
    }

}