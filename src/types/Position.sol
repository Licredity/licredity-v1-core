// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {SafeCast} from "../libraries/SafeCast.sol";
import {Fungible} from "./Fungible.sol";
import {FungibleState, toFungibleState} from "./FungibleState.sol";
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
            self.fungibleStates[fungible] = state.add(amount.toUint192());
        }
    }

    /// @notice Checks if the position is empty
    /// @param self The position to check
    /// @return bool True if the position is empty, false otherwise
    function isEmpty(Position storage self) internal view returns (bool) {
        return self.debtShare == 0 && self.fungibles.length == 0 && self.nonFungibles.length == 0;
    }
}
