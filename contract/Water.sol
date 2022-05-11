//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./NFT.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//prevents re-entrancy attacks
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 

contract Water is ReentrancyGuard {
   using Counters for Counters.Counter;
   Counters.Counter private _groundIds;
   Counters.Counter private _groundSold;
   Counters.Counter private _groundDeleted;

   address payable owner;

   uint256 listingPrice = 0.025 ether; 

   constructor() {
      owner = payable(msg.sender);
   } 

   struct Ground {
      uint groundId;
      address nftContract;
      uint256 tokenId;
      address payable seller;
      address payable owner;
      uint256 price;
      bool sold;
   }

   //ID를 입력하면 Ground struct에서 value들을 접근 가능
   mapping(uint256 => Ground) private idGround;

   //땅이 팔렸을 때 log msg 출력
   event GroundCreated (
      uint indexed groundId,
      address indexed nftContract,
      uint256 indexed tokenId,
      address seller,
      address owner,
      uint256 price,
      bool sold
   );
    event GroundDeleted (
    uint indexed groundId
  );
  event ProductListed( 
    uint indexed groundId
  );

   function getListingPrice() public view returns (uint256) {
      return listingPrice;
   }

   function setListingPrice(uint _price) public returns (uint) {
      if(msg.sender == address(this)) {
         listingPrice = _price;
      }
      return listingPrice;
   }

   function createGround(address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {
      require(price > 0, "Price must be above zero");

      _groundIds.increment();
      uint256 groundId = _groundIds.current();

      idGround[groundId] = Ground (
         groundId,
         nftContract,
         tokenId,
         payable(msg.sender),
         payable(address(0)),
         price,
         false
      );

      IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

      emit GroundCreated(
         groundId,
         nftContract,
         tokenId,
         msg.sender,
         address(0),
         price,
         false
      );
   }

   //구매시
   function createGroundSale(address nftContract, uint256 groundId) public payable nonReentrant {
      uint price = idGround[groundId].price;
      uint tokenId = idGround[groundId].tokenId;

      require(msg.value == price, "Please submit the asking price in order to complete purchase");

      idGround[groundId].seller.transfer(msg.value);

      IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

      idGround[groundId].owner = payable(msg.sender);
      idGround[groundId].sold = true;
      _groundSold.increment();
      //payable(owner).transfer(listingPrice);
   }
   modifier onlyItemOwner(uint256 id) {
        require(
            idGround[id].owner == msg.sender,
            "Only product owner can do this operation"
        );
        _;
    }
    
   modifier onlyProductOrMarketPlaceOwner(uint256 id) {
        require(
            idGround[id].owner == address(this),
            "Only product or market owner can do this operation"
        );
        _;
    }

    function putItemToResell(address nftContract, uint256 groundId, uint256 newPrice)
        public
        payable
        nonReentrant
        onlyItemOwner(groundId)
    {
        uint256 tokenId = idGround[groundId].tokenId;
        require(newPrice > 0, "Price must be at least 1 wei");
        
        // require(msg.value == listingPrice, "Price must be equal to listing price");
    
        NFT tokenContract = NFT(nftContract);

        tokenContract.transferToken(msg.sender, address(this), tokenId);
       
        address payable oldOwner = idGround[groundId].owner;
        idGround[groundId].owner = payable(address(0));
        idGround[groundId].seller = oldOwner;
        idGround[groundId].price = newPrice;
        idGround[groundId].sold = false;
        _groundSold.decrement();

        emit ProductListed(groundId);
    }

     function transferFrom(address nftContract, uint256 groundId) public payable nonReentrant {
        //solhint-disable-next-line max-line-length
        uint tokenId = idGround[groundId].tokenId;
        idGround[groundId].owner = payable(address(this));
        idGround[groundId].sold = false;
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    }

   function fetchGrounds() public view returns(Ground[] memory) {
         uint groundCount = _groundIds.current(); //total number of items ever created
         //total number of items that are unsold = total items ever created - totla items sold
         uint unsoldGroundCount = _groundIds.current() - _groundSold.current();
         uint currentIndex = 0;

         Ground[] memory grounds = new Ground[](unsoldGroundCount);
         
         //loop through all items ever created
         for(uint i = 0; i < groundCount; i++){
            //get only unsold item
            //check if the item has not been sold
            //by checking if the owner field is empty
            if(idGround[i+1].owner == address(0)) {
               //yes this item has never been sold
               uint currentId = idGround[i + 1].groundId;
               Ground storage currentItem = idGround[currentId];
               grounds[currentIndex] = currentItem;
               currentIndex += 1;
            }
         }
         return grounds; //return array of all unsold items
   }
   function fetchMyGrounds() public view returns (Ground[] memory) {
      uint groundCount = _groundIds.current();
      uint unsoldGroundCount = _groundIds.current() - _groundSold.current();
      uint currentIndex = 0;

      Ground[] memory grounds = new Ground[](unsoldGroundCount);

      for (uint256 i = 0; i < groundCount; i++) {
         if(idGround[i+1].owner == address(0)) {
            uint currentId = idGround[i + 1].groundId;
            Ground storage currentGround = idGround[currentId];
            grounds[currentIndex] = currentGround;
            currentIndex += 1;
         }
      }
      return grounds;
   }

   function fetchgroundsCreated() public view returns (Ground[] memory) {
      //get total number of items ever created
      uint totalItemCount = _groundIds.current();

      uint groundCount = 0;
      uint currentIndex = 0;

      for(uint i = 0; i < totalItemCount; i++) {
         //get only the items that this user has bought/is the seller
         if(idGround[i+1].seller == msg.sender) {
            groundCount += 1; //total myNFT length
         }
      }
      Ground[] memory grounds = new Ground[](groundCount);
      for(uint i = 0; i < totalItemCount; i++) {
         if(idGround[i+1].seller == msg.sender) {
            uint currentId = idGround[i+1].groundId;
            Ground storage currentItem = idGround[currentId];
            grounds[currentIndex] = currentItem;
            currentIndex += 1;
         }
      }
      return grounds;
   }
}