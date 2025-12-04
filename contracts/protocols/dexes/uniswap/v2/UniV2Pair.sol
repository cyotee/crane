// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

import {Math} from "./deps/libs/Math.sol";
import {UQ112x112} from "@crane/contracts/protocols/dexes/uniswap/v2/deps/libs/UQ112x112.sol";
import {IUniswapV2ERC20} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2ERC20.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {BetterIERC20 as IERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {ERC20Target} from "@crane/contracts/tokens/ERC20/ERC20Target.sol";
import {IUniswapV2Callee} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Callee.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";

import {SafeMath} from "./deps/libs/SafeMath.sol";
import "@crane/contracts/constants/Constants.sol";
// import "hardhat/console.sol";
import "forge-std/console.sol";
// import "forge-std/console2.sol";

contract UniV2Pair is ERC20Target, IUniswapV2Pair {
    using BetterEfficientHashLib for bytes;
    using SafeMath for uint256;
    using Math for uint256;
    using UQ112x112 for uint224;

    // event Sync(uint112 reserve0, uint112 reserve1);

    bytes32 internal _DOMAIN_SEPARATOR;
    // bytes32 internal constant _PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    uint256 internal constant _MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    mapping(address => uint256) internal _nonces;

    address internal _factory;
    address internal _token0;
    address internal _token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 internal _price0CumulativeLast;
    uint256 internal _price1CumulativeLast;
    uint256 internal _kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        _factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address token0_, address token1_) external override {
        require(msg.sender == _factory, "UniswapV2: FORBIDDEN"); // sufficient check
        _token0 = token0_;
        _token1 = token1_;
        string memory symbol_ = string.concat(IERC20(token0_).symbol(), "/", IERC20(token1_).symbol());
        ERC20Repo.Storage storage erc20 = ERC20Repo._layout();
        ERC20Repo._initialize(erc20, string.concat("MockUniV2 Pair of ", symbol_), symbol_, 18);
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(ERC20Repo._name(erc20))),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    function PERMIT_TYPEHASH() external pure returns (bytes32) {
        return _PERMIT_TYPEHASH;
    }

    // function allowance(address owner, address spender) external view returns (uint) {
    //     return _allowance[owner][spender];
    // }

    // function balanceOf(address owner) external view returns (uint) {
    //     return _balanceOf[owner];
    // }

    // function decimals() external pure returns (uint8) {
    //     return _decimals;
    // }

    // function name() external pure returns (string memory) {
    //     return _name;
    // }

    function nonces(address owner) external view returns (uint256) {
        return _nonces[owner];
    }

    // function symbol() external pure returns (string memory) {
    //     return _symbol;
    // }

    // function totalSupply() external view returns (uint) {
    //     return _totalSupply;
    // }

    // function _approve(address owner, address spender, uint value) internal {
    //     _allowance[owner][spender] = value;
    //     // emit Approval(owner, spender, value);
    // }

    // function approve(address spender, uint value) external returns (bool) {
    //     _approve(msg.sender, spender, value);
    //     return true;
    // }

    // function _transfer(address from, address to, uint value) internal {
    //     _balanceOf[from] = _balanceOf[from].sub(value);
    //     _balanceOf[to] = _balanceOf[to].add(value);
    //     // emit Transfer(from, to, value);
    // }

    // function transfer(address to, uint value) external returns (bool) {
    //     _transfer(msg.sender, to, value);
    //     return true;
    // }

    // function transferFrom(address from, address to, uint value) public returns (bool) {
    //     if (_allowance[from][msg.sender] != type(uint).max) {
    //         _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
    //     }
    //     _transfer(from, to, value);
    //     return true;
    // }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        // bytes32 digest = keccak256(
        //     abi.encodePacked(
        //         '\x19\x01',
        //         _DOMAIN_SEPARATOR,
        //         keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _nonces[owner]++, deadline))
        //     )
        // );
        bytes32 digest = abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _nonces[owner]++, deadline))
            )._hash();
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "UniswapV2: INVALID_SIGNATURE");
        ERC20Repo._approve(owner, spender, value);
    }

    function MINIMUM_LIQUIDITY() external pure override returns (uint256) {
        return _MINIMUM_LIQUIDITY;
    }

    function factory() external view override returns (address) {
        return _factory;
    }

    function token0() external view override returns (address) {
        return _token0;
    }

    function token1() external view override returns (address) {
        return _token1;
    }

    function price0CumulativeLast() external view override returns (uint256) {
        return _price0CumulativeLast;
    }

    function price1CumulativeLast() external view override returns (uint256) {
        return _price1CumulativeLast;
    }

    function kLast() external view override returns (uint256) {
        return _kLast;
    }

    function getReserves()
        public
        view
        override
        returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "UniswapV2: TRANSFER_FAILED");
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        // console.log("UniV2PairStub::_update(uint256,uint256,uint256,uint256): Entering function.");
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "UniswapV2: OVERFLOW");
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            _price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            _price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
        // console.log("UniV2PairStub::_update(uint256,uint256,uint256,uint256): Exiting function.");
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(_factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 kLast_ = _kLast; // gas savings
        if (feeOn) {
            if (kLast_ != 0) {
                uint256 rootK = Math._sqrt(uint256(_reserve0) * (_reserve1));
                uint256 rootKLast = Math._sqrt(kLast_);
                if (rootK > rootKLast) {
                    uint256 numerator = ERC20Repo._totalSupply() * (rootK - (rootKLast));
                    uint256 denominator = (rootK * 5) + (rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) ERC20Repo._mint(feeTo, liquidity);
                }
            }
        } else if (kLast_ != 0) {
            kLast_ = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external override lock returns (uint256 liquidity) {
        // console.log("UniV2PairStub::mint(address): Entering function.");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 amount0 = balance0 - (_reserve0);
        uint256 amount1 = balance1 - (_reserve1);

        // console.log("UniV2PairStub::mint(address): minting fee.");
        bool feeOn = _mintFee(_reserve0, _reserve1);
        // console.log("UniV2PairStub::mint(address): minted fee.");
        // console.log("UniV2PairStub::mint(address): Loading total supply.");
        uint256 totalSupply_ = ERC20Repo._totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        // console.log("UniV2PairStub::mint(address): Total supply is %s.", totalSupply_);
        if (totalSupply_ == 0) {
            // console.log("UniV2PairStub::mint(address): IS first deposit.");
            // console.log("UniV2PairStub::mint(address): Calcing LP token mint.");
            // console.log("UniV2PairStub::mint(address): Amount 0: .", amount0);
            // console.log("UniV2PairStub::mint(address): Amount 1: .", amount1);
            // console.log("UniV2PairStub::mint(address): Min Liquidity: .", _MINIMUM_LIQUIDITY);
            // liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            liquidity = Math._sqrt((amount0 * amount1)) - (_MINIMUM_LIQUIDITY);
            // console.log("UniV2PairStub::mint(address): Will mint %s LP tokens.", liquidity);
            // console.log("UniV2PairStub::mint(address): Minting min LP tokens to address(0).");
            ERC20Repo._mint(address(0), _MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            // console.log("UniV2PairStub::mint(address): Minted min LP tokens to address(0).");
        } else {
            // console.log("UniV2PairStub::mint(address): IS NOT first deposit.");
            // console.log("UniV2PairStub::mint(address): Calcing LP more token mint.");
            // liquidity = Math.min(amount0.mul(totalSupply_) / _reserve0, amount1.mul(totalSupply_) / _reserve1);
            liquidity = Math._min((amount0 * totalSupply_) / _reserve0, (amount1 * totalSupply_) / _reserve1);
            // console.log("UniV2PairStub::mint(address): Will mint %s LP tokens.", liquidity);
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        // console.log("UniV2PairStub::mint(address): Minting min LP tokens to %s .", to);
        ERC20Repo._mint(to, liquidity);

        // console.log("UniV2PairStub::mint(address): Updating reserve record.");
        _update(balance0, balance1, _reserve0, _reserve1);
        // console.log("UniV2PairStub::mint(address): Checking if fee is on.");
        if (feeOn) _kLast = uint256(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        // console.log("UniV2PairStub::mint(address): emitting Mint event.");
        emit Mint(msg.sender, amount0, amount1);
        // console.log("UniV2PairStub::mint(address): Exiting function.");
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external override lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address token0_ = _token0; // gas savings
        address token1_ = _token1; // gas savings
        uint256 balance0 = IERC20(token0_).balanceOf(address(this));
        uint256 balance1 = IERC20(token1_).balanceOf(address(this));
        uint256 liquidity = ERC20Repo._balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 totalSupply_ = ERC20Repo._totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity * balance0) / totalSupply_; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / totalSupply_; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED");
        ERC20Repo._burn(address(this), liquidity);
        _safeTransfer(token0_, to, amount0);
        _safeTransfer(token1_, to, amount1);
        balance0 = IERC20(token0_).balanceOf(address(this));
        balance1 = IERC20(token1_).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) _kLast = uint256(reserve0) * (reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external override lock {
        // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): Entering function.");
        require(amount0Out > 0 || amount1Out > 0, "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "UniswapV2: INSUFFICIENT_LIQUIDITY");

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address token0_ = _token0;
            address token1_ = _token1;
            require(to != _token0 && to != _token1, "UniswapV2: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(token0_, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(token1_, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(token0_).balanceOf(address(this));
            balance1 = IERC20(token1_).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): amount0In: %s", amount0In);
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): amount1In: %s", amount1In);
        require(amount0In > 0 || amount1In > 0, "UniswapV2: INSUFFICIENT_INPUT_AMOUNT");
        // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): balance0: %s", balance0);
        // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): balance1: %s", balance1);
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            // uint balance0Adjusted = (balance0 * 1000) - (amount0In * (3));
            // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): balance0Adjusted: %s", balance0Adjusted);
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            // uint balance1Adjusted = (balance1 * 1000) - (amount1In * (3));
            // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): balance1Adjusted: %s", balance1Adjusted);
            // // require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
            require(
                balance0Adjusted.mul(balance1Adjusted) >= uint256(_reserve0).mul(_reserve1).mul(1000 ** 2),
                "UniswapV2: K"
            );
            // console.log("New K: %s ", (balance0Adjusted * balance1Adjusted));
            // console.log("Old K: %s ", ((_reserve0 * _reserve1) * (1000**2)));
            // require(
            //     (balance0Adjusted * balance1Adjusted)
            //     >=
            //     ((_reserve0 * _reserve1) * (1000**2))
            //     , 'UniswapV2: K'
            // );
        }

        // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): Updating reserves.");
        _update(balance0, balance1, _reserve0, _reserve1);
        // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): Updated reserves.");
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
        // console.log("UniV2PairStub::swap(uint256,uint256,address,bytes): Exiting function.");
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address token0_ = _token0; // gas savings
        address token1_ = _token1; // gas savings
        _safeTransfer(token0_, to, IERC20(token0_).balanceOf(address(this)) - (reserve0));
        _safeTransfer(token1_, to, IERC20(token1_).balanceOf(address(this)) - (reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(_token0).balanceOf(address(this)), IERC20(_token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
