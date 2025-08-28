// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {Fungible} from "./Fungible.sol";
import {FungibleState, toFungibleState} from "./FungibleState.sol";
import {NonFungible} from "./NonFungible.sol";

/// @title Position
/// @notice Represents a margin position
struct Position {
    address owner;
    uint256 debtShare;
    Fungible[] fungibles;
    NonFungible[] nonFungibles;
    mapping(Fungible => FungibleState) fungibleStates;
}

using PositionLibrary for Position global;

/// @title PositionLibrary
/// @notice Library for managing positions
library PositionLibrary {
    uint256 private constant OWNER_OFFSET = 0;
    uint256 private constant DEBT_SHARE_OFFSET = 1;
    uint256 private constant FUNGIBLES_OFFSET = 2;
    uint256 private constant NON_FUNGIBLES_OFFSET = 3;
    uint256 private constant FUNGIBLE_STATES_OFFSET = 4;

    /// @notice Sets the owner of a position
    /// @param self The position to set owner for
    /// @param owner The new owner of the position
    function setOwner(Position storage self, address owner) internal {
        assembly ("memory-safe") {
            // self.owner = owner;
            sstore(add(self.slot, OWNER_OFFSET), and(owner, 0xffffffffffffffffffffffffffffffffffffffff))
        }
    }

    /// @notice Adds amount of fungible to a position
    /// @param self The position to add fungible to
    /// @param fungible The fungible to add
    /// @param amount The amount of fungible to add
    function addFungible(Position storage self, Fungible fungible, uint256 amount) internal {
        FungibleState state = self.fungibleStates[fungible];

        if (state.index() == 0 && amount > 0) {
            // add a fungible to the fungibles array
            assembly ("memory-safe") {
                let slot := add(self.slot, FUNGIBLES_OFFSET)
                let len := sload(slot)

                mstore(0x00, slot)
                sstore(add(keccak256(0x00, 0x20), len), fungible)
                sstore(slot, add(len, 1))
            }

            state = toFungibleState(self.fungibles.length, amount);
        } else {
            state = toFungibleState(state.index(), state.balance() + amount);
        }

        // update fungible state
        assembly ("memory-safe") {
            mstore(0x00, fungible)
            mstore(0x20, add(self.slot, FUNGIBLE_STATES_OFFSET))
            sstore(keccak256(0x00, 0x40), state)
        }
    }

    /// @notice Removes amount of fungible from a position
    /// @param self The position to remove fungible from
    /// @param fungible The fungible to remove
    /// @param amount The amount of fungible to remove
    /// @return isRemoved True if the non-fungible was removed, false otherwise
    function removeFungible(Position storage self, Fungible fungible, uint256 amount)
        internal
        returns (bool isRemoved)
    {
        FungibleState state = self.fungibleStates[fungible];
        uint256 index = state.index();
        uint256 newBalance = state.balance() - amount;

        if (index != 0) {
            if (newBalance != 0) {
                state = toFungibleState(index, newBalance);
            } else {
                state = FungibleState.wrap(0);

                // remove a fungible from the fungibles array
                assembly ("memory-safe") {
                    let slot := add(self.slot, FUNGIBLES_OFFSET)
                    let len := sload(slot)
                    mstore(0x00, slot)
                    let dataSlot := keccak256(0x00, 0x20)

                    if iszero(eq(index, len)) {
                        sstore(add(dataSlot, sub(index, 1)), sload(add(dataSlot, sub(len, 1))))
                    }

                    sstore(add(dataSlot, sub(len, 1)), 0)
                    sstore(slot, sub(len, 1))
                }
            }

            // update fungible state
            assembly ("memory-safe") {
                mstore(0x00, fungible)
                mstore(0x20, add(self.slot, FUNGIBLE_STATES_OFFSET))
                sstore(keccak256(0x00, 0x40), state)
            }

            isRemoved = true;
        }
    }

    /// @notice Adds a non-fungible to a position
    /// @param self The position to add non-fungible to
    /// @param nonFungible The non-fungible to add
    function addNonFungible(Position storage self, NonFungible nonFungible) internal {
        // add a non-fungible to the non-fungibles array
        assembly ("memory-safe") {
            let slot := add(self.slot, NON_FUNGIBLES_OFFSET)
            let len := sload(slot)

            mstore(0x00, slot)
            sstore(add(keccak256(0x00, 0x20), len), nonFungible)
            sstore(slot, add(len, 1))
        }
    }

    /// @notice Removes a non-fungible from a position
    /// @param self The position to remove non-fungible from
    /// @param nonFungible The non-fungible to remove
    /// @return isRemoved True if the non-fungible was removed, false otherwise
    function removeNonFungible(Position storage self, NonFungible nonFungible) internal returns (bool isRemoved) {
        assembly ("memory-safe") {
            let slot := add(self.slot, NON_FUNGIBLES_OFFSET)
            let len := sload(slot)
            mstore(0x00, slot)
            let dataSlot := keccak256(0x00, 0x20)

            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                let elementSlot := add(dataSlot, i)

                if eq(sload(elementSlot), nonFungible) {
                    let lastElementSlot := add(dataSlot, sub(len, 1))

                    if iszero(eq(elementSlot, lastElementSlot)) { sstore(elementSlot, sload(lastElementSlot)) }

                    sstore(lastElementSlot, 0)
                    sstore(slot, sub(len, 1))

                    isRemoved := 1
                    break
                }
            }
        }
    }

    /// @notice Increases the debt share in a position
    /// @param self The position to increase debt share in
    /// @param delta The number of debt shares to increase by
    function increaseDebtShare(Position storage self, uint256 delta) internal {
        self.debtShare += delta;
    }

    /// @notice Decreases the debt share in a position
    /// @param self The position to decrease debt share in
    /// @param delta The number of debt shares to decrease by
    function decreaseDebtShare(Position storage self, uint256 delta) internal {
        self.debtShare -= delta;
    }

    /// @notice Checks whether a position is empty
    /// @param self The position to check
    /// @return _isEmpty True if the position is empty, false otherwise
    function isEmpty(Position storage self) internal view returns (bool _isEmpty) {
        assembly ("memory-safe") {
            // _isEmpty = self.debtShare == 0 && self.fungibles.length == 0 && self.nonFungibles.length == 0;
            _isEmpty :=
                iszero(
                    add(
                        sload(add(self.slot, DEBT_SHARE_OFFSET)),
                        add(sload(add(self.slot, FUNGIBLES_OFFSET)), sload(add(self.slot, NON_FUNGIBLES_OFFSET)))
                    )
                )
        }
    }
}
