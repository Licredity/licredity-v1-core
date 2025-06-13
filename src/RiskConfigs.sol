// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOracle} from "./interfaces/IOracle.sol";
import {Math} from "./libraries/Math.sol";
import {Fungible} from "./types/Fungible.sol";

/// @title RiskConfigs
/// @notice Abstract implementation of the IRiskConfigs interface
abstract contract RiskConfigs {
    uint256 internal constant ORACLE_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant POSITION_MRR_BPS_MASK = 0xffff0000000000000000000000000000000000000000;
    uint256 internal constant POSITION_MRR_BPS_OFFSET = 160;
    uint256 internal constant PROTOCOL_FEE_BPS_MASK = 0xffff00000000000000000000000000000000000000000000;
    uint256 internal constant PROTOCOL_FEE_BPS_OFFSET = 176;

    address internal governor;
    address internal pendingGovernor;
    IOracle internal oracle;
    uint16 internal positionMrrBps;
    uint16 internal protocolFeeBps;
    address internal protocolFeeRecipient;

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
            if iszero(eq(caller(), sload(pendingGovernor.slot))) {
                mstore(0x00, 0xcea73e00) // 'NotPendingGovernor()'
                revert(0x1c, 0x04)
            }

            sstore(governor.slot, caller())
            sstore(pendingGovernor.slot, 0x00)
        }
    }

    /// @notice Sets the oracle
    /// @param _oracle The address of the oracle
    function setOracle(address _oracle) external onlyGovernor {
        assembly ("memory-safe") {
            let maskedSlot := and(sload(oracle.slot), not(ORACLE_MASK))
            sstore(oracle.slot, or(maskedSlot, and(_oracle, ORACLE_MASK)))
        }
    }

    /// @notice Sets the position margin requirement ratio in basis points
    /// @param _positionMrrBps The position margin requirement ratio in basis points
    function setPositionMrrBps(uint16 _positionMrrBps) external onlyGovernor {
        uint16 bps = Math.UNIT_BASIS_POINTS;

        assembly ("memory-safe") {
            if gt(_positionMrrBps, bps) {
                mstore(0x00, 0x56701746) // 'InvalidPositionMrrBps()'
                revert(0x1c, 0x04)
            }

            let maskedSlot := and(sload(positionMrrBps.slot), not(POSITION_MRR_BPS_MASK))
            let maskedValue := and(shl(POSITION_MRR_BPS_OFFSET, _positionMrrBps), POSITION_MRR_BPS_MASK)

            sstore(positionMrrBps.slot, or(maskedSlot, maskedValue))
        }
    }

    /// @notice Sets the protocol fee in basis points
    /// @param _protocolFeeBps The protocol fee in basis points
    function setProtocolFeeBps(uint16 _protocolFeeBps) external onlyGovernor {
        uint16 bps = Math.UNIT_BASIS_POINTS;

        assembly ("memory-safe") {
            if gt(_protocolFeeBps, bps) {
                mstore(0x00, 0xa535919f) // 'InvalidProtocolFeeBps()'
                revert(0x1c, 0x04)
            }

            let maskedSlot := and(sload(protocolFeeBps.slot), not(PROTOCOL_FEE_BPS_MASK))
            let maskedValue := and(shl(PROTOCOL_FEE_BPS_OFFSET, _protocolFeeBps), PROTOCOL_FEE_BPS_MASK)

            sstore(protocolFeeBps.slot, or(maskedSlot, maskedValue))
        }
    }

    /// @notice Sets the protocol fee recipient
    /// @param _protocolFeeRecipient The address of the protocol fee recipient
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyGovernor {
        assembly ("memory-safe") {
            sstore(protocolFeeRecipient.slot, _protocolFeeRecipient)
        }
    }
}
