// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {SafeCast} from "../libraries/SafeCast.sol";
import {Fungible} from "./Fungible.sol";
import {FungibleState, FungibleStateLibrary, toFungibleState} from "./FungibleState.sol";
import {NonFungible} from "./NonFungible.sol";

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
    using SafeCast for uint256;

    /// @notice Sets the owner of a position
    /// @param self The position to set the owner for
    /// @param owner The new owner of the position
    function setOwner(Position storage self, address owner) internal {
        self.owner = owner;
    }

    /// @notice Add fungible to a position
    /// @param self The position to add fungible to
    /// @param fungible The fungible to add
    /// @param amount The amount of fungible to add
    function addFungible(Position storage self, Fungible fungible, uint256 amount) internal {
        FungibleState state = self.fungibleStates[fungible];

        if (state.isEmpty()) {
            self.fungibles.push(fungible);
            self.fungibleStates[fungible] = toFungibleState(self.fungibles.length.toUint64(), amount.toUint192());
        } else {
            self.fungibleStates[fungible] = toFungibleState(state.index(), state.balance() + amount.toUint192()); // overflow desired
        }
    }

    /// @notice Remove fungible from a position
    /// @param self The position to remove fungible from
    /// @param fungible The fungible to remove
    /// @param amount The amount of fungible to remove
    function removeFungible(Position storage self, Fungible fungible, uint256 amount) internal {
        FungibleState state = self.fungibleStates[fungible];
        uint64 index = state.index();
        uint192 newBalance = state.balance() - amount.toUint192(); // underflow desired

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
            self.fungibleStates[fungible] = FungibleStateLibrary.EMPTY;
        }
    }

    /// @notice Add non-fungible to a position
    /// @param self The position to add non-fungible to
    /// @param nonFungible The non-fungible to add
    function addNonFungible(Position storage self, NonFungible nonFungible) internal {
        self.nonFungibles.push(nonFungible);
    }

    /// @notice Remove non-fungible from a position
    /// @param self The position to remove non-fungible from
    /// @param nonFungible The non-fungible to remove
    /// @return bool True if the non-fungible was removed, false if it was not found
    function removeNonFungible(Position storage self, NonFungible nonFungible) internal returns (bool) {
        uint256 count = self.nonFungibles.length;

        for (uint256 i = 0; i < count; ++i) {
            if (self.nonFungibles[i] == nonFungible) {
                if (i != count - 1) {
                    self.nonFungibles[i] = self.nonFungibles[count - 1];
                }
                self.nonFungibles.pop();

                return true;
            }
        }

        return false;
    }

    /// @notice Checks if the position is empty
    /// @param self The position to check
    /// @return bool True if the position is empty, false otherwise
    function isEmpty(Position storage self) internal view returns (bool) {
        return self.debtShare == 0 && self.fungibles.length == 0 && self.nonFungibles.length == 0;
    }
}
