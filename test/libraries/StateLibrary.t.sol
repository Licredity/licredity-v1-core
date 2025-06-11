// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "../utils/Deployer.sol";
import {Licredity} from "src/Licredity.sol";
import {StateLibrary} from "src/libraries/StateLibrary.sol";
import {Fungible} from "src/types/Fungible.sol";
import {NonFungible} from "src/types/NonFungible.sol";

contract StateLibraryTest is Deployers {
    using StateLibrary for Licredity;

    Fungible public fungible;
    Fungible public otherFungible;

    function setUp() public {
        deployFreshETHLicredity();
        deployNonFungibleMock();
        deployFungibleMock();

        fungible = Fungible.wrap(address(fungibleMock));
        otherFungible = Fungible.wrap(address(otherFungibleMock));
    }

    function test_getPositionOwner() public {
        uint256 positionId = licredity.open();
        assertEq(licredity.getPositionOwner(positionId), address(this));
    }

    function test_getPositionFungibles() public {
        uint256 positionId = licredity.open();

        licredity.stageFungible(fungible);
        licredity.depositFungible(positionId);

        licredity.stageFungible(otherFungible);
        licredity.depositFungible(positionId);

        address[] memory fungibles = new address[](2);
        fungibles[0] = address(fungibleMock);
        fungibles[1] = address(otherFungibleMock);

        assertEq(licredity.getPositionFungibles(positionId), fungibles);
    }

    function test_getPositionFungiblesBalance() public {
        uint256 positionId = licredity.open();

        licredity.stageFungible(fungible);
        fungibleMock.mint(address(licredity), 10 ether);
        licredity.depositFungible(positionId);

        assertEq(licredity.getPositionFungiblesBalance(1, address(fungibleMock)), 10 ether);
    }

    function test_getPositionNonFungibles() public {
        nonFungibleMock.mint(address(this), 1);
        uint256 positionId = licredity.open();

        licredity.stageNonFungible(getMockFungible(1));
        nonFungibleMock.transferFrom(address(this), address(licredity), 1);
        licredity.depositNonFungible(positionId);

        NonFungible[] memory nonFungibles = licredity.getPositionNonFungibles(positionId);

        assertEq(NonFungible.unwrap(nonFungibles[0]), NonFungible.unwrap(getMockFungible(1)));
    }
}
