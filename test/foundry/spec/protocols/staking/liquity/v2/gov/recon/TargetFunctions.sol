// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.35;

import {BaseTargetFunctions} from "@crane/contracts/external/chimera/BaseTargetFunctions.sol";
import {vm} from "@crane/contracts/external/chimera/Hevm.sol";
import {IERC20Permit} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Permit.sol";
import {console2} from "forge-std/Test.sol";

import {Properties} from "./Properties.sol";
import {GovernanceTargets} from "./targets/GovernanceTargets.sol";
import {BribeInitiativeTargets} from "./targets/BribeInitiativeTargets.sol";
import {MaliciousInitiative} from "../mocks/MaliciousInitiative.sol";
import {BribeInitiative} from "@crane/contracts/protocols/cdps/liquity/v2/gov/BribeInitiative.sol";
import {ILQTYStaking} from "@crane/contracts/protocols/cdps/liquity/v2/gov/interfaces/ILQTYStaking.sol";
import {IInitiative} from "@crane/contracts/protocols/cdps/liquity/v2/gov/interfaces/IInitiative.sol";
import {IUserProxy} from "@crane/contracts/protocols/cdps/liquity/v2/gov/interfaces/IUserProxy.sol";
import {PermitParams} from "@crane/contracts/protocols/cdps/liquity/v2/gov/utils/Types.sol";

abstract contract TargetFunctions is GovernanceTargets, BribeInitiativeTargets {
    // helper to deploy initiatives for registering that results in more bold transferred to the Governance contract
    function helper_deployInitiative() public withChecks {
        address initiative = address(new BribeInitiative(address(governance), address(lusd), address(lqty)));
        deployedInitiatives.push(initiative);
    }

    // helper to simulate bold accrual in Governance contract
    function helper_accrueBold(uint256 boldAmount) public withChecks {
        boldAmount = uint256(boldAmount % lusd.balanceOf(user));
        // target contract is the user so it can transfer directly
        lusd.transfer(address(governance), boldAmount);
    }
}
