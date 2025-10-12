// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Currency} from "@uniswap-v4-core/types/Currency.sol";
import {PoolKey} from "@uniswap-v4-core/types/PoolKey.sol";
import {ChainInfo} from "src/libraries/ChainInfo.sol";
import {StateLibrary} from "src/libraries/StateLibrary.sol";
import {BaseERC20Mock} from "src/test/BaseERC20Mock.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {Deployers} from "../utils/Deployer.sol";

contract FungibleTest is Deployers {
    Fungible public fungible;
    BaseERC20Mock public token;

    function setUp() public {
        deployETHLicredityWithUniswapV4();
        deployAndSetOracleMock();
        deployLicredityRouter();
        deployNonFungibleMock();

        token = _newAsset(18);
        fungible = Fungible.wrap(address(token));
    }

    function test_getPoolKey() public view {
        PoolKey memory poolKey = StateLibrary.getPoolKey(licredity);
        assertEq(Currency.unwrap(poolKey.currency0), address(0));
        assertEq(Currency.unwrap(poolKey.currency1), address(licredity));
        assertEq(poolKey.fee, 100);
        assertEq(poolKey.tickSpacing, 1);
        assertEq(address(poolKey.hooks), address(licredity));
    }

    function test_getPositionOwner() public {
        assertEq(StateLibrary.getPositionOwner(licredity, licredity.nextPositionId()), address(0));

        uint256 positionId = licredity.openPosition();
        assertEq(StateLibrary.getPositionOwner(licredity, positionId), address(this));

        licredity.closePosition(positionId);
        assertEq(StateLibrary.getPositionOwner(licredity, positionId), address(0));
    }

    function test_getPositionDebtShare(uint256 delta) public {
        vm.assume(delta < 10000 ether);

        uint256 totalDebtShareBefore = licredity.totalDebtShare();
        uint256 positionId = licredityRouter.openPosition();
        licredityRouter.depositFungible{value: 1 ether}(positionId, ChainInfo.NATIVE_FUNGIBLE, 1 ether);
        assertEq(StateLibrary.getPositionDebtShare(licredity, positionId), 0);

        licredityRouterHelper.addDebt(positionId, delta, address(licredity));
        assertEq(StateLibrary.getPositionDebtShare(licredity, positionId), delta);
        assertEq(licredity.totalDebtShare() - totalDebtShareBefore, delta);
    }

    function test_getPositionDebtBalance(uint256 delta) public {
        vm.assume(delta < 10000 ether);

        uint256 totalDebtBalanceBefore = licredity.totalDebtBalance();
        uint256 positionId = licredityRouter.openPosition();
        licredityRouter.depositFungible{value: 1 ether}(positionId, ChainInfo.NATIVE_FUNGIBLE, 1 ether);
        assertEq(StateLibrary.getPositionDebtBalance(licredity, positionId), 0);

        licredityRouterHelper.addDebt(positionId, delta, address(licredity));
        assertEq(
            StateLibrary.getPositionDebtBalance(licredity, positionId),
            licredity.totalDebtBalance() - totalDebtBalanceBefore
        );
    }

    function test_getPositionFungibleCount() public {
        uint256 positionId = licredity.openPosition();
        assertEq(StateLibrary.getPositionFungibleCount(licredity, positionId), 0);

        licredity.depositFungible{value: 1 ether}(positionId);
        assertEq(StateLibrary.getPositionFungibleCount(licredity, positionId), 1);

        licredity.depositFungible{value: 1 ether}(positionId);
        assertEq(StateLibrary.getPositionFungibleCount(licredity, positionId), 1);

        licredity.stageFungible(fungible);
        token.mint(address(this), 10 ether);
        token.transfer(address(licredity), 10 ether);
        licredity.depositFungible(positionId);
        assertEq(StateLibrary.getPositionFungibleCount(licredity, positionId), 2);
    }

    function test_getPositionFungibleBalance() public {
        uint256 positionId = licredity.openPosition();
        assertEq(StateLibrary.getPositionFungibleBalance(licredity, positionId, ChainInfo.NATIVE_FUNGIBLE), 0);

        licredity.depositFungible{value: 1 ether}(positionId);
        assertEq(StateLibrary.getPositionFungibleBalance(licredity, positionId, ChainInfo.NATIVE_FUNGIBLE), 1 ether);

        licredity.depositFungible{value: 1 ether}(positionId);
        assertEq(StateLibrary.getPositionFungibleBalance(licredity, positionId, ChainInfo.NATIVE_FUNGIBLE), 2 ether);

        licredity.stageFungible(fungible);
        token.mint(address(this), 10 ether);
        token.transfer(address(licredity), 10 ether);
        licredity.depositFungible(positionId);
        assertEq(StateLibrary.getPositionFungibleBalance(licredity, positionId, fungible), 10 ether);
    }

    function test_getPositionNonFungibleCount() public {
        uint256 positionId = licredity.openPosition();
        assertEq(StateLibrary.getPositionNonFungibleCount(licredity, positionId), 0);

        nonFungibleMock.mint(address(this), 1);
        licredity.stageNonFungible(getMockFungible(1));
        nonFungibleMock.transferFrom(address(this), address(licredity), 1);
        licredity.depositNonFungible(positionId);
        assertEq(StateLibrary.getPositionNonFungibleCount(licredity, positionId), 1);
    }

    function test_getPositionNonFungibleByIndex() public {
        uint256 positionId = licredity.openPosition();

        nonFungibleMock.mint(address(this), 1);
        licredity.stageNonFungible(getMockFungible(1));
        nonFungibleMock.transferFrom(address(this), address(licredity), 1);
        licredity.depositNonFungible(positionId);
        assertEq(
            NonFungible.unwrap(StateLibrary.getPositionNonFungibleByIndex(licredity, positionId, 0)),
            NonFungible.unwrap(getMockFungible(1))
        );
    }
}
