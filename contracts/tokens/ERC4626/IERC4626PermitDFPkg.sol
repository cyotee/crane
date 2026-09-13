// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";

interface IERC4626PermitDFPkg {
    struct PkgInit {
        IFacet erc20Facet;
        IFacet erc5267Facet;
        IFacet erc2612Facet;
        IFacet erc4626Facet;
    }

    struct PkgArgs {
        IERC20Metadata reserveAsset;
        uint8 optionalDecimalOffset;
        bytes32 optionalSalt;
        uint256 optionalInitialDeposit;
        address depositor;
        address recipient;
    }

    error NoReserveAsset();
    error NoDepositor();
    error NoRecipient();
}
