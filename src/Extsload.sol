// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IExtsload} from "./interfaces/IExtsload.sol";

/// @title Extsload
/// @notice Abstract implementation of external storage load
abstract contract Extsload is IExtsload {
    /// @inheritdoc IExtsload
    function extsload(bytes32 slot) external view returns (bytes32) {
        assembly ("memory-safe") {
            mstore(0, sload(slot))
            return(0, 0x20)
        }
    }
}
