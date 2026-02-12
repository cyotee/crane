// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {ICowRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowRouter.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";

/* -------------------------------------------------------------------------- */
/*                              Real Facet Imports                            */
/* -------------------------------------------------------------------------- */

import {BalancerV3VaultAwareFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol";
import {BalancerV3AuthenticationFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationFacet.sol";
import {CowRouterFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                   DFPkg                                    */
/* -------------------------------------------------------------------------- */

import {CowRouterDFPkg, ICowRouterDFPkg} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterDFPkg.sol";

contract MockBalancerV3Vault {
    function getAuthorizer() external pure returns (address) {
        return address(0);
    }
}

contract CowRouterDFPkg_Integration_Test is CraneTest {
    CowRouterDFPkg internal pkg;

    BalancerV3VaultAwareFacet internal vaultAwareFacet;
    BalancerV3AuthenticationFacet internal authFacet;
    CowRouterFacet internal cowRouterFacet;

    MockBalancerV3Vault internal mockVault;

    address internal feeSweeper;

    function setUp() public override {
        CraneTest.setUp();

        mockVault = new MockBalancerV3Vault();
        vm.label(address(mockVault), "MockBalancerV3Vault");

        feeSweeper = makeAddr("feeSweeper");

        _deployRealFacets();
        _deployPkg();
    }

    function _deployRealFacets() internal {
        vaultAwareFacet = new BalancerV3VaultAwareFacet();
        authFacet = new BalancerV3AuthenticationFacet();
        cowRouterFacet = new CowRouterFacet();

        vm.label(address(vaultAwareFacet), "BalancerV3VaultAwareFacet");
        vm.label(address(authFacet), "BalancerV3AuthenticationFacet");
        vm.label(address(cowRouterFacet), "CowRouterFacet");
    }

    function _deployPkg() internal {
        pkg = new CowRouterDFPkg(
            ICowRouterDFPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                cowRouterFacet: IFacet(address(cowRouterFacet)),
                balancerV3Vault: IVault(address(mockVault)),
                diamondFactory: diamondFactory
            })
        );
        vm.label(address(pkg), "CowRouterDFPkg");
    }

    function test_deployProxy_viaRealFactory_andSelectorsResolve() public {
        bytes memory pkgArgs = abi.encode(
            ICowRouterDFPkg.PkgArgs({
                protocolFeePercentage: 10e16,
                feeSweeper: feeSweeper
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);
        vm.label(proxy, "CowRouterProxy");

        IDiamondLoupe loupe = IDiamondLoupe(proxy);
        assertEq(
            loupe.facetAddress(IBalancerV3VaultAware.balV3Vault.selector),
            address(vaultAwareFacet),
            "balV3Vault selector should map to VaultAwareFacet"
        );
        assertEq(
            loupe.facetAddress(ICowRouter.getFeeSweeper.selector),
            address(cowRouterFacet),
            "getFeeSweeper selector should map to CowRouterFacet"
        );
    }
}
