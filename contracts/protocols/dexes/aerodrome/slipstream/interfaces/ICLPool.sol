// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title ICLPool
/// @notice Interface for Slipstream (Aerodrome CL) pools
/// @dev Compatible with Solidity 0.8+, mirrors Slipstream's ICLPool with necessary adjustments
interface ICLPool {
    /* -------------------------------------------------------------------------- */
    /*                               Pool Constants                               */
    /* -------------------------------------------------------------------------- */

    /// @notice The contract that deployed the pool
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @dev This is dynamic in Slipstream, retrieved from factory
    function fee() external view returns (uint24);

    /// @notice The pool's unstaked fee in hundredths of a bip, i.e. 1e-6
    /// @dev Additional fee applied to unstaked liquidity
    function unstakedFee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick
    function maxLiquidityPerTick() external view returns (uint128);

    /// @notice The gauge address associated with the pool
    function gauge() external view returns (address);

    /// @notice The nonfungible position manager address
    function nft() external view returns (address);

    /// @notice The factory registry address
    function factoryRegistry() external view returns (address);

    /* -------------------------------------------------------------------------- */
    /*                                 Pool State                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice The 0th storage slot in the pool stores many values
    /// @dev Different from Uniswap V3: no feeProtocol field
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool
    /// @return observationIndex The index of the last oracle observation that was written
    /// @return observationCardinality The current maximum number of observations stored
    /// @return observationCardinalityNext The next maximum number of observations
    /// @return unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The reward growth as a Q128.128 rewards collected per unit of liquidity for the entire life of the pool
    function rewardGrowthGlobalX128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the gauge
    function gaugeFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The emission rate of time-based farming
    function rewardRate() external view returns (uint256);

    /// @notice Virtual reserve that holds information on how many rewards are yet to be distributed
    function rewardReserve() external view returns (uint256);

    /// @notice Timestamp of the end of the current epoch's rewards
    function periodFinish() external view returns (uint256);

    /// @notice Last time the rewardReserve and rewardRate were updated
    function lastUpdated() external view returns (uint32);

    /// @notice Tracks total rewards distributed when no staked liquidity in active tick
    function rollover() external view returns (uint256);

    /// @notice The currently in range liquidity available to the pool
    function liquidity() external view returns (uint128);

    /// @notice The currently in range staked liquidity available to the pool
    function stakedLiquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross The total amount of position liquidity that uses the pool either as tick lower or tick upper
    /// @return liquidityNet How much liquidity changes when the pool price crosses the tick
    /// @return stakedLiquidityNet How much staked liquidity changes when the pool price crosses the tick
    /// @return feeGrowthOutside0X128 Fee growth on the other side of the tick from the current tick in token0
    /// @return feeGrowthOutside1X128 Fee growth on the other side of the tick from the current tick in token1
    /// @return rewardGrowthOutsideX128 Reward growth on the other side of the tick
    /// @return tickCumulativeOutside The cumulative tick value on the other side of the tick
    /// @return secondsPerLiquidityOutsideX128 Seconds spent per liquidity on the other side of the tick
    /// @return secondsOutside Seconds spent on the other side of the tick
    /// @return initialized Set to true if the tick is initialized
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            int128 stakedLiquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            uint256 rewardGrowthOutsideX128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position
    /// @return feeGrowthInside0LastX128 Fee growth of token0 inside the tick range as of the last mint/burn/poke
    /// @return feeGrowthInside1LastX128 Fee growth of token1 inside the tick range as of the last mint/burn/poke
    /// @return tokensOwed0 The computed amount of token0 owed to the position
    /// @return tokensOwed1 The computed amount of token1 owed to the position
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @return blockTimestamp The timestamp of the observation
    /// @return tickCumulative The tick multiplied by seconds elapsed for the life of the pool
    /// @return secondsPerLiquidityCumulativeX128 Seconds per in range liquidity for the life of the pool
    /// @return initialized Whether the observation has been initialized
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    /// @notice Returns data about reward growth within a tick range
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @param _rewardGrowthGlobalX128 A calculated rewardGrowthGlobalX128 or 0 (uses state if 0)
    /// @return rewardGrowthInsideX128 The reward growth in the range
    function getRewardGrowthInside(int24 tickLower, int24 tickUpper, uint256 _rewardGrowthGlobalX128)
        external
        view
        returns (uint256 rewardGrowthInsideX128);

    /* -------------------------------------------------------------------------- */
    /*                              Derived State                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside);

    /* -------------------------------------------------------------------------- */
    /*                                  Actions                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Sets the initial price for the pool
    /// @param _factory The factory address
    /// @param _token0 The first token address
    /// @param _token1 The second token address
    /// @param _tickSpacing The tick spacing
    /// @param _factoryRegistry The factory registry address
    /// @param _sqrtPriceX96 The initial sqrt price of the pool as a Q64.96
    function initialize(
        address _factory,
        address _token0,
        address _token1,
        int24 _tickSpacing,
        address _factoryRegistry,
        uint160 _sqrtPriceX96
    ) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the liquidity
    /// @return amount1 The amount of token1 that was paid to mint the liquidity
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0Requested How much token0 should be withdrawn
    /// @param amount1Requested How much token1 should be withdrawn
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Collects tokens owed to a position (NFT manager variant)
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0Requested How much token0 should be withdrawn
    /// @param amount1Requested How much token1 should be withdrawn
    /// @param owner The owner of the position
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested,
        address owner
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(int24 tickLower, int24 tickUpper, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burn liquidity for a specific owner (NFT manager variant)
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount How much liquidity to burn
    /// @param owner The owner of the position
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(int24 tickLower, int24 tickUpper, uint128 amount, address owner)
        external
        returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap (positive for exact input, negative for exact output)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool
    /// @return amount1 The delta of the balance of token1 of the pool
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;

    /// @notice Increase the maximum number of price and liquidity observations
    /// @param observationCardinalityNext The desired minimum number of observations
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    /* -------------------------------------------------------------------------- */
    /*                              Staking Actions                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Update staked liquidity for a position
    /// @param stakedLiquidityDelta The change in staked liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param positionUpdate Whether to update position ownership
    function stake(int128 stakedLiquidityDelta, int24 tickLower, int24 tickUpper, bool positionUpdate) external;

    /// @notice Update rewards growth global
    function updateRewardsGrowthGlobal() external;

    /// @notice Sync reward parameters from gauge
    /// @param _rewardRate The reward rate
    /// @param _rewardReserve The reward reserve
    /// @param _periodFinish The period finish timestamp
    function syncReward(uint256 _rewardRate, uint256 _rewardReserve, uint256 _periodFinish) external;

    /// @notice Set gauge and position manager addresses
    /// @param _gauge The gauge address
    /// @param _nft The NFT position manager address
    function setGaugeAndPositionManager(address _gauge, address _nft) external;

    /// @notice Collect gauge fees
    /// @return amount0 The amount of token0 collected
    /// @return amount1 The amount of token1 collected
    function collectFees() external returns (uint128 amount0, uint128 amount1);
}
