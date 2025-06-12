// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Fungible} from "../types/Fungible.sol";
import {NonFungible} from "../types/NonFungible.sol";

/// @title IOracle
/// @notice Interface for the oracle contracts
interface IOracle {
    /// @notice Gets the price of the base fungible in debt fungible terms
    /// @return uint256 The price of the base fungible in debt fungible terms
    function getBasePrice() external view returns (uint256);

    /// @notice Function to get the value and margin requirement, in debt token terms, of some amount of fungible
    /// @param fungible The fungible to quote
    /// @param amount The amount of fungible to quote
    /// @return value The value of the fungible in debt token terms
    /// @return marginRequirement The margin requirement in debt token terms
    function quoteFungible(Fungible fungible, uint256 amount)
        external
        view
        returns (uint256 value, uint256 marginRequirement);

    /// @notice Function to get the value and margin requirement, in debt token terms, of a non-fungible
    /// @param nonFungible The non-fungible to quote
    /// @return value The value of the non-fungible in debt token terms
    /// @return marginRequirement The margin requirement in debt token terms
    function quoteNonFungible(NonFungible nonFungible)
        external
        view
        returns (uint256 value, uint256 marginRequirement);

    /// @notice Function to notify the oracle of a price update
    function update() external;
}
