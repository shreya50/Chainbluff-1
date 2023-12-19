import React from "react";
import { Container, Row } from "react-bootstrap";

import GameInstruction from "./GameInstruction";
import ProfilePicture from "../profile-picture/ProfilePicture";

import "./GameLanding.styles.css";
import pokerBG from "../../assets/poker-background.jpg";
import CardRow from "../card/CardRow";

const GameLanding: React.FC = () => {
  return (
    <Container
      fluid
      className="background-container"
      style={{ backgroundImage: `url(${pokerBG})` }}
    >
      <Row className="justify-content-center text-center">
        <ProfilePicture showName={false} size="200px" />
        <GameInstruction />
      </Row>
    </Container>
  );
};

export default GameLanding;
