#!/bin/bash

INVARIANTS=(
    
    # ========== COMMON INVARIANTS ==========
    
    "lastInterestCollectionNotInFuture"
    "liquidityOnsetsNotInFuture"
    "positionsWithDataMustHaveOwner"
    "totalDebtNotExceedLimit"
    "debtOutstandingWithinSupply"
    "noDebtTokenAllowances"
    "outstandingDebtPairedWithAvailableBase"
    "singlePositionDebtSolvency"
    
    # ========== FUNGIBLE INVARIANTS ==========
    
    "fungibleArrayElementsBeyondLengthAreEmpty"
    "allFungiblesAreUnique"
    "fungiblesHaveNonZeroBalance"
    "fungiblesHaveCorrectIndex"
    "fungibleIndexesWithinBounds"
    "fungibleStatesPointToCorrectPosition"
    "fungiblePositionBalancesBacked"
    "baseTokenPositionBalancesBacked"
    
    # ========== NON-FUNGIBLE INVARIANTS ==========
    
    "nonFungibleArrayElementsBeyondLengthAreEmpty"
    "allNonFungiblesAreUnique"
    "nonFungiblesOwnedByLicredity"
    
    # ========== ISSUES - KNOWN PROBLEMS ==========
    
    # The following invariants are commented out due to known issues
    # Uncomment to test after fixes are applied
    
    # https://github.com/Cyfrin/audit-2025-08-licredity/issues/26
    # "fungiblesHaveNonZeroBalance"
    
    # https://github.com/Cyfrin/audit-2025-08-licredity/issues/22  
    # "fungibleStatesPointToCorrectPosition"
    # "fungiblesHaveCorrectIndex"
    
    # https://github.com/Cyfrin/audit-2025-08-licredity/issues/12
    # "positionsWithDataMustHaveOwner"
    # "debtOutstandingWithinSupply"
)

for invariant in "${INVARIANTS[@]}"; do
    certoraRun certora/confs/licredity_valid_state_single.conf --rule "$invariant" --msg "$invariant"
done