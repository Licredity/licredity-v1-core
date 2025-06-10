// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOracle} from "./interfaces/IOracle.sol";

/// @title RiskConfigs
/// @notice Abstract implementation of the IRiskConfigs interface
abstract contract RiskConfigs {
    uint16 internal constant UNIT_BASIS_POINTS = 10000;
    uint256 internal constant ORACLE_SLOT_MASK = 0xffff0000000000000000000000000000000000000000;

    address internal governor;
    address internal pendingGovernor;
    IOracle internal oracle;
    uint16 internal minMarginRequirementBps;

    /// @notice Modifier for functions that can only be called by the governor
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        assembly ("memory-safe") {
            if iszero(eq(caller(), sload(governor.slot))) {
                mstore(0x00, 0xee3675d4) // 'NotGovernor()'
                revert(0x1c, 0x04)
            }
        }
    }

    constructor(address _governor) {
        governor = _governor;
    }

    /// @notice Appoints a new governor
    /// @param _governor The address of the new governor
    function appointGovernor(address _governor) external onlyGovernor {
        pendingGovernor = _governor;
    }

    /// @notice Confirms the appointment of a new governor
    function confirmGovernor() external {
        assembly ("memory-safe") {
            let _pendingGovernor := sload(pendingGovernor.slot)

            if iszero(eq(caller(), _pendingGovernor)) {
                mstore(0x00, 0xcea73e00) // 'NotPendingGovernor()'
                revert(0x1c, 0x04)
            }

            sstore(governor.slot, _pendingGovernor)
            sstore(pendingGovernor.slot, 0x00)
        }
    }

    /// @notice Sets the oracle
    /// @param _oracle The address of the oracle
    function setOracle(address _oracle) external onlyGovernor {
        assembly ("memory-safe") {
            let slot := and(sload(oracle.slot), ORACLE_SLOT_MASK)
            sstore(oracle.slot, or(slot, and(_oracle, 0xffffffffffffffffffffffffffffffffffffffff)))
        }
    }

    /// @notice Sets the minimum margin requirement in basis points
    /// @param _minMarginRequirementBps The minimum margin requirement in basis points
    function setMinMarginRequirementBps(uint16 _minMarginRequirementBps) external onlyGovernor {
        assembly ("memory-safe") {
            _minMarginRequirementBps := and(_minMarginRequirementBps, 0xffff)

            if gt(_minMarginRequirementBps, UNIT_BASIS_POINTS) {
                mstore(0x00, 0x8505f13c) // 'InvalidMinMarginRequirementBps()'
                revert(0x1c, 0x04)
            }

            let slot := and(sload(minMarginRequirementBps.slot), not(ORACLE_SLOT_MASK))

            sstore(minMarginRequirementBps.slot, or(slot, shl(160, and(_minMarginRequirementBps, 0xffff))))
        }
    }
}
