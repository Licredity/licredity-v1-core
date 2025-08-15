// SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.30;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/console.sol";
import {Licredity} from "../src/Licredity.sol";

contract DeployScript is Script {
    function run() external {
        // Load deployment settings
        string memory chain = vm.envString("CHAIN");
        string memory baseTokenTicker = vm.envString("BASE_TOKEN");
        console.log("Deploying to chain ", chain, " for ", baseTokenTicker);

        // Load deployment parameters
        address baseToken = vm.envAddress(string.concat(chain, "_", baseTokenTicker));
        address poolManager = vm.envAddress(string.concat(chain, "_POOL_MANAGER"));
        uint256 interestSensitivity = vm.envUint(string.concat(chain, "_INTEREST_SENSITIVITY"));
        address governor = vm.envAddress(string.concat(chain, "_GOVERNOR"));
        bytes32 salt = vm.envBytes32(string.concat(chain, "_", baseTokenTicker, "_CREATE2_SALT"));

        string memory name = string.concat(vm.envString("DEBT_TOKEN_NAME_PREFIX"), " ", baseTokenTicker);
        string memory symbol = string.concat(vm.envString("DEBT_TOKEN_SYMBOL_PREFIX"), baseTokenTicker);
        console.log("Base Token Address:", baseToken);
        console.log("Pool Manager Address:", poolManager);
        console.log("Interest Sensitivity:", interestSensitivity);
        console.log("Governor Address:", governor);
        console.log("Token Name:", name);
        console.log("Token Symbol:", symbol);

        // Validate deployment parameters
        require(poolManager != address(0), "PoolManager address cannot be zero");
        require(governor != address(0), "Governor address cannot be zero");

        // Deploy contracts
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        console.log("Deploying Licredity...");
        Licredity licredity =
            new Licredity{salt: salt}(baseToken, interestSensitivity, poolManager, governor, name, symbol);
        vm.stopBroadcast();
        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("Licredity deployed at:", address(licredity));
    }
}
