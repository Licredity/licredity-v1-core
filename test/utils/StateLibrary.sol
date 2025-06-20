// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ILicredity} from "src/interfaces/ILicredity.sol";
import {FungibleState} from "src/types/FungibleState.sol";

library StateLibrary {
    uint256 public constant TOTAL_DEBT_SHARE_OFFSET = 14;
    uint256 public constant TOTAL_DEBT_BALANCE_OFFSET = 15;
    uint256 public constant POSITIONS_OFFSET = 21;
    uint256 public constant FUNGIBLES_STATE_OFFSET = 4;

    uint256 public constant BASE_AMOUNT_AVAILABLE_OFFSET = 18;
    uint256 public constant DEBT_AMOUNT_OUTSTANDING_OFFSET = 19;

    function getExchangeAmount(ILicredity manager)
        internal
        view
        returns (uint256 baseAmountAvailable, uint256 debtAmountOutstanding)
    {
        baseAmountAvailable = uint256(manager.extsload(bytes32(BASE_AMOUNT_AVAILABLE_OFFSET)));
        debtAmountOutstanding = uint256(manager.extsload(bytes32(DEBT_AMOUNT_OUTSTANDING_OFFSET)));
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
