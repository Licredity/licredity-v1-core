// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Fungible
/// @notice Represents a fungible token
type Fungible is address;

using FungibleLibrary for Fungible global;

/// @title FungibleLibrary
/// @notice Library for managing fungible tokens
library FungibleLibrary {}
