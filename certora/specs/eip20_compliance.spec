// Prove Licredity contract is compatible with EIP20 (https://eips.ethereum.org/EIPS/eip-20)

import "./setup/setup_single.spec";

// EIP20-01: Verify totalSupply() returns correct total token supply from contract state
// EIP-20: "Returns the total token supply."
rule eip20_totalSupplyIntegrity(env e) {

    setup(e);

    assert(totalSupply(e) == ghostERC20TotalSupply256[_Licredity], 
        "[EIP-20] Total supply must match ghost state"
    );
}

// EIP20-02: Verify balanceOf() returns correct balance for any account address
// EIP-20: "Returns the account balance of another account with address owner."
rule eip20_balanceOfIntegrity(env e, address owner) {

    setup(e);

    assert(balanceOf(e, owner) == ghostERC20Balances128[_Licredity][owner], 
        "[EIP-20] Balance must match ghost state for account"
    );
}

// EIP20-03: Verify allowance() returns correct spending allowance between any two addresses
// EIP-20: "Returns the amount which spender is still allowed to withdraw from owner."
rule eip20_allowanceIntegrity(env e, address owner, address spender) {

    setup(e);

    assert(allowance(e, owner, spender) == ghostERC20Allowances128[_Licredity][owner][spender], 
        "[EIP-20] Allowance must match ghost state"
    );
}

// EIP20-04: Verify transfer() correctly updates balances and maintains invariants
// EIP-20: "Transfers _value amount of tokens to address _to, and MUST fire the Transfer event."
// EIP-20: "The function SHOULD throw if the message caller's account balance does not have enough tokens to spend."
rule eip20_transferIntegrity(env e, address to, uint256 amount) {

    setup(e);

    address other; 
    address any1;
    address any2;

    require(other != e.msg.sender && other != to, "Other address must not be involved in transfer");

    // Capture pre-state
    mathint fromBalancePrev = ghostERC20Balances128[_Licredity][e.msg.sender];
    mathint toBalancePrev = ghostERC20Balances128[_Licredity][to];
    mathint otherBalancePrev = ghostERC20Balances128[_Licredity][other];
    mathint totalSupplyPrev = ghostERC20TotalSupply256[_Licredity];
    mathint allowanceAny1Any2Prev = ghostERC20Allowances128[_Licredity][any1][any2];

    // Perform transfer
    transfer(e, to, amount);

    assert(e.msg.sender != to ? ghostERC20Balances128[_Licredity][e.msg.sender] == fromBalancePrev - amount 
                               : ghostERC20Balances128[_Licredity][e.msg.sender] == fromBalancePrev,
           "[EIP-20] Sender balance must decrease by transfer amount or stay same if self-transfer");

    assert(e.msg.sender != to && to != 0 ? ghostERC20Balances128[_Licredity][to] == toBalancePrev + amount 
                               : ghostERC20Balances128[_Licredity][to] == toBalancePrev,
           "[EIP-20] Receiver balance must increase by transfer amount or stay same if self-transfer");

    assert(ghostERC20Balances128[_Licredity][other] == otherBalancePrev, 
           "[INVARIANT] Uninvolved addresses must maintain their balance");
    assert(ghostERC20TotalSupply256[_Licredity] == totalSupplyPrev, 
           "[INVARIANT] Total supply must remain unchanged");
    assert(ghostERC20Allowances128[_Licredity][any1][any2] == allowanceAny1Any2Prev, 
           "[INVARIANT] Allowances must remain unchanged during transfer");
}

// EIP20-05: Verify transfer() reverts in invalid conditions
// EIP-20: "The function SHOULD throw if the message caller's account balance does not have enough tokens to spend."
rule eip20_transferMustRevert(env e, address to, uint256 amount) {

    setup(e);

    // Snapshot the 'from' balance
    mathint fromBalancePrev = ghostERC20Balances128[_Licredity][e.msg.sender];

    // Attempt transfer with revert path
    transfer@withrevert(e, to, amount);
    bool reverted = lastReverted;

    assert(e.msg.sender == 0 => reverted, 
           "[SAFETY] Transfer from zero address must revert");

    assert(to == 0 => reverted, 
           "[SAFETY] Transfer to zero address must revert");

    assert(fromBalancePrev < amount => reverted, 
           "[EIP-20] Transfer must revert if sender has insufficient balance");
}

// EIP20-06: Verify transfer() handles zero amount transfers correctly
// EIP-20: "Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event."
rule eip20_transferSupportZeroAmount(env e, address to, uint256 amount) {

    setup(e);

    // Perform transfer
    transfer(e, to, amount);

    // Zero amount transfers must succeed
    satisfy(amount == 0);
}

