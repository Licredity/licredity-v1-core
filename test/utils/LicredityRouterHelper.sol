// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {LicredityRouter, Actions} from "./LicredityRouter.sol";
import {NonFungible} from "src/types/NonFungible.sol";

contract LicredityRouterHelper {
    LicredityRouter internal router;

    constructor(LicredityRouter router_) {
        router = router_;
    }

    function addDebt(uint256 positionId, uint256 delta, address recipient) external {
        Actions[] memory actions = new Actions[](1);
        bytes[] memory params = new bytes[](1);

        actions[0] = Actions.ADD_DEBT;
        params[0] = abi.encode(positionId, delta, recipient);

        router.executeActions(actions, params);
    }

    function withdrawFungible(uint256 positionId, address recipient, address fungible, uint256 amount) external {
        Actions[] memory actions = new Actions[](1);
        bytes[] memory params = new bytes[](1);

        actions[0] = Actions.WITHDRAW_FUNGIBLE;
        params[0] = abi.encode(positionId, recipient, fungible, amount);

        router.executeActions(actions, params);
    }

    function withdrawNonFungible(uint256 positionId, address recipient, NonFungible nonFungible) external {
        Actions[] memory actions = new Actions[](1);
        bytes[] memory params = new bytes[](1);

        actions[0] = Actions.WITHDRAW_NON_FUNGIBLE;
        params[0] = abi.encode(positionId, recipient, nonFungible);

        router.executeActions(actions, params);
    }

    function seize(uint256 positionId, address recipient) external {
        Actions[] memory actions = new Actions[](1);
        bytes[] memory params = new bytes[](1);

        actions[0] = Actions.SEIZE;
        params[0] = abi.encode(positionId, recipient);

        router.executeActions(actions, params);
    }
}
