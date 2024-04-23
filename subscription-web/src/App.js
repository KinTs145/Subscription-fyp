import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import PlanCreator from './PlanCreator';
import PlanSubscriber from './PlanSubscriber';
import './App.css';

function App() {
    useEffect(() => {
        const ethereum = window.ethereum;

        // Function to reload the page
        const handleAccountChanged = (accounts) => {
            if (accounts.length > 0) {
                console.log('Selected account changed to:', accounts[0]);
                window.location.reload();  // Reload the page
            }
        };

        // Listen for account changes
        ethereum?.on('accountsChanged', handleAccountChanged);

        // Cleanup the event listener when the component is unmounted
        return () => {
            ethereum?.removeListener('accountsChanged', handleAccountChanged);
        };
    }, []);

    return (
        <BrowserRouter>
            <div>
                <nav>
                    <ul>
                        <li><Link to="/create-plan" className="button">Create Plan</Link></li>
                        <li><Link to="/subscribe-plan" className="button">Subscribe to Plan</Link></li>
                    </ul>
                </nav>
                <Routes>
                    <Route path="/create-plan" element={<PlanCreator />} />
                    <Route path="/subscribe-plan" element={<PlanSubscriber />} />
                </Routes>
            </div>
        </BrowserRouter>
    );
}

export default App;