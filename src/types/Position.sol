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

    /// @notice Sets the owner of a position
    /// @param self The position to set owner for
    /// @param owner The new owner of the position
    function setOwner(Position storage self, address owner) internal {
        self.owner = owner;
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
        self.nonFungibles.push(nonFungible);
    }

    /// @notice Removes a non-fungible from a position
    /// @param self The position to remove non-fungible from
    /// @param nonFungible The non-fungible to remove
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
        return self.debtShare == 0 && self.fungibles.length == 0 && self.nonFungibles.length == 0;
    }
}
