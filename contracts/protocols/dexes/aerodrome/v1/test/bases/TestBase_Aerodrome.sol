// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import {ManagedRewardsFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/factories/ManagedRewardsFactory.sol";
import {VotingRewardsFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/factories/VotingRewardsFactory.sol";
import {GaugeFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/factories/GaugeFactory.sol";
import {PoolFactory, IPoolFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/factories/PoolFactory.sol";
import {IFactoryRegistry, FactoryRegistry} from "@crane/contracts/protocols/dexes/aerodrome/v1/factories/FactoryRegistry.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {IMinter, Minter} from "@crane/contracts/protocols/dexes/aerodrome/v1/Minter.sol";
import {IReward, Reward} from "@crane/contracts/protocols/dexes/aerodrome/v1/rewards/Reward.sol";
import {FeesVotingReward} from "@crane/contracts/protocols/dexes/aerodrome/v1/rewards/FeesVotingReward.sol";
import {BribeVotingReward} from "@crane/contracts/protocols/dexes/aerodrome/v1/rewards/BribeVotingReward.sol";
import {FreeManagedReward} from "@crane/contracts/protocols/dexes/aerodrome/v1/rewards/FreeManagedReward.sol";
import {LockedManagedReward} from "@crane/contracts/protocols/dexes/aerodrome/v1/rewards/LockedManagedReward.sol";
import {IGauge, Gauge} from "@crane/contracts/protocols/dexes/aerodrome/v1/gauges/Gauge.sol";
import {PoolFees} from "@crane/contracts/protocols/dexes/aerodrome/v1/PoolFees.sol";
import {RewardsDistributor, IRewardsDistributor} from "@crane/contracts/protocols/dexes/aerodrome/v1/RewardsDistributor.sol";
import {IAirdropDistributor, AirdropDistributor} from "@crane/contracts/protocols/dexes/aerodrome/v1/AirdropDistributor.sol";
import {IRouter, Router} from "@crane/contracts/protocols/dexes/aerodrome/v1/Router.sol";
import {IAero, Aero} from "@crane/contracts/protocols/dexes/aerodrome/v1/Aero.sol";
import {IVoter, Voter} from "@crane/contracts/protocols/dexes/aerodrome/v1/Voter.sol";
import {VeArtProxy} from "@crane/contracts/protocols/dexes/aerodrome/v1/VeArtProxy.sol";
import {IVotingEscrow, VotingEscrow} from "@crane/contracts/protocols/dexes/aerodrome/v1/VotingEscrow.sol";
import {ProtocolGovernor} from "@crane/contracts/protocols/dexes/aerodrome/v1/ProtocolGovernor.sol";
import {EpochGovernor} from "@crane/contracts/protocols/dexes/aerodrome/v1/EpochGovernor.sol";
import {SafeCastLibrary} from "@crane/contracts/protocols/dexes/aerodrome/v1/libraries/SafeCastLibrary.sol";
import {IWETH} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SigUtils} from "@crane/contracts/protocols/dexes/aerodrome/v1/test/SigUtils.sol";
import {Forwarder} from "@opengsn/contracts/src/forwarder/Forwarder.sol";
import {BetterTest} from "@crane/contracts/test/BetterTest.sol";

contract TestBase_Aerodrome is BetterTest {

    IWETH public WETH;
    Aero public AERO;
    address[] public aeroGaugeTokens;

    address team = makeAddr("team");
    address emergencyCouncil = makeAddr("emergencyCouncil");
    address feeManager = makeAddr("feeManager");

    /// @dev Core Deployment
    Forwarder public forwarder;
    Pool public implementation;
    Router public router;
    VotingEscrow public escrow;
    VeArtProxy public artProxy;
    PoolFactory public factory;
    FactoryRegistry public factoryRegistry;
    GaugeFactory public gaugeFactory;
    VotingRewardsFactory public votingRewardsFactory;
    ManagedRewardsFactory public managedRewardsFactory;
    Voter public voter;
    RewardsDistributor public distributor;
    Minter public minter;
    AirdropDistributor public airdrop;
    Gauge public gauge;
    ProtocolGovernor public governor;
    EpochGovernor public epochGovernor;

    /// @dev Global address to set
    address public allowedManager;

    function setUp() public virtual {
        implementation = new Pool();
        factory = new PoolFactory(address(implementation));

        votingRewardsFactory = new VotingRewardsFactory();
        gaugeFactory = new GaugeFactory();
        managedRewardsFactory = new ManagedRewardsFactory();
        factoryRegistry = new FactoryRegistry(
            address(factory),
            address(votingRewardsFactory),
            address(gaugeFactory),
            address(managedRewardsFactory)
        );
        forwarder = new Forwarder();

        escrow = new VotingEscrow(address(forwarder), address(AERO), address(factoryRegistry));
        artProxy = new VeArtProxy(address(escrow));
        escrow.setArtProxy(address(artProxy));

        // Setup voter and distributor
        distributor = new RewardsDistributor(address(escrow));
        voter = new Voter(address(forwarder), address(escrow), address(factoryRegistry));

        escrow.setVoterAndDistributor(address(voter), address(distributor));
        escrow.setAllowedManager(allowedManager);

        // Setup router
        router = new Router(
            address(forwarder),
            address(factoryRegistry),
            address(factory),
            address(voter),
            address(WETH)
        );

        // Setup minter
        minter = new Minter(address(voter), address(escrow), address(distributor));
        distributor.setMinter(address(minter));
        AERO.setMinter(address(minter));

        airdrop = new AirdropDistributor(address(escrow));

        /// @dev tokens are already set in the respective setupBefore()
        voter.initialize(aeroGaugeTokens, address(minter));

        // Set protocol state to team
        escrow.setTeam(team);
        minter.setTeam(team);
        factory.setPauser(team);
        voter.setEmergencyCouncil(emergencyCouncil);
        voter.setEpochGovernor(team);
        voter.setGovernor(team);
        factoryRegistry.transferOwnership(team);

        // Set contract vars
        factory.setFeeManager(feeManager);
        factory.setVoter(address(voter));

    }

}