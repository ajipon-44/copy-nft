// SPDX-License-Identifier: MIT
// https://goerli.etherscan.io/address/0xcf7D54A81ebe40e5972b0B607dcC116a26f462fE

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";

contract CopyNFT is ERC721URIStorage, Ownable {

    constructor() ERC721("CopyNFT", "CNFT") {}

    /**
     * @dev
     * - 学校用のMint関数
     * - 発行者を学校としてNFTを発行する _mint()
     * - mintの際にURIを設定 _setTokenURI()
     * - 学校のアドレスから学生のアドレスにNFTを送る safeTransferFrom()
    */
    function mintAndTransferFromSchoolToStudent(uint256 tokenId, string calldata uri, address studentAddress) public onlyOwner {
        _mint(_msgSender(), tokenId);
        _setTokenURI(tokenId, uri);
        safeTransferFrom(_msgSender(), studentAddress, tokenId);
    }

    /**
     * @dev
     * - 学生用のMint関数
     * - 学校が発行した原本のNFTのtokenURIを取得するtokenURI()
     * - 発行者を学生としてNFTを発行する _mint()
     * - mintの際にURIを設定(URIは原本と同じ) _setTokenURI()
     * - 学生のアドレスから企業のアドレスにNFTを送る safeTransferFrom()
    */
    function mintAndTransferFromStudentToCompany(uint256 originalTokenId, uint256 CopyTokenId, address companyAddress) public {
        string memory uri = tokenURI(originalTokenId);
        _mint(_msgSender(), CopyTokenId);
        _setTokenURI(CopyTokenId, uri);
        safeTransferFrom(_msgSender(), companyAddress, CopyTokenId);
    }
}
