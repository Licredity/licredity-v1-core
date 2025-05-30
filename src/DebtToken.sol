// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@forge-std/interfaces/IERC20.sol";

/// @title DebtToken
/// @notice Abstract implementation of the IERC20 interface for debt tokens
abstract contract DebtToken is IERC20 {
    struct OwnerData {
        uint256 balance;
        mapping(address => uint256) allowances;
    }

    /// @inheritdoc IERC20
    string public name;
    /// @inheritdoc IERC20
    string public symbol;
    /// @inheritdoc IERC20
    uint8 public immutable decimals;
    /// @inheritdoc IERC20
    uint256 public totalSupply;

    mapping(address => OwnerData) internal ownerData;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) public returns (bool) {
        ownerData[msg.sender].allowances[spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = ownerData[from].allowances[msg.sender];

        // do not reduce if given unlimited allowance
        if (currentAllowance != type(uint256).max) {
            ownerData[from].allowances[msg.sender] = currentAllowance - amount; // underflow desired
        }
        _transfer(from, to, amount);

        return true;
    }

    /// @inheritdoc IERC20
    function balanceOf(address owner) public view returns (uint256) {
        return ownerData[owner].balance;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view returns (uint256) {
        return ownerData[owner].allowances[spender];
    }

    function _mint(address to, uint256 amount) internal {
        _transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _transfer(from, address(0), amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) {
            totalSupply += amount; // overflow desired
        } else {
            ownerData[from].balance -= amount; // underflow desired
        }

        // over/underflow not possible
        unchecked {
            if (to == address(0)) {
                totalSupply -= amount;
            } else {
                ownerData[to].balance += amount;
            }
        }

        emit Transfer(from, to, amount);
    }
}
