// Verify the correctness of transitions between valid states. Firstly, we confirm that the valid states change
// according to their correct order in the state machine. Then, we verify that the transitions only occur under 
// the right conditions, like calls to specific functions or time elapsing.

import "./valid_state_single.spec";

// ST-LI-01: Position modifications that could reduce health MUST register in locker
// When a position's debt increases (borrow) or collateral decreases (withdraw), 
// it must be registered for health validation at the end of the unlock operation.
// Operations that improve health (deposit, repay) do not require registration.
rule transitionPositionModificationRequiresRegistration(
    env e, method f, calldataarg args, LicredityHarness.Fungible fungible
    ) filtered { f -> !EXCLUDED_FUNCTION(f) } {
    
    setupValidState(e);
    
    require(fungible != _Licredity, "Assume fungible is not the debt token (Licredity itself)");
        
    // Remember position state before
    mathint debtBefore = ghostLiPositionDebtShare128;
    mathint fungibleBalanceBefore = ghostLiPositionFungibleStatesBalance112[fungible];
    mathint nonFungiblesLengthBefore = ghostLiPositionNonFungiblesLength;
    
    // Execute function
    f(e, args);
    
    // Check if position was modified in a way that could reduce health
    bool debtIncreased = ghostLiPositionDebtShare128 > debtBefore;
    
    // Check for collateral withdrawal (fungible balance decrease or NFT removal)
    // Note: We exclude debt token since its withdrawal is part of decreaseDebtShare
    bool collateralWithdrawn = 
        ghostLiPositionFungibleStatesBalance112[fungible] < fungibleBalanceBefore ||
        ghostLiPositionNonFungiblesLength < nonFungiblesLengthBefore;
    
    // If position health could have been reduced, it must be registered
    // Functions that register: withdrawFungible, withdrawNonFungible, increaseDebtShare (borrow), seize
    // Functions that don't: depositFungible, depositNonFungible, decreaseDebtShare (they improve health)
    assert(debtIncreased || collateralWithdrawn => ghostLockerRegisteredItems,
        "Position modified in a way that could reduce health but not registered for validation");
}

// ST-LI-02: Debt operations must collect interest when time has elapsed
// When any debt operation modifies totalDebtBalance or totalDebtShare,
// if time has passed since the last interest collection, the function must
// first collect interest by updating lastInterestCollectionTimestamp.
// This ensures borrowers cannot repay debt using stale ratios to avoid accrued interest.
rule transitionDebtChangesRequireInterestAccrual(
    env e, method f, calldataarg args
    ) filtered { f -> !EXCLUDED_FUNCTION(f) } {
    
    setupValidState(e);
    
    // Track state before operation
    mathint totalDebtBalanceBefore = ghostLiTotalDebtBalance128;
    mathint totalDebtShareBefore = ghostLiTotalDebtShare128;
    mathint lastCollectionBefore = ghostLiLastInterestCollectionTimestamp32;
    
    // Execute function
    f(e, args);
    
    // Check if a debt operation occurred (changes to debt balance or shares)
    bool debtOperationOccurred = 
        ghostLiTotalDebtBalance128 != totalDebtBalanceBefore ||
        ghostLiTotalDebtShare128 != totalDebtShareBefore;
    
    // Check if time has elapsed since last interest collection
    bool timeElapsed = e.block.timestamp > lastCollectionBefore;
        
    // Verify: If debt changes AND time elapsed => interest must be collected (timestamp updated)
    assert(debtOperationOccurred && timeElapsed => ghostLiLastInterestCollectionTimestamp32 == e.block.timestamp, 
        "Debt operation occurred without collecting interest (timestamp not updated)");
}