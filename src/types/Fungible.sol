// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@forge-std/interfaces/IERC20.sol";
import {ChainInfo} from "../libraries/ChainInfo.sol";

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
            assembly ("memory-safe") {
                let fmp := mload(0x40)
                mstore(fmp, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // 'transfer(address,uint256)'
                mstore(add(fmp, 0x04), and(recipient, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(fmp, 0x24), amount)

                // success if the call returns true or no data
                let success :=
                    and(
                        or(and(eq(mload(0), true), gt(returndatasize(), 31)), iszero(returndatasize())),
                        call(gas(), self, 0, fmp, 68, 0, 32)
                    )

                mstore(fmp, 0)
                mstore(add(fmp, 0x04), 0)
                mstore(add(fmp, 0x24), 0)

                // revert if the transfer failed
                if iszero(success) {
                    mstore(0x00, 0xf27f64e4) // 'ERC20TransferFailed()'
                    revert(0x1c, 0x04)
                }
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
        _decimals = self.isNative() ? ChainInfo.NATIVE_DECIMALS : IERC20(Fungible.unwrap(self)).decimals();
    }

    /// @notice Checks whether a fungible is the native fungible
    /// @param self The fungible to check
    /// @return _isNative True if the fungible is the native fungible, false otherwise
    function isNative(Fungible self) internal pure returns (bool _isNative) {
        _isNative = Fungible.unwrap(self) == ChainInfo.NATIVE;
    }
}
