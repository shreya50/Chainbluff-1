import React, { useEffect, useState } from "react";
import { Col, Container, Row } from "react-bootstrap";
import foldCard from "../../assets/cards/255.png";
import ProfilePicture from "../profile-picture/ProfilePicture";
import PokerCard from "../card/PokerCard";
import { getPokerGameContract } from "../../utils/contracts";
import { Contract } from "ethers";

interface OtherPlayerProps {
  showCards?: boolean; // nullable for test
  cards?: string[]; // nullable for test
  playerLeft?: boolean;
}

const OtherPlayer: React.FC<OtherPlayerProps> = ({
  showCards,
  cards,
  playerLeft = true,
}) => {
  const [contract, setContract] = useState<any>(null);
  const [otherPlayers, setOtherPlayer] = useState<string[]>([]);
  useEffect(() => {
    let fetchedContract: Contract;
    //get Contract
    const fetchData = async () => {
      fetchedContract = await getPokerGameContract();
      setContract(fetchedContract);
      // console.log("fetchedContract2", fetchedContract)
      // get Players
      const selfPlayer = localStorage.getItem("accountAddr");
      const tableId = window.location.pathname.split("/")[2];
      // console.log("fetchedContract", fetchedContract)
      const fetchedPlayers = await fetchedContract.getPlayers(tableId);
      const OtherPlayer: string[] = fetchedPlayers.filter((player: string) => {
        // console.log(player);
        return player !== selfPlayer!;
      });
      setOtherPlayer(OtherPlayer);
    };
    fetchData();
    // fetchPlayers();
  }, [])

  const playerLeftProfile = (playerLeft: boolean) => {
    console.log("otherPlayers", otherPlayers.length)
    if (otherPlayers.length === 0 || otherPlayers.length === 1) {
      return;
    }
    var otherPlayer = otherPlayers[0];
    if (!playerLeft) {
      otherPlayer = otherPlayers[1];
    }
    console.log("otherPlayers", otherPlayers)
    return (
      <div className="" >
        <ProfilePicture size="70px" playerAddr={otherPlayer} />
      </div>
    )
  }

  const { left, top, right } = playerLeft
    ? { left: "-500px", top: "-100px", right: "200px" }
    : { left: "45px", top: "-100px", right: "0px" };

  return (
    <Container>
      <Row>
        <Col className="position-relative">
          <PokerCard
            url={foldCard}
            style={{
              zIndex: 2,
            }}
          />

          <PokerCard
            url={foldCard}
            style={{
              zIndex: 1,
              left: "50px",
              top: "50px",
            }}
            className="position-absolute"
          />
        </Col>

        <Col className="position-relative">
          <div
            className="position-absolute"
            style={{ zIndex: 2, left: left, top: top, right: right, margin: "auto", minWidth: "300px" }}
          >
            {playerLeftProfile(playerLeft)}
            {/* <ProfilePicture size="100px" playerAddr={otherPlayers[0]} />  */}
          </div>
        </Col>
      </Row>
    </Container>
  );
};

export default OtherPlayer;
