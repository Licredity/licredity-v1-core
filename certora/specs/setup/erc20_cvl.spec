// CVL implementation of ERC20 tokens supporting up to 4 tokens and 5 users each
// UNSAFE: Bounded implementation - only supports predefined token and account sets

methods {
    function _.balanceOf(address account) external 
        => balanceOfERC20CVL(calledContract, account) expect uint256;
    
    function _.decimals() external
        => require_uint8(ghostErc20Decimals8[calledContract]) expect uint8;
    
    function _.totalSupply() external 
        => require_uint256(ghostERC20TotalSupply256[calledContract]) expect uint256;
    
    function _.approve(address spender, uint256 amount) external with (env e)
        => approveERC20CVL(calledContract, e.msg.sender, spender, amount) expect bool;
    
    function _.transfer(address to, uint256 amount) external with (env e)
        => transferERC20CVL(calledContract, e.msg.sender, to, amount) expect bool;
    
    function _.transferFrom(address from, address to, uint256 amount) external with (env e)
        => transferFromERC20CVL(calledContract, from, to, amount) expect bool;

    function _.allowance(address owner, address spender) external 
        => require_uint256(ghostERC20Allowances128[calledContract][owner][spender]) expect uint256;
}

// ========== TOKEN BOUNDS AND CONFIGURATION (DISABLED HERE) ==========

definition MAX_ERC20_TOKENS() returns mathint = 4;

// Return true when token address is within the bounded token set
definition ERC20_TOKEN_BOUNDS(address token) returns bool = 
    ghostErc20TokensValues[0] == token
    || ghostErc20TokensValues[1] == token
    || ghostErc20TokensValues[2] == token
    || ghostErc20TokensValues[3] == token
    ;

// Assume MAX_ERC20_TOKENS different token addresses
persistent ghost ghostErc20Tokens(mathint) returns address {
    // All tokens in the range are different (no duplicates)
    axiom forall mathint i. forall mathint j. 
        i >= 0 && i < MAX_ERC20_TOKENS() && j >= 0 && j < MAX_ERC20_TOKENS() && i != j
        => ghostErc20Tokens(i) != ghostErc20Tokens(j);
}

// Mapping for direct access to token addresses
persistent ghost mapping (mathint => address) ghostErc20TokensValues {
    axiom forall mathint i. ghostErc20TokensValues[i] == ghostErc20Tokens(i);    
}

// ========== ACCOUNT BOUNDS AND CONFIGURATION ==========
// UNSAFE: Limited to 5 users per token for verification performance

definition MAX_ERC20_USERS() returns mathint = 5;

// Return true when address is an existing ERC20 account
definition ERC20_ACCOUNT_BOUNDS(address token, address account) returns bool = 
    ghostErc20AccountsValues[token][0] == account
    || ghostErc20AccountsValues[token][1] == account
    || ghostErc20AccountsValues[token][2] == account
    || ghostErc20AccountsValues[token][3] == account
    || ghostErc20AccountsValues[token][4] == account
    ;

// Assume MAX_ERC20_USERS different accounts per token
persistent ghost ghostErc20Accounts(address, mathint) returns address {
    // All accounts in the range are different (no duplicates per token)
    axiom forall address token. forall mathint i. forall mathint j. 
        i >= 0 && i < MAX_ERC20_USERS() && j >= 0 && j < MAX_ERC20_USERS() && i != j
        => ghostErc20Accounts(token, i) != ghostErc20Accounts(token, j);
}

// Mapping for direct access to account addresses
persistent ghost mapping (address => mapping (mathint => address)) ghostErc20AccountsValues {
    // Synchronize with ghostErc20Accounts
    axiom forall address token. forall mathint i. 
        ghostErc20AccountsValues[token][i] == ghostErc20Accounts(token, i);
    // All addresses are non-zero (prevents zero address issues)
    axiom forall address token. forall mathint i. 
        ghostErc20AccountsValues[token][i] != 0;
}

// ========== HELPER FUNCTIONS AND SETUP ==========

// Helper: Check if tokens were transferred from one address to another
definition ERC20_TRANSFERRED(
    mathint senderBalanceBefore,
    mathint senderBalanceAfter,
    mathint receiverBalanceBefore,
    mathint receiverBalanceAfter
) returns bool = 
    senderBalanceAfter < senderBalanceBefore 
    && receiverBalanceAfter > receiverBalanceBefore
    && (senderBalanceBefore - senderBalanceAfter) == (receiverBalanceAfter - receiverBalanceBefore)
    && (senderBalanceBefore - senderBalanceAfter) > 0;

