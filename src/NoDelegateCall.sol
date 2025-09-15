// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title NoDelegateCall
/// @notice Abstract contract that prevents delegate calls
abstract contract NoDelegateCall {
    address private immutable _self;

    modifier noDelegateCall() {
        _noDelegateCall();
        _;
    }

    function _noDelegateCall() internal view {
        address self = _self;

        // require(address(this) == _self, DelegateCallNotAllowed());
        assembly ("memory-safe") {
            if iszero(eq(address(), self)) {
                mstore(0x00, 0x0d89438e) // 'DelegateCallNotAllowed()'
                revert(0x1c, 0x04)
            }
        }
    }

    constructor() {
        _self = address(this);
    }
}
