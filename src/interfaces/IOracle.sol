// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";

/// @title IOracle
/// @notice Interface for the oracle contracts
interface IOracle {
    /// @notice Gets the price of the base fungible in debt fungible terms
    /// @return uint256 The price of the base fungible in debt fungible terms
    function quotePrice() external view returns (uint256);

    /// @notice Function to get the value and margin requirement, in debt token terms, of fungibles
    /// @param tokens The fungible tokens to quote
    /// @param amounts The amounts of fungible to quote
    /// @return value The value of the fungible in debt token terms
    /// @return marginRequirement The margin requirement in debt token terms
    function quoteFungibles(address[] memory tokens, uint256[] memory amounts)
        external
        returns (uint256 value, uint256 marginRequirement);

    /// @notice Function to get the value and margin requirement, in debt token terms, of non-fungibles
    /// @param tokens The non-fungible tokens to quote
    /// @param ids The IDs of the non-fungible to quote
    /// @return value The value of the non-fungible in debt token terms
    /// @return marginRequirement The margin requirement in debt token terms
    function quoteNonFungibles(address[] memory tokens, uint256[] memory ids)
        external
        returns (uint256 value, uint256 marginRequirement);

    /// @notice Function to notify the oracle of a price update
    function update() external;
}
