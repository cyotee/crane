// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";

import {
    IMorpho,
    Id,
    MarketParams,
    Market,
    Position
} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {Morpho} from "@crane/contracts/external/morpho/blue/Morpho.sol";
import {OracleMock} from "@crane/contracts/external/morpho/blue/mocks/OracleMock.sol";
import {ERC20Mock} from "@crane/contracts/external/morpho/blue/mocks/ERC20Mock.sol";
import {AdaptiveCurveIrm} from "@crane/contracts/external/morpho/blue-irm/AdaptiveCurveIrm.sol";
import {MarketParamsLib} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";
import {ORACLE_PRICE_SCALE} from "@crane/contracts/external/morpho/blue/libraries/ConstantsLib.sol";
import {MorphoBlueService} from "@crane/contracts/protocols/lending/morpho/blue/services/MorphoBlueService.sol";

// tag::TestBase_MorphoBlue[]
/**
 * @title TestBase_MorphoBlue
 * @notice Hermetic Morpho Blue setup: real Morpho + AdaptiveCurveIRM + OracleMock + mintable ERC20s.
 * @dev Production-first: deploys ported bytecode via `new` (protocol port path). Never mocks Morpho SUT.
 */
abstract contract TestBase_MorphoBlue is Test {
    using MarketParamsLib for MarketParams;
    using MorphoBlueService for IMorpho;

    uint256 internal constant DEFAULT_LLTV = 0.8e18;
    uint256 internal constant HIGH_COLLATERAL_AMOUNT = 1e24;

    address internal OWNER;
    address internal SUPPLIER;
    address internal BORROWER;
    address internal LIQUIDATOR;
    address internal FEE_RECIPIENT;

    IMorpho internal morpho;
    AdaptiveCurveIrm internal irm;
    OracleMock internal oracle;
    ERC20Mock internal loanToken;
    ERC20Mock internal collateralToken;

    MarketParams internal marketParams;
    Id internal marketId;

    function setUp() public virtual {
        OWNER = makeAddr("OWNER");
        SUPPLIER = makeAddr("SUPPLIER");
        BORROWER = makeAddr("BORROWER");
        LIQUIDATOR = makeAddr("LIQUIDATOR");
        FEE_RECIPIENT = makeAddr("FEE_RECIPIENT");

        morpho = IMorpho(address(new Morpho(OWNER)));
        vm.label(address(morpho), "Morpho");

        irm = new AdaptiveCurveIrm(address(morpho));
        vm.label(address(irm), "AdaptiveCurveIrm");

        oracle = new OracleMock();
        oracle.setPrice(ORACLE_PRICE_SCALE);
        vm.label(address(oracle), "OracleMock");

        loanToken = new ERC20Mock();
        collateralToken = new ERC20Mock();
        vm.label(address(loanToken), "LoanToken");
        vm.label(address(collateralToken), "CollateralToken");

        vm.startPrank(OWNER);
        morpho.enableIrm(address(irm));
        morpho.enableLltv(DEFAULT_LLTV);
        morpho.setFeeRecipient(FEE_RECIPIENT);
        vm.stopPrank();

        marketParams = MarketParams({
            loanToken: address(loanToken),
            collateralToken: address(collateralToken),
            oracle: address(oracle),
            irm: address(irm),
            lltv: DEFAULT_LLTV
        });
        marketId = marketParams.id();

        morpho.createMarket(marketParams);

        _approveAll(SUPPLIER);
        _approveAll(BORROWER);
        _approveAll(LIQUIDATOR);
        _approveAll(address(this));
    }

    function _approveAll(address who) internal {
        vm.startPrank(who);
        loanToken.approve(address(morpho), type(uint256).max);
        collateralToken.approve(address(morpho), type(uint256).max);
        vm.stopPrank();
    }

    function _mintLoan(address to, uint256 amount) internal {
        loanToken.setBalance(to, amount);
    }

    function _mintCollateral(address to, uint256 amount) internal {
        collateralToken.setBalance(to, amount);
    }

    function _fundSupplier(uint256 amount) internal {
        _mintLoan(SUPPLIER, amount);
    }

    function _fundBorrowerCollateral(uint256 amount) internal {
        _mintCollateral(BORROWER, amount);
    }
}
// end::TestBase_MorphoBlue[]
