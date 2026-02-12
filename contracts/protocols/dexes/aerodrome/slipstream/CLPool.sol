// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {ICLFactory} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLFactory.sol";
import {IFactoryRegistry} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/factories/IFactoryRegistry.sol";

import {SafeCast} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/SafeCast.sol";
import {Tick} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/libraries/Tick.sol";
import {TickBitmap} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickBitmap.sol";
import {Position} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/libraries/Position.sol";
import {Oracle} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/Oracle.sol";

import {FullMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FullMath.sol";
import {FixedPoint128} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/FixedPoint128.sol";
import {TransferHelper} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TransferHelper.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {LiquidityMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/LiquidityMath.sol";
import {SqrtPriceMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/SqrtPriceMath.sol";
import {SwapMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/SwapMath.sol";

import {IERC20Minimal} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IERC20Minimal.sol";
import {ICLMintCallback} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/callback/ICLMintCallback.sol";
import {ICLSwapCallback} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/callback/ICLSwapCallback.sol";
import {ICLFlashCallback} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/callback/ICLFlashCallback.sol";

/// @title CLPool
/// @notice Slipstream Concentrated Liquidity Pool implementation
/// @dev Ported from Slipstream (Solidity 0.7.6) to Solidity 0.8.x
/// @dev Key differences from Uniswap V3:
///      - Added gauge staking integration (stakedLiquidity, rewardGrowthGlobalX128)
///      - Added unstaked fee mechanism
///      - Dynamic fees retrieved from factory
///      - Reward distribution for staked liquidity
contract CLPool is ICLPool {
    using SafeCast for uint256;
    using SafeCast for int256;
    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using Oracle for Oracle.Observation[65535];

    /* -------------------------------------------------------------------------- */
    /*                               Pool Constants                               */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    address public override factory;
    /// @inheritdoc ICLPool
    address public override token0;
    /// @inheritdoc ICLPool
    address public override token1;
    /// @inheritdoc ICLPool
    address public override gauge;
    /// @inheritdoc ICLPool
    address public override nft;
    /// @inheritdoc ICLPool
    address public override factoryRegistry;

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // whether the pool is locked
        bool unlocked;
    }

    /// @inheritdoc ICLPool
    Slot0 public override slot0;

    /// @inheritdoc ICLPool
    uint256 public override feeGrowthGlobal0X128;
    /// @inheritdoc ICLPool
    uint256 public override feeGrowthGlobal1X128;

    /// @inheritdoc ICLPool
    uint256 public override rewardGrowthGlobalX128;

    // accumulated gauge fees in token0/token1 units
    struct GaugeFees {
        uint128 token0;
        uint128 token1;
    }

    /// @inheritdoc ICLPool
    GaugeFees public override gaugeFees;

    /// @inheritdoc ICLPool
    uint256 public override rewardRate;
    /// @inheritdoc ICLPool
    uint256 public override rewardReserve;
    /// @inheritdoc ICLPool
    uint256 public override periodFinish;
    /// @inheritdoc ICLPool
    uint256 public override rollover;

    /// @inheritdoc ICLPool
    uint128 public override stakedLiquidity;
    /// @inheritdoc ICLPool
    uint32 public override lastUpdated;
    /// @inheritdoc ICLPool
    int24 public override tickSpacing;

    /// @inheritdoc ICLPool
    uint128 public override liquidity;
    /// @inheritdoc ICLPool
    uint128 public override maxLiquidityPerTick;

    /// @inheritdoc ICLPool
    mapping(int24 => Tick.Info) public override ticks;
    /// @inheritdoc ICLPool
    mapping(int16 => uint256) public override tickBitmap;
    /// @inheritdoc ICLPool
    mapping(bytes32 => Position.Info) public override positions;
    /// @inheritdoc ICLPool
    Oracle.Observation[65535] public override observations;

    /* -------------------------------------------------------------------------- */
    /*                                  Modifiers                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Mutually exclusive reentrancy protection into the pool to/from a method.
    modifier lock() {
        require(slot0.unlocked, "LOK");
        slot0.unlocked = false;
        _;
        slot0.unlocked = true;
    }

    /// @dev Prevents calling a function from anyone except the gauge associated with this pool
    modifier onlyGauge() {
        require(msg.sender == gauge, "NG");
        _;
    }

    /// @dev Prevents calling a function from anyone except the nft manager
    modifier onlyNftManager() {
        require(msg.sender == nft, "NNFT");
        _;
    }

    /// @dev Prevents calling a function from anyone except the gauge factory
    modifier onlyGaugeFactory() {
        (, address gaugeFactory) = IFactoryRegistry(factoryRegistry).factoriesToPoolFactory(address(factory));
        require(msg.sender == gaugeFactory, "NGF");
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                               Initialization                               */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function initialize(
        address _factory,
        address _token0,
        address _token1,
        int24 _tickSpacing,
        address _factoryRegistry,
        uint160 _sqrtPriceX96
    ) external override {
        require(factory == address(0) && _factory != address(0));
        factory = _factory;
        token0 = _token0;
        token1 = _token1;
        tickSpacing = _tickSpacing;
        factoryRegistry = _factoryRegistry;

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);

        int24 tick = TickMath.getTickAtSqrtRatio(_sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

        slot0 = Slot0({
            sqrtPriceX96: _sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            unlocked: true
        });

        emit Initialize(_sqrtPriceX96, tick);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Fee Functions                               */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function fee() public view override returns (uint24) {
        return ICLFactory(factory).getSwapFee(address(this));
    }

    /// @inheritdoc ICLPool
    function unstakedFee() public view override returns (uint24) {
        return ICLFactory(factory).getUnstakedFee(address(this));
    }

    /* -------------------------------------------------------------------------- */
    /*                              Internal Helpers                              */
    /* -------------------------------------------------------------------------- */

    /// @dev Common checks for valid tick inputs.
    function checkTicks(int24 tickLower, int24 tickUpper) private pure {
        require(tickLower < tickUpper, "TLU");
        require(tickLower >= TickMath.MIN_TICK, "TLM");
        require(tickUpper <= TickMath.MAX_TICK, "TUM");
    }

    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32.
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    /// @dev Get the pool's balance of token0
    function balance0() private view returns (uint256) {
        (bool success, bytes memory data) =
            token0.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @dev Get the pool's balance of token1
    function balance1() private view returns (uint256) {
        (bool success, bytes memory data) =
            token1.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /* -------------------------------------------------------------------------- */
    /*                              Derived State                                 */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        override
        returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside)
    {
        checkTicks(tickLower, tickUpper);

        int56 tickCumulativeLower;
        int56 tickCumulativeUpper;
        uint160 secondsPerLiquidityOutsideLowerX128;
        uint160 secondsPerLiquidityOutsideUpperX128;
        uint32 secondsOutsideLower;
        uint32 secondsOutsideUpper;

        {
            Tick.Info storage lower = ticks[tickLower];
            Tick.Info storage upper = ticks[tickUpper];
            bool initializedLower;
            (tickCumulativeLower, secondsPerLiquidityOutsideLowerX128, secondsOutsideLower, initializedLower) = (
                lower.tickCumulativeOutside,
                lower.secondsPerLiquidityOutsideX128,
                lower.secondsOutside,
                lower.initialized
            );
            require(initializedLower);

            bool initializedUpper;
            (tickCumulativeUpper, secondsPerLiquidityOutsideUpperX128, secondsOutsideUpper, initializedUpper) = (
                upper.tickCumulativeOutside,
                upper.secondsPerLiquidityOutsideX128,
                upper.secondsOutside,
                upper.initialized
            );
            require(initializedUpper);
        }

        Slot0 memory _slot0 = slot0;

        unchecked {
            if (_slot0.tick < tickLower) {
                return (
                    tickCumulativeLower - tickCumulativeUpper,
                    secondsPerLiquidityOutsideLowerX128 - secondsPerLiquidityOutsideUpperX128,
                    secondsOutsideLower - secondsOutsideUpper
                );
            } else if (_slot0.tick < tickUpper) {
                uint32 time = _blockTimestamp();
                (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) = observations.observeSingle(
                    time, 0, _slot0.tick, _slot0.observationIndex, liquidity, _slot0.observationCardinality
                );
                return (
                    tickCumulative - tickCumulativeLower - tickCumulativeUpper,
                    secondsPerLiquidityCumulativeX128 - secondsPerLiquidityOutsideLowerX128
                        - secondsPerLiquidityOutsideUpperX128,
                    time - secondsOutsideLower - secondsOutsideUpper
                );
            } else {
                return (
                    tickCumulativeUpper - tickCumulativeLower,
                    secondsPerLiquidityOutsideUpperX128 - secondsPerLiquidityOutsideLowerX128,
                    secondsOutsideUpper - secondsOutsideLower
                );
            }
        }
    }

    /// @inheritdoc ICLPool
    function observe(uint32[] calldata secondsAgos)
        external
        view
        override
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s)
    {
        return observations.observe(
            _blockTimestamp(), secondsAgos, slot0.tick, slot0.observationIndex, liquidity, slot0.observationCardinality
        );
    }

    /// @inheritdoc ICLPool
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external override lock {
        uint16 observationCardinalityNextOld = slot0.observationCardinalityNext;
        uint16 observationCardinalityNextNew =
            observations.grow(observationCardinalityNextOld, observationCardinalityNext);
        slot0.observationCardinalityNext = observationCardinalityNextNew;
        if (observationCardinalityNextOld != observationCardinalityNextNew) {
            emit IncreaseObservationCardinalityNext(observationCardinalityNextOld, observationCardinalityNextNew);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            Position Management                             */
    /* -------------------------------------------------------------------------- */

    struct ModifyPositionParams {
        address owner;
        int24 tickLower;
        int24 tickUpper;
        int128 liquidityDelta;
    }

    /// @dev Effect some changes to a position
    function _modifyPosition(ModifyPositionParams memory params)
        private
        returns (Position.Info storage position, int256 amount0, int256 amount1)
    {
        checkTicks(params.tickLower, params.tickUpper);

        Slot0 memory _slot0 = slot0;

        position = _updatePosition(params.owner, params.tickLower, params.tickUpper, params.liquidityDelta, _slot0.tick);

        if (params.liquidityDelta != 0) {
            if (_slot0.tick < params.tickLower) {
                amount0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            } else if (_slot0.tick < params.tickUpper) {
                uint128 liquidityBefore = liquidity;

                (slot0.observationIndex, slot0.observationCardinality) = observations.write(
                    _slot0.observationIndex,
                    _blockTimestamp(),
                    _slot0.tick,
                    liquidityBefore,
                    _slot0.observationCardinality,
                    _slot0.observationCardinalityNext
                );

                amount0 = SqrtPriceMath.getAmount0Delta(
                    _slot0.sqrtPriceX96, TickMath.getSqrtRatioAtTick(params.tickUpper), params.liquidityDelta
                );
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower), _slot0.sqrtPriceX96, params.liquidityDelta
                );

                liquidity = LiquidityMath.addDelta(liquidityBefore, params.liquidityDelta);
            } else {
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            }
        }
    }

    /// @dev Gets and updates a position with the given liquidity delta
    function _updatePosition(address owner, int24 tickLower, int24 tickUpper, int128 liquidityDelta, int24 tick)
        private
        returns (Position.Info storage position)
    {
        position = positions.get(owner, tickLower, tickUpper);

        uint256 _feeGrowthGlobal0X128 = feeGrowthGlobal0X128;
        uint256 _feeGrowthGlobal1X128 = feeGrowthGlobal1X128;

        bool flippedLower;
        bool flippedUpper;
        if (liquidityDelta != 0) {
            uint32 time = _blockTimestamp();
            (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) = observations.observeSingle(
                time, 0, slot0.tick, slot0.observationIndex, liquidity, slot0.observationCardinality
            );

            flippedLower = ticks.update(
                tickLower,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                false,
                maxLiquidityPerTick
            );
            flippedUpper = ticks.update(
                tickUpper,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                true,
                maxLiquidityPerTick
            );

            if (flippedLower) {
                tickBitmap.flipTick(tickLower, tickSpacing);
            }
            if (flippedUpper) {
                tickBitmap.flipTick(tickUpper, tickSpacing);
            }
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            ticks.getFeeGrowthInside(tickLower, tickUpper, tick, _feeGrowthGlobal0X128, _feeGrowthGlobal1X128);

        bool staked = (owner == gauge) && (owner != address(0));
        position.update(liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128, staked);

        if (liquidityDelta < 0) {
            if (flippedLower) {
                ticks.clear(tickLower);
            }
            if (flippedUpper) {
                ticks.clear(tickUpper);
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Mint                                    */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes calldata data)
        external
        override
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        require(amount > 0);
        (, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(uint256(amount)).toInt128()
            })
        );

        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();
        ICLMintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);
        unchecked {
            if (amount0 > 0) require(balance0Before + amount0 <= balance0(), "M0");
            if (amount1 > 0) require(balance1Before + amount1 <= balance1(), "M1");
        }

        emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Collect                                  */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        (amount0, amount1) = _collect({
            recipient: recipient,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Requested: amount0Requested,
            amount1Requested: amount1Requested,
            owner: msg.sender
        });
    }

    /// @inheritdoc ICLPool
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested,
        address owner
    ) external override lock onlyNftManager returns (uint128 amount0, uint128 amount1) {
        (amount0, amount1) = _collect({
            recipient: recipient,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Requested: amount0Requested,
            amount1Requested: amount1Requested,
            owner: owner
        });
    }

    function _collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested,
        address owner
    ) private returns (uint128 amount0, uint128 amount1) {
        Position.Info storage position = positions.get(owner, tickLower, tickUpper);

        amount0 = amount0Requested > position.tokensOwed0 ? position.tokensOwed0 : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1 ? position.tokensOwed1 : amount1Requested;

        unchecked {
            if (amount0 > 0) {
                position.tokensOwed0 -= amount0;
                TransferHelper.safeTransfer(token0, recipient, amount0);
            }
            if (amount1 > 0) {
                position.tokensOwed1 -= amount1;
                TransferHelper.safeTransfer(token1, recipient, amount1);
            }
        }

        emit Collect(owner, recipient, tickLower, tickUpper, amount0, amount1);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Burn                                    */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function burn(int24 tickLower, int24 tickUpper, uint128 amount)
        external
        override
        lock
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = _burn({tickLower: tickLower, tickUpper: tickUpper, amount: amount, owner: msg.sender});
    }

    /// @inheritdoc ICLPool
    function burn(int24 tickLower, int24 tickUpper, uint128 amount, address owner)
        external
        override
        lock
        onlyNftManager
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = _burn({tickLower: tickLower, tickUpper: tickUpper, amount: amount, owner: owner});
    }

    function _burn(int24 tickLower, int24 tickUpper, uint128 amount, address owner)
        private
        returns (uint256 amount0, uint256 amount1)
    {
        (Position.Info storage position, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: owner,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: -int256(uint256(amount)).toInt128()
            })
        );

        unchecked {
            amount0 = uint256(-amount0Int);
            amount1 = uint256(-amount1Int);

            if (amount0 > 0 || amount1 > 0) {
                (position.tokensOwed0, position.tokensOwed1) =
                    (position.tokensOwed0 + uint128(amount0), position.tokensOwed1 + uint128(amount1));
            }
        }

        emit Burn(owner, tickLower, tickUpper, amount, amount0, amount1);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Staking                                  */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function stake(int128 stakedLiquidityDelta, int24 tickLower, int24 tickUpper, bool positionUpdate)
        external
        override
        lock
        onlyGauge
    {
        int24 tick = slot0.tick;
        // Increase staked liquidity in the current tick
        if (tick >= tickLower && tick < tickUpper) {
            _updateRewardsGrowthGlobal();
            stakedLiquidity = LiquidityMath.addDelta(stakedLiquidity, stakedLiquidityDelta);
        }

        if (positionUpdate) {
            Position.Info storage nftPosition = positions.get(nft, tickLower, tickUpper);
            Position.Info storage gaugePosition = positions.get(gauge, tickLower, tickUpper);

            (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
                ticks.getFeeGrowthInside(tickLower, tickUpper, tick, feeGrowthGlobal0X128, feeGrowthGlobal1X128);

            // Assign the staked positions virtually to the gauge
            nftPosition.update(-stakedLiquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128, false);
            gaugePosition.update(stakedLiquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128, true);
        }

        // Update tick locations where staked liquidity needs to be added or subtracted
        if (ticks[tickLower].initialized) ticks.updateStake(tickLower, stakedLiquidityDelta, false);
        if (ticks[tickUpper].initialized) ticks.updateStake(tickUpper, stakedLiquidityDelta, true);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Swap                                    */
    /* -------------------------------------------------------------------------- */

    struct SwapCache {
        uint128 liquidityStart;
        uint128 stakedLiquidityStart;
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        bool computedLatestObservation;
    }

    struct SwapState {
        int256 amountSpecifiedRemaining;
        int256 amountCalculated;
        uint160 sqrtPriceX96;
        int24 tick;
        uint24 swapFee;
        bool hasUpdatedFees;
        uint256 feeGrowthGlobalX128;
        uint128 gaugeFee;
        uint128 currentLiquidity;
        uint128 currentStakedLiquidity;
    }

    struct StepComputations {
        uint160 sqrtPriceStartX96;
        int24 tickNext;
        bool initialized;
        uint160 sqrtPriceNextX96;
        uint256 amountIn;
        uint256 amountOut;
        uint256 feeAmount;
    }

    /// @inheritdoc ICLPool
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, "AS");

        Slot0 memory slot0Start = slot0;

        require(slot0Start.unlocked, "LOK");
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            "SPL"
        );

        slot0.unlocked = false;

        SwapCache memory cache = SwapCache({
            liquidityStart: liquidity,
            stakedLiquidityStart: stakedLiquidity,
            blockTimestamp: _blockTimestamp(),
            secondsPerLiquidityCumulativeX128: 0,
            tickCumulative: 0,
            computedLatestObservation: false
        });

        bool exactInput = amountSpecified > 0;

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: slot0Start.sqrtPriceX96,
            tick: slot0Start.tick,
            swapFee: fee(),
            hasUpdatedFees: false,
            feeGrowthGlobalX128: zeroForOne ? feeGrowthGlobal0X128 : feeGrowthGlobal1X128,
            gaugeFee: 0,
            currentLiquidity: cache.liquidityStart,
            currentStakedLiquidity: cache.stakedLiquidityStart
        });

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) =
                tickBitmap.nextInitializedTickWithinOneWord(state.tick, tickSpacing, zeroForOne);

            // ensure that we do not overshoot the min/max tick
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.currentLiquidity,
                state.amountSpecifiedRemaining,
                state.swapFee
            );

            unchecked {
                if (exactInput) {
                    state.amountSpecifiedRemaining -= int256(step.amountIn + step.feeAmount);
                    state.amountCalculated -= int256(step.amountOut);
                } else {
                    state.amountSpecifiedRemaining += int256(step.amountOut);
                    state.amountCalculated += int256(step.amountIn + step.feeAmount);
                }

                // update global fee tracker and gauge fee
                if (state.currentLiquidity > 0) {
                    (uint256 _feeGrowthGlobalX128, uint256 _stakedFeeAmount) =
                        calculateFees(step.feeAmount, state.currentLiquidity, state.currentStakedLiquidity);

                    state.feeGrowthGlobalX128 += _feeGrowthGlobalX128;
                    state.gaugeFee += uint128(_stakedFeeAmount);
                }
            }

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                if (step.initialized) {
                    if (!cache.computedLatestObservation) {
                        (cache.tickCumulative, cache.secondsPerLiquidityCumulativeX128) = observations.observeSingle(
                            cache.blockTimestamp,
                            0,
                            slot0Start.tick,
                            slot0Start.observationIndex,
                            cache.liquidityStart,
                            slot0Start.observationCardinality
                        );
                        cache.computedLatestObservation = true;
                    }
                    if (!state.hasUpdatedFees) {
                        _updateRewardsGrowthGlobal();
                        state.hasUpdatedFees = true;
                    }
                    Tick.LiquidityNets memory nets = ticks.cross(
                        step.tickNext,
                        (zeroForOne ? state.feeGrowthGlobalX128 : feeGrowthGlobal0X128),
                        (zeroForOne ? feeGrowthGlobal1X128 : state.feeGrowthGlobalX128),
                        cache.secondsPerLiquidityCumulativeX128,
                        cache.tickCumulative,
                        cache.blockTimestamp,
                        rewardGrowthGlobalX128
                    );
                    // if we're moving leftward, we interpret liquidityNet & stakedLiquidityNet as the opposite sign
                    if (zeroForOne) {
                        nets.liquidityNet = -nets.liquidityNet;
                        nets.stakedLiquidityNet = -nets.stakedLiquidityNet;
                    }

                    state.currentLiquidity = LiquidityMath.addDelta(state.currentLiquidity, nets.liquidityNet);
                    state.currentStakedLiquidity = LiquidityMath.addDelta(state.currentStakedLiquidity, nets.stakedLiquidityNet);
                }

                unchecked {
                    state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
                }
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        // update tick and write an oracle entry if the tick changed
        if (state.tick != slot0Start.tick) {
            (uint16 observationIndex, uint16 observationCardinality) = observations.write(
                slot0Start.observationIndex,
                cache.blockTimestamp,
                slot0Start.tick,
                cache.liquidityStart,
                slot0Start.observationCardinality,
                slot0Start.observationCardinalityNext
            );
            (slot0.sqrtPriceX96, slot0.tick, slot0.observationIndex, slot0.observationCardinality) =
                (state.sqrtPriceX96, state.tick, observationIndex, observationCardinality);
        } else {
            slot0.sqrtPriceX96 = state.sqrtPriceX96;
        }

        // update liquidity and stakedLiquidity if it changed
        if (cache.liquidityStart != state.currentLiquidity) liquidity = state.currentLiquidity;
        if (cache.stakedLiquidityStart != state.currentStakedLiquidity) stakedLiquidity = state.currentStakedLiquidity;

        // update fee growth global and, if necessary, gauge fees
        unchecked {
            if (zeroForOne) {
                feeGrowthGlobal0X128 = state.feeGrowthGlobalX128;
                if (state.gaugeFee > 0) gaugeFees.token0 += state.gaugeFee;
            } else {
                feeGrowthGlobal1X128 = state.feeGrowthGlobalX128;
                if (state.gaugeFee > 0) gaugeFees.token1 += state.gaugeFee;
            }
        }

        unchecked {
            (amount0, amount1) = zeroForOne == exactInput
                ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
                : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
        }

        // do the transfers and collect payment
        if (zeroForOne) {
            unchecked {
                if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));
            }

            uint256 balance0Before = balance0();
            ICLSwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
            unchecked {
                require(balance0Before + uint256(amount0) <= balance0(), "IIA");
            }
        } else {
            unchecked {
                if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));
            }

            uint256 balance1Before = balance1();
            ICLSwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
            unchecked {
                require(balance1Before + uint256(amount1) <= balance1(), "IIA");
            }
        }

        emit Swap(msg.sender, recipient, amount0, amount1, state.sqrtPriceX96, state.currentLiquidity, state.tick);
        slot0.unlocked = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Flash                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external override lock {
        uint128 _liquidity = liquidity;
        require(_liquidity > 0, "L");

        uint256 fee0 = FullMath.mulDivRoundingUp(amount0, fee(), 1e6);
        uint256 fee1 = FullMath.mulDivRoundingUp(amount1, fee(), 1e6);
        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();

        if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
        if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);

        ICLFlashCallback(msg.sender).uniswapV3FlashCallback(fee0, fee1, data);

        uint256 balance0After = balance0();
        uint256 balance1After = balance1();

        unchecked {
            require(balance0Before + fee0 <= balance0After, "F0");
            require(balance1Before + fee1 <= balance1After, "F1");

            uint256 paid0 = balance0After - balance0Before;
            uint256 paid1 = balance1After - balance1Before;

            if (paid0 > 0) {
                (uint256 feeGrowthGlobalX128_, uint256 stakedFeeAmount) = calculateFees(paid0, _liquidity, stakedLiquidity);

                if (feeGrowthGlobalX128_ > 0) feeGrowthGlobal0X128 += feeGrowthGlobalX128_;
                if (uint128(stakedFeeAmount) > 0) gaugeFees.token0 += uint128(stakedFeeAmount);
            }
            if (paid1 > 0) {
                (uint256 feeGrowthGlobalX128_, uint256 stakedFeeAmount) = calculateFees(paid1, _liquidity, stakedLiquidity);

                if (feeGrowthGlobalX128_ > 0) feeGrowthGlobal1X128 += feeGrowthGlobalX128_;
                if (uint128(stakedFeeAmount) > 0) gaugeFees.token1 += uint128(stakedFeeAmount);
            }
        }
        emit Flash(msg.sender, recipient, amount0, amount1, balance0After - balance0Before, balance1After - balance1Before);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Reward Functions                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function getRewardGrowthInside(int24 tickLower, int24 tickUpper, uint256 _rewardGrowthGlobalX128)
        external
        view
        override
        returns (uint256 rewardGrowthInside)
    {
        checkTicks(tickLower, tickUpper);
        if (_rewardGrowthGlobalX128 == 0) _rewardGrowthGlobalX128 = rewardGrowthGlobalX128;

        return ticks.getRewardGrowthInside(tickLower, tickUpper, slot0.tick, _rewardGrowthGlobalX128);
    }

    /// @inheritdoc ICLPool
    function updateRewardsGrowthGlobal() external override lock onlyGauge {
        _updateRewardsGrowthGlobal();
    }

    /// @dev timeDelta != 0 handles case when function is called twice in the same block.
    /// @dev stakedLiquidity > 0 handles case when depositing staked liquidity and there is no liquidity staked yet,
    /// @dev or when notifying rewards when there is no liquidity staked
    function _updateRewardsGrowthGlobal() internal {
        uint32 timestamp = _blockTimestamp();
        uint256 _lastUpdated = lastUpdated;
        uint256 timeDelta = timestamp - _lastUpdated;

        if (timeDelta != 0) {
            if (rewardReserve > 0) {
                uint256 reward = rewardRate * timeDelta;
                if (reward > rewardReserve) reward = rewardReserve;
                unchecked {
                    rewardReserve -= reward;
                }
                if (stakedLiquidity > 0) {
                    rewardGrowthGlobalX128 += FullMath.mulDiv(reward, FixedPoint128.Q128, stakedLiquidity);
                } else {
                    rollover += reward;
                }
            }
            lastUpdated = timestamp;
        }
    }

    /// @inheritdoc ICLPool
    function syncReward(uint256 _rewardRate, uint256 _rewardReserve, uint256 _periodFinish)
        external
        override
        lock
        onlyGauge
    {
        rewardRate = _rewardRate;
        rewardReserve = _rewardReserve;
        periodFinish = _periodFinish;
        delete rollover;
    }

    /* -------------------------------------------------------------------------- */
    /*                              Fee Calculations                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Calculates the fees owed to staked liquidity, then calculates fee levied on unstaked liquidity
    function splitFees(uint256 feeAmount, uint128 _liquidity, uint128 _stakedLiquidity)
        internal
        view
        returns (uint256 unstakedFeeAmount, uint256 stakedFeeAmount)
    {
        stakedFeeAmount = FullMath.mulDivRoundingUp(feeAmount, _stakedLiquidity, _liquidity);
        (unstakedFeeAmount, stakedFeeAmount) = applyUnstakedFees(feeAmount - stakedFeeAmount, stakedFeeAmount);
    }

    /// @notice Calculates fee levied on unstaked liquidity only
    function applyUnstakedFees(uint256 _unstakedFeeAmount, uint256 _stakedFeeAmount)
        internal
        view
        returns (uint256 unstakedFeeAmount, uint256 stakedFeeAmount)
    {
        uint256 _stakedFee = FullMath.mulDivRoundingUp(_unstakedFeeAmount, unstakedFee(), 1_000_000);
        unchecked {
            unstakedFeeAmount = _unstakedFeeAmount - _stakedFee;
            stakedFeeAmount = _stakedFeeAmount + _stakedFee;
        }
    }

    /// @notice Calculates the fee growths for unstaked liquidity and returns it with the staked fee amount
    function calculateFees(uint256 feeAmount, uint128 _liquidity, uint128 _stakedLiquidity)
        internal
        view
        returns (uint256 feeGrowthGlobalX128_, uint256 stakedFeeAmount)
    {
        // if there is only staked liquidity
        if (_liquidity == _stakedLiquidity) {
            stakedFeeAmount = feeAmount;
        }
        // if there is only unstaked liquidity
        else if (_stakedLiquidity == 0) {
            (uint256 unstakedFeeAmount, uint256 _stakedFeeAmount) = applyUnstakedFees(feeAmount, 0);
            feeGrowthGlobalX128_ = FullMath.mulDiv(unstakedFeeAmount, FixedPoint128.Q128, _liquidity);
            stakedFeeAmount = _stakedFeeAmount;
        }
        // if there are staked and unstaked liquidities
        else {
            unchecked {
                (uint256 unstakedFeeAmount, uint256 _stakedFeeAmount) = splitFees(feeAmount, _liquidity, _stakedLiquidity);
                feeGrowthGlobalX128_ = FullMath.mulDiv(unstakedFeeAmount, FixedPoint128.Q128, _liquidity - _stakedLiquidity);
                stakedFeeAmount = _stakedFeeAmount;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Owner Actions                                 */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICLPool
    function collectFees() external override lock onlyGauge returns (uint128 amount0, uint128 amount1) {
        amount0 = gaugeFees.token0;
        amount1 = gaugeFees.token1;
        unchecked {
            if (amount0 > 1) {
                gaugeFees.token0 = 1;
                TransferHelper.safeTransfer(token0, msg.sender, --amount0);
            }
            if (amount1 > 1) {
                gaugeFees.token1 = 1;
                TransferHelper.safeTransfer(token1, msg.sender, --amount1);
            }
        }

        emit CollectFees(msg.sender, amount0, amount1);
    }

    /// @inheritdoc ICLPool
    function setGaugeAndPositionManager(address _gauge, address _nft) external override lock onlyGaugeFactory {
        require(gauge == address(0));
        gauge = _gauge;
        nft = _nft;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Emitted when the pool is initialized
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flash loans of token0/token1
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when fees are collected by the gauge
    event CollectFees(address indexed recipient, uint128 amount0, uint128 amount1);
}
