// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";

/// @title IOracle
/// @notice Interface for the oracle contracts
interface IOracle {
    /// @notice Quotes the price of base fungible in debt fungible
    /// @return uint256 The price of base fungible in debt fungible
    /// @dev Price has 18 decimal places
    function quotePrice() external view returns (uint256);

    /// @notice Quotes the value and margin requirement for given fungibles in debt fungible
    /// @param fungibles The fungibles to quote
    /// @param amounts The amounts of fungibles to quote
    /// @return value The total value of the fungibles in debt fungible
    /// @return marginRequirement The total margin requirement of the fungibles in debt fungible
    function quoteFungibles(Fungible[] memory fungibles, uint256[] memory amounts)
        external
        returns (uint256 value, uint256 marginRequirement);

    /// @notice Quotes the value and margin requirement for given non-fungibles in debt fungible
    /// @param nonFungibles The non-fungibles to quote
    /// @return value The total value of the non-fungibles in debt fungible
    /// @return marginRequirement The total margin requirement of the non-fungibles in debt fungible
    function quoteNonFungibles(NonFungible[] memory nonFungibles)
        external
        returns (uint256 value, uint256 marginRequirement);

    /// @notice Triggers a price update (base fungible in debt fungible)
    function update() external;
}
