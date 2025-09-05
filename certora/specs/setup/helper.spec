// Helper contract methods and utilities for CVL assertions and type conversions

using HelperCVL as _HelperCVL;

methods {
    function _HelperCVL.assertOnFailure(bool success) external envfree;
}

// ========== ASSERTION HELPER ==========

// Trigger a Solidity assertion from CVL
function ASSERT(bool expression, string _message) {
    _HelperCVL.assertOnFailure(expression);
}