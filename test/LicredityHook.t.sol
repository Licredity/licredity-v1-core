// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {StateLibrary as LicredityStateLibrary} from "./utils/StateLibrary.sol";
import {Licredity} from "src/Licredity.sol";
import {Fungible} from "src/types/Fungible.sol";
import {IERC20} from "@forge-std/interfaces/IERC20.sol";
import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {Currency} from "@uniswap-v4-core/types/Currency.sol";
import {TickMath} from "@uniswap-v4-core/libraries/TickMath.sol";
import {IHooks} from "@uniswap-v4-core/interfaces/IHooks.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";
import {StateLibrary} from "@uniswap-v4-core/libraries/StateLibrary.sol";

contract LicredityHookTest is Deployers {
    using StateLibrary for IPoolManager;
    using LicredityStateLibrary for Licredity;

    error NotBaseFungible();
    error NotDebtFungible();
    error ExceedsAmountOutstanding();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Exchange(address indexed recipient, bool indexed baseForDebt, uint256 debtAmountIn, uint256 baseAmountOut);

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

        int256 amountSpecified = -int256(uint256(bound(uint256(swapAmount), 1, 1.0002 ether)));
        uint256 hookEtherBefore = address(licredity).balance;
        uniswapV4RouterHelper.zeroForOneSwap(
            user,
            poolKey,
            IPoolManager.SwapParams({
                zeroForOne: true,
                amountSpecified: amountSpecified,
                sqrtPriceLimitX96: TickMath.getSqrtPriceAtTick(-3)
            })
        );
        uint256 hookEtherAfter = address(licredity).balance;

        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolKey.toId());
        assertGe(sqrtPriceX96, ONE_SQRT_PRICE_X96);
        assertApproxEqAbsDecimal(hookEtherAfter - hookEtherBefore, uint256(-amountSpecified), 0.0001 ether, 18);

        uint256 userDebtAmount = IERC20(address(licredity)).balanceOf(address(user));

        (uint256 baseAmountAvailable, uint256 debtAmountOutstanding) = licredity.getExchangeAmount();
        assertApproxEqAbsDecimal(baseAmountAvailable, uint256(-amountSpecified), 0.0001 ether, 18);
        assertApproxEqAbsDecimal(debtAmountOutstanding, uint256(userDebtAmount), 0.00021 ether, 18);
    }

    function test_exchangeFungible_NotBaseFungible() public {
        licredity.stageFungible(Fungible.wrap(address(licredity)));
        vm.expectRevert(NotBaseFungible.selector);
        licredity.exchangeFungible(address(user), true);
    }

    function test_exchangeFungible_zeroBaseFungible() public {
        licredity.stageFungible(Fungible.wrap(address(0)));
        licredity.exchangeFungible(user, true);
    }

    function test_exchangeFungible_ExceedsAmountOutstanding() public {
        swapForExchange(int256(-0.5 ether));

        getDebtERC20(address(this), 1 ether);

        (, uint256 debtAmountOutstanding) = licredity.getExchangeAmount();
        licredity.stageFungible(Fungible.wrap(address(licredity)));
        IERC20(address(licredity)).transfer(address(licredity), debtAmountOutstanding + 1);
        vm.expectRevert(ExceedsAmountOutstanding.selector);
        licredity.exchangeFungible(user, false);
    }

    function test_exchangeDebtFungible() public {
        swapForExchange(int256(-0.5 ether));

        getDebtERC20(address(this), 1 ether);

        (uint256 baseAmountAvailable, uint256 debtAmountOutstanding) = licredity.getExchangeAmount();
        licredity.stageFungible(Fungible.wrap(address(licredity)));
        IERC20(address(licredity)).transfer(address(licredity), debtAmountOutstanding);

        uint256 beforeUserBalance = user.balance;

        vm.expectEmit(true, false, false, true);
        emit Exchange(user, false, debtAmountOutstanding, baseAmountAvailable);
        licredity.exchangeFungible(address(user), false);

        uint256 afterUserBalance = user.balance;

        assertEq(afterUserBalance - beforeUserBalance, baseAmountAvailable);

        (baseAmountAvailable, debtAmountOutstanding) = licredity.getExchangeAmount();
        assertEq(baseAmountAvailable, 0);
        assertEq(debtAmountOutstanding, 0);
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
        emit Transfer(address(0), address(poolManager), 0);
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
        emit Transfer(address(0), address(poolManager), 0);

        uniswapV4RouterHelper.removeLiquidity(
            address(this),
            poolKey,
            IPoolManager.ModifyLiquidityParams({tickLower: -2, tickUpper: 2, liquidityDelta: -100 ether, salt: ""})
        );
    }

    receive() external payable {}
}
