// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

// TODO Write NatSpec comments.
// TODO Complete unit testing for all functions.
// TODO Implement and test external versions of all functions.
struct Fraction {
    uint256 n;
    uint256 d;
}

struct Fraction112 {
    uint112 n;
    uint112 d;
}

error InvalidFraction();