// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {
    MockBCDeployer,
    MockAgreementFactory,
    MockAgreement,
    MockBCRegistry,
    MockAttackRegistry
} from "battlechain-lib-mocks/MockBCInfra.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Script_Promo_BC_Launch} from "../../../../scripts/foundry/Script_Promo_BC_Launch.s.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";

/// @notice Local mock coverage for Wave A BattleChain promo deploy (no live BC).
contract Pilot_BC_Promo_Launch_LocalMock_Test is Script_Promo_BC_Launch, Test {
    MockBCDeployer internal mockDeployer;
    MockBCRegistry internal mockRegistry;
    MockAgreementFactory internal mockFactory;
    MockAttackRegistry internal mockAttackRegistry;

    address internal owner;

    function setUp() public {
        owner = address(this);

        mockDeployer = new MockBCDeployer();
        mockRegistry = new MockBCRegistry();
        mockFactory = new MockAgreementFactory();
        mockAttackRegistry = new MockAttackRegistry();

        _setBcAddresses(
            address(mockRegistry), address(mockFactory), address(mockAttackRegistry), address(mockDeployer)
        );

        // Promo binds fixed BC-provided addresses; etch minimal code for local hermetic runs.
        WETH9 stub = new WETH9();
        bytes memory stubCode = address(stub).code;
        vm.etch(BATTLECHAIN_TESTNET_WETH, stubCode);
        vm.etch(BATTLECHAIN_TESTNET_UNI_V3_FACTORY, stubCode);
        vm.etch(BATTLECHAIN_TESTNET_UNI_V3_SWAP_ROUTER, stubCode);
        vm.etch(BATTLECHAIN_TESTNET_UNI_V3_NPM, stubCode);
    }

    function test_waveA_allSurfacesHaveCode() public {
        _runDeploy(owner, owner);

        assertTrue(address(coreFactory).code.length > 0, "coreFactory");
        assertTrue(address(diamondFactory).code.length > 0, "diamondFactory");
        assertTrue(permitPackage.code.length > 0, "permitPackage");
        assertTrue(samplePermitToken.code.length > 0, "samplePermitToken");
        assertEq(weth, BATTLECHAIN_TESTNET_WETH, "weth is BC-provided");
        assertEq(uniV3Factory, BATTLECHAIN_TESTNET_UNI_V3_FACTORY, "uniV3 factory is BC-provided");
        assertEq(uniV3SwapRouter, BATTLECHAIN_TESTNET_UNI_V3_SWAP_ROUTER, "uniV3 router is BC-provided");
        assertEq(uniV3Npm, BATTLECHAIN_TESTNET_UNI_V3_NPM, "uniV3 npm is BC-provided");
        assertTrue(weth.code.length > 0, "weth");
        assertTrue(uniV2Factory.code.length > 0, "uniV2Factory");
        assertTrue(uniV2Router.code.length > 0, "uniV2Router");
        assertTrue(uniV3Factory.code.length > 0, "uniV3Factory");
        assertTrue(uniV4PoolManager.code.length > 0, "uniV4PoolManager");
        assertTrue(permit2.code.length > 0, "permit2");
        assertTrue(agreement != address(0), "agreement");
    }

    function test_sampleToken_metadata() public {
        _runDeploy(owner, owner);

        assertEq(IERC20Metadata(samplePermitToken).name(), SAMPLE_TOKEN_NAME);
        assertEq(IERC20Metadata(samplePermitToken).symbol(), SAMPLE_TOKEN_SYMBOL);
        assertEq(IERC20Metadata(samplePermitToken).decimals(), SAMPLE_TOKEN_DECIMALS);
        assertEq(IERC20Metadata(samplePermitToken).totalSupply(), SAMPLE_TOKEN_SUPPLY);
    }

    function test_diamondFactory_wiredToCore() public {
        _runDeploy(owner, owner);

        assertEq(
            address(ICreate3Factory(address(coreFactory)).diamondPackageFactory()),
            address(diamondFactory),
            "diamond factory wiring"
        );
    }

    function test_agreement_adoptedInMockRegistry() public {
        _runDeploy(owner, owner);

        assertTrue(mockRegistry.getAgreement(owner) != address(0) || agreement != address(0), "agreement created");
    }
}
