// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Deployers} from "./utils/Deployer.sol";
import {Licredity} from "src/Licredity.sol";
import {ChainInfo} from "src/libraries/ChainInfo.sol";
import {FullMath} from "src/libraries/FullMath.sol";
import {Fungible} from "src/types/Fungible.sol";
import {StateLibrary} from "./utils/StateLibrary.sol";
import {ChainInfo} from "src/libraries/ChainInfo.sol";
import {AAVEIntertestMath, RAY} from "./utils/AAVEMathInterest.sol";

contract LicredityInterestTest is Deployers {
    using StateLibrary for Licredity;

    function setUp() public {
        deployETHLicredityWithUniswapV4();
        deployNonFungibleMock();
        deployAndSetOracleMock();
        deployLicredityRouter();
    }

    function test_interest(uint32 elapsed, uint256 price) public {
        price = bound(price, 1 ether, 5 ether);

        getDebtERC20(address(this), 1 ether);
        (, uint256 beforeTotalAssets) = licredity.getTotalDebt();

        skip(elapsed);
        oracleMock.setQuotePrice(price);

        uint256 positionId = licredityRouter.open();
        licredityRouter.depositFungible{value: 0.5 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 0.5 ether);
        licredityRouterHelper.withdrawFungible(positionId, address(1), ChainInfo.NATIVE, 0.1 ether);

        (, uint256 afterTotalAssets) = licredity.getTotalDebt();

        uint256 rate = (price - 1e18) * 1e9;
        uint256 rayRate = AAVEIntertestMath.calculateCompoundedInterest(rate, elapsed);

        uint256 interestAsset = FullMath.fullMulDiv(beforeTotalAssets, rayRate, RAY);
        assertApproxEqAbs(afterTotalAssets, interestAsset, 1);
    }
}
