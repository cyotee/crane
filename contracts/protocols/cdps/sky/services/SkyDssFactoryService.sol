// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { Vat } from "../core/Vat.sol";
import { Dai } from "../core/Dai.sol";
import { GemJoin, DaiJoin } from "../core/Join.sol";
import { Jug } from "../core/Jug.sol";
import { Pot } from "../core/Pot.sol";
import { Spotter } from "../core/Spot.sol";
import { Vow } from "../core/Vow.sol";
import { Dog } from "../core/Dog.sol";
import { Flapper } from "../core/Flap.sol";
import { Flopper } from "../core/Flop.sol";
import { End } from "../core/End.sol";

import { MockChainlog } from "../test/mocks/MockChainlog.sol";

/// @title SkyDssFactoryService
/// @notice Library for deploying a complete DSS (Multi-Collateral DAI) system
/// @dev Deploys all core contracts and wires them together
library SkyDssFactoryService {
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;

    /// @notice Struct containing all deployed DSS contracts
    struct DssDeployment {
        Vat vat;
        Dai dai;
        DaiJoin daiJoin;
        Jug jug;
        Pot pot;
        Spotter spotter;
        Vow vow;
        Dog dog;
        Flapper flapper;
        Flopper flopper;
        End end;
        MockChainlog chainlog;
    }

    /// @notice Deploy the complete DSS system
    /// @param chainId The chain ID for DAI EIP-712 domain separator
    /// @return deployment Struct containing all deployed contracts
    function deployDss(uint256 chainId) internal returns (DssDeployment memory deployment) {
        // Deploy core accounting
        deployment.vat = new Vat();
        deployment.dai = new Dai(chainId);

        // Deploy join adapters
        deployment.daiJoin = new DaiJoin(address(deployment.vat), address(deployment.dai));

        // Deploy rate accumulation
        deployment.jug = new Jug(address(deployment.vat));

        // Deploy savings rate
        deployment.pot = new Pot(address(deployment.vat));

        // Deploy price oracle integration
        deployment.spotter = new Spotter(address(deployment.vat));

        // Deploy auction houses (need to be deployed before Vow)
        deployment.flapper = new Flapper(address(deployment.vat), address(0)); // gov token set later
        deployment.flopper = new Flopper(address(deployment.vat), address(0)); // gov token set later

        // Deploy debt engine
        deployment.vow = new Vow(
            address(deployment.vat),
            address(deployment.flapper),
            address(deployment.flopper)
        );

        // Deploy liquidation engine
        deployment.dog = new Dog(address(deployment.vat));

        // Deploy global settlement
        deployment.end = new End();

        // Deploy chainlog
        deployment.chainlog = new MockChainlog();

        // Wire up the system
        _wireSystem(deployment);

        // Register addresses in chainlog
        _registerChainlog(deployment);

        return deployment;
    }

    /// @notice Wire up all the contract dependencies
    function _wireSystem(DssDeployment memory d) internal {
        // Vat authorizations
        d.vat.rely(address(d.daiJoin));
        d.vat.rely(address(d.jug));
        d.vat.rely(address(d.pot));
        d.vat.rely(address(d.spotter));
        d.vat.rely(address(d.vow));
        d.vat.rely(address(d.dog));
        d.vat.rely(address(d.end));

        // Dai authorizations
        d.dai.rely(address(d.daiJoin));

        // Jug configuration
        d.jug.file("vow", address(d.vow));

        // Pot configuration
        d.pot.file("vow", address(d.vow));

        // Dog configuration
        d.dog.file("vow", address(d.vow));

        // Vow configuration - authorize dog to push debt
        d.vow.rely(address(d.dog));

        // Flapper configuration
        d.flapper.rely(address(d.vow));

        // Flopper configuration
        d.flopper.rely(address(d.vow));

        // End configuration
        d.end.file("vat", address(d.vat));
        d.end.file("dog", address(d.dog));
        d.end.file("vow", address(d.vow));
        d.end.file("pot", address(d.pot));
        d.end.file("spot", address(d.spotter));
    }

    /// @notice Register all addresses in the chainlog
    function _registerChainlog(DssDeployment memory d) internal {
        d.chainlog.setAddress("MCD_VAT", address(d.vat));
        d.chainlog.setAddress("MCD_DAI", address(d.dai));
        d.chainlog.setAddress("MCD_JOIN_DAI", address(d.daiJoin));
        d.chainlog.setAddress("MCD_JUG", address(d.jug));
        d.chainlog.setAddress("MCD_POT", address(d.pot));
        d.chainlog.setAddress("MCD_SPOT", address(d.spotter));
        d.chainlog.setAddress("MCD_VOW", address(d.vow));
        d.chainlog.setAddress("MCD_DOG", address(d.dog));
        d.chainlog.setAddress("MCD_FLAP", address(d.flapper));
        d.chainlog.setAddress("MCD_FLOP", address(d.flopper));
        d.chainlog.setAddress("MCD_END", address(d.end));
    }

    /// @notice Initialize an ilk (collateral type) with default parameters
    /// @param d The DSS deployment
    /// @param ilk The ilk identifier (e.g., "ETH-A")
    /// @param gem The collateral token address
    /// @param pip The price feed address
    /// @return join The created GemJoin adapter
    function initIlk(
        DssDeployment memory d,
        bytes32 ilk,
        address gem,
        address pip
    ) internal returns (GemJoin join) {
        // Deploy join adapter
        join = new GemJoin(address(d.vat), ilk, gem);

        // Authorize join in vat
        d.vat.rely(address(join));

        // Initialize ilk in vat
        d.vat.init(ilk);

        // Initialize ilk in jug
        d.jug.init(ilk);

        // Set price feed
        d.spotter.file(ilk, "pip", pip);

        // Set liquidation ratio to 150%
        d.spotter.file(ilk, "mat", RAY * 150 / 100);

        // Poke to update spot price
        d.spotter.poke(ilk);

        // Set debt ceiling to 1 million DAI
        d.vat.file(ilk, "line", 1_000_000 * RAD);

        // Set dust to 100 DAI
        d.vat.file(ilk, "dust", 100 * RAD);

        // Register in chainlog
        bytes memory joinKey = abi.encodePacked("MCD_JOIN_", ilk);
        bytes memory pipKey = abi.encodePacked("PIP_", ilk);
        d.chainlog.setAddress(bytes32(joinKey), address(join));
        d.chainlog.setAddress(bytes32(pipKey), pip);

        return join;
    }

    /// @notice Set global debt ceiling
    /// @param d The DSS deployment
    /// @param line The global debt ceiling in RAD
    function setGlobalDebtCeiling(DssDeployment memory d, uint256 line) internal {
        d.vat.file("Line", line);
    }

    /// @notice Set default system parameters
    /// @param d The DSS deployment
    function setDefaultParameters(DssDeployment memory d) internal {
        // Global debt ceiling: 10 million DAI
        d.vat.file("Line", 10_000_000 * RAD);

        // Vow parameters
        d.vow.file("wait", 0);           // No delay for debt auctions
        d.vow.file("bump", 10_000 * RAD); // Surplus auction lot size
        d.vow.file("sump", 50_000 * RAD); // Debt auction bid size
        d.vow.file("dump", 250 * WAD);    // Debt auction lot size
        d.vow.file("hump", 0);            // Surplus buffer

        // Pot parameters (DSR = 0%)
        // DSR is set in ray, 1.0 = no interest
        // pot.file("dsr", RAY) is already the default

        // End parameters
        d.end.file("wait", 0); // No wait period for settlement
    }
}
