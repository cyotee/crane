// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Initializable} from "@crane/contracts/external/openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {AToken} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/tokenization/AToken.sol";
import {StataTokenV2} from "@crane/contracts/protocols/lending/aave/v3.6/extensions/stata-token/StataTokenV2.sol"; // TODO: change import to isolate to 4626
import {DataTypes} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/types/DataTypes.sol";
import {BaseTest} from "./TestBase.sol";

contract StataTokenV2GettersTest is BaseTest {
    function test_initializeShouldRevert() public {
        address impl = factory.STATA_TOKEN_IMPL();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        StataTokenV2(impl).initialize(aToken, "hey", "ho");
    }

    function test_getters() public view {
        assertEq(stataTokenV2.name(), "Wrapped Aave Local WETH");
        assertEq(stataTokenV2.symbol(), "waLocWETH");

        address referenceAsset = stataTokenV2.getReferenceAsset();
        assertEq(referenceAsset, aToken);

        address underlyingAddress = address(stataTokenV2.asset());
        assertEq(underlyingAddress, underlying);

        assertEq(stataTokenV2.aToken(), contracts.poolProxy.getReserveAToken(underlyingAddress));

        IERC20Metadata underlying = IERC20Metadata(underlyingAddress);
        assertEq(stataTokenV2.decimals(), underlying.decimals());

        assertEq(address(stataTokenV2.INCENTIVES_CONTROLLER()), address(AToken(aToken).getIncentivesController()));
    }
}
