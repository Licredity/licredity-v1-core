// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title NoDelegateCall
/// @notice Abstract contract that prevents delegate calls
abstract contract NoDelegateCall {
    address internal immutable self;

    modifier noDelegateCall() {
        _noDelegateCall();
        _;
    }

    function _noDelegateCall() internal view {
        address _self = self;
        assembly ("memory-safe") {
            // require(address(this) == self, DelegateCallNotAllowed());
            if iszero(eq(address(), _self)) {
                mstore(0x00, 0x0d89438e) // 'DelegateCallNotAllowed()'
                revert(0x1c, 0x04)
            }
        }
    }

    constructor() {
        self = address(this);
    }
}
