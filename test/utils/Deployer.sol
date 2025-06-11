// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "@forge-std/Test.sol";
import {Licredity} from "src/Licredity.sol";
import {NonFungible} from "src/types/NonFungible.sol";
import {NonFungibleMock} from "test/mocks/NonFungibleMock.sol";
import {TestERC20} from "@uniswap-v4-core/test/TestERC20.sol";

contract Deployers is Test {
    address constant UNISWAP_V4 = address(0x000000000004444c5dc75cB358380D2e3dE08A90);
    Licredity public licredity;
    NonFungibleMock public nonFungibleMock;
    TestERC20 public fungibleMock;

    function deployFreshETHLicredity() public {
        licredity = new Licredity(address(0), UNISWAP_V4, "Debt ETH", "DETH", 18, address(this));
    }

    function deployNonFungibleMock() public {
        nonFungibleMock = new NonFungibleMock();
    }

    function deployFungibleMock() public {
        fungibleMock = new TestERC20(0);
    }

    function getMockFungible(uint256 tokenId) public view returns (NonFungible nft) {
        address nonFungibleMockAddress = address(nonFungibleMock);
        assembly ("memory-safe") {
            nft := or(shl(96, nonFungibleMockAddress), tokenId)
        }
    }
}
