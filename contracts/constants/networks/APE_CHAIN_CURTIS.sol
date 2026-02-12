// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

library APE_CHAIN_CURTIS {
    uint256 constant CHAIN_ID = 33111;

    address payable constant WAPE = payable(0x7e03a497f6719d883E441f1C31b82Dc2bB096CCE);

    address constant CAMELOT_FACTORY_V2 = 0x7d8c6B58BA2d40FC6E34C25f9A488067Fe0D2dB4;

    bytes32 constant CAMELOT_PAIR_CODE_HASH = 0xba70494e4abe6721f3f96552635a28b70921f79b39c6b06ab9cb14618a78df9f;

    address constant CAMELOT_ROUTER_V2 = 0x18E621B64d7808c3C47bccbbD7485d23F257D26f;
}
