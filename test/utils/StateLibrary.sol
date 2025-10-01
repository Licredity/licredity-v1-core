// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ILicredity} from "src/interfaces/ILicredity.sol";
import {FungibleState} from "src/types/FungibleState.sol";

library StateLibrary {
    uint256 public constant CURRENCY0_OFFSET = 12;
    uint256 public constant TOTAL_DEBT_SHARE_OFFSET = 21;
    uint256 public constant TOTAL_DEBT_BALANCE_OFFSET = 22;
    uint256 public constant POSITIONS_OFFSET = 23;
    uint256 public constant FUNGIBLES_STATE_OFFSET = 4;

    uint24 private constant FEE = 100;
    int24 private constant TICK_SPACING = 1;

    function getPoolId(ILicredity manager) internal view returns (bytes32 poolId) {
        bytes32 currency0 = manager.extsload(bytes32(CURRENCY0_OFFSET));
        assembly ("memory-safe") {
            let memptr := mload(0x40)
            mstore(memptr, currency0) // currency0
            mstore(add(memptr, 0x20), manager) // currency1
            mstore(add(memptr, 0x40), FEE) // fee
            mstore(add(memptr, 0x60), TICK_SPACING) // tickSpacing
            mstore(add(memptr, 0x80), manager) // hooks
            poolId := keccak256(memptr, 0xa0)

            mstore(0x40, add(memptr, 0xa0)) // update free memory pointer
        }
    }

    function getTotalDebt(ILicredity manager) internal view returns (uint256 totalShares, uint256 totalAssets) {
        totalShares = uint256(manager.extsload(bytes32(TOTAL_DEBT_SHARE_OFFSET)));
        totalAssets = uint256(manager.extsload(bytes32(TOTAL_DEBT_BALANCE_OFFSET)));
    }

    function getPositionFungiblesBalance(ILicredity manager, uint256 positionId, address token)
        internal
        view
        returns (uint256)
    {
        bytes32 stateSlot = _getFungibleStateSlot(positionId, token);
        uint256 value = uint256(FungibleState.wrap(manager.extsload(stateSlot)).balance());
        return value;
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
}
