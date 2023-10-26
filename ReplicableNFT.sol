// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/utils/Counters.sol";

contract ReplicableNFT is ERC721URIStorage {
    /**
     * @dev
     * - _tokenIdsはCountersの全関数を使用可能
    */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => address) public _nextCompanies;
    mapping(address => address[]) public sentLogs;
    uint256 public listSize;
    address constant zeroAddress = address(0);

    constructor() ERC721("ReplicableNFT", "RNFT") {
        _nextCompanies[zeroAddress] = zeroAddress;
    }

    /**
     * @dev
     * - 学校用のMint関数
     * - defaultで0のトークンIDをインクリメントする _tokenIds.increment()
     * - インクリメントしたトークンIDを変数newTokenIdに入れる
     * - 発行者を学校として学生にNFTを発行する _mint()
     * - mintの際にURIを設定 _setTokenURI()
    */
    function mintAndTransferFromSchoolToStudent(string calldata uri, address studentAddress) public {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(studentAddress, newTokenId);
        _setTokenURI(newTokenId, uri);
    }

    /**
     * @dev
     * - 学生用のMint関数
     * - 所有していないoriginalTokenIdにアクセスしようとした場合はリクエストを拒否する require
     * - 既にエントリーしたことのある企業に対してNFTを送信しようとした場合はリクエストを拒否する require
     * - defaultで0のトークンIDをインクリメントする _tokenIds.increment()
     * - インクリメントしたトークンIDを変数newTokenIdに入れる
     * - 学校が発行した原本のNFTのtokenURIを取得するtokenURI()
     * - 発行者を学生として企業にNFTを発行する _mint()
     * - mintの際にURIを設定(URIは原本と同じ) _setTokenURI()
     * - NFTの送信履歴に学生→企業という形で記録する
     * - 企業のNFTの所持数が1ならaddCompany，それ以上ならupdateNFTCount
    */
    function mintAndTransferFromStudentToCompany(uint256 originalTokenId, address companyAddress) public {
        require(ownerOf(originalTokenId) == _msgSender(), "caller is not the owner of the token");

        address[] memory sentLog = sentLogs[msg.sender];
        for (uint256 i = 0; i < sentLog.length; i++) {
            require(sentLog[i] != companyAddress, "Already entried");
        }

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        string memory uri = tokenURI(originalTokenId);
        _mint(companyAddress, newTokenId);
        _setTokenURI(newTokenId, uri);

        sentLogs[_msgSender()].push(companyAddress);

        uint256 NFTCount = balanceOf(companyAddress);

        if(NFTCount == 1){
            addCompany(companyAddress, NFTCount);
        } else {
            updateNftCount(companyAddress, NFTCount);
        }
    }

    function _verifyIndex(address prevCompany, uint256 newValue, address nextCompany) internal view returns(bool){
        return (prevCompany == zeroAddress || balanceOf(prevCompany) >= newValue) &&
               (nextCompany == zeroAddress || newValue > balanceOf(nextCompany));
    }

    function _findIndex(uint256 newValue) internal view returns(address){
        address candidateAddress = zeroAddress;
        while(true){
            if(_verifyIndex(candidateAddress, newValue, _nextCompanies[candidateAddress]))
                return candidateAddress;
            candidateAddress = _nextCompanies[candidateAddress];
        }
    }

    function addCompany(address company, uint256 value) public {
        require(_nextCompanies[company] == address(0));
        address index = _findIndex(value);
        _nextCompanies[company] = _nextCompanies[index];
        _nextCompanies[index] = company;
        listSize++;
    }

    function _isPrevCompany(address company, address prevCompany) internal view returns(bool){
        return _nextCompanies[prevCompany] == company;
    }

    function _findPrevCompany(address company) internal view returns(address){
        address currentAddress = zeroAddress;
        while(_nextCompanies[currentAddress] != zeroAddress){
            if(_isPrevCompany(company, currentAddress))
                return currentAddress;
            currentAddress = _nextCompanies[currentAddress];
        }
        return address(0);
    }

    function removeCompany(address company) public {
        //require(_nextCompanies[company] != address(0));
        address prevCompany = _findPrevCompany(company);
        _nextCompanies[prevCompany] = _nextCompanies[company];
        _nextCompanies[company] = address(0);
        listSize--;
    }

    function updateNftCount(address company, uint256 newValue) public {
        //require(_nextCompanies[company] != address(0));
        address prevCompany = _findPrevCompany(company);
        address nextCompany = _nextCompanies[company];
        if(_verifyIndex(prevCompany, newValue, nextCompany) == false){
            removeCompany(company);
            addCompany(company, newValue);
        }
    }

    /**
     * @dev
     * - 指定した企業の順位を返す関数
    */
    function getRankOfComapny(address company) public view returns(uint256){
        require(company != address(0));
        uint256 rank = 0;
        address currentAddress = zeroAddress;
        while(currentAddress != company){
            currentAddress = _nextCompanies[currentAddress];
            rank++;
        }
        return rank;
    }

    /**
     * @dev
     * - 上位k位の順位を返す関数
    */
    function getTop(uint256 k) public view returns(address[] memory){
        require(k <= listSize, "k is greater than listSize, Specify k less than listSize");
        address[] memory companiesList = new address[](k);
        address currentAddress = _nextCompanies[zeroAddress];
        for(uint256 i = 0; i < k; ++i){
            companiesList[i] = currentAddress;
            currentAddress = _nextCompanies[currentAddress];
        }
        return companiesList;
    }
}
