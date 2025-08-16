// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {Licredity} from "src/Licredity.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";

contract LicredityInitalizeTest is Deployers {
    error InvalidAddress();

    function test_initalize_BaseERC20LtBaseToken() public {
        deployPoolManager(address(this), hex"01");

        address baseToken = address(_newAsset(18));
        address deployAddress = address(uint160(uint160(baseToken) - 1));

        vm.expectRevert(InvalidAddress.selector);
        deployCodeTo(
            "Licredity.sol", abi.encode(baseToken, 1, poolManager, address(this), "Debt T", "DT"), deployAddress
        );
    }

    function test_initalize_ETH() public {
        deployETHLicredityWithUniswapV4();
        assertEq(licredity.decimals(), 18);

        bytes32 governorValue = vm.load(address(licredity), bytes32(uint256(6)));
        address governor;
        assembly ("memory-safe") {
            governor := governorValue
        }

        assertEq(governor, address(this));
    }
}
