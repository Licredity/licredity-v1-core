// SPDX-License-Identifier: MIT
pragma solidity =0.8.30;

library Locker {
    // bytes32(uint256(keccak256("Unlocked")) - 1)
    bytes32 internal constant UNLOCKED_SLOT = 0xc090fc4683624cfc3884e9d8de5eca132f2d0ec062aff75d43c0465d5ceeab23;

    // bytes32(uint256(keccak256("RegisteredItems")) - 1)
    bytes32 internal constant REGISTERED_ITEMS_SLOT = 0x200b7f4f488b59c5fce2ca35008c3bf548ce04262fab17c5838c90724a17a1fa;

    /// @notice Unlocks the locker, clearing registered items.
    function unlock() internal {
        assembly ("memory-safe") {
            if iszero(iszero(tload(UNLOCKED_SLOT))) {
                mstore(0x00, 0x5090d6c6) // 'AlreadyUnlocked()'
                revert(0x1c, 0x04)
            }

            tstore(UNLOCKED_SLOT, true)
            tstore(REGISTERED_ITEMS_SLOT, 0)
        }
    }

    /// @notice Locks the locker
    function lock() internal {
        assembly ("memory-safe") {
            if iszero(tload(UNLOCKED_SLOT)) {
                mstore(0x00, 0x5f0ccd7c) // 'AlreadyLocked()'
                revert(0x1c, 0x04)
            }

            tstore(UNLOCKED_SLOT, false)
        }
    }

    /// @notice Registers an item in the locker
    function register(bytes32 item) internal {
        assembly ("memory-safe") {
            if iszero(tload(UNLOCKED_SLOT)) {
                mstore(0x00, 0xfa680065) // 'NotUnlocked()'
                revert(0x1c, 0x04)
            }

            let newCount := add(tload(REGISTERED_ITEMS_SLOT), 1)
            tstore(add(REGISTERED_ITEMS_SLOT, mul(0x20, newCount)), item)
            tstore(REGISTERED_ITEMS_SLOT, newCount)
        }
    }

    /// @notice Gets the registered items in the locker
    function getRegisteredItems() internal view returns (bytes32[] memory items) {
        assembly ("memory-safe") {
            let count := tload(REGISTERED_ITEMS_SLOT)
            items := mload(0x40)

            mstore(items, count)
            for { let i := 1 } iszero(gt(i, count)) { i := add(i, 1) } {
                mstore(add(items, mul(0x20, i)), tload(add(REGISTERED_ITEMS_SLOT, mul(0x20, i))))
            }
            mstore(0x40, add(items, mul(0x20, add(count, 1))))
        }
    }
}
