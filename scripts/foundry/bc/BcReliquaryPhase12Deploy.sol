// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {Reliquary} from "@crane/contracts/protocols/staking/reliquary/v1/Reliquary.sol";
import {LinearCurve} from "@crane/contracts/protocols/staking/reliquary/v1/curves/LinearCurve.sol";
import {LinearPlateauCurve} from
    "@crane/contracts/protocols/staking/reliquary/v1/curves/LinearPlateauCurve.sol";
import {
    PolynomialPlateauCurve
} from "@crane/contracts/protocols/staking/reliquary/v1/curves/PolynomialPlateauCurve.sol";
import {ICurves} from "@crane/contracts/protocols/staking/reliquary/v1/interfaces/ICurves.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import {MockERC20} from "@crane/contracts/test/mocks/MockERC20.sol";

/// @notice Phase 12 Reliquary + full curve set + reward funding (TestBase_Reliquary parity).
contract BcReliquaryPhase12Deploy is Script {
    uint256 public constant DEFAULT_EMISSION = 1e18;
    uint256 public constant DEFAULT_REWARD_FUND = 1_000_000e18;

    struct DeployResult {
        address reliquary;
        address linearCurve;
        address linearPlateauCurve;
        address polynomialCurve;
        address rewardToken;
        address poolToken;
        uint8 poolId;
        uint256 rewardFunded;
    }

    /// @notice Deploy with existing reward + pool tokens; funds reliquary from this contract's balance.
    /// @param bootstrapTo EOA (or IERC721Receiver) that receives the 1-wei bootstrap Relic from addPool.
    function deployWithTokens(
        address rewardToken_,
        address poolToken_,
        uint256 rewardFundAmount,
        address bootstrapTo
    ) external returns (DeployResult memory r) {
        require(rewardToken_ != address(0) && poolToken_ != address(0), "p12: tokens zero");
        require(bootstrapTo != address(0), "p12: bootstrapTo zero");
        r.rewardToken = rewardToken_;
        r.poolToken = poolToken_;

        r.linearCurve = address(new LinearCurve(1, 1));
        r.linearPlateauCurve = address(new LinearPlateauCurve(1, 1, 10));
        int256[] memory coeffs = new int256[](1);
        coeffs[0] = int256(1e18);
        r.polynomialCurve = address(new PolynomialPlateauCurve(coeffs, 100));

        Reliquary rel = new Reliquary(rewardToken_, DEFAULT_EMISSION, "Reliquary Deposit", "RELIC");
        r.reliquary = address(rel);

        if (rewardFundAmount > 0) {
            // Transfer reward tokens into Reliquary (this helper must hold balance).
            require(IERC20(rewardToken_).transfer(address(rel), rewardFundAmount), "p12: fund");
            r.rewardFunded = rewardFundAmount;
        }

        // addPool always mints a 1-wei bootstrap Relic to `_to` — must be EOA or ERC721 receiver.
        // Helper must hold ≥1 pool token and approve Reliquary.
        require(IERC20(poolToken_).approve(address(rel), type(uint256).max), "p12: pool approve");
        rel.addPool(100, poolToken_, address(0), ICurves(r.linearCurve), "Pool A", address(0), true, bootstrapTo);
        r.poolId = 0;

        console2.log("p12 reliquary", r.reliquary);
        console2.log("p12 linearCurve", r.linearCurve);
        console2.log("p12 linearPlateau", r.linearPlateauCurve);
        console2.log("p12 polynomial", r.polynomialCurve);
        console2.log("p12 rewardFunded", r.rewardFunded);
        return r;
    }

    /// @notice Hermetic: mintable reward/pool tokens + full fund + createRelic-ready.
    /// @param bootstrapTo EOA receiving the bootstrap Relic (use test address, not this helper).
    function deployHermetic(address bootstrapTo) external returns (DeployResult memory r) {
        MockERC20 reward = new MockERC20("Reward", "RWD", 18);
        MockERC20 pool = new MockERC20("Pool", "POOL", 18);
        reward.mint(address(this), DEFAULT_REWARD_FUND * 2);
        pool.mint(address(this), 1_000_000e18);

        r = this.deployWithTokens(address(reward), address(pool), DEFAULT_REWARD_FUND, bootstrapTo);
        return r;
    }
}
