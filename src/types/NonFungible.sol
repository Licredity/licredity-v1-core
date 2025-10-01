// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@forge-std/interfaces/IERC721.sol";

/// @title NonFungible
/// @notice Represents a non-fungible
/// @dev 160 bits token address | 32 bits empty | 64 bits token ID
type NonFungible is bytes32;

using {equals as ==} for NonFungible global;
using NonFungibleLibrary for NonFungible global;

function equals(NonFungible self, NonFungible other) pure returns (bool _equals) {
    bytes32 mask = NonFungibleLibrary.NON_FUNGIBLE_MASK;

    assembly ("memory-safe") {
        _equals := iszero(and(xor(self, other), mask))
    }
}

/// @title NonFungibleLibrary
/// @notice Library for managing non-fungibles
library NonFungibleLibrary {
    bytes32 internal constant NON_FUNGIBLE_MASK = 0xffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffffff;

    /// @notice Transfers a non-fungible to recipient
    /// @param self The non-fungible to transfer
    /// @param recipient The recipient of the transfer
    function transfer(NonFungible self, address recipient) internal {
        self.transferFrom(address(this), recipient);
    }

    /// @notice Transfers a non-fungible from sender to recipient
    /// @param self The non-fungible to transfer
    /// @param sender The sender of the transfer
    /// @param recipient The recipient of the transfer
    function transferFrom(NonFungible self, address sender, address recipient) internal {
        IERC721(self.tokenAddress()).safeTransferFrom(sender, recipient, self.tokenId());
    }

    /// @notice Gets the owner of a non-fungible
    /// @param self The non-fungible to get the owner of
    /// @return _owner The owner of the non-fungible
    function owner(NonFungible self) internal view returns (address _owner) {
        _owner = IERC721(self.tokenAddress()).ownerOf(self.tokenId());
    }

    /// @notice Gets the token address of a non-fungible
    /// @param self The non-fungible to get the token address of
    /// @return _tokenAddress The token address of the non-fungible
    function tokenAddress(NonFungible self) internal pure returns (address _tokenAddress) {
        assembly ("memory-safe") {
            _tokenAddress := shr(96, self)
        }
    }

    /// @notice Gets the token ID of a non-fungible
    /// @param self The non-fungible to get the token ID of
    /// @return _tokenId The token ID of the non-fungible
    function tokenId(NonFungible self) internal pure returns (uint256 _tokenId) {
        assembly ("memory-safe") {
            _tokenId := and(self, 0xffffffffffffffff)
        }
    }

    /// @notice Constructs a non-fungible from token address and token ID
    /// @param _tokenAddress The token address of the non-fungible
    /// @param _tokenId The token ID of the non-fungible
    /// @return nonFungible The constructed non-fungible
    function from(address _tokenAddress, uint256 _tokenId) internal pure returns (NonFungible nonFungible) {
        assembly ("memory-safe") {
            if gt(_tokenId, 0xffffffffffffffff) {
                mstore(0x00, 0x1493c569) // 'TokenIdOutOfBound()'
                revert(0x1c, 0x04)
            }

            nonFungible := or(shl(96, _tokenAddress), _tokenId)
        }
    }
}
