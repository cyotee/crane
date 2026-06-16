// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract OFTAdapterUpgradeable {
    address public immutable token;
    address public immutable lzEndpoint;

    bool private _initializersDisabled;
    bool private _initialized;

    constructor(address token_, address lzEndpoint_) {
        token = token_;
        lzEndpoint = lzEndpoint_;
    }

    modifier initializer() {
        require(!_initializersDisabled && !_initialized, "Initializable: already initialized");
        _initialized = true;
        _;
    }

    function _disableInitializers() internal virtual {
        _initializersDisabled = true;
    }

    function __OFTAdapter_init(address) internal virtual {}

    function __Ownable_init(address) internal virtual {}
}
