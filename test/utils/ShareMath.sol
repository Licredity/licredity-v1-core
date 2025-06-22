// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {FullMath} from "src/libraries/FullMath.sol";

library ShareMath {
    using FullMath for uint256;

    function toShares(uint128 assets, uint256 totalAssets, uint256 totalShares) internal pure returns (uint256) {
        return uint256(assets).fullMulDiv(totalShares, totalAssets);
    }
}
