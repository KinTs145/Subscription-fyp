import React, { useState } from 'react';
import { ethers } from 'ethers';
import { tokencontractAddress, contractAddress, contractAbi } from './constant';

function CreatePlan() {
    const [amount, setAmount] = useState('');
    const [frequency, setFrequency] = useState('');
    const [content, setContent] = useState('');
    
    

    async function createPlan() {
        if (!window.ethereum) {
            alert("Please install MetaMask to use this feature.");
            return;
        }
        const daysInSeconds = Math.round(frequency * 24 * 60 * 60);

        try {
            const provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();
            const contract = new ethers.Contract(contractAddress, contractAbi, signer);
            
            const tx = await contract.createPlan(tokencontractAddress, ethers.parseEther(amount), daysInSeconds,content);
            await tx.wait();
            alert('Plan created successfully!');
        } catch (error) {
            if (error.code === 4001) { 
                alert('Transaction rejected by user.');
            } else {
                console.error('Transaction failed:', error);
                alert('You have rejected to make transacrions.');
            }
        }
    }
    return (
        <div>
            <input type="number" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="Enter the amount of ST" />
            <input type="number" value={frequency} onChange={(e) => setFrequency(e.target.value)} placeholder="Enter the subscription days" />
            <input type="text" step="0.1" value={content} onChange={(e) => setContent(e.target.value)} placeholder="Enter subscription content" />
            <button type="submit" onClick={createPlan}>Create Plan</button>
        </div>
    );
}

export default CreatePlan;