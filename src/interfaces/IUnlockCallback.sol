// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IUnlockCallback
/// @notice Interface for the unlock callback contracts
interface IUnlockCallback {
    /// @notice Handles the unlock callback
    /// @param data The data passed from the unlock operation
    /// @return result The result to be returned to the unlock operation
    function unlockCallback(bytes calldata data) external returns (bytes memory result);
}
