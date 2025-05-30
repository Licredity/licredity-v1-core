// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {Fungible} from "./Fungible.sol";
import {FungibleState} from "./FungibleState.sol";
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
    /// @notice Sets the owner of the position
    /// @param self The position to set the owner for
    /// @param owner The new owner of the position
    function setOwner(Position storage self, address owner) internal {
        self.owner = owner;
    }

    /// @notice Checks if the position is empty
    /// @param self The position to check
    /// @return bool True if the position is empty, false otherwise
    function isEmpty(Position storage self) internal view returns (bool) {
        return self.debtShare == 0 && self.fungibles.length == 0 && self.nonFungibles.length == 0;
    }
}
