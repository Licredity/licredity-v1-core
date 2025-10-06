// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {ILicredity} from "../interfaces/ILicredity.sol";
import {FullMath} from "../libraries/FullMath.sol";
import {Fungible} from "../types/Fungible.sol";
import {FungibleState} from "../types/FungibleState.sol";
import {NonFungible} from "../types/NonFungible.sol";
import {PositionLibrary} from "../types/Position.sol";

/// @title StateLibrary
/// @notice Library for reading state from a Licredity market
library StateLibrary {
    using FullMath for uint256;

    uint256 internal constant POOL_KEY_OFFSET = 12;
    uint256 internal constant POSITIONS_OFFSET = 16;

    function getPoolKey(ILicredity market) internal view returns (PoolKey memory poolKey) {
        bytes32[] memory data = market.extsload(bytes32(POOL_KEY_OFFSET), 3);

        assembly ("memory-safe") {
            poolKey := mload(0x40)
            mstore(0x40, add(poolKey, 0xa0))

            mstore(poolKey, mload(add(data, 0x20)))
            let packed := mload(add(data, 0x40))
            mstore(add(poolKey, 0x20), and(packed, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(poolKey, 0x40), and(shr(160, packed), 0xffffff))
            mstore(add(poolKey, 0x60), shr(184, packed))
            mstore(add(poolKey, 0x80), mload(add(data, 0x60)))
        }
    }

    function getPositionOwner(ILicredity market, uint256 positionId) internal view returns (address owner) {
        uint256 ownerOffset = PositionLibrary.OWNER_OFFSET;

        bytes32 ownerSlot;
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            ownerSlot := add(keccak256(0x00, 0x40), ownerOffset)
        }

        owner = address(uint160(uint256(market.extsload(ownerSlot))));
    }

    function getPositionDebtShare(ILicredity market, uint256 positionId) internal view returns (uint256 debtShare) {
        uint256 debtShareOffset = PositionLibrary.DEBT_SHARE_OFFSET;

        bytes32 debtShareSlot;
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            debtShareSlot := add(keccak256(0x00, 0x40), debtShareOffset)
        }

        debtShare = uint256(market.extsload(debtShareSlot));
    }

    function getPositionDebtBalance(ILicredity market, uint256 positionId)
        internal
        view
        returns (uint256 debtBalance)
    {
        uint256 debtShare = getPositionDebtShare(market, positionId);

        debtBalance = debtShare.fullMulDiv(market.totalDebtBalance(), market.totalDebtShare());
    }

    function getPositionFungibleCount(ILicredity market, uint256 positionId) internal view returns (uint256 count) {
        uint256 fungiblesOffset = PositionLibrary.FUNGIBLES_OFFSET;
        bytes32 fungiblesSlot;

        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            fungiblesSlot := add(keccak256(0x00, 0x40), fungiblesOffset)
        }

        count = uint256(market.extsload(fungiblesSlot));
    }

    function getPositionFungibleBalance(ILicredity market, uint256 positionId, Fungible fungible)
        internal
        view
        returns (uint256 balance)
    {
        uint256 fungibleStatesOffset = PositionLibrary.FUNGIBLE_STATES_OFFSET;
        bytes32 fungibleStateSlot;

        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            mstore(0x20, add(keccak256(0x00, 0x40), fungibleStatesOffset))
            mstore(0x00, fungible)
            fungibleStateSlot := keccak256(0x00, 0x40)
        }

        balance = FungibleState.wrap(market.extsload(fungibleStateSlot)).balance();
    }

    function getPositionNonFungibleCount(ILicredity market, uint256 positionId) internal view returns (uint256 count) {
        uint256 nonFungiblesOffset = PositionLibrary.NON_FUNGIBLES_OFFSET;
        bytes32 nonFungiblesSlot;

        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            nonFungiblesSlot := add(keccak256(0x00, 0x40), nonFungiblesOffset)
        }

        count = uint256(market.extsload(nonFungiblesSlot));
    }

    function getPositionNonFungibleByIndex(ILicredity market, uint256 positionId, uint256 index)
        internal
        view
        returns (NonFungible nonFungible)
    {
        uint256 nonFungiblesOffset = PositionLibrary.NON_FUNGIBLES_OFFSET;
        bytes32 nonFungibleSlot;

        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            mstore(0x00, add(keccak256(0x00, 0x40), nonFungiblesOffset))
            nonFungibleSlot := add(keccak256(0x00, 0x20), mul(index, 0x20))
        }

        nonFungible = NonFungible.wrap(market.extsload(nonFungibleSlot));
    }
}
