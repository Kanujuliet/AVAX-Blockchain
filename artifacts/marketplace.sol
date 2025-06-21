// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract DataMarketplace {
    struct DataAsset {
        address uploader;
        string metadataURI;
        uint256 price;
    }

    IERC20 public token;
    address public owner;
    uint256 public feePercent = 3; // 3% platform fee
    uint256 private nextId = 1;

    mapping(uint256 => DataAsset) public dataAssets;
    mapping(uint256 => address[]) public dataBuyers;
    mapping(uint256 => mapping(address => bool)) public hasPurchased;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);  // ERC20 token address
        owner = msg.sender;
    }

    function uploadData(string calldata _metadataURI, uint256 _price) external {
        require(_price > 0, "Price must be positive");

        dataAssets[nextId] = DataAsset({
            uploader: msg.sender,
            metadataURI: _metadataURI,
            price: _price
        });

        nextId++;
    }

    function buyData(uint256 _dataId) external {
        DataAsset memory asset = dataAssets[_dataId];
        require(asset.price > 0, "Data does not exist");

        require(!hasPurchased[_dataId][msg.sender], "Already purchased");

        uint256 fee = (asset.price * feePercent) / 100;
        uint256 sellerShare = asset.price - fee;

        require(token.transferFrom(msg.sender, asset.uploader, sellerShare), "Seller payment failed");
        require(token.transferFrom(msg.sender, owner, fee), "Platform fee payment failed");

        dataBuyers[_dataId].push(msg.sender);
        hasPurchased[_dataId][msg.sender] = true;
    }

    function getMetadataURI(uint256 _dataId) external view returns (string memory) {
        require(hasPurchased[_dataId][msg.sender] || msg.sender == dataAssets[_dataId].uploader, "Access denied");
        return dataAssets[_dataId].metadataURI;
    }

    function setFeePercent(uint256 _newFee) external onlyOwner {
        require(_newFee <= 20, "Fee too high");
        feePercent = _newFee;
    }

    function getBuyers(uint256 _dataId) external view returns (address[] memory) {
        return dataBuyers[_dataId];
    }

    function getAllData() external view returns (DataAsset[] memory) {
        DataAsset[] memory assets = new DataAsset[](nextId - 1);
        for (uint256 i = 1; i < nextId; i++) {
            assets[i - 1] = dataAssets[i];
        }
        return assets;
    }
}
