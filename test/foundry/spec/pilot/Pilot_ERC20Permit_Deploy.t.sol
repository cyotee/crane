// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";
import {IERC20PermitDFPkg, ERC20PermitDFPkg} from "@crane/contracts/tokens/ERC20/ERC20PermitDFPkg.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {ERC2612Facet} from "@crane/contracts/tokens/ERC2612/ERC2612Facet.sol";
import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

contract Pilot_ERC20Permit_Deploy_Test is Test {
    using BetterEfficientHashLib for bytes;

    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    ICreate3FactoryProxy internal factory;
    IDiamondPackageCallBackFactory internal diamondFactory;

    IFacet internal erc20Facet;
    IFacet internal erc5267Facet;
    IFacet internal erc2612Facet;

    IERC20PermitDFPkg internal erc20PermitPkg;
    IERC20 internal token;

    uint256 internal ownerPk;
    address internal owner;
    address internal spender;

    IERC20PermitDFPkg.PkgArgs internal pkgArgs;

    function setUp() public {
        ownerPk = 0xA11CE;
        owner = vm.addr(ownerPk);
        spender = address(0xBEEF);

        pkgArgs = IERC20PermitDFPkg.PkgArgs({
            name: "Pilot Permit Token",
            symbol: "PPT",
            decimals: 18,
            totalSupply: 1_000_000e18,
            recipient: owner,
            optionalSalt: keccak256("pilot-erc20-permit")
        });

        (factory, diamondFactory) = InitDevService.initEnv(address(this));

        erc20Facet = factory.deployFacet(type(ERC20Facet).creationCode, abi.encode(type(ERC20Facet).name)._hash());
        erc5267Facet =
            factory.deployFacet(type(ERC5267Facet).creationCode, abi.encode(type(ERC5267Facet).name)._hash());
        erc2612Facet =
            factory.deployFacet(type(ERC2612Facet).creationCode, abi.encode(type(ERC2612Facet).name)._hash());

        erc20PermitPkg = IERC20PermitDFPkg(
            address(
                factory.deployPackageWithArgs(
                    type(ERC20PermitDFPkg).creationCode,
                    abi.encode(
                        IERC20PermitDFPkg.PkgInit({
                            erc20Facet: erc20Facet,
                            erc5267Facet: erc5267Facet,
                            erc2612Facet: erc2612Facet
                        })
                    ),
                    abi.encode(type(ERC20PermitDFPkg).name)._hash()
                )
            )
        );

        token = IERC20(
            diamondFactory.deploy(IDiamondFactoryPackage(address(erc20PermitPkg)), abi.encode(pkgArgs))
        );
    }

    function test_pilot_bootstrap_deploysFactoriesAndPermitProxy() public view {
        assertTrue(address(factory) != address(0), "factory should be deployed");
        assertTrue(address(diamondFactory) != address(0), "diamondFactory should be deployed");
        assertTrue(address(erc20PermitPkg) != address(0), "permit package should be deployed");
        assertTrue(address(token) != address(0), "token proxy should be deployed");

        assertEq(IERC20Metadata(address(token)).name(), pkgArgs.name, "name mismatch");
        assertEq(IERC20Metadata(address(token)).symbol(), pkgArgs.symbol, "symbol mismatch");
        assertEq(IERC20Metadata(address(token)).decimals(), pkgArgs.decimals, "decimals mismatch");

        assertEq(token.totalSupply(), pkgArgs.totalSupply, "supply mismatch");
        assertEq(token.balanceOf(pkgArgs.recipient), pkgArgs.totalSupply, "recipient supply mismatch");

        assertEq(IERC2612(address(token)).nonces(owner), 0, "initial nonce should be zero");
        assertTrue(IERC2612(address(token)).DOMAIN_SEPARATOR() != bytes32(0), "domain separator should be set");
    }

    function test_pilot_permit_validSignature_updatesAllowanceAndNonce() public {
        uint256 value = 25e18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = IERC2612(address(token)).nonces(owner);

        bytes32 digest = _permitDigest(owner, spender, value, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        assertEq(token.allowance(owner, spender), 0, "precondition allowance should be zero");

        IERC2612(address(token)).permit(owner, spender, value, deadline, v, r, s);

        assertEq(token.allowance(owner, spender), value, "allowance should match signed value");
        assertEq(IERC2612(address(token)).nonces(owner), nonce + 1, "nonce should increment");
    }

    function test_pilot_calcAddress_matchesDeployedProxy() public view {
        address predicted =
            diamondFactory.calcAddress(IDiamondFactoryPackage(address(erc20PermitPkg)), abi.encode(pkgArgs));

        assertEq(predicted, address(token), "predicted address must match deployed proxy");
    }

    function test_pilot_sameArgs_secondDeploy_returnsSameAddress() public {
        address deployedAgain =
            diamondFactory.deploy(IDiamondFactoryPackage(address(erc20PermitPkg)), abi.encode(pkgArgs));

        assertEq(deployedAgain, address(token), "re-deploy with same args should be idempotent");
    }

    function _permitDigest(address owner_, address spender_, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, value, nonce, deadline));
        bytes32 domainSeparator = IERC2612(address(token)).DOMAIN_SEPARATOR();
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
