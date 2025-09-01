// CVL implementation of FullMath library potentially reducing run-time

methods {
    function _.fullMulDiv(uint256 x, uint256 y, uint256 d) internal 
        => mulDivDownCVL(x, y, d) expect uint256 ALL;
        
    function _.fullMulDivUp(uint256 x, uint256 y, uint256 d) internal 
        => mulDivUpCVL(x, y, d) expect uint256 ALL;
}

// Computes floor(x * y / z) without overflow
// In CVL, we use mathint (unbounded integers) to avoid overflow
function mulDivDownCVL(uint256 x, uint256 y, uint256 z) returns uint256 {

    ASSERT(z != 0, "DivisionByZero");
    
    // Use mathint to prevent overflow during multiplication
    mathint product = to_mathint(x) * to_mathint(y);
    mathint result = product / to_mathint(z);
    
    // Result must fit in uint256    
    return require_uint256(result);
}

// Computes ceil(x * y / z) without overflow
// Rounds up the result of the division
function mulDivUpCVL(uint256 x, uint256 y, uint256 z) returns uint256 {

    ASSERT(z != 0, "DivisionByZero");
    
    // Use mathint to prevent overflow during multiplication and addition
    mathint product = to_mathint(x) * to_mathint(y);
    mathint result = (product + to_mathint(z) - 1) / to_mathint(z);
    
    // Result must fit in uint256    
    return require_uint256(result);
}