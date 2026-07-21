pragma solidity >=0.4.24 <0.9.0;

import "../../../common/DepositableStorage.sol";
import "../../../kernel/Kernel.sol";

contract KernelDepositableMock is Kernel, DepositableStorage {
    constructor(bool _shouldPetrify) Kernel(_shouldPetrify) public {
    }

    function () external payable {
        require(isDepositable());
    }

    function enableDeposits() external isInitialized {
        setDepositable(true);
    }
}
