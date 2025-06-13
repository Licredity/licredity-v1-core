// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC721} from "@forge-std/interfaces/IERC721.sol";

/// @dev An 'address' token address and a 'uint96' token ID, packed into a single 'bytes32' value
type NonFungible is bytes32;

using {equals as ==} for NonFungible global;
using NonFungibleLibrary for NonFungible global;

function equals(NonFungible x, NonFungible y) pure returns (bool) {
    return NonFungible.unwrap(x) == NonFungible.unwrap(y);
}

/// @title NonFungibleLibrary
/// @notice Library for managing non-fungibles
library NonFungibleLibrary {
    /// @notice Transfer non-fungible to recipient
    /// @param self The non-fungible to transfer
    /// @param recipient The address to transfer the non-fungible to
    function transfer(NonFungible self, address recipient) internal {
        address tokenAddress;
        uint256 tokenId;
        assembly ("memory-safe") {
            tokenAddress := shr(96, self)
            tokenId := and(self, 0xffffffffffffffffffffffff)
        }

        IERC721(tokenAddress).safeTransferFrom(address(this), recipient, tokenId);
    }

    /// @notice Gets the token of a non-fungible
    /// @param self The non-fungible to get the token of
    /// @return address The address of the token
    function token(NonFungible self) internal pure returns (address) {
        address tokenAddress;
        assembly ("memory-safe") {
            tokenAddress := shr(96, self)
        }
        return tokenAddress;
    }

    /// @notice Gets the ID of a non-fungible
    /// @param self The non-fungible to get the ID of
    /// @return uint256 The ID of the non-fungible
    function id(NonFungible self) internal pure returns (uint256) {
        uint256 tokenId;
        assembly ("memory-safe") {
            tokenId := and(self, 0xffffffffffffffffffffffff)
        }
        return tokenId;
    }

    /// @notice Gets the owner of a non-fungible
    /// @param self The non-fungible to get the owner of
    /// @return address The owner of the non-fungible
    function owner(NonFungible self) internal view returns (address) {
        address tokenAddress;
        uint256 tokenId;
        assembly ("memory-safe") {
            tokenAddress := shr(96, self)
            tokenId := and(self, 0xffffffffffffffffffffffff)
        }

        return IERC721(tokenAddress).ownerOf(tokenId);
    }
}
