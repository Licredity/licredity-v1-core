// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Fungible} from "../types/Fungible.sol";

/// @title ChainInfo
/// @notice Library for chain-specific parameters
library ChainInfo {
    Fungible internal constant NATIVE_FUNGIBLE = Fungible.wrap(address(0));
    uint8 internal constant NATIVE_FUNGIBLE_DECIMALS = 18;
}
