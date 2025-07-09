// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {Locker} from "src/libraries/Locker.sol";

contract LockerTest is Test {
    error AlreadyLocked();
    error AlreadyUnlocked();
    error NotUnlocked();

    bytes32 private constant LOCKER_SLOT = 0x0e87e1788ebd9ed6a7e63c70a374cd3283e41cad601d21fbe27863899ed4a708;

    mapping(bytes32 => bool) private isRegisteredItems;
    bytes32[] private registeredItems;

    function test_unlock() public {
        bool unlocked;
        uint256 count;

        Locker.unlock();
        assembly {
            unlocked := and(tload(LOCKER_SLOT), 0x01)
            count := shr(224, tload(LOCKER_SLOT))
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
            unlocked := and(tload(LOCKER_SLOT), 0x01)
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
