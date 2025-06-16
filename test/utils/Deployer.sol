// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {Licredity} from "src/Licredity.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {NonFungibleMock} from "test/mocks/NonFungibleMock.sol";
import {OracleMock} from "test/mocks/OracleMock.sol";
import {DebtTokenMock} from "test/mocks/DebtTokenMock.sol";
import {LicredityRouter} from "./LicredityRouter.sol";
import {LicredityRouterHelper} from "./LicredityRouterHelper.sol";
import {IPoolManager} from "@uniswap-v4-core/interfaces/IPoolManager.sol";

contract Deployers is Test {
    IPoolManager public poolManager;
    address constant UNISWAP_V4 = address(0x000000000004444c5dc75cB358380D2e3dE08A90);

    Licredity public licredity;
    NonFungibleMock public nonFungibleMock;

    //     TestERC20 public fungibleMock;
    //     TestERC20 public otherFungibleMock;

    LicredityRouter public licredityRouter;
    LicredityRouterHelper public licredityRouterHelper;

    function _newAsset(uint8 decimals) internal returns (DebtTokenMock) {
        return new DebtTokenMock("Token", "T", decimals);
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
    }

    function deployLicredityRouter() public {
        licredityRouter = new LicredityRouter(licredity);
        licredityRouterHelper = new LicredityRouterHelper(licredityRouter);
    }

    function deployNonFungibleMock() public {
        nonFungibleMock = new NonFungibleMock();
    }

    function deployAndSetOracleMock() public {
        OracleMock oracleMock = new OracleMock();
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
}
