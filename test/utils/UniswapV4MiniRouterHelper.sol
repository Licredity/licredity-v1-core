// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";
import {Currency} from "@uniswap-v4-core/types/Currency.sol";
import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {V4MiniRouter, V4Actions} from "./UniswapV4MiniRouter.sol";

contract V4RouterHelper {
    V4MiniRouter public router;

    constructor(V4MiniRouter _router) {
        router = _router;
    }

    function addLiquidity(
        address sender,
        PoolKey memory poolKey,
        IPoolManager.ModifyLiquidityParams memory liquidityParam
    ) public {
        V4Actions[] memory actions = new V4Actions[](3);
        bytes[] memory params = new bytes[](3);

        actions[0] = V4Actions.MODIFY_LIQUIDITY;
        params[0] = abi.encode(poolKey, liquidityParam);

        actions[1] = V4Actions.SETTLE_ALL;
        params[1] = abi.encode(sender, Currency.unwrap(poolKey.currency0));

        actions[2] = V4Actions.SETTLE_ALL;
        params[2] = abi.encode(sender, Currency.unwrap(poolKey.currency1));

        router.executeV4Actions(actions, params);
    }

    function removeLiquidity(
        address sender,
        PoolKey memory poolKey,
        IPoolManager.ModifyLiquidityParams memory liquidityParam
    ) public {
        V4Actions[] memory actions = new V4Actions[](3);
        bytes[] memory params = new bytes[](3);

        actions[0] = V4Actions.MODIFY_LIQUIDITY;
        params[0] = abi.encode(poolKey, liquidityParam);

        actions[1] = V4Actions.TAKE_ALL;
        params[1] = abi.encode(sender, Currency.unwrap(poolKey.currency0));

        actions[2] = V4Actions.TAKE_ALL;
        params[2] = abi.encode(sender, Currency.unwrap(poolKey.currency1));

        router.executeV4Actions(actions, params);
    }

    function zeroForOneSwap(address sender, PoolKey memory poolKey, IPoolManager.SwapParams memory swapParams) public {
        V4Actions[] memory actions = new V4Actions[](3);
        bytes[] memory params = new bytes[](3);

        actions[0] = V4Actions.SWAP;
        params[0] = abi.encode(poolKey, swapParams);

        actions[1] = V4Actions.TAKE_ALL;
        params[1] = abi.encode(sender, Currency.unwrap(poolKey.currency1));

        actions[2] = V4Actions.SETTLE_ALL;
        params[2] = abi.encode(sender, Currency.unwrap(poolKey.currency0));

        router.executeV4Actions(actions, params);
    }

    function oneForZeroSwap(address sender, PoolKey memory poolKey, IPoolManager.SwapParams memory swapParams) public {
        V4Actions[] memory actions = new V4Actions[](3);
        bytes[] memory params = new bytes[](3);

        actions[0] = V4Actions.SWAP;
        params[0] = abi.encode(poolKey, swapParams);

        actions[1] = V4Actions.TAKE_ALL;
        params[1] = abi.encode(sender, Currency.unwrap(poolKey.currency0));

        actions[2] = V4Actions.SETTLE_ALL;
        params[2] = abi.encode(sender, Currency.unwrap(poolKey.currency1));

        router.executeV4Actions(actions, params);
    }
}
