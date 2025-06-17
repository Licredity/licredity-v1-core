// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@forge-std/interfaces/IERC20.sol";

/// @title DebtToken
/// @notice Abstract implementation of debt token
abstract contract DebtToken is IERC20 {
    struct OwnerData {
        uint256 balance;
        mapping(address => uint256) allowances;
    }

    uint256 private constant BALANCE_OFFSET = 0;
    uint256 private constant ALLOWANCES_OFFSET = 1;
    uint256 private constant ADDRESS_MASK = 0x00ffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;
    uint256 private constant TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @inheritdoc IERC20
    string public name;
    /// @inheritdoc IERC20
    string public symbol;
    /// @inheritdoc IERC20
    uint8 public immutable decimals;
    /// @inheritdoc IERC20
    uint256 public totalSupply = 0;

    mapping(address => OwnerData) internal ownerData;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 amount) public returns (bool) {
        assembly ("memory-safe") {
            spender := and(spender, ADDRESS_MASK)

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
            log3(0x00, 0x20, APPROVAL_EVENT_SIGNATURE, caller(), spender)
        }

        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);

        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        assembly ("memory-safe") {
            from := and(from, ADDRESS_MASK)

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

                // revert on insufficient allowance
                if lt(_allowance, amount) {
                    mstore(0x00, 0x13be252b) // 'InsufficientAllowance()'
                    revert(0x1c, 0x04)
                }

                // update allowance if not infinite
                if iszero(eq(_allowance, sub(0, 1))) { mstore(allowanceSlot, sub(_allowance, amount)) }
            }
        }

        _transfer(from, to, amount);

        return true;
    }

    /// @inheritdoc IERC20
    function balanceOf(address owner) public view returns (uint256 _balance) {
        assembly ("memory-safe") {
            // get balance
            mstore(0x00, and(owner, ADDRESS_MASK))
            mstore(0x20, ownerData.slot)
            _balance := sload(add(keccak256(0x00, 0x40), BALANCE_OFFSET))
        }
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view returns (uint256 _allowance) {
        assembly ("memory-safe") {
            // calculate owner data slot
            mstore(0x00, and(owner, ADDRESS_MASK))
            mstore(0x20, ownerData.slot)
            let ownerDataSlot := keccak256(0x00, 0x40)

            // get allowance
            mstore(0x00, and(spender, ADDRESS_MASK))
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
            totalSupply += amount; // overflow desired
        } else {
            // transfer
            ownerData[from].balance -= amount; // underflow desired
        }

        assembly ("memory-safe") {
            to := and(to, ADDRESS_MASK)

            // burn
            if iszero(to) {
                // underflow not possible
                mstore(totalSupply.slot, sub(sload(totalSupply.slot), amount))
            }

            // transfer
            if iszero(iszero(to)) {
                // calculate owner data slot
                mstore(0x00, to)
                mstore(0x20, ownerData.slot)
                let balanceSlot := add(keccak256(0x00, 0x40), BALANCE_OFFSET)

                // overflow not possible
                mstore(balanceSlot, add(sload(balanceSlot), amount))
            }

            // emit Transfer(from, to, amount);
            mstore(0x00, amount)
            log3(0x00, 0x20, TRANSFER_EVENT_SIGNATURE, and(from, ADDRESS_MASK), to)
        }
    }
}
