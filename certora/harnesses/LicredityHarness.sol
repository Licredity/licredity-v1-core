// SPDX-License-Identifier: MIT
pragma solidity =0.8.30;

import "../../src/Licredity.sol";
import {NonFungible, NonFungibleLibrary} from "../../src/types/NonFungible.sol";
import {IERC20} from "@forge-std/interfaces/IERC20.sol";
import {IERC721} from "@forge-std/interfaces/IERC721.sol";

contract LicredityHarness is Licredity {
    constructor(
        address baseToken,
        address _poolManager,
        address _governor,
        string memory name,
        string memory symbol
    ) Licredity(baseToken, _poolManager, _governor, name, symbol) {}
    
    // Helper function for Certora to transfer native currency
    function transferNative(address recipient, uint256 amount) external {
        require(address(this).balance >= amount, "Insufficient native balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Native transfer failed");
    }
    
    // Harness function for Certora: stage fungible, transfer tokens, then exchange
    // This simulates the complete flow for exchanging fungibles
    function stageTransferExchange(
        Fungible fungible,
        address sender,
        uint256 amount,
        address recipient,
        bool baseForDebt
    ) external payable {
        stageFungible(fungible);
        
        if (!fungible.isNative()) {
            IERC20(Fungible.unwrap(fungible)).transferFrom(sender, address(this), amount);
        }
        
        exchangeFungible(recipient, baseForDebt);
    }
    
    // Harness function for Certora: stage fungible, transfer tokens, then deposit to position
    // This simulates the complete flow for depositing fungibles to a position
    function stageTransferDeposit(
        Fungible fungible,
        address sender,
        uint256 amount,
        uint256 positionId
    ) external payable {
        stageFungible(fungible);
        
        if (!fungible.isNative()) {
            IERC20(Fungible.unwrap(fungible)).transferFrom(sender, address(this), amount);
        }
        
        depositFungible(positionId);
    }
    
    // Harness function for Certora: stage non-fungible, transfer NFT, then deposit to position
    // This simulates the complete flow for depositing non-fungibles to a position
    function stageTransferDepositNonFungible(
        NonFungible nonFungible,
        uint256 positionId
    ) external {
        stageNonFungible(nonFungible);
        
        address nftContract = NonFungibleLibrary.tokenAddress(nonFungible);
        uint256 tokenId = NonFungibleLibrary.tokenId(nonFungible);
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);
        
        depositNonFungible(positionId);
    }
    
    // Harness for withdrawFungible with unlock simulation
    function withdrawFungibleHarness(uint256 positionId, address recipient, Fungible fungible, uint256 amount) external {
        // Collect interest as would happen in unlock
        _collectInterest(false);
        
        // Call the actual withdrawFungible function
        withdrawFungible(positionId, recipient, fungible, amount);
        
        // Appraise position as would happen at end of unlock
        Position storage position = positions[positionId];
        (,,, bool isHealthy) = _appraisePosition(position);
        require(isHealthy, "Position unhealthy after withdrawFungible");
    }
    
    // Harness for withdrawNonFungible with unlock simulation  
    function withdrawNonFungibleHarness(uint256 positionId, address recipient, NonFungible nonFungible) external {
        // Collect interest as would happen in unlock
        _collectInterest(false);
        
        // Call the actual withdrawNonFungible function
        withdrawNonFungible(positionId, recipient, nonFungible);
        
        // Appraise position as would happen at end of unlock
        Position storage position = positions[positionId];
        (,,, bool isHealthy) = _appraisePosition(position);
        require(isHealthy, "Position unhealthy after withdrawNonFungible");
    }
    
    // Harness for increaseDebtShare with unlock simulation
    function increaseDebtShareHarness(uint256 positionId, uint256 delta, address recipient) external returns (uint256 amount) {
        // Collect interest as would happen in unlock
        _collectInterest(false);
        
        // Call the actual increaseDebtShare function
        amount = increaseDebtShare(positionId, delta, recipient);
        
        // Appraise position as would happen at end of unlock
        Position storage position = positions[positionId];
        (,,, bool isHealthy) = _appraisePosition(position);
        require(isHealthy, "Position unhealthy after increaseDebtShare");
    }
    
    // Harness for seize with unlock simulation
    function seizeHarness(uint256 positionId, address recipient) external returns (uint256 shortfall) {
        // Collect interest as would happen in unlock
        _collectInterest(false);
        
        // Call the actual seize function
        shortfall = seize(positionId, recipient);
        
        // Appraise position as would happen at end of unlock (seize changes owner so position should be healthy for new owner)
        Position storage position = positions[positionId];
        (,,, bool isHealthy) = _appraisePosition(position);
        // Note: seize is special - it can leave position unhealthy if it was underwater
    }
}