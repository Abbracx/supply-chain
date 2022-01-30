// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


contract Item {
    uint public priceInWei;
    uint public pricePaid;
    uint public index;

    ItemManager parentContract;

    constructor (ItemManager _parentContract, uint _priceInWei, uint _index){
        priceInWei = _priceInWei;
        index      = _index;
        parentContract = _parentContract;
    }

    receive () external payable {
        require( pricePaid == 0, "Item is paid already...");
        require( priceInWei == msg.value, "Only full payments allowed..." );
        pricePaid += msg.value;
        (bool success, ) = address(parentContract).call.{value: msg.value}(abi.encodeWithSignature("triggerPayment(uint256)", index));
    }
}

contract ItemManager {

    enum SupplyChainState { CREATED, PAID, DELIVERED }
    event SupplyChainStep(uint _itemIndex, SupplyChainState _step);

    struct S_Item {
        Item _item;
        string _identifier;
        uint _itemPrice;
        SupplyChainState _state;
    }

    mapping(uint => S_Item) public items;
    uint itemIndex;

    function createItem(string memory _identifier, uint _itemPrice) public {
        Item item = new Item(this, _itemPrice, itemIndex);
        items[itemIndex]._item = item;
        items[itemIndex]._identifier = _identifier;
        items[itemIndex]._itemPrice  = _itemPrice;
        items[itemIndex]._state      = SupplyChainState.CREATED;
        emit SupplyChainStep(itemIndex, items[itemIndex]._state);
        itemIndex++;
    }

    function triggerPayment(uint _itemIndex) public payable {
        require(items[_itemIndex]._itemPrice == msg.value, "Only full payments accepted..");
        require(items[_itemIndex]._state == SupplyChainState.CREATED, "Item is already further in the chain..");

        items[_itemIndex]._state =  SupplyChainState.PAID;
        emit SupplyChainStep(itemIndex, items[itemIndex]._state);
    }

    function triggerDelivery(uint _itemIndex) public {
        require(items[_itemIndex]._state == SupplyChainState.PAID, "Item is already further in the chain..");  
        items[_itemIndex]._state =  SupplyChainState.DELIVERED;
        emit SupplyChainStep(itemIndex, items[itemIndex]._state);
    }
}
