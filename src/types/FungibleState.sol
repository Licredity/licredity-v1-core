// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FungibleState
/// @notice Represents the state of a fungible
/// @dev 64 bits index | 64 bits empty | 128 bits balance
type FungibleState is bytes32;

using FungibleStateLibrary for FungibleState global;

/// @notice Converts the index and balance of a fungible into a fungible state
/// @param index The index of the fungible
/// @param _balance The balance of the fungible
/// @return state The fungible state representing the index and balance
function toFungibleState(uint64 index, uint128 _balance) pure returns (FungibleState state) {
    assembly ("memory-safe") {
        state := or(shl(192, and(index, 0xffffffffffffffff)), and(_balance, 0xffffffffffffffffffffffffffffffff))
    }
}

/// @title FungibleStateLibrary
/// @notice Library for managing fungible states
library FungibleStateLibrary {
    /// @notice Gets the index of a fungible from its state
    /// @param self The fungible state to get the index from
    /// @return _index The index of the fungible
    function index(FungibleState self) internal pure returns (uint64 _index) {
        assembly ("memory-safe") {
            _index := shr(192, self)
        }
    }

    /// @notice Gets the balance of a fungible from its state
    /// @param self The fungible state to get the balance from
    /// @return _balance The balance of the fungible
    function balance(FungibleState self) internal pure returns (uint128 _balance) {
        assembly ("memory-safe") {
            _balance := and(self, 0xffffffffffffffffffffffffffffffff)
        }
    }
}
