// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {ILicredity} from "src/interfaces/ILicredity.sol";

contract LicredityNoDelegateTest is Deployers {
    error DelegateCallNotAllowed();

    function setUp() public {
        deployETHLicredityWithUniswapV4();
    }

    function test_noDelegateCall_unlock() public {
        vm.expectRevert(DelegateCallNotAllowed.selector);
        address(licredity).delegatecall(abi.encodeCall(ILicredity.unlock, (hex"01")));
    }

    function test_noDelegateCall_increaseDebtShare() public {
        vm.expectRevert(DelegateCallNotAllowed.selector);
        address(licredity).delegatecall(abi.encodeCall(ILicredity.increaseDebtShare, (1, 1, address(0))));
    }

    function test_noDelegateCall_decreaseDebtShare() public {
        vm.expectRevert(DelegateCallNotAllowed.selector);
        address(licredity).delegatecall(abi.encodeCall(ILicredity.decreaseDebtShare, (1, 1, true)));
    }

    function test_noDelegateCall_seize() public {
        vm.expectRevert(DelegateCallNotAllowed.selector);
        address(licredity).delegatecall(abi.encodeCall(ILicredity.seize, (1, address(0))));
    }
}
