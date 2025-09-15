// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.30;

import {RiskConfigs} from "src/RiskConfigs.sol";

contract RiskConfigsMock is RiskConfigs {
    constructor(address _governor) RiskConfigs(_governor) {}

    function loadGovernor() external view returns (address) {
        return _governor;
    }

    function loadNextGovernor() external view returns (address) {
        return _nextGovernor;
    }

    function loadOracle() external view returns (address) {
        return address(_oracle);
    }

    function loadProtocolFeeRecipient() external view returns (address) {
        return _protocolFeeRecipient;
    }

    function loadProtocolFeePips() external view returns (uint256) {
        return _protocolFeePips;
    }

    function loadDebtLimit() external view returns (uint256) {
        return _debtLimit;
    }

    function loadMinMargin() external view returns (uint256) {
        return _minMargin;
    }

    function _collectInterest(bool) internal virtual override {}
}