// EIP20-07: Verify transferFrom() correctly updates balances, allowances and maintains invariants
// EIP-20: "Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event."
// EIP-20: "The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf."
// EIP-20: "This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies."
// EIP-20: "The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism."
rule eip20_transferFromIntegrity(env e, address from, address to, uint256 amount) {

    setup(e);

    address other; 
    address any1;
    address any2;
    require(any1 != from && any2 != to, "Any addresses must be different from from/to for testing");

    require(other != from && other != to, "Other address must not be involved in transferFrom");

    // Capture pre-state
    mathint fromBalancePrev = ghostERC20Balances128[_Licredity][from];
    mathint toBalancePrev = ghostERC20Balances128[_Licredity][to];
    mathint otherBalancePrev = ghostERC20Balances128[_Licredity][other];
    mathint totalSupplyPrev = ghostERC20TotalSupply256[_Licredity];
    mathint allowanceFromSenderPrev = ghostERC20Allowances128[_Licredity][from][e.msg.sender];
    mathint allowanceAny1Any2Prev = ghostERC20Allowances128[_Licredity][any1][any2];

    // Perform the transferFrom
    transferFrom(e, from, to, amount);

    assert(
        from != to 
            ? ghostERC20Balances128[_Licredity][from] == fromBalancePrev - amount 
            : ghostERC20Balances128[_Licredity][from] == fromBalancePrev,
        "[EIP-20] From balance must decrease by transfer amount or stay same if self-transfer"
    );

    assert(
        from != to && to != 0
            ? ghostERC20Balances128[_Licredity][to] == toBalancePrev + amount
            : ghostERC20Balances128[_Licredity][to] == toBalancePrev,
        "[EIP-20] To balance must increase by transfer amount or stay same if self-transfer"
    );

    assert(ghostERC20Balances128[_Licredity][other] == otherBalancePrev, 
           "[INVARIANT] Uninvolved addresses must maintain their balance");
    assert(ghostERC20TotalSupply256[_Licredity] == totalSupplyPrev, 
           "[INVARIANT] Total supply must remain unchanged");
    assert(ghostERC20Allowances128[_Licredity][any1][any2] == allowanceAny1Any2Prev, 
           "[INVARIANT] Other allowances must remain unchanged");
}

// EIP20-08: Verify transferFrom() reverts in invalid conditions
// EIP-20: "The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism."
// EIP-20: "Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event."
rule eip20_transferFromMustRevert(env e, address from, address to, uint256 amount) {

    setup(e);

    // Snapshot the 'from' balance and allowance
    mathint fromBalancePrev = ghostERC20Balances128[_Licredity][from];
    mathint allowancePrev = ghostERC20Allowances128[_Licredity][from][e.msg.sender];

    // Attempt the transferFrom with revert path
    transferFrom@withrevert(e, from, to, amount);
    bool reverted = lastReverted;

    assert(from == 0 => reverted, 
           "[SAFETY] TransferFrom from zero address must revert");

    assert(to == 0 => reverted, 
           "[SAFETY] TransferFrom to zero address must revert");

    assert(fromBalancePrev < amount => reverted, 
           "[EIP-20] TransferFrom must revert if from has insufficient balance");

    assert(e.msg.sender != from && allowancePrev < amount => reverted, 
           "[EIP-20] TransferFrom must revert if sender has insufficient allowance (when sender != from)");
}

// EIP20-09: Verify transferFrom() handles zero amount transfers correctly
// EIP-20: "Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event."
rule eip20_transferFromSupportZeroAmount(env e, address from, address to, uint256 amount) {

    setup(e);

    // Perform the transferFrom
    transferFrom(e, from, to, amount);

    // Zero amount transferFrom must succeed
    satisfy(amount == 0);
}

// EIP20-10: Verify approve() correctly sets allowances without affecting balances
// EIP-20: "Allows spender to withdraw from your account multiple times, up to the _value amount."
// EIP-20: "If this function is called again it overwrites the current allowance with _value."
rule eip20_approveIntegrity(env e, address spender, uint256 value) {

    setup(e);

    address other;
    address any1;
    address any2;

    require(other != e.msg.sender && other != spender, "Other address must not be involved in approve");

    // Capture pre-state
    mathint ownerBalancePrev = ghostERC20Balances128[_Licredity][e.msg.sender];
    mathint spenderBalancePrev = ghostERC20Balances128[_Licredity][spender];
    mathint otherBalancePrev = ghostERC20Balances128[_Licredity][other];
    mathint totalSupplyPrev = ghostERC20TotalSupply256[_Licredity];
    mathint allowanceAny1Any2Prev = ghostERC20Allowances128[_Licredity][any1][any2];

    // Perform the approve
    approve(e, spender, value);

    assert(ghostERC20Balances128[_Licredity][e.msg.sender] == ownerBalancePrev, 
           "[INVARIANT] Owner balance must remain unchanged during approve");
    assert(ghostERC20Balances128[_Licredity][spender] == spenderBalancePrev, 
           "[INVARIANT] Spender balance must remain unchanged during approve");
    assert(ghostERC20Balances128[_Licredity][other] == otherBalancePrev, 
           "[INVARIANT] Uninvolved addresses must maintain their balance");

    assert(ghostERC20TotalSupply256[_Licredity] == totalSupplyPrev, 
           "[INVARIANT] Total supply must remain unchanged");

    assert(any1 == e.msg.sender && any2 == spender 
        ? ghostERC20Allowances128[_Licredity][e.msg.sender][spender] == value
        : ghostERC20Allowances128[_Licredity][any1][any2] == allowanceAny1Any2Prev,
        "[EIP-20] Only the owner-spender allowance should change to the approved value"
    );
}

// EIP20-11: Verify approve() reverts in invalid conditions
// EIP-20: "NOTE: To prevent attack vectors like the one described here and discussed here,
// clients SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender.
// THOUGH The contract itself shouldn't enforce it, to allow backwards compatibility with contracts deployed before"
rule eip20_approveMustRevert(env e, address spender, uint256 value) {

    setup(e);

    // Attempt the approve with revert path
    approve@withrevert(e, spender, value);
    bool reverted = lastReverted;

    assert(spender == 0 => reverted, 
           "[SAFETY] Approve to zero address must revert");

    assert(e.msg.sender == 0 => reverted, 
           "[SAFETY] Approve from zero address must revert");
}
