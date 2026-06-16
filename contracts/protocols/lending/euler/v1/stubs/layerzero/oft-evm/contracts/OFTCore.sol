// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract OFTCore {
    uint8 public immutable sharedDecimals;
    address public immutable lzEndpoint;
    address public immutable delegate;

    constructor(uint8 sharedDecimals_, address lzEndpoint_, address delegate_) {
        sharedDecimals = sharedDecimals_;
        lzEndpoint = lzEndpoint_;
        delegate = delegate_;
    }

    function token() public view virtual returns (address);
    function approvalRequired() external view virtual returns (bool);

    function _debit(address from, uint256 amountLD, uint256 minAmountLD, uint32 dstEid)
        internal
        virtual
        returns (uint256 amountSentLD, uint256 amountReceivedLD);

    function _debitView(uint256 amountLD, uint256 minAmountLD, uint32)
        internal
        pure
        virtual
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        require(amountLD >= minAmountLD, "OFTCore: amount slippage");
        return (amountLD, amountLD);
    }

    function _credit(address to, uint256 amountLD, uint32 srcEid) internal virtual returns (uint256 amountReceivedLD);
}
