// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Subscription.sol";
import "../src/Token.sol";

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
        token.mint(subscriber, 1000);
        token.approve(address(payment), 1000);
       
    }
    
    function testCreatePlan() public{
        uint256 THIRTY_DAYS = 30 days;
        string memory content = "hi";
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS, content);
        (address _merchant, address _token, uint _amount, uint _frequency, string memory _content) = payment.plans(0);
        assertEq(_merchant, merchant);  
        assertEq(_token, address(token));  
        assertEq(_amount, 100);  
        assertEq(_frequency, THIRTY_DAYS);
        assertEq( _content, "hi");

    }

    function testCannotCreatePlanWithZeroAmount() public {
        uint256 THIRTY_DAYS = 30 days;
        string memory content = "hi";
        vm.expectRevert();
        vm.prank(merchant);
        payment.createPlan(address(token), 0, THIRTY_DAYS, content);
       
        uint256 SIXTY_DAYS = 60 days;
        vm.expectRevert();
        vm.prank(merchant);
        payment.createPlan(address(token), 0, SIXTY_DAYS, content);
    }


    function testCannotCreatePlanWithZeroAddress() public {
        uint256 THIRTY_DAYS = 30 days;
        string memory content = "hi";
        vm.expectRevert();
        vm.prank(merchant);
        payment.createPlan(address(0), 100, THIRTY_DAYS, content);

        uint256 SIXTY_DAYS = 60 days;
        vm.expectRevert();
        vm.prank(merchant);
        payment.createPlan(address(0), 200, SIXTY_DAYS, content);
    }

    function testCreateSubscription() public {
        uint256 THIRTY_DAYS = 30 days;
        string memory content = "hi";
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS, content);
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
        string memory content = "hi";
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS, content);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        vm.prank(subscriber);
        payment.subscribe(0);
        payment.cancel(0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));

        uint256 SIXTY_DAYS = 60 days;
        vm.prank(merchant);
        payment.createPlan(address(token), 200, SIXTY_DAYS, content);
        vm.prank(subscriber);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        payment.subscribe(1);
        payment.cancel(1);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
    }

    function testCannotCancelNonExistSubscription() public {
        string memory content = "hi";
        uint256 THIRTY_DAYS = 30 days;
        payment.createPlan(address(token), 100, THIRTY_DAYS, content);
        vm.expectRevert();
        payment.cancel(0);

        uint256 SIXTY_DAYS = 60 days;
        payment.createPlan(address(token), 200, SIXTY_DAYS, content);
        vm.expectRevert();
        payment.cancel(1);
    }

    function testRenewPaymentBeforeDueDate() public {
        string memory content = "hi";
        uint256 THIRTY_DAYS = 30 days;
        payment.createPlan(address(token), 100, THIRTY_DAYS, content);
        payment.subscribe(0);
        (address _subscriber,,) = payment.subscriptions(subscriber, 0);
        vm.expectRevert();
        payment.pay(_subscriber, 0);
    }

    function testRenewPaymentAfterDueDate() public {
        string memory content = "hi";
        uint256 THIRTY_DAYS = 30 days;
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS, content);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        vm.prank(subscriber);
        payment.subscribe(0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        (address _subscriber,, ) = payment.subscriptions(subscriber, 0);
        vm.warp(block.timestamp + 31 days);
        payment.pay(_subscriber, 0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
    }


    function testCannotRenewPaymentAfterCancelled() public {
        string memory content = "hi";
        uint256 THIRTY_DAYS = 30 days;
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS, content);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        vm.prank(subscriber);
        payment.subscribe(0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
        (address _subscriber,, ) = payment.subscriptions(subscriber, 0);
        payment.cancel(0);
        vm.expectRevert();
        vm.warp(block.timestamp + 31 days);
        payment.pay(_subscriber, 0);
        console.log("Subscriber's token balance:", token.balanceOf(subscriber));
    }


    function testInitialPlanCount() public {
        string memory content = "hi";
        uint initialCount = payment.getPlanCount();
        assertEq(initialCount, 0, "Initial plan count should be 0");
        console.log(initialCount);
        payment.createPlan(address(token), 100, 30, content);

        uint count = payment.getPlanCount();
        assertEq(count, 1, "Initial plan count should be 0");
        console.log(count);
    }
    

    function testSubscriberDetails() public {
        uint256 THIRTY_DAYS = 30 days;
        string memory content = "hi";
        uint start = block.timestamp;
        vm.prank(merchant);
        payment.createPlan(address(token), 100, THIRTY_DAYS, content);
        vm.prank(subscriber);
        payment.subscribe(0);

        (address returnedSubscriber, uint returnedStart, uint returnedNextPayment) = payment.getSubscription(subscriber, 0);
        assertEq(returnedSubscriber, subscriber);
        assertEq(returnedStart, start);
        assertEq(returnedNextPayment, start + THIRTY_DAYS);
        console.log(returnedSubscriber);

    }
  
}
