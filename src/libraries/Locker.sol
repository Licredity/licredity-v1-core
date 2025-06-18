// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

/// @title Locker
/// @notice Library for managing locker operations

library Locker {
    // bytes32(uint256(keccak256("Unlocked")) - 1)
    bytes32 private constant UNLOCKED_SLOT = 0xc090fc4683624cfc3884e9d8de5eca132f2d0ec062aff75d43c0465d5ceeab23;

    // bytes32(uint256(keccak256("RegisteredItems")) - 1)
    bytes32 private constant REGISTERED_ITEMS_SLOT = 0x200b7f4f488b59c5fce2ca35008c3bf548ce04262fab17c5838c90724a17a1fa;

    /// @notice Unlocks the locker and clears registered items
    function unlock() internal {
        assembly ("memory-safe") {
            // revert if already unlocked
            if iszero(iszero(tload(UNLOCKED_SLOT))) {
                mstore(0x00, 0x5090d6c6) // 'AlreadyUnlocked()'
                revert(0x1c, 0x04)
            }

            // clear each registered item
            let length := tload(REGISTERED_ITEMS_SLOT)
            for { let i := 1 } iszero(gt(i, length)) { i := add(i, 1) } {
                // calculate the transient mapping and array slots
                let arraySlot := add(REGISTERED_ITEMS_SLOT, mul(0x20, i))
                mstore(0x00, tload(arraySlot))
                mstore(0x20, REGISTERED_ITEMS_SLOT)

                // clear the transient mapping and array slots
                tstore(keccak256(0x00, 0x40), false)
                tstore(arraySlot, 0)
            }
            // clear the transient array
            tstore(REGISTERED_ITEMS_SLOT, 0)

            // set the locker to unlocked
            tstore(UNLOCKED_SLOT, true)
        }
    }

    /// @notice Locks the locker
    function lock() internal {
        assembly ("memory-safe") {
            // revert if already locked
            if iszero(tload(UNLOCKED_SLOT)) {
                mstore(0x00, 0x5f0ccd7c) // 'AlreadyLocked()'
                revert(0x1c, 0x04)
            }

            // set the locker to locked
            tstore(UNLOCKED_SLOT, false)
        }
    }

    /// @notice Registers an item in the locker
    function register(bytes32 item) internal {
        assembly ("memory-safe") {
            // revert if not unlocked
            if iszero(tload(UNLOCKED_SLOT)) {
                mstore(0x00, 0xfa680065) // 'NotUnlocked()'
                revert(0x1c, 0x04)
            }

            // calulate the transient mapping slot
            mstore(0x00, item)
            mstore(0x20, REGISTERED_ITEMS_SLOT)
            let mappingSlot := keccak256(0x00, 0x40)

            // only register the item if it is not already registered
            if iszero(tload(mappingSlot)) {
                // set transient mapping slot
                tstore(mappingSlot, true)

                // set transient array slot and grow the array
                let newLength := add(tload(REGISTERED_ITEMS_SLOT), 1)
                tstore(add(REGISTERED_ITEMS_SLOT, mul(0x20, newLength)), item)
                tstore(REGISTERED_ITEMS_SLOT, newLength)
            }
        }
    }

    /// @notice Gets the registered items in the locker
    function registeredItems() internal view returns (bytes32[] memory items) {
        assembly ("memory-safe") {
            let length := tload(REGISTERED_ITEMS_SLOT)
            items := mload(0x40)

            // copy arry from transient storage to memory
            mstore(items, length)
            let i := 1
            for {} iszero(gt(i, length)) { i := add(i, 1) } {
                let offset := mul(0x20, i)
                mstore(add(items, offset), tload(add(REGISTERED_ITEMS_SLOT, offset)))
            }

            // update free memory pointer (i = length + 1)
            mstore(0x40, add(items, mul(0x20, i)))
        }
    }
}
