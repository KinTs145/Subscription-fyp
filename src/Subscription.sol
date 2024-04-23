// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract Payment {
  uint public nextPlanId;
  uint private timeOffset = 0;
  
  struct Plan {
    address merchant;
    address token;
    uint amount;
    uint frequency;
    string content;
  }
  struct Subscription {
    address subscriber;
    uint start;
    uint nextPayment;
  }
  mapping(uint => Plan) public plans;
  mapping(address => mapping(uint => Subscription)) public subscriptions;

  event PlanCreated(
    address merchant,
    uint planId,
    uint date
  );
  event SubscriptionCreated(
    address subscriber,
    uint planId,
    uint date
  );
  event PaymentSent(
    address from,
    address to,
    uint amount,
    uint planId,
    uint date
  );
  event SubscriptionCancelled(
    address subscriber,
    uint planId,
    uint date
  );
  
  function createPlan(address token, uint amount, uint frequency, string memory content) external {
    require(token != address(0), 'Token address should be exists');
    require(amount > 0, 'amount needs to be > 0');
    require(frequency > 0, 'Dates needs to be > 0');
    plans[nextPlanId] = Plan(
      msg.sender, 
      token,
      amount, 
      frequency,
      content
    );
    nextPlanId++;
  }
  function getPlanCount() public view returns (uint) {
        return nextPlanId;
  }

  function subscribe(uint planId) external {
    IERC20 token = IERC20(plans[planId].token);
    Plan storage plan = plans[planId];
    require(plan.merchant != address(0), 'This plan does not exist');

    token.transferFrom(msg.sender, plan.merchant, plan.amount);  
    emit PaymentSent(
      msg.sender, 
      plan.merchant, 
      plan.amount, 
      planId, 
      block.timestamp
    );

    subscriptions[msg.sender][planId] = Subscription(
      msg.sender, 
      block.timestamp, 
      block.timestamp + plan.frequency
    );
    emit SubscriptionCreated(msg.sender, planId, block.timestamp);
  }



  function getSubscription(address _subscriber, uint _planId) public view returns (address, uint, uint) {
        Subscription memory sub = subscriptions[_subscriber][_planId];
        return (sub.subscriber, sub.start, sub.nextPayment);
  }

  function cancel(uint planId) external {
    Subscription storage subscription = subscriptions[msg.sender][planId];
    require(
      subscription.subscriber != address(0), 
      'This subscription does not exist'
    );
    delete subscriptions[msg.sender][planId]; 
    emit SubscriptionCancelled(msg.sender, planId, block.timestamp);
  }

  function pay(address subscriber, uint planId) external {
    Subscription storage subscription = subscriptions[subscriber][planId];
    Plan storage plan = plans[planId];
    IERC20 token = IERC20(plan.token);
    require(
      subscription.subscriber != address(0), 
      'This subscription does not exist'
    );
    require(
      block.timestamp > subscription.nextPayment,
      'Does not ready for next subscription'
    );
    token.transferFrom(subscriber, plan.merchant, plan.amount);  
    emit PaymentSent(
      subscriber,
      plan.merchant, 
      plan.amount, 
      planId, 
      block.timestamp
    );
    subscription.nextPayment = subscription.nextPayment + plan.frequency;
  }

  function skipTime(uint _days) public {
        timeOffset += _days * 1 days;
    }
}