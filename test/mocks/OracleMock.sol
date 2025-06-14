// // SPDX-License-Identifier: UNLICENSED
// pragma solidity =0.8.30;

// import {IOracle} from "src/interfaces/IOracle.sol";
// import {Math} from "src/libraries/Math.sol";

// contract OracleMock is IOracle {
//     using Math for uint256;

//     uint256 public quotePrice;
//     mapping(address fungible => uint256 price) fungiblePrices;
//     mapping(address fungible => uint16 mrrBps) fungibleMrrBps;
//     mapping(address nonFungible => mapping(uint256 id => uint256 price)) nonFungibleValue;
//     mapping(address nonFungible => uint16 mrrBps) nonFungibleMrrBps;

//     function setQuotePrice(uint256 quotePrice_) external {
//         quotePrice = quotePrice_;
//     }

//     function setFungibleConfig(address fungible, uint256 price_, uint16 mrrBps_) external {
//         fungiblePrices[fungible] = price_;
//         fungibleMrrBps[fungible] = mrrBps_;
//     }

//     function quoteFungible(address fungible, uint256 amount)
//         internal
//         view
//         returns (uint256 value, uint256 marginRequirement)
//     {
//         value = amount.fullMulDiv(fungiblePrices[fungible], 1 ether);
//         marginRequirement = value.mulBpsUp(fungibleMrrBps[fungible]);
//     }

//     function quoteFungibles(address[] memory tokens, uint256[] memory amounts)
//         external
//         view
//         returns (uint256 value, uint256 marginRequirement)
//     {
//         uint256 count = tokens.length;
//         for (uint256 i = 0; i < count; i++) {
//             (uint256 _value, uint256 _marginRequirement) = quoteFungible(tokens[i], amounts[i]);
//             value += _value;
//             marginRequirement += _marginRequirement;
//         }
//     }

//     function setNonFungibleConfig(address nonFungible, uint256 tokenId, uint256 value, uint16 mrrBps) external {
//         nonFungibleValue[nonFungible][tokenId] = value;
//         nonFungibleMrrBps[nonFungible] = mrrBps;
//     }

//     function quoteNonFungibles(address[] memory tokens, uint256[] memory ids)
//         external
//         view
//         returns (uint256 value, uint256 marginRequirement)
//     {
//         uint256 count = tokens.length;
//         for (uint256 i = 0; i < count; i++) {
//             value += nonFungibleValue[tokens[i]][ids[i]];
//             marginRequirement += value.mulBpsUp(nonFungibleMrrBps[tokens[i]]);
//         }
//     }

//     function update() external {}
// }
