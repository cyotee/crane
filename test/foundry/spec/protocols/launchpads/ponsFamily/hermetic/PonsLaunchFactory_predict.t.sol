// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_PonsFamily
} from "@crane/contracts/protocols/launchpads/ponsFamily/test/bases/TestBase_PonsFamily.sol";
import {PonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/pons/PonsLaunchFactory.sol";

contract PonsLaunchFactory_predict_Test is TestBase_PonsFamily {
    function test_predictTokenAddress_matchesDeploy() public {
        PonsLaunchFactory.TokenParams memory params = _defaultTokenParams("Predict", "PRD");
        bytes32 saltStart = keccak256("predict-vanity-1");

        (bytes32 deploySalt, address predictedVanity) = ponsFactory.predictVanityTokenAddress(
            params, ponsLaunchConfigId, ponsDexId, saltStart, ponsLauncher
        );

        // Direct CREATE2 predict with the resolved vanity salt must match vanity preview.
        address predictedDirect =
            ponsFactory.predictTokenAddress(params, ponsLaunchConfigId, ponsDexId, deploySalt, ponsLauncher);
        assertEq(predictedDirect, predictedVanity, "predict paths agree");
        assertEq(uint16(uint160(predictedVanity)), 0xbbbb, "predicted vanity suffix");

        // Launch with the same saltStart; factory re-resolves to the same deploySalt.
        address deployed = _launchWithoutSeed(params, saltStart);
        assertEq(deployed, predictedVanity, "deployed == predicted");
        assertEq(deployed, predictedDirect, "deployed == direct predict");
    }
}
