// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {RiskConfigsMock} from "./mocks/RiskConfigsMock.sol";

contract RiskConfigsTest is Test {
    error NotGovernor();
    error NotPendingGovernor();
    error InvalidPositionMrrBps();

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

    function test_setPositionMrrBps_invalid(uint16 _positionMrrBps) public {
        uint16 positionMrrBps = uint16(bound(_positionMrrBps, 10001, type(uint16).max));
        vm.expectRevert(InvalidPositionMrrBps.selector);
        riskConfigs.setPositionMrrBps(positionMrrBps);
    }

    function test_setPositionMrrBps_valid(uint16 _positionMrrBps) public {
        uint16 positionMrrBps = uint16(bound(_positionMrrBps, 0, 10000));

        riskConfigs.setPositionMrrBps(positionMrrBps);

        assertEq(riskConfigs.loadPositionMrrBps(), positionMrrBps);
    }

    /// forge-config: default.fuzz.runs = 1000
    function test_setOracleAndPositionMrrBps(address[] calldata _oracle, uint16[] calldata _positionMrrBps) public {
        vm.assume(_oracle.length > 1);
        vm.assume(_positionMrrBps.length > 1);
        for (uint256 i = 0; i < _oracle.length; i++) {
            riskConfigs.setOracle(_oracle[i]);
        }
        assertEq(riskConfigs.loadOracle(), _oracle[_oracle.length - 1]);

        uint16 positionMrrBps;
        for (uint256 j = 0; j < _positionMrrBps.length; j++) {
            positionMrrBps = uint16(bound(_positionMrrBps[j], 0, 10000));
            riskConfigs.setPositionMrrBps(positionMrrBps);
        }

        assertEq(riskConfigs.loadPositionMrrBps(), positionMrrBps);
    }
}
