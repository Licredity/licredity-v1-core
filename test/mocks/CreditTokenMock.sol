// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.30;

import {CreditToken} from "src/CreditToken.sol";

contract CreditTokenMock is CreditToken {
    constructor(string memory name, string memory symbol, uint8 decimals) CreditToken(name, symbol, decimals) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
