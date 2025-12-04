// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/tokens/ERC20TargetStub.sol";
import "contracts/tokens/ERC20/TestBase_ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract ERC20TargetStubInvariantTest is TestBase_ERC20 {
    function _deployToken(ERC20TargetStubHandler handler_) internal virtual override returns (IERC20 token_) {
        token_ = new ERC20TargetStub(address(handler_), 1_000_000_000e18);
    }
}
