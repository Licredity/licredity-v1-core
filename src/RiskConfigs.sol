// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOracle} from "./interfaces/IOracle.sol";
import {IRiskConfigs} from "./interfaces/IRiskConfigs.sol";
import {PipsMath} from "./libraries/PipsMath.sol";

/// @title RiskConfigs
/// @notice Abstract implementation of risk configurations
abstract contract RiskConfigs is IRiskConfigs {
    address internal governor;
    address internal nextGovernor;
    IOracle internal oracle;
    uint256 internal debtLimit; // global debt limit in debt fungible
    uint256 internal minMargin; // minimum margin in an indebted position
    uint24 internal protocolFeePips;
    address internal protocolFeeRecipient;

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        // require(msg.sender == governor, NotGovernor());
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

    /// @inheritdoc IRiskConfigs
    function appointNextGovernor(address _nextGovernor) external onlyGovernor {
        assembly ("memory-safe") {
            _nextGovernor := and(_nextGovernor, 0xffffffffffffffffffffffffffffffffffffffff)

            // nextGovernor = _nextGovernor;
            sstore(nextGovernor.slot, _nextGovernor)

            // emit AppointNextGovernor(_nextGovernor);
            log2(0x00, 0x00, 0x192874f7d03868e0e27e79172ef01f27e1200fd3a5b08d7b3986fbe037125ee8, _nextGovernor)
        }
    }

    /// @inheritdoc IRiskConfigs
    function confirmNextGovernor() external {
        assembly ("memory-safe") {
            // require(msg.sender == nextGovernor, NotNextGovernor());
            if iszero(eq(caller(), sload(nextGovernor.slot))) {
                mstore(0x00, 0x7dc8c6f8) // 'NotNextGovernor()'
                revert(0x1c, 0x04)
            }

            // address lastGovernor = governor;
            // no dirty bits
            let lastGovernor := sload(governor.slot)

            // transfer governor role to the next governor and clear nextGovernor
            // governor = msg.sender;
            // delete nextGovernor;
            sstore(governor.slot, caller())
            sstore(nextGovernor.slot, 0x00)

            // emit ConfirmNextGovernor(lastGovernor, msg.sender);
            log3(0x00, 0x00, 0x7c33d066bdd1139ec2077fef5825172051fa827c50f89af128ae878e44e44632, lastGovernor, caller())
        }
    }

    /// @inheritdoc IRiskConfigs
    function setOracle(address _oracle) external onlyGovernor {
        assembly ("memory-safe") {
            _oracle := and(_oracle, 0xffffffffffffffffffffffffffffffffffffffff)

            // oracle = _oracle;
            sstore(oracle.slot, _oracle)

            // emit SetOracle(_oracle);
            log2(0x00, 0x00, 0xd3b5d1e0ffaeff528910f3663f0adace7694ab8241d58e17a91351ced2e08031, _oracle)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setDebtLimit(uint256 _debtLimit) external onlyGovernor {
        assembly ("memory-safe") {
            // debtLimit = _debtLimit;
            sstore(debtLimit.slot, _debtLimit)

            // emit SetDebtLimit(_debtLimit);
            mstore(0x00, _debtLimit)
            log1(0x00, 0x20, 0xe0f0b7b6b88dbfa7d2d8d71a265ff500ccbafdb56c820e058b9a4c66d007c312)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setMinMargin(uint256 _minMargin) external onlyGovernor {
        assembly ("memory-safe") {
            // minMargin = _minMargin;
            sstore(minMargin.slot, _minMargin)

            // emit SetMinMargin(_minMargin);
            mstore(0x00, _minMargin)
            log1(0x00, 0x20, 0x49ec42791c6fc287661930b06d5ae845a2bc030c0edc63db175b4e4092458d5b)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setProtocolFeePips(uint256 _protocolFeePips) external onlyGovernor {
        uint256 uintPips = PipsMath.UNIT_PIPS;
        // collect interest first so that the new protocol fee is not applied retroactively
        _collectInterest(false);

        assembly ("memory-safe") {
            // require(_protocolFeePips <= UNIT_PIPS / 2 ** 4, InvalidProtocolFeePips());
            if gt(_protocolFeePips, shr(4, uintPips)) {
                mstore(0x00, 0x4587a813) // 'InvalidProtocolFeePips()'
                revert(0x1c, 0x04)
            }

            // protocolFeePips = _protocolFeePips;
            sstore(
                protocolFeePips.slot,
                or(and(sload(protocolFeePips.slot), 0xffffffffffffffffffffffffffffffffffffffff000000), _protocolFeePips)
            )

            // emit SetProtocolFeePips(_protocolFeePips);
            mstore(0x00, _protocolFeePips)
            log1(0x00, 0x20, 0xb1a0d772ecb38fe2a9733de958330f541c1e2b510ff5089a41ba494078f90c48)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyGovernor {
        assembly ("memory-safe") {
            _protocolFeeRecipient := and(_protocolFeeRecipient, 0xffffffffffffffffffffffffffffffffffffffff)

            // protocolFeeRecipient = _protocolFeeRecipient;
            sstore(
                protocolFeeRecipient.slot,
                or(shl(24, _protocolFeeRecipient), and(sload(protocolFeeRecipient.slot), 0xffffff))
            )

            // emit SetProtocolFeeRecipient(_protocolFeeRecipient);
            log2(0x00, 0x00, 0x0adecf76fa869b35236c53f76ec37546457966d5848d8be34a4508acdd51f7c3, _protocolFeeRecipient)
        }
    }

    /// @notice internal virtual function to collect interest
    function _collectInterest(bool donate) internal virtual;
}
