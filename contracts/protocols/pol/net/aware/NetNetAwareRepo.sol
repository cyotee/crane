// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/external/openzeppelin-contracts/interfaces/IERC4626.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {IMorpho} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";

import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";
import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IBondDepository} from "@crane/contracts/protocols/pol/net/src/interfaces/IBondDepository.sol";
import {IInverseBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IInverseBond.sol";
import {IPremiumSeller} from "@crane/contracts/protocols/pol/net/src/interfaces/IPremiumSeller.sol";
import {ITaxCollector} from "@crane/contracts/protocols/pol/net/src/interfaces/ITaxCollector.sol";
import {IPTEAM} from "@crane/contracts/protocols/pol/net/src/interfaces/IPTEAM.sol";

// tag::NetNetAwareRepo[]
/**
 * @title NetNetAwareRepo - Storage for NetNet P0 protocol addresses.
 * @author Crane
 * @dev Dual overloads (parameterized Storage + default STORAGE_SLOT). Slot: `protocols.pol.net.aware`.
 */
library NetNetAwareRepo {
    // tag::STORAGE_SLOT[]
    /// @dev ERC1967-style slot: keccak256("protocols.pol.net.aware") - 1.
    bytes32 internal constant STORAGE_SLOT =
        bytes32(uint256(keccak256(abi.encode("protocols.pol.net.aware"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::NetNetAwareInit[]
    struct NetNetAwareInit {
        IERC20 usdg;
        INET net;
        IsNET sNet;
        IStaking staking;
        ITreasury treasury;
        IBondDepository bondDepository;
        IInverseBond inverseBond;
        IPremiumSeller premiumSeller;
        ITaxCollector taxCollector;
        IPTEAM pteam;
        IUniswapV2Pair canonicalPair;
        IUniswapV2Router02 router;
        address turboRouter;
        address wsNet;
        address zap;
        IMorpho morpho;
        bytes32 loopbackMarketId;
        IERC4626 morphoVault;
        address pTeamHolder;
    }
    // end::NetNetAwareInit[]

    // tag::Storage[]
    struct Storage {
        IERC20 usdg;
        INET net;
        IsNET sNet;
        IStaking staking;
        ITreasury treasury;
        IBondDepository bondDepository;
        IInverseBond inverseBond;
        IPremiumSeller premiumSeller;
        ITaxCollector taxCollector;
        IPTEAM pteam;
        IUniswapV2Pair canonicalPair;
        IUniswapV2Router02 router;
        address turboRouter;
        address wsNet;
        address zap;
        IMorpho morpho;
        bytes32 loopbackMarketId;
        IERC4626 morphoVault;
        address pTeamHolder;
    }
    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_initialize(Storage-NetNetAwareInit)[]
    function _initialize(Storage storage layoutStruct, NetNetAwareInit memory init_) internal {
        layoutStruct.usdg = init_.usdg;
        layoutStruct.net = init_.net;
        layoutStruct.sNet = init_.sNet;
        layoutStruct.staking = init_.staking;
        layoutStruct.treasury = init_.treasury;
        layoutStruct.bondDepository = init_.bondDepository;
        layoutStruct.inverseBond = init_.inverseBond;
        layoutStruct.premiumSeller = init_.premiumSeller;
        layoutStruct.taxCollector = init_.taxCollector;
        layoutStruct.pteam = init_.pteam;
        layoutStruct.canonicalPair = init_.canonicalPair;
        layoutStruct.router = init_.router;
        layoutStruct.turboRouter = init_.turboRouter;
        layoutStruct.wsNet = init_.wsNet;
        layoutStruct.zap = init_.zap;
        layoutStruct.morpho = init_.morpho;
        layoutStruct.loopbackMarketId = init_.loopbackMarketId;
        layoutStruct.morphoVault = init_.morphoVault;
        layoutStruct.pTeamHolder = init_.pTeamHolder;
    }
    // end::_initialize(Storage-NetNetAwareInit)[]

    // tag::_initialize(NetNetAwareInit)[]
    function _initialize(NetNetAwareInit memory init_) internal {
        _initialize(_layoutStruct(), init_);
    }
    // end::_initialize(NetNetAwareInit)[]

    function _usdg(Storage storage layoutStruct) internal view returns (IERC20) {
        return layoutStruct.usdg;
    }

    function _usdg() internal view returns (IERC20) {
        return _usdg(_layoutStruct());
    }

    function _net(Storage storage layoutStruct) internal view returns (INET) {
        return layoutStruct.net;
    }

    function _net() internal view returns (INET) {
        return _net(_layoutStruct());
    }

    function _sNet(Storage storage layoutStruct) internal view returns (IsNET) {
        return layoutStruct.sNet;
    }

    function _sNet() internal view returns (IsNET) {
        return _sNet(_layoutStruct());
    }

    function _staking(Storage storage layoutStruct) internal view returns (IStaking) {
        return layoutStruct.staking;
    }

    function _staking() internal view returns (IStaking) {
        return _staking(_layoutStruct());
    }

    function _treasury(Storage storage layoutStruct) internal view returns (ITreasury) {
        return layoutStruct.treasury;
    }

    function _treasury() internal view returns (ITreasury) {
        return _treasury(_layoutStruct());
    }

    function _bondDepository(Storage storage layoutStruct) internal view returns (IBondDepository) {
        return layoutStruct.bondDepository;
    }

    function _bondDepository() internal view returns (IBondDepository) {
        return _bondDepository(_layoutStruct());
    }

    function _inverseBond(Storage storage layoutStruct) internal view returns (IInverseBond) {
        return layoutStruct.inverseBond;
    }

    function _inverseBond() internal view returns (IInverseBond) {
        return _inverseBond(_layoutStruct());
    }

    function _premiumSeller(Storage storage layoutStruct) internal view returns (IPremiumSeller) {
        return layoutStruct.premiumSeller;
    }

    function _premiumSeller() internal view returns (IPremiumSeller) {
        return _premiumSeller(_layoutStruct());
    }

    function _taxCollector(Storage storage layoutStruct) internal view returns (ITaxCollector) {
        return layoutStruct.taxCollector;
    }

    function _taxCollector() internal view returns (ITaxCollector) {
        return _taxCollector(_layoutStruct());
    }

    function _pteam(Storage storage layoutStruct) internal view returns (IPTEAM) {
        return layoutStruct.pteam;
    }

    function _pteam() internal view returns (IPTEAM) {
        return _pteam(_layoutStruct());
    }

    function _canonicalPair(Storage storage layoutStruct) internal view returns (IUniswapV2Pair) {
        return layoutStruct.canonicalPair;
    }

    function _canonicalPair() internal view returns (IUniswapV2Pair) {
        return _canonicalPair(_layoutStruct());
    }

    function _router(Storage storage layoutStruct) internal view returns (IUniswapV2Router02) {
        return layoutStruct.router;
    }

    function _router() internal view returns (IUniswapV2Router02) {
        return _router(_layoutStruct());
    }

    function _turboRouter(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.turboRouter;
    }

    function _turboRouter() internal view returns (address) {
        return _turboRouter(_layoutStruct());
    }

    function _wsNet(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.wsNet;
    }

    function _wsNet() internal view returns (address) {
        return _wsNet(_layoutStruct());
    }

    function _zap(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.zap;
    }

    function _zap() internal view returns (address) {
        return _zap(_layoutStruct());
    }

    function _morpho(Storage storage layoutStruct) internal view returns (IMorpho) {
        return layoutStruct.morpho;
    }

    function _morpho() internal view returns (IMorpho) {
        return _morpho(_layoutStruct());
    }

    function _loopbackMarketId(Storage storage layoutStruct) internal view returns (bytes32) {
        return layoutStruct.loopbackMarketId;
    }

    function _loopbackMarketId() internal view returns (bytes32) {
        return _loopbackMarketId(_layoutStruct());
    }

    function _morphoVault(Storage storage layoutStruct) internal view returns (IERC4626) {
        return layoutStruct.morphoVault;
    }

    function _morphoVault() internal view returns (IERC4626) {
        return _morphoVault(_layoutStruct());
    }

    function _pTeamHolder(Storage storage layoutStruct) internal view returns (address) {
        return layoutStruct.pTeamHolder;
    }

    function _pTeamHolder() internal view returns (address) {
        return _pTeamHolder(_layoutStruct());
    }
}
// end::NetNetAwareRepo[]
