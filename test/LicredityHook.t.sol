// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {StateLibrary as LicredityStateLibrary} from "./utils/StateLibrary.sol";
import {ILicredity} from "src/interfaces/ILicredity.sol";
import {Licredity} from "src/Licredity.sol";
import {Fungible} from "src/types/Fungible.sol";
import {IERC20} from "@forge-std/interfaces/IERC20.sol";
import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {Currency} from "@uniswap-v4-core/types/Currency.sol";
import {CustomRevert} from "@uniswap-v4-core/libraries/CustomRevert.sol";
import {Hooks} from "@uniswap-v4-core/libraries/Hooks.sol";
import {TickMath} from "@uniswap-v4-core/libraries/TickMath.sol";
import {IHooks} from "@uniswap-v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";
import {StateLibrary} from "@uniswap-v4-core/libraries/StateLibrary.sol";

contract LicredityHookTest is Deployers {
    using StateLibrary for IPoolManager;
    using LicredityStateLibrary for Licredity;

    uint24 private constant FEE = 100;
    int24 private constant TICK_SPACING = 1;
    uint160 private constant ONE_SQRT_PRICE_X96 = 0x1000000000000000000000000;

    PoolKey public poolKey;

    function setUp() public {
        deployETHLicredityWithUniswapV4();
        deployAndSetOracleMock();
        deployLicredityRouter();
        deployUniswapV4Router();

        poolKey = PoolKey(
            Currency.wrap(address(0)), Currency.wrap(address(licredity)), FEE, TICK_SPACING, IHooks(address(licredity))
        );
    }

    function swapForExchange(int256 amountSpecified) public {
        vm.deal(address(uniswapV4Router), 2.1 ether);

        getDebtERC20(address(this), 1.1 ether);
        IERC20(address(licredity)).approve(address(uniswapV4Router), 1.1 ether);

        uniswapV4RouterHelper.addLiquidity(
            address(this),
            poolKey,
            IPoolManager.ModifyLiquidityParams({tickLower: -2, tickUpper: 2, liquidityDelta: 10001 ether, salt: ""})
        );

        uniswapV4RouterHelper.zeroForOneSwap(
            user,
            poolKey,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: amountSpecified,
                sqrtPriceLimitX96: TickMath.getSqrtPriceAtTick(-3)
            })
        );
    }

    function test_afterSwap(uint256 swapAmount) public {
        vm.deal(address(uniswapV4Router), 2.1 ether);

        getDebtERC20(address(this), 1.1 ether);
        IERC20(address(licredity)).approve(address(uniswapV4Router), 1.1 ether);

        uniswapV4RouterHelper.addLiquidity(
            address(this),
            poolKey,
            IPoolManager.ModifyLiquidityParams({tickLower: -2, tickUpper: 2, liquidityDelta: 10001 ether, salt: ""})
        );

        int256 amountSpecified = -int256(uint256(bound(uint256(swapAmount), 2, 1.0002 ether)));
        /// 0xb47b2fb1 = afterSwap selector
        vm.expectRevert(
            abi.encodeWithSelector(
                CustomRevert.WrappedError.selector,
                address(licredity),
                bytes4(0xb47b2fb1),
                abi.encodePacked(ILicredity.PriceTooLow.selector),
                abi.encodePacked(Hooks.HookCallFailed.selector)
            )
        );
        uniswapV4RouterHelper.zeroForOneSwap(
            user,
            poolKey,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: amountSpecified,
                sqrtPriceLimitX96: TickMath.getSqrtPriceAtTick(-3)
            })
        );
    }

    function test_exchangeFungible_recipientZeroAddress() public {
        vm.expectRevert(ILicredity.ZeroAddressNotAllowed.selector);
        licredity.exchangeFungible(address(0), true);
    }

    function test_exchangeFungible_NotBaseFungible() public {
        licredity.stageFungible(Fungible.wrap(address(licredity)));
        vm.expectRevert(ILicredity.NotBaseFungible.selector);
        licredity.exchangeFungible(address(user), true);
    }

    function test_exchangeFungible_baseForDebt_zeroBaseFungible() public {
        licredity.stageFungible(Fungible.wrap(address(0)));
        licredity.exchangeFungible(user, true);
    }

    function test_exchangeFungible_baseForDebt(uint256 amount) public {
        amount = bound(amount, 1, address(this).balance);
        vm.expectEmit(true, true, false, true);
        emit ILicredity.ExchangeFungible(user, true, amount);

        licredity.exchangeFungible{value: amount}(user, true);
        assertEq(IERC20(address(licredity)).balanceOf(address(user)), amount);
    }

    function test_exchangeFungible_DebtForbase_ExceedsAmountOutstanding() public {
        getDebtERC20(address(this), 1 ether);

        licredity.stageFungible(Fungible.wrap(address(licredity)));
        IERC20(address(licredity)).transfer(address(licredity), 1);
        vm.expectRevert(ILicredity.ExchangeableAmountExceeded.selector);
        licredity.exchangeFungible(user, false);
    }

    function test_exchangeFungible_DebtForBase_zeroDebtFungible() public {
        licredity.stageFungible(Fungible.wrap(address(0)));
        vm.expectRevert(ILicredity.NotDebtFungible.selector);
        licredity.exchangeFungible(user, false);
    }

    function test_exchangeFungible_DebtForBase(uint256 baseAmount, uint256 debtAmount) public {
        baseAmount = bound(baseAmount, 1, address(this).balance);
        debtAmount = bound(debtAmount, 1, baseAmount);

        licredity.exchangeFungible{value: baseAmount}(address(this), true);

        licredity.stageFungible(Fungible.wrap(address(licredity)));
        IERC20(address(licredity)).transfer(address(licredity), debtAmount);

        vm.expectEmit(true, true, false, true);
        emit ILicredity.ExchangeFungible(user, false, debtAmount);
        licredity.exchangeFungible(address(user), false);
    }

    function test_beforeAddLiquidity() public {
        // Add debt
        vm.deal(address(uniswapV4Router), 2.1 ether);
        getDebtERC20(address(this), 1.1 ether);
        IERC20(address(licredity)).approve(address(uniswapV4Router), 1.1 ether);

        skip(1000);

        uniswapV4RouterHelper.addLiquidity(
            address(this),
            poolKey,
            IPoolManager.ModifyLiquidityParams({tickLower: -2, tickUpper: 2, liquidityDelta: 10001 ether, salt: ""})
        );
    }

    function test_beforeAddLiquidity_mintInterest() public {
        // Add debt
        vm.deal(address(uniswapV4Router), 2.1 ether);
        getDebtERC20(address(this), 2.1 ether);
        IERC20(address(licredity)).approve(address(uniswapV4Router), 2.1 ether);

        uniswapV4RouterHelper.addLiquidity(
            address(this),
            poolKey,
            IPoolManager.ModifyLiquidityParams({tickLower: -2, tickUpper: 2, liquidityDelta: 10001 ether, salt: ""})
        );

        oracleMock.setQuotePrice(1.01 ether);

        skip(1000);

        vm.expectEmit(true, true, false, false, address(licredity));
        emit IERC20.Transfer(address(0), address(poolManager), 0);
        uniswapV4RouterHelper.addLiquidity(
            address(this),
            poolKey,
            IPoolManager.ModifyLiquidityParams({tickLower: -1, tickUpper: 1, liquidityDelta: 100 ether, salt: ""})
        );
    }

    function test_removeLiquidity() public {
        // Add debt
        vm.deal(address(uniswapV4Router), 2.1 ether);
        getDebtERC20(address(this), 2.1 ether);
        IERC20(address(licredity)).approve(address(uniswapV4Router), 2.1 ether);

        uniswapV4RouterHelper.addLiquidity(
            address(this),
            poolKey,
            IPoolManager.ModifyLiquidityParams({tickLower: -2, tickUpper: 2, liquidityDelta: 10001 ether, salt: ""})
        );

        oracleMock.setQuotePrice(1.01 ether);

        skip(1000);
        vm.expectEmit(true, true, false, false, address(licredity));
        emit IERC20.Transfer(address(0), address(poolManager), 0);

        uniswapV4RouterHelper.removeLiquidity(
            address(this),
            poolKey,
            IPoolManager.ModifyLiquidityParams({tickLower: -2, tickUpper: 2, liquidityDelta: -100 ether, salt: ""})
        );
    }

    receive() external payable {}
}
