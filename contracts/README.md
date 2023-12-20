# Chainbluff Contract Documentation

## main-v2.sol

## Smart Contract Overview
`PokerChain` is a Solidity smart contract designed for running a decentralized Texas Hold'em poker game on the Ethereum blockchain. It features functionalities for game creation, player actions during the game, and managing poker rounds.

## Constants
- `MAX_PLAYERS`: (uint8) The maximum number of players in a game.
- `TOTAL_CARDS`: (uint8) Total number of cards in a deck.

## Enums
### GameStatus
Represents different states of a poker game.
- `Create`
- `AwaitingToStart`
- `PreFlop`
- `Flop`
- `Turn`
- `River`
- `Finish`

### PlayerAction
Possible actions a player can take during a game.
- `Call`
- `Raise`
- `Check`
- `Fold`
- `Idle`
- `AllIn`

## Structs
### Game
Represents a single poker game with attributes like owner, players, player states, deck, community cards, pot, game status, etc.

## State Variables
- `games`: Mapping of game IDs to `Game` structs.
- `owner`: Address of the contract owner.
- `commission`: Commission fee for the contract owner.
- `nextGameId`: ID for the next game to be created.
- `numGames`: Total number of games created.

## Modifiers
### onlyOwner
Restricts function access to the contract owner.

### onlyState
Ensures the game is in a specific state.
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
  - `state` (`GameStatus`): Desired state of the game.

### validGameId
Validates a game ID.
- **Parameters**:
  - `gameId` (`uint8`): ID of the game to validate.

## Events
- `NextPlayerAction(gameId, player, actionType, amount, nextPlayer)`
- `GameStateChanged(gameId, communityCards)`
- `GameEnded(gameId, winner, winnings)`
- `PotUpdated(gameId, newPotSize)`

## Constructor
### PokerChain
- **Parameters**:
  - `_commission` (`uint24`): Commission rate for the contract.
- **Functionality**: Sets the contract owner and commission rate.

## Functions

### createGame
- **Modifiers**: require(minBuyIn <= maxBuyIn);
- **Parameters**: 
  - `blindAmount` (`uint24`): The blind amount for the game.
  - `minBuyIn` (`uint24`): Minimum buy-in amount.
  - `maxBuyIn` (`uint24`): Maximum buy-in amount.
- **Returns**: `uint8` - The ID of the created game.
- **Functionality**: Initializes a new game with specified parameters.

### _joinGame
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game to join.
- **Functionality**: Internal function to manage the logic of joining a game. Validates the joining conditions like the amount, player limit, and player address.

### _transfer
- **Modifiers**: None
- **Parameters**:
  - `to` (`address`): The address to transfer ether to.
  - `amount` (`uint24`): Amount of ether to transfer.
- **Functionality**: Internal function to handle ether transfers. It ensures the transfer is successful and reverts if not.

### drawCard
- **Modifiers**: validGameId(gameId)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
  - `seed` (`uint24`): Seed for randomization.
- **Returns**: `uint8` - The drawn card.
- **Functionality**: Draws a card from the game's deck based on the provided seed and randomization logic.

### startGame
- **Modifiers**: onlyState(gameId, GameStatus.AwaitingToStart), validGameId(gameId)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game to start.
  - `seed` (`uint24`): Seed for randomization.
- **Functionality**: Starts the game, transitioning it to the PreFlop state. Deals cards to players and sets up the game for play.

### _min
- **Modifiers**: None
- **Parameters**:
  - `a` (`uint24`): First value.
  - `b` (`uint24`): Second value.
- **Returns**: `uint24` - The minimum of the two values.
- **Functionality**: Internal function to determine the minimum of two values.

### _max
- **Modifiers**: None
- **Parameters**:
  - `a` (`uint24`): First value.
  - `b` (`uint24`): Second value.
- **Returns**: `uint24` - The maximum of the two values.
- **Functionality**: Internal function to determine the maximum of two values.

### callAction
- **Modifiers**: validGameId(gameId)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game where the action takes place.
- **Functionality**: Enables a player to call the current bet. Validates if the action is permissible under the current game state.

### raiseAction
- **Modifiers**: validGameId(gameId)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game where the action takes place.
  - `raiseAmount` (`uint24`): Amount by which the player wishes to raise the bet.
- **Functionality**: Allows a player to raise the bet in the game. Checks if the raise is valid and the player has sufficient balance.

### checkAction
- **Modifiers**: validGameId(gameId)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game where the action takes place.
- **Functionality**: Enables a player to check, passing the action to the next player without betting. Validates the action based on the current bet.

