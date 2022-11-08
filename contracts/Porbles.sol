// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/IERC20.sol";
import "./lib/ERC721Royalty.sol";
import "./lib/Ownable.sol";

contract Porbles is ERC721Royalty, Ownable {
    // An ERC-20 token that is accepted as payment for the minting of the tokens (e.g. WAVAX)
    address tokenToPay;

    constructor(uint96 royaltyFeeNumerator)
        ERC721("Porbles", "PBS")
    {
        _setDefaultRoyalty(owner(), royaltyFeeNumerator);
    }

    function safeMint(
        address to,
        uint256 tokenId,
    ) public {
        IERC20(tokenToPay).transferFrom(
            msg.sender,
            address(this),
            10
        );
        _safeMint(to, tokenId);
    }
}
