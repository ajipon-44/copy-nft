// SPDX-License-Identifier: MIT
// https://goerli.etherscan.io/address/0xcf7D54A81ebe40e5972b0B607dcC116a26f462fE

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";

contract CopyNFT is ERC721URIStorage, Ownable {
    /**
     * @dev
     * - _tokenIdsはCountersの全関数を使用可能
    */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("CopyNFT", "CNFT") {}

    /**
     * @dev
     * - 学校用のMint関数
     * - defaultで0のトークンIDをインクリメントする _tokenIds.increment()
     * - インクリメントしたトークンIDを変数newTokenIdに入れる
     * - 発行者を学校としてNFTを発行する _mint()
     * - mintの際にURIを設定 _setTokenURI()
     * - 学校のアドレスから学生のアドレスにNFTを送る safeTransferFrom()
    */
    function mintAndTransferFromSchoolToStudent(string calldata uri, address studentAddress) public onlyOwner {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(_msgSender(), newTokenId);
        _setTokenURI(newTokenId, uri);
        safeTransferFrom(_msgSender(), studentAddress, newTokenId);
    }

    /**
     * @dev
     * - 学生用のMint関数
     * - 自分以外のoriginalTokenIdにアクセスしようとした場合はリクエストを拒否する require
     * - defaultで0のトークンIDをインクリメントする _tokenIds.increment()
     * - インクリメントしたトークンIDを変数newTokenIdに入れる
     * - 学校が発行した原本のNFTのtokenURIを取得するtokenURI()
     * - 発行者を学生としてNFTを発行する _mint()
     * - mintの際にURIを設定(URIは原本と同じ) _setTokenURI()
     * - 学生のアドレスから企業のアドレスにNFTを送る safeTransferFrom()
    */
    function mintAndTransferFromStudentToCompany(uint256 originalTokenId, address companyAddress) public {
        require(ownerOf(originalTokenId) == _msgSender(), "caller is not the owner of the token");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        string memory uri = tokenURI(originalTokenId);
        _mint(_msgSender(), newTokenId);
        _setTokenURI(newTokenId, uri);
        safeTransferFrom(_msgSender(), companyAddress, newTokenId);
    }
}
