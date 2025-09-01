// CVL implementation defining position bounds and ghost state for position management

definition MAX_POSITIONS() returns mathint = 2;

// Return true when positionId is within the bounded position set
definition POSITION_BOUNDS(mathint positionId) returns bool = 
    ghostPositionIds[0] == positionId
    || ghostPositionIds[1] == positionId
    ;

// Assume MAX_POSITIONS different position IDs
persistent ghost ghostPositions(mathint) returns uint256 {
    // All positions in the range are different
    axiom forall mathint i. forall mathint j. 
        i >= 0 && i < MAX_POSITIONS() && j >= 0 && j < MAX_POSITIONS() && i != j
        => ghostPositions(i) != ghostPositions(j);    
}

persistent ghost mapping (mathint => uint256) ghostPositionIds {
    axiom forall mathint i. ghostPositionIds[i] == ghostPositions(i);
}

// Check position solvency - total debt shares equal sum of position debt shares
definition POSITION_DEBT_SOLVENCY() returns bool =
    ghostLiTotalDebtShare128 == INITIAL_DEBT_SHARE_CVL() 
        + ghostLiPositionDebtShare128[ghostPositionIds[0]]
        + ghostLiPositionDebtShare128[ghostPositionIds[1]];
