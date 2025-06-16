// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOracle} from "./interfaces/IOracle.sol";

/// @title RiskConfigs
/// @notice Abstract implementation of risk configurations
abstract contract RiskConfigs {
    uint24 internal constant UNIT_PIPS = 1_000_000;
    uint256 private constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant PROTOCOL_FEE_PIPS_MASK = 0xffffff0000000000000000000000000000000000000000;
    uint256 private constant PROTOCOL_FEE_PIPS_OFFSET = 160;
    uint256 private constant POSITION_MRR_PIPS_MASK = 0xffffff0000000000000000000000000000000000000000000000;
    uint256 private constant POSITION_MRR_PIPS_OFFSET = 184;

    address internal governor;
    address internal nextGovernor;
    IOracle internal oracle;
    address internal protocolFeeRecipient;
    uint24 internal protocolFeePips;
    uint24 internal positionMrrPips;

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

    /// @notice Appoints the next governor
    /// @param _nextGovernor The next governor
    function appointGovernor(address _nextGovernor) external onlyGovernor {
        assembly ("memory-safe") {
            sstore(nextGovernor.slot, and(_nextGovernor, ADDRESS_MASK))
        }
    }

    /// @notice Confirms the new governor
    function confirmGovernor() external {
        assembly ("memory-safe") {
            if iszero(eq(caller(), sload(nextGovernor.slot))) {
                mstore(0x00, 0x7dc8c6f8) // 'NotNextGovernor()'
                revert(0x1c, 0x04)
            }

            sstore(governor.slot, caller())
            sstore(nextGovernor.slot, 0x00)
        }
    }

    /// @notice Sets the oracle
    /// @param _oracle The oracle
    function setOracle(address _oracle) external onlyGovernor {
        assembly ("memory-safe") {
            sstore(oracle.slot, and(_oracle, ADDRESS_MASK))
        }
    }

    /// @notice Sets the protocol fee recipient
    /// @param _protocolFeeRecipient The protocol fee recipient
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyGovernor {
        assembly ("memory-safe") {
            let maskedSlot := and(sload(protocolFeeRecipient.slot), not(ADDRESS_MASK))
            sstore(protocolFeeRecipient.slot, or(maskedSlot, and(_protocolFeeRecipient, ADDRESS_MASK)))
        }
    }

    /// @notice Sets the protocol fee in pips
    /// @param _protocolFeePips The protocol fee in pips
    function setProtocolFeePips(uint24 _protocolFeePips) external onlyGovernor {
        assembly ("memory-safe") {
            if gt(_protocolFeePips, UNIT_PIPS) {
                mstore(0x00, 0x4587a813) // 'InvalidProtocolFeePips()'
                revert(0x1c, 0x04)
            }

            let maskedSlot := and(sload(protocolFeePips.slot), not(PROTOCOL_FEE_PIPS_MASK))
            let maskedValue := and(shl(PROTOCOL_FEE_PIPS_OFFSET, _protocolFeePips), PROTOCOL_FEE_PIPS_MASK)

            sstore(protocolFeePips.slot, or(maskedSlot, maskedValue))
        }
    }

    /// @notice Sets the position margin requirement ratio in pips
    /// @param _positionMrrPips The position margin requirement ratio in pips
    function setPositionMrrPips(uint24 _positionMrrPips) external onlyGovernor {
        assembly ("memory-safe") {
            if gt(_positionMrrPips, UNIT_PIPS) {
                mstore(0x00, 0x88b3e212) // 'InvalidPositionMrrPips()'
                revert(0x1c, 0x04)
            }

            let maskedSlot := and(sload(positionMrrPips.slot), not(POSITION_MRR_PIPS_MASK))
            let maskedValue := and(shl(POSITION_MRR_PIPS_OFFSET, _positionMrrPips), POSITION_MRR_PIPS_MASK)

            sstore(positionMrrPips.slot, or(maskedSlot, maskedValue))
        }
    }
}
