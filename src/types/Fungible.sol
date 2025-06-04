// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "@forge-std/interfaces/IERC20.sol";

type Fungible is address;

using {equals as ==} for Fungible global;
using FungibleLibrary for Fungible global;

function equals(Fungible x, Fungible y) pure returns (bool) {
    return Fungible.unwrap(x) == Fungible.unwrap(y);
}

/// @title FungibleLibrary
/// @notice Library for managing fungibles
library FungibleLibrary {
    /// @notice A constant representing the native fungible
    Fungible public constant NATIVE = Fungible.wrap(address(0));

    /// @notice Transfer fungible to recipient
    /// @param self The fungible to transfer
    /// @param amount The amount of fungible to transfer
    /// @param recipient The address to transfer the fungible to
    function transfer(Fungible self, uint256 amount, address recipient) internal {
        // TODO: implement
    }

    /// @notice Get the balance of a fungible for an address
    /// @param self The fungible to check the balance of
    /// @param owner The address to check the balance for
    /// @return uint256 The balance of the fungible for the address
    function balanceOf(Fungible self, address owner) internal view returns (uint256) {
        return self.isNative() ? owner.balance : IERC20(Fungible.unwrap(self)).balanceOf(owner);
    }

    /// @notice Checks if the fungible is the native fungible
    /// @param self The fungible to check
    /// @return bool True if the fungible is the native fungible, false otherwise
    function isNative(Fungible self) internal pure returns (bool) {
        return self == NATIVE;
    }
}
