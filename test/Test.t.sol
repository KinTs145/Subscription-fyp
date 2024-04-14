// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Subscription.sol";
import "../src/MockToken.sol";

contract PaymentTest is Test {
    Payment payment;
    MockToken token;
    address merchant;
    address subscriber;
    
    function setUp() public {
        merchant = vm.addr(1);  
        subscriber = address(this);
        token = new MockToken();
        payment = new Payment(); 
        token.approve(address(payment), 1000);
    
    }
    
    function testCreatePlan() public{
        uint256 THIRTY_DAYS = 30 days;
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS);
        (address _merchant, address _token, uint _amount, uint _frequency) = payment.plans(0);
        assertEq(_merchant, merchant);  
        assertEq(_token, address(token));  
        assertEq(_amount, 100);  
        assertEq(_frequency, THIRTY_DAYS);     
    }

    function testCannotCreatePlanWithZeroAmount() public {
        uint256 THIRTY_DAYS = 30 days;
        vm.expectRevert();
        vm.prank(merchant);
        payment.createPlan(address(token), 0, THIRTY_DAYS);
       
        uint256 SIXTY_DAYS = 60 days;
        vm.expectRevert();
        vm.prank(merchant);
        payment.createPlan(address(token), 0, SIXTY_DAYS);
    }


    function testCannotCreatePlanWithZeroAddress() public {
        uint256 THIRTY_DAYS = 30 days;
        vm.expectRevert();
        vm.prank(merchant);
        payment.createPlan(address(0), 100, THIRTY_DAYS);

        uint256 SIXTY_DAYS = 60 days;
        vm.expectRevert();
        vm.prank(merchant);
        payment.createPlan(address(0), 200, SIXTY_DAYS);
    }

    function testCreateSubscription() public {
        uint256 THIRTY_DAYS = 30 days;
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        console.log("Merchant's token balance:", token.balanceOf(merchant));
        vm.prank(subscriber);
        payment.subscribe(0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        console.log("Merchant's token balance:", token.balanceOf(merchant));
        (address _subscriber,, uint _nextPayment) = payment.subscriptions(subscriber, 0);
        assertEq(_subscriber, subscriber);
        assertTrue(_nextPayment > block.timestamp);
    }

    function testCannotSubscribeNonExistentPlan() public {
        vm.expectRevert();
        payment.subscribe(0);
    }

    
    function testCancelSubscription() public {
        uint256 THIRTY_DAYS = 30 days;
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        vm.prank(subscriber);
        payment.subscribe(0);
        payment.cancel(0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));

        uint256 SIXTY_DAYS = 60 days;
        vm.prank(merchant);
        payment.createPlan(address(token), 200, SIXTY_DAYS);
        vm.prank(subscriber);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        payment.subscribe(1);
        payment.cancel(1);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
    }

    function testCannotCancelNonExistSubscription() public {
        uint256 THIRTY_DAYS = 30 days;
        payment.createPlan(address(token), 100, THIRTY_DAYS);
        vm.expectRevert();
        payment.cancel(0);

        uint256 SIXTY_DAYS = 60 days;
        payment.createPlan(address(token), 200, SIXTY_DAYS);
        vm.expectRevert();
        payment.cancel(1);
    }

    function testRenewPaymentBeforeDueDate() public {
        uint256 THIRTY_DAYS = 30 days;
        payment.createPlan(address(token), 100, THIRTY_DAYS);
        payment.subscribe(0);
        (address _subscriber,,) = payment.subscriptions(subscriber, 0);
        vm.expectRevert();
        payment.pay(_subscriber, 0);
    }

    function testRenewPaymentAfterDueDate() public {
        uint256 THIRTY_DAYS = 30 days;
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        vm.prank(subscriber);
        payment.subscribe(0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        (address _subscriber,, ) = payment.subscriptions(subscriber, 0);
        vm.warp(block.timestamp + 31 days);
        payment.pay(_subscriber, 0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
    }

  
}
