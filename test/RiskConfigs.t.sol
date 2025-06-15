// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {RiskConfigsMock} from "./mocks/RiskConfigsMock.sol";

contract RiskConfigsTest is Test {
    error NotGovernor();
    error NotNextGovernor();
    error InvalidProtocolFeePips();
    error InvalidPositionMrrPips();

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

    function test_appointGovernor(address[] calldata nextGovernors) public {
        vm.assume(nextGovernors.length > 1);
        for (uint256 i = 0; i < nextGovernors.length; i++) {
            riskConfigs.appointGovernor(nextGovernors[i]);
        }

        assertEq(riskConfigs.loadNextGovernor(), nextGovernors[nextGovernors.length - 1]);
    }

    function test_confirmGovernor(address _governorAddr) public {
        riskConfigs.appointGovernor(_governorAddr);

        vm.startPrank(_governorAddr);
        riskConfigs.confirmGovernor();
        vm.stopPrank();

        assertEq(riskConfigs.loadGovernor(), _governorAddr);
        assertEq(riskConfigs.loadNextGovernor(), address(0));
    }

    function test_confirmGovernor_notPending(address pendingAddr, address other) public {
        vm.assume(pendingAddr != other);

        riskConfigs.appointGovernor(pendingAddr);

        vm.startPrank(other);
        vm.expectRevert(NotNextGovernor.selector);
        riskConfigs.confirmGovernor();
        vm.stopPrank();
    }

    function test_setOracle(address[] calldata oracles) public {
        vm.assume(oracles.length > 1);
        for (uint256 i = 0; i < oracles.length; i++) {
            riskConfigs.setOracle(oracles[i]);
        }

        assertEq(riskConfigs.loadOracle(), oracles[oracles.length - 1]);
    }

    function test_setProtocolFeeRecipient(address[] calldata protocolFeeRecipients) public {
        vm.assume(protocolFeeRecipients.length > 1);
        for (uint256 i = 0; i < protocolFeeRecipients.length; i++) {
            riskConfigs.setProtocolFeeRecipient(protocolFeeRecipients[i]);
        }

        assertEq(riskConfigs.loadProtocolFeeRecipient(), protocolFeeRecipients[protocolFeeRecipients.length - 1]);
    }

    function test_setProtocolFeePips_invalid(uint24 _protocolFeePips) public {
        uint24 protocolFeePips = uint24(bound(_protocolFeePips, 1_000_001, type(uint24).max));
        vm.expectRevert(InvalidProtocolFeePips.selector);
        riskConfigs.setProtocolFeePips(protocolFeePips);
    }

    function test_setPositionMrrPips_invalid(uint24 _positionMrrPips) public {
        uint24 positionMrrPips = uint24(bound(_positionMrrPips, 1_000_001, type(uint24).max));
        vm.expectRevert(InvalidPositionMrrPips.selector);
        riskConfigs.setPositionMrrPips(positionMrrPips);
    }

    // function test_setProtocolFeePips() public {
    //     // uint24 _protocolFeePips = 12947;
    //     riskConfigs.setPositionMrrPips(1_000_000);
    //     riskConfigs.setProtocolFeePips(129472);

    //     assertEq(riskConfigs.loadProtocolFeePips(), 129472);
    // }
    function test_setProtocolFeeWithPips(
        address[] calldata protocolFeeRecipients,
        uint24[] calldata protocolFeePips,
        uint24[] calldata positionMrrPips
    ) public {
        vm.assume(protocolFeeRecipients.length > 1);
        vm.assume(protocolFeePips.length > 1);
        vm.assume(positionMrrPips.length > 1);

        for (uint256 i = 0; i < protocolFeeRecipients.length; i++) {
            riskConfigs.setProtocolFeeRecipient(protocolFeeRecipients[i]);
            assertEq(riskConfigs.loadProtocolFeeRecipient(), protocolFeeRecipients[i]);
        }

        for (uint256 i = 0; i < protocolFeePips.length; i++) {
            if (protocolFeePips[i] < 1_000_001) {
                riskConfigs.setProtocolFeePips(protocolFeePips[i]);
                assertEq(riskConfigs.loadProtocolFeePips(), protocolFeePips[i]);
            }
        }

        for (uint256 i = 0; i < positionMrrPips.length; i++) {
            if (positionMrrPips[i] < 1_000_001) {
                riskConfigs.setPositionMrrPips(positionMrrPips[i]);
                assertEq(riskConfigs.loadPositionMrrPips(), positionMrrPips[i]);
            }
        }
    }
}
