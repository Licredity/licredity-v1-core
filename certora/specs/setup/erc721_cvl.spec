// CVL implementation of ERC721 tokens supporting up to 3 users and 5 tokens each
// UNSAFE: Bounded implementation - only supports predefined token and account sets

methods {
    // Duplicate with ERC20
    // function _.balanceOf(address owner) external 
    //    => balanceOfERC721CVL(calledContract, owner) expect uint256;
    
    function _.ownerOf(uint256 tokenId) external 
        => ownerOfERC721CVL(calledContract, tokenId) expect address;
    
    function _.safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external with (env e)
        => transferFromERC721CVL(calledContract, e.msg.sender, from, to, tokenId) expect void;
    
    function _.safeTransferFrom(address from, address to, uint256 tokenId) external with (env e)
        => transferFromERC721CVL(calledContract, e.msg.sender, from, to, tokenId) expect void;
    
    // Duplicate with ERC20
    // function _.transferFrom(address from, address to, uint256 tokenId) external with (env e)
    //    => transferFromERC721CVL(calledContract, e.msg.sender, from, to, tokenId) expect void;
    
    // Duplicate with ERC20
    // function _.approve(address to, uint256 tokenId) external with (env e)
    //    => approveERC721CVL(calledContract, e.msg.sender, to, tokenId) expect void;
    
    function _.setApprovalForAll(address operator, bool approved) external with (env e)
        => setApprovalForAllERC721CVL(calledContract, e.msg.sender, operator, approved) expect void;
    
    function _.getApproved(uint256 tokenId) external 
        => getApprovedERC721CVL(calledContract, tokenId) expect address;
    
    function _.isApprovedForAll(address owner, address operator) external 
        => isApprovedForAllERC721CVL(calledContract, owner, operator) expect bool;
}

// ========== ACCOUNT BOUNDS AND CONFIGURATION ==========
// UNSAFE: Limited to 3 users for verification performance

definition MAX_ERC721_USERS() returns mathint = 3;

// Return true when address is existing ERC721 account
definition ERC721_ACCOUNT_BOUNDS(address contract, address account) returns bool = 
    account == ghostErc721AccountsValues[contract][0]
    || account == ghostErc721AccountsValues[contract][1]
    || account == ghostErc721AccountsValues[contract][2]
    ;

persistent ghost ghostErc721Accounts(address, mathint) returns address {
    // All accounts in the range are different
    axiom forall address token. forall mathint i. forall mathint j. 
        i >= 0 && i < MAX_ERC721_USERS() && j >= 0 && j < MAX_ERC721_USERS() && i != j => (
            ghostErc721Accounts(token, i) != ghostErc721Accounts(token, j)
        );
}

persistent ghost mapping (address => mapping (mathint => address)) ghostErc721AccountsValues {
    axiom forall address token. forall mathint i. 
        ghostErc721AccountsValues[token][i] == ghostErc721Accounts(token, i);
}

// ========== TOKEN BOUNDS AND CONFIGURATION ==========
// UNSAFE: Limited to 5 tokens per contract for verification performance

definition MAX_ERC721_TOKENS() returns mathint = 5;

// Return true when tokenId is existing ERC721 token
definition ERC721_TOKEN_BOUNDS(address contract, mathint tokenId) returns bool = 
    tokenId == ghostErc721TokensValues[contract][0]
    || tokenId == ghostErc721TokensValues[contract][1]
    || tokenId == ghostErc721TokensValues[contract][2]
    || tokenId == ghostErc721TokensValues[contract][3]
    || tokenId == ghostErc721TokensValues[contract][4]
    ;

// Assume MAX_ERC721_TOKENS different token IDs per contract
persistent ghost ghostErc721Tokens(address, mathint) returns mathint {
    // All tokens in the range are different (no duplicates)
    axiom forall address contract. forall mathint i. forall mathint j. 
        i >= 0 && i < MAX_ERC721_TOKENS() && j >= 0 && j < MAX_ERC721_TOKENS() && i != j => (
            ghostErc721Tokens(contract, i) != ghostErc721Tokens(contract, j)
        );    
}

// Mapping for direct access to token IDs
persistent ghost mapping (address => mapping (mathint => mathint)) ghostErc721TokensValues {
    axiom forall address contract. forall mathint i. 
        ghostErc721TokensValues[contract][i] == ghostErc721Tokens(contract, i);
    // Token IDs bounded to uint128 for verification performance
    axiom forall address contract. forall mathint i. 
        ghostErc721TokensValues[contract][i] >= 0 && ghostErc721TokensValues[contract][i] <= max_uint128;
}

