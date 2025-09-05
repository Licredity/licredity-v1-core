// Valid state invariants that must hold in every reachable state of the Licredity protocol

import "./setup/setup_multi.spec";

// Setup function that includes all valid state requirements
function setupValidState(env e) {

    setup(e);
    
    requireInvariant invalidPositionsAreEmpty(e);
    requireInvariant positionDebtSolvency(e);
    requireInvariant positionsBeyondCountAreEmpty(e);
}

// Use in invariants preserved block
function SETUP(env e, env eFunc) {
    requireSameEnv(e, eFunc); 
    setupValidState(e);
}

// VS-LI-20: Technical invariant: Data for invalid positions must be empty
// All data for positions outside the bounded set must be zero
invariant invalidPositionsAreEmpty(env e)
    forall uint256 positionId. forall mathint i. forall LicredityHarness.Fungible fungible.
        !POSITION_BOUNDS(positionId) => (
            // Core position fields
            ghostLiPositionOwner[positionId] == 0
            && ghostLiPositionDebtShare128[positionId] == 0
            // Array elements
            && ghostLiPositionFungiblesLength[positionId] == 0
            && ghostLiPositionNonFungiblesLength[positionId] == 0
            && ghostLiPositionFungibles[positionId][i] == 0
            && ghostLiPositionNonFungibles[positionId][i] == to_bytes32(0)
        )
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-21: Position debt solvency - total debt shares must equal initial shares plus position debts
// The total debt shares in the system must always equal the initial locked 1e6 shares
// plus the sum of all debt shares across the bounded position set
invariant positionDebtSolvency(env e)
    POSITION_DEBT_SOLVENCY()
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-22: Positions beyond positionCount must be completely empty
// All position data for IDs greater than positionCount must be zero/empty
invariant positionsBeyondCountAreEmpty(env e)
    forall uint256 positionId. forall uint8 i. forall LicredityHarness.Fungible fungible.
        positionId == 0 || positionId > ghostLiPositionCount64 => (
            // Core position fields are empty
            ghostLiPositionOwner[positionId] == 0
            && ghostLiPositionDebtShare128[positionId] == 0
            // Fungible array elements are empty
            && ghostLiPositionFungibles[positionId][i] == 0
            // NonFungible array elements and their components are empty
            && ghostLiPositionNonFungibles[positionId][i] == to_bytes32(0)
        )
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }