// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IBoldToken} from "@crane/contracts/protocols/staking/liquity/v2/bold/Interfaces/IBoldToken.sol";
import {ICollateralRegistry} from "@crane/contracts/protocols/staking/liquity/v2/bold/Interfaces/ICollateralRegistry.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {HintHelpers} from "@crane/contracts/protocols/staking/liquity/v2/bold/HintHelpers.sol";
import {TestDeployer} from "./Deployment.t.sol";

contract BaseMultiCollateralTest {
    struct Contracts {
        IWETH weth;
        ICollateralRegistry collateralRegistry;
        IBoldToken boldToken;
        HintHelpers hintHelpers;
        TestDeployer.LiquityContractsDev[] branches;
    }

    IERC20 weth;
    ICollateralRegistry collateralRegistry;
    IBoldToken boldToken;
    HintHelpers hintHelpers;
    TestDeployer.LiquityContractsDev[] branches;

    function setupContracts(Contracts memory contracts) internal {
        weth = contracts.weth;
        collateralRegistry = contracts.collateralRegistry;
        boldToken = contracts.boldToken;
        hintHelpers = contracts.hintHelpers;

        for (uint256 i = 0; i < contracts.branches.length; ++i) {
            branches.push(contracts.branches[i]);
        }
    }
}
