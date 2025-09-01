// Storage hooks and ghost state for tracking Licredity single position

// positions mapping
persistent ghost address ghostLiPositionOwner {
    init_state axiom ghostLiPositionOwner == 0;
}

hook Sload address val _Licredity.positions[KEY uint256 positionId].owner {
    require(ghostLiPositionOwner == val, "Assume ghost position owner equals storage value");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].owner address val {
    ghostLiPositionOwner = val;
}

persistent ghost mathint ghostLiPositionDebtShare128 {
    init_state axiom ghostLiPositionDebtShare128 == 0;
    // Bounded from uint256 to uint128 for verification
    axiom ghostLiPositionDebtShare128 >= 0 && ghostLiPositionDebtShare128 <= max_uint128;
}

hook Sload uint256 val _Licredity.positions[KEY uint256 positionId].debtShare {
    require(ghostLiPositionDebtShare128 == val, 
        "Assume ghost position debtShare equals storage value");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].debtShare uint256 val {
    ghostLiPositionDebtShare128 = val;
}

// positions.fungibles array
persistent ghost mapping(mathint => LicredityHarness.Fungible) ghostLiPositionFungibles {
    init_state axiom forall mathint i. ghostLiPositionFungibles[i] == 0;
}

persistent ghost mathint ghostLiPositionFungiblesLength {
    init_state axiom ghostLiPositionFungiblesLength == 0;
    // Limit maximum array length to LOOP_ITER_CVL()
    axiom ghostLiPositionFungiblesLength >= 0 && ghostLiPositionFungiblesLength <= LOOP_ITER_CVL();
}

hook Sload uint256 val _Licredity.positions[KEY uint256 positionId].(offset 64) {
    require(ghostLiPositionFungiblesLength == val, "Assume ghost fungibles length equals storage value");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].(offset 64) uint256 val {
    ghostLiPositionFungiblesLength = val;
}

hook Sload LicredityHarness.Fungible val _Licredity.positions[KEY uint256 positionId].fungibles[INDEX uint256 i] {
    require(ghostLiPositionFungibles[i] == val, "Assume ghost position fungible equals storage value at index");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].fungibles[INDEX uint256 i] LicredityHarness.Fungible val {
    ghostLiPositionFungibles[i] = val;
}

// positions.nonFungibles array

persistent ghost mapping(mathint => LicredityHarness.NonFungible) ghostLiPositionNonFungibles {
    init_state axiom forall mathint i. ghostLiPositionNonFungibles[i] == to_bytes32(0);
}

persistent ghost mathint ghostLiPositionNonFungiblesLength {
    init_state axiom ghostLiPositionNonFungiblesLength == 0;
    // Limit maximum array length to LOOP_ITER_CVL()
    axiom ghostLiPositionNonFungiblesLength >= 0 && ghostLiPositionNonFungiblesLength <= LOOP_ITER_CVL();
}

hook Sload uint256 val _Licredity.positions[KEY uint256 positionId].(offset 96) {
    require(ghostLiPositionNonFungiblesLength == val, "Assume ghost nonFungibles length equals storage value");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].(offset 96) uint256 val {
    ghostLiPositionNonFungiblesLength = val;
}

hook Sload LicredityHarness.NonFungible val _Licredity.positions[KEY uint256 positionId].nonFungibles[INDEX uint256 i] {
    require(ghostLiPositionNonFungibles[i] == val, "Assume ghost nonFungibles equals storage value");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].nonFungibles[INDEX uint256 i] LicredityHarness.NonFungible val {
    ghostLiPositionNonFungibles[i] = val;
}

// positions.fungibleStates mapping

// positions.fungibleStates mapping
persistent ghost mapping(LicredityHarness.Fungible => mathint) ghostLiPositionFungibleStates256 {
    init_state axiom forall LicredityHarness.Fungible fungible. ghostLiPositionFungibleStates256[fungible] == 0;
    axiom forall LicredityHarness.Fungible fungible. ghostLiPositionFungibleStates256[fungible] >= 0 
        && ghostLiPositionFungibleStates256[fungible] <= max_uint256;
    // Support only valid range of `address` fungible key (looks like a prover issue while dealing with custom type)
    axiom forall LicredityHarness.Fungible fungible. to_mathint(fungible) < 0 || to_mathint(fungible) > max_uint160 
        => ghostLiPositionFungibleStates256[fungible] == 0;
}

persistent ghost mapping(LicredityHarness.Fungible => uint112) ghostLiPositionFungibleStatesBalance112 {
    init_state axiom forall LicredityHarness.Fungible fungible. 
        ghostLiPositionFungibleStatesBalance112[fungible] == 0;
    // Support only valid range of `address` fungible key (looks like a prover issue while dealing with custom type)
    axiom forall LicredityHarness.Fungible fungible. to_mathint(fungible) < 0 || to_mathint(fungible) > max_uint160 
        => ghostLiPositionFungibleStatesBalance112[fungible] == 0;
}

persistent ghost mapping(LicredityHarness.Fungible => uint64) ghostLiPositionFungibleStatesIndex64 {
    init_state axiom forall LicredityHarness.Fungible fungible. 
        ghostLiPositionFungibleStatesIndex64[fungible] == 0;
    // Support only valid range of `address` fungible key (looks like a prover issue while dealing with custom type)
    axiom forall LicredityHarness.Fungible fungible. to_mathint(fungible) < 0 || to_mathint(fungible) > max_uint160 
        => ghostLiPositionFungibleStatesIndex64[fungible] == 0;
}

hook Sload LicredityHarness.FungibleState val _Licredity.positions[KEY uint256 positionId].fungibleStates[KEY LicredityHarness.Fungible fungible] {
    require(ghostLiPositionFungibleStates256[fungible] == val, 
        "Assume ghost position fungibleStates equals storage value at index");
    require(ghostLiPositionFungibleStatesBalance112[fungible] == require_uint112(FUNGIBLE_STATE_BALANCE(val)), 
        "Extract 128bit balance from fungibleState");
    require(ghostLiPositionFungibleStatesIndex64[fungible] == FUNGIBLE_STATE_INDEX(val), 
        "Extract 64bit index from fungibleState");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].fungibleStates[KEY LicredityHarness.Fungible fungible] LicredityHarness.FungibleState val {
    ghostLiPositionFungibleStates256[fungible] = val;
    ghostLiPositionFungibleStatesBalance112[fungible] = require_uint112(FUNGIBLE_STATE_BALANCE(val));
    ghostLiPositionFungibleStatesIndex64[fungible] = FUNGIBLE_STATE_INDEX(val);
}