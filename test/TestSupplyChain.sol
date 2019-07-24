pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
import "./Proxy.sol";

contract TestSupplyChain {
    uint public initialBalance = 1 ether;

    SupplyChain public chain;
    Proxy public seller;
    Proxy public buyer;
    Proxy public random;

    string itemName = "TestItem";
    uint256 itemPrice = 5;
    uint256 itemSku = 0;

    function() external payable {}

    function beforeEach() public
    {
        chain = new SupplyChain();

        seller = new Proxy(chain);
        buyer = new Proxy(chain);
        random = new Proxy(chain);

        uint256 seedValue = itemPrice + 1;
        address(buyer).transfer(seedValue);

        seller.placeItemForSale(itemName, itemPrice);
    }

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    // buyItem

    // test for failure if user does not send enough funds
    // test for purchasing an item that is not for Sale
    function testNotEnoughFunds() public {
        uint offer = 2;

        bool result = buyer.purchaseItem(itemSku, offer);
        Assert.isFalse(result, "Not Enough Funds");
        result = buyer.purchaseItem(itemSku, itemPrice);
        Assert.isTrue(result, "Item was not for sale");
    }

    function testNotForSale() public {
        bool result = buyer.purchaseItem(itemSku, itemPrice);
        Assert.isTrue(result, "Item is not for sale");
        result = buyer.purchaseItem(itemSku, itemPrice);
        Assert.isFalse(result, "Item was for sale");
    }

    // shipItem

    // test for calls that are made by not the seller
    // test for trying to ship an item that is not marked Sold

    function testForSeller() public {
        buyer.purchaseItem(itemSku, itemPrice);
        bool result = random.shipItem(itemSku);
        Assert.isFalse(result, "Was in fact the seller");
    }

    function testShipNotSoldItem() public {
        bool result = seller.shipItem(itemSku);
        Assert.isFalse(result, "Item was in sold state");
        buyer.purchaseItem(itemSku, itemPrice);
        result = seller.shipItem(itemSku);
        Assert.isTrue(result, "Item must be in sold state");
    }

    // receiveItem

    // test calling the function from an address that is not the buyer
    // test calling the function on an item not marked Shipped
    function testReceiveFromNonBuyer() public {
        buyer.purchaseItem(itemSku, itemPrice);
        seller.shipItem(itemSku);
        bool result = random.receiveItem(itemSku);
        Assert.isFalse(result, "Received by buyer");
        result = buyer.receiveItem(itemSku);
        Assert.isTrue(result, "Must be received by buyer");
    }

    function testReceiveOnNotShippedItem() public {
        bool result = buyer.receiveItem(itemSku);
        Assert.isFalse(result, "Item was Shipped");
        buyer.purchaseItem(itemSku, itemPrice);
        seller.shipItem(itemSku);
        result = buyer.receiveItem(itemSku);
        Assert.isTrue(result, "Item must be Shipped");
    }
}
