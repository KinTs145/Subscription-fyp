// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Subscription.sol";
import "../src/Token.sol";


contract SubscriptionScript is Script {
    MockToken token;
    address merchant;
    address subscriber;
    address platform;

     function setUp() public {
        token = new MockToken();
        subscriber = vm.addr(1); 
        merchant = vm.addr(2);   
        platform  = vm.addr(3);
        

        token.transferOwnership(platform);
        vm.startPrank(platform);
        token.mint(platform, 1000);
        token.ownerTransfer(subscriber, 1000);
        vm.stopPrank();
    }

    function run() external {
        string memory content = "hi";
        vm.startBroadcast();
        Payment payment = new Payment();
        vm.stopBroadcast();
       
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        console.log("Merchant's token balance:", token.balanceOf(merchant));

        vm.startPrank(merchant);
        payment.createPlan(address(token), 100, 30 days, content);  
        vm.stopPrank();

        vm.startPrank(subscriber);
        token.approve(address(payment), 100); 
        payment.subscribe(0);  
        vm.stopPrank();

        console.log("Subscriber's token balance after payment:", token.balanceOf(subscriber));
        console.log("Merchant's token balance after payment:", token.balanceOf(merchant));
    }


}










