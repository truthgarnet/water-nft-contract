//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721URIStorage, Ownable{
    
    //auto-increment field for each token
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string public fileExtention = ".json";
    //address of the NFT market place 
    address contractAddress;
    using Strings for uint256;

    mapping(address => bool) public isAdmin;

    modifier onlyAdmin() {
        require( isAdmin[_msgSender()] || owner() == _msgSender(), "caller has no minting right!!!");
        _;
    }

    constructor(address waterAddress) ERC721("WaterNFT Tokens", "WNT"){
        contractAddress = waterAddress;
    }

    /// @notice create a new token
    /// @param tokenuri : token URI
    function createToken(string memory tokenuri) public onlyAdmin returns(uint) {
        //set a new token Id for the token to be minted
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId); //mint the token
        _setTokenURI(newItemId, tokenuri); //generate the URI
        setApprovalForAll(contractAddress, true); //grant transaction permisiion to marketplace

        //return token Id
        return newItemId;
    } 

    //https://gateway.pinata.cloud/ipfs/QmZFWm8imSxuBXm2HphsyoQcZj4cvgeCtSAqKcdkNnw7C3/ , 1, 100 ~ 100, 208
    function batchMint(string memory tokenuri, uint amount_from, uint amount_to) public onlyAdmin {
        for(uint i = amount_from; i < amount_to; i++) {
            createToken(tokenuri);
        }
    }

    function tokenURI(uint256 tokenId) public override view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory uri = "https://gateway.pinata.cloud/ipfs/QmZFWm8imSxuBXm2HphsyoQcZj4cvgeCtSAqKcdkNnw7C3/";
        return bytes(uri).length >= 0 ? string(abi.encodePacked(uri, tokenId.toString(), fileExtention)): "";
    }

    function transferToken(address from, address to, uint256 tokenId) external {
        require(ownerOf(tokenId) == from, "From address must be token owner");
        _transfer(from, to, tokenId);
    }

    function addAdmin(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "admin Address is the zero address");
        isAdmin[adminAddress] = true;
   }

   function removeAdmin(address adminAddress) public onlyOwner {
        require(adminAddress != address(0), "admin Address is the zero address");
       isAdmin[adminAddress] = true;
   }

   function blackListAddress(address userAddress) public onlyAdmin {
        require(userAddress != address(0), "userAddress  is the zero address");
       isAdmin[userAddress] = false;
   }

}