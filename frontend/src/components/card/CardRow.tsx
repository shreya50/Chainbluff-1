import React from "react";
import PokerCard from "./PokerCard";

interface CardRowProps {
  cards: number[];
}

const CardRow: React.FC<CardRowProps> = ({ cards }) => {
  // console.log(cards);
  return (
    <div>
      {cards.map((card, index) => {
        return (
          <>
            <PokerCard
              key={index}
              url={require(`../../assets/cards/${card}.png`)}
            />
            ;
          </>
        );
      })}
    </div>
  );
};

export default CardRow;
