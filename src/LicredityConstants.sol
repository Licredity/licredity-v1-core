// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PipsMath} from "./libraries/PipsMath.sol";
import {Fungible} from "./types/Fungible.sol";

/// @title LicredityConstants
/// @notice Library for Licredity constants
library LicredityConstants {
    Fungible internal constant CHAIN_NATIVE_FUNGIBLE = Fungible.wrap(address(0));
    uint8 internal constant CHAIN_NATIVE_FUNGIBLE_DECIMALS = 18;

    uint24 internal constant POOL_FEE = 100;
    int24 internal constant POOL_TICK_SPACING = 1;

    uint256 internal constant POSITION_MAX_FUNGIBLES = 128; // maximum number of fungibles per position
    uint256 internal constant POSITION_MAX_NON_FUNGIBLES = 128; // maximum number of non-fungibles per position
    uint256 internal constant POSITION_MIN_MRR_PIPS = 10_000; // 1% margin requirement

    uint256 internal constant MAX_INTEREST_RATE = 3.65e27; // maximum interest rate (365% per year)
    uint256 internal constant MAX_MIN_LIQUIDITY_LIFESPAN = 7 days;
    uint256 internal constant MAX_PROTOCOL_FEE_PIPS = PipsMath.ONE_PIPS / 2 ** 4; // 6.25%
}
