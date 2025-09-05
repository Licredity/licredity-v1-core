// Storage hooks and ghost state for tracking Licredity contract state variables during verification

// ========== LICREDITY CORE STORAGE ==========

// totalDebtShare - tracks the total debt shares in the system
persistent ghost mathint ghostLiTotalDebtShare128 {
    init_state axiom ghostLiTotalDebtShare128 == INITIAL_DEBT_SHARE_CVL();
    // SAFE: Bounded from uint256 to uint128 for verification
    axiom ghostLiTotalDebtShare128 >= 0 && ghostLiTotalDebtShare128 <= max_uint128;
}

hook Sload uint256 val _Licredity.totalDebtShare {
    require(ghostLiTotalDebtShare128 == val, "Assume ghost totalDebtShare equals storage value");
}

hook Sstore _Licredity.totalDebtShare uint256 val {
    ghostLiTotalDebtShare128 = val;
}

// totalDebtBalance - tracks the total debt balance
persistent ghost mathint ghostLiTotalDebtBalance128 {
    // Establishes the initial conversion rate and inflation attack difficulty
    init_state axiom ghostLiTotalDebtBalance128 == INITIAL_DEBT_BALANCE_CVL();
    // SAFE: Bounded from uint256 to uint128 for verification
    axiom ghostLiTotalDebtBalance128 >= 0 && ghostLiTotalDebtBalance128 <= max_uint128;
}

hook Sload uint256 val _Licredity.totalDebtBalance {
    require(ghostLiTotalDebtBalance128 == val, "Assume ghost totalDebtBalance equals storage value");
}

hook Sstore _Licredity.totalDebtBalance uint256 val {
    ghostLiTotalDebtBalance128 = val;
}

// accruedDonation
persistent ghost mathint ghostLiAccruedDonation128 {
    init_state axiom ghostLiAccruedDonation128 == 0;
    // SAFE: Bounded from uint256 to uint128 for verification
    axiom ghostLiAccruedDonation128 >= 0 && ghostLiAccruedDonation128 <= max_uint128;
}

hook Sload uint256 val _Licredity.accruedDonation {
    require(ghostLiAccruedDonation128 == val, "Assume ghost accruedDonation equals storage value");
}

hook Sstore _Licredity.accruedDonation uint256 val {
    ghostLiAccruedDonation128 = val;
}

// accruedProtocolFee
persistent ghost mathint ghostLiAccruedProtocolFee128 {
    init_state axiom ghostLiAccruedProtocolFee128 == 0;
    // SAFE: Bounded from uint256 to uint128 for verification
    axiom ghostLiAccruedProtocolFee128 >= 0 && ghostLiAccruedProtocolFee128 <= max_uint128;
}

hook Sload uint256 val _Licredity.accruedProtocolFee {
    require(ghostLiAccruedProtocolFee128 == val, "Assume ghost accruedProtocolFee equals storage value");
}

hook Sstore _Licredity.accruedProtocolFee uint256 val {
    ghostLiAccruedProtocolFee128 = val;
}

// lastInterestCollectionTimestamp
persistent ghost mathint ghostLiLastInterestCollectionTimestamp32 {
    init_state axiom ghostLiLastInterestCollectionTimestamp32 == 0;
    // SAFE: Bounded from uint256 to uint32 for verification (valid until 2106)
    axiom ghostLiLastInterestCollectionTimestamp32 >= 0 && ghostLiLastInterestCollectionTimestamp32 <= max_uint32;
}

hook Sload uint256 val _Licredity.lastInterestCollectionTimestamp {
    require(ghostLiLastInterestCollectionTimestamp32 == val, 
        "Assume ghost lastInterestCollectionTimestamp equals storage value");
}

hook Sstore _Licredity.lastInterestCollectionTimestamp uint256 val {
    ghostLiLastInterestCollectionTimestamp32 = val;
}

// baseAmountAvailable
persistent ghost mathint ghostLiBaseAmountAvailable128 {
    init_state axiom ghostLiBaseAmountAvailable128 == 0;
    // SAFE: Bounded from uint256 to uint128 for verification
    axiom ghostLiBaseAmountAvailable128 >= 0 && ghostLiBaseAmountAvailable128 <= max_uint128;
}

hook Sload uint256 val _Licredity.baseAmountAvailable {
    require(ghostLiBaseAmountAvailable128 == val, "Assume ghost baseAmountAvailable equals storage value");
}

