// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ILicredity} from "../interfaces/ILicredity.sol";
import {FungibleState} from "../types/FungibleState.sol";
import {NonFungible} from "../types/NonFungible.sol";

/// @title State Library
/// @notice A helper library to provide state getters that use extsload
library StateLibrary {
    uint256 public constant TOTAL_DEBT_SHARE_OFFSET = 15;
    uint256 public constant TOTAL_DEBT_AMOUNT_OFFSET = 16;
    uint256 public constant POSITIONS_OFFSET = 18;
    uint256 public constant FUNGIBLES_OFFSET = 2;
    uint256 public constant NON_FUNGIBLES_OFFSET = 3;
    uint256 public constant FUNGIBLES_STATE_OFFSET = 4;

    /// @notice Get the total debt share and amount
    /// @param manager The licredity contract
    /// @return totalDebtShare The total debt share
    /// @return totalDebtAmount The total debt amount
    function getTotalDebt(ILicredity manager) internal view returns (uint256 totalDebtShare, uint256 totalDebtAmount) {
        totalDebtShare = uint256(manager.extsload(bytes32(TOTAL_DEBT_SHARE_OFFSET)));
        totalDebtAmount = uint256(manager.extsload(bytes32(TOTAL_DEBT_AMOUNT_OFFSET)));
    }

    /// @notice Get the owner of a position
    /// @param manager The licredity contract
    /// @param positionId The position id
    /// @return owner The owner of the position
    function getPositionOwner(ILicredity manager, uint256 positionId) internal view returns (address owner) {
        bytes32 stateSlot = _getPositionSlot(positionId);
        bytes32 value = manager.extsload(stateSlot);
        assembly ("memory-safe") {
            owner := and(value, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @notice Get the fungibles of a position
    /// @param manager The licredity contract
    /// @param positionId The position id
    /// @return fungibles The fungibles of the position
    function getPositionFungibles(ILicredity manager, uint256 positionId)
        internal
        view
        returns (address[] memory fungibles)
    {
        bytes32 stateSlot = _getPositionSlot(positionId);
        bytes32 fungibleArraySlot = bytes32(uint256(stateSlot) + FUNGIBLES_OFFSET);
        bytes32 fungibleLength = manager.extsload(fungibleArraySlot);

        bytes32[] memory fungibleArray = _getArray(manager, fungibleArraySlot, uint256(fungibleLength));

        assembly ("memory-safe") {
            fungibles := fungibleArray
        }
    }

    /// @notice Get the non fungibles of a position
    /// @param manager The licredity contract
    /// @param positionId The position id
    /// @return nonFungibles The non fungibles of the position
    function getPositionNonFungibles(ILicredity manager, uint256 positionId)
        internal
        view
        returns (NonFungible[] memory nonFungibles)
    {
        bytes32 stateSlot = _getPositionSlot(positionId);
        bytes32 nonFungibleArraySlot = bytes32(uint256(stateSlot) + NON_FUNGIBLES_OFFSET);
        bytes32 nonFungibleLength = manager.extsload(nonFungibleArraySlot);

        bytes32[] memory nonFungibleArray = _getArray(manager, nonFungibleArraySlot, uint256(nonFungibleLength));

        assembly ("memory-safe") {
            nonFungibles := nonFungibleArray
        }
    }

    /// @notice Get the balance of a fungible in a position
    /// @param manager The licredity contract
    /// @param positionId The position id
    /// @param token The fungible address
    /// @return balance The balance of the fungible in the position
    function getPositionFungiblesBalance(ILicredity manager, uint256 positionId, address token)
        internal
        view
        returns (uint256)
    {
        bytes32 stateSlot = _getFungibleStateSlot(positionId, token);
        uint256 value = uint256(FungibleState.wrap(manager.extsload(stateSlot)).balance());
        return value;
    }

    function _getPositionSlot(uint256 positionId) internal pure returns (bytes32 slot) {
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            slot := keccak256(0x00, 0x40)
        }
    }

    function _getFungibleStateSlot(uint256 positionId, address token) internal pure returns (bytes32 slot) {
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            mstore(0x20, add(keccak256(0x00, 0x40), FUNGIBLES_STATE_OFFSET))
            mstore(0x00, token)
            slot := keccak256(0x00, 0x40)
        }
    }

    function _getArray(ILicredity manager, bytes32 arrayStartSlot, uint256 length)
        internal
        view
        returns (bytes32[] memory readArray)
    {
        assembly ("memory-safe") {
            let memptr := mload(0x40)

            mstore(memptr, 0xdbd035ff)
            mstore(add(memptr, 0x20), 0x20)
            mstore(add(memptr, 0x40), length)

            mstore(0x00, arrayStartSlot)
            let fungibleArrayStart := keccak256(0x00, 0x20)
            let soltsPtr := add(memptr, 0x60)

            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                mstore(add(soltsPtr, shl(5, i)), add(fungibleArrayStart, i))
            }

            let calldataLen := add(0x60, shl(5, length))
            let success := staticcall(gas(), manager, add(0x1c, memptr), calldataLen, memptr, calldataLen)

            if iszero(success) {
                mstore(0x00, 0x973d59b4) // "FailReadArray()"
                revert(0x1c, 0x04)
            }

            mstore(0x40, add(memptr, calldataLen))
            readArray := add(memptr, 0x20)
        }
    }
}
