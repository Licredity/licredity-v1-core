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

    /// @notice Emitted when the minimum liquidity lifespan is set
    /// @param minLiquidityLifespan The new minimum liquidity lifespan in seconds
    event SetMinLiquidityLifespan(uint256 minLiquidityLifespan);

    /// @notice Emitted when the protocol fee in pips are set
    /// @param protocolFeePips The new protocol fee in pips
    event SetProtocolFeePips(uint256 protocolFeePips);

    /// @notice Emitted when the protocol fee recipient is set
    /// @param protocolFeeRecipient The new protocol fee recipient
    event SetProtocolFeeRecipient(address indexed protocolFeeRecipient);

    /// @notice Appoints the next governor
    /// @param nextGovernor The next governor
    /// @dev Can only be called by the current governor
    function appointNextGovernor(address nextGovernor) external;

    /// @notice Confirms the new governor
    /// @dev Can only be called by the next governor
    function confirmNextGovernor() external;

    /// @notice Sets the oracle
    /// @param oracle The oracle
    /// @dev Can only be called by the current governor
    function setOracle(address oracle) external;

    /// @notice Sets the debt limit
    /// @param debtLimit The debt limit
    /// @dev Can only be called by the current governor
    function setDebtLimit(uint256 debtLimit) external;

    /// @notice Sets the minimum margin
    /// @param minMargin The minimum margin
    /// @dev Can only be called by the current governor
    function setMinMargin(uint256 minMargin) external;

    /// @notice Sets the minimum liquidity lifespan
    /// @param minLiquidityLifespan The minimum liquidity lifespan in seconds
    /// @dev Can only be called by the current governor
    function setMinLiquidityLifespan(uint256 minLiquidityLifespan) external;

    /// @notice Sets the protocol fee in pips
    /// @param protocolFeePips The protocol fee in pips
    /// @dev Can only be called by the current governor
    function setProtocolFeePips(uint256 protocolFeePips) external;

    /// @notice Sets the protocol fee recipient
    /// @param protocolFeeRecipient The protocol fee recipient
    /// @dev Can only be called by the current governor
    function setProtocolFeeRecipient(address protocolFeeRecipient) external;
}
