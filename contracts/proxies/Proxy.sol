// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// solhint-disable no-complex-fallback
// solhint-disable no-empty-blocks
// solhint-disable reason-string
// solhint-disable no-inline-assembly
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";

/**
 * @title Base proxy contract
 */
// TODO Write NatSpec comments.
// TODO Complete unit testing for all functions.
abstract contract Proxy {
    using BetterAddress for address;

    // error TargetNotValid(address invalidTarget);
    error NoTargetFor(bytes4 selector);

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    // TODO Define all Consider as SPIKE once Anchor config is updated.
    // TODO Consider reverting if msg.sender is address(0).
    // Has implications with RPC providers that use address(0) when calling view functions.
    fallback() external payable {
        address target = _getTarget();
        if (!target.isContract()) {
            revert NoTargetFor(msg.sig);
        }

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}

    /**
     * @notice get logic implementation address
     * @return target_ DELEGATECALL address target
     */
    function _getTarget() internal virtual returns (address target_);
}
