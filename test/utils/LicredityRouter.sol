// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IUnlockCallback} from "src/interfaces/IUnlockCallback.sol";
import {ILicredity} from "src/interfaces/ILicredity.sol";

enum Actions {
    ADD_DEBT
}

contract LicredityRouter is IUnlockCallback {
    ILicredity public licredity;

    mapping(uint256 => address) public owners;

    constructor(ILicredity _licredity) {
        licredity = _licredity;
    }

    function open() external returns (uint256 positionId) {
        positionId = licredity.open();
    }

    function executeActions(Actions[] memory actions, bytes[] memory params) external payable {
        licredity.unlock(abi.encode(actions, params));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        (Actions[] memory actions, bytes[] memory params) = abi.decode(data, (Actions[], bytes[]));
        for (uint256 i = 0; i < actions.length; i++) {
            Actions action = actions[i];
            bytes memory param = params[i];

            if (action == Actions.ADD_DEBT) {
                _addDebt(param);
            }
        }
        return "";
    }

    function _addDebt(bytes memory param) internal {
        (uint256 positionId, uint256 delta, address recipient) = abi.decode(param, (uint256, uint256, address));
        licredity.increaseDebtShare(positionId, delta, recipient);
    }
}
