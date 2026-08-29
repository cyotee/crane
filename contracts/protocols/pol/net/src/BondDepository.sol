// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IBondDepository} from "@crane/contracts/protocols/pol/net/src/interfaces/IBondDepository.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";
import {Wired} from "@crane/contracts/protocols/pol/net/src/abstract/Wired.sol";

/// @title BondDepository — standard bonds ("primary offerings")
/// @notice Two markets: 0 = USDG reserve bonds, 1 = NET/USDG v2 LP bonds.
///         Pricing (Q11, zero levers):
///             price = max(TWAP × (1 − BOND_DISCOUNT_BPS), backingPerToken)
///         The NAV floor makes every sale strictly accretive to backing.
///         Per-epoch payout capacity is BOND_EPOCH_CAP_BPS of totalSupply
///         (scales with supply — the demand throttle). Payouts vest linearly
///         over BOND_VEST (2 days). LP quotes are valued with the same
///         2·√(x·y) convention the Treasury RFV uses (Q14) — anything else
///         would make LP bonds a NAV leak.
contract BondDepository is IBondDepository, Wired {
    error NotEnabled();
    error AlreadyEnabled();
    error NotGenesisBond();
    error InvalidMarket();
    error PriceAboveMax();
    error EpochCapExceeded();
    error ZeroAmount();
    error TransferFailed();

    struct Note {
        uint256 payout;
        uint256 claimed;
        uint64 start;
        uint64 end;
    }

    INET public immutable net;
    IERC20 public immutable usdg;
    IUniswapV2Pair public immutable pairContract;
    IPairOracle public immutable oracle;
    ITreasury public immutable treasury;
    bool private immutable _netIsToken0;
    uint256 private immutable _usdgWadFactor;

    address public genesisBond;
    bool public enabled;
    uint64 public startTime;

    mapping(address => Note[]) public notes;
    /// @notice NET payout already committed per epoch index.
    mapping(uint256 => uint256) public payoutInEpoch;

    constructor(address net_, address usdg_, address pair_, address oracle_, address treasury_) {
        net = INET(_nonZero(net_));
        usdg = IERC20(_nonZero(usdg_));
        pairContract = IUniswapV2Pair(_nonZero(pair_));
        oracle = IPairOracle(_nonZero(oracle_));
        treasury = ITreasury(_nonZero(treasury_));
        _netIsToken0 = IUniswapV2Pair(pair_).token0() == net_;
        _usdgWadFactor = 10 ** (18 - IERC20Metadata(usdg_).decimals());
    }

    /// @notice One-time wiring (GenesisBond ↔ BondDepository deploy cycle).
    function wire(address genesisBond_) external wiring {
        genesisBond = _nonZero(genesisBond_);
    }

    /// @inheritdoc IBondDepository
    function enable() external {
        _checkWired();
        if (msg.sender != genesisBond) revert NotGenesisBond();
        if (enabled) revert AlreadyEnabled();
        enabled = true;
        startTime = uint64(block.timestamp);
    }

    /// @inheritdoc IBondDepository
    function marketCount() external pure returns (uint256) {
        return 2;
    }

    /// @inheritdoc IBondDepository
    function quoteToken(uint256 marketId) external view returns (address) {
        if (marketId == 0) return address(usdg);
        if (marketId == 1) return address(pairContract);
        revert InvalidMarket();
    }

    /// @inheritdoc IBondDepository
    function bondPrice(uint256 marketId) public view returns (uint256) {
        if (marketId > 1) revert InvalidMarket();
        uint256 discounted =
            oracle.twapNetUsdg() * (Constants.BPS - Constants.BOND_DISCOUNT_BPS) / Constants.BPS;
        uint256 backing = treasury.backingPerToken();
        return discounted > backing ? discounted : backing;
    }

    /// @inheritdoc IBondDepository
    function deposit(uint256 marketId, uint256 amount, uint256 maxPriceWad, address to)
        external
        returns (uint256 noteId, uint256 payout)
    {
        if (!enabled) revert NotEnabled();
        if (amount == 0) revert ZeroAmount();
        uint256 price = bondPrice(marketId); // reverts on stale TWAP (D1)
        if (price > maxPriceWad) revert PriceAboveMax();

        uint256 valueWad;
        if (marketId == 0) {
            valueWad = amount * _usdgWadFactor;
            if (!usdg.transferFrom(msg.sender, address(treasury), amount)) {
                revert TransferFailed();
            }
        } else {
            valueWad = _lpValueWad(amount);
            if (!pairContract.transferFrom(msg.sender, address(treasury), amount)) {
                revert TransferFailed();
            }
        }

        payout = FixedPointMath.mulDiv(valueWad, Constants.NET_UNIT, price);
        _checkEpochCap(payout);

        treasury.mintNet(address(this), payout);
        noteId = notes[to].length;
        notes[to].push(
            Note({
                payout: payout,
                claimed: 0,
                start: uint64(block.timestamp),
                end: uint64(block.timestamp + Constants.BOND_VEST)
            })
        );
        emit BondCreated(to, marketId, amount, payout, price);
    }

    /// @inheritdoc IBondDepository
    function redeem(address to) external returns (uint256 paid) {
        Note[] storage userNotes = notes[msg.sender];
        for (uint256 i = 0; i < userNotes.length; i++) {
            uint256 claimable = _claimable(userNotes[i]);
            if (claimable == 0) continue;
            userNotes[i].claimed += claimable;
            paid += claimable;
            emit BondRedeemed(msg.sender, i, claimable);
        }
        if (paid != 0 && !net.transfer(to, paid)) revert TransferFailed();
    }

    /// @inheritdoc IBondDepository
    function pendingFor(address account)
        external
        view
        returns (uint256 totalPending, uint256 claimableNow)
    {
        Note[] storage userNotes = notes[account];
        for (uint256 i = 0; i < userNotes.length; i++) {
            totalPending += userNotes[i].payout - userNotes[i].claimed;
            claimableNow += _claimable(userNotes[i]);
        }
    }

    function noteCount(address account) external view returns (uint256) {
        return notes[account].length;
    }

    /// @dev LP valued exactly as the Treasury RFV values it (Q14): share of
    ///      2·√(xWad·yWad), NET leg at 1 USDG intrinsic.
    function _lpValueWad(uint256 lpAmount) internal view returns (uint256) {
        (uint112 r0, uint112 r1,) = pairContract.getReserves();
        (uint112 netR, uint112 quoteR) = _netIsToken0 ? (r0, r1) : (r1, r0);
        uint256 xWad = uint256(quoteR) * _usdgWadFactor;
        uint256 yWad = uint256(netR) * Constants.NET_UNIT;
        uint256 rfvAll = 2 * FixedPointMath.sqrt(xWad * yWad);
        return FixedPointMath.mulDiv(rfvAll, lpAmount, pairContract.totalSupply());
    }

    function _checkEpochCap(uint256 payout) internal {
        uint256 epochIdx = (block.timestamp - startTime) / Constants.EPOCH_LENGTH;
        uint256 cap = net.totalSupply() * Constants.BOND_EPOCH_CAP_BPS / Constants.BPS;
        uint256 used = payoutInEpoch[epochIdx];
        if (used + payout > cap) revert EpochCapExceeded();
        payoutInEpoch[epochIdx] = used + payout;
    }

    function _claimable(Note storage note) internal view returns (uint256) {
        uint256 vested;
        if (block.timestamp >= note.end) {
            vested = note.payout;
        } else {
            vested = note.payout * (block.timestamp - note.start) / (note.end - note.start);
        }
        return vested - note.claimed;
    }
}