hook Sstore _Licredity.baseAmountAvailable uint256 val {
    ghostLiBaseAmountAvailable128 = val;
}

// debtAmountOutstanding
persistent ghost mathint ghostLiDebtAmountOutstanding128 {
    init_state axiom ghostLiDebtAmountOutstanding128 == 0;
    // SAFE: Bounded from uint256 to uint128 for verification
    axiom ghostLiDebtAmountOutstanding128 >= 0 && ghostLiDebtAmountOutstanding128 <= max_uint128;
}

hook Sload uint256 val _Licredity.debtAmountOutstanding {
    require(ghostLiDebtAmountOutstanding128 == val, "Assume ghost debtAmountOutstanding equals storage value");
}

hook Sstore _Licredity.debtAmountOutstanding uint256 val {
    ghostLiDebtAmountOutstanding128 = val;
}

// positionCount
persistent ghost mathint ghostLiPositionCount64 {
    init_state axiom ghostLiPositionCount64 == 0;
    // SAFE: Bounded from uint256 to uint64 for verification
    axiom ghostLiPositionCount64 >= 0 && ghostLiPositionCount64 <= max_uint64;
}

hook Sload uint256 val _Licredity.positionCount {
    require(ghostLiPositionCount64 == val, "Assume ghost positionCount equals storage value");
}

hook Sstore _Licredity.positionCount uint256 val {
    ghostLiPositionCount64 = val;
}

// liquidityOnsets mapping
persistent ghost mapping(bytes32 => mathint) ghostLiLiquidityOnsets32 {
    init_state axiom forall bytes32 key. ghostLiLiquidityOnsets32[key] == 0;
    // Bounded from uint256 to uint32 for verification (timestamps valid until 2106)
    axiom forall bytes32 key. ghostLiLiquidityOnsets32[key] >= 0 && ghostLiLiquidityOnsets32[key] <= max_uint32;
}

hook Sload uint256 val _Licredity.liquidityOnsets[KEY bytes32 key] {
    require(ghostLiLiquidityOnsets32[key] == val, "Assume ghost liquidityOnsets equals storage value for key");
}

hook Sstore _Licredity.liquidityOnsets[KEY bytes32 key] uint256 val {
    ghostLiLiquidityOnsets32[key] = val;
}

// ========== INHERITED FROM BaseERC20 ==========

// decimals

hook Sload uint8 val _Licredity.decimals {
    require(ghostErc20Decimals8[_Licredity] == val, "Assume ghost decimals equals storage value");
}

hook Sstore _Licredity.decimals uint8 val {
    ghostErc20Decimals8[_Licredity] = val;
}

// totalSupply

hook Sload uint256 val _Licredity.totalSupply {
    require(ghostERC20TotalSupply256[_Licredity] == val, "Assume ghost totalSupply equals storage value");
}

hook Sstore _Licredity.totalSupply uint256 val {
    ghostERC20TotalSupply256[_Licredity] = val;
}

// ownerData mapping - balance

hook Sload uint256 val _Licredity.ownerData[KEY address owner].balance {
    require(ERC20_ACCOUNT_BOUNDS(_Licredity, owner), "Assume address is within predefined account set");
    require(ghostERC20Balances128[_Licredity][owner] == val, "Assume ghost owner balance equals storage value");
}

hook Sstore _Licredity.ownerData[KEY address owner].balance uint256 val {
    require(ERC20_ACCOUNT_BOUNDS(_Licredity, owner), "Assume address is within predefined account set");
    ghostERC20Balances128[_Licredity][owner] = val;
}

// ownerData mapping - allowances

hook Sload uint256 val _Licredity.ownerData[KEY address owner].allowances[KEY address spender] {
    require(ERC20_ACCOUNT_BOUNDS(_Licredity, owner), "Assume address is within predefined account set");
    require(ERC20_ACCOUNT_BOUNDS(_Licredity, spender), "Assume address is within predefined account set");
    require(ghostERC20Allowances128[_Licredity][owner][spender] == val, "Assume ghost allowance equals storage value for owner-spender pair");
}

hook Sstore _Licredity.ownerData[KEY address owner].allowances[KEY address spender] uint256 val {
    require(ERC20_ACCOUNT_BOUNDS(_Licredity, owner), "Assume address is within predefined account set");
    require(ERC20_ACCOUNT_BOUNDS(_Licredity, spender), "Assume address is within predefined account set");
    ghostERC20Allowances128[_Licredity][owner][spender] = val;
}

