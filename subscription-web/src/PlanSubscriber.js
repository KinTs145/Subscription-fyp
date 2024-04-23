import React, { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import { tokencontractAddress, contractAddress, contractAbi, tokencontractAbi } from './constant';

function SubscribePlan() {
    const [subscriptions, setSubscriptions] = useState([]);
    const [plans, setPlans] = useState([]);
  
   
    
    useEffect(() => {
        async function loadPlans() {
            if (window.ethereum) {
                const provider = new ethers.BrowserProvider(window.ethereum);
                const contract = new ethers.Contract(contractAddress, contractAbi, provider);
                const signer = await provider.getSigner();
                const address = await signer.getAddress();
                const planCount = await contract.getPlanCount();
                const currentTime = Math.floor(Date.now() / 1000);

                
                
                
                try {
                    const allPlans = [];
                    for (let i = 0; i < planCount; i++) {
                        const subscriptionData= await contract.getSubscription(address , i);

                        console.log("This is the plan time",Number(subscriptionData[2]));
                        // console.log("This is the current time",currentTime);
                        // const diff = Number(subscriptionData[2]) - currentTime;
                        // console.log("This is the time diff",diff);

                      
                   
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
                } catch (error) {
                    console.error('Error loading plans:', error);
                    alert(error);       
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
        // const updatedSubscriptionData = await contract.getSubscription(address, planId);
       

        try {
            // const length = updatedSubscriptionData[2]-updatedSubscriptionData[1];
           
            const tx = await contract.pay(address,planId);
            await tx.wait();
            alert('Subscribed successfully!');
        
            // const newNextPayment = Math.floor(Date.now() / 1000)  + Number(length);
            // console.log("Renewal the time",Math.floor(Date.now() / 1000))
            // console.log("Renewal the plan",newNextPayment)
            // const diff = newNextPayment-Math.floor(Date.now() / 1000)
            // console.log("Renewal the difference",diff)

            const updatedSubscriptionData = await contract.getSubscription(address, planId);
            console.log("Updated next payment time:", updatedSubscriptionData[2]);
          
            setSubscriptions(prevSubscriptions => 
                prevSubscriptions.map(sub => 
                    sub[0] === planId ? [planId, address, updatedSubscriptionData[2]] : sub
                )
            );
            // const subscriptionData= await contract.getSubscription(address , planId);
            // console.log("asfdsafdssfgdsfdsssssssssssssssss",Number(subscriptionData[2]));
            
            // console.log("This is the plan diff ",subscriptionData- updatedSubscriptionData[2]);

      
        } catch (error) {
            if (error.code === 4001) {
                alert("You rejected transaction. Please try again.");
            }else {
                alert(error);
                // alert("You need to approve sufficient amount of ST before making transactions.");
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
            if (error.code === 4001) {
                alert("You rejected cancelation. Please try again.");
            }else {
                alert(error);
                // alert("You need to approve sufficient amount of ST before making transactions.");
            }      
        }
    };

    return (
        <div>
            {plans.map((plan, index) => (
                <div key={index}>
                    <p>Plan {plan.id+1}: Subscibe with {plan.amount} ST to get this context every {plan.frequency} days</p>
                    {plan.isSubscribed ? (
                    <button onClick={() => renewal(plan.id)}>Renewal</button>
                ) : (
                    <button onClick={() => subscribe(plan.id, plan.amount)}>Subscribe</button>
                )}
                
                    <button onClick={() => approve(plan.amount)}>Approve</button>

                    <button onClick={() => cancel(plan.id)}>Cancel</button>
                    {<p  type= "content">Only members can see the subscribed content: {plan.content}</p>}
                </div>
            ))}
        
        </div>
    );
}

export default SubscribePlan;

