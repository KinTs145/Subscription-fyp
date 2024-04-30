import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import { tokencontractAddress, contractAddress, contractAbi, tokencontractAbi } from './constant';

function SubscribePlan() {
    const [subscriptions, setSubscriptions] = useState([]);
    const [plans, setPlans] = useState([]);
    const [isMetaMaskConnected, setIsMetaMaskConnected] = useState(false);
    
    
    useEffect(() => {
        async function loadPlans() {
            if (window.ethereum) {
                try {
                    const provider = new ethers.BrowserProvider(window.ethereum);
                    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
                    if (accounts.length > 0) {
                        setIsMetaMaskConnected(true);
                        const contract = new ethers.Contract(contractAddress, contractAbi, provider);
                        const signer = await provider.getSigner();
                        const address = await signer.getAddress();
                        const planCount = await contract.getPlanCount();
                        const currentTime = Math.floor(Date.now() / 1000);

                    
                        const allPlans = [];
                        for (let i = 0; i < planCount; i++) {
                            const subscriptionData= await contract.getSubscription(address , i);
                            const plan = await contract.plans(i);
                            let content;  
                            if (subscriptionData[0] === address) {

                                if (currentTime < subscriptionData[2]) {
                                    content = plan.content;  // User is subscribed and within the active period
                                } else {
                                    content = "Your subscription has expired. Please renew to access the content!!!!";  // Subscription has expired
                                }
                            } else {
                                content = "!!!Please subscribe to see the content!!!"; 
                            } 
                            const isSubscribed = subscriptionData[0] === address;
        
                            allPlans.push({
                                id: i,
                                amount: ethers.formatEther(plan.amount),
                                frequency: (parseInt(plan.frequency.toString()) / 86400).toString(),
                                content: content,
                                isSubscribed
                            });
                        }
                        setPlans(allPlans);
                    }
                } catch (error) {
                    alert("There is an error when loading plans or user has not login to metamask!");       
                }   
            } else {
                alert("Ethereum wallet is not connected");
            }
        }

        loadPlans();
    }, []);
    async function approve(amount){
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const tokenContract = new ethers.Contract(tokencontractAddress, tokencontractAbi, signer);
        
        try{
            const approvalTx = await tokenContract.approve(contractAddress, ethers.parseEther(amount));
            await approvalTx.wait();
            alert(`Approval successful for ${amount} tokens!`);

        } catch (error) {
            console.error('Subscription error:', error);    
            alert("You rejected the approvement");
        }
        

    };
    async function subscribe(planId) {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const contract = new ethers.Contract(contractAddress, contractAbi, signer);
        const address = await signer.getAddress();

        try {
            const tx = await contract.subscribe(planId);
            await tx.wait();
            alert('Subscribed successfully!');
            setSubscriptions(data =>[...data , [planId, address]]);
            
        } catch (error) {
            if (error.code === 4001) {
                alert("You rejected transaction. Please try again.");
            }else {
                alert("You need to approve sufficient amount of ST before making transactions.");
            }      
        }
    };

    async function renewal(planId) {
        console.log("The time now.",Math.floor(Date.now() / 1000));
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const contract = new ethers.Contract(contractAddress, contractAbi, signer);
        const address = await signer.getAddress();
        try { 
            const tx = await contract.pay(address,planId);
            await tx.wait();
            alert('Subscribed successfully!');

            const updatedSubscriptionData = await contract.getSubscription(address, planId);
            console.log("Updated next payment time:", updatedSubscriptionData[2]);
          
            setSubscriptions(prevSubscriptions => 
                prevSubscriptions.map(sub => 
                    sub[0] === planId ? [planId, address, updatedSubscriptionData[2]] : sub
                )
            ); 
        } catch (error) {
            if (error.code === 4001) {
                alert("You rejected transaction. Please try again.");
            }else {
                alert("You need to approve sufficient amount of ST before making transactions.");
            }      
        }
    };
    async function cancel(planId) {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const contract = new ethers.Contract(contractAddress, contractAbi, signer);
        const address = await signer.getAddress();
        
        try {
            
            const tx = await contract.cancel(planId);
            await tx.wait();
            alert('Subscribtion cancelled successfully!');
            subscriptions(data => data.filter(pair => !(pair[0] === planId && pair[1] === address)));
            
        } catch (error) {
       

            if (error.code === "ACTION_REJECTED") {
                // User rejected the transaction
                alert("You have rejected the transaction. Please try again if you wish to cancel.");
            } else if (error.code === "CALL_EXCEPTION") {
                // Check if the error message is provided by ethers.js
                alert("You cannot cancel non existing plan.");
            } else if (error.message) {
                // Fallback to the error message provided by ethers.js
                alert("Transaction is failed: " + error.code);
            } else {
                // General fallback error message
                alert("Transaction failed due to contract requirements not being met.");
            }     
        }
    };
    return (
        <div>
            {isMetaMaskConnected ? (
            <div>
            <p>Welcome to our subscription plans page! Below you will find the available plans. Choose a plan that suits you best and follow the steps to subscribe, renew, or cancel your subscription.</p>
            {plans.map((plan, index) => (
            <div key={index}>
                <p>Plan {plan.id + 1}: Subscribe with {plan.amount} ST to get this content every 
                    {parseInt(plan.frequency) < 1 ? ' >1 day' : `${plan.frequency} days`}
                </p>
                {plan.isSubscribed ? (
                    <button onClick={() => renewal(plan.id)}>Renew</button>
                ) : (
                    <button onClick={() => subscribe(plan.id)}>Subscribe</button>
                )}
                <button onClick={() => approve(plan.amount)}>Approve</button>
                <button onClick={() => cancel(plan.id)}>Cancel</button>
                <p type="content">Only members can see the subscribed content: {plan.content}</p>
            </div>
            ))}
            </div>
             ) : (
                <p>Please connect to MetaMask to view the subscription plans.</p>
            )}
        </div>
    );
}

export default SubscribePlan;

