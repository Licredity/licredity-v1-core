// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOracle} from "./interfaces/IOracle.sol";
import {IRiskConfigs} from "./interfaces/IRiskConfigs.sol";
import {PipsMath} from "./libraries/PipsMath.sol";

/// @title RiskConfigs
/// @notice Abstract implementation of risk configurations
abstract contract RiskConfigs is IRiskConfigs {
    uint256 private constant MAX_MIN_LIQUIDITY_LIFESPAN = 7 days;
    uint256 private constant MAX_PROTOCOL_FEE_PIPS = PipsMath.ONE_PIPS / 2 ** 4; // 6.25%

    address internal _governor;
    address internal _nextGovernor;
    IOracle internal _oracle;
    uint256 internal _debtLimit; // global debt limit in debt fungible
    uint256 internal _minMargin; // minimum margin in an indebted position
    uint256 internal _minLiquidityLifespan; // minimum lifespan of a liquidity position in seconds
    uint24 internal _protocolFeePips;
    address internal _protocolFeeRecipient;

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        // require(msg.sender == _governor, NotGovernor());
        assembly ("memory-safe") {
            if iszero(eq(caller(), sload(_governor.slot))) {
                mstore(0x00, 0xee3675d4) // 'NotGovernor()'
                revert(0x1c, 0x04)
            }
        }
    }

    constructor(address governor) {
        _governor = governor;
    }

    /// @inheritdoc IRiskConfigs
    function appointNextGovernor(address nextGovernor) external onlyGovernor {
        assembly ("memory-safe") {
            nextGovernor := and(nextGovernor, 0xffffffffffffffffffffffffffffffffffffffff)

            // _nextGovernor = nextGovernor;
            sstore(_nextGovernor.slot, nextGovernor)

            // emit AppointNextGovernor(nextGovernor);
            log2(0x00, 0x00, 0x192874f7d03868e0e27e79172ef01f27e1200fd3a5b08d7b3986fbe037125ee8, nextGovernor)
        }
    }

    /// @inheritdoc IRiskConfigs
    function confirmNextGovernor() external {
        assembly ("memory-safe") {
            // require(msg.sender == _nextGovernor, NotNextGovernor());
            if iszero(eq(caller(), sload(_nextGovernor.slot))) {
                mstore(0x00, 0x7dc8c6f8) // 'NotNextGovernor()'
                revert(0x1c, 0x04)
            }

            // address lastGovernor = _governor;
            let lastGovernor := sload(_governor.slot) // no dirty bits possible

            // transfer governor role to the next governor and clear nextGovernor
            // _governor = msg.sender;
            // delete _nextGovernor;
            sstore(_governor.slot, caller())
            sstore(_nextGovernor.slot, 0x00)

            // emit ConfirmNextGovernor(lastGovernor, msg.sender);
            log3(0x00, 0x00, 0x7c33d066bdd1139ec2077fef5825172051fa827c50f89af128ae878e44e44632, lastGovernor, caller())
        }
    }

    /// @inheritdoc IRiskConfigs
    function setOracle(address oracle) external onlyGovernor {
        assembly ("memory-safe") {
            oracle := and(oracle, 0xffffffffffffffffffffffffffffffffffffffff)

            // _oracle = oracle;
            sstore(_oracle.slot, oracle)

            // emit SetOracle(oracle);
            log2(0x00, 0x00, 0xd3b5d1e0ffaeff528910f3663f0adace7694ab8241d58e17a91351ced2e08031, oracle)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setDebtLimit(uint256 debtLimit) external onlyGovernor {
        assembly ("memory-safe") {
            // _debtLimit = debtLimit;
            sstore(_debtLimit.slot, debtLimit)

            // emit SetDebtLimit(debtLimit);
            mstore(0x00, debtLimit)
            log1(0x00, 0x20, 0xe0f0b7b6b88dbfa7d2d8d71a265ff500ccbafdb56c820e058b9a4c66d007c312)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setMinMargin(uint256 minMargin) external onlyGovernor {
        assembly ("memory-safe") {
            // _minMargin = minMargin;
            sstore(_minMargin.slot, minMargin)

            // emit SetMinMargin(minMargin);
            mstore(0x00, minMargin)
            log1(0x00, 0x20, 0x49ec42791c6fc287661930b06d5ae845a2bc030c0edc63db175b4e4092458d5b)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setMinLiquidityLifespan(uint256 minLiquidityLifespan) external onlyGovernor {
        uint256 maxMinLiquidityLifespan = MAX_MIN_LIQUIDITY_LIFESPAN;

        assembly ("memory-safe") {
            // require(minLiquidityLifespan <= MAX_MIN_LIQUIDITY_LIFESPAN, MaxMinLiquidityLifespanExceeded());
            if gt(minLiquidityLifespan, maxMinLiquidityLifespan) {
                mstore(0x00, 0x673c8224) // 'MaxMinLiquidityLifespanExceeded()'
                revert(0x1c, 0x04)
            }

            // _minLiquidityLifespan = minLiquidityLifespan;
            sstore(_minLiquidityLifespan.slot, minLiquidityLifespan)

            // emit SetMinLiquidityLifespan(minLiquidityLifespan);
            mstore(0x00, minLiquidityLifespan)
            log1(0x00, 0x20, 0xec2fc83a63c373b5e2712344cfb94409f5688a351e7266d18d37e4a4a10baf8e)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setProtocolFeePips(uint256 protocolFeePips) external onlyGovernor {
        uint256 maxProtocolFeePips = MAX_PROTOCOL_FEE_PIPS;

        // collect interest first so that the new protocol fee is not applied retroactively
        _collectInterest(false);

        assembly ("memory-safe") {
            // require(protocolFeePips <= MAX_PROTOCOL_FEE_PIPS, MaxProtocolFeePipsExceeded());
            if gt(protocolFeePips, maxProtocolFeePips) {
                mstore(0x00, 0xf91fc24f) // 'MaxProtocolFeePipsExceeded()'
                revert(0x1c, 0x04)
            }

            // _protocolFeePips = protocolFeePips;
            sstore(_protocolFeePips.slot, or(shl(shr(sload(_protocolFeePips.slot), 24), 24), protocolFeePips))

            // emit SetProtocolFeePips(protocolFeePips);
            mstore(0x00, protocolFeePips)
            log1(0x00, 0x20, 0xb1a0d772ecb38fe2a9733de958330f541c1e2b510ff5089a41ba494078f90c48)
        }
    }

    /// @inheritdoc IRiskConfigs
    function setProtocolFeeRecipient(address protocolFeeRecipient) external onlyGovernor {
        assembly ("memory-safe") {
            protocolFeeRecipient := and(protocolFeeRecipient, 0xffffffffffffffffffffffffffffffffffffffff)

            // _protocolFeeRecipient = protocolFeeRecipient;
            sstore(
                _protocolFeeRecipient.slot,
                or(shl(24, protocolFeeRecipient), and(sload(_protocolFeeRecipient.slot), 0xffffff))
            )

            // emit SetProtocolFeeRecipient(protocolFeeRecipient);
            log2(0x00, 0x00, 0x0adecf76fa869b35236c53f76ec37546457966d5848d8be34a4508acdd51f7c3, protocolFeeRecipient)
        }
    }

    /// @notice internal virtual function to collect interest
    function _collectInterest(bool donate) internal virtual;
}