// ========== HELPER FUNCTIONS ==========

// Helper to count tokens owned by an account
definition COUNT_TOKENS_OWNED(address contract, address account) returns mathint = (
    (ghostERC721Owners[contract][ghostErc721TokensValues[contract][0]] == account ? 1 : 0)
    + (ghostERC721Owners[contract][ghostErc721TokensValues[contract][1]] == account ? 1 : 0) 
    + (ghostERC721Owners[contract][ghostErc721TokensValues[contract][2]] == account ? 1 : 0) 
    + (ghostERC721Owners[contract][ghostErc721TokensValues[contract][3]] == account ? 1 : 0) 
    + (ghostERC721Owners[contract][ghostErc721TokensValues[contract][4]] == account ? 1 : 0)
);

// ========== SOLVENCY REQUIREMENTS ==========

// Ensure each account's balance equals the count of tokens they own
definition ERC721_OWNER_TOKENS_SOLVENCY(address contract) returns bool = (
    ghostERC721Balances256[contract][ghostErc721AccountsValues[contract][0]] 
        == COUNT_TOKENS_OWNED(contract, ghostErc721AccountsValues[contract][0])
    && 
    ghostERC721Balances256[contract][ghostErc721AccountsValues[contract][1]] 
        == COUNT_TOKENS_OWNED(contract, ghostErc721AccountsValues[contract][1])
    && 
    ghostERC721Balances256[contract][ghostErc721AccountsValues[contract][2]] 
        == COUNT_TOKENS_OWNED(contract, ghostErc721AccountsValues[contract][2])
    &&
    // Empty balances for all other owners
    (forall address owner. !ERC721_ACCOUNT_BOUNDS(contract, owner) 
        => ghostERC721Balances256[contract][owner] == 0)
    && 
    // Empty owners and approvals for all other tokens
    (forall mathint tokenId. !ERC721_TOKEN_BOUNDS(contract, tokenId) => (
        ghostERC721Owners[contract][tokenId] == 0 && 
        ghostERC721TokenApprovals[contract][tokenId] == 0
    ))
    && 
    // Empty operators for all other owners
    (forall address owner. forall address operator. !ERC721_ACCOUNT_BOUNDS(contract, owner) => 
        ghostERC721OperatorApprovals[contract][owner][operator] == false
    )
);

function setupERC721() {
    // Assume valid state only for bounded contracts
    require(forall address contract. ERC721_OWNER_TOKENS_SOLVENCY(contract), 
        "Assume each account's balance must equal the count of tokens they own for bounded contracts"
    );
}

// ========== GHOST STATE FOR ERC721 TRACKING ==========

// Token ownership mapping: contract -> tokenId -> owner
persistent ghost mapping(address => mapping(mathint => address)) ghostERC721Owners {
    init_state axiom forall address contract. forall mathint tokenId. 
        ghostERC721Owners[contract][tokenId] == 0;
}

// Balance mapping: contract -> owner -> balance
persistent ghost mapping(address => mapping(address => mathint)) ghostERC721Balances256 {
    init_state axiom forall address contract. forall address owner. 
        ghostERC721Balances256[contract][owner] == 0;
    axiom forall address contract. forall address owner. 
        ghostERC721Balances256[contract][owner] >= 0 && ghostERC721Balances256[contract][owner] <= max_uint256;
}

// Token approval mapping: contract -> tokenId -> approved address
persistent ghost mapping(address => mapping(mathint => address)) ghostERC721TokenApprovals {
    init_state axiom forall address contract. forall mathint tokenId. 
        ghostERC721TokenApprovals[contract][tokenId] == 0;
}

// Operator approval mapping: contract -> owner -> operator -> approved
persistent ghost mapping(address => mapping(address => mapping(address => bool))) ghostERC721OperatorApprovals {
    init_state axiom forall address contract. forall address owner. forall address operator. 
        ghostERC721OperatorApprovals[contract][owner][operator] == false;
}

// ========== CVL FUNCTION IMPLEMENTATIONS ==========

