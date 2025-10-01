// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FungibleState
/// @notice Represents the state of a fungible
/// @dev 64 bits index | 64 bits empty | 128 bits balance
type FungibleState is bytes32;

using FungibleStateLibrary for FungibleState global;

/// @title FungibleStateLibrary
/// @notice Library for managing fungible states
library FungibleStateLibrary {
    /// @notice Gets the index of a fungible from its state
    /// @param self The fungible state to get the index from
    /// @return _index The index of the fungible
    function index(FungibleState self) internal pure returns (uint256 _index) {
        assembly ("memory-safe") {
            _index := shr(192, self)
        }
    }

    /// @notice Gets the balance of a fungible from its state
    /// @param self The fungible state to get the balance from
    /// @return _balance The balance of the fungible
    function balance(FungibleState self) internal pure returns (uint256 _balance) {
        assembly ("memory-safe") {
            _balance := and(self, 0xffffffffffffffffffffffffffffffff)
        }
    }

    /// @notice Constructs a fungible state from index and a balance
    /// @param _index The index of the fungible, must fit within 64 bits
    /// @param _balance The balance of the fungible, must fit within 128 bits
    /// @return state The constructed fungible state
    function from(uint256 _index, uint256 _balance) internal pure returns (FungibleState state) {
        assembly ("memory-safe") {
            // require(_index <= 0xffffffffffffffff, MaxFungibleIndexExceeded());
            if gt(_index, 0xffffffffffffffff) {
                mstore(0x00, 0x336267e5) // 'MaxFungibleIndexExceeded()'
                revert(0x1c, 0x04)
            }

            // require(_balance <= 0xffffffffffffffffffffffffffffffff, MaxFungibleBalanceExceeded());
            if gt(_balance, 0xffffffffffffffffffffffffffffffff) {
                mstore(0x00, 0x452d7c3a) // 'MaxFungibleBalanceExceeded()'
                revert(0x1c, 0x04)
            }

            state := or(shl(192, _index), _balance)
        }
    }
}
