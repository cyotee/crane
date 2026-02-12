// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";

interface IERC4626PermitProxy is IERC20PermitProxy, IERC4626 {}
