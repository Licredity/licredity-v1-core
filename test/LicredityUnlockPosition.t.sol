// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {ShareMath} from "./utils/ShareMath.sol";
import {StateLibrary} from "src/libraries/StateLibrary.sol";
import {Licredity} from "src/Licredity.sol";

contract LicredityExchangeTest is Deployers {
    using ShareMath for uint256;
    using StateLibrary for Licredity;

    error PositionIsAtRisk();

    function setUp() public {
        deployETHLicredityWithUniswapV4();
        deployAndSetOracleMock();
        deployLicredityRouter();
    }

    function test_addDebt(uint256 amount) public {
        vm.assume(amount < type(uint256).max / 1e6);

        uint256 positionId = licredityRouter.open();

        (uint256 totalShares, uint256 totalAssets) = licredity.getTotalDebt();
        licredity.depositFungible{value: 1 ether}(positionId);

        uint256 share = amount.toSharesUp(totalAssets, totalShares);

        if (amount < 1000 ether) {
            licredityRouterHelper.addDebt(positionId, share, address(this));
            assertEq(licredity.balanceOf(address(this)), amount);
        } else {
            vm.expectRevert(PositionIsAtRisk.selector);
            licredityRouterHelper.addDebt(positionId, share, address(this));
            // assertEq(licredity.balanceOf(address(this)), 1000 ether);
        }
    }
}
