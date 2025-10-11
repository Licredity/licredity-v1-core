// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILicredity} from "../interfaces/ILicredity.sol";
import {FullMath} from "../libraries/FullMath.sol";
import {Fungible} from "../types/Fungible.sol";
import {FungibleState} from "../types/FungibleState.sol";
import {NonFungible} from "../types/NonFungible.sol";
import {PositionLibrary} from "../types/Position.sol";

/// @title PositionStateView
/// @notice Library for reading position states in a Licredity market
library PositionStateView {
    using FullMath for uint256;

    uint256 internal constant POSITIONS_OFFSET = 15;

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

    function getPositionFungibles(ILicredity market, uint256 positionId)
        internal
        view
        returns (Fungible[] memory fungibles)
    {
        uint256 fungiblesOffset = PositionLibrary.FUNGIBLES_OFFSET;

        bytes32 fungiblesSlot;
        bytes32 fungiblesDataSlot;
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            fungiblesSlot := add(keccak256(0x00, 0x40), fungiblesOffset)
            mstore(0x00, fungiblesSlot)
            fungiblesDataSlot := keccak256(0x00, 0x20)
        }

        uint256 count = uint256(market.extsload(fungiblesSlot));
        bytes32[] memory fungiblesData = market.extsload(fungiblesDataSlot, count);

        fungibles = new Fungible[](count);
        for (uint256 i = 0; i < count; i++) {
            fungibles[i] = Fungible.wrap(address(uint160(uint256(fungiblesData[i]))));
        }
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

    function getPositionNonFungibles(ILicredity market, uint256 positionId)
        internal
        view
        returns (NonFungible[] memory nonFungibles)
    {
        uint256 nonFungiblesOffset = PositionLibrary.NON_FUNGIBLES_OFFSET;

        bytes32 nonFungiblesSlot;
        bytes32 nonFungiblesDataSlot;
        assembly ("memory-safe") {
            mstore(0x00, positionId)
            mstore(0x20, POSITIONS_OFFSET)
            nonFungiblesSlot := add(keccak256(0x00, 0x40), nonFungiblesOffset)
            mstore(0x00, nonFungiblesSlot)
            nonFungiblesDataSlot := keccak256(0x00, 0x20)
        }

        uint256 count = uint256(market.extsload(nonFungiblesSlot));
        bytes32[] memory nonFungiblesData = market.extsload(nonFungiblesDataSlot, count);

        nonFungibles = new NonFungible[](count);
        for (uint256 i = 0; i < count; i++) {
            nonFungibles[i] = NonFungible.wrap(nonFungiblesData[i]);
        }
    }
}
