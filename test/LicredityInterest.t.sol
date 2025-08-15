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
import {LicredityRouter} from "./utils/LicredityRouter.sol";
import {LicredityRouterHelper} from "./utils/LicredityRouterHelper.sol";

contract LicredityInterestTest is Deployers {
    using StateLibrary for Licredity;

    function setUp() public {
        deployETHLicredityWithUniswapV4();
        deployNonFungibleMock();
        deployAndSetOracleMock();
        deployLicredityRouter();
    }

    // (1 - price) = day interest rate
    function test_dayRate_interest(uint32 elapsed, uint256 price) public {
        price = bound(price, 1 ether, 5 ether);

        getDebtERC20(address(this), 1 ether);
        (, uint256 beforeTotalAssets) = licredity.getTotalDebt();

        skip(elapsed);
        oracleMock.setQuotePrice(price);

        uint256 positionId = licredityRouter.open();
        licredityRouter.depositFungible{value: 0.5 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 0.5 ether);
        licredityRouterHelper.withdrawFungible(positionId, address(1), ChainInfo.NATIVE, 0.1 ether);

        (, uint256 afterTotalAssets) = licredity.getTotalDebt();

        uint256 yearRate = (price - 1e18) * 1e9 * 365;
        if (yearRate > 365e25) {
            yearRate = 365e25;
        }

        uint256 rayRate = AAVEIntertestMath.calculateCompoundedInterest(yearRate, elapsed);

        uint256 interestAsset = FullMath.fullMulDiv(beforeTotalAssets, rayRate, RAY);
        assertApproxEqAbs(afterTotalAssets, interestAsset, 1);
    }

    function deployInterestSensitivityLicredity(uint256 interestSensitivity) public {
        address payable mockLicredity = payable(address(0x15b0f23F7b8b8d267Eef0BBaCD6eAE4B00626aC0));
        deployCodeTo(
            "Licredity.sol",
            abi.encode(address(0), interestSensitivity, address(poolManager), address(this), "Debt ETH", "DETH"),
            mockLicredity
        );
        licredity = Licredity(mockLicredity);
        licredity.setDebtLimit(10000 ether);
        licredity.setOracle(address(oracleMock));

        licredityRouter = new LicredityRouter(licredity);
        licredityRouterHelper = new LicredityRouterHelper(licredityRouter);
    }

    /// (1 - price) = year interest rate
    function test_yearRate_interest(uint32 elapsed, uint256 price) public {
        price = bound(price, 1 ether, 5 ether);

        deployInterestSensitivityLicredity(1);
        getDebtERC20(address(this), 1 ether);
        (, uint256 beforeTotalAssets) = licredity.getTotalDebt();

        skip(elapsed);
        oracleMock.setQuotePrice(price);

        uint256 positionId = licredityRouter.open();
        licredityRouter.depositFungible{value: 0.5 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 0.5 ether);
        licredityRouterHelper.withdrawFungible(positionId, address(1), ChainInfo.NATIVE, 0.1 ether);

        (, uint256 afterTotalAssets) = licredity.getTotalDebt();

        uint256 yearRate = (price - 1e18) * 1e9;
        if (yearRate > 365e25) {
            yearRate = 365e25;
        }

        uint256 rayRate = AAVEIntertestMath.calculateCompoundedInterest(yearRate, elapsed);
        uint256 interestAsset = FullMath.fullMulDiv(beforeTotalAssets, rayRate, RAY);

        assertApproxEqAbs(afterTotalAssets, interestAsset, 1);
    }

    function test_fuzz_SensitivityLicredity(uint32 elapsed, uint256 price, uint256 interestSensitivity) public {
        price = bound(price, 1 ether, 5 ether);
        interestSensitivity = bound(interestSensitivity, 1, 365);

        deployInterestSensitivityLicredity(interestSensitivity);
        getDebtERC20(address(this), 1 ether);
        (, uint256 beforeTotalAssets) = licredity.getTotalDebt();

        skip(elapsed);
        oracleMock.setQuotePrice(price);

        uint256 positionId = licredityRouter.open();
        licredityRouter.depositFungible{value: 0.5 ether}(positionId, Fungible.wrap(ChainInfo.NATIVE), 0.5 ether);
        licredityRouterHelper.withdrawFungible(positionId, address(1), ChainInfo.NATIVE, 0.1 ether);

        (, uint256 afterTotalAssets) = licredity.getTotalDebt();

        uint256 yearRate = (price - 1e18) * 1e9 * interestSensitivity;
        if (yearRate > 365e25) {
            yearRate = 365e25;
        }

        uint256 rayRate = AAVEIntertestMath.calculateCompoundedInterest(yearRate, elapsed);
        uint256 interestAsset = FullMath.fullMulDiv(beforeTotalAssets, rayRate, RAY);

        assertApproxEqAbs(afterTotalAssets, interestAsset, 1);
    }
}
