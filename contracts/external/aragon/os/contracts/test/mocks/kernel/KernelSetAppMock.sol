pragma solidity >=0.4.24 <0.9.0;

import "../../../kernel/Kernel.sol";

contract KernelSetAppMock is Kernel {
    constructor() Kernel(false) public {
    }

    // Overloaded mock to bypass the auth and isContract checks
    function setApp(bytes32 _namespace, bytes32 _appId, address _app) public {
        apps[_namespace][_appId] = _app;
    }
}
