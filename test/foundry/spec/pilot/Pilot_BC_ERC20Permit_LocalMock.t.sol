// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {ChildContractScope, AgreementDetails} from "battlechain-lib/types/AgreementTypes.sol";
import {IAgreementFactory} from "@battlechain-contracts/interface/IAgreementFactory.sol";
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

import {Script_Pilot_BC_ERC20Permit} from "../../../../scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";
import {IERC20PermitDFPkg} from "@crane/contracts/tokens/ERC20/ERC20PermitDFPkg.sol";

contract Pilot_BC_ERC20Permit_LocalMock_Test is Script_Pilot_BC_ERC20Permit, Test {
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    MockBCDeployer internal mockDeployer;
    MockBCRegistry internal mockRegistry;
    MockAgreementFactory internal mockFactory;
    MockAttackRegistry internal mockAttackRegistry;

    uint256 internal ownerPk;
    address internal owner;
    address internal spender;

    function setUp() public {
        ownerPk = 0xA11CE;
        owner = vm.addr(ownerPk);
        spender = address(0xBEEF);

        mockDeployer = new MockBCDeployer();
        mockRegistry = new MockBCRegistry();
        mockFactory = new MockAgreementFactory();
        mockAttackRegistry = new MockAttackRegistry();

        _setBcAddresses(address(mockRegistry), address(mockFactory), address(mockAttackRegistry), address(mockDeployer));
    }

    function test_coreFactory_deployedViaBcDeployer() public {
        _runDeploy(address(this), owner);

        assertTrue(address(coreFactory).code.length > 0, "coreFactory has code");
        assertTrue(address(diamondFactory).code.length > 0, "diamondFactory has code");
        assertTrue(permitPackage.code.length > 0, "permitPackage has code");
        assertTrue(permitProxy.code.length > 0, "permitProxy has code");
    }

    function test_diamondFactory_isWiredToCoreFactory() public {
        _runDeploy(address(this), owner);

        assertEq(
            address(ICreate3Factory(address(coreFactory)).diamondPackageFactory()),
            address(diamondFactory),
            "core factory's diamond factory should match"
        );
    }

    function test_proxy_addressIsDeterministic() public {
        _runDeploy(address(this), owner);

        bytes memory args = abi.encode(
            IERC20PermitDFPkg.PkgArgs({
                name: TOKEN_NAME,
                symbol: TOKEN_SYMBOL,
                decimals: TOKEN_DECIMALS,
                totalSupply: TOKEN_SUPPLY,
                recipient: owner,
                optionalSalt: bytes32(0)
            })
        );

        assertEq(
            diamondFactory.calcAddress(IDiamondFactoryPackage(permitPackage), args),
            permitProxy,
            "calcAddress should match deployed proxy"
        );
    }

    function test_agreementDetails_listCoreFactory_withChildScopeAll() public {
        _runDeploy(address(this), owner);

        AgreementDetails memory d = _buildAgreementDetails();
        assertEq(d.chains.length, 1, "one chain");
        assertEq(d.chains[0].accounts.length, 1, "one account in scope");
        assertEq(d.chains[0].accounts[0].accountAddress, vm.toString(address(coreFactory)), "account is core factory");
        assertEq(uint8(d.chains[0].accounts[0].childContractScope), uint8(ChildContractScope.All), "scope must be All");
    }

    function test_agreementFactory_calledWithExpectedDetails() public {
        // Snapshot/revert dance: we need the coreFactory address to build the matcher,
        // but it is only known after _runDeploy. Run once to learn it, revert, then
        // install the expectCall and re-run.
        uint256 snap = vm.snapshotState();
        _runDeploy(address(this), owner);
        address expectedFactory = address(coreFactory);
        vm.revertToState(snap);

        address[] memory scope = new address[](1);
        scope[0] = expectedFactory;
        AgreementDetails memory expected =
            defaultAgreementDetails(_protocolName(), _contacts(), scope, _recoveryAddress());

        vm.expectCall(
            address(mockFactory), abi.encodeCall(IAgreementFactory.create, (expected, address(this), AGREEMENT_SALT))
        );
        _runDeploy(address(this), owner);
    }

    function test_adoption_andCommitmentWindow() public {
        _runDeploy(address(this), owner);

        // Adopter is whoever called adoptSafeHarbor — i.e. this test contract.
        assertEq(mockRegistry.getAgreement(address(this)), agreement, "adoption registered");
        assertGt(MockAgreement(agreement).cantChangeUntil(), block.timestamp, "commitment window set");
    }

    function test_proxy_erc20Metadata() public {
        _runDeploy(address(this), owner);

        IERC20Metadata md = IERC20Metadata(permitProxy);
        assertEq(md.name(), TOKEN_NAME, "name");
        assertEq(md.symbol(), TOKEN_SYMBOL, "symbol");
        assertEq(md.decimals(), TOKEN_DECIMALS, "decimals");

        IERC20 t = IERC20(permitProxy);
        assertEq(t.totalSupply(), TOKEN_SUPPLY, "totalSupply");
        assertEq(t.balanceOf(owner), TOKEN_SUPPLY, "recipient balance");
    }

    function test_proxy_domainSeparator_nonZero_nonces_startAtZero() public {
        _runDeploy(address(this), owner);

        IERC2612 t = IERC2612(permitProxy);
        assertEq(t.nonces(owner), 0, "initial nonce zero");
        assertTrue(t.DOMAIN_SEPARATOR() != bytes32(0), "DOMAIN_SEPARATOR non-zero");
    }

    function test_proxy_permitSignature_updatesAllowanceAndNonce() public {
        _runDeploy(address(this), owner);

        uint256 value = 25 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = IERC2612(permitProxy).nonces(owner);

        bytes32 digest = _permitDigest(owner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        assertEq(IERC20(permitProxy).allowance(owner, spender), 0, "precondition: allowance zero");

        IERC2612(permitProxy).permit(owner, spender, value, deadline, v, r, s);

        assertEq(IERC20(permitProxy).allowance(owner, spender), value, "allowance updated");
        assertEq(IERC2612(permitProxy).nonces(owner), nonce + 1, "nonce incremented");
    }

    function _permitDigest(address owner_, address spender_, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, value, nonce, deadline));
        bytes32 ds = IERC2612(permitProxy).DOMAIN_SEPARATOR();
        return keccak256(abi.encodePacked("\x19\x01", ds, structHash));
    }
}
