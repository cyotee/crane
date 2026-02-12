// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IAuthentication} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";

/**
 * @notice Building block for performing access control on external functions.
 * @dev Vendored from Balancer V3 Solidity Utils.
 */
abstract contract Authentication is IAuthentication {
    bytes32 private immutable _actionIdDisambiguator;

    constructor(bytes32 actionIdDisambiguator) {
        _actionIdDisambiguator = actionIdDisambiguator;
    }

    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    function _authenticateCaller() internal view {
        bytes32 actionId = getActionId(msg.sig);
        if (!_canPerform(actionId, msg.sender)) {
            revert SenderNotAllowed();
        }
    }

    function getActionId(bytes4 selector) public view override returns (bytes32) {
        return keccak256(abi.encodePacked(_actionIdDisambiguator, selector));
    }

    function _canPerform(bytes32 actionId, address user) internal view virtual returns (bool);
}
