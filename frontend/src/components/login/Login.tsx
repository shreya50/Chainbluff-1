import React, { useState } from 'react';
import { ethers } from 'ethers';
import { useNavigate } from 'react-router-dom';

interface LoginProps {
    setIsAuthenticated: (isAuthenticated: boolean) => void;
}
const Login: React.FC<LoginProps> = ({ setIsAuthenticated }) => {
    const [account, setAccount] = useState('');
    const navigate = useNavigate();

    const connectWallet = async () => {
        if (window.ethereum) {
            try {
                await window.ethereum.request({ method: 'eth_requestAccounts' });
                const provider = new ethers.BrowserProvider(window.ethereum)

                const signer = await provider.getSigner();
                const accountAddress = await signer.getAddress();
                // set accountAddr to Storage
                localStorage.setItem('accountAddr', accountAddress);

                setAccount(accountAddress);
                setIsAuthenticated(true);
                sessionStorage.setItem('isAuthenticated', 'true'); // Storing authentication state
                navigate('/game-table');
            } catch (error) {
                console.error("You need to allow MetaMask.");
            }
        } else {
            console.error("You need to install MetaMask.");
        }
    };

    return (
        <div>
            <button onClick={connectWallet}>Connect MetaMask</button>
            {account && <p>Connected Account: {account}</p>}
        </div>
    );
};

export default Login;