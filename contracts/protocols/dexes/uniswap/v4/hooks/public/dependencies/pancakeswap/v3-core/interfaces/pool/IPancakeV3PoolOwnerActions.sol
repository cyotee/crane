// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IPancakeV3PoolOwnerActions {
    function setFeeProtocol(uint32 feeProtocol0, uint32 feeProtocol1) external;

    function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested)
        external
        returns (uint128 amount0, uint128 amount1);

    function setLmPool(address lmPool) external;
}