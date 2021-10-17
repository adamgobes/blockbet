//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";
import "./ISportsFeed.sol";

contract BlockBet is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Bet {
        uint256 betId;
        address playerOne;
        address playerTwo;
        uint256 teamOne;
        uint256 teamTwo;
        uint256 winningTeam;
        uint256 amount;
        address betToken;
        uint256 gameId;
        bool betAccepted;
        bool payOutOccured;
    }

    uint256 private betIdCounter;

    mapping(address => Bet[]) playerToBets;
    mapping(uint256 => Bet) betIdToBet;

    ISportsFeed oracleClient;

    constructor(address oracleclientAddress) {
        betIdCounter = 0;
        oracleClient = ISportsFeed(oracleclientAddress);
    }

    /**
     * @notice Initializes the bet with immutable variables
     * @param receiver is the address of the person that the initiator wishes to wager against
     * @param teamOne is the SportsFeed team ID of the initiator
     * @param teamTwo is the SportsFeed team ID of the receiver
     * @param amount is the amount that the initiator would like to wager
     * @param betToken is the ERC20 that the initiator would like to wager in
     * @param gameId is the SportsFeed game ID
     */
    function placeBet(
        address receiver,
        uint256 teamOne,
        uint256 teamTwo,
        uint256 amount,
        address betToken,
        uint256 gameId
    ) external returns (uint256) {
        require(amount > 0, "cannot wager zero");

        uint256 betId = ++betIdCounter;

        Bet memory bet = Bet({
            betId: betId,
            playerOne: msg.sender,
            playerTwo: receiver,
            teamOne: teamOne,
            teamTwo: teamTwo,
            winningTeam: 0,
            amount: amount,
            betToken: betToken,
            gameId: gameId,
            betAccepted: false,
            payOutOccured: false
        });

        IERC20(betToken).safeTransferFrom(msg.sender, address(this), amount);

        playerToBets[msg.sender].push(bet);
        playerToBets[receiver].push(bet);
        betIdToBet[betId] = bet;

        return betId;
    }

    function acceptBet(uint256 betId) public nonReentrant {
        Bet storage bet = betIdToBet[betId];
        require(bet.playerTwo == msg.sender, "you cannot accept this bet");

        IERC20(bet.betToken).safeTransferFrom(
            msg.sender,
            address(this),
            bet.amount
        );
        bet.betAccepted = true;
    }

    function initiateOutcome(uint256 betId) public returns (uint256) {
        Bet storage bet = betIdToBet[betId];

        uint256 winner = oracleClient.getResultForGame(bet.gameId);
        if (winner == 0) {
            oracleClient.fetchGameResultFromOracle(bet.gameId);
        } else {
            bet.winningTeam = winner;
        }

        return winner;
    }

    function claimReward(uint256 betId)
        public
        nonReentrant
        payoutNotOccuredForBet(betId)
        betAccepted(betId)
    {
        Bet memory bet = betIdToBet[betId];
        require(
            msg.sender == bet.playerOne || msg.sender == bet.playerTwo,
            "you did not participate in this bet!"
        );
        require(bet.winningTeam != 0, "winner has not been determined yet");

        uint256 selectedTeam = 0;
        if (msg.sender == bet.playerOne) {
            selectedTeam = bet.teamOne;
        } else if (msg.sender == bet.playerTwo) {
            selectedTeam = bet.teamTwo;
        } else {
            return;
        }

        require(
            bet.winningTeam == selectedTeam,
            "you did not choose the winning team"
        );

        IERC20(bet.betToken).safeTransfer(msg.sender, bet.amount);
        bet.payOutOccured = true;
    }

    function getBetsForAddress(address addr)
        external
        view
        returns (Bet[] memory)
    {
        return playerToBets[addr];
    }

    function getBetById(uint256 betId) external view returns (Bet memory) {
        return betIdToBet[betId];
    }

    function resultBeenDeterminedForBet(uint256 betId) external returns (bool) {
        return oracleClient.getResultForGame(betIdToBet[betId].gameId) != 0;
    }

    modifier betAccepted(uint256 betId) {
        require(betIdToBet[betId].betAccepted, "bet has not been accepted");
        _;
    }

    modifier payoutNotOccuredForBet(uint256 betId) {
        require(
            !betIdToBet[betId].payOutOccured,
            "payout already occured for bet"
        );
        _;
    }
}
