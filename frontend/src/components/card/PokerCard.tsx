import React from "react";
import { Image } from "react-bootstrap";

interface CardProps {
  url: string;
  className?: string;
  style?: React.CSSProperties;
}

const CARD_WIDTH = 150;
const CARD_HEIGHT = 200;

const defaultStyle: React.CSSProperties = {
  width: CARD_WIDTH,
  height: CARD_HEIGHT,
};

const PokerCard: React.FC<CardProps> = ({ url, className, style }) => {
  return (
    <Image
      src={url}
      className={className}
      style={{ ...defaultStyle, ...style }}
    />
  );
};

export default PokerCard;
