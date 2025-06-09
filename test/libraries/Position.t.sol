// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {Position} from "src/types/Position.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {PositionDB} from "test/utils/PositionFuzzDB.sol";

contract PositionTest is Test {
    Position public position;

    function test_setOwner(address owner) public {
        position.setOwner(owner);
        assertEq(position.owner, owner);
    }

    function test_addFungible_init(Fungible fungible, uint192 amount) public {
        position.addFungible(fungible, amount);

        assertEq(position.fungibles.length, 1);
        assertEq(Fungible.unwrap(position.fungibles[0]), Fungible.unwrap(fungible));
        assertEq(position.fungibleStates[fungible].index(), 1);
        assertEq(position.fungibleStates[fungible].balance(), amount);
    }

    function initFungibles(Fungible[] calldata fungibles, uint160[] calldata amounts, PositionDB db)
        public
        returns (uint256 fungibleLength)
    {
        for (uint256 i = 0; i < fungibles.length; i++) {
            Fungible fungible = fungibles[i];
            uint160 addAmount = amounts[i];

            position.addFungible(fungible, addAmount);
            db.addFungibleBalance(fungible, addAmount);

            if (!db.isUsedFungible(fungible)) {
                fungibleLength += 1;

                db.addUsedFungible(fungible);

                assertEq(position.fungibles.length, fungibleLength);
                assertEq(position.fungibleStates[fungible].balance(), addAmount);
            }
        }
    }

    function test_addFungible(Fungible[] calldata fungibles, uint160[] calldata amounts, uint16 index, uint32 amount)
        public
    {
        vm.assume(fungibles.length <= amounts.length);
        vm.assume(fungibles.length > 0);

        uint256 boundIndex = bound(index, 0, fungibles.length - 1);

        PositionDB db = new PositionDB();

        uint256 fungibleLength = initFungibles(fungibles, amounts, db);

        Fungible selectedFungible = fungibles[boundIndex];
        position.addFungible(selectedFungible, amount);

        assertEq(position.fungibles.length, fungibleLength);
        assertEq(position.fungibleStates[selectedFungible].balance(), db.fungibleBalance(selectedFungible) + amount);
    }

    function test_removeNullFungible() public {
        position.removeFungible(Fungible.wrap(address(0)), 0);

        assertEq(position.fungibles.length, 0);
    }

    function test_removeFungible(
        Fungible[] calldata fungibles,
        uint160[] calldata amounts,
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

    function test_addNonFungible(NonFungible[] memory nonFungibles) public {
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
            NonFungible nonFungible = nonFungibles[i];
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
        position.addDebtShare(addShare);
        position.removeDebtShare(removeShare);
        assertEq(position.debtShare, addShare - removeShare);
    }
}