// Use as a requirement in setup function
definition ERC20_TOTAL_SUPPLY_SOLVENCY() returns bool =
    forall address token.
        ghostERC20TotalSupply256[token] 
        == ghostERC20Balances128[token][ghostErc20AccountsValues[token][0]] 
        + ghostERC20Balances128[token][ghostErc20AccountsValues[token][1]] 
        + ghostERC20Balances128[token][ghostErc20AccountsValues[token][2]] 
        + ghostERC20Balances128[token][ghostErc20AccountsValues[token][3]] 
        + ghostERC20Balances128[token][ghostErc20AccountsValues[token][4]];

function setupERC20() {
    
    require(ERC20_TOTAL_SUPPLY_SOLVENCY(), "Assume total supply equals sum of all balances for ERC20 tokens");

    require(forall address token. ghostErc20Decimals8[token] >= 6 && ghostErc20Decimals8[token] <= 18, 
        "Assume realistic token decimals between 6 and 18"
    );    
}

//
// Handle external functions
//

persistent ghost mapping(address => uint8) ghostErc20Decimals8;

persistent ghost mapping(address => mapping(address => mathint)) ghostERC20Balances128 {
    init_state axiom forall address token. forall address account. 
        ghostERC20Balances128[token][account] == 0;
    axiom forall address token. forall address account. 
        ghostERC20Balances128[token][account] >= 0 
            && ghostERC20Balances128[token][account] <= max_uint128;
}

persistent ghost mapping(address => mapping(address => mapping(address => mathint))) ghostERC20Allowances128 {
    init_state axiom forall address token. forall address owner. forall address spender. 
        ghostERC20Allowances128[token][owner][spender] == 0;
    axiom forall address token. forall address owner. forall address spender. 
        ghostERC20Allowances128[token][owner][spender] >= 0 
        && ghostERC20Allowances128[token][owner][spender] <= max_uint128;
}

persistent ghost mapping(address => mathint) ghostERC20TotalSupply256 {
    init_state axiom forall address token. ghostERC20TotalSupply256[token] == 0;
    axiom forall address token. ghostERC20TotalSupply256[token] >= 0 
        && ghostERC20TotalSupply256[token] <= max_uint256;
}

function balanceOfERC20CVL(address token, address account) returns uint256 {

    require(ERC20_ACCOUNT_BOUNDS(token, account), "Assume account is within predefined account set");

    ASSERT(token != 0, "Zero token address");

    return require_uint256(ghostERC20Balances128[token][account]);
}

function approveERC20CVL(address token, address owner, address spender, uint256 amount) returns bool {

    require(ERC20_ACCOUNT_BOUNDS(token, owner) && ERC20_ACCOUNT_BOUNDS(token, spender), 
        "Assume owner and spender are within predefined account set");

    ASSERT(token != 0, "Zero token address");
    ASSERT(owner != 0 && spender != 0, "InvalidZeroAddress");

    ghostERC20Allowances128[token][owner][spender] = require_uint256(amount);
    
    return true;
}

function transferERC20CVL(address token, address from, address to, uint256 amount) returns bool {

    require(ERC20_ACCOUNT_BOUNDS(token, from) && ERC20_ACCOUNT_BOUNDS(token, to), 
        "Assume from and to are within predefined account set");
        
    ASSERT(token != 0, "Zero token address");
    ASSERT(from != 0 && to != 0, "InvalidZeroAddress");
    ASSERT(ghostERC20Balances128[token][from] >= amount, "InsufficientBalance");
    
    ghostERC20Balances128[token][from] = require_uint256(ghostERC20Balances128[token][from] - amount);
    ghostERC20Balances128[token][to] = require_uint256(ghostERC20Balances128[token][to] + amount);
    
    return true;
}

function transferFromERC20CVL(address token, address from, address to, uint256 amount) returns bool {

    require(ERC20_ACCOUNT_BOUNDS(token, from) && ERC20_ACCOUNT_BOUNDS(token, to), 
        "Assume from and to are within predefined account set");

    ASSERT(token != 0, "Zero token address");
    ASSERT(from != to && from != 0 && to != 0, "InvalidTransferParameters");
    ASSERT(ghostERC20Allowances128[token][from][currentContract] == max_uint256 
        || ghostERC20Allowances128[token][from][currentContract] >= amount, "InsufficientAllowance");
    ASSERT(ghostERC20Balances128[token][from] >= amount, "InsufficientBalance");

    if(ghostERC20Allowances128[token][from][currentContract] != max_uint256) {
        ghostERC20Allowances128[token][from][currentContract] 
            = require_uint256(ghostERC20Allowances128[token][from][currentContract] - amount);
    }
    
    ghostERC20Balances128[token][from] = require_uint256(ghostERC20Balances128[token][from] - amount);
    ghostERC20Balances128[token][to] = require_uint256(ghostERC20Balances128[token][to] + amount);

    return true;
}