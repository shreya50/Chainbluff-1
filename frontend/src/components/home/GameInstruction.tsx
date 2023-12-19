import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "react-bootstrap";
import CreateTableModal from "./CreateTableModal";
import { getPokerGameContract } from "../../utils/contracts";

const GameInstruction: React.FC = () => {
  const navigate = useNavigate();

  const [showModal, setShowModal] = useState<boolean>(false);
  const [gameList, setGameList] = useState<number[]>([]);

  const createTable = () => {
    setShowModal(true);
  };

  const joinTable = async (tableId: number) => {
    try {
      const contract = await getPokerGameContract();
      contract.joinGame(tableId, { value: 100 });
      console.log(`Joining table ${tableId}`);
      navigate(`/table/${tableId}`);
    } catch (error) {
      window.alert("This table is full. Please try another one.");
    }
  };

  const renderTable = (tableId: number) => (
    <div
      key={tableId}
      style={{ marginBottom: '20px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
      onClick={() => joinTable(tableId)}
    >
      <p style={{ margin: '0 10px 0 0' }}>Table {tableId}</p>
      <button style={{ margin: 0 }}>Join Table</button>
    </div>
  );

  const divideTablewith5 = (gameList: number[]) => {
    let result = [];
    for (let i = 0; i < gameList.length; i += 5) {
      result.push(
        <div key={i}>
          {gameList.slice(i, i + 5).map(renderTable)}
        </div>
      );
    }
    return result;
  }
  return (
    <div style={{ color: "#FFFFFF" }}>
      <h2>Available Poker Tables</h2>
      <div style={{ display: 'flex', flexDirection: 'row', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'center' }}>
        {divideTablewith5(gameList)}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <p>Create a New Table</p>
        <Button onClick={createTable} variant="light" style={{ margin: 0 }}>
          Create Table
        </Button>
      </div>

      <CreateTableModal
        showModal={showModal}
        setShowModal={setShowModal}
        setGameList={setGameList}
      />
    </div>
  );
};

export default GameInstruction;
