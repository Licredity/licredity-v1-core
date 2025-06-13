// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Math} from "src/libraries/Math.sol";

library ShareMath {
    using Math for uint256;

    function toSharesUp(uint256 assets, uint256 totalAssets, uint256 totalShares) internal pure returns (uint256) {
        return assets.fullMulDivUp(totalShares, totalAssets);
    }
}
