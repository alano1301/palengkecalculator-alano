pragma solidity ^0.8.0;

contract MyPalengkeCalculator {
   
    uint256[] public prices;
    uint256[] public quantities;

    // Called for each order
    function calculateTotal(
        uint256 pricePerUnit,
        uint256 quantity
    ) public returns (uint256) {

        prices.push(pricePerUnit);
        quantities.push(quantity);

        return pricePerUnit * quantity;
    }

    // Computes total of all stored orders
    function calculateGrandTotal() public view returns (uint256) {

        uint256 total = 0;

        for (uint256 i = 0; i < prices.length; i++) {
            total += prices[i] * quantities[i];
        }

        return total;
    }

    function calculateChange(
        uint256 totalCost,
        uint256 payment
    ) public pure returns (uint256) {
        require(payment >= totalCost, "Insufficient payment.");
        return payment - totalCost;
    }

    function applyDiscount(
        uint256 totalCost,
        uint256 discountPercent
    ) public pure returns (uint256) {
        require(discountPercent <= 100, "Invalid discount percentage.");
        return totalCost - ((totalCost * discountPercent) / 100);
    }

    function splitBill(
         uint256 totalCost,
         uint256 groupSize
    ) public pure returns (uint256) {
         require(groupSize > 0, "Group size must be greater than zero.");
         return totalCost / groupSize;
    }

    function calculateGrandTotal(
        uint256[3] memory prices,
        uint256[3] memory quantities
    ) public pure returns (uint256) {
        uint256 total = 0;
        for (uint i = 0; i < 3; i++) {
            total += prices[i] * quantities[i];
        }
        return total;
    }
}