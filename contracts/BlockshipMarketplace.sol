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

    constructor () {
        marketplaceOwner = msg.sender;
    }

    struct MarketItem {
        uint itemId;    //unique identifier
        address nftContract;    //contract address for digital asset
        uint256 tokenId;   //asset id
        address payable seller; //person putting item on sale
        address payable owner;  //initially empty because yet not sold
        uint256 price; //price on sale
    }

    mapping(uint => MarketItem) private idToMarketItem; //retrieve specific data of item and return marketItem detail of it

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
    //nft put on sale
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        console.log("item put on sale with a price of: ");
        require(price > 0, "NFT_MARKETPLACE: Invalid Price");
        itemId.increment();
        uint256 _itemId = itemId.current();

        console.log(price);
        //item put on sale
        idToMarketItem[_itemId] = MarketItem(_itemId, nftContract, tokenId, payable(msg.sender), payable(address(0)), price);
        address  whoPutOnSale = idToMarketItem[_itemId].seller;
        console.log("whoPutOnSale");
        console.log(whoPutOnSale);

        // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketItemCreated(_itemId, nftContract, tokenId, msg.sender, address(0), price);
    }

    function createMarketSale (address _nftContract, uint _itemId) public payable nonReentrant {
        require(msg.sender != address(0), "undefined owner address");
        MarketItem storage _item = idToMarketItem[_itemId];
        uint price = _item.price;
        uint tokenId = _item.tokenId;

        require(msg.value == price, "please send the required amount to process ");
        address [] memory ownersOfNFT = listOfTokenOwners(tokenId);
        
        for(uint128 i = 0; i<ownersOfNFT.length; i++) {
            uint sharePercent = (ownerToTokenShare[ownersOfNFT[i]][tokenId]/divisibility)*100;
            uint toSend = (price * sharePercent ) / 100;
            payable(ownersOfNFT[i]).call{value: toSend};
            
        }

        // idToMarketItem[_itemId].seller.transfer(msg.value);
        // IERC721(_nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[_itemId].owner = payable(msg.sender);
        itemsSold.increment();
        emit ItemSold(_item.seller, msg.sender, _nftContract, _itemId, _item.price);
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = itemId.current();
        uint256 unSoldItemCount = itemCount - itemsSold.current();
        uint256 currentIndex = 0;

        console.log(unSoldItemCount);
        MarketItem[] memory allMarketItems = new MarketItem[](unSoldItemCount); //the length of this array will be unsoldItems
        for (uint256 i = 0; i < itemCount; i++) {
            //check for unsold items
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                console.log(currentItem.price);
                allMarketItems[currentIndex] = currentItem;
                currentId++;
            }
        }
        // console.log(allMarketItems);
        // console.log(allMarketItems);
        return allMarketItems;
    }

}