// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.30;

import {RiskConfigs} from "src/RiskConfigs.sol";

contract RiskConfigsMock is RiskConfigs {
    constructor(address _governor) RiskConfigs(_governor) {}

    function loadGovernor() external view returns (address) {
        return governor;
    }

    function loadNextGovernor() external view returns (address) {
        return nextGovernor;
    }

    function loadOracle() external view returns (address) {
        return address(oracle);
    }

    function loadProtocolFeeRecipient() external view returns (address) {
        return protocolFeeRecipient;
    }

    function loadProtocolFeePips() external view returns (uint24) {
        return protocolFeePips;
    }

    function loadPositionMrrPips() external view returns (uint24) {
        return positionMrrPips;
    }
}
