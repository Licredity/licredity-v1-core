// CVL implementation redirecting NonFungible type methods to internal CVL implementations of ERC721 transfers

methods {
    function NonFungibleLibrary.transfer(LicredityHarness.NonFungible nf, address recipient) internal
        => transferFromERC721CVL(
            ghostNonFungibleTokenAddress[nf], 
            currentContract, 
            currentContract, 
            recipient, 
            ghostNonFungibleTokenId[nf]
        );

    function NonFungibleLibrary.owner(LicredityHarness.NonFungible nf) internal returns (address)
        => ownerOfERC721CVL(ghostNonFungibleTokenAddress[nf], ghostNonFungibleTokenId[nf]);
        
    function NonFungibleLibrary.tokenAddress(LicredityHarness.NonFungible nf) internal returns (address)
        => ghostNonFungibleTokenAddress[nf];
        
    function NonFungibleLibrary.tokenId(LicredityHarness.NonFungible nf) internal returns (uint256)
        => require_uint256(ghostNonFungibleTokenId[nf]);
}

persistent ghost mapping(LicredityHarness.NonFungible => address) ghostNonFungibleTokenAddress {
    // Zero NonFungible (empty) must have zero address and tokenId, and vice versa
    axiom forall LicredityHarness.NonFungible nf. 
        nf == to_bytes32(0) <=> (ghostNonFungibleTokenAddress[nf] == 0 && ghostNonFungibleTokenId[nf] == 0);
    // NonFungibles with same address and tokenId must be the same bytes32 value
    axiom forall LicredityHarness.NonFungible nf1. forall LicredityHarness.NonFungible nf2.
        (ghostNonFungibleTokenAddress[nf1] == ghostNonFungibleTokenAddress[nf2] && 
         ghostNonFungibleTokenId[nf1] == ghostNonFungibleTokenId[nf2])
            => nf1 == nf2;
}

persistent ghost mapping(LicredityHarness.NonFungible => uint64) ghostNonFungibleTokenId;