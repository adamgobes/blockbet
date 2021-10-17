//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// This is the main building block for smart contracts.
contract ERC20Token is ERC20 {
    using SafeMath for uint256;

    constructor() ERC20("Fake DAI", "FDAI") {}

    function mintDummy() public {
        _mint(msg.sender, 1000000 * (10**uint256(decimals())));
    }
}
