import React, { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { getPokerGameContract } from '../../utils/contracts';

const PokerTablePage: React.FC = () => {
  const [players, setPlayers] = useState<any[]>([]);
  const { gameId } = useParams<{ gameId: string }>();

  const getPlayers = async () => {
    try {
      if (window.ethereum) {
        const contract = await getPokerGameContract();
        console.log(contract);

        const gameIdNumber = Number(gameId);
        console.log(gameIdNumber);
        const playersList = await contract.getPlayers(gameIdNumber);
        console.log(playersList);

        if (Array.isArray(playersList)) {
          setPlayers(playersList);
        } else {
          setPlayers([]);
        }
      } else {
        console.error('Ethereum object not found');
        setPlayers([]);
      }
    } catch (error) {
      console.error('Error fetching players:', error);
      setPlayers([]);
    }
  };

  useEffect(() => {
    getPlayers();
  }, []);

  return (
    <div className="poker-table">
      {players.map((player, index) => (
        <div key={index} className="player">
          Player: {player}
        </div>
      ))}
    </div>
  );
};

export default PokerTablePage;
