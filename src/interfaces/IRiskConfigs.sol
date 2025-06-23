// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title IRiskConfigs
/// @notice Interface for the risk configurations contract
interface IRiskConfigs {
    /// @notice Emitted when the next governor is appointed
    /// @param nextGovernor The next governor
    event AppointNextGovernor(address indexed nextGovernor);

    /// @notice Emitted when the next governor is confirmed
    /// @param lastGovernor The last governor
    /// @param newGovernor The new governor
    event ConfirmNextGovernor(address indexed lastGovernor, address indexed newGovernor);

    /// @notice Emitted when the oracle is set
    /// @param oracle The new oracle
    event SetOracle(address indexed oracle);

    /// @notice Emitted when the debt limit is set
    /// @param debtLimit The new debt limit
    event SetDebtLimit(uint256 debtLimit);

    /// @notice Emitted when the minimum margin is set
    /// @param minMargin The new minimum margin
    event SetMinMargin(uint256 minMargin);

    /// @notice Emitted when the protocol fee in pips are set
    /// @param protocolFeePips The new protocol fee in pips
    event SetProtocolFeePips(uint256 protocolFeePips);

    /// @notice Emitted when the protocol fee recipient is set
    /// @param protocolFeeRecipient The new protocol fee recipient
    event SetProtocolFeeRecipient(address indexed protocolFeeRecipient);
}