### foldAction
- **Modifiers**: validGameId(gameId)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game where the action takes place.
- **Functionality**: Allows a player to fold their hand, forfeiting their position in the current round of the game.

### _isValidAction
- **Modifiers**: None
- **Parameters**: 
  - `game` (`Game storage`): The game struct instance.
- **Returns**: `bool` - Indicates whether the action is valid.
- **Functionality**: Internal function that checks if a player's action is valid based on the game state, player's status, and turn order.

### getIsValidAction
- **Modifiers**: None
- **Parameters**: 
  - `gameId` (`uint8`): ID of the game.
- **Returns**: Multiple return values indicating various aspects of action validity (boolean values).
- **Functionality**: Provides a comprehensive check of the action's validity, including the state, player, and turn conditions.

### _nextPlayer
- **Modifiers**: None
- **Parameters**:
  - `game` (`Game storage`): The game struct instance.
- **Functionality**: Internal function to update the `currentPlayerIndex` to the next active player in the game, skipping folded and all-in players.

### flop
- **Modifiers**: onlyState(gameId, GameStatus.PreFlop)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: The first three community cards (`uint8`).
- **Functionality**: Transitions the game to the Flop state and reveals the first three community cards.

### turn
- **Modifiers**: onlyState(gameId, GameStatus.Flop)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: The first four community cards (`uint8`).
- **Functionality**: Moves the game to the Turn state and reveals the fourth community card.

### River
- **Modifiers**: onlyState(gameId, GameStatus.Turn)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: All five community cards (`uint8`).
- **Functionality**: Advances the game to the River state, revealing the final (fifth) community card.

### showdown
- **Modifiers**: onlyState(gameId, GameStatus.River)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: Arrays of player hands, best hands, and winner indices.
- **Functionality**: Determines the winner(s) of the game based on the best poker hands. Calculates and distributes the pot accordingly.

### clear
- **Modifiers**: onlyState(gameId, GameStatus.Finish)
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Functionality**: Resets the game state for a new round or completely ends the game if certain conditions are met.

### _resetRound
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Functionality**: Internal function to reset the game state for a new round, maintaining the same players.

### _resetGame
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Functionality**: Internal function to reset and clear all data of a finished game.

### _resetPlayerCards
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Functionality**: Internal function to reset the cards of each player in the game.

### getGameBasicDetails
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: Basic details of the game including owner, blind amount, pot, status, and player count.
- **Functionality**: Retrieves basic details about a specific game.

### getMyHand
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: The two cards in the player's hand.
- **Functionality**: Returns the hand of the player calling this function in the specified game.

### getPlayers
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: An array of addresses representing the players in the game.
- **Functionality**: Retrieves the list of players participating in a specific game.

### getMyBalance
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: The balance of the player calling the function.
- **Functionality**: Returns the chip balance of the player calling this function in the specified game.

### getNumGames
- **Modifiers**: None
- **Returns**: The number of games created (`uint8`).
- **Functionality**: Returns the total number of games created since the contract deployment.

### getRoundDetails
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: Detailed information about the current round of the specified game.
- **Functionality**: Provides detailed round information including player bets, actions, and game state.

### getCardsDetail
- **Modifiers**: None
- **Parameters**:
  - `gameId` (`uint8`): ID of the game.
- **Returns**: Details of the cards in the game including player hands, community cards, deck length, best hands, and winner indices.
- **Functionality**: Provides a comprehensive view of all card-related details in the specified game.

[...End of Documentation...]

## utils.sol

## CardUtils Library Documentation

The `CardUtils` library is designed to provide utility functions for handling cards in a poker game contract. It includes methods for card manipulation, hand evaluation, and determining the winner of a poker round.

## Modifiers

### onlyValidHand
Ensures that a hand does not contain any duplicate cards.
- **Parameters**: 
  - `hand` (`uint8[] memory`): An array representing a hand of cards.
- **Requirements**: 
  - Each card in the hand must be unique unless it's a placeholder value (255 for an empty or invalid card).

## Functions

### getRank
Returns the rank of a card.
- **Parameters**: 
  - `card` (`uint8`): The card value.
- **Returns**: 
  - `uint8`: The rank of the card.

### getSuit
Returns the suit of a card.
- **Parameters**: 
  - `card` (`uint8`): The card value.
- **Returns**: 
  - `uint8`: The suit of the card.

### sortHand
Sorts a hand of cards in descending order.
- **Parameters**: 
  - `hand` (`uint8[] memory`): An unsorted array of card values.
- **Returns**: 
  - `uint8[] memory`: The sorted hand of cards.

