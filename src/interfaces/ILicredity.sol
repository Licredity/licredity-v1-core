// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title ILicredity
/// @notice Interface for the Licredity contract
interface ILicredity {
    /// @notice Unlocks the Licredity contract
    /// @param data The data to be passed to the unlock callback
    /// @return result The result returned from the unlock callback
    function unlock(bytes calldata data) external returns (bytes memory result);
}
