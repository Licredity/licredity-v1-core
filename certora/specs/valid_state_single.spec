// Valid state invariants that must hold in every reachable state of the Licredity protocol

import "./setup/setup_single.spec";

// Setup function that includes all valid state requirements
function setupValidState(env e) {

    setup(e);
    
    // Common invariants
    requireInvariant lastInterestCollectionNotInFuture(e);
    requireInvariant liquidityOnsetsNotInFuture(e);
    requireInvariant positionsWithDataMustHaveOwner(e);
    requireInvariant totalDebtNotExceedLimit(e);
    requireInvariant debtOutstandingWithinSupply(e);
    requireInvariant noDebtTokenAllowances(e);
    requireInvariant outstandingDebtPairedWithAvailableBase(e);
    requireInvariant singlePositionDebtSolvency(e);

    // Fungible invariants
    requireInvariant fungibleArrayElementsBeyondLengthAreEmpty(e);
    requireInvariant allFungiblesAreUnique(e);
    requireInvariant fungiblesHaveNonZeroBalance(e);
    requireInvariant fungiblesHaveCorrectIndex(e);
    requireInvariant fungibleIndexesWithinBounds(e);
    requireInvariant fungibleStatesPointToCorrectPosition(e);
    requireInvariant fungiblePositionBalancesBacked(e);
    requireInvariant baseTokenPositionBalancesBacked(e);

    // Non-fungible invariants
    requireInvariant nonFungibleArrayElementsBeyondLengthAreEmpty(e);
    requireInvariant allNonFungiblesAreUnique(e);
    requireInvariant nonFungiblesOwnedByLicredity(e);
}

// Use in invariants preserved block
function SETUP(env e, env eFunc) {
    requireSameEnv(e, eFunc); 
    setupValidState(e);
}

// VS-LI-01: Last interest collection timestamp cannot be in the future
// Interest can only be collected for time that has already passed
invariant lastInterestCollectionNotInFuture(env e)
    ghostLiLastInterestCollectionTimestamp32 <= e.block.timestamp
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-02: Liquidity onset timestamps cannot be in the future
// Liquidity positions can only be marked as added at the current time or in the past
invariant liquidityOnsetsNotInFuture(env e)
    forall bytes32 liquidityKey. 
        ghostLiLiquidityOnsets32[liquidityKey] <= e.block.timestamp
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-03: Positions with any data must have an owner
// If a position has any data (debt, fungibles, or nonFungibles), it must have a non-zero owner
invariant positionsWithDataMustHaveOwner(env e)
    ghostLiPositionDebtShare128 != 0 ||
    ghostLiPositionFungiblesLength != 0 ||
    ghostLiPositionNonFungiblesLength != 0
        => ghostLiPositionOwner != 0
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-04: Total debt must not exceed debt limit
// The total debt balance in the system must never exceed the configured debt limit
invariant totalDebtNotExceedLimit(env e)
    ghostLiTotalDebtBalance128 <= ghostLiDebtLimit128
