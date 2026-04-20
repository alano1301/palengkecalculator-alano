// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TilapiaFarmSupplyChain
 * @author Alano, Prince Russel — BSIT-4A
 * @notice Tracks the lifecycle of tilapia farm products from Farmer to Distributor.
 *         Ensures transparency, traceability, and data integrity.
 */
contract TilapiaFarmSupplyChain {

    // =========================================================================
    // Enums
    // =========================================================================

    enum Status { Created, InTransit, Delivered }

    enum Role { None, Farmer, Distributor }

    // =========================================================================
    // Structs
    // =========================================================================

    struct Product {
        uint256 id;
        string  name;           // e.g. "Fresh Tilapia", "Smoked Tilapia"
        uint256 quantity;       // in kilograms
        string  origin;         // farm location
        uint256 price;          // price in wei (bonus: price tracking)
        address farmer;
        address currentOwner;
        address distributor;
        Status  status;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct OwnershipRecord {
        address from;
        address to;
        uint256 timestamp;
        string  note;
    }

    // =========================================================================
    // State Variables
    // =========================================================================

    address public admin;
    uint256 private _productCounter;

    mapping(address => Role)   public roles;
    mapping(uint256 => Product) public products;
    mapping(uint256 => OwnershipRecord[]) private _ownershipHistory;

    uint256[] private _allProductIds;

    // =========================================================================
    // Events
    // =========================================================================

    event RoleAssigned(address indexed account, Role role, uint256 timestamp);

    event ProductRegistered(
        uint256 indexed productId,
        string  name,
        uint256 quantity,
        string  origin,
        uint256 price,
        address indexed farmer,
        uint256 timestamp
    );

    event OwnershipTransferred(
        uint256 indexed productId,
        address indexed from,
        address indexed to,
        Status  newStatus,
        uint256 timestamp
    );

    event DeliveryConfirmed(
        uint256 indexed productId,
        address indexed distributor,
        uint256 timestamp
    );

    event BatchTransferred(
        uint256[] productIds,
        address indexed distributor,
        uint256 timestamp
    );

    event PriceUpdated(
        uint256 indexed productId,
        uint256 oldPrice,
        uint256 newPrice,
        uint256 timestamp
    );

    // =========================================================================
    // Modifiers
    // =========================================================================

    modifier onlyAdmin() {
        require(msg.sender == admin, "Access denied: admin only");
        _;
    }

    modifier onlyFarmer() {
        require(roles[msg.sender] == Role.Farmer, "Access denied: farmer role required");
        _;
    }

    modifier onlyDistributor() {
        require(roles[msg.sender] == Role.Distributor, "Access denied: distributor role required");
        _;
    }

    modifier onlyCurrentOwner(uint256 productId) {
        require(products[productId].currentOwner == msg.sender, "Access denied: not current owner");
        _;
    }

    modifier productExists(uint256 productId) {
        require(products[productId].farmer != address(0), "Product does not exist");
        _;
    }

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor() {
        admin = msg.sender;
        // Admin is also a Farmer by default for easy testing in Remix
        roles[msg.sender] = Role.Farmer;
    }

    // =========================================================================
    // Role Management (Access Control)
    // =========================================================================

    /**
     * @notice Assign a role to an address. Only admin can do this.
     * @param account  The wallet address to assign a role to.
     * @param role     1 = Farmer, 2 = Distributor
     */
    function assignRole(address account, Role role) external onlyAdmin {
        require(account != address(0), "Invalid address");
        require(role != Role.None, "Cannot assign None role");
        roles[account] = role;
        emit RoleAssigned(account, role, block.timestamp);
    }

    /**
     * @notice Check what role an address has.
     */
    function getRole(address account) external view returns (string memory) {
        Role r = roles[account];
        if (r == Role.Farmer)      return "Farmer";
        if (r == Role.Distributor) return "Distributor";
        return "None";
    }

    // =========================================================================
    // 1. Product Registration
    // =========================================================================

    /**
     * @notice Register a new tilapia farm product. Only Farmers can call this.
     * @param name      Product name (e.g. "Fresh Tilapia")
     * @param quantity  Quantity in kilograms
     * @param origin    Farm location (e.g. "Laguna, Philippines")
     * @param price     Price in wei
     * @return productId The newly created product ID
     */
    function registerProduct(
        string calldata name,
        uint256 quantity,
        string  calldata origin,
        uint256 price
    ) external onlyFarmer returns (uint256 productId) {
        require(bytes(name).length > 0,   "Product name cannot be empty");
        require(quantity > 0,              "Quantity must be greater than zero");
        require(bytes(origin).length > 0,  "Origin cannot be empty");

        _productCounter++;
        productId = _productCounter;

        products[productId] = Product({
            id:           productId,
            name:         name,
            quantity:     quantity,
            origin:       origin,
            price:        price,
            farmer:       msg.sender,
            currentOwner: msg.sender,
            distributor:  address(0),
            status:       Status.Created,       // 0 – Created
            createdAt:    block.timestamp,
            updatedAt:    block.timestamp
        });

        _allProductIds.push(productId);

        // Record initial ownership
        _ownershipHistory[productId].push(OwnershipRecord({
            from:      address(0),
            to:        msg.sender,
            timestamp: block.timestamp,
            note:      "Product registered by farmer"
        }));

        emit ProductRegistered(productId, name, quantity, origin, price, msg.sender, block.timestamp);
    }

    // =========================================================================
    // 2. Ownership Tracking & 4. Transfer Function
    // =========================================================================

    /**
     * @notice Transfer product from Farmer to Distributor.
     *         Automatically updates status to InTransit (1).
     *         Only the current owner (Farmer) can call this.
     * @param productId   Product to transfer
     * @param distributor Address of the distributor
     */
    function transferToDistributor(uint256 productId, address distributor)
        external
        productExists(productId)
        onlyCurrentOwner(productId)
    {
        require(roles[distributor] == Role.Distributor, "Recipient must have Distributor role");
        require(
            products[productId].status == Status.Created,
            "Product must be in Created status to transfer"
        );

        Product storage p = products[productId];
        address previousOwner = p.currentOwner;

        p.distributor  = distributor;
        p.currentOwner = distributor;
        p.status       = Status.InTransit;  // 1 – In Transit
        p.updatedAt    = block.timestamp;

        _ownershipHistory[productId].push(OwnershipRecord({
            from:      previousOwner,
            to:        distributor,
            timestamp: block.timestamp,
            note:      "Transferred to distributor - In Transit"
        }));

        emit OwnershipTransferred(productId, previousOwner, distributor, Status.InTransit, block.timestamp);
    }

    // =========================================================================
    // 3. Status Updates
    // =========================================================================

    /**
     * @notice Confirm delivery of a product.
     *         Sets status to Delivered (2).
     *         Only the Distributor (current owner) can call this.
     * @param productId Product to confirm delivery for
     */
    function confirmDelivery(uint256 productId)
        external
        productExists(productId)
        onlyCurrentOwner(productId)
        onlyDistributor
    {
        require(
            products[productId].status == Status.InTransit,
            "Product must be In Transit before confirming delivery"
        );

        Product storage p = products[productId];
        p.status    = Status.Delivered; // 2 – Delivered
        p.updatedAt = block.timestamp;

        _ownershipHistory[productId].push(OwnershipRecord({
            from:      msg.sender,
            to:        msg.sender,
            timestamp: block.timestamp,
            note:      "Delivery confirmed by distributor"
        }));

        emit DeliveryConfirmed(productId, msg.sender, block.timestamp);
    }

    // =========================================================================
    // BONUS: Batch Tracking
    // =========================================================================

    /**
     * @notice Transfer multiple products to the same distributor in one transaction.
     * @param productIds  Array of product IDs
     * @param distributor Address of the distributor
     */
    function batchTransferToDistributor(
        uint256[] calldata productIds,
        address distributor
    ) external {
        require(productIds.length > 0,                "Batch cannot be empty");
        require(roles[distributor] == Role.Distributor, "Recipient must have Distributor role");

        for (uint256 i = 0; i < productIds.length; i++) {
            uint256 pid = productIds[i];
            require(products[pid].farmer != address(0),        "Product does not exist");
            require(products[pid].currentOwner == msg.sender,  "Not owner of all products");
            require(products[pid].status == Status.Created,    "All products must be in Created status");

            Product storage p = products[pid];
            address prev      = p.currentOwner;

            p.distributor  = distributor;
            p.currentOwner = distributor;
            p.status       = Status.InTransit;
            p.updatedAt    = block.timestamp;

            _ownershipHistory[pid].push(OwnershipRecord({
                from:      prev,
                to:        distributor,
                timestamp: block.timestamp,
                note:      "Batch transfer - In Transit"
        }));


            emit OwnershipTransferred(pid, prev, distributor, Status.InTransit, block.timestamp);
        }

        emit BatchTransferred(productIds, distributor, block.timestamp);
    }

    // =========================================================================
    // BONUS: Price Tracking
    // =========================================================================

    /**
     * @notice Update the price of a product. Only the farmer who created it can do this.
     * @param productId Product ID
     * @param newPrice  New price in wei
     */
    function updatePrice(uint256 productId, uint256 newPrice)
        external
        productExists(productId)
    {
        require(products[productId].farmer == msg.sender, "Only the original farmer can update price");
        require(products[productId].status != Status.Delivered, "Cannot update price after delivery");

        uint256 oldPrice = products[productId].price;
        products[productId].price     = newPrice;
        products[productId].updatedAt = block.timestamp;

        emit PriceUpdated(productId, oldPrice, newPrice, block.timestamp);
    }

    // =========================================================================
    // BONUS: Payment Simulation
    // =========================================================================

    /**
     * @notice Simulate payment by the distributor to the farmer upon delivery.
     *         Send ETH equal to product price when calling this function.
     * @param productId Product ID to pay for
     */
    function simulatePayment(uint256 productId)
        external
        payable
        productExists(productId)
        onlyDistributor
    {
        Product storage p = products[productId];
        require(p.status == Status.Delivered, "Product must be Delivered before payment");
        require(p.distributor == msg.sender,  "Only the assigned distributor can pay");
        require(msg.value >= p.price,         "Insufficient payment amount");

        address payable farmer = payable(p.farmer);
        farmer.transfer(msg.value);
    }

    // =========================================================================
    // 6. Data Retrieval
    // =========================================================================

    /**
     * @notice Get full details of a product.
     */
    function getProduct(uint256 productId)
        external
        view
        productExists(productId)
        returns (Product memory)
    {
        return products[productId];
    }

    /**
     * @notice Get the status of a product as a number.
     *         0 = Created, 1 = InTransit, 2 = Delivered
     */
    function getStatus(uint256 productId)
        external
        view
        productExists(productId)
        returns (uint8)
    {
        return uint8(products[productId].status);
    }

    /**
     * @notice Get the full ownership history of a product.
     */
    function getOwnershipHistory(uint256 productId)
        external
        view
        productExists(productId)
        returns (OwnershipRecord[] memory)
    {
        return _ownershipHistory[productId];
    }

    /**
     * @notice Get all registered product IDs.
     */
    function getAllProductIds() external view returns (uint256[] memory) {
        return _allProductIds;
    }

    /**
     * @notice Total number of products registered.
     */
    function totalProducts() external view returns (uint256) {
        return _productCounter;
    }
}