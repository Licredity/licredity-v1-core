// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IUnlockExecutor
/// @notice Interface for the unlock executor contracts
interface IUnlockExecutor {
    /// @notice Handles the unlock execution on behalf of the sender
    /// @param sender The address initiating the unlock
    /// @param data The data passed from the unlock operation
    /// @return result The result to be returned to the unlock operation
    function execute(address sender, bytes calldata data) external payable returns (bytes memory result);
}
