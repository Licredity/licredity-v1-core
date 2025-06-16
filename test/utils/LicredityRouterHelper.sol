// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {LicredityRouter, Actions} from "./LicredityRouter.sol";

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
}