### combineHand
Combines a player's hand with the community cards to form a complete hand.
- **Parameters**: 
  - `playerHands` (`uint8[] memory`): The player's cards.
  - `tableCards` (`uint8[] memory`): The community cards.
- **Returns**: 
  - `uint8[] memory`: The combined hand of cards.

### getScore
Returns the score of a hand.
- **Parameters**: 
  - `hand` (`uint40`): The encoded hand value.
- **Returns**: 
  - `uint8`: The score of the hand.

### decodeHand
Decodes an encoded hand into its card values.
- **Parameters**: 
  - `hand` (`uint40`): The encoded hand value.
- **Returns**: 
  - `uint8[] memory`: An array of card values.

### encodeHand
Encodes a hand along with its score.
- **Parameters**: 
  - `hand` (`uint8[] memory`): The hand of cards.
  - `score` (`uint8`): The score of the hand.
- **Returns**: 
  - `uint40`: The encoded hand value.

### checkWinningHands
Determines the winning hands among multiple players.
- **Parameters**: 
  - `playerHands` (`uint8[][] memory`): An array of player hands.
  - `tableCards` (`uint8[] memory`): The community cards.
- **Returns**: 
  - `uint40[] memory`: An array of hand scores.
  - `uint8[] memory`: An array of indices of the winning hands.

### getHandScore
Calculates and returns the score of a hand.
- **Parameters**: 
  - `hand` (`uint8[] memory`): The hand of cards to evaluate.
- **Modifiers**: 
  - `onlyValidHand`: Ensures the hand is valid with no duplicates.
- **Returns**: 
  - `uint40`: The score of the hand.

### getWinner
Identifies the winner(s) based on hand scores.
- **Parameters**: 
  - `handScores` (`uint40[] memory`): An array of encoded hand scores.
- **Returns**: 
  - `uint8[] memory`: An array of indices of the winning hands.

### isEliminated
Checks if a hand is eliminated based on placeholder values.
- **Parameters**: 
  - `hand` (`uint8[] memory`): The hand of cards to check.
- **Returns**: 
  - `bool`: True if the hand is eliminated, false otherwise.
  - `uint8[] memory`: The hand with placeholders if eliminated.

### isRoyalFlush
Determines if a hand is a royal flush.
- **Parameters**:
  - `hand` (`uint8[] memory`): The hand of cards to evaluate.
- **Returns**: 
  - `bool`: True if the hand is a royal flush, false otherwise.
  - `uint8[] memory`: The best hand if it's a royal flush.

### isStraightFlush
Determines if a hand is a straight flush.
- **Parameters**:
  - `hand` (`uint8[] memory`): The hand of cards to evaluate.
- **Returns**: 
  - `bool`: True if the hand is a straight flush, false otherwise.
  - `uint8[] memory`: The best hand if it's a straight flush.

### isFullHouse
Determines if a hand is a full house.
- **Parameters**:
  - `hand` (`uint8[] memory`): The hand of cards to evaluate.
- **Returns**: 
  - `bool`: True if the hand is a full house, false otherwise.
  - `uint8[] memory`: The best hand if it's a full house.

### isFlush
Determines if a hand is a flush.
- **Parameters**:
  - `hand` (`uint8[] memory`): The hand of cards to evaluate.
- **Returns**: 
  - `bool`: True if the hand is a flush, false otherwise.
  - `uint8[] memory`: The best hand if it's a flush.

### isStraight
Determines if a hand is a straight.
- **Parameters**:
  - `hand` (`uint8[] memory`): The hand of cards to evaluate.
- **Returns**: 
  - `bool`: True if the hand is a straight, false otherwise.
  - `uint8[] memory`: The best hand if it's a straight.

### isNOfAKind
Determines if a hand has n cards of the same rank.
- **Parameters**:
  - `hand` (`uint8[] memory`): The hand of cards to evaluate.
  - `n` (`uint8`): The number of cards of the same rank to look for.
- **Returns**: 
  - `bool`: True if the hand has n cards of the same rank, false otherwise.
  - `uint8[] memory`: The best hand if it has n cards of the same rank.

### isTwoPair
Determines if a hand is two pairs.
- **Parameters**:
  - `hand` (`uint8[] memory`): The hand of cards to evaluate.
- **Returns**: 
  - `bool`: True if the hand is two pairs, false otherwise.
  - `uint8[] memory`: The best hand if it's two pairs.

[...End of Function Documentation...]


## Deployment
This contract is initialized and deployed using Remix IDE, with MetaMask as the chosen wallet, on the Sepolia network.

## License
This smart contract is released under the MIT License. See the SPDX-License-Identifier at the top of the code for details.





