// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {RiskConfigsMock} from "./mocks/RiskConfigsMock.sol";

contract RiskConfigsTest is Test {
    error NotGovernor();
    error NotPendingGovernor();
    error InvalidMinMarginRequirementBps();

    RiskConfigsMock public riskConfigs;

    function setUp() public {
        riskConfigs = new RiskConfigsMock(address(this));
    }

    function test_appointGovernor_notOwner() public {
        vm.startPrank(address(1));
        vm.expectRevert(NotGovernor.selector);
        riskConfigs.appointGovernor(address(1));
        vm.stopPrank();
    }

    function test_appointGovernor_appointGovernor(address pendingGovernor) public {
        riskConfigs.appointGovernor(pendingGovernor);

        assertEq(riskConfigs.loadPendingGovernor(), pendingGovernor);
    }

    function test_confirmGovernor(address _governorAddr) public {
        riskConfigs.appointGovernor(_governorAddr);

        vm.startPrank(_governorAddr);
        riskConfigs.confirmGovernor();
        vm.stopPrank();

        assertEq(riskConfigs.loadGovernor(), _governorAddr);
        assertEq(riskConfigs.loadPendingGovernor(), address(0));
    }

    function test_confirmGovernor_notPending(address pendingAddr, address other) public {
        vm.assume(pendingAddr != other);

        riskConfigs.appointGovernor(pendingAddr);

        vm.startPrank(other);
        vm.expectRevert(NotPendingGovernor.selector);
        riskConfigs.confirmGovernor();
        vm.stopPrank();
    }

    function test_setOracle(address _oracle) public {
        riskConfigs.setOracle(_oracle);

        assertEq(riskConfigs.loadOracle(), _oracle);
    }

    function test_setMinMarginRequirementBps_invalid(uint16 _minMarginRequirementBps) public {
        uint16 minMarginRequirementBps = uint16(bound(_minMarginRequirementBps, 10001, type(uint16).max));
        vm.expectRevert(InvalidMinMarginRequirementBps.selector);
        riskConfigs.setMinMarginRequirementBps(minMarginRequirementBps);
    }

    function test_setMinMarginRequirementBps_valid(uint16 _minMarginRequirementBps) public {
        uint16 minMarginRequirementBps = uint16(bound(_minMarginRequirementBps, 0, 10000));

        riskConfigs.setMinMarginRequirementBps(minMarginRequirementBps);

        assertEq(riskConfigs.loadMinMarginRequirementBps(), minMarginRequirementBps);
    }

    /// forge-config: default.fuzz.runs = 1000
    function test_setOracleAndMinMarginRequirementBps(
        address[] calldata _oracle,
        uint16[] calldata _minMarginRequirementBps
    ) public {
        vm.assume(_oracle.length > 1);
        vm.assume(_minMarginRequirementBps.length > 1);
        for (uint256 i = 0; i < _oracle.length; i++) {
            riskConfigs.setOracle(_oracle[i]);
        }
        assertEq(riskConfigs.loadOracle(), _oracle[_oracle.length - 1]);

        uint16 minMarginRequirementBps;
        for (uint256 j = 0; j < _minMarginRequirementBps.length; j++) {
            minMarginRequirementBps = uint16(bound(_minMarginRequirementBps[j], 0, 10000));
            riskConfigs.setMinMarginRequirementBps(minMarginRequirementBps);
        }

        assertEq(riskConfigs.loadMinMarginRequirementBps(), minMarginRequirementBps);
    }
}
