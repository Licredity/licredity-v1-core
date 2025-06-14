// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import {Fungible} from "src/types/Fungible.sol";
// import {NonFungible} from "src/types/NonFungible.sol";

// contract PositionDB {
//     uint256 public nextFungibleIndex;
//     mapping(Fungible => bool) public isUsedFungible;
//     mapping(NonFungible => bool) public isUsedNonFungible;
//     mapping(uint256 index => NonFungible) public usedNonFungibles;
//     mapping(Fungible => uint256) public fungibleBalance;

//     function addUsedFungible(Fungible fungible) public {
//         isUsedFungible[fungible] = true;
//     }

//     function addUsedNonFungible(NonFungible nonFungible) public {
//         isUsedNonFungible[nonFungible] = true;
//         usedNonFungibles[nextFungibleIndex] = nonFungible;
//         nextFungibleIndex += 1;
//     }

//     function addFungibleBalance(Fungible fungible, uint256 amount) public {
//         fungibleBalance[fungible] += amount;
//     }
// }
