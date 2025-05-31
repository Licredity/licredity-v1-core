// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @dev A 'uint64' index and a 'uint192' balance, packed into a single 'bytes32' value
type FungibleState is bytes32;

using FungibleStateLibrary for FungibleState global;

function toFungibleState(uint64 index, uint192 _balance) pure returns (FungibleState state) {
    assembly ("memory-safe") {
        state := or(shl(192, index), and(_balance, sub(shl(192, 1), 1)))
    }
}

/// @title FungibleStateLibrary
/// @notice Library for managing fungible states
library FungibleStateLibrary {
    /// @notice Get the index part of the fungible state
    /// @param self The fungible state to get the index part of
    /// @return _index The index part of the fungible state
    function index(FungibleState self) internal pure returns (uint64 _index) {
        assembly ("memory-safe") {
            _index := shr(192, self)
        }
    }

    /// @notice Get the balance part of the fungible state
    /// @param self The fungible state to get the balance part of
    /// @return _balance The balance part of the fungible state
    function balance(FungibleState self) internal pure returns (uint192 _balance) {
        assembly ("memory-safe") {
            _balance := and(self, sub(shl(192, 1), 1))
        }
    }
}
