// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {IHooks} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IHooks.sol";
import {PoolKey} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";
import {Currency} from "@crane/contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {PoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/PoolManager.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IUniswapV4ProtocolAware} from "@crane/contracts/interfaces/IUniswapV4ProtocolAware.sol";
import {IUniswapV4SinglePositionAware} from "@crane/contracts/interfaces/IUniswapV4SinglePositionAware.sol";
import {UniswapV4ProtocolAwareRepo} from "@crane/contracts/protocols/dexes/uniswap/v4/aware/UniswapV4ProtocolAwareRepo.sol";
import {UniswapV4ProtocolAwareTarget} from "@crane/contracts/protocols/dexes/uniswap/v4/aware/UniswapV4ProtocolAwareTarget.sol";
import {UniswapV4ProtocolAwareFacet} from "@crane/contracts/protocols/dexes/uniswap/v4/aware/UniswapV4ProtocolAwareFacet.sol";
import {UniswapV4SinglePositionAwareRepo} from "@crane/contracts/protocols/dexes/uniswap/v4/aware/UniswapV4SinglePositionAwareRepo.sol";
import {UniswapV4SinglePositionAwareTarget} from "@crane/contracts/protocols/dexes/uniswap/v4/aware/UniswapV4SinglePositionAwareTarget.sol";
import {UniswapV4SinglePositionAwareFacet} from "@crane/contracts/protocols/dexes/uniswap/v4/aware/UniswapV4SinglePositionAwareFacet.sol";

contract UniswapV4AwareHarness is UniswapV4ProtocolAwareTarget, UniswapV4SinglePositionAwareTarget {
    function initializeProtocol(
        IPoolManager manager_,
        address descriptor_,
        address positionManager_,
        address quoter_,
        address stateView_,
        address lens_,
        address router_
    ) external {
        UniswapV4ProtocolAwareRepo._initialize(manager_, descriptor_, positionManager_, quoter_, stateView_, lens_, router_);
    }

    function initializePosition(PoolKey memory key_, int24 lower_, int24 upper_, bytes32 salt_) external {
        UniswapV4SinglePositionAwareRepo._initialize(key_, lower_, upper_, salt_);
    }
}

contract UniswapV4Aware_Test is Test {
    UniswapV4AwareHarness internal harness;
    IPoolManager internal manager;

    function setUp() public {
        harness = new UniswapV4AwareHarness();
        manager = IPoolManager(address(new PoolManager(address(this))));
    }

    function test_protocolSlot() public pure {
        bytes32 expected = bytes32(uint256(keccak256(abi.encode("protocols.dexes.uniswap.v4.protocol.aware"))) - 1);
        assertEq(UniswapV4ProtocolAwareRepo.STORAGE_SLOT, expected);
    }

    function test_positionSlot() public pure {
        bytes32 expected = bytes32(uint256(keccak256(abi.encode("protocols.dexes.uniswap.v4.singlePosition.aware"))) - 1);
        assertEq(UniswapV4SinglePositionAwareRepo.STORAGE_SLOT, expected);
    }

    function test_protocolGetters() public {
        harness.initializeProtocol(manager, address(1), address(2), address(3), address(4), address(5), address(6));
        assertEq(address(harness.poolManager()), address(manager));
        assertEq(harness.positionDescriptor(), address(1));
        assertEq(harness.positionManager(), address(2));
        assertEq(harness.quoter(), address(3));
        assertEq(harness.stateView(), address(4));
        assertEq(harness.reservesLens(), address(5));
        assertEq(harness.universalRouter(), address(6));
    }

    function test_positionGettersAndEmptyLiquidity() public {
        PoolKey memory key_ = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(address(0xBEEF)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
        harness.initializeProtocol(manager, address(0), address(0), address(0), address(0), address(0), address(0));
        harness.initializePosition(key_, -60, 60, bytes32(0));
        PoolKey memory stored_ = harness.poolKey();
        assertEq(Currency.unwrap(stored_.currency0), address(0));
        assertEq(Currency.unwrap(stored_.currency1), address(0xBEEF));
        assertEq(stored_.fee, 3000);
        assertEq(stored_.tickSpacing, 60);
        assertEq(harness.tickLower(), int24(-60));
        assertEq(harness.tickUpper(), int24(60));
        assertEq(harness.positionSalt(), bytes32(0));
        assertEq(uint256(harness.positionLiquidity()), 0);
    }

    function test_facetSelectors() public {
        UniswapV4ProtocolAwareFacet protocol_ = new UniswapV4ProtocolAwareFacet();
        UniswapV4SinglePositionAwareFacet position_ = new UniswapV4SinglePositionAwareFacet();
        assertEq(protocol_.facetName(), "UniswapV4ProtocolAwareFacet");
        assertEq(position_.facetName(), "UniswapV4SinglePositionAwareFacet");
        assertEq(protocol_.facetInterfaces()[0], type(IUniswapV4ProtocolAware).interfaceId);
        assertEq(position_.facetInterfaces()[0], type(IUniswapV4SinglePositionAware).interfaceId);
        assertEq(protocol_.facetFuncs().length, 7);
        assertEq(position_.facetFuncs().length, 5);
        assertEq(protocol_.facetFuncs()[0], IUniswapV4ProtocolAware.poolManager.selector);
        assertEq(position_.facetFuncs()[4], IUniswapV4SinglePositionAware.positionLiquidity.selector);
        assertEq(IFacet(address(protocol_)).facetFuncs().length, 7);
    }
}
