// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {IRiskConfigs} from "../src/interfaces/IRiskConfigs.sol";
import {RiskConfigsMock} from "./mocks/RiskConfigsMock.sol";

contract RiskConfigsTest is Test {
    RiskConfigsMock public riskConfigs;

    function setUp() public {
        riskConfigs = new RiskConfigsMock(address(this));
    }

    function test_appointNextGovernor_notOwner() public {
        vm.startPrank(address(1));
        vm.expectRevert(IRiskConfigs.NotGovernor.selector);
        riskConfigs.appointNextGovernor(address(1));
        vm.stopPrank();
    }

    function test_appointNextGovernor(address[] calldata nextGovernors) public {
        vm.assume(nextGovernors.length > 1);
        for (uint256 i = 0; i < nextGovernors.length; i++) {
            vm.expectEmit(true, false, false, false);
            emit IRiskConfigs.AppointNextGovernor(nextGovernors[i]);
            riskConfigs.appointNextGovernor(nextGovernors[i]);
        }

        assertEq(riskConfigs.loadNextGovernor(), nextGovernors[nextGovernors.length - 1]);
    }

    function test_confirmNextGovernor(address _governorAddr) public {
        riskConfigs.appointNextGovernor(_governorAddr);

        vm.startPrank(_governorAddr);
        vm.expectEmit(true, true, false, false);
        emit IRiskConfigs.ConfirmNextGovernor(address(this), _governorAddr);
        riskConfigs.confirmNextGovernor();
        vm.stopPrank();

        assertEq(riskConfigs.loadGovernor(), _governorAddr);
        assertEq(riskConfigs.loadNextGovernor(), address(0));
    }

    function test_confirmNextGovernor_notPending(address pendingAddr, address other) public {
        vm.assume(pendingAddr != other);

        riskConfigs.appointNextGovernor(pendingAddr);

        vm.startPrank(other);
        vm.expectRevert(IRiskConfigs.NotNextGovernor.selector);
        riskConfigs.confirmNextGovernor();
        vm.stopPrank();
    }

    function test_setOracle(address[] calldata oracles) public {
        vm.assume(oracles.length > 1);
        for (uint256 i = 0; i < oracles.length; i++) {
            vm.expectEmit(true, false, false, false);
            emit IRiskConfigs.SetOracle(oracles[i]);

            riskConfigs.setOracle(oracles[i]);
        }

        assertEq(riskConfigs.loadOracle(), oracles[oracles.length - 1]);
    }

    function test_setProtocolFeeRecipient(address[] calldata protocolFeeRecipients) public {
        vm.assume(protocolFeeRecipients.length > 1);
        for (uint256 i = 0; i < protocolFeeRecipients.length; i++) {
            vm.expectEmit(true, false, false, false);
            emit IRiskConfigs.SetProtocolFeeRecipient(protocolFeeRecipients[i]);
            riskConfigs.setProtocolFeeRecipient(protocolFeeRecipients[i]);
        }

        assertEq(riskConfigs.loadProtocolFeeRecipient(), protocolFeeRecipients[protocolFeeRecipients.length - 1]);
    }

    function test_setProtocolFeePips_invalid(uint256 _protocolFeePips) public {
        uint256 protocolFeePips = bound(_protocolFeePips, 62501, type(uint24).max);
        vm.expectRevert(IRiskConfigs.MaxProtocolFeePipsExceeded.selector);
        riskConfigs.setProtocolFeePips(protocolFeePips);
    }

    function test_setProtocolFeePips(uint256 _protocolFeePips) public {
        uint256 protocolFeePips = bound(_protocolFeePips, 0, 62500);

        vm.expectEmit(false, false, false, true);
        emit IRiskConfigs.SetProtocolFeePips(protocolFeePips);
        riskConfigs.setProtocolFeePips(protocolFeePips);

        assertEq(riskConfigs.loadProtocolFeePips(), protocolFeePips);
    }

    function test_setMinMargin(uint256 _minMargin) public {
        vm.expectEmit(false, false, false, true);
        emit IRiskConfigs.SetMinMargin(_minMargin);
        riskConfigs.setMinMargin(_minMargin);
        assertEq(riskConfigs.loadMinMargin(), _minMargin);
    }

    function test_setDebtLimit(uint256 _debtLimit) public {
        vm.expectEmit(false, false, false, true);
        emit IRiskConfigs.SetDebtLimit(_debtLimit);
        riskConfigs.setDebtLimit(_debtLimit);
        assertEq(riskConfigs.loadDebtLimit(), _debtLimit);
    }
}
