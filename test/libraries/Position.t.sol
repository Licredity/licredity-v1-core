// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {Position} from "src/types/Position.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {PositionDB} from "test/utils/PositionFuzzDB.sol";

contract PositionTest is Test {
    Position public position;

    error FungibleLimitReached();
    error NonFungibleLimitReached();

    function test_setOwner(address[] calldata owners) public {
        vm.assume(owners.length > 0);
        for (uint256 i = 0; i < owners.length; i++) {
            position.setOwner(owners[i]);
        }
        assertEq(position.owner, owners[owners.length - 1]);
    }

    function test_addFungible_init(Fungible fungible, uint128 amount) public {
        vm.assume(amount > 0);
        position.addFungible(fungible, amount);

        assertEq(position.fungibles.length, 1);
        assertEq(Fungible.unwrap(position.fungibles[0]), Fungible.unwrap(fungible));
        assertEq(position.fungibleStates[fungible].index(), 1);
        assertEq(position.fungibleStates[fungible].balance(), amount);
    }

    function test_addFungible_dup(Fungible fungible) public {
        position.addFungible(fungible, 1 ether);
        position.addFungible(fungible, 1.5 ether);

        assertEq(position.fungibles.length, 1);
        assertEq(position.fungibleStates[fungible].index(), 1);
        assertEq(position.fungibleStates[fungible].balance(), 2.5 ether);
    }

    function initFungibles(Fungible[] calldata fungibles, uint128[] calldata amounts, PositionDB db)
        public
        returns (uint256 fungibleLength)
    {
        for (uint256 i = 0; i < fungibles.length; i++) {
            Fungible fungible = fungibles[i];
            uint160 addAmount = amounts[i];

            uint256 beforeAmount = position.fungibleStates[fungible].balance();

            if (beforeAmount + addAmount <= type(uint128).max) {
                position.addFungible(fungible, addAmount);
                db.addFungibleBalance(fungible, addAmount);

                if (!db.isUsedFungible(fungible) && addAmount > 0) {
                    fungibleLength += 1;

                    db.addUsedFungible(fungible);

                    assertEq(position.fungibles.length, fungibleLength);
                    assertEq(position.fungibleStates[fungible].balance(), addAmount);
                }
            }
        }
    }

    function test_addFungible(Fungible[] calldata fungibles, uint128[] calldata amounts, uint16 index, uint32 amount)
        public
    {
        vm.assume(fungibles.length <= amounts.length);
        vm.assume(fungibles.length > 0);
        vm.assume(amounts[0] > 0);

        assertTrue(position.isEmpty());
        uint256 boundIndex = bound(index, 0, fungibles.length - 1);

        PositionDB db = new PositionDB();

        uint256 fungibleLength = initFungibles(fungibles, amounts, db);

        Fungible selectedFungible = fungibles[boundIndex];

        uint256 beforeSelectedFungibleBalance = position.fungibleStates[selectedFungible].balance();
        if (beforeSelectedFungibleBalance + uint256(amount) <= type(uint128).max) {
            position.addFungible(selectedFungible, amount);

            assertEq(
                position.fungibles.length, fungibleLength + (beforeSelectedFungibleBalance == 0 && amount > 0 ? 1 : 0)
            );
            assertEq(position.fungibleStates[selectedFungible].balance(), db.fungibleBalance(selectedFungible) + amount);
        }

        assertFalse(position.isEmpty());
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_addFungible_overLimit(Fungible[] calldata fungibles, uint128[] calldata amounts) public {
        vm.assume(fungibles.length <= amounts.length);
        vm.assume(fungibles.length > 0);

        PositionDB db = new PositionDB();
        uint256 fungibleLength = 0;

        for (uint256 i = 0; i < fungibles.length; i++) {
            Fungible fungible = fungibles[i];
            uint160 addAmount = amounts[i];

            uint256 beforeAmount = position.fungibleStates[fungible].balance();

            if (beforeAmount + addAmount <= type(uint128).max) {
                position.addFungible(fungible, addAmount);
                db.addFungibleBalance(fungible, addAmount);

                if (!db.isUsedFungible(fungible) && addAmount > 0) {
                    fungibleLength = fungibleLength + 1;
                    db.addUsedFungible(fungible);

                    assertEq(position.fungibles.length, fungibleLength);
                    assertEq(position.fungibleStates[fungible].balance(), addAmount);
                }
            }
        }
    }

    function test_removeNullFungible() public {
        bool isRemoved = position.removeFungible(Fungible.wrap(address(0)), 0);

        assertFalse(isRemoved);
    }

    function test_removeFungible_notExist(Fungible fungible, Fungible removeFungible) public {
        vm.assume(Fungible.unwrap(fungible) != Fungible.unwrap(removeFungible));
        position.addFungible(fungible, 1 ether);
        bool isRemoved = position.removeFungible(removeFungible, 0);

        assertFalse(isRemoved);
    }

    function test_removeFungible(
        Fungible[] calldata fungibles,
        uint128[] calldata amounts,
        uint16 index,
        uint256 removeAmount
    ) public {
        vm.assume(fungibles.length <= amounts.length);
        vm.assume(fungibles.length > 0);

        uint256 boundIndex = bound(index, 0, fungibles.length - 1);

        PositionDB db = new PositionDB();
        uint256 fungibleLength = initFungibles(fungibles, amounts, db);

        Fungible selectedFungible = fungibles[boundIndex];
        uint256 fungibleBalance = db.fungibleBalance(selectedFungible);

        removeAmount = bound(removeAmount, 0, fungibleBalance);
        position.removeFungible(selectedFungible, removeAmount);

        assertEq(position.fungibleStates[selectedFungible].balance(), fungibleBalance - removeAmount);

        if (removeAmount != fungibleBalance) {
            assertEq(position.fungibles.length, fungibleLength);
            position.removeFungible(selectedFungible, fungibleBalance - removeAmount);
            assertEq(position.fungibles.length, fungibleLength - 1);
        }
    }

    function test_isEmpty_debtShare() public {
        position.debtShare = 1;
        assertFalse(position.isEmpty());

        position.debtShare = 0;
        assertTrue(position.isEmpty());
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_addNonFungible(NonFungible[] memory nonFungibles) public {
        vm.assume(nonFungibles.length > 0);

        for (uint256 i = 0; i < nonFungibles.length; i++) {
            position.addNonFungible(nonFungibles[i]);
        }

        assertEq(position.nonFungibles.length, nonFungibles.length);

        for (uint256 i = 0; i < nonFungibles.length; i++) {
            assertEq(NonFungible.unwrap(position.nonFungibles[i]), NonFungible.unwrap(nonFungibles[i]));
        }
    }

    function test_removeNullNonFungible() public {
        bool isRemoved = position.removeNonFungible(NonFungible.wrap(0));
        assertFalse(isRemoved);
        assertEq(position.nonFungibles.length, 0);
    }

    function test_removeNonFungible(NonFungible[] memory nonFungibles, uint16 index) public {
        vm.assume(nonFungibles.length > 0);
        PositionDB db = new PositionDB();
        uint256 nonFungibleLength;

        for (uint256 i = 0; i < nonFungibles.length; i++) {
            NonFungible nonFungible = NonFungible.wrap(
                NonFungible.unwrap(nonFungibles[i]) & 0xffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffffff
            );
            if (!db.isUsedNonFungible(nonFungible)) {
                position.addNonFungible(nonFungible);
                db.addUsedNonFungible(nonFungible);
                nonFungibleLength += 1;
            }
        }

        assertEq(position.nonFungibles.length, nonFungibleLength);
        // assertGe(position.nonFungibles.length, deleteIndex);
        uint256 deleteIndex = bound(index, 0, nonFungibleLength - 1);
        NonFungible selectNonFungible = position.nonFungibles[deleteIndex];

        bool isRemoved = position.removeNonFungible(selectNonFungible);
        assertTrue(isRemoved);
        assertEq(position.nonFungibles.length, nonFungibleLength - 1);

        if (deleteIndex != nonFungibleLength - 1) {
            assertEq(
                NonFungible.unwrap(position.nonFungibles[deleteIndex]),
                NonFungible.unwrap(db.usedNonFungibles(nonFungibleLength - 1))
            );
        }

        for (uint256 i = 0; i < nonFungibleLength - 1; i++) {
            if (i != deleteIndex) {
                assertEq(NonFungible.unwrap(position.nonFungibles[i]), NonFungible.unwrap(db.usedNonFungibles(i)));
            }
        }
    }

    function test_addRemoveDebtShare(uint256 addShare, uint256 removeShare) public {
        vm.assume(addShare >= removeShare);
        position.increaseDebtShare(addShare);
        position.decreaseDebtShare(removeShare);
        assertEq(position.debtShare, addShare - removeShare);
    }
}
