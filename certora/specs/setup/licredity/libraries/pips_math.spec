// CVL specification for PipsMath library potentially reducing run-time

methods {
    function PipsMath.pipsMulUp(uint256 x, uint256 y) internal returns (uint256) 
        => pipsMulUpCVL(x, y);
}

// Unit pips constant (1 million pips = 100%)
definition UNIT_PIPS_CVL() returns mathint = 1000000; // 1,000,000 pips = 100%

// Multiplies x by y (in pips) and divides by UNIT_PIPS, rounding up
// Example: pipsMulUp(100, 500000) = 50 (100 * 0.5 = 50)
function pipsMulUpCVL(mathint x, mathint y) returns uint256 {
    
    // Use mathint to prevent overflow during multiplication
    mathint product = x * y;
    
    // Check for overflow in original calculation
    // If y != 0 and product / y != x, then overflow occurred
    ASSERT(y == 0 || product / y == x, "MultiplicationOverflow");
    
    // Calculate the result with rounding up
    // Equivalent to: (product / UNIT_PIPS) + (product % UNIT_PIPS != 0 ? 1 : 0)
    mathint remainder = product % UNIT_PIPS_CVL();
    mathint result = product / UNIT_PIPS_CVL() + (remainder != 0 ? 1 : 0);
    
    // Result must fit in uint256    
    return require_uint256(result);
}