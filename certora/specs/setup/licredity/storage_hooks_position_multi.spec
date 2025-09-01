// Storage hooks and ghost state for tracking Licredity positions

// positions mapping
persistent ghost mapping(uint256 => address) ghostLiPositionOwner {
    init_state axiom forall uint256 positionId. ghostLiPositionOwner[positionId] == 0;
}

hook Sload address val _Licredity.positions[KEY uint256 positionId].owner {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    require(ghostLiPositionOwner[positionId] == val, "Assume ghost position owner equals storage value for positionId");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].owner address val {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    ghostLiPositionOwner[positionId] = val;
}

persistent ghost mapping(uint256 => mathint) ghostLiPositionDebtShare128 {
    init_state axiom forall uint256 positionId. ghostLiPositionDebtShare128[positionId] == 0;
    // Bounded from uint256 to uint128 for verification
    axiom forall uint256 positionId. ghostLiPositionDebtShare128[positionId] >= 0 
        && ghostLiPositionDebtShare128[positionId] <= max_uint128;
}

hook Sload uint256 val _Licredity.positions[KEY uint256 positionId].debtShare {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    require(ghostLiPositionDebtShare128[positionId] == val, 
        "Assume ghost position debtShare equals storage value for positionId");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].debtShare uint256 val {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    ghostLiPositionDebtShare128[positionId] = val;
}

// positions.fungibles array
persistent ghost mapping(mathint => mapping(mathint => LicredityHarness.Fungible)) ghostLiPositionFungibles {
    init_state axiom forall mathint positionId. forall mathint i. ghostLiPositionFungibles[positionId][i] == 0;
}

persistent ghost mapping(mathint => mathint) ghostLiPositionFungiblesLength {
    init_state axiom forall mathint positionId. ghostLiPositionFungiblesLength[positionId] == 0;
    // Limit maximum array length to LOOP_ITER_CVL()
    axiom forall mathint positionId. ghostLiPositionFungiblesLength[positionId] >= 0 
        && ghostLiPositionFungiblesLength[positionId] <= LOOP_ITER_CVL();
}

hook Sload uint256 val _Licredity.positions[KEY uint256 positionId].(offset 64) {
    require(ghostLiPositionFungiblesLength[positionId] == val, "Assume ghost fungibles length equals storage value");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].(offset 64) uint256 val {
    ghostLiPositionFungiblesLength[positionId] = val;
}

hook Sload LicredityHarness.Fungible val _Licredity.positions[KEY uint256 positionId].fungibles[INDEX uint256 i] {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    require(ghostLiPositionFungibles[positionId][i] == val, "Assume ghost position fungible equals storage value at index");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].fungibles[INDEX uint256 i] LicredityHarness.Fungible val {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    ghostLiPositionFungibles[positionId][i] = val;
}

// positions.nonFungibles array
persistent ghost mapping(mathint => mapping(mathint => HelperCVL.NonFungible)) ghostLiPositionNonFungibles {
    init_state axiom forall mathint positionId. forall mathint i. 
        ghostLiPositionNonFungibles[positionId][i] == to_bytes32(0);
}

persistent ghost mapping(mathint => mathint) ghostLiPositionNonFungiblesLength {
    init_state axiom forall mathint positionId. ghostLiPositionNonFungiblesLength[positionId] == 0;
    // Limit maximum array length to LOOP_ITER_CVL()
    axiom forall mathint positionId. ghostLiPositionNonFungiblesLength[positionId] >= 0 
        && ghostLiPositionNonFungiblesLength[positionId] <= LOOP_ITER_CVL();
}

hook Sload uint256 val _Licredity.positions[KEY uint256 positionId].(offset 96) {
    require(ghostLiPositionNonFungiblesLength[positionId] == val, "Assume ghost nonFungibles length equals storage value");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].(offset 96) uint256 val {
    ghostLiPositionNonFungiblesLength[positionId] = val;
}

hook Sload LicredityHarness.NonFungible val _Licredity.positions[KEY uint256 positionId].nonFungibles[INDEX uint256 i] {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    require(ghostLiPositionNonFungibles[positionId][i] == val, "Assume ghost nonFungibles equals storage value");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].nonFungibles[INDEX uint256 i] LicredityHarness.NonFungible val {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    ghostLiPositionNonFungibles[positionId][i] = val;
}

// positions.fungibleStates mapping

persistent ghost mapping(mathint => mapping(LicredityHarness.Fungible => LicredityHarness.FungibleState)) ghostLiPositionFungibleStates {
    init_state axiom forall mathint positionId. forall LicredityHarness.Fungible fungible. 
        ghostLiPositionFungibleStates[positionId][fungible] == 0;
}

hook Sload LicredityHarness.FungibleState val _Licredity.positions[KEY uint256 positionId].fungibleStates[KEY LicredityHarness.Fungible fungible] {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    require(ghostLiPositionFungibleStates[positionId][fungible] == val, 
        "Assume ghost position fungibleStates equals storage value at index");
}

hook Sstore _Licredity.positions[KEY uint256 positionId].fungibleStates[KEY LicredityHarness.Fungible fungible] LicredityHarness.FungibleState val {
    require(POSITION_BOUNDS(positionId), "Assume position id within predefined position set");
    ghostLiPositionFungibleStates[positionId][fungible] = val;
}