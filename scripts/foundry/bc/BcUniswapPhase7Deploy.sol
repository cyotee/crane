// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {IAllowanceTransfer} from "@crane/contracts/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol";
import {IPositionDescriptor} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPositionDescriptor.sol";
import {IWETH9} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/external/IWETH9.sol";
import {PoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/PoolManager.sol";
import {PositionManager} from "@crane/contracts/protocols/dexes/uniswap/v4/PositionManager.sol";
import {PositionDescriptor} from "@crane/contracts/protocols/dexes/uniswap/v4/PositionDescriptor.sol";
import {StateView} from "@crane/contracts/protocols/dexes/uniswap/v4/lens/StateView.sol";
import {V4Quoter} from "@crane/contracts/protocols/dexes/uniswap/v4/lens/V4Quoter.sol";
import {V4Router} from "@crane/contracts/protocols/dexes/uniswap/v4/V4Router.sol";
import {ReentrancyLock} from "@crane/contracts/protocols/dexes/uniswap/v4/base/ReentrancyLock.sol";
import {Currency} from "@crane/contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {IERC20Minimal} from
    "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/external/IERC20Minimal.sol";
import {BetterPermit2} from "@crane/contracts/protocols/utils/permit2/BetterPermit2.sol";
import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";

/// @notice Concrete V4Router for BC greenfield (abstract base needs entry + _pay + msgSender).
/// @dev Mirrors PositionManager pattern: ReentrancyLock locker + ERC20 transferFrom settle.
contract BcV4Router is V4Router, ReentrancyLock {
    constructor(IPoolManager _poolManager) V4Router(_poolManager) {}

    /// @notice Execute a batch of V4 router actions (unlockData = abi.encode(actions, params)).
    function execute(bytes calldata unlockData, uint256 deadline) external payable isNotLocked {
        if (block.timestamp > deadline) revert();
        _executeActions(unlockData);
    }

    function msgSender() public view override returns (address) {
        return _getLocker();
    }

    function _pay(Currency currency, address payer, uint256 amount) internal override {
        if (payer == address(this)) {
            currency.transfer(address(poolManager), amount);
        } else {
            IERC20Minimal(Currency.unwrap(currency)).transferFrom(payer, address(poolManager), amount);
        }
    }
}

/// @notice Phase 7 Uniswap V4 periphery + concrete V4Router deploy graph.
/// @dev Plain CREATE for hermetic/fork tests. Operator script binds BC Uni V3 + Phase1 PM when set.
contract BcUniswapPhase7Deploy is Script {
    uint256 internal constant UNSUBSCRIBE_GAS_LIMIT = 500_000;

    struct DeployResult {
        address poolManager;
        address permit2;
        address weth;
        address positionDescriptor;
        address positionManager;
        address v4Router;
        address stateView;
        address v4Quoter;
        address uniV3Factory; // bind-only when provided
    }

    /// @notice Deploy periphery against existing PoolManager / Permit2 / WETH (Phase 1 handoff).
    function deployPeriphery(
        address poolManager_,
        address permit2_,
        address weth_,
        address uniV3Factory_
    ) external returns (DeployResult memory r) {
        require(poolManager_ != address(0) && poolManager_.code.length > 0, "p7: pm");
        require(permit2_ != address(0) && permit2_.code.length > 0, "p7: permit2");
        require(weth_ != address(0), "p7: weth");

        r.poolManager = poolManager_;
        r.permit2 = permit2_;
        r.weth = weth_;
        r.uniV3Factory = uniV3Factory_;

        r.positionDescriptor = address(
            new PositionDescriptor(IPoolManager(poolManager_), weth_, bytes32("ETH"))
        );
        r.positionManager = address(
            new PositionManager(
                IPoolManager(poolManager_),
                IAllowanceTransfer(permit2_),
                UNSUBSCRIBE_GAS_LIMIT,
                IPositionDescriptor(r.positionDescriptor),
                IWETH9(weth_)
            )
        );
        // P7-3: concrete V4Router (not abstract base).
        r.v4Router = address(new BcV4Router(IPoolManager(poolManager_)));
        r.stateView = address(new StateView(IPoolManager(poolManager_)));
        r.v4Quoter = address(new V4Quoter(IPoolManager(poolManager_)));

        console2.log("p7 positionManager", r.positionManager);
        console2.log("p7 v4Router", r.v4Router);
        console2.log("p7 stateView", r.stateView);
        console2.log("p7 v4Quoter", r.v4Quoter);
        return r;
    }

    /// @notice Hermetic: deploy PoolManager + Permit2 + WETH + full periphery.
    function deployHermetic(address owner) external returns (DeployResult memory r) {
        require(owner != address(0), "p7: owner zero");
        WETH9 weth_ = new WETH9();
        PoolManager pm = new PoolManager(owner);
        BetterPermit2 p2 = new BetterPermit2();
        return this.deployPeriphery(address(pm), address(p2), address(weth_), address(0));
    }
}
