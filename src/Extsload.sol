// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IExtsload} from "./interfaces/IExtsload.sol";

/// @title Extsload
/// @notice Abstract implementation of external storage load
abstract contract Extsload is IExtsload {
    /// @inheritdoc IExtsload
    function extsload(bytes32 slot) external view returns (bytes32 value) {
        assembly ("memory-safe") {
            value := sload(slot)
        }
    }

    /// @inheritdoc IExtsload
    function extsload(bytes32 startSlot, uint256 nSlots) external view returns (bytes32[] memory) {
        assembly ("memory-safe") {
            let memptr := mload(0x40)
            let start := memptr
            let length := shl(5, nSlots) // nSlots * 32

            mstore(memptr, 0x20) // array offset
            mstore(add(memptr, 0x20), nSlots) // array length
            memptr := add(memptr, 0x40) // move memory pointer to start of array data

            let end := add(memptr, length)
            for {} 1 {} {
                mstore(memptr, sload(startSlot)) // load from storage to memory
                memptr := add(memptr, 0x20) // move to next memory slot
                startSlot := add(startSlot, 1) // move to next storage slot

                if iszero(lt(memptr, end)) { break }
            }

            return(start, sub(end, start))
        }
    }

    /// @inheritdoc IExtsload
    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory) {
        assembly ("memory-safe") {
            let memptr := mload(0x40)
            let start := memptr

            mstore(memptr, 0x20) // array offset
            mstore(add(memptr, 0x20), slots.length) // array length
            memptr := add(memptr, 0x40) // move memory pointer to start of array data

            let calldataptr := slots.offset
            let end := add(memptr, shl(5, slots.length)) // slots.length * 32
            for {} 1 {} {
                mstore(memptr, sload(calldataload(calldataptr))) // load from storage to memory
                memptr := add(memptr, 0x20) // move to next memory slot
                calldataptr := add(calldataptr, 0x20) // move to next calldata slot

                if iszero(lt(memptr, end)) { break }
            }
            return(start, sub(end, start))
        }
    }
}
