pragma solidity ^0.8.0;

interface ISportsFeed {
    function fetchGameResultFromOracle(uint256 gameId)
        external
        returns (bytes32 requestId);

    function getResultForGame(uint256 gameId) external returns (uint256);
}
