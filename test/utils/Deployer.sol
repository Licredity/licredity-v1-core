// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {Licredity} from "src/Licredity.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {ChainInfo} from "src/libraries/ChainInfo.sol";
import {NonFungibleMock} from "test/mocks/NonFungibleMock.sol";
import {OracleMock} from "test/mocks/OracleMock.sol";
import {BaseERC20Mock} from "test/mocks/BaseERC20Mock.sol";
import {StateLibrary} from "./StateLibrary.sol";
import {ShareMath} from "./ShareMath.sol";
import {LicredityRouter} from "./LicredityRouter.sol";
import {LicredityRouterHelper} from "./LicredityRouterHelper.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";

contract Deployers is Test {
    using ShareMath for uint128;
    using StateLibrary for Licredity;

    IPoolManager public poolManager;
    address constant UNISWAP_V4 = address(0x000000000004444c5dc75cB358380D2e3dE08A90);

    Licredity public licredity;
    NonFungibleMock public nonFungibleMock;
    OracleMock public oracleMock;
    //     TestERC20 public fungibleMock;
    //     TestERC20 public otherFungibleMock;

    LicredityRouter public licredityRouter;
    LicredityRouterHelper public licredityRouterHelper;

    function _newAsset(uint8 decimals) internal returns (BaseERC20Mock) {
        return new BaseERC20Mock("Token", "T", decimals);
    }

    function deployPoolManager() public {
        vm.createSelectFork("ETH", 22638094);
        poolManager = IPoolManager(address(0x000000000004444c5dc75cB358380D2e3dE08A90));
    }

    function deployETHLicredityWithUniswapV4() public {
        deployPoolManager();

        address mockLicredity = address(0xFb46d30c9B3ACc61d714D167179748FD01E09aC0);

        vm.label(mockLicredity, "Licredity");
        deployCodeTo(
            "Licredity.sol", abi.encode(address(0), UNISWAP_V4, address(this), "Debt ETH", "DETH"), mockLicredity
        );

        licredity = Licredity(mockLicredity);
        licredity.setDebtLimit(10000 ether);
    }

    function deployLicredityRouter() public {
        licredityRouter = new LicredityRouter(licredity);
        licredityRouterHelper = new LicredityRouterHelper(licredityRouter);
    }

    function deployNonFungibleMock() public {
        nonFungibleMock = new NonFungibleMock();
    }

    function deployAndSetOracleMock() public {
        oracleMock = new OracleMock();
        oracleMock.setQuotePrice(1e18);
        oracleMock.setFungibleConfig(Fungible.wrap(address(0)), 1 ether, 1000); // 1000 / 1_000_000 = 0.1%
        oracleMock.setFungibleConfig(Fungible.wrap(address(licredity)), 1 ether, 0);
        licredity.setOracle(address(oracleMock));
    }

    function getMockFungible(uint256 tokenId) public view returns (NonFungible nft) {
        address nonFungibleMockAddress = address(nonFungibleMock);
        assembly ("memory-safe") {
            nft := or(shl(96, nonFungibleMockAddress), tokenId)
        }
    }

    function getDebtERC20(address receiver, uint128 amount) public {
        uint256 positionId = licredityRouter.open();

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        licredityRouter.depositFungible{value: 2 * amount}(positionId, Fungible.wrap(ChainInfo.NATIVE), 2 * amount);

        uint256 debtDelta = amount.toShares(totalAssets, totalShares);
        licredityRouterHelper.addDebt(positionId, debtDelta, receiver);
    }
}
