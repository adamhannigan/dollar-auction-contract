// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract DollarAuction is ERC721 {
    using SafeMath for uint256;
        
    event HighestBidderChanged(address newBidder);
            
    address payable owner;

    struct Bid {
        address payable bidder;
        uint amount;
        string name;
        uint bidAt;
    }
    
    Bid[] public bids;
    
    uint DOLLAR_TOKEN_ID = 1;
    
    constructor() ERC721("DollarAuction", "DA") {
        owner = payable(msg.sender);
            
        // Dollar Auction is the first owner for a price of $0
        _mint(address(this), DOLLAR_TOKEN_ID);

        Bid memory initialBid = Bid({
            bidder: payable(address(this)),
            amount: 0,
            name: "Dollar Auction",
            bidAt: block.timestamp
        });
        
        bids.push(initialBid);
    }


    receive() external payable {}

    function bid(string memory name) public payable {
        Bid memory highestBid = bids[bids.length - 1];
        require(msg.sender != highestBid.bidder, "You are already the owner");

        uint minimumBid = highestBid.amount +  highestBid.amount.div(20);
        require(msg.value >= minimumBid, "Bid amount must be 5% higher than the previous bid");
        
        Bid memory newBid = Bid({
            bidder: payable(msg.sender),
            amount: msg.value,
            name: name,
            bidAt: block.timestamp
        });
        
        bids.push(newBid);
        
        // Transfer the NFT from second place to new owner
        _safeTransfer(highestBid.bidder, newBid.bidder, DOLLAR_TOKEN_ID, "");

        // Pay out royalties
        if (bids.length > 3) {
            Bid memory thirdPlace = bids[bids.length - 3];

            // 5% royalties distributed to previous owners
            uint royalties = thirdPlace.amount.div(20);

            uint value = thirdPlace.amount.add(royalties);
            (bool bidReturned, ) = thirdPlace.bidder.call{ value: value }("");
            require(bidReturned, "Bid return failed.");

            // 5% royalities distributed to designers
            (bool royalitiesPaid, ) = owner.call{ value: royalties }("");
            require(royalitiesPaid, "Designer royalties failed.");
        }

        emit HighestBidderChanged(msg.sender);
    }
    
    function leaderboard() public view returns (Bid[] memory) {
        return bids;
    }

    
    function _baseURI() internal pure override returns (string memory) {
        return "https://www.dollar-auction.com/nft/";
    }
    
    // Allow users to mint their bids
    function mint(address to, uint256 bidNumber) public {
        require(bidNumber <= bids.length - 2, "Cannot mint a token that is the first or second highest bid");

        require(bidNumber > DOLLAR_TOKEN_ID, "You cannot mint the original dollar");

        Bid memory bid = bids[bidNumber - 1];
        
        require(bid.bidder == msg.sender, "You are not the owner of the bid");
        
        _safeMint(to, bidNumber, "");
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(tokenId <= bids.length - 2, "Cannot transfer a token that is first or second highest bid");
        
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(tokenId <= bids.length - 2, "Cannot safe transfer a token that is first or second highest bid");
        
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(tokenId <= bids.length - 2, "Cannot safe transfer a token that is first or second highest bid");
        
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}
