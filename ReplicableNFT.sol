// SPDX-License-Identifier: MIT
// deploy tx https://goerli.etherscan.io/tx/0xa12f990dab849f99357ec4d9decb87ee34adf93976f0ac4731dbe725277c57e1
// contract address 0xf7159734Da9787F2b1007A9Eb8B56B61150c028E

// School → Student1 tx https://goerli.etherscan.io/tx/0x5e3f3a4559575913d4150e99176b103c0ad3b123649351045de71979ae8ac705
// Student1 → Company1 tx https://goerli.etherscan.io/tx/0x2b45f5f31a78cd7475c420e586c43d1349d648db21c1fd6f5bf51c56f2666f9d

// School → Student2 tx https://goerli.etherscan.io/tx/0x77cd7353c8f1158fa2b1e8d3d0449c5f944975de85b9e9053f8804eb3d279663
// Student2 → Company1 tx https://goerli.etherscan.io/tx/0x30ebeeea0b6a40c4858fe848a9c576ac7a9caf8a2ce1dd39513026a0081621eb
// Student2 → Company2 tx https://goerli.etherscan.io/tx/0x951ad59eb207cd3ee4366d5038502f40db52f2cbd0a61c155f53398d88d698ce

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
     * - 発行者を学校としてNFTを発行する _mint()
     * - mintの際にURIを設定 _setTokenURI()
     * - 学校のアドレスから学生のアドレスにNFTを送る safeTransferFrom()
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
        _mint(companyAddress, newTokenId);
        _setTokenURI(newTokenId, uri);

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
