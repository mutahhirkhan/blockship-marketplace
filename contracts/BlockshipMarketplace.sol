// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //modifier for non-reentrance

import "./DNFT.sol";

import "hardhat/console.sol";
contract BlockshipMaketplace is ReentrancyGuard, DNFT{
    address public marketplaceOwner;
    using Counters for Counters.Counter;
    Counters.Counter private itemId;   //unique id for every marketplace itemsId
    Counters.Counter private itemsSold; //this would help in to keep track of items are on sale currently e.g.(itemsId - itemsSold)

    //                  C O S N T R U C T O R
    constructor () { marketplaceOwner = msg.sender;}

    //                  V A R I A B L E S 
    struct MarketItem {
        uint itemId;    //unique identifier
        address nftContract;    //contract address for digital asset
        uint256 tokenId;   //asset id
        address payable seller; //person putting item on sale
        address payable owner;  //initially empty because yet not sold
        uint256 price; //price on sale
    }

    //retrieve specific data of item and return marketItem detail of it
    mapping(uint => MarketItem) private idToMarketItem; 


    //              E V E N  T S
    //triggeres when marketItem sold or put on sale
    //use for graph protocol to index the data from smart contract
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );

    event ItemSold(address seller, address buyer, address nft, uint256 tokenId, uint256 price);


    //                   C O R E    F U N C T I O N S
    //nft put on sale
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "NFT_MARKETPLACE: Invalid Price");
        itemId.increment();
        uint256 _itemId = itemId.current();

        //              I T E M    P U T    O N    S A L  E
        idToMarketItem[_itemId] = MarketItem(_itemId, nftContract, tokenId, payable(msg.sender), payable(address(0)), price);
        address  whoPutOnSale = idToMarketItem[_itemId].seller;

        emit MarketItemCreated(_itemId, nftContract, tokenId, msg.sender, address(0), price);
    }


    //                       M A R K E T P L A C E   I T E M   S O L D 
    function createMarketSale (address _nftContract, uint _itemId) public payable nonReentrant {
        require(msg.sender != address(0), "undefined owner address");
        MarketItem storage _item = idToMarketItem[_itemId];
        uint price = _item.price;
        uint tokenId = _item.tokenId;

        require(msg.value == price, "please send the required amount to process ");
        address [] memory ownersOfNFT = listOfTokenOwners(tokenId);
        
        // T R A N S F E R  - A M O U N T  -  R E G A R D I N G  - T H E -   OW N E R S - H O L D I N G
        for(uint128 i = 0; i<ownersOfNFT.length; i++) {
            uint sharePercent = (ownerToTokenShare[ownersOfNFT[i]][tokenId]/divisibility)*100;
            uint toSend = (price * sharePercent ) / 100;
            payable(ownersOfNFT[i]).call{value: toSend};
        }
        //          C H A N G E   O W N E R S H I P   O F  I T E  M
        idToMarketItem[_itemId].owner = payable(msg.sender);
        itemsSold.increment();
        emit ItemSold(_item.seller, msg.sender, _nftContract, _itemId, _item.price);
    }

//                          A L L   T H E   I T E M S   T H A T  A R E   O N   S A L E
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = itemId.current();
        uint256 unSoldItemCount = itemCount - itemsSold.current();
        uint256 currentIndex = 0;

        //the length of this array will be unsoldItems
        MarketItem[] memory allMarketItems = new MarketItem[](unSoldItemCount); 
        for (uint256 i = 0; i < itemCount; i++) {
            //check for unsold items
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                allMarketItems[currentIndex] = currentItem;
                currentId++;
            }
        }
        return allMarketItems;
    }

}