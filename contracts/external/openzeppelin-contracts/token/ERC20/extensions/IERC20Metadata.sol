// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts compatibility shim — re-exports Crane's IERC20Metadata
// (and IERC20, which OZ v4 importers expect to be transitively available).
pragma solidity ^0.8.35;

import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
