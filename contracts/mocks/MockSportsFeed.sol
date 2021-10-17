pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "../ISportsFeed.sol";

contract MockSportsFeed is ChainlinkClient, ISportsFeed {
    mapping(uint256 => uint256) outcomes;
    mapping(bytes32 => uint256) requestIdToGameId;

    function fetchGameResultFromOracle(uint256 gameId)
        public
        override
        returns (bytes32)
    {
        bytes32 requestId = stringToBytes32("random string");

        requestIdToGameId[requestId] = gameId;

        outcomes[gameId] = 123;

        return requestId;
    }

    function getResultForGame(uint256 gameId)
        public
        view
        override
        returns (uint256)
    {
        return outcomes[gameId];
    }

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
