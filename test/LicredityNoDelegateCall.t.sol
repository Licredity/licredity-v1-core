// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {ILicredity} from "src/interfaces/ILicredity.sol";

contract LicredityNoDelegateTest is Deployers {
    function setUp() public {
        deployETHLicredityWithUniswapV4();
    }

    function test_noDelegateCall_unlock() public {
        (bool success, bytes memory data) = address(licredity).delegatecall(abi.encodeCall(ILicredity.unlock, (hex"01")));
        assertFalse(success);
        assertEq(bytes4(data), ILicredity.DelegateCallNotAllowed.selector);
    }

    function test_noDelegateCall_increaseDebtShare() public {
        (bool success, bytes memory data) = address(licredity).delegatecall(abi.encodeCall(ILicredity.increaseDebtShare, (1, 1, address(0))));
        assertFalse(success);
        assertEq(bytes4(data), ILicredity.DelegateCallNotAllowed.selector);
    }

    function test_noDelegateCall_decreaseDebtShare() public {
        (bool success, bytes memory data) = address(licredity).delegatecall(abi.encodeCall(ILicredity.decreaseDebtShare, (1, 1, true)));
        assertFalse(success);
        assertEq(bytes4(data), ILicredity.DelegateCallNotAllowed.selector);
    }

    function test_noDelegateCall_seize() public {
        (bool success, bytes memory data) = address(licredity).delegatecall(abi.encodeCall(ILicredity.seizePosition, (1, address(0))));
        assertFalse(success);
        assertEq(bytes4(data), ILicredity.DelegateCallNotAllowed.selector);
    }
}
