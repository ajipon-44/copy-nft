// SPDX-License-Identifier: MIT
// 0x17660D828a03E6E085eF403E178c4eea21f977F3

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";

interface ISchoolContract{
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract StudentContract is ERC721URIStorage, Ownable {
    /**
     * @dev
     * - _tokenIdsはCountersの全関数を使用可能
    */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("StudentToken", "StT") {}

    // 使用したいコントラクト(Schoolコントラクト)のイーサリアム上のアドレス
    address SchoolContractAddress = 0x72d9908aB29694287Ad68062a1B32ecED72C67A4;
    ISchoolContract schoolContract = ISchoolContract(SchoolContractAddress);

    /**
     * @dev
     * - defaultで0のトークンIDをインクリメントする _tokenIds.increment()
     * - インクリメントしたトークンIDを変数newTokenIdに入れる
     * - 学生用のMint関数
     * - 学校が発行した原本のNFTのtokenURIを取得するtokenURI()
     * - 発行者を学生としてNFTを発行する _mint()
     * - mintの際にURIを設定(URIは原本と同じ) _setTokenURI()
     * - 学生のアドレスから企業のアドレスにNFTを送る safeTransferFrom()
    */
    function mintAndTransferToCompany(uint256 originalTokenId, address companyAddress) public onlyOwner {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        string memory originalURI = ISchoolContract(schoolContract).tokenURI(originalTokenId);
        _mint(_msgSender(), newTokenId);
        _setTokenURI(newTokenId, originalURI);
        safeTransferFrom(_msgSender(), companyAddress, newTokenId);
    }
}
