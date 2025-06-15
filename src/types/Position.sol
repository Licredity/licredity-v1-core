// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {Fungible} from "./Fungible.sol";
import {FungibleState} from "./FungibleState.sol";
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
library PositionLibrary {}
