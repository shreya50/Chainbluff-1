import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Modal, Button, Form } from "react-bootstrap";
import { getPokerGameContract } from "../../utils/contracts";

interface CreateTableModalProps {
  showModal: boolean;
  setShowModal: React.Dispatch<React.SetStateAction<boolean>>;
  setGameList: React.Dispatch<React.SetStateAction<number[]>>;
}

const CreateTableModal: React.FC<CreateTableModalProps> = ({
  showModal,
  setShowModal,
  setGameList,
}) => {
  const navigate = useNavigate();

  const [blindAmount, setblindAmount] = useState<number>(100);
  const [minBuyIn, setMinBuyIn] = useState<number>(0);
  const [maxBuyIn, setMaxBuyIn] = useState<number>(0);
  const [buyIn, setBuyIn] = useState<number>(0);
  const [contract, setContract] = useState<any>(null);


  useEffect(() => {
    const fetchData = async () => {
      const fetchedContract = await getPokerGameContract();
      setContract(fetchedContract);
      const count = await fetchedContract.getNumGames();
      setGameList(Array.from({ length: Number(count) }, (_, i) => i));
    };

    fetchData();
  }, []); // Empty dependency array to run only once on mount

  const handleSubmit = async () => {
    setShowModal(false);
    try {
      console.log("contract:", contract);
      const tx = await contract.createGame(
        blindAmount,
        minBuyIn,
        maxBuyIn,
      );
      await tx.wait();

    } catch (error) {
      console.error("Error creating table:", error);
    }
  };

  return (
    <div>
      {showModal && (
        <Modal show={showModal} onHide={() => setShowModal(false)}>
          <Modal.Header closeButton>
            <Modal.Title>Create Game</Modal.Title>
          </Modal.Header>
          <Modal.Body>
            <Form>
              <Form.Group>
                <Form.Label>Blind Amount:</Form.Label>
                <Form.Control
                  name="Blind Amount"
                  type="number"
                  value={blindAmount}
                  onChange={(e) => setblindAmount(Number(e.target.value))}
                  placeholder="Blind Amount"
                />
              </Form.Group>
              <Form.Group>
                <Form.Label>Min Buy-In:</Form.Label>
                <Form.Control
                  name="minBuyIn"
                  type="number"
                  value={minBuyIn}
                  onChange={(e) => setMinBuyIn(Number(e.target.value))}
                  placeholder="Min Buy-In"
                />
              </Form.Group>
              <Form.Group>
                <Form.Label>Max Buy-In:</Form.Label>
                <Form.Control
                  name="maxBuyIn"
                  type="number"
                  value={maxBuyIn}
                  onChange={(e) => setMaxBuyIn(Number(e.target.value))}
                  placeholder="Max Buy-In"
                />
              </Form.Group>
              <Form.Group>
                <Form.Label>Your Buy-In Amount:</Form.Label>
                <Form.Control
                  name="buyIn"
                  type="number"
                  value={buyIn}
                  onChange={(e) => setBuyIn(Number(e.target.value))}
                  placeholder="Your Buy-In Amount"
                />
              </Form.Group>
            </Form>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="dark" onClick={handleSubmit}>
              Submit
            </Button>
          </Modal.Footer>
        </Modal>
      )}
    </div>
  );
};

export default CreateTableModal;
