// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {Locker} from "src/libraries/Locker.sol";

contract LockerTest is Test {
    error AlreadyLocked();
    error AlreadyUnlocked();
    error NotUnlocked();

    bytes32 private constant UNLOCKED_SLOT = 0xc090fc4683624cfc3884e9d8de5eca132f2d0ec062aff75d43c0465d5ceeab23;
    bytes32 private constant REGISTERED_ITEMS_SLOT = 0x200b7f4f488b59c5fce2ca35008c3bf548ce04262fab17c5838c90724a17a1fa;

    mapping(bytes32 => bool) private isRegisteredItems;
    bytes32[] private registeredItems;

    function test_unlock() public {
        bool unlocked;
        uint256 count;

        Locker.unlock();
        assembly {
            unlocked := tload(UNLOCKED_SLOT)
            count := tload(REGISTERED_ITEMS_SLOT)
        }
        assertTrue(unlocked);
        assertEq(count, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_duplicate_unlock() public {
        Locker.unlock();
        vm.expectRevert(AlreadyUnlocked.selector);
        Locker.unlock();
    }

    function test_lock() public {
        Locker.unlock();
        Locker.lock();
        bool unlocked;
        assembly {
            unlocked := tload(UNLOCKED_SLOT)
        }
        assertFalse(unlocked);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_lock_AlreadyLocked() public {
        vm.expectRevert(AlreadyLocked.selector);
        Locker.lock();
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_register_NotUnlocked() public {
        vm.expectRevert(NotUnlocked.selector);
        Locker.register(bytes32(0));
    }

    function test_register(bytes32[] memory items) public {
        Locker.unlock();
        for (uint256 i = 0; i < items.length; i++) {
            if (!isRegisteredItems[items[i]]) {
                Locker.register(items[i]);
                isRegisteredItems[items[i]] = true;
                registeredItems.push(items[i]);
            }
        }

        bytes32[] memory _registeredItems = Locker.registeredItems();

        assertEq(_registeredItems.length, registeredItems.length);
        for (uint256 i = 0; i < _registeredItems.length; i++) {
            assertEq(_registeredItems[i], registeredItems[i]);
        }

        Locker.lock();
        Locker.unlock();
        bytes32[] memory zeroRegisteredItems = Locker.registeredItems();
        assertEq(zeroRegisteredItems.length, 0);
    }
}
