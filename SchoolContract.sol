// SPDX-License-Identifier: MIT
// 0x72d9908aB29694287Ad68062a1B32ecED72C67A4

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";

contract SchoolContract is ERC721URIStorage, Ownable {
    /**
     * @dev
     * - _tokenIdsはCountersの全関数を使用可能
    */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("SchoolToken", "ScT") {}

    /**
     * @dev
     * - defaultで0のトークンIDをインクリメントする _tokenIds.increment()
     * - インクリメントしたトークンIDを変数newTokenIdに入れる
     * - 学校用のMint関数
     * - 発行者を学校としてNFTを発行する _mint()
     * - mintの際にURIを設定 _setTokenURI()
     * - 学校のアドレスから学生のアドレスにNFTを送る safeTransferFrom()
    */
    function mintAndTransferToStudent(string calldata uri, address studentAddress) public onlyOwner {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(_msgSender(), newTokenId);
        _setTokenURI(newTokenId, uri);
        safeTransferFrom(_msgSender(), studentAddress, newTokenId);
    }
}
