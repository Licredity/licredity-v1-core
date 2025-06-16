// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {SafeCast} from "../libraries/SafeCast.sol";
import {Fungible} from "./Fungible.sol";
import {FungibleState, toFungibleState} from "./FungibleState.sol";
import {NonFungible} from "./NonFungible.sol";

/// @title Position
/// @notice Represents a margin position
struct Position {
    address owner;
    uint128 debtShare;
    Fungible[] fungibles;
    NonFungible[] nonFungibles;
    mapping(Fungible => FungibleState) fungibleStates;
}

using PositionLibrary for Position global;

/// @title PositionLibrary
/// @notice Library for managing positions
library PositionLibrary {
    using SafeCast for uint256;

    uint256 private constant OWNER_OFFSET = 0;
    uint256 private constant DEBT_SHARE_OFFSET = 1;
    uint256 private constant FUNGIBLES_OFFSET = 2;
    uint256 private constant NON_FUNGIBLES_OFFSET = 3;
    uint256 private constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;

    /// @notice Sets the owner of a position
    /// @param self The position to set owner for
    /// @param owner The new owner of the position
    function setOwner(Position storage self, address owner) internal {
        assembly ("memory-safe") {
            sstore(add(self.slot, OWNER_OFFSET), and(owner, ADDRESS_MASK))
        }
    }

    /// @notice Adds amount of fungible to a position
    /// @param self The position to add fungible to
    /// @param fungible The fungible to add
    /// @param amount The amount of fungible to add
    function addFungible(Position storage self, Fungible fungible, uint256 amount) internal {
        FungibleState state = self.fungibleStates[fungible];

        if (state.index() == 0) {
            self.fungibles.push(fungible);
            self.fungibleStates[fungible] = toFungibleState(self.fungibles.length.toUint64(), amount.toUint128());
        } else {
            self.fungibleStates[fungible] = toFungibleState(state.index(), (state.balance() + amount).toUint128());
        }
    }

    /// @notice Removes amount of fungible from a position
    /// @param self The position to remove fungible from
    /// @param fungible The fungible to remove
    /// @param amount The amount of fungible to remove
    function removeFungible(Position storage self, Fungible fungible, uint256 amount) internal {
        FungibleState state = self.fungibleStates[fungible];
        uint64 index = state.index();
        uint128 newBalance = (state.balance() - amount).toUint128();

        if (newBalance != 0) {
            self.fungibleStates[fungible] = toFungibleState(index, newBalance);
        } else {
            uint256 lastIndex = self.fungibles.length;

            if (index != lastIndex) {
                Fungible lastFungible = self.fungibles[lastIndex - 1];

                self.fungibles[index - 1] = lastFungible;
                self.fungibleStates[lastFungible] = toFungibleState(index, self.fungibleStates[lastFungible].balance());
            }

            self.fungibles.pop();
            self.fungibleStates[fungible] = FungibleState.wrap(0);
        }
    }

    /// @notice Adds a non-fungible to a position
    /// @param self The position to add non-fungible to
    /// @param nonFungible The non-fungible to add
    function addNonFungible(Position storage self, NonFungible nonFungible) internal {
        assembly ("memory-safe") {
            let slot := add(self.slot, NON_FUNGIBLES_OFFSET)
            let len := sload(slot)
            mstore(0x00, slot)
            let dataSlot := keccak256(0x00, 0x20)

            sstore(add(dataSlot, len), nonFungible)
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
                let element := sload(elementSlot)

                if eq(element, nonFungible) {
                    let lenMinusOne := sub(len, 1)
                    let lastElementSlot := add(dataSlot, lenMinusOne)

                    if iszero(eq(i, lenMinusOne)) { sstore(elementSlot, sload(lastElementSlot)) }

                    sstore(lastElementSlot, 0)
                    sstore(slot, lenMinusOne)

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
        self.debtShare += delta.toUint128();
    }

    /// @notice Decreases the debt share in a position
    /// @param self The position to decrease debt share in
    /// @param delta The number of debt shares to decrease by
    function decreaseDebtShare(Position storage self, uint256 delta) internal {
        self.debtShare -= delta.toUint128();
    }

    /// @notice Checks whether a position is empty
    /// @param self The position to check
    /// @return bool True if the position is empty, false otherwise
    function isEmpty(Position storage self) internal view returns (bool) {
        assembly ("memory-safe") {
            let debtShare := sload(add(self.slot, DEBT_SHARE_OFFSET))
            let fungiblesCount := sload(add(self.slot, FUNGIBLES_OFFSET))
            let nonFungiblesCount := sload(add(self.slot, NON_FUNGIBLES_OFFSET))

            if iszero(add(debtShare, add(fungiblesCount, nonFungiblesCount))) {
                mstore(0x00, true)
                return(0x00, 0x20)
            }
        }
    }
}
