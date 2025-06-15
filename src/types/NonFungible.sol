// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title NonFungible
/// @notice Represents a non-fungible token
/// @dev 160 bits token address | 32 bits empty | 64 bits token id
type NonFungible is bytes32;

using NonFungibleLibrary for NonFungible global;

/// @title NonFungibleLibrary
/// @notice Library for managing non-fungible tokens
library NonFungibleLibrary {}
