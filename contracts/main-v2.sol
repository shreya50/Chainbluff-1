// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./utils.sol";

contract PokerChain {
    uint8 private constant MAX_PLAYERS = 3;
    struct Game {
        address owner;
        address[] players;
        mapping(address => uint24) playerChips;
        mapping(address => uint8[]) playerCards;
        PlayerAction[] playerActions;
        uint8[] isPlayerInGame;
        uint8[] isPlayerTakeTurn;
        uint8[] isPlayerFolded;
        uint8[] isPlayerAllIn;
        uint24[] playerBetAmounts;
        uint8[] deck;
        uint8[] communityCards;
        uint24 pot;
        uint8 numPlayerInGame;
        uint24 blindAmount;
        uint24 minBuyIn;
        uint24 maxBuyIn;
        uint24 currentBet;
        uint8 currentPlayerIndex;
        uint8 verifiedPlayerCount;
        uint8 gameCount;
        GameStatus status;
    }

    enum GameStatus {
        Create,
        AwaitingToStart,
        PreFlop,
        Flop,
        Turn,
        River,
        Finish
    }

    enum PlayerAction {
        Call,
        Raise,
        Check,
        Fold,
        Idle,
        AllIn
    }

    mapping(uint8 => Game) private games; // nextGameId to get Size
    address private owner;
    uint24 private commission; // pay to our system
    uint8 private nextGameId;
    uint8 private numGames;
    uint8 private constant TOTAL_CARDS = 52;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyState(uint8 gameId, GameStatus state) {
        Game storage game = games[gameId];
        require(game.status == state, "Invalid state");
        _;
    }

    modifier validGameId(uint8 gameId) {
        Game storage game = games[gameId];
        require(gameId <= numGames, "gameId does not exists");
        _;
    }

    event NextPlayerAction(uint8 gameId, address player, uint8 actionType, uint24 amount, address nextPlayer);
    event GameStateChanged(uint8 gameId, uint8[] communityCards);
    event GameEnded(uint8 gameId, address winner, uint24 winnings);
    event PotUpdated(uint8 gameId, uint24 newPotSize);

    constructor(uint24 _commission) {
        owner = msg.sender;
        commission = _commission;
    }

    /*
        Function to create new game
        @param : smallBlind, minBuyIn, maxBuyIn
    */
    function createGame(
        uint24 blindAmount,
        uint24 minBuyIn,
        uint24 maxBuyIn
    ) public payable returns (uint8) {
        require(
            minBuyIn <= maxBuyIn,
            "Minimum buy in must not exceed maximum buy in"
        );

        uint8 gameId = nextGameId++;
        numGames = gameId;
        Game storage newGame = games[gameId];
        newGame.owner = msg.sender;
        newGame.blindAmount = blindAmount;
        newGame.minBuyIn = minBuyIn;
        newGame.maxBuyIn = maxBuyIn;
        newGame.currentPlayerIndex = 0;

        newGame.status = GameStatus.Create;
        for (uint8 i = 0; i < 52; i++) {
            newGame.deck.push(i);
        }

        return gameId;
    }

    /*
        Function to join existing game
        @param : gameId, player hash
    */
    function joinGame(
        uint8 gameId
    ) public payable onlyState(gameId, GameStatus.Create) validGameId(gameId) {
        _joinGame(gameId);
    }

    function _joinGame(uint8 gameId) internal {
        Game storage game = games[gameId];
        require(
            msg.value >= commission + game.minBuyIn &&
                msg.value <= commission + game.maxBuyIn,
            "Deposit amount must not less than minBuyIn and not more than MaxBuyIn"
        );
        require(game.players.length < MAX_PLAYERS, "Game is full");
        require(
            msg.sender != address(0x0) && msg.sender != address(this),
            "Invalid player address"
        );

        game.players.push(msg.sender);
        uint256 amountAfterCommission = msg.value - commission;
        game.playerChips[msg.sender] = uint24(amountAfterCommission);
        game.isPlayerInGame.push(1);
        game.numPlayerInGame += 1;
        game.verifiedPlayerCount += 1;
        game.playerBetAmounts.push(0);
        game.playerActions.push(PlayerAction.Idle);
        game.isPlayerAllIn.push(0);
        game.isPlayerTakeTurn.push(0);
        game.isPlayerFolded.push(0);

        if (game.players.length == MAX_PLAYERS) {
            game.status = GameStatus.AwaitingToStart;
            _transfer(owner, commission); // pay commission to us
        }
    }

    /*
        Function to transfer assets
        @param : receiver address, amount
    */
    function _transfer(address to, uint24 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));
        if (!success) {
            revert("Transfer error");
        }
    }

    /*
        Function to draw card
        @param : gameId, seed
    */
    function drawCard(
        uint8 gameId,
        uint24 seed
    ) internal validGameId(gameId) returns (uint8) {
        Game storage game = games[gameId];
        require(game.deck.length > 0, "No more cards in the deck");
        uint8 randomIndex = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(seed, block.timestamp, block.prevrandao)
                )
            ) % game.deck.length
        );
        uint8 card = game.deck[randomIndex];
        game.deck[randomIndex] = game.deck[game.deck.length - 1];
        game.deck.pop();

        return card;
    }

    /*
        Function to start game and enter the preflop state
        @param : gameId, seed
    */
    function startGame(
        uint8 gameId,
        uint24 seed
    ) public onlyState(gameId, GameStatus.AwaitingToStart) validGameId(gameId) {
        Game storage game = games[gameId];
        require(game.players.length == MAX_PLAYERS, "Table does not full yet");

        game.status = GameStatus.PreFlop;
        // deal the card
        for (uint8 i = 0; i < game.players.length; i++) {
            address playerAddress = game.players[i];
            if (game.isPlayerInGame[i] == 0) {
                game.playerCards[playerAddress] = [255, 255];
                continue;
            }
            for (uint8 j = 0; j < 2; j++) {
                uint8 card = drawCard(gameId, seed);
                game.playerCards[playerAddress].push(card);
            }
        }
        for (uint8 i = 0; i < 5; i++) {
            uint8 card = drawCard(gameId, seed);
            game.communityCards.push(card);
        }

        game.currentBet = 0;
        for (uint8 i = 0; i < MAX_PLAYERS; i++) {
            uint24 chips = game.playerChips[game.players[i]];
            if (chips == 0) {
                game.isPlayerInGame[i] = 0;
                game.isPlayerTakeTurn[i] = 1;
            }
            else if (chips <= game.blindAmount) {
                game.pot += chips;
                game.playerChips[game.players[i]] = 0;
                game.isPlayerAllIn[i] = 1;
                game.playerActions[i] = PlayerAction.AllIn;
                game.isPlayerTakeTurn[i] = 0;
            } else {
                game.pot += game.blindAmount;
                game.playerChips[game.players[i]] = chips - game.blindAmount;
                game.playerActions[i] = PlayerAction.Raise;
                game.isPlayerTakeTurn[i] = 0;
            }
        }
        uint8[] memory tmpTable = new uint8[](5);
        for (uint8 i = 0; i < 5; i++) {
            tmpTable[i] = 255;
        }
        emit GameStateChanged(gameId, tmpTable);
        uint8 nextPlayerIndex = (game.currentPlayerIndex + 1) % MAX_PLAYERS;
        emit NextPlayerAction(
            gameId,
            game.players[game.currentPlayerIndex],
            1,
            game.currentBet,
            game.players[nextPlayerIndex]
        );
        emit PotUpdated(gameId, game.pot);
        game.currentPlayerIndex = nextPlayerIndex;
    }

    function _min(uint24 a, uint24 b) internal pure returns (uint24) {
        return a <= b ? a : b;
    }

    function _max(uint24 a, uint24 b) internal pure returns (uint24) {
        return a >= b ? a : b;
    }

    /*
        Function to Call in the Round
        @param : gameId, player action, raise amount
    */
    function callAction(uint8 gameId) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(_isValidAction(game), "Invalid call action");
        uint8 currentPlayerIndex = game.currentPlayerIndex;
        if (game.isPlayerAllIn[game.currentPlayerIndex] == 1) {
            _nextPlayer(game);
            emit NextPlayerAction(
                gameId,
                game.players[currentPlayerIndex],
                6,
                game.currentBet,
                game.players[game.currentPlayerIndex]
            );
            return;
        }
        address player = game.players[game.currentPlayerIndex];

        game.playerActions[game.currentPlayerIndex] = PlayerAction.Call;
        uint24 callAmount = _min(
            game.currentBet - game.playerBetAmounts[game.currentPlayerIndex],
            game.playerChips[player]
        );
        game.pot += callAmount;
        game.playerChips[player] -= callAmount;
        game.playerBetAmounts[game.currentPlayerIndex] = _min(
            game.currentBet,
            game.playerBetAmounts[game.currentPlayerIndex] + callAmount
        );
        if (game.playerChips[player] == 0) {
            game.isPlayerAllIn[game.currentPlayerIndex] = 1;
            game.playerActions[game.currentPlayerIndex] = PlayerAction.AllIn;
        }
        game.isPlayerTakeTurn[game.currentPlayerIndex] = 1;
        _nextPlayer(game);
        emit NextPlayerAction(
            gameId,
            game.players[currentPlayerIndex],
            1,
            game.currentBet,
            game.players[game.currentPlayerIndex]
        );
        emit PotUpdated(gameId, game.pot);
    }

    /*
        Function to Raise in the Round
        @param : gameId, player action, raise amount
    */
    function raiseAction(
        uint8 gameId,
        uint24 raiseAmount
    ) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(_isValidAction(game), "Invalid raise action");
        uint8 currentPlayerIndex = game.currentPlayerIndex;
        if (game.isPlayerAllIn[game.currentPlayerIndex] == 1) {
            _nextPlayer(game);
            emit NextPlayerAction(
                gameId,
                game.players[currentPlayerIndex],
                6,
                game.currentBet,
                game.players[game.currentPlayerIndex]
            );
            return;
        }
        address player = game.players[game.currentPlayerIndex];

        require(
            raiseAmount > game.currentBet,
            "Raise amount must be greater than current bet"
        );
        require(
            game.playerChips[player] >= raiseAmount,
            "Insufficient balance"
        );

        game.playerActions[game.currentPlayerIndex] = PlayerAction.Raise;
        game.currentBet = raiseAmount;
        game.pot += raiseAmount;
        game.playerBetAmounts[game.currentPlayerIndex] = raiseAmount;
        game.playerChips[player] -= raiseAmount;
        if (game.playerChips[player] == 0) {
            game.isPlayerAllIn[game.currentPlayerIndex] = 1;
            game.playerActions[game.currentPlayerIndex] = PlayerAction.AllIn;
        }
        game.playerActions[game.currentPlayerIndex] = PlayerAction.Raise;
        for (uint8 i = 0; i < MAX_PLAYERS; i++) {
            game.isPlayerTakeTurn[i] = i == game.currentPlayerIndex ? 1 : 0;
        }
        _nextPlayer(game);
        emit NextPlayerAction(
            gameId,
            game.players[currentPlayerIndex],
            2,
            game.currentBet,
            game.players[game.currentPlayerIndex]
        );
        emit PotUpdated(gameId, game.pot);
    }

    /*
        Function to Check in the Round
        @param : gameId, player action, raise amount
    */
    function checkAction(uint8 gameId) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(_isValidAction(game), "Invalid check action");
        uint8 currentPlayerIndex = game.currentPlayerIndex;
        if (game.isPlayerAllIn[game.currentPlayerIndex] == 1) {
            _nextPlayer(game);
            emit NextPlayerAction(
                gameId,
                game.players[currentPlayerIndex],
                6,
                game.currentBet,
                game.players[game.currentPlayerIndex]
            );
            return;
        }
        require(
            game.playerBetAmounts[game.currentPlayerIndex] == game.currentBet,
            "Cannot check, must call to match the current bet"
        );
        game.playerActions[game.currentPlayerIndex] = PlayerAction.Check;
        game.isPlayerTakeTurn[game.currentPlayerIndex] = 1;
        _nextPlayer(game);
        emit NextPlayerAction(
            gameId,
            game.players[currentPlayerIndex],
            3,
            game.currentBet,
            game.players[game.currentPlayerIndex]
        );
    }

    /*
        Function to Fold in the Round
        @param : gameId, player action, raise amount
    */
    function foldAction(uint8 gameId) public validGameId(gameId) {
        Game storage game = games[gameId];
        require(_isValidAction(game), "Invalid fold action");
        uint8 currentPlayerIndex = game.currentPlayerIndex;
        if (game.isPlayerAllIn[game.currentPlayerIndex] == 1) {
            _nextPlayer(game);
            emit NextPlayerAction(
                gameId,
                game.players[currentPlayerIndex],
                6,
                game.currentBet,
                game.players[game.currentPlayerIndex]
            );
            return;
        }
        game.playerActions[game.currentPlayerIndex] = PlayerAction.Fold;
        game.isPlayerTakeTurn[game.currentPlayerIndex] = 1;
        game.isPlayerFolded[game.currentPlayerIndex] = 1;
        _nextPlayer(game);
        emit NextPlayerAction(
            gameId,
            game.players[currentPlayerIndex],
            4,
            game.currentBet,
            game.players[game.currentPlayerIndex]
        );
    }

    function _isValidAction(Game storage game) internal view returns (bool) {
        return
            (game.status == GameStatus.PreFlop ||
                game.status == GameStatus.Flop ||
                game.status == GameStatus.Turn ||
                game.status == GameStatus.River) &&
            (game.playerActions[game.currentPlayerIndex] !=
                PlayerAction.Fold) &&
            (msg.sender == game.players[game.currentPlayerIndex]) &&
            (game.isPlayerInGame[game.currentPlayerIndex] != 0) &&
            (game.isPlayerTakeTurn[game.currentPlayerIndex] == 0);
    }

    function getIsValidAction(
        uint8 gameId
    )
        public
        view
        returns (
            bool validState,
            bool validAction,
            bool validPlayer,
            bool validActivePlayer,
            bool validTakeTurn
        )
    {
        Game storage game = games[gameId];
        return (
            game.status == GameStatus.PreFlop ||
                game.status == GameStatus.Flop ||
                game.status == GameStatus.Turn ||
                game.status == GameStatus.River,
            game.playerActions[game.currentPlayerIndex] != PlayerAction.Fold,
            msg.sender == game.players[game.currentPlayerIndex],
            game.isPlayerInGame[game.currentPlayerIndex] != 0,
            game.isPlayerTakeTurn[game.currentPlayerIndex] == 0
        );
    }

    function _nextPlayer(Game storage game) internal {
        uint8 count = 0;

        do {
            game.currentPlayerIndex = (game.currentPlayerIndex + 1) % MAX_PLAYERS;
            count++;
            if (count >= MAX_PLAYERS) {
                return;
            }
        } while (
            game.isPlayerFolded[game.currentPlayerIndex] == 1 || game.isPlayerAllIn[game.currentPlayerIndex] == 1
        );
    }

    /*
        Function to reveal 3 community cards
        @param : gameId
    */
    function flop(
        uint8 gameId
    )
        public
        onlyState(gameId, GameStatus.PreFlop)
        returns (uint8 firstCard, uint8 secondCard, uint8 thirdCard)
    {
        Game storage game = games[gameId];
        uint8 numPlayerTakeTurn = 0;
        for (uint8 i = 0; i < MAX_PLAYERS; i++) {
            numPlayerTakeTurn += uint8(
                _max(_max(game.isPlayerTakeTurn[i], game.isPlayerAllIn[i]), game.isPlayerFolded[i])
            );
            game.isPlayerTakeTurn[i] = 0;
        }
        require(numPlayerTakeTurn == MAX_PLAYERS, "All player must take turn");
        game.status = GameStatus.Flop;
        _nextPlayer(game);
        game.currentBet = 0;
        for (uint8 i = 0; i < MAX_PLAYERS; ++i) {
            game.playerActions[i] = PlayerAction.Idle;
        }
        for (uint8 i = 0; i < MAX_PLAYERS; ++i) {
            game.playerBetAmounts[i] = 0;
        }
        uint8[] memory tmpTable = new uint8[](5);
        for (uint8 i = 0; i < 5; i++) {
            tmpTable[i] = i < 3 ? game.communityCards[i] : 255;
        }
        emit GameStateChanged(gameId, tmpTable);
        return (
            game.communityCards[0],
            game.communityCards[1],
            game.communityCards[2]
        );
    }

    /*
        Function to reveal 4 community cards
        @param : gameId
    */
    function turn(
        uint8 gameId
    )
        public
        onlyState(gameId, GameStatus.Flop)
        returns (
            uint8 firstCard,
            uint8 secondCard,
            uint8 thirdCard,
            uint8 fourthCard
        )
    {
        Game storage game = games[gameId];
        uint8 numPlayerTakeTurn = 0;
        for (uint8 i = 0; i < MAX_PLAYERS; i++) {
            numPlayerTakeTurn += uint8(
                _max(_max(game.isPlayerTakeTurn[i], game.isPlayerAllIn[i]), game.isPlayerFolded[i])
            );
            game.isPlayerTakeTurn[i] = 0;
        }
        require(numPlayerTakeTurn == MAX_PLAYERS, "All player must take turn");
        game.status = GameStatus.Turn;
        _nextPlayer(game);
        game.currentBet = 0;
        for (uint8 i = 0; i < MAX_PLAYERS; ++i) {
            game.playerActions[i] = PlayerAction.Idle;
        }
        for (uint8 i = 0; i < MAX_PLAYERS; ++i) {
            game.playerBetAmounts[i] = 0;
        }
        uint8[] memory tmpTable = new uint8[](5);
        for (uint8 i = 0; i < 5; i++) {
            tmpTable[i] = i < 4 ? game.communityCards[i] : 255;
        }
        emit GameStateChanged(gameId, tmpTable);
        return (
            game.communityCards[0],
            game.communityCards[1],
            game.communityCards[2],
            game.communityCards[3]
        );
    }

    /*
        Function to reveal 5 community cards
        @param : gameId
    */
    function River(
        uint8 gameId
    )
        public
        onlyState(gameId, GameStatus.Turn)
        returns (
            uint8 firstCard,
            uint8 secondCard,
            uint8 thirdCard,
            uint8 fourthCard,
            uint8 FifthCard
        )
    {
        Game storage game = games[gameId];
        uint8 numPlayerTakeTurn = 0;
        for (uint8 i = 0; i < MAX_PLAYERS; i++) {
            numPlayerTakeTurn += uint8(
                _max(_max(game.isPlayerTakeTurn[i], game.isPlayerAllIn[i]), game.isPlayerFolded[i])
            );
            game.isPlayerTakeTurn[i] = 0;
        }
        require(numPlayerTakeTurn == MAX_PLAYERS, "All player must take turn");
        game.status = GameStatus.River;
        _nextPlayer(game);
        game.currentBet = 0;
        for (uint8 i = 0; i < MAX_PLAYERS; ++i) {
            game.playerActions[i] = PlayerAction.Idle;
        }
        for (uint8 i = 0; i < MAX_PLAYERS; ++i) {
            game.playerBetAmounts[i] = 0;
        }
        emit GameStateChanged(gameId, game.communityCards);
        return (
            game.communityCards[0],
            game.communityCards[1],
            game.communityCards[2],
            game.communityCards[3],
            game.communityCards[4]
        );
    }

    /*
        Function to reward
        @param : gameId
    */
    function showdown(
        uint8 gameId
    )
        public
        onlyState(gameId, GameStatus.River)
        returns (uint8[][] memory, uint8[] memory, uint8[] memory)
    {
        Game storage game = games[gameId];
        uint8[][] memory playerHands = new uint8[][](game.numPlayerInGame);
        for (uint8 i = 0; i < game.players.length; i++) {
            playerHands[i] = game.playerCards[game.players[i]];
        }
        (uint40[] memory bestHands, uint8[] memory winnerIndices) = CardUtils
            .checkWinningHands(playerHands, game.communityCards);
        uint24 rewards = uint24(game.pot / winnerIndices.length);
        for (uint8 i = 0; i < winnerIndices.length; i++) {
            game.playerChips[game.players[winnerIndices[i]]] += uint24(rewards);
        }

        uint8[][] memory bestHandsDecoded = new uint8[][](bestHands.length);
        uint8[] memory bestHandsCombination = new uint8[](bestHands.length);
        for (uint8 i = 0; i < bestHands.length; i++) {
            bestHandsDecoded[i] = CardUtils.decodeHand(bestHands[i]);
            bestHandsCombination[i] = CardUtils.getScore(bestHands[i]);
        }
        game.status = GameStatus.Finish;
        // emit GameStateChanged(gameId, game.communityCards);
        return (bestHandsDecoded, bestHandsCombination, winnerIndices);
    }

    /*
        Function to reset game
        @param : gameId
    */
    function clear(
        uint8 gameId
    ) public payable onlyState(gameId, GameStatus.Finish) {
        Game storage game = games[gameId];
        for (uint8 i = 0; i < MAX_PLAYERS; i++) {
            if (game.playerChips[game.players[i]] == 0) {
                game.isPlayerInGame[i] == 0;
                game.numPlayerInGame--;
            }
        }

        if (game.numPlayerInGame == 1) {
            uint8 winner_idx = 0;
            for (uint8 i = 0; i < game.isPlayerInGame.length; i++) {
                if (game.isPlayerInGame[i] == 1) {
                    winner_idx = i;
                }
            }
            emit GameEnded(gameId, game.players[winner_idx], game.playerChips[game.players[winner_idx]]);
            _transfer(
                game.players[winner_idx],
                game.playerChips[game.players[winner_idx]]
            );
            _resetGame(gameId);
            return;
        }
        _resetRound(gameId);
        uint8[] memory tmpTable = new uint8[](5);
        for (uint8 i = 0; i < 5; i++) {
            tmpTable[i] = 255;
        }
        emit GameStateChanged(gameId, tmpTable);
    }

    /*
        Function to reset round
        @param : gameId
    */
    function _resetRound(uint8 gameId) internal {
        Game storage game = games[gameId];
        game.pot = 0;
        game.currentBet = 0;
        // game.currentPlayerIndex = 0;
        game.status = GameStatus.AwaitingToStart;
        game.playerActions = new PlayerAction[](MAX_PLAYERS);
        game.playerBetAmounts = new uint24[](MAX_PLAYERS);
        game.communityCards = new uint8[](0);
        game.isPlayerAllIn = new uint8[](MAX_PLAYERS);
        game.isPlayerTakeTurn = new uint8[](MAX_PLAYERS);
        game.isPlayerFolded = new uint8[](MAX_PLAYERS);

        game.deck = new uint8[](0);
        for (uint8 i = 0; i < 52; i++) {
            game.deck.push(i);
        }
        _resetPlayerCards(gameId);
    }

    function _resetGame(uint8 gameId) internal {
        delete games[gameId];
    }

    function _resetPlayerCards(uint8 gameId) internal {
        Game storage game = games[gameId];
        for (uint8 i = 0; i < game.players.length; i++) {
            if (game.isPlayerInGame[i] == 0) {
                game.playerCards[game.players[i]] = [255, 255];
                continue;
            }
            game.playerCards[game.players[i]] = new uint8[](0);
        }
    }

    function getGameBasicDetails(
        uint8 gameId
    )
        public
        view
        returns (
            address oowner,
            uint24 blindAmount,
            uint24 pot,
            GameStatus status,
            uint8 verifiedPlayerCount,
            uint8[] memory
        )
    {
        Game storage game = games[gameId];
        return (
            game.owner,
            game.blindAmount,
            game.pot,
            game.status,
            game.verifiedPlayerCount,
            game.isPlayerInGame
        );
    }

    function getMyHand(
        uint8 gameId
    ) public view returns (uint8 firstCard, uint8 secondCard) {
        Game storage game = games[gameId];
        return (
            game.playerCards[msg.sender][0],
            game.playerCards[msg.sender][1]
        );
    }

    function getPlayers(uint8 gameId) public view returns (address[] memory) {
        return games[gameId].players;
    }

    function getMyBalance(uint8 gameId) public view returns (uint24) {
        return games[gameId].playerChips[msg.sender];
    }

    function getNumGames() public view returns (uint8) {
        return nextGameId;
    }

    function getRoundDetails(
        uint8 gameId
    )
        public
        view
        returns (
            uint24[] memory,
            PlayerAction[] memory,
            uint24 blindAmount,
            uint24 pot,
            uint24 currentBet,
            uint8 currentPlayerIndex,
            uint8[] memory,
            uint8[] memory,
            uint8[] memory
        )
    {
        Game storage game = games[gameId];
        return (
            game.playerBetAmounts,
            game.playerActions,
            game.blindAmount,
            game.pot,
            game.currentBet,
            game.currentPlayerIndex,
            game.isPlayerAllIn,
            game.isPlayerTakeTurn,
            game.isPlayerFolded
        );
    }

    function getCardsDetail(
        uint8 gameId
    ) public view returns (uint8[][] memory, uint8[] memory, uint8 deckLength, uint40[] memory, uint8[] memory) {
        Game storage game = games[gameId];
        uint8[][] memory playerHands = new uint8[][](game.numPlayerInGame);
        for (uint8 i = 0; i < game.players.length; i++) {
            playerHands[i] = game.playerCards[game.players[i]];
        }
        (uint40[] memory bestHands, uint8[] memory winnerIndices) = CardUtils
            .checkWinningHands(playerHands, game.communityCards);
        return (playerHands, game.communityCards, uint8(game.deck.length), bestHands, winnerIndices);
    }
}
