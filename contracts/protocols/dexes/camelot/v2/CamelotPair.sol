// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import "@crane/contracts/protocols/dexes/camelot/v2/UniswapV2ERC20.sol";
import "@crane/contracts/protocols/dexes/camelot/v2/libraries/Math.sol";
import {BetterIERC20 as IERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Callee.sol";
import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";

contract CamelotPair is

    // ICamelotPair,
    UniswapV2ERC20
{
    using SafeMath for uint256;

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    address public factory;
    address public token0;
    address public token1;

    bool public initialized;

    uint256 public constant FEE_DENOMINATOR = 100000;
    uint256 public constant MAX_FEE_PERCENT = 2000; // = 2%ee

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint16 public token0FeePercent = 500; // default = 0.3%  // uses single storage slot, accessible via getReserves
    uint16 public token1FeePercent = 500; // default = 0.3%  // uses single storage slot, accessible via getReserves

    uint256 public precisionMultiplier0;
    uint256 public precisionMultiplier1;

    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    bool public stableSwap; // if set to true, defines pair type as stable
    bool public pairTypeImmutable; // if set to true, stableSwap states cannot be updated anymore

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "CamelotPair: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        returns (uint112 _reserve0, uint112 _reserve1, uint16 _token0FeePercent, uint16 _token1FeePercent)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _token0FeePercent = token0FeePercent;
        _token1FeePercent = token1FeePercent;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "CamelotPair: TRANSFER_FAILED");
    }

    event DrainWrongToken(address indexed token, address to);
    event FeePercentUpdated(uint16 token0FeePercent, uint16 token1FeePercent);
    event SetStableSwap(bool prevStableSwap, bool stableSwap);
    event SetPairTypeImmutable();
    //   event Mint(address indexed sender, uint amount0, uint amount1);
    //   event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    //   event Swap(
    //     address indexed sender,
    //     uint amount0In,
    //     uint amount1In,
    //     uint amount0Out,
    //     uint amount1Out,
    //     address indexed to
    //   );
    //   event Sync(uint112 reserve0, uint112 reserve1);
    event Skim();

    constructor() {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory && !initialized, "CamelotPair: FORBIDDEN");
        // sufficient check
        token0 = _token0;
        token1 = _token1;

        precisionMultiplier0 = 10 ** uint256(IERC20(_token0).decimals());
        precisionMultiplier1 = 10 ** uint256(IERC20(_token1).decimals());

        initialized = true;
    }

    /**
     * @dev Updates the swap fees percent
     *
     * Can only be called by the factory's feeAmountOwner
     */
    function setFeePercent(uint16 newToken0FeePercent, uint16 newToken1FeePercent) external lock {
        require(msg.sender == ICamelotFactory(factory).feePercentOwner(), "CamelotPair: only factory's feeAmountOwner");
        require(
            newToken0FeePercent <= MAX_FEE_PERCENT && newToken1FeePercent <= MAX_FEE_PERCENT,
            "CamelotPair: feePercent mustn't exceed the maximum"
        );
        require(
            newToken0FeePercent > 0 && newToken1FeePercent > 0, "CamelotPair: feePercent mustn't exceed the minimum"
        );
        token0FeePercent = newToken0FeePercent;
        token1FeePercent = newToken1FeePercent;
        emit FeePercentUpdated(newToken0FeePercent, newToken1FeePercent);
    }

    function setStableSwap(bool stable, uint112 expectedReserve0, uint112 expectedReserve1) external lock {
        require(msg.sender == ICamelotFactory(factory).setStableOwner(), "CamelotPair: only factory's setStableOwner");
        require(!pairTypeImmutable, "CamelotPair: immutable");

        require(stable != stableSwap, "CamelotPair: no update");
        require(expectedReserve0 == reserve0 && expectedReserve1 == reserve1, "CamelotPair: failed");

        bool feeOn = _mintFee(reserve0, reserve1);

        emit SetStableSwap(stableSwap, stable);
        stableSwap = stable;
        kLast = (stable && feeOn) ? _k(uint256(reserve0), uint256(reserve1)) : 0;
    }

    function setPairTypeImmutable() external lock {
        require(msg.sender == ICamelotFactory(factory).owner(), "CamelotPair: only factory's owner");
        require(!pairTypeImmutable, "CamelotPair: already immutable");

        pairTypeImmutable = true;
        emit SetPairTypeImmutable();
    }

    // update reserves
    function _update(uint256 balance0, uint256 balance1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "CamelotPair: OVERFLOW");

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        emit ICamelotPair.Sync(uint112(balance0), uint112(balance1));
    }

    // if fee is on, mint liquidity equivalent to "factory.ownerFeeShare()" of the growth in sqrt(k)
    // only for uni configuration
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        if (stableSwap) return false;

        (uint256 ownerFeeShare, address feeTo) = ICamelotFactory(factory).feeInfo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(_k(uint256(_reserve0), uint256(_reserve1)));
                uint256 rootKLast = Math.sqrt(_kLast);
                console.log("_mintFee: ownerFeeShare", ownerFeeShare);
                console.log("_mintFee: feeTo (as uint160)", uint256(uint160(feeTo)));
                console.log("_mintFee: _kLast", _kLast);
                console.log("_mintFee: rootK, rootKLast", rootK, rootKLast);
                if (rootK > rootKLast) {
                    uint256 d = (FEE_DENOMINATOR.mul(100) / ownerFeeShare).sub(100);
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast)).mul(100);
                    uint256 denominator = rootK.mul(d).add(rootKLast.mul(100));
                    uint256 liquidity = numerator / denominator;
                    console.log("_mintFee: d", d);
                    console.log("_mintFee: numerator", numerator);
                    console.log("_mintFee: denominator", denominator);
                    console.log("_mintFee: liquidity (to mint)", liquidity);
                    if (liquidity > 0) {
                        _mint(feeTo, liquidity);
                        console.log("_mintFee: minted liquidity", liquidity);
                        console.log("_mintFee: totalSupply after mint", totalSupply);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves();
        // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
            // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, "CamelotPair: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1);
        if (feeOn) kLast = _k(uint256(reserve0), uint256(reserve1));
        // reserve0 and reserve1 are up-to-date
        emit ICamelotPair.Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,,) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        console.log("CamelotPair.burn: liquidity", liquidity);
        console.log("CamelotPair.burn: balances", balance0, balance1);
        console.log("CamelotPair.burn: reserves", uint256(_reserve0), uint256(_reserve1));
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        console.log("CamelotPair.burn: feeOn", feeOn ? 1 : 0);
        console.log("CamelotPair.burn: totalSupply", _totalSupply);
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        console.log("CamelotPair.burn: computed amount0,amount1", amount0, amount1);
        require(amount0 > 0 && amount1 > 0, "CamelotPair: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1);
        if (feeOn) kLast = _k(uint256(reserve0), uint256(reserve1)); // reserve0 and reserve1 are up-to-date
        emit ICamelotPair.Burn(msg.sender, amount0, amount1, to);
    }

    struct TokensData {
        address token0;
        address token1;
        uint256 amount0Out;
        uint256 amount1Out;
        uint256 balance0;
        uint256 balance1;
        uint256 remainingFee0;
        uint256 remainingFee1;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external {
        TokensData memory tokensData = TokensData({
            token0: token0,
            token1: token1,
            amount0Out: amount0Out,
            amount1Out: amount1Out,
            balance0: 0,
            balance1: 0,
            remainingFee0: 0,
            remainingFee1: 0
        });
        _swap(tokensData, to, data, address(0));
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data, address referrer) external {
        TokensData memory tokensData = TokensData({
            token0: token0,
            token1: token1,
            amount0Out: amount0Out,
            amount1Out: amount1Out,
            balance0: 0,
            balance1: 0,
            remainingFee0: 0,
            remainingFee1: 0
        });
        _swap(tokensData, to, data, referrer);
    }

    function _swap(TokensData memory tokensData, address to, bytes memory data, address referrer) internal lock {
        require(tokensData.amount0Out > 0 || tokensData.amount1Out > 0, "CamelotPair: INSUFFICIENT_OUTPUT_AMOUNT");

        (uint112 _reserve0, uint112 _reserve1, uint16 _token0FeePercent, uint16 _token1FeePercent) = getReserves();
        require(
            tokensData.amount0Out < _reserve0 && tokensData.amount1Out < _reserve1,
            "CamelotPair: INSUFFICIENT_LIQUIDITY"
        );

        {
            require(to != tokensData.token0 && to != tokensData.token1, "CamelotPair: INVALID_TO");
            // optimistically transfer tokens
            if (tokensData.amount0Out > 0) _safeTransfer(tokensData.token0, to, tokensData.amount0Out);
            // optimistically transfer tokens
            if (tokensData.amount1Out > 0) _safeTransfer(tokensData.token1, to, tokensData.amount1Out);
            if (data.length > 0) {
                IUniswapV2Callee(to).uniswapV2Call(msg.sender, tokensData.amount0Out, tokensData.amount1Out, data);
            }
            tokensData.balance0 = IERC20(tokensData.token0).balanceOf(address(this));
            tokensData.balance1 = IERC20(tokensData.token1).balanceOf(address(this));
        }

        uint256 amount0In = tokensData.balance0 > _reserve0 - tokensData.amount0Out
            ? tokensData.balance0 - (_reserve0 - tokensData.amount0Out)
            : 0;
        uint256 amount1In = tokensData.balance1 > _reserve1 - tokensData.amount1Out
            ? tokensData.balance1 - (_reserve1 - tokensData.amount1Out)
            : 0;
        require(amount0In > 0 || amount1In > 0, "CamelotPair: INSUFFICIENT_INPUT_AMOUNT");

        tokensData.remainingFee0 = amount0In.mul(_token0FeePercent) / FEE_DENOMINATOR;
        tokensData.remainingFee1 = amount1In.mul(_token1FeePercent) / FEE_DENOMINATOR;

        {
            // scope for referer/stable fees management
            uint256 fee = 0;

            uint256 referrerInputFeeShare =
                referrer != address(0) ? ICamelotFactory(factory).referrersFeeShare(referrer) : 0;
            if (referrerInputFeeShare > 0) {
                if (amount0In > 0) {
                    fee = amount0In.mul(referrerInputFeeShare).mul(_token0FeePercent) / (FEE_DENOMINATOR ** 2);
                    tokensData.remainingFee0 = tokensData.remainingFee0.sub(fee);
                    _safeTransfer(tokensData.token0, referrer, fee);
                }
                if (amount1In > 0) {
                    fee = amount1In.mul(referrerInputFeeShare).mul(_token1FeePercent) / (FEE_DENOMINATOR ** 2);
                    tokensData.remainingFee1 = tokensData.remainingFee1.sub(fee);
                    _safeTransfer(tokensData.token1, referrer, fee);
                }
            }

            if (stableSwap) {
                (uint256 ownerFeeShare, address feeTo) = ICamelotFactory(factory).feeInfo();
                if (feeTo != address(0)) {
                    ownerFeeShare = FEE_DENOMINATOR.sub(referrerInputFeeShare).mul(ownerFeeShare);
                    if (amount0In > 0) {
                        fee = amount0In.mul(ownerFeeShare).mul(_token0FeePercent) / (FEE_DENOMINATOR ** 3);
                        tokensData.remainingFee0 = tokensData.remainingFee0.sub(fee);
                        _safeTransfer(tokensData.token0, feeTo, fee);
                    }
                    if (amount1In > 0) {
                        fee = amount1In.mul(ownerFeeShare).mul(_token1FeePercent) / (FEE_DENOMINATOR ** 3);
                        tokensData.remainingFee1 = tokensData.remainingFee1.sub(fee);
                        _safeTransfer(tokensData.token1, feeTo, fee);
                    }
                }
            }
            // readjust tokens balance
            if (amount0In > 0) tokensData.balance0 = IERC20(tokensData.token0).balanceOf(address(this));
            if (amount1In > 0) tokensData.balance1 = IERC20(tokensData.token1).balanceOf(address(this));
        }
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = tokensData.balance0.sub(tokensData.remainingFee0);
            uint256 balance1Adjusted = tokensData.balance1.sub(tokensData.remainingFee1);
            require(
                _k(balance0Adjusted, balance1Adjusted) >= _k(uint256(_reserve0), uint256(_reserve1)), "CamelotPair: K"
            );
        }
        _update(tokensData.balance0, tokensData.balance1);
        emit ICamelotPair.Swap(msg.sender, amount0In, amount1In, tokensData.amount0Out, tokensData.amount1Out, to);
    }

    function _k(uint256 balance0, uint256 balance1) internal view returns (uint256) {
        if (stableSwap) {
            uint256 _x = balance0.mul(1e18) / precisionMultiplier0;
            uint256 _y = balance1.mul(1e18) / precisionMultiplier1;
            uint256 _a = (_x.mul(_y)) / 1e18;
            uint256 _b = (_x.mul(_x) / 1e18).add(_y.mul(_y) / 1e18);
            return _a.mul(_b) / 1e18; // x3y+y3x >= k
        }
        return balance0.mul(balance1);
    }

    function _get_y(uint256 x0, uint256 xy, uint256 y) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = (xy - k) * 1e18 / _d(x0, y);
                y = y + dy;
            } else {
                uint256 dy = (k - xy) * 1e18 / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return x0 * (y * y / 1e18 * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18) * y / 1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return 3 * x0 * (y * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18);
    }

    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256) {
        uint16 feePercent = tokenIn == token0 ? token0FeePercent : token1FeePercent;
        return _getAmountOut(amountIn, tokenIn, uint256(reserve0), uint256(reserve1), feePercent);
    }

    function _getAmountOut(uint256 amountIn, address tokenIn, uint256 _reserve0, uint256 _reserve1, uint256 feePercent)
        internal
        view
        returns (uint256)
    {
        console.log("CamelotPair._getAmountOut: amountIn", amountIn);
        console.log("CamelotPair._getAmountOut: tokenIn (as uint160)", uint256(uint160(tokenIn)));
        console.log("CamelotPair._getAmountOut: reserves", _reserve0, _reserve1);
        console.log("CamelotPair._getAmountOut: feePercent", feePercent);
        if (stableSwap) {
            amountIn = amountIn.sub(amountIn.mul(feePercent) / FEE_DENOMINATOR); // remove fee from amount received
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = _reserve0 * 1e18 / precisionMultiplier0;
            _reserve1 = _reserve1 * 1e18 / precisionMultiplier1;

            (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn =
                tokenIn == token0 ? amountIn * 1e18 / precisionMultiplier0 : amountIn * 1e18 / precisionMultiplier1;
            uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            console.log("CamelotPair._getAmountOut: stable out", y);
            return y * (tokenIn == token0 ? precisionMultiplier1 : precisionMultiplier0) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = amountIn.mul(FEE_DENOMINATOR.sub(feePercent));
            uint256 out = (amountIn.mul(reserveB)) / (reserveA.mul(FEE_DENOMINATOR).add(amountIn));
            console.log("CamelotPair._getAmountOut: uni out", out);
            return out;
        }
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0;
        // gas savings
        address _token1 = token1;
        // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
        emit Skim();
    }

    // force reserves to match balances
    function sync() external lock {
        uint256 token0Balance = IERC20(token0).balanceOf(address(this));
        uint256 token1Balance = IERC20(token1).balanceOf(address(this));
        require(token0Balance != 0 && token1Balance != 0, "CamelotPair: liquidity ratio not initialized");
        _update(token0Balance, token1Balance);
    }

    /**
     * @dev Allow to recover token sent here by mistake
     *
     * Can only be called by factory's owner
     */
    function drainWrongToken(address token, address to) external lock {
        require(msg.sender == ICamelotFactory(factory).owner(), "CamelotPair: only factory's owner");
        require(token != token0 && token != token1, "CamelotPair: invalid token");
        _safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        emit DrainWrongToken(token, to);
    }
}
