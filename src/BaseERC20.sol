// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@forge-std/interfaces/IERC20.sol";

/// @title BaseERC20
/// @notice Abstract implementation of ERC20 token
abstract contract BaseERC20 is IERC20 {
    struct OwnerData {
        uint256 balance;
        mapping(address => uint256) allowances;
    }

    uint256 private constant BALANCE_OFFSET = 0;
    uint256 private constant ALLOWANCES_OFFSET = 1;

    /// @inheritdoc IERC20
    string public name;
    /// @inheritdoc IERC20
    string public symbol;
    /// @inheritdoc IERC20
    uint8 public decimals;
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
        assembly ("memory-safe") {
            spender := and(spender, 0xffffffffffffffffffffffffffffffffffffffff)

            // calculate owner data slot
            mstore(0x00, caller())
            mstore(0x20, ownerData.slot)
            let ownerDataSlot := keccak256(0x00, 0x40)

            // set allowance
            mstore(0x00, spender)
            mstore(0x20, add(ownerDataSlot, ALLOWANCES_OFFSET))
            sstore(keccak256(0x00, 0x40), amount)

            // emit Approval(msg.sender, spender, amount);
            mstore(0x00, amount)
            log3(0x00, 0x20, 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925, caller(), spender)
        }

        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0));

        _transfer(msg.sender, to, amount);

        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(to != address(0));

        assembly ("memory-safe") {
            from := and(from, 0xffffffffffffffffffffffffffffffffffffffff)

            // check and update allowance if from is not the caller
            if iszero(eq(from, caller())) {
                // calculate owner data slot
                mstore(0x00, from)
                mstore(0x20, ownerData.slot)
                let ownerDataSlot := keccak256(0x00, 0x40)

                // get allowance
                mstore(0x00, caller())
                mstore(0x20, add(ownerDataSlot, ALLOWANCES_OFFSET))
                let allowanceSlot := keccak256(0x00, 0x40)
                let _allowance := sload(allowanceSlot)

                // require(_allowance >= amount, InsufficientAllowance());
                if lt(_allowance, amount) {
                    mstore(0x00, 0x13be252b) // 'InsufficientAllowance()'
                    revert(0x1c, 0x04)
                }

                // update allowance if not infinite
                if iszero(eq(_allowance, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) {
                    sstore(allowanceSlot, sub(_allowance, amount))
                }
            }
        }

        _transfer(from, to, amount);

        return true;
    }

    /// @inheritdoc IERC20
    function balanceOf(address owner) public view returns (uint256 _balance) {
        assembly ("memory-safe") {
            owner := and(owner, 0xffffffffffffffffffffffffffffffffffffffff)

            // _balance = ownerData[owner].balance;
            mstore(0x00, owner)
            mstore(0x20, ownerData.slot)
            _balance := sload(add(keccak256(0x00, 0x40), BALANCE_OFFSET))
        }
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view returns (uint256 _allowance) {
        assembly ("memory-safe") {
            owner := and(owner, 0xffffffffffffffffffffffffffffffffffffffff)
            spender := and(spender, 0xffffffffffffffffffffffffffffffffffffffff)

            // _allowance = ownerData[owner].allowances[spender];
            mstore(0x00, owner)
            mstore(0x20, ownerData.slot)
            let ownerDataSlot := keccak256(0x00, 0x40)

            mstore(0x00, spender)
            mstore(0x20, add(ownerDataSlot, ALLOWANCES_OFFSET))

            _allowance := sload(keccak256(0x00, 0x40))
        }
    }

    function _mint(address to, uint256 amount) internal {
        _transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        _transfer(from, address(0), amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) {
            // mint
            totalSupply += amount;
        } else {
            // transfer
            ownerData[from].balance -= amount;
        }

        assembly ("memory-safe") {
            from := and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            to := and(to, 0xffffffffffffffffffffffffffffffffffffffff)

            // burn
            if iszero(to) {
                // totalSupply -= amount; // underflow not possible
                sstore(totalSupply.slot, sub(sload(totalSupply.slot), amount))
            }

            // transfer
            if iszero(iszero(to)) {
                // ownerData[to].balance += amount; // overflow not possible
                mstore(0x00, to)
                mstore(0x20, ownerData.slot)
                let balanceSlot := add(keccak256(0x00, 0x40), BALANCE_OFFSET)

                sstore(balanceSlot, add(sload(balanceSlot), amount))
            }

            // emit Transfer(from, to, amount);
            mstore(0x00, amount)
            log3(0x00, 0x20, 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef, from, to)
        }
    }
}
