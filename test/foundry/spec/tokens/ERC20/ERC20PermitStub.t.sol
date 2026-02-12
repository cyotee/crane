// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/tokens/ERC20/TestBase_ERC20Permit.sol";
import "contracts/tokens/ERC20/ERC20PermitStub.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

contract ERC20PermitStubInvariantTest is TestBase_ERC20Permit {
    function _deployToken(ERC20TargetStubHandler handler_) internal virtual override returns (IERC20 token_) {
        token_ = IERC20(address(new ERC20PermitStub("Test Tokens", "TT", 18, address(handler_), 1_000_000_000e18)));
    }
}
