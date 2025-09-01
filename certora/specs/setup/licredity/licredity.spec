// Main Licredity contract setup - methods block and configuration

import "./storage_hooks.spec";            // Storage hooks and ghost state for Licredity state variables
import "./base_hooks.spec";               // UNSAFE: BaseHooks abstract methods marked as NONDET/DELETE

import "./libraries/full_math.spec";      // SAFE: CVL implementation of FullMath
import "./libraries/pips_math.spec";      // SAFE: CVL implementation of PipsMath 

import "./types/fungible.spec";           // SAFE: CVL redirects for Fungible type (ERC20/native)
import "./types/fungible_state.spec";     // SAFE: CVL implementation of FungibleState
import "./types/non_fungible.spec";       // SAFE: CVL redirects for NonFungible type (ERC721)

import "./oracle_mock_nondet.spec";       // UNSAFE: Oracle mock with NONDET returns for price queries

using LicredityHarness as _Licredity;

methods {                
    // ERC20 view functions marked as envfree
    function _Licredity.balanceOf(address owner) external returns (uint256) envfree;
    function _Licredity.allowance(address owner, address spender) external returns (uint256) envfree;
    function _Licredity.totalSupply() external returns (uint256) envfree;
    function _Licredity.decimals() external returns (uint8) envfree;
    
    // SAFE: Remove from verification - ERC20 string functions (metadata only)
    function _Licredity.name() external returns (string) 
        => NONDET DELETE;
    function _Licredity.symbol() external returns (string) 
        => NONDET DELETE;
                
    // SAFE: Remove from verification - Extsload functions
    function _Licredity.extsload(bytes32 slot) external returns (bytes32) 
        => NONDET DELETE;
    function _Licredity.extsload(bytes32 startSlot, uint256 nSlots) external returns (bytes32[]) 
        => NONDET DELETE;
    function _Licredity.extsload(bytes32[] slots) external returns (bytes32[]) 
        => NONDET DELETE;

    // SAFE: Remove from verification - ERC721 receiver callback
    function _Licredity.onERC721Received(address, address, uint256, bytes) external returns (bytes4) 
        => NONDET DELETE;

    // SAFE: Remove from verification - use harness functions 2-step stage flow
    function _Licredity.unlock(bytes) external returns (bytes) 
        => NONDET DELETE;
    function _Licredity.stageFungible(LicredityHarness.Fungible) external 
        => NONDET DELETE;
    function _Licredity.stageNonFungible(LicredityHarness.NonFungible) external 
        => NONDET DELETE;
    function _Licredity.exchangeFungible(address, bool) external 
        => NONDET DELETE;
    function _Licredity.depositFungible(uint256) external 
        => NONDET DELETE;
    function _Licredity.depositNonFungible(uint256) external 
        => NONDET DELETE;
    
    // SAFE: Remove from verification - use harness functions that simulate unlock flow
    function _Licredity.withdrawFungible(uint256, address, LicredityHarness.Fungible, uint256) external 
        => NONDET DELETE;
    function _Licredity.withdrawNonFungible(uint256, address, LicredityHarness.NonFungible) external 
        => NONDET DELETE;
    function _Licredity.increaseDebtShare(uint256, uint256, address) external returns (uint256)
        => NONDET DELETE;
    function _Licredity.seize(uint256, address) external returns (uint256)
        => NONDET DELETE;

    // SAFE: Known issue (use dispatch call in Helper() instead of NONDET) - PoolManager call from constructor
    // See: https://discord.com/channels/795999272293236746/1408406304753451179
    function _.initialize(LicredityHarness.PoolKey key, uint160) external => DISPATCHER(true);
}

// SAFE: Defines which functions to exclude from verification in parametric rules and invariants
definition LICREDITY_EXCLUDED_FUNCTION(method f) returns bool = 
    // Helper functions - not part of actual contract interface
    f.selector == sig:transferNative(address,uint256).selector
    ;

// Protocol constants - initial values prevent inflation attacks
definition INITIAL_DEBT_SHARE_CVL() returns mathint = 1000000;
definition INITIAL_DEBT_BALANCE_CVL() returns mathint = 1;