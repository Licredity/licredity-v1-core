// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IExtsload
/// @notice Interface for the Extsload contract
interface IExtsload {
    /// @notice Called by external contracts to access a contract state
    /// @param slot The slot to sload from
    /// @return value The sloaded value
    function extsload(bytes32 slot) external view returns (bytes32 value);
}
