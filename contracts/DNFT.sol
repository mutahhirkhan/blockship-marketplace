// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";


contract DNFT is ERC721{

    //                       V A R I A B L E  

    // If a token has been created
    mapping(uint => bool) mintedToken;

    //who owns the token (could be more than one)
    mapping(uint => address[]) tokenOwners;

    // Percentage of ownership over a token
    mapping(address => mapping(uint => uint)) ownerToTokenShare;

    // How much owners have of a token
    mapping(uint => mapping(address => uint)) tokenToOwnersHoldings;


    // Number of equal(fungible) units that constitute a token (that a token can be divised to)
    uint public divisibility = 100; // All tokens have the same divisibility in our example

    // total of managed/tracked tokens by this smart contract
    uint public totalSupply;

    event Minted (address owner, uint tokenId);
    event Transfer(address from, address to, uint tokenId, uint units);

    //                           C O N S T R U C T O R  
     constructor() ERC721("Noder's digital marketplace", "NDM") {}


    // ------------------------------ Modifiers ------------------------------
    modifier onlyNonExistentToken(uint _tokenId) {
        require(mintedToken[_tokenId] == false);
        _;
    }

    modifier onlyExistentToken(uint _tokenId) {
        require(mintedToken[_tokenId] == true);
        _;
    }


    //                       V I E W   F U N C T I O N S   ( N O   G A S   F E E ) 

    // The balance an owner have of a token
    function unitsOwnedOfAToken(address _owner, uint _tokenId) public view returns (uint _balance)
    {
        uint balanceOfAToken = ownerToTokenShare[_owner][_tokenId];
        return balanceOfAToken;
    }

    // list of owners who owns the particular share of nft 
    function listOfTokenOwners(uint _tokenId) public view returns(address [] memory) {
        return tokenOwners[_tokenId];
    }

    // the buyer who is making a purchase should not be seller itself
    function buyerIsNotSeller(uint _tokenId, address _seller) public view returns(bool isTrue){
        address [] memory owners = tokenOwners[_tokenId];
        for(uint128 i = 0; i<owners.length; i++) {
            if(owners[i] == _seller){
                return false;
            }
        }
        return true;
    }

    // this will remove the unnecessary owners (owners with zero shares) from the token owners list 
    function ownersWithZeroShare (uint _tokenId) public view returns(uint _index){
        address [] memory owners = tokenOwners[_tokenId];
        for(uint32 i = 0; i < owners.length; i++) {
            if(unitsOwnedOfAToken(owners[i], _tokenId) == 0) {
                return uint(i+1);
            }
        }
    }

    // don't duplicate the owner, just add share to the previous saved address
    function isUserAlreadyExist (address _user, uint _tokenId) public view returns (bool mayOrMayNot) {
        address [] memory owners = tokenOwners[_tokenId];
        for(uint32 i = 0; i < owners.length; i++) {
            if(owners[i] == _user) {
                return true;
            }
        }
        return false;
    }




    //                          C O R E   F U N C T I O N S (P U B L I C) 

    /// Anybody can create a token in our example
    /// whoever mint the token first, will have a 100% sare of it.
    function mint(address _owner, uint _tokenId) public onlyNonExistentToken (_tokenId)
    {
        mintedToken[_tokenId] = true;

        includeSharesToNewOwner(_owner, _tokenId, divisibility);
        addLatestOwnerHoldingsToToken(_owner, _tokenId, divisibility);

        totalSupply = totalSupply + 1;

        emit Minted(_owner, _tokenId); // emit event
    }

    /// transfer parts of a token to another user
    function transfer(address _to, uint _tokenId, uint _units) public onlyExistentToken (_tokenId)
    {
        require(ownerToTokenShare[msg.sender][_tokenId] >= _units);

        require(_to != address(0), "undefined address");
        require(msg.sender != _to, "owner to owner itself transfer is not allowed");
        require(_to != address(this), "deployer can't have a nft share");
        // will check _to address on frontend using "web3.utils.toChecksumAddress(rawInput)"

        excludeShareOfPreviousOwner(msg.sender, _tokenId, _units);
        subtractPreviousOwnerHoldings(msg.sender, _tokenId, _units);

        includeSharesToNewOwner(_to, _tokenId, _units);
        addLatestOwnerHoldingsToToken(_to, _tokenId, _units);

        //this will pop out the owners with zero holding over a token
        uint res = ownersWithZeroShare(_tokenId);
        if(res != 0) {
                address [] storage owners = tokenOwners[_tokenId];
                owners[res-1] = owners[owners.length - 1];
                owners.pop();
                tokenOwners[_tokenId] = owners;
            }

        emit Transfer(msg.sender, _to, _tokenId, _units); // emit event
    }
    

    //                               P O  W E R   F U N C T I O N S 

    // Remove token units from last owner
    function excludeShareOfPreviousOwner(address _owner, uint _tokenId, uint _units) internal
    {
        ownerToTokenShare[_owner][_tokenId] -= _units;
    }

    // Add token units to new owner
    function includeSharesToNewOwner(address _owner, uint _tokenId, uint _units) internal
    {
        ownerToTokenShare[_owner][_tokenId] += _units;
    }

    // Remove units from last owner
    function subtractPreviousOwnerHoldings(address _owner, uint _tokenId, uint _units) internal
    {
        tokenToOwnersHoldings[_tokenId][_owner] -= _units;
    }

    // Add the units to new owner
    function addLatestOwnerHoldingsToToken(address _owner, uint _tokenId, uint _units) internal
    {
        tokenToOwnersHoldings[_tokenId][_owner] += _units;

        // avoid reEntrance of a user for the same token.
        if(!isUserAlreadyExist(_owner, _tokenId)){
            tokenOwners[_tokenId].push(_owner);
        }
    }
}