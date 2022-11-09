// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Ownable.sol";
import "./lib/IERC20.sol";
import "./lib/IERC721.sol";
import "./lib/IERC2981.sol";
import "./lib/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard, Ownable {
    // Structs
    struct Listing {
        uint256 price;
        address seller;
    }

    // Events
    event ItemListed(
        address indexed NFTAddress,
        uint256 indexed tokenId,
        address indexed sellerAddress
        uint256 price
    );

    event ItemCancelled(
        address indexed NFTAddress,
        uint256 indexed tokenId,
        address indexed sellerAddress
    );

    event ItemBought(
        address indexed NFTAddress,
        uint256 indexed tokenId,
        address indexed sellerAddress
        uint256 price,
    );

    event ItemUpdated(
        address indexed NFTAddress,
        uint256 indexed tokenId,
        address indexed sellerAddress
        uint256 price,
    );

    // Modifiers
    modifier notListed(
        address NFTAddress,
        uint256 tokenId,
        address owner
    ) {
        require(listings[NFTAddress][tokenId].seller != owner, "NFT already listed by its current owner")
    }

    modifier isNFTOwner(
        address NFTAddress,
        uint256 tokenId,
        address spender
    ) {
        require(
            IERC721(NFTAddress).ownerOf(tokenId) == spender,
            "Not NFT owner"
        );
    }

    modifier isListed(address NFTAddress, uint256 tokenId) {
        require(
            bytes(listings[NFTAddress][tokenId]).length > 0,
            "NFT not listed"
        );
    }

    // An ERC-20 token that is accepted as payment in the marketplace (e.g. WAVAX)
    address tokenToPay;

    mapping(address => mapping(uint256 => Listing)) private listings;

    constructor(address _tokenToPay) {
        tokenToPay = _tokenToPay;
    }

    function listItem(
        address NFTAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(NFTAddress, tokenId, msg.sender)
        isNFTOwner(NFTAddress, tokenId, msg.sender)
    {
        require(price > 0, "Price must be above zero");
        require(
            IERC721(NFTAddress).getApproved(tokenId) == address(this),
            "Not approved for marketplace"
        );
        listings[NFTAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(NFTAddress, tokenId, msg.sender, price);
    }

    function cancelListing(address NFTAddress, uint256 tokenId)
        external
        isNFTOwner(NFTAddress, tokenId, msg.sender)
        isListed(NFTAddress, tokenId)
    {
        delete (listings[NFTAddress][tokenId]);
        emit ItemCancelled(NFTAddress, tokenId, msg.sender);
    }

    function buyItem(address NFTAddress, uint256 tokenId)
        external
        isListed(NFTAddress, tokenId)
    {
        Listing memory listedItem = listings[NFTAddress][tokenId];

        delete (listings[NFTAddress][tokenId]);

        address royaltyReceiver;
        uint256 royaltyAmount;
        (royaltyReceiver, royaltyAmount) = IERC2981(NFTAddress).royaltyInfo(tokenId, listedItem.price);

        IERC20(tokenToPay).transferFrom(
            msg.sender,
            listedItem.seller,
            listedItem.price - royaltyAmount
        );
        IERC20(tokenToPay).transferFrom(
            msg.sender,
            royaltyReceiver,
            royaltyAmount
        );

        IERC721(NFTAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            tokenId
        );

        emit ItemBought(NFTAddress, tokenId, listedItem.seller);
    }

    function updateListing(
        address NFTAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(NFTAddress, tokenId)
        isNFTOwner(NFTAddress, tokenId, msg.sender)
    {
        require(newPrice > 0, "Price must be above zero");
        listings[NFTAddress][tokenId].price = newPrice;

        emit ItemUpdated(NFTAddress, tokenId, msg.sender, listedItem.price);
    }

    function getListing(address NFTAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[NFTAddress][tokenId];
    }
}
