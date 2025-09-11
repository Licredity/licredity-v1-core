// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ILicredity} from "src/interfaces/ILicredity.sol";
import {Deployers} from "./utils/Deployer.sol";
import {StateLibrary} from "./utils/StateLibrary.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";

contract LicredityInitalizeTest is Deployers {
    function test_initalize_BaseERC20LtBaseToken() public {
        deployPoolManager(address(this), hex"01");

        address baseToken = address(_newAsset(18));
        address deployAddress = address(uint160(uint160(baseToken) - 1));

        vm.expectRevert(ILicredity.LicredityAddressNotValid.selector);
        deployCodeTo(
            "Licredity.sol", abi.encode(baseToken, 1, poolManager, address(this), "Debt T", "DT"), deployAddress
        );
    }

    function test_initalize_poolManager() public {
        deployETHLicredityWithUniswapV4();

        bytes32 poolManagerValue = vm.load(address(licredity), bytes32(StateLibrary.POOL_MANAGER_OFFSET));
        address poolManagerAddress;

        assembly ("memory-safe") {
            poolManagerAddress := poolManagerValue
        }

        assertEq(poolManagerAddress, address(poolManager));
    }

    function test_initalize_poolId() public {
        deployETHLicredityWithUniswapV4();

        bytes32 poolId = StateLibrary.getPoolId(licredity);
        assertEq(poolId, hex"86f15e7ec533935883c86e206d779a79b78e0e9e9d2166b62ad60a99a0c5e276");
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
