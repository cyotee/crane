// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {NoncesKeyed} from "@crane/contracts/protocols/lending/aave/v4/utils/NoncesKeyed.sol";

contract MockNoncesKeyed is NoncesKeyed {
    function useCheckedNonce(address owner, uint256 keyNonce) public {
        _useCheckedNonce(owner, keyNonce);
    }
}
