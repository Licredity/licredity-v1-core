// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {FullMath} from "src/libraries/FullMath.sol";
import {InterestRateLibrary} from "src/types/InterestRate.sol";
import {Fungible} from "src/types/Fungible.sol";
import {Licredity} from "src/Licredity.sol";
import {LicredityConstants} from "src/LicredityConstants.sol";
import {AaveIntertestMath} from "./utils/AaveMathInterest.sol";
import {Deployers} from "./utils/Deployer.sol";
import {LicredityRouter} from "./utils/LicredityRouter.sol";
import {LicredityRouterHelper} from "./utils/LicredityRouterHelper.sol";

contract LicredityInterestTest is Deployers {
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
        uint256 beforeTotalAssets = licredity.totalDebtBalance();

        skip(elapsed);
        oracleMock.setQuotePrice(price);

        uint256 positionId = licredityRouter.openPosition();
        licredityRouter.depositFungible{value: 0.5 ether}(
            positionId, LicredityConstants.CHAIN_NATIVE_FUNGIBLE, 0.5 ether
        );
        licredityRouterHelper.withdrawFungible(
            positionId, address(1), Fungible.unwrap(LicredityConstants.CHAIN_NATIVE_FUNGIBLE), 0.1 ether
        );

        uint256 afterTotalAssets = licredity.totalDebtBalance();

        uint256 yearRate = (price - 1e18) * LicredityConstants.PRICE_TO_INTEREST_RATE_SCALE_FACTOR;
        if (yearRate > 365e25) {
            yearRate = 365e25;
        }

        uint256 rayRate = AaveIntertestMath.calculateCompoundedInterest(yearRate, elapsed);

        uint256 interestAsset = FullMath.fullMulDiv(beforeTotalAssets, rayRate, InterestRateLibrary.RAY);
        assertApproxEqAbs(afterTotalAssets, interestAsset, 1);
    }

    // function deployInterestSensitivityLicredity(uint256 interestSensitivity) public {
    //     address payable mockLicredity = payable(address(0x15b0f23F7b8b8d267Eef0BBaCD6eAE4B00626aC0));
    //     deployCodeTo(
    //         "Licredity.sol",
    //         abi.encode(address(0), interestSensitivity, address(poolManager), "Debt ETH", "DETH", address(this)),
    //         mockLicredity
    //     );
    //     licredity = Licredity(mockLicredity);
    //     licredity.setDebtLimit(10000 ether);
    //     licredity.setOracle(address(oracleMock));

    //     licredityRouter = new LicredityRouter(licredity);
    //     licredityRouterHelper = new LicredityRouterHelper(licredityRouter);
    // }

    // /// (1 - price) = year interest rate
    // function test_yearRate_interest(uint32 elapsed, uint256 price) public {
    //     price = bound(price, 1 ether, 5 ether);

    //     deployInterestSensitivityLicredity(1);
    //     getDebtERC20(address(this), 1 ether);
    //     uint256 beforeTotalAssets = licredity.totalDebtBalance();

    //     skip(elapsed);
    //     oracleMock.setQuotePrice(price);

    //     uint256 positionId = licredityRouter.openPosition();
    //     licredityRouter.depositFungible{value: 0.5 ether}(
    //         positionId, LicredityConstants.CHAIN_NATIVE_FUNGIBLE, 0.5 ether
    //     );
    //     licredityRouterHelper.withdrawFungible(
    //         positionId, address(1), Fungible.unwrap(LicredityConstants.CHAIN_NATIVE_FUNGIBLE), 0.1 ether
    //     );

    //     uint256 afterTotalAssets = licredity.totalDebtBalance();

    //     uint256 yearRate = (price - 1e18) * 1e9;
    //     if (yearRate > 365e25) {
    //         yearRate = 365e25;
    //     }

    //     uint256 rayRate = AaveIntertestMath.calculateCompoundedInterest(yearRate, elapsed);
    //     uint256 interestAsset = FullMath.fullMulDiv(beforeTotalAssets, rayRate, InterestRateLibrary.RAY);

    //     assertApproxEqAbs(afterTotalAssets, interestAsset, 1);
    // }

    // function test_fuzz_SensitivityLicredity(uint32 elapsed, uint256 price, uint256 interestSensitivity) public {
    //     price = bound(price, 1 ether, 5 ether);
    //     interestSensitivity = bound(interestSensitivity, 1, 365);

    //     deployInterestSensitivityLicredity(interestSensitivity);
    //     getDebtERC20(address(this), 1 ether);
    //     uint256 beforeTotalAssets = licredity.totalDebtBalance();

    //     skip(elapsed);
    //     oracleMock.setQuotePrice(price);

    //     uint256 positionId = licredityRouter.openPosition();
    //     licredityRouter.depositFungible{value: 0.5 ether}(
    //         positionId, LicredityConstants.CHAIN_NATIVE_FUNGIBLE, 0.5 ether
    //     );
    //     licredityRouterHelper.withdrawFungible(
    //         positionId, address(1), Fungible.unwrap(LicredityConstants.CHAIN_NATIVE_FUNGIBLE), 0.1 ether
    //     );

    //     uint256 afterTotalAssets = licredity.totalDebtBalance();

    //     uint256 yearRate = (price - 1e18) * 1e9 * interestSensitivity;
    //     if (yearRate > 365e25) {
    //         yearRate = 365e25;
    //     }

    //     uint256 rayRate = AaveIntertestMath.calculateCompoundedInterest(yearRate, elapsed);
    //     uint256 interestAsset = FullMath.fullMulDiv(beforeTotalAssets, rayRate, InterestRateLibrary.RAY);

    //     assertApproxEqAbs(afterTotalAssets, interestAsset, 1);
    // }

    function test_decreaseDebtShare_collectsInterest(uint256 elapsed, uint256 price) public {
        price = bound(price, 1 ether, 5 ether);
        elapsed = bound(elapsed, 1, 30 days);

        uint256 positionId = licredityRouter.openPosition();
        licredityRouter.depositFungible{value: 10.2 ether}(
            positionId, LicredityConstants.CHAIN_NATIVE_FUNGIBLE, 10.2 ether
        );

        uint256 delta = 10 ether * 1e6;

        licredityRouterHelper.addDebt(positionId, delta, address(this));

        skip(elapsed);
        oracleMock.setQuotePrice(price);

        uint256 amountRepaid = licredity.decreaseDebtShare(positionId, 1 ether * 1e6, false);

        uint256 yearRate = (price - 1e18) * LicredityConstants.PRICE_TO_INTEREST_RATE_SCALE_FACTOR;
        if (yearRate > 365e25) {
            yearRate = 365e25;
        }

        uint256 rayRate = AaveIntertestMath.calculateCompoundedInterest(yearRate, elapsed);
        uint256 borrowWithInterest = FullMath.fullMulDiv(1 ether, rayRate, InterestRateLibrary.RAY);
        assertApproxEqAbs(amountRepaid, borrowWithInterest, 2);
    }
}
