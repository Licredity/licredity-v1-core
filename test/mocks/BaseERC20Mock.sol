// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.30;

import {BaseERC20} from "src/BaseERC20.sol";

contract BaseERC20Mock is BaseERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals) BaseERC20(name, symbol, decimals) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
