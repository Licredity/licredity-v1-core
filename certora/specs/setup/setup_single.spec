// Main setup file with single position support

import "./licredity/licredity.spec";      // Main Licredity contract methods and configuration
import "./licredity/storage_hooks_position_single.spec";
import "./licredity/libraries/locker_single.spec";

import "./erc20_cvl.spec";                // CVL implementation for ERC20 tokens
import "./erc721_cvl.spec";               // CVL implementation for ERC721 tokens

import "./helper.spec";                   // Helper functions and assertion utilities

// ========== VERIFICATION BOUNDS ==========

// UNSAFE: Max number of supported loop iterations (matches loop_iter in config)
definition LOOP_ITER_CVL() returns mathint = 3; 

// SAFE: Defines which functions to exclude from verification in parametric rules and invariants
definition EXCLUDED_FUNCTION(method f) returns bool = 
    f.isView || f.isPure || LICREDITY_EXCLUDED_FUNCTION(f);

// SAFE: Timestamp bounds for realistic blockchain scenarios
definition MIN_BLOCK_TIMESTAMP() returns mathint = max_uint16;  // ~18 hours after epoch
definition MAX_BLOCK_TIMESTAMP() returns mathint = max_uint32;  // Valid until year 2106

// ========== ENVIRONMENT SETUP FUNCTIONS ==========

// Sets up common environmental constraints to reduce state space
// and focus verification on realistic transaction scenarios
function setupEnv(env e) {
    require(e.msg.sender != 0, "Assume sender is not zero address");
    require(e.msg.sender != currentContract, "Assume sender is not the contract itself");
    require(e.block.timestamp >= MIN_BLOCK_TIMESTAMP() && e.block.timestamp < MAX_BLOCK_TIMESTAMP(), 
        "Assume realistic timestamp bounds"); 
    require(e.block.number != 0, "Assume block number is not zero");
}

// Ensures same environment for function calls in invariants
function requireSameEnv(env e1, env e2) {
    require(e1.block.number == e2.block.number, "Assume same block number for both environments");
    require(e1.block.timestamp == e2.block.timestamp, "Assume same timestamp for both environments"); 
    require(e1.msg.sender == e2.msg.sender, "Assume same sender for both environments");
    require(e1.msg.value == e2.msg.value, "Assume same msg.value for both environments");
}

// ========== MAIN SETUP FUNCTION ==========

// Executes all necessary setup functions for verification
function setup(env e) {

    // Constructor's assumption
    require(_Licredity.baseFungible != _Licredity, "Base fungible must be different from debt token");

    // Establishes reasonable bounds for transaction environment
    setupEnv(e);

    // Initialize valid state for ERC20 tokens
    setupERC20();   

    // Initialize valid state for ERC721 tokens
    setupERC721();
}