function balanceOfERC721CVL(address contract, address owner) returns uint256 {

    require(ERC721_ACCOUNT_BOUNDS(contract, owner), "Assume owner is within predefined account set");

    ASSERT(contract != 0, "ERC721: token zero address");    
    ASSERT(owner != 0, "ERC721: balance query for the zero address");
    
    return require_uint256(ghostERC721Balances256[contract][owner]);
}

function ownerOfERC721CVL(address contract, mathint tokenId) returns address {

    require(ERC721_TOKEN_BOUNDS(contract, tokenId), "Assume tokenId is within predefined token set");

    ASSERT(contract != 0, "ERC721: token zero address");
    
    address owner = ghostERC721Owners[contract][tokenId];
    ASSERT(owner != 0, "ERC721: owner query for nonexistent token");
    
    return owner;
}

function getApprovedERC721CVL(address contract, uint256 tokenId) returns address {

    require(ERC721_TOKEN_BOUNDS(contract, tokenId), "Assume tokenId is within predefined token set");

    ASSERT(contract != 0, "ERC721: token zero address");
    ASSERT(ghostERC721Owners[contract][tokenId] != 0, "ERC721: approved query for nonexistent token");
    
    return ghostERC721TokenApprovals[contract][tokenId];
}

function isApprovedForAllERC721CVL(address contract, address owner, address operator) returns bool {

    require(ERC721_ACCOUNT_BOUNDS(contract, owner) && ERC721_ACCOUNT_BOUNDS(contract, operator), 
        "Assume owner and operator are within predefined account set");

    ASSERT(contract != 0, "ERC721: token zero address");
    
    return ghostERC721OperatorApprovals[contract][owner][operator];
}

function approveERC721CVL(address contract, address sender, address to, uint256 tokenId) {

    require(ERC721_TOKEN_BOUNDS(contract, tokenId), "Assume tokenId is within predefined token set");
    require(ERC721_ACCOUNT_BOUNDS(contract, sender), "Assume sender and to are within predefined account set");

    ASSERT(contract != 0, "ERC721: token zero address");
    
    address owner = ghostERC721Owners[contract][tokenId];
    ASSERT(owner != 0, "ERC721: approve for nonexistent token");
    ASSERT(sender == owner || ghostERC721OperatorApprovals[contract][owner][sender], 
        "ERC721: approve caller is not owner nor approved for all");
    ASSERT(owner != to, "ERC721: approval to current owner");
    
    ghostERC721TokenApprovals[contract][tokenId] = to;
}

function setApprovalForAllERC721CVL(address contract, address owner, address operator, bool approved) {

    require(ERC721_ACCOUNT_BOUNDS(contract, owner), "Assume owner and operator are within predefined account set");

    ASSERT(contract != 0, "ERC721: token zero address");    
    ASSERT(operator != 0, "ERC721: approve to the zero address");
    ASSERT(owner != operator, "ERC721: approve to caller");
    
    ghostERC721OperatorApprovals[contract][owner][operator] = approved;
}

function transferFromERC721CVL(address contract, address sender, address from, address to, mathint tokenId) {
    
    require(ERC721_TOKEN_BOUNDS(contract, tokenId), "Assume tokenId is within predefined token set");
    require(ERC721_ACCOUNT_BOUNDS(contract, from) && ERC721_ACCOUNT_BOUNDS(contract, to), 
        "Assume from and to are within predefined account set");
    
    ASSERT(contract != 0, "ERC721: token zero address");
    ASSERT(to != 0, "ERC721: transfer to the zero address");
    ASSERT(to != from, "ERC721: transfer to same address");
    
    address owner = ghostERC721Owners[contract][tokenId];
    ASSERT(owner != 0, "ERC721: transfer of nonexistent token");
    
    ASSERT(owner == from, "ERC721: transfer from incorrect owner");
    ASSERT(
        sender == from 
        || ghostERC721TokenApprovals[contract][tokenId] == sender
        || ghostERC721OperatorApprovals[contract][from][sender],
        "ERC721: transfer caller is not owner nor approved"
    );
    
    ASSERT(ghostERC721Balances256[contract][from] >= 1, "Insufficient balance");

    // Clear approvals
    ghostERC721TokenApprovals[contract][tokenId] = 0;
    
    // Update balances
    ghostERC721Balances256[contract][from] = require_uint256(ghostERC721Balances256[contract][from] - 1);
    ghostERC721Balances256[contract][to] = require_uint256(ghostERC721Balances256[contract][to] + 1);
    
    // Transfer ownership
    ghostERC721Owners[contract][tokenId] = to;
}