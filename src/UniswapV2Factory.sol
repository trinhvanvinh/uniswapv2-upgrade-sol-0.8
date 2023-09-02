// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./UniswapV2Pair.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract UniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    function createPair(
        address tokenA,
        address tokenB
    ) public returns (address pair) {
        require(tokenA != tokenB, "Identical address");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Zero address");
        require(pairs[token0][token1] == address(0), "Pair exists");

        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}
