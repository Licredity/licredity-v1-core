// CVL implementation for FungibleState type methods

// FungibleState packing: 64 bits index | 64 bits empty | 128 bits balance
// Extract index from FungibleState (upper 64 bits, bits 192-255)
definition FUNGIBLE_STATE_INDEX(uint256 state) returns uint64 
    = require_uint64(state >> 192) & 0xffffffffffffffff;

// Extract balance from FungibleState (lower 128 bits)
definition FUNGIBLE_STATE_BALANCE(uint256 state) returns uint256
    = state & 0xffffffffffffffffffffffffffffffff;
