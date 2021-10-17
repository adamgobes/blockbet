pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./ISportsFeed.sol";
import "./BlockBet.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract SportsFeed is ChainlinkClient, ISportsFeed {
    using Chainlink for Chainlink.Request;

    uint256 public volume;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    mapping(uint256 => uint256) outcomes;
    mapping(bytes32 => uint256) requestIdToGameId;

    event GameResultObtained(uint256 gameId, uint256 winningTeam);

    constructor() {
        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10**18;
    }

    function fetchGameResultFromOracle(uint256 gameId)
        public
        override
        returns (bytes32 requestId)
    {
        require(
            outcomes[gameId] == 0,
            "outcome for this game has already been computed"
        );

        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        requestIdToGameId[requestId] = gameId;

        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    function fulfill(bytes32 _requestId, uint256 winner)
        public
        recordChainlinkFulfillment(_requestId)
    {
        uint256 gameId = requestIdToGameId[_requestId];
        outcomes[gameId] = winner;
        emit GameResultObtained(gameId, winner);
    }

    function getResultForGame(uint256 gameId)
        public
        view
        override
        returns (uint256)
    {
        return outcomes[gameId];
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}
