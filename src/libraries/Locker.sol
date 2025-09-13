// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

/// @title Locker
/// @notice Library for managing locker operations
library Locker {
    // bytes32(uint256(keccak256("Locker")) - 1)
    // 1 bit unlocked | 223 bits empty | 32 bits count
    bytes32 private constant LOCKER_SLOT = 0x0e87e1788ebd9ed6a7e63c70a374cd3283e41cad601d21fbe27863899ed4a708;

    /// @notice Unlocks the locker and clears registered items
    function unlock() internal {
        assembly ("memory-safe") {
            let locker := tload(LOCKER_SLOT)

            // requires locker to be locked
            if iszero(iszero(shr(255, locker))) {
                mstore(0x00, 0xe6a9f77d) // 'LockerAlreadyUnlocked()'
                revert(0x1c, 0x04)
            }

            // clear each registered item
            let count := and(locker, 0xffffffff)
            mstore(0x20, LOCKER_SLOT)
            for { let i := 1 } iszero(gt(i, count)) { i := add(i, 1) } {
                let itemSlot := add(LOCKER_SLOT, mul(0x20, i))

                // set item's registered slot to false and remove it from the registered items array
                mstore(0x00, tload(itemSlot))
                tstore(keccak256(0x00, 0x40), false)
                tstore(itemSlot, 0)
            }

            // clear count and unlock the locker
            tstore(LOCKER_SLOT, shl(255, 1))
        }
    }

    /// @notice Locks the locker
    function lock() internal {
        assembly ("memory-safe") {
            let locker := tload(LOCKER_SLOT)

            // requires locker to be unlocked
            if iszero(shr(255, locker)) {
                mstore(0x00, 0x75ad9ebe) // 'LockerAlreadyLocked()'
                revert(0x1c, 0x04)
            }

            // set the locker to locked
            tstore(LOCKER_SLOT, xor(locker, shl(255, 1)))
        }
    }

    /// @notice Registers an item in the locker
    /// @param item The item to register
    function register(bytes32 item) internal {
        assembly ("memory-safe") {
            let locker := tload(LOCKER_SLOT)

            // requires locker to be unlocked
            if iszero(shr(255, locker)) {
                mstore(0x00, 0x796facfe) // 'LockerNotUnlocked()'
                revert(0x1c, 0x04)
            }

            // calculate item's registered slot
            mstore(0x00, item)
            mstore(0x20, LOCKER_SLOT)
            let registeredSlot := keccak256(0x00, 0x40)

            // only register the item if it is not already registered
            if iszero(tload(registeredSlot)) {
                // set the registered slot to true
                tstore(registeredSlot, true)

                // add item to the registered items array and increment count
                let count := add(and(locker, 0xffffffff), 1)
                tstore(add(LOCKER_SLOT, mul(count, 0x20)), item)
                tstore(LOCKER_SLOT, or(shl(255, 1), count))
            }
        }
    }

    /// @notice Gets the registered items in the locker
    function registeredItems() internal view returns (bytes32[] memory items) {
        assembly ("memory-safe") {
            let count := and(tload(LOCKER_SLOT), 0xffffffff)
            items := mload(0x40)
            mstore(items, count)

            // copy array from transient storage to memory
            let i := 1
            for {} iszero(gt(i, count)) { i := add(i, 1) } {
                let offset := mul(i, 0x20)
                mstore(add(items, offset), tload(add(LOCKER_SLOT, offset)))
            }

            // update free memory pointer
            mstore(0x40, add(items, mul(i, 0x20)))
        }
    }

    /// @notice Checks whether an item is registered
    function isRegistered(bytes32 item) internal view returns (bool _isRegistered) {
        assembly ("memory-safe") {
            mstore(0x00, item)
            mstore(0x20, LOCKER_SLOT)
            _isRegistered := tload(keccak256(0x00, 0x40))
        }
    }
}
