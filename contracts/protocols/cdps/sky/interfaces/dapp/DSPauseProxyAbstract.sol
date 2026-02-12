// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// https://github.com/dapphub/ds-pause
interface DSPauseProxyAbstract {
    function owner() external view returns (address);
    function exec(address, bytes calldata) external returns (bytes memory);
}
