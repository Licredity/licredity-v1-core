// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@forge-std/interfaces/IERC20.sol";
import {LicredityConstants} from "../LicredityConstants.sol";

/// @title Fungible
/// @notice Represents a fungible
type Fungible is address;

using {equals as ==} for Fungible global;
using FungibleLibrary for Fungible global;

function equals(Fungible self, Fungible other) pure returns (bool) {
    return Fungible.unwrap(self) == Fungible.unwrap(other);
}

/// @title FungibleLibrary
/// @notice Library for managing fungibles
library FungibleLibrary {
    error ERC20TransferFailed();
    error ERC20TransferFromFailed();
    error NativeTransferFailed();
    error NativeTransferFromNotAllowed();

    /// @notice Transfers amount of fungible to recipient
    /// @param self The fungible to transfer
    /// @param recipient The recipient of the transfer
    /// @param amount The amount to transfer
    function transfer(Fungible self, address recipient, uint256 amount) internal {
        if (self.isNative()) {
            // native transfer
            assembly ("memory-safe") {
                let success := call(gas(), recipient, amount, 0, 0, 0, 0)

                // revert if the transfer failed
                if iszero(success) {
                    mstore(0x00, 0xf4b3b1bc) // 'NativeTransferFailed()'
                    revert(0x1c, 0x04)
                }
            }
        } else {
            // ERC20 transfer
            // modified from: https://github.com/Vectorized/solady/blob/main/src/utils/SafeTransferLib.sol
            assembly ("memory-safe") {
                let m := mload(0x40) // Cache the free memory pointer.
                mstore(0x14, recipient) // Store the `recipient` argument.
                mstore(0x34, amount) // Store the `amount` argument.
                mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
                // Perform the transfer, reverting upon failure.
                let success := call(gas(), self, 0, 0x10, 0x44, 0x00, 0x20)
                if iszero(and(eq(mload(0x00), 1), success)) {
                    if iszero(lt(or(iszero(extcodesize(self)), returndatasize()), success)) {
                        mstore(0x00, 0xf27f64e4) // `ERC20TransferFailed()`.
                        revert(0x1c, 0x04)
                    }
                }
                mstore(0x40, m) // Restore the free memory pointer.
            }
        }
    }

    /// @notice Transfers amount of fungible from sender to recipient
    /// @param self The Fungible to transfer
    /// @param sender The sender of the transfer
    /// @param recipient The recipient of the transfer
    /// @param amount The amount to transfer
    function transferFrom(Fungible self, address sender, address recipient, uint256 amount) internal {
        if (sender == address(this)) {
            self.transfer(recipient, amount);
        } else {
            // require(!self.isNative(), NativeTransferFromNotAllowed());
            if (self.isNative()) {
                assembly ("memory-safe") {
                    mstore(0x00, 0x59d4edfe) // 'NativeTransferFromNotAllowed()'
                    revert(0x1c, 0x04)
                }
            }

            // ERC20 transferFrom
            // modified from: https://github.com/Vectorized/solady/blob/main/src/utils/SafeTransferLib.sol
            assembly ("memory-safe") {
                let m := mload(0x40) // Cache the free memory pointer.
                mstore(0x60, amount) // Store the `amount` argument.
                mstore(0x40, recipient) // Store the `recipient` argument.
                mstore(0x2c, shl(96, sender)) // Store the `sender` argument.
                mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
                // Perform the transfer from, reverting upon failure.
                let success := call(gas(), self, 0, 0x1c, 0x64, 0x00, 0x20)
                if iszero(and(eq(mload(0x00), 1), success)) {
                    if iszero(lt(or(iszero(extcodesize(self)), returndatasize()), success)) {
                        mstore(0x00, 0xa512d51e) // `ERC20TransferFromFailed()`.
                        revert(0x1c, 0x04)
                    }
                }
                mstore(0x60, 0) // Restore the zero slot to zero.
                mstore(0x40, m) // Restore the free memory pointer.
            }
        }
    }

    /// @notice Gets the balance of a fungible for a owner
    /// @param self The fungible to get balance of
    /// @param owner The owner to get balance for
    /// @return _balance The balance of the fungible for the owner
    function balanceOf(Fungible self, address owner) internal view returns (uint256 _balance) {
        _balance = self.isNative() ? owner.balance : IERC20(Fungible.unwrap(self)).balanceOf(owner);
    }

    /// @notice Gets the decimals of a fungible
    /// @param self The fungible to get decimals of
    /// @return _decimals The number of decimals of the fungible
    function decimals(Fungible self) internal view returns (uint8 _decimals) {
        _decimals = self.isNative()
            ? LicredityConstants.CHAIN_NATIVE_FUNGIBLE_DECIMALS
            : IERC20(Fungible.unwrap(self)).decimals();
    }

    /// @notice Checks whether a fungible is the chain native fungible
    /// @param self The fungible to check
    /// @return _isNative True if the fungible is the chain native fungible, false otherwise
    function isNative(Fungible self) internal pure returns (bool _isNative) {
        _isNative = self == LicredityConstants.CHAIN_NATIVE_FUNGIBLE;
    }
}
