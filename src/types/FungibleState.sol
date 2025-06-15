// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FungibleState
/// @notice Represents the state of a fungible token
/// @dev 64 bits index | 64 bits empty | 128 bits balance
type FungibleState is bytes32;

using FungibleStateLibrary for FungibleState global;

/// @title FungibleStateLibrary
/// @notice Library for managing fungible states
library FungibleStateLibrary {}
