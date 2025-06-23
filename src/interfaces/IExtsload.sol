// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IExtsload
/// @notice Interface for the Extsload contract
interface IExtsload {
    /// @notice Called by external contracts to access a contract state
    /// @param slot The slot to sload from
    /// @return value The sloaded value
    function extsload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Called by external contracts to access continuous states
    /// @param startSlot The slot to start sload from
    /// @param nSlots Number of slots to sload
    /// @return values The sloaded values
    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes32[] memory values);

    /// @notice Called by external contracts to access sparse states
    /// @param slots The slots to sload from
    /// @return values The sloaded values
    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory values);
}
