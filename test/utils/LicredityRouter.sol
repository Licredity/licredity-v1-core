// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IUnlockCallback} from "src/interfaces/IUnlockCallback.sol";
import {ILicredity} from "src/interfaces/ILicredity.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {IERC20} from "@forge-std/interfaces/IERC20.sol";

enum Actions {
    ADD_DEBT,
    REMOVE_DEBT,
    WITHDRAW_FUNGIBLE,
    WITHDRAW_NON_FUNGIBLE,
    DEPOSIT_FUNGIBLE,
    SEIZE
}

contract LicredityRouter is IUnlockCallback {
    address transient owner;

    ILicredity public licredity;

    mapping(uint256 => address) public owners;

    constructor(ILicredity _licredity) {
        licredity = _licredity;
    }

    function openPosition() external returns (uint256 positionId) {
        positionId = licredity.openPosition();
    }

    function closePosition(uint256 positionId) external {
        licredity.closePosition(positionId);
    }

    function _depositFungible(address from, uint256 positionId, Fungible fungible, uint256 amount) internal {
        if (fungible.isNative()) {
            licredity.depositFungible{value: amount}(positionId);
        } else {
            licredity.stageFungible(fungible);
            IERC20(Fungible.unwrap(fungible)).transferFrom(from, address(licredity), amount);
            licredity.depositFungible(positionId);
        }
    }

    function depositFungible(uint256 positionId, Fungible fungible, uint256 amount) public payable {
        _depositFungible(msg.sender, positionId, fungible, amount);
    }

    function depositNonFungible(uint256 positionId, NonFungible nonFungible) external {
        licredity.stageNonFungible(nonFungible);
        nonFungible.transfer(address(licredity));
        licredity.depositNonFungible(positionId);
    }

    function decreaseDebtShare(uint256 positionId, uint256 delta, bool useBalance) external {
        licredity.decreaseDebtShare(positionId, delta, useBalance);
    }

    function executeActions(Actions[] memory actions, bytes[] memory params) external payable {
        licredity.unlock(abi.encode(actions, params));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        owner = msg.sender;
        (Actions[] memory actions, bytes[] memory params) = abi.decode(data, (Actions[], bytes[]));
        for (uint256 i = 0; i < actions.length; i++) {
            Actions action = actions[i];
            bytes memory param = params[i];

            if (action == Actions.ADD_DEBT) {
                _addDebt(param);
            } else if (action == Actions.REMOVE_DEBT) {
                _removeDebt(param);
            } else if (action == Actions.WITHDRAW_FUNGIBLE) {
                _withdrawFungible(param);
            } else if (action == Actions.WITHDRAW_NON_FUNGIBLE) {
                _withdrawNonFungible(param);
            } else if (action == Actions.DEPOSIT_FUNGIBLE) {
                (uint256 positionId, address fungible, uint256 amount) = abi.decode(param, (uint256, address, uint256));
                _depositFungible(owner, positionId, Fungible.wrap(fungible), amount);
            } else if (action == Actions.SEIZE) {
                _seizePosition(param);
            }
        }
        return "";
    }

    function _addDebt(bytes memory param) internal {
        (uint256 positionId, uint256 delta, address recipient) = abi.decode(param, (uint256, uint256, address));
        licredity.increaseDebtShare(positionId, delta, recipient);
    }

    function _removeDebt(bytes memory param) internal {
        (uint256 positionId, uint256 delta, bool useBalance) = abi.decode(param, (uint256, uint256, bool));
        licredity.decreaseDebtShare(positionId, delta, useBalance);
    }

    function _withdrawFungible(bytes memory param) internal {
        (uint256 positionId, address recipient, address fungible, uint256 amount) =
            abi.decode(param, (uint256, address, address, uint256));
        licredity.withdrawFungible(positionId, recipient, Fungible.wrap(fungible), amount);
    }

    function _withdrawNonFungible(bytes memory param) internal {
        (uint256 positionId, address recipient, bytes32 nonFungible) = abi.decode(param, (uint256, address, bytes32));
        licredity.withdrawNonFungible(positionId, recipient, NonFungible.wrap(nonFungible));
    }

    function _seizePosition(bytes memory param) internal {
        (uint256 positionId, address recipient) = abi.decode(param, (uint256, address));
        licredity.seizePosition(positionId, recipient);
    }
}
