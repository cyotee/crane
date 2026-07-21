pragma solidity >=0.4.24 <0.9.0;

import "../../../kernel/Kernel.sol";


contract UpgradedKernel is Kernel {
    constructor(bool _shouldPetrify) Kernel(_shouldPetrify) public {}

    // just adds one more function to the kernel implementation.
    // calling this function on the previous instance will fail
    function isUpgraded() public pure returns (bool) {
        return true;
    }
}
