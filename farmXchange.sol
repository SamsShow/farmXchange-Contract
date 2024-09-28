// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FarmerMarketplace {
    uint256 public productCount = 0;
    uint256 public farmerCount = 0;

    struct Product {
        uint256 id;
        address payable farmer;
        string name;
        uint256 price;
        uint256 quantity;
        string ipfsHash;
    }

    struct Farmer {
        address farmerAddress;
        string name;
        bool isRegistered;
    }

    mapping(uint256 => Product) public products;
    mapping(address => Farmer) public farmers;

    event FarmerRegistered(address farmerAddress, string name);
    event ProductAdded(uint256 id, string name, uint256 price, uint256 quantity);
    event ProductPurchased(uint256 id, address buyer, uint256 quantity);

    modifier onlyRegisteredFarmer() {
        require(farmers[msg.sender].isRegistered, "Only registered farmers can perform this action");
        _;
    }

    function registerFarmer(string memory _name) public {
        require(!farmers[msg.sender].isRegistered, "Farmer already registered");
        farmers[msg.sender] = Farmer(msg.sender, _name, true);
        farmerCount++;
        emit FarmerRegistered(msg.sender, _name);
    }

    function addProduct(string memory _name, uint256 _price, uint256 _quantity, string memory _ipfsHash) public onlyRegisteredFarmer {
        require(_price > 0, "Price must be greater than 0");
        require(_quantity > 0, "Quantity must be greater than 0");
        
        productCount++;
        products[productCount] = Product(productCount, payable(msg.sender), _name, _price, _quantity, _ipfsHash);
        emit ProductAdded(productCount, _name, _price, _quantity);
    }

    function purchaseProduct(uint256 _id, uint256 _quantity) public payable {
        Product storage product = products[_id];
        require(_id > 0 && _id <= productCount, "Invalid product ID");
        require(product.quantity >= _quantity, "Not enough quantity available");
        require(msg.value >= product.price * _quantity, "Insufficient payment");

        product.farmer.transfer(product.price * _quantity);
        product.quantity -= _quantity;
        emit ProductPurchased(_id, msg.sender, _quantity);

        // Refund excess payment
        if (msg.value > product.price * _quantity) {
            payable(msg.sender).transfer(msg.value - (product.price * _quantity));
        }
    }

    function updateProduct(uint256 _id, uint256 _newPrice, uint256 _newQuantity, string memory _newIpfsHash) public onlyRegisteredFarmer {
        require(_id > 0 && _id <= productCount, "Invalid product ID");
        Product storage product = products[_id];
        require(msg.sender == product.farmer, "Only the product owner can update it");

        product.price = _newPrice;
        product.quantity = _newQuantity;
        product.ipfsHash = _newIpfsHash;
    }

    function getProduct(uint256 _id) public view returns (string memory, uint256, uint256, string memory, address) {
        require(_id > 0 && _id <= productCount, "Invalid product ID");
        Product memory product = products[_id];
        return (product.name, product.price, product.quantity, product.ipfsHash, product.farmer);
    }

    function getFarmerDetails(address _farmerAddress) public view returns (string memory, bool) {
        Farmer memory farmer = farmers[_farmerAddress];
        return (farmer.name, farmer.isRegistered);
    }

    function getProductCount() public view returns (uint256) {
        return productCount;
    }

    function getFarmerCount() public view returns (uint256) {
        return farmerCount;
    }
}