// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@forge-std/interfaces/IERC20.sol";
import {ChainInfo} from "../libraries/ChainInfo.sol";

/// @title Fungible
/// @notice Represents a fungible token
type Fungible is address;

using FungibleLibrary for Fungible global;

/// @title FungibleLibrary
/// @notice Library for managing fungible tokens
library FungibleLibrary {
    /// @notice Gets the decimals of the fungible token
    /// @param self The fungible token to get the decimals of
    /// @return uint8 The number of decimals of the fungible token
    function decimals(Fungible self) internal view returns (uint8) {
        return self.isNative() ? ChainInfo.NATIVE_DECIMALS : IERC20(Fungible.unwrap(self)).decimals();
    }

    /// @notice Checks if the fungible token is native to the chain
    /// @param self The fungible token to check
    /// @return bool True if the fungible token is native, false otherwise
    function isNative(Fungible self) internal pure returns (bool) {
        return Fungible.unwrap(self) == ChainInfo.NATIVE;
    }
}
