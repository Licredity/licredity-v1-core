// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";

contract HelperCVL {    

    function initialize(PoolKey memory key, uint160 sqrtPriceX96) external returns (int24 tick) { }

    function assertOnFailure(bool success) external pure {
        require(success);
    }
}