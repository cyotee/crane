// SPDX-FileCopyrightText: 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// https://github.com/makerdao/mip21-toolkit/blob/master/src/tokens/RwaTokenFactory.sol
interface RwaTokenFactoryAbstract {
    function createRwaToken(string calldata, string calldata, address) external returns (address);
}
