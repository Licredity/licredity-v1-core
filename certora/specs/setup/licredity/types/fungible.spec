// CVL implementation redirecting Fungible type methods to internal CVL implementations of ERC20 or native transfers

methods {
    function FungibleLibrary.transfer(LicredityHarness.Fungible self, address recipient, uint256 amount) internal with (env e) 
        => fungibleTransferCVL(e, self, currentContract, recipient, amount);

    function FungibleLibrary.balanceOf(LicredityHarness.Fungible self, address owner) internal returns (uint256)
        => fungibleBalanceOfCVL(self, owner);
        
    function FungibleLibrary.decimals(LicredityHarness.Fungible self) internal returns (uint8)
        => fungibleDecimalsCVL(self);
        
    function FungibleLibrary.isNative(LicredityHarness.Fungible self) internal returns (bool)
        => IS_NATIVE_ADDRESS_CVL(self);    
}

definition NATIVE_ADDRESS_CVL() returns address = 0; 
definition NATIVE_DECIMALS_CVL() returns mathint = 18;

// Check if fungible is native currency
definition IS_NATIVE_ADDRESS_CVL(address fungible) returns bool =
    fungible == NATIVE_ADDRESS_CVL();

// Check if fungible is within bounds (either ERC20 token or native) - DISABLED
definition FUNGIBLE_TOKEN_BOUNDS(address fungible) returns bool =
    ERC20_TOKEN_BOUNDS(fungible) || IS_NATIVE_ADDRESS_CVL(fungible);

// Transfer fungible tokens from current contract to recipient
function fungibleTransferCVL(env e, address fungible, address from, address recipient, uint256 amount) {
    
    if (IS_NATIVE_ADDRESS_CVL(fungible)) {
        transferNative(e, recipient, amount);
    } else {
        // ERC20 token transfer - use transferCVL from erc20.spec
        bool success = transferERC20CVL(fungible, from, recipient, amount);
        ASSERT(success, "FungibleTransferFailed");
    }
}

// Get balance of fungible for an owner
function fungibleBalanceOfCVL(address fungible, address owner) returns uint256 {
    
    if (IS_NATIVE_ADDRESS_CVL(fungible)) {
        // Native currency balance
        return require_uint256(nativeBalances[owner]);
    } else {
        // ERC20 token balance - use balanceOfCVL from erc20.spec
        return balanceOfERC20CVL(fungible, owner);
    }
}

// Get decimals of fungible
function fungibleDecimalsCVL(address fungible) returns uint8 {
    
    if (IS_NATIVE_ADDRESS_CVL(fungible)) {
        // Native currency has 18 decimals
        return require_uint8(NATIVE_DECIMALS_CVL());
    } else {
        // ERC20 token decimals
        return require_uint8(ghostErc20Decimals8[fungible]);
    }
}