// ========== INHERITED FROM BaseHooks ==========

// poolManager
persistent ghost address ghostLiPoolManager;

hook Sload address val _Licredity.poolManager {
    require(ghostLiPoolManager == val, "Assume ghost poolManager address equals storage value");
}

hook Sstore _Licredity.poolManager address val {
    ghostLiPoolManager = val;
}

// ========== INHERITED FROM RiskConfigs ==========

// governor
persistent ghost address ghostLiGovernor {
    init_state axiom ghostLiGovernor == 0;
}

hook Sload address val _Licredity.governor {
    require(ghostLiGovernor == val, "Assume ghost governor address equals storage value");
}

hook Sstore _Licredity.governor address val {
    ghostLiGovernor = val;
}

// nextGovernor
persistent ghost address ghostLiNextGovernor {
    init_state axiom ghostLiNextGovernor == 0;
}

hook Sload address val _Licredity.nextGovernor {
    require(ghostLiNextGovernor == val, "Assume ghost nextGovernor address equals storage value");
}

hook Sstore _Licredity.nextGovernor address val {
    ghostLiNextGovernor = val;
}

// oracle
persistent ghost address ghostLiOracle {
    init_state axiom ghostLiOracle == 0;
}

hook Sload address val _Licredity.oracle {
    require(ghostLiOracle == val, "Assume ghost oracle address equals storage value");
}

hook Sstore _Licredity.oracle address val {
    ghostLiOracle = val;
}

// debtLimit
persistent ghost mathint ghostLiDebtLimit128 {
    // UNSAFE: assume debt limit set during deployment
    init_state axiom ghostLiDebtLimit128 == INITIAL_DEBT_BALANCE_CVL(); 
    // SAFE: Bounded from uint256 to uint128 for verification
    axiom ghostLiDebtLimit128 >= 0 && ghostLiDebtLimit128 <= max_uint128;
}

hook Sload uint256 val _Licredity.debtLimit {
    require(ghostLiDebtLimit128 == val, "Assume ghost debtLimit equals storage value");
}

hook Sstore _Licredity.debtLimit uint256 val {
    ghostLiDebtLimit128 = val;
}

// minMargin
persistent ghost mathint ghostLiMinMargin128 {
    init_state axiom ghostLiMinMargin128 == 0;
    // SAFE: Bounded from uint256 to uint128 for verification
    axiom ghostLiMinMargin128 >= 0 && ghostLiMinMargin128 <= max_uint128;
}

hook Sload uint256 val _Licredity.minMargin {
    require(ghostLiMinMargin128 == val, "Assume ghost minMargin equals storage value");
}

hook Sstore _Licredity.minMargin uint256 val {
    ghostLiMinMargin128 = val;
}

// minLiquidityLifespan
persistent ghost mathint ghostLiMinLiquidityLifespan32 {
    init_state axiom ghostLiMinLiquidityLifespan32 == 0;
    // SAFE: Bounded from uint256 to uint32 for verification
    axiom ghostLiMinLiquidityLifespan32 >= 0 && ghostLiMinLiquidityLifespan32 <= max_uint32;
}

hook Sload uint256 val _Licredity.minLiquidityLifespan {
    require(ghostLiMinLiquidityLifespan32 == val, "Assume ghost minLiquidityLifespan equals storage value");
}

hook Sstore _Licredity.minLiquidityLifespan uint256 val {
    ghostLiMinLiquidityLifespan32 = val;
}

// protocolFeePips
persistent ghost mathint ghostLiProtocolFeePips24 {
    init_state axiom ghostLiProtocolFeePips24 == 0;
    axiom ghostLiProtocolFeePips24 >= 0 && ghostLiProtocolFeePips24 <= 16777215;
}

hook Sload uint24 val _Licredity.protocolFeePips {
    require(ghostLiProtocolFeePips24 == val, "Assume ghost protocolFeePips equals storage value");
}

hook Sstore _Licredity.protocolFeePips uint24 val {
    ghostLiProtocolFeePips24 = val;
}

// protocolFeeRecipient
persistent ghost address ghostLiProtocolFeeRecipient {
    init_state axiom ghostLiProtocolFeeRecipient == 0;
}

hook Sload address val _Licredity.protocolFeeRecipient {
    require(ghostLiProtocolFeeRecipient == val, "Assume ghost protocolFeeRecipient address equals storage value");
}

hook Sstore _Licredity.protocolFeeRecipient address val {
    ghostLiProtocolFeeRecipient = val;
}