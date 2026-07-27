// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {Aero} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Aero.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";
import {PoolFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/PoolFactory.sol";
import {VotingRewardsFactory} from
    "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/VotingRewardsFactory.sol";
import {GaugeFactory} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/GaugeFactory.sol";
import {ManagedRewardsFactory} from
    "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/ManagedRewardsFactory.sol";
import {FactoryRegistry} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/factories/FactoryRegistry.sol";
import {Forwarder} from "@crane/contracts/protocols/utils/gsn/forwarder/Forwarder.sol";
import {VotingEscrow} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/VotingEscrow.sol";
import {VeArtProxy} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/VeArtProxy.sol";
import {RewardsDistributor} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/RewardsDistributor.sol";
import {Voter} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Voter.sol";
import {Router} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Router.sol";
import {Minter} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Minter.sol";
import {AirdropDistributor} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/AirdropDistributor.sol";
import {ProtocolGovernor} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/ProtocolGovernor.sol";
import {EpochGovernor} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/EpochGovernor.sol";
import {IVotes} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IVotes.sol";
import {CLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/CLPool.sol";
import {CLFactory} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/CLFactory.sol";
import {CustomSwapFeeModule} from
    "@crane/contracts/protocols/dexes/aerodrome/slipstream/fees/CustomSwapFeeModule.sol";
import {CustomUnstakedFeeModule} from
    "@crane/contracts/protocols/dexes/aerodrome/slipstream/fees/CustomUnstakedFeeModule.sol";
import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";
import {MockERC20} from "@crane/contracts/test/mocks/MockERC20.sol";

/// @notice Phase 6 Aerodrome ve(3,3) + Slipstream deploy graph (TestBase_Aerodrome order).
/// @dev Plain CREATE so hermetic tests and operator scripts share one path. CLGauge path is
///      out of scope (not in Crane slipstream port — see gap report P6-7).
contract BcAerodromePhase6Deploy is Script {
    struct DeployResult {
        address aero;
        address poolImpl;
        address poolFactory;
        address votingRewardsFactory;
        address gaugeFactory;
        address managedRewardsFactory;
        address factoryRegistry;
        address forwarder;
        address votingEscrow;
        address artProxy;
        address rewardsDistributor;
        address voter;
        address router;
        address minter;
        address airdrop;
        address protocolGovernor;
        address epochGovernor;
        address clPoolImpl;
        address clFactory;
        address customSwapFeeModule;
        address customUnstakedFeeModule;
        address weth;
        address samplePool; // optional volatile pool from smoke
    }

    /// @notice Full stack with supplied WETH (BC bind or hermetic WETH9).
    function deploy(address team, address weth_) external returns (DeployResult memory r) {
        require(team != address(0), "p6: team zero");
        require(weth_ != address(0), "p6: weth zero");
        r.weth = weth_;

        r.aero = address(new Aero());
        r.poolImpl = address(new Pool());
        r.poolFactory = address(new PoolFactory(r.poolImpl));
        r.votingRewardsFactory = address(new VotingRewardsFactory());
        r.gaugeFactory = address(new GaugeFactory());
        r.managedRewardsFactory = address(new ManagedRewardsFactory());
        r.factoryRegistry = address(
            new FactoryRegistry(
                r.poolFactory, r.votingRewardsFactory, r.gaugeFactory, r.managedRewardsFactory
            )
        );
        r.forwarder = address(new Forwarder());
        r.votingEscrow = address(new VotingEscrow(r.forwarder, r.aero, r.factoryRegistry));
        r.artProxy = address(new VeArtProxy(r.votingEscrow));
        VotingEscrow(r.votingEscrow).setArtProxy(r.artProxy);

        r.rewardsDistributor = address(new RewardsDistributor(r.votingEscrow));
        // Voter governor/epochGovernor init to address(this) (this helper).
        r.voter = address(new Voter(r.forwarder, r.votingEscrow, r.factoryRegistry));
        VotingEscrow(r.votingEscrow).setVoterAndDistributor(r.voter, r.rewardsDistributor);

        r.router = address(
            new Router(r.forwarder, r.factoryRegistry, r.poolFactory, r.voter, r.weth)
        );
        r.minter = address(new Minter(r.voter, r.votingEscrow, r.rewardsDistributor));
        RewardsDistributor(r.rewardsDistributor).setMinter(r.minter);
        Aero(r.aero).setMinter(r.minter);

        r.airdrop = address(new AirdropDistributor(r.votingEscrow));

        address[] memory gaugeTokens = new address[](0);
        Voter(r.voter).initialize(gaugeTokens, r.minter);

        // Role wiring (team as ops; then real governors).
        VotingEscrow(r.votingEscrow).setTeam(team);
        Minter(r.minter).setTeam(team);
        PoolFactory(r.poolFactory).setPauser(team);
        Voter(r.voter).setEmergencyCouncil(team);
        FactoryRegistry(r.factoryRegistry).transferOwnership(team);
        PoolFactory(r.poolFactory).setFeeManager(team);
        PoolFactory(r.poolFactory).setVoter(r.voter);

        // P6-2 / P6-3: real ProtocolGovernor + EpochGovernor (PRD 6.16–6.17).
        r.protocolGovernor = address(new ProtocolGovernor(IVotes(r.votingEscrow)));
        r.epochGovernor = address(new EpochGovernor(r.forwarder, IVotes(r.votingEscrow), r.minter));
        // Helper is still Voter.governor after construction.
        Voter(r.voter).setEpochGovernor(r.epochGovernor);
        Voter(r.voter).setGovernor(r.protocolGovernor);

        // Slipstream CL
        r.clPoolImpl = address(new CLPool());
        r.clFactory = address(new CLFactory(r.voter, address(0), r.clPoolImpl));

        // P6-6: custom fee modules
        r.customSwapFeeModule = address(new CustomSwapFeeModule(r.clFactory));
        r.customUnstakedFeeModule = address(new CustomUnstakedFeeModule(r.clFactory));
        CLFactory(r.clFactory).setSwapFeeModule(r.customSwapFeeModule);
        CLFactory(r.clFactory).setUnstakedFeeModule(r.customUnstakedFeeModule);

        console2.log("p6 aero", r.aero);
        console2.log("p6 protocolGovernor", r.protocolGovernor);
        console2.log("p6 epochGovernor", r.epochGovernor);
        console2.log("p6 clFactory", r.clFactory);
        console2.log("p6 swapFeeModule", r.customSwapFeeModule);
        return r;
    }

    /// @notice Hermetic: deploy WETH9 + full stack + one volatile pool (createPool smoke).
    function deployHermetic(address team) external returns (DeployResult memory r) {
        WETH9 weth_ = new WETH9();
        r = this.deploy(team, address(weth_));

        MockERC20 t0 = new MockERC20("TokenA", "TKA", 18);
        MockERC20 t1 = new MockERC20("TokenB", "TKB", 18);
        t0.mint(team, 1_000_000e18);
        t1.mint(team, 1_000_000e18);
        r.samplePool = PoolFactory(r.poolFactory).createPool(address(t0), address(t1), false);
        require(r.samplePool != address(0) && r.samplePool.code.length > 0, "p6: pool");
        return r;
    }
}