filtered { f -> !EXCLUDED_FUNCTION(f) 
    // SAFE: setDebtLimit directly modifies the debt limit parameter itself
    && f.selector != sig:setDebtLimit(uint256).selector
    // SAFE: setProtocolFeePips calls _collectInterest which increases totalDebtBalance by accrued interest
    && f.selector != sig:setProtocolFeePips(uint256).selector
    // SAFE: seize can mint debt tokens during topup to cover underwater positions, temporarily exceeding debt limit
    && f.selector != sig:seizeHarness(uint256,address).selector
    // SAFE: harness functions call _collectInterest which can increase totalDebtBalance beyond limit
    && f.selector != sig:withdrawFungibleHarness(uint256,address,LicredityHarness.Fungible,uint256).selector
    && f.selector != sig:withdrawNonFungibleHarness(uint256,address,LicredityHarness.NonFungible).selector
    && f.selector != sig:increaseDebtShareHarness(uint256,uint256,address).selector
} { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-05: Debt amount outstanding must not exceed total supply
// The debtAmountOutstanding represents debt tokens available for exchange back to base tokens.
// These are "free" tokens outside of positions that can be redeemed.
invariant debtOutstandingWithinSupply(env e)
    ghostLiDebtAmountOutstanding128 <= ghostERC20TotalSupply256[_Licredity]
filtered { f -> !EXCLUDED_FUNCTION(f) 
    // SAFE: decreaseDebtShare burns debt tokens (reducing totalSupply) but doesn't affect debtAmountOutstanding
    && f.selector != sig:decreaseDebtShare(uint256,uint256,bool).selector
} { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-06: Licredity must have no debt token allowances
// The Licredity contract should never approve anyone to transfer its debt tokens.
invariant noDebtTokenAllowances(env e)
    forall address spender. 
        spender != 0 => ghostERC20Allowances128[_Licredity][_Licredity][spender] == 0
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-07: Outstanding debt and available base must be paired
// When there is outstanding debt available for exchange, there must be corresponding base tokens available.
// Both values are set together during exchanges and should maintain their relationship.
invariant outstandingDebtPairedWithAvailableBase(env e)
    (ghostLiDebtAmountOutstanding128 > 0 <=> ghostLiBaseAmountAvailable128 > 0)
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-08: Single position debt solvency
// The total debt shares in the system must always equal the initial locked 1e6 shares
// plus the debt share of the single position
invariant singlePositionDebtSolvency(env e)
    ghostLiTotalDebtShare128 == INITIAL_DEBT_SHARE_CVL() + ghostLiPositionDebtShare128
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-09: Technical invariant: Fungible array elements beyond length must be zero
// All fungible array elements at indices >= length must be zero
invariant fungibleArrayElementsBeyondLengthAreEmpty(env e)
    forall mathint i.
        i < 0 || i >= ghostLiPositionFungiblesLength =>
            ghostLiPositionFungibles[i] == 0
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-10: All fungibles in a position must be unique
// No duplicate fungibles allowed in the fungibles array of any position
invariant allFungiblesAreUnique(env e)
    forall mathint i. forall mathint j.
        i >= 0 && i < ghostLiPositionFungiblesLength 
        && j >= 0 && j < ghostLiPositionFungiblesLength 
        && i != j 
            => ghostLiPositionFungibles[i] != ghostLiPositionFungibles[j]
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-11: Fungibles in array must have corresponding fungibleStates with non-zero balance
// For every fungible in the fungibles array, there must be a corresponding fungibleStates entry with non-zero balance
invariant fungiblesHaveNonZeroBalance(env e)
    forall mathint i.
        i >= 0 && i < ghostLiPositionFungiblesLength 
            => ghostLiPositionFungibleStatesBalance112[ghostLiPositionFungibles[i]] != 0
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-12: Fungibles in array must have matching index in fungibleStates
// For every fungible in the fungibles array, the index stored in fungibleStates must be array position + 1 (1-based)
invariant fungiblesHaveCorrectIndex(env e)
    forall mathint i.
        i >= 0 && i < ghostLiPositionFungiblesLength
            => ghostLiPositionFungibleStatesIndex64[ghostLiPositionFungibles[i]] == i + 1
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-13: Fungible indexes must be within valid bounds
// If a fungible has non-zero state, its index must be valid (1-based, within array bounds)
invariant fungibleIndexesWithinBounds(env e)
    forall LicredityHarness.Fungible fungible.
        ghostLiPositionFungibleStates256[fungible] != 0 => (
            ghostLiPositionFungibleStatesIndex64[fungible] > 0 
            && ghostLiPositionFungibleStatesIndex64[fungible] <= ghostLiPositionFungiblesLength
        )
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-14: Fungibles with state must be at their claimed position
// If a fungible has non-zero state, it must appear in the array at the position indicated by its index
invariant fungibleStatesPointToCorrectPosition(env e)
    forall LicredityHarness.Fungible fungible.
        ghostLiPositionFungibleStates256[fungible] != 0 
            => ghostLiPositionFungibles[ghostLiPositionFungibleStatesIndex64[fungible] - 1] == fungible
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-15: Fungible balances in positions must be backed
// For all fungible tokens (except base), the sum of balances across all positions must not exceed 
// the contract's actual token balance.
invariant fungiblePositionBalancesBacked(env e)
    forall LicredityHarness.Fungible fungible. 
        // Looks like a prover issue while dealing with custom type
        fungible >= 0 => fungible <= max_uint160 =>                   
        // Total fungible balance across all positions
        ghostLiPositionFungibleStatesBalance112[fungible] <= (
            fungible == 0 
            ? nativeBalances[_Licredity] 
            : ghostERC20Balances128[fungible][_Licredity] 
        )
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-16: Base tokens reserved for exchange must be backed
// The base tokens held in positions plus the amount reserved for debt-to-base exchanges
// must not exceed the contract's actual base token balance
invariant baseTokenPositionBalancesBacked(env e)
    ghostLiPositionFungibleStatesBalance112[_Licredity.baseFungible] + ghostLiBaseAmountAvailable128 <= (
        _Licredity.baseFungible == 0 ? nativeBalances[_Licredity] : ghostERC20Balances128[_Licredity.baseFungible][_Licredity]
    )
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-17: Technical invariant: NonFungible array elements beyond length must be zero
// All nonFungible array elements and their components at indices >= length must be zero (and vice versa)
invariant nonFungibleArrayElementsBeyondLengthAreEmpty(env e)
    forall mathint i.
        (i < 0 || i >= ghostLiPositionNonFungiblesLength) <=> (
            ghostLiPositionNonFungibles[i] == to_bytes32(0) 
            && ghostNonFungibleTokenAddress[ghostLiPositionNonFungibles[i]] == 0 
            && ghostNonFungibleTokenId[ghostLiPositionNonFungibles[i]] == 0
        )
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-18: All nonFungibles in a position must be unique
// No duplicate nonFungibles allowed in the nonFungibles array of any position
invariant allNonFungiblesAreUnique(env e)
    forall mathint i. forall mathint j.
        i >= 0 && i < ghostLiPositionNonFungiblesLength &&
        j >= 0 && j < ghostLiPositionNonFungiblesLength &&
        i != j 
            => ghostLiPositionNonFungibles[i] != ghostLiPositionNonFungibles[j]
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }

// VS-LI-19: Licredity must own all NonFungibles stored in positions
// Every NonFungible token stored in any position must be owned by the Licredity contract
invariant nonFungiblesOwnedByLicredity(env e)
    forall mathint i. 
        i >= 0 && i < ghostLiPositionNonFungiblesLength 
            => ghostERC721Owners[ghostNonFungibleTokenAddress[ghostLiPositionNonFungibles[i]]]
                [ghostNonFungibleTokenId[ghostLiPositionNonFungibles[i]]] == _Licredity
filtered { f -> !EXCLUDED_FUNCTION(f) } { preserved with (env eFunc) { SETUP(e, eFunc); } }