// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOracle} from "./interfaces/IOracle.sol";
import {PipsMath} from "./libraries/PipsMath.sol";

/// @title RiskConfigs
/// @notice Abstract implementation of risk configurations
abstract contract RiskConfigs {
    address internal governor;
    address internal nextGovernor;
    IOracle internal oracle;
    uint256 internal debtLimit; // global debt limit in debt fungible
    uint256 internal minMargin; // minimum margin in an indebted position
    uint256 internal protocolFeePips;
    address internal protocolFeeRecipient;

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        // require(caller() == governor, NotGovernor());
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
    function appointNextGovernor(address _nextGovernor) external onlyGovernor {
        assembly ("memory-safe") {
            sstore(nextGovernor.slot, and(_nextGovernor, 0xffffffffffffffffffffffffffffffffffffffff))
        }
    }

    /// @notice Confirms the new governor
    function confirmNextGovernor() external {
        assembly ("memory-safe") {
            // require(caller() == nextGovernor, NotNextGovernor());
            if iszero(eq(caller(), sload(nextGovernor.slot))) {
                mstore(0x00, 0x7dc8c6f8) // 'NotNextGovernor()'
                revert(0x1c, 0x04)
            }

            // transfer governor role to the next governor and clear nextGovernor
            sstore(governor.slot, caller())
            sstore(nextGovernor.slot, 0x00)
        }
    }

    /// @notice Sets the oracle
    /// @param _oracle The oracle
    function setOracle(address _oracle) external onlyGovernor {
        assembly ("memory-safe") {
            sstore(oracle.slot, and(_oracle, 0xffffffffffffffffffffffffffffffffffffffff))
        }
    }

    /// @notice Sets the debt limit
    /// @param _debtLimit The debt limit
    function setDebtLimit(uint256 _debtLimit) external onlyGovernor {
        assembly ("memory-safe") {
            sstore(debtLimit.slot, _debtLimit)
        }
    }

    /// @notice Sets the minimum margin
    /// @param _minMargin The minimum margin
    function setMinMargin(uint256 _minMargin) external onlyGovernor {
        assembly ("memory-safe") {
            sstore(minMargin.slot, _minMargin)
        }
    }

    /// @notice Sets the protocol fee in pips
    /// @param _protocolFeePips The protocol fee in pips
    function setProtocolFeePips(uint256 _protocolFeePips) external onlyGovernor {
        uint256 uintPips = PipsMath.UNIT_PIPS;

        assembly ("memory-safe") {
            // require(_protocolFeePips <= UNIT_PIPS / 2 ** 4, InvalidProtocolFeePips());
            if gt(_protocolFeePips, shr(4, uintPips)) {
                mstore(0x00, 0x4587a813) // 'InvalidProtocolFeePips()'
                revert(0x1c, 0x04)
            }

            // protocolFeePips = _protocolFeePips;
            sstore(protocolFeePips.slot, _protocolFeePips)
        }
    }

    /// @notice Sets the protocol fee recipient
    /// @param _protocolFeeRecipient The protocol fee recipient
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyGovernor {
        assembly ("memory-safe") {
            // protocolFeeRecipient = _protocolFeeRecipient;
            sstore(protocolFeeRecipient.slot, and(_protocolFeeRecipient, 0xffffffffffffffffffffffffffffffffffffffff))
        }
    }
